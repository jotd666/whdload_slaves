; DataStorm loader by Jff
;
; Assembled with Barfly

	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	DataStorm.slave
	ENDC

CHIPMEMSIZE = $80000


_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd|WHDLF_ClearMem
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
		dc.l	$0			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
		
_config:
	dc.b	"C1:X:trainer infinite lives:0;"
	dc.b	"C1:X:trainer infinite bombs:1;"
		dc.b	0
		
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,0

_name		dc.b	"DataStorm",0
_copy		dc.b	"1989 Visionary Design Technologies Inc",0
_info		dc.b	"installed & fixed by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

		even
	
IGNORE_JOY_DIRECTIONS
		include	ReadJoyPad.s

; version supported: SPS 1555

; this game has a strange reboot sequence to start
; I think this is maybe in order to reboot until Action Replay is off
; (or actually the AR splash screen)
; but maybe AR believes bootblock is a virus
;
; anyway, the program heavily relies on CIAB_SDR value and it is part of the protection

_Start
	clr.l	$4.W
	bsr		_detect_controller_types
	
	lea	CHIPMEMSIZE-$100,A7

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	;enable cache
	IFEQ	1
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	move.l	#CACRF_EnableI,D0
	move.l	D0,D1
	jsr	(resload_SetCACR,a2)
	ENDC

	; load the boot in $40000

	lea	$40000,a0
	moveq.l	#0,D0
	move.l	#$400,d1
	moveq.l	#1,d2
	jsr	(resload_DiskLoad,a2)

	lea	$40000,a1
	lea	_boot_patchlist(pc),a0
	jsr	(resload_Patch,a2)


	lea	_fakediskio(pc),A1
;;	jmp	$40026
	jmp	$401C0

_fakediskio:
	ds.l	20,0

_trackload:
	move.w	(IO_COMMAND,a1),d0
	and.w	#$7FFF,d0
	cmp.w	#2,D0
	bne.b	.skip

	movem.l	d1/d2/a0/a1,-(a7)
	move.l	(IO_OFFSET,a1),d0
	move.l	(IO_LENGTH,a1),d1
	move.l	(IO_UNIT,a1),d2
	addq.l	#1,d2
	move.l	(IO_DATA,a1),a0
	move.l	_resload(pc),a1
	jsr	(resload_DiskLoad,a1)
	movem.l	(a7)+,d1/d2/a0/a1
.skip
	clr.b	(IO_ERROR,a1)
	moveq.l	#0,D0
	rts


_jump1:
;	move.b	#$52,$BFDC00
;	move.b	#$4C,$BFDC00
;	move.l	#$80000,$70000	; expmem location
;	move.l	#$80000,$70004	; expmem size

	move.l	#0,$70000
	move.l	#0,$70004

	move.w	#$7FFF,$DFF09A

	patch	$452CE,_jump2
	bsr	_flushcache

	jmp	$45224

_jump2
	patch	$100,_jump400
	move.l	#$FFFFFFFE,$120.W	; correct copperlist

	move.l	_resload(pc),a2
	lea	$45000,a1
	lea	_45000_patchlist(pc),a0
	jsr	(resload_Patch,a2)

	jmp	$45000

; main program start in $400

_jump400:
	bsr	_readscores

	sub.l	a1,a1
	lea	patchlist_400_v1555(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)

	lea	$900,A0
	lea	$20000,A1
	move.l	#$51C8FFFE,D0
	move.l	#$4EB80100,D1
	bsr	_hexreplacelong

	move.l	#$51C9FFFE,D0
	move.l	#$4EB80106,D1
	bsr	_hexreplacelong

	move.l	#$51CAFFFE,D0
	move.l	#$4EB8010C,D1
	bsr	_hexreplacelong

	move.l	#$51CFFFFE,D0
	move.l	#$4EB80112,D1
	bsr	_hexreplacelong

;	move.l	#$4E714E71,D0
;	move.l	#$4EB80118,D1
;	bsr	_hexreplacelong

	bsr	_flushcache
	jmp	$400.W

_readsectors:
	movem.l	D0-A6,-(A7)
	move.l	A3,A0	; dest
	moveq.l	#1,D2	; disk 1, of course
	moveq.l	#0,D0
	move.w	D6,D0
	mulu	#$200,D0	; offset
	move.l	D5,D1		; length
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
	movem.l	(A7)+,D0-A6
	rts


_resload:
	dc.l	0

_emunop:
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	rts
	
_emudbf_d0:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_emudbf_d1:
	move.l	D0,-(A7)
	move.l	D1,D0
	bsr.b	_emudbf_d0
	move.l	(A7)+,D0
	rts
_emudbf_d2:
	move.l	D0,-(A7)
	move.l	D2,D0
	bsr.b	_emudbf_d0
	move.l	(A7)+,D0
	rts
_emudbf_d7:
	move.l	D0,-(A7)
	move.l	D7,D0
	bsr.b	_emudbf_d0
	move.l	(A7)+,D0
	rts

dma_sound_wait_loop
	move.l	D0,-(A7)
	move.l	#10,d0
	bsr	_beamdelay
	move.l	(A7)+,D0
	rts

in_game_dma_sound
	move	d1,$dff096
	bsr	dma_sound_wait_loop
	add.l	#8,(a7)
	rts

move_dmacon_sound
	move	d0,$dff096	; stolen
	bsr	dma_sound_wait_loop
	rts

load_d6
	; original code is move.b ciab_sdr,d6

	; the game uses CIAB_SDR value as a protection
	;
	; the value is set to $52 at first in the game boot, then the game reboots
	; and checks for CIAB_SDR value properly set to $52, if so, game loads normally
	;
	; Afterwards, the OS or some other device must do some stuff and it's $79 when
	; we reach this location (it no longer changes, then)
	;
	; This value is added to some audio internal data structure.
	;
	; That's a nice protection trick. Never saw it anywhere else.
	;
	; we simulate correct value so when it adds up to sound pointer, it is correct
	; (else it is odd, and on a 68000 it would have crashed because of multi-byte move
	; of an odd address. On a 68020+ it works but there's no sound, funny side-effect)

	move.b	#$79,d6
	rts

patchlist_400_v1555
	PL_START
	PL_P	$100,_emudbf_d0
	PL_P	$106,_emudbf_d1
	PL_P	$10C,_emudbf_d2
	PL_P	$112,_emudbf_d7
	PL_P	$118,_emunop
	PL_P	$63A,_readsectors

	; disk protection (track 0 head 1)

	PL_P	$1C0E6,emulate_protection

	; protections code checks, useless to fix since I have patched before!

	IFEQ	1
	PL_L	$1BF08,$4E714E71
	PL_L	$1B558,$4E714E71
	PL_W	$1B818,$4E71
	ENDC

	PL_IFC1X	0
	PL_NOP	$0714a,6		; infinite lives
	PL_ENDIF
	PL_IFC1X	1
	PL_NOP	$0969a,6		; infinite smart bombs
	PL_ENDIF
	
	
	PL_P	$1AD3C,_writescores
	PL_PS	$1631C,_main_game_50004

	; read joypad
	PL_PS	$0e170,level3_interrupt_hook
	
	; keyboard handshake
	PL_PS	$FE32,kb_handshake
	
	; specific dbf fixes for sound

	PL_PS	$1AE40,load_d6

	PL_PS	$1AECC,in_game_dma_sound
	PL_PS	$1AF24,in_game_dma_sound
	PL_PS	$1B5DC,in_game_dma_sound
	PL_PS	$1B9C2,move_dmacon_sound

	; blitter waits

	PL_PS	$41EE,_move_a0_dff050
	PL_PS	$4200,_move_a0_dff050
	PL_PS	$4294,_move_a0_dff050
	PL_PS	$42A6,_move_a0_dff050
	PL_PS	$434A,_move_a0_dff050
	PL_PS	$4362,_move_a0_dff050
	PL_PS	$4402,_move_a0_dff050
	PL_PS	$441A,_move_a0_dff050
	PL_PS	$44CE,_move_a0_dff050
	PL_PS	$44E6,_move_a0_dff050
	PL_PS	$4580,_move_a0_dff050
	PL_PS	$4598,_move_a0_dff050

	PL_PS	$3B22,_move_a2_dff054	
	PL_PS	$9FB0,_move_a2_dff054
	PL_PS	$D4DE,_move_a2_dff054	


	PL_PS	$079EE,_move_d0_dff040
	PL_PS	$07A8E,_move_d0_dff040
	PL_PS	$07B2E,_move_d0_dff040
	PL_PS	$07C02,_move_d0_dff040
	PL_PS	$07CA8,_move_d0_dff040
	PL_PS	$07D48,_move_d0_dff040
	PL_PS	$09F90,_move_d0_dff040
	PL_PS	$0D312,_move_d0_dff040

	PL_PS	$CF0A,_move_fwm
	PL_NOP	$CF10,4

	PL_P	$EAAE,_waitblit	; used a potentially problematic waitblit

	; copper lists

	PL_PS	$FEFE,move_dmacon_copperlist
	PL_NOP	$FEFE+6,2

	; other strange SNOOP bugs

	PL_PS	$136C2,watch_blitter_source_d0
	PL_PS	$13642,watch_blitter_source_dff04c
	PL_NOP	$13642+6,4
	PL_PS	$115B0,fix_read_custom_1
	PL_NOP	$115B6,2
	PL_PS	$115D0,fix_read_custom_2
	PL_END
	

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

kb_handshake
	cmp.b	_keyexit(pc),d0
	beq.b	_quit
	move.l	#2,d0

.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
	
key_pressed_ascii_code = $FDE4
key_pressed_flag = $cb8
CIAA_SDR = $BFEC01

BUTTON_PRESSED:MACRO
	btst	#JPB_BTN_\1,d0
	beq.b	.no_\1
	move.b	#\2,CIAA_SDR
	bra.b	.next\@
.no_\1
	btst	#JPB_BTN_\1,d1
	beq.b	.next\@
	clr.b	CIAA_SDR
.next\@
	ENDM
	
level3_interrupt_hook
	movem.l	d0-d1/A0,-(a7)
	lea		joypad_state(pc),a0
	move.l	(a0),d1		; previous state
	bsr		_read_joystick
	move.l	d0,(a0)

	BUTTON_PRESSED	BLU,$7F
	BUTTON_PRESSED	PLAY,$CD
	btst	#JPB_BTN_GRN,d0
	beq.b	.no_green
	; pressed but is this the first time?
	btst	#JPB_BTN_GRN,d1
	bne.b	.no_green
	; first pressed
	; any key works
	move.b	#'A',key_pressed_ascii_code
.no_green
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.no_esc
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.no_esc
	move.b	#$75,CIAA_SDR
.no_esc	
	movem.l	(a7)+,D0-d1/a0
	
	cmp.l	#0,a0	; orig
	rts
	
	
	
fix_read_custom_1
	move.w	#0,d0
	movem.l	d1,-(a7)
	move.l	a2,d1
	and.w	#$FFFFF000,d1
	cmp.l	#$00DFF000,d1
	beq.b	.skipreadcustom
	move.w	$200(a2),d0	; original code
.skipreadcustom
	movem.l	(a7)+,d1
	SUBI	#$0400,D0
	rts

fix_read_custom_2
	moveq.l	#0,d0
	movem.l	d1,-(a7)
	move.l	a2,d1
	and.w	#$FFFFF000,d1
	cmp.l	#$00DFF000,d1
	beq.b	.skipreadcustom
	move.l	$200(a2),d0	; original code
.skipreadcustom
	movem.l	(a7)+,d1
	moveq	#2,d7
	rts

watch_blitter_source_d0
	move.l	$1338E,d0
	cmp.l	#$80000,d0
	bcs.b	.ok
	; completely wrong blit because $1338E is reused for something else
	; in $13DE: skip the rest of the routine
	addq.l	#4,a7
.ok
	rts

watch_blitter_source_dff04c
	move.l	$1338E,d2
	cmp.l	#$80000,d2
	bcs.b	.ok
	; completely wrong blit because $1338E is reused for something else
	; in $13DE: skip the rest of the routine
	addq.l	#4,a7
	rts
.ok
	move.l	d2,$dff04c
	rts

emulate_protection
	rts

_boot_patchlist:
	PL_START
	PL_PS	$44,_trackload
	PL_L	$4A,$4E714E71
	PL_P	$80,_jump1
	PL_PS	$1E8,_trackload
	PL_W	$1EE,$4E71
	PL_L	$1FA,$4E714E71
	PL_END

_45000_patchlist:
	PL_START
	PL_W	$148,$100
	PL_S	$24,$52-$24	; skip disk stuff

	PL_L	$8C,$120	; avoids garbage in copperlist1
	PL_L	$96,$120	; avoids garbage in copperlist2
	PL_END

_pl_50004
	PL_START
	PL_L	$5A98,$FFFFFFFE
	PL_PS	$8974,_fix_cl1
	PL_NOP	$897A,4
	PL_END

_main_game_50004:
	movem.l	D0-A6,-(A7)
	lea	_pl_50004(pc),a0
	lea	$50000,a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)	
	movem.l	(A7)+,D0-A6

	jmp	$50004


move_dmacon_copperlist
	move.l	#$01005200,$EFE4	; fix invalid cl entry
	move.w	#$81A0,$dff096
	rts

_fix_cl1
	move.l	#-2,$58424
	move.l	$58970,$dff080
	rts

_move_fwm:
	bsr	_waitblit
	MOVE.L	#$FFFF0000,$DFF044
	rts


_move_a0_dff050
	bsr	_waitblit
	move.l	a0,$dff050
	rts


_move_d0_dff040
	bsr	_waitblit
	move.w	d0,$dff040
	rts

_move_a2_dff054
	bsr	_waitblit
	move.l	a2,$dff054
	rts


_waitblit:
	btst	#6,$dff002
	beq.b	.end
.wait
	btst	#6,$dff002
	bne.b	.wait
.end
	rts

_writescores:
	movem.l	D0-A6,-(A7)
	MOVE.L	_resload(PC),A2
	MOVE.L	#$1B6,D0			;len to save
	MOVEQ.L	#0,D1			;start with begin of file
	lea	_hiscname(pc),A0
	lea	$1700C,A1
	JSR	(resload_SaveFileOffset,a2)	
	movem.l	(A7)+,D0-A6
	rts

_readscores:
	movem.l	D0-A6,-(A7)
	MOVE.L	_resload(PC),A2
	MOVE.L	#$1B6,D0			;len to save
	MOVEQ.L	#0,D1			;start with begin of file
	lea	_hiscname(pc),A0
	lea	$1700C,A1
	JSR	(resload_LoadFileOffset,a2)	
	movem.l	(A7)+,D0-A6
	rts

; < D0: to search
; < D1: to replace
; < A0: start
; < A1: end

_hexreplacelong:
	movem.l	A0-A1/D0-D1,-(A7)
.srch
	cmp.l	(A0),D0
	beq.b	.found
.next
	addq.l	#2,A0
	cmp.l	A1,A0
	bcc.b	.exit
	bra.b	.srch
.found
	move.l	D1,(A0)+
	bra	.next
.exit
	movem.l	(A7)+,A0-A1/D0-D1
	rts

_flushcache:
	move.l	A2,-(A7)
	move.l	(_resload,pc),a2
	jsr	(resload_FlushCache,a2)
	move.l	(A7)+,A2
	rts

joypad_state
	dc.l	0
_hiscname:
	dc.b	"Highs",0
