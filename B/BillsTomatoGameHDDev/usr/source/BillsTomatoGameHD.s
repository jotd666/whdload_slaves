;*---------------------------------------------------------------------------
;  :Program.	BillsTomatoGameHD.asm
;  :Contents.	Slave for "BillsTomatoGame" from
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	BillsTomatoGame.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;CHIP_ONLY

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_EmulTrap	;ws_flags
		IFND	CHIP_ONLY
		dc.l	$80000		;ws_BaseMemSize
		ELSE
		dc.l	$100000
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFND	CHIP_ONLY	
	dc.l	$80000			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
;---
	dc.w	slv_config-_base
	
slv_config:
        dc.b    "C1:X:infinite tries:0;"
        dc.b    "C1:X:infinite time:1;"
        dc.b    "C1:X:HELP skips level:2;"
		dc.b	0
;============================================================================


;;DEBUG

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"Bill's Tomato Game"
		IFD	CHIP_ONLY
		dc.b	" (DEBUG/CHIP MODE)"
		ENDC
		dc.b	0
_copy		dc.b	"1992 Psygnosis",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION

	dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION

		dc.b	0

DO_PATCH:MACRO
	movem.l	d0-d1/a0-a2,-(a7)
	lea	\1(pc),a0
	move.l	_resload(pc),a2
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	ENDM

;======================================================================
start	;	A0 = resident loader
;======================================================================

	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	sub.l	a3,a3
	sub.l	a4,a4
	sub.l	a5,a5
	sub.l	a6,a6

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	;get tags
    lea	(_tag,pc),a0
    jsr	(resload_Control,a2)

	lea	$7FF00,a7
	move	#$2700,SR
	move.l	#$7FFF,$DFF096

	bsr	set_extmem
	move.l	#$D270A306,$C.W

	lea	$40000,A0
	moveq	#1,D2
	move.l	#$400,D0
	move.l	#$C000,D1
	bsr	diskload

	lea	$40000,A0
	move.l	#$C000,d0
	jsr	resload_CRC16(a2)

	lea	version(pc),a0
	cmp.w	#$419A,d0
	bne	.not_v1
	move.l	#1,(a0)     ; PAL, SPS
	bra.b	.cont

.not_v1
	cmp.w	#$D5BC,d0
	bne	.not_v2
	move.l	#2,(a0)     ; NTSC
	bra.b	.cont

.not_v2
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.cont
	lea	$40000,A0
	lea	$800.W,A1
	bsr	decrunch

    
	pea	trap_jsr(pc)
	move.l	(a7)+,$BC	; TRAP #15: SMC fix

    move.l  version(pc),d0
    cmp.l   #2,d0
    beq.b   .ntsc
	DO_PATCH	pl_boot_pal
    bra.b   .start
.ntsc
    ;;move.w  #0,_custom+beamcon0

	DO_PATCH	pl_boot_ntsc
        ; enable SMC-detection for the area $10000..$3e000:
	;IFD	DEBUG
	;move.l  #$10000,d0              ;length
	;lea	$efa.W,a0               ;address
	;move.l  (_resload,pc),a2
	;jsr	(resload_ProtectSMC,a2)
	;ENDC
.start
	move	#$2000,SR    
	jmp	$EFA.W

pl_boot_pal
	PL_START
	PL_PSS	$65CE,soundtracker_loop,2
	PL_PSS	$65E4,soundtracker_loop,2
	PL_PS	$1AF8,remove_checksum_pal
	PL_P	$1E0A,patch_main_pal
    PL_NEXT pl_boot_common

pl_boot_common
	PL_START
	PL_P	$4F0C,read_sectors
	PL_L	$50B0,MOVEQZD0RTS		; check for disk in drive
	PL_P	$13F4,set_dmacon_boot
	PL_R	$50FC
;;	PL_PS	$1B12,fix_smc_boot

	PL_PSS	$5E54,soundtracker_loop,2
	PL_PSS	$5E6A,soundtracker_loop,2

	PL_W	$F4A,$4E4F
	PL_W	$F50,$4E4F
	PL_W	$F58,$4E4F
	PL_W	$2462,$4E4F
	PL_W	$2576,$4E4F
	PL_END
		
pl_boot_ntsc
	PL_START
    
	PL_PSS	$65D0,soundtracker_loop,2
	PL_PSS	$65E6,soundtracker_loop,2
	PL_PS	$1AF8,remove_checksum_ntsc
	PL_P	$1E0A,patch_main_ntsc

    PL_NEXT pl_boot_common
		
fix_smc_boot
	bsr	_flushcache
	jmp	$1D70.W

set_dmacon_boot
	move.w	#$0200,$11F4.W
	move.w	#$87e0,($96,a6)
	rts



diskload
	movem.l	d0-d1/d3/a0-a2,-(a7)
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
	movem.l	(a7)+,d0-d1/d3/a0-a2
	rts


write_sectors_trainer:
	cmp.w	#$774,D1
	beq	write_hisc

	moveq	#0,D7		; other parts, disabled
	rts
    
write_sectors:
	cmp.w	#$768,D1
	beq	write_saves

	cmp.w	#$774,D1
	beq	write_hisc

	moveq	#0,D7		; other parts, disabled
	rts

; executes the real disk routine, but I removed all
; CIA drive stuff, so noone will notice it

bypass_pal:
	movem.l	D0-D6/A0-A6,-(A7)
	jmp	$13434
bypass_ntsc:
	movem.l	D0-D6/A0-A6,-(A7)
	jmp	$134e8

; gamesaves

read_768_pal:
	bsr	bypass_pal		; to activate the load code
	bra	read_saves
read_768_ntsc:
	bsr	bypass_ntsc		; to activate the load code
	bra	read_saves

; hiscores

read_774:
	bra	read_hisc


read_hisc:
	movem.l	d0-d1/a0-a3,-(a7)
	moveq	#-1,d7
	move.l	_resload(pc),a2
	move.l	a0,a3		; save dest
	lea	hisc_name(pc),A0
	jsr	resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.nofile	
	move.l	a3,a1		; dest
	lea	hisc_name(pc),A0
	jsr	resload_LoadFile(a2)
	moveq	#0,D7
.nofile
	movem.l	(a7)+,d0-d1/a0-a3
	rts

read_saves:
	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	save_name(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)
.ok
	movem.l	(a7)+,d0-a6
	moveq	#0,D7
	rts


write_hisc:
	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	hisc_name(pc),A0
	move.l	_resload(pc),a2
	move.l	#$200,d0
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	moveq	#0,D7
	rts

write_saves:
	movem.l	d0-a6,-(a7)
	move.l	a0,a1
	lea	save_name(pc),A0
	move.l	_resload(pc),a2
	move.l	#$200,d0
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	moveq	#0,D7
	rts

set_extmem
	lea	_expmem(pc),a0
	IFD	CHIP_ONLY
	move.l	#$80000,(a0)
	ENDC
	move.l	(a0),a0
	move.l	A0,$8.W
	rts

jump_1876_pal:
	DO_PATCH	pl_1876_pal
	jmp	$1876.W
jump_1876_ntsc:
	DO_PATCH	pl_1876_ntsc
	jmp	$1876.W

MOVEQZD7RTS = $7E004E75
MOVEQZD0RTS = $7004E75

pl_1876_pal
	PL_START
    ; stupid crash on NTSC display
    PL_R    $0d4c6
	; this bitch does not like that the disk code
	; is not called in the read scores section
	; the following code removes all disk accesses and leds

	PL_L	$1371C,MOVEQZD7RTS
	PL_L	$13A1C,MOVEQZD7RTS
	PL_L	$138AA,MOVEQZD7RTS
	PL_L	$136F6,MOVEQZD7RTS
	PL_L	$13814,MOVEQZD7RTS
	PL_L	$13622,MOVEQZD0RTS
	PL_R	$1378A
	PL_R	$13752
	PL_R	$137BE
	PL_R	$136B8

	; *** load game & hiscores

	PL_PS	$D8AA,read_768_pal	; saves
	PL_PS	$E616,read_774	; hiscores

	; *** copperlist

	PL_PS	$1E96,set_dmacon_main

	; *** disk read

    PL_P    $C0,read_sectors
	PL_L	$13430,$4EF800C0
	PL_L	$135D4,MOVEQZD0RTS

	; *** track format

	PL_P	$13546,format_sectors

	; *** disk write

    PL_IFC1    
	PL_P	$134B4,write_sectors_trainer
    PL_ELSE
	PL_P	$134B4,write_sectors
    PL_ENDIF
    
	; *** remove code checksum 1

	PL_R	$98F8

	; *** remove code check

	PL_W	$C634,$6008
	PL_W	$C638,$0	; unnecessary but removes $4AFC reference

	; *** no more password

	PL_B	$DD30,$FF

	; *** some other illegal calls (not reached, but...)

	PL_NOP	$181E,2
	PL_NOP	$D9F0,2
	PL_NOP	$12DBE,$2

	; *** keyboard

	PL_PS	$1A1A,kb_int

	; keyboard timing

	PL_PS	$1A50,kb_delay

	; active loops
	
	PL_PSS	$14216,soundtracker_loop,2
	PL_PSS	$1422C,soundtracker_loop,2
	PL_PSS	$14990,soundtracker_loop,2
	PL_PSS	$149A6,soundtracker_loop,2

    PL_PSS  $21976,soundtracker_loop,2

	PL_PS	$BE66,d7_loop
	PL_PS	$B6C6,d7_loop
	PL_PS	$C106,d7_loop

    PL_PS   $0ca8e,small_delay
    
	; infinite loop replaced by ILLEGAL just in case

	PL_I	$12A02

	; avoid "this is an illegal copy" message
	; this is the obvious check

	PL_NOP	$12CBE,4

    ; this is the sneaky check. Happens when completing a level, completing a full level
    ; and trying to go the the next one. Example: enter VIGOGG or NOOVAT, skip level, climb tree
    ; play/skip all sea levels. At the interlude, this crap code is called and destroys
    ; some code/replaces by a jump to another "this is an illegal copy..."
    ;
    ; there are shorter ways to reproduce the error too. But never mind, we got this :)
    ;
    ; don't forget: to climb the tree, use big jumps: left+right mouse
    
    PL_PS   $12b16,unpack_data_hook_pal
    
    
	; SMC (JSR to modified locations)

    PL_W    $020fc,$4E4F
	PL_W	$101AE,$4E4F
	PL_W	$102CA,$4E4F
	PL_W	$102D0,$4E4F
    
    PL_IFC1X    0
    PL_NOP  $C07C,4  ; infinite attempts
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $01bd4,6
    PL_ENDIF
	PL_END

pl_1876_ntsc
	PL_START
    ; stupid crash on PAL display
    PL_R    $0d57c
    
	; this bitch does not like that the disk code
	; is not called in the read scores section
	; the following code removes all disk accesses and leds


	PL_L	$137d0,MOVEQZD7RTS
	PL_L	$13ad0,MOVEQZD7RTS
	PL_L	$1395e,MOVEQZD7RTS
	PL_L	$137aa,MOVEQZD7RTS
	PL_L	$138c8,MOVEQZD7RTS
	PL_L	$136d6,MOVEQZD0RTS
	PL_R	$1383e
	PL_R	$13806
	PL_R	$13872
	PL_R	$1376c

	; *** load game & hiscores

	PL_PS	$0d968,read_768_ntsc	; saves
	PL_PS	$0e6ca,read_774	; hiscores

	; *** copperlist

	PL_PS	$1E96,set_dmacon_main

	; *** disk read

    PL_P    $C0,read_sectors
	PL_L	$134e4,$4EF800C0
	PL_L	$13688,MOVEQZD0RTS

	; *** track format

	PL_P	$135fa,format_sectors

	; *** disk write

    PL_IFC1    
	PL_P	$13568,write_sectors_trainer
    PL_ELSE
	PL_P	$13568,write_sectors
    PL_ENDIF
    
	; *** remove code checksum 1

	PL_R	$09948

	; *** remove code checksum 2

	PL_W	$0c6f2,$6008
	PL_W	$C6f6,$0	; unnecessary but removes $4AFC reference

	; *** no more password

	PL_B	$dde4,$FF

	; *** some other illegal calls (not reached, but...)

	;PL_NOP	$xx 181E,2
	;PL_NOP	$xx D9F0,2
	;PL_NOP	$xx 12DBE,$2

	; *** keyboard

	PL_PS	$1A1A,kb_int

	; keyboard timing

	PL_PS	$1A50,kb_delay

	; active loops
	
	PL_PSS	$142ca,soundtracker_loop,2
	PL_PSS	$142e0,soundtracker_loop,2
	PL_PSS	$14a5a,soundtracker_loop,2
	PL_PSS	$14a70,soundtracker_loop,2

    PL_PSS  $21a40,soundtracker_loop,2

	PL_PS	$0b784,d7_loop
	PL_PS	$0bf24,d7_loop
	PL_PS	$0c1c4,d7_loop

    PL_PS   $0cb4c,small_delay
    
	; infinite loop replaced by ILLEGAL just in case

	;PL_I	$xx 12A02

	; avoid "this is an illegal copy" message
	; this is the obvious check

	PL_NOP	$12d72,4

    ; this is the sneaky check. Happens when completing a level, completing a full level
    ; and trying to go the the next one: this is an illegal copy...
    ; Example: enter VIGOGG or NOOVAT, skip level, climb tree
    ; play/skip all sea levels. At the interlude, this crap code is called and destroys
    ; some code/replaces by a jump to another "this is an illegal copy..." when entering
    ; the yin-yang level
    ; this is really stealthy: you have to complete one entire level set without passwords
    ; to trigger it.
    ;
    ; there are shorter ways to reproduce the error too. But never mind, we got this :)
    
    PL_PS   $12bca,unpack_data_hook_ntsc
    
    
	; SMC (JSR to modified locations)

    PL_W    $020fc,$4E4F
	PL_W	$10262,$4E4F
	PL_W	$1037e,$4E4F
	PL_W	$10384,$4E4F

    PL_IFC1X    0
    PL_NOP  $c13a,4  ; infinite attempts
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $01bd4,6    ; same address as PAL
    PL_ENDIF

	PL_END


unpack_data_hook_pal:
    JSR	$12b1e
    ; now a hidden checksum code may have been loaded at some point
    cmp.l   #$4A586716,$00057F14
    beq.b   .bingo
    rts
    
.bingo:
    ; remove the stealthy checksum and its side-effects
    move.w  #$4E75,$00057F14
    bra _flushcache
    
unpack_data_hook_ntsc:
    JSR	$12bd2

    ; now a hidden checksum code may have been loaded at some point
    cmp.l   #$4A586716,$00057FDE
    beq.b   .bingo
    rts
    
.bingo:
    ; remove the stealthy checksum and its side-effects
    move.w  #$4E75,$00057FDE
    bra _flushcache
    

; corrects SMC $4EB9(address changing all the time)
; fixes color flashes

trap_jsr
	; first, recover from the trap (tricky)
	movem.l	A0/A1,-(A7)
	move.l	10(A7),A0	; return address
	lea	.jsraddr(pc),a1
	move.l	(A0)+,(a1)+	; address to JSR to
	move.l	a0,(a1)		; save return address
	lea	.dojsr(pc),a1
	move.l	a1,10(a7)	; modifies return address
	movem.l	(A7)+,A0/A1
	rte

	; once returned from trap, user mode, remembers addresses
.dojsr
	; push game original return address
	move.l	.jsraddr+4(pc),-(a7)
	; push SMC JSR address
	move.l	.jsraddr(pc),-(a7)
	rts

.jsraddr
	dc.l	0,0

small_delay
	move.l	d0,d7
	move.l	#2,d0
	bsr	beamdelay
	move.l	d7,d0
    rts
    
d7_loop
	move.l	d0,d7
	move.l	#1638,d0
	bsr	beamdelay
	move.l	d7,d0
	rts

soundtracker_loop
	moveq	#8,d0
	bsr	beamdelay
	rts


read_sectors
	movem.l	d0-d3/a0-a2,-(A7)

	sub.l	#$18,D1	; remove 2 first tracks
	and.w	#$FFFF,D2
	moveq	#0,d0
	moveq	#0,D3

	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.readnothing		; length=0: out

	exg.l	d0,d2

	exg.l	d0,d1

	ext.l	d0
	lsl.l	#7,d0
	lsl.l	#2,d0
	ext.l	d1
	lsl.l	#7,d1			;diskoffset
	lsl.l	#2,d1

	moveq.l	#1,d2	; disk number: always 1
	bsr	diskload

.readnothing
	movem.l	(a7)+,d0-d3/a0-a2
	moveq	#0,d7
	rts


kb_delay
	moveq	#2,d0
	bra	beamdelay

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

set_dmacon_main
	move.w	#$0200,$1D42.W
	move.w	#$87e0,($96,a6)
	rts

kb_int
	clr.b	$BFEC01
	move.l	D0,-(sp)
	ror.b	#1,D0
	not.b	D0
	cmp.b	_keyexit(pc),D0
	bne	.noquit

	; quit

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
.noquit
    

	cmp.b	#$5F,d0
	bne.b	.nolskip
    move.l  _trainer(pc),d0
    btst    #2,d0
    beq.b   .nolskip
	st.b	$14F6.W		; level completed flag
.nolskip
	move.l	(sp)+,D0
	rts

patch_main_pal:
	bsr	decrunch
		
	DO_PATCH	pl_main_pal
	jmp	$128B2
    
patch_main_ntsc:
	bsr	decrunch
	DO_PATCH	pl_main_ntsc
	jmp	$128B4

pl_main_pal
	PL_START
	PL_P	$128DC,jump_7e800_pal
	PL_END
pl_main_ntsc
	PL_START
	PL_P	$128DE,jump_7e800_ntsc
	PL_END

jump_7e800_pal:
	DO_PATCH	pl_7e800_pal
	jmp	$7E800
jump_7e800_ntsc:
	DO_PATCH	pl_7e800_ntsc
	jmp	$7E800

pl_7e800_pal
	PL_START
	PL_W	$128DC,$4EF9
	PL_L	$128DE,$7E800
;;	PL_P	$7E80C,jump_1876    ; useful?
;;	PL_P	$7E828,jump_1876    ; useful?
	PL_P	$7E836,jump_1876_pal    ; this JMP is used others may not be
	PL_END
    
pl_7e800_ntsc
	PL_START
	PL_W	$128DE,$4EF9
	PL_L	$128E0,$7E800
;;	PL_P	$7E80C,jump_1876    ; useful?
;;	PL_P	$7E828,jump_1876    ; useful?
	PL_P	$7E836,jump_1876_ntsc    ; this JMP is used others may not be
	PL_END

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

; remove a checksum in the intro!

remove_checksum_pal:
	cmp.l	#$0CB801FC,$43806
	bne	.nopatch
	move.w	#$21FC,$43806
	move.b	#$60,$4380E
	bsr	_flushcache
.nopatch
	JMP	$1BF8.W	; original
    
remove_checksum_ntsc:
	cmp.l	#$0CB801FC,$00043808
	bne	.nopatch
	move.w	#$21FC,$43808
	move.b	#$60,$43810
	bsr	_flushcache
.nopatch
	JMP	$1BF8.W	; original

format_sectors
	moveq	#0,d7
	rts

; < a0: source
; < a1: dest
	
decrunch:
	LEA	18(A0),A0		;025E: 41E80012
	MOVEQ	#-128,D2		;0262: 7480
	ADD.B	D2,D2			;0264: D402
	MOVE.B	(A0)+,D2		;0266: 1418
	ADDX.B	D2,D2			;0268: D502
	ADD.B	D2,D2			;026A: D402
	BRA	.lab_0028		;026C: 600000BA
.lab_000B:
	MOVE.B	(A0)+,D2		;0270: 1418
	ADDX.B	D2,D2			;0272: D502
	BRA.S	.lab_0015		;0274: 6030
.lab_000C:
	MOVE.B	(A0)+,D2		;0276: 1418
	ADDX.B	D2,D2			;0278: D502
	BRA.S	.lab_0018		;027A: 6044
.lab_000D:
	MOVE.B	(A0)+,D2		;027C: 1418
	ADDX.B	D2,D2			;027E: D502
	BRA.S	.lab_0019		;0280: 6044
.lab_000E:
	MOVE.B	(A0)+,D2		;0282: 1418
	ADDX.B	D2,D2			;0284: D502
	BRA.S	.lab_001A		;0286: 6046
.lab_000F:
	MOVE.B	(A0)+,D2		;0288: 1418
	ADDX.B	D2,D2			;028A: D502
	BRA.S	.lab_001C		;028C: 604C
.lab_0010:
	MOVE.B	(A0)+,D2		;028E: 1418
	ADDX.B	D2,D2			;0290: D502
	BRA.S	.lab_001D		;0292: 604C
.lab_0011:
	MOVE.B	(A0)+,D2		;0294: 1418
	ADDX.B	D2,D2			;0296: D502
	BRA.S	.lab_001E		;0298: 604C
.lab_0012:
	MOVE.B	(A0)+,D2		;029A: 1418
	ADDX.B	D2,D2			;029C: D502
	BRA.S	.lab_0020		;029E: 6052
.lab_0013:
	MOVEQ	#3,D0			;02A0: 7003
.lab_0014:
	ADD.B	D2,D2			;02A2: D402
	BEQ.S	.lab_000B		;02A4: 67CA
.lab_0015:
	ADDX	D1,D1			;02A6: D341
	DBF	D0,.lab_0014		;02A8: 51C8FFF8
	ADDQ	#2,D1			;02AC: 5441
.lab_0016:
	MOVE.B	(A0)+,(A1)+		;02AE: 12D8
	MOVE.B	(A0)+,(A1)+		;02B0: 12D8
	MOVE.B	(A0)+,(A1)+		;02B2: 12D8
	MOVE.B	(A0)+,(A1)+		;02B4: 12D8
	DBF	D1,.lab_0016		;02B6: 51C9FFF6
	BRA.S	.lab_0028		;02BA: 606C
.lab_0017:
	ADD.B	D2,D2			;02BC: D402
	BEQ.S	.lab_000C		;02BE: 67B6
.lab_0018:
	ADDX	D0,D0			;02C0: D140
	ADD.B	D2,D2			;02C2: D402
	BEQ.S	.lab_000D		;02C4: 67B6
.lab_0019:
	BCC.S	.lab_001B		;02C6: 640E
	SUBQ	#1,D0			;02C8: 5340
	ADD.B	D2,D2			;02CA: D402
	BEQ.S	.lab_000E		;02CC: 67B4
.lab_001A:
	ADDX	D0,D0			;02CE: D140
	CMPI.B	#$09,D0			;02D0: 0C000009
	BEQ.S	.lab_0013		;02D4: 67CA
.lab_001B:
	ADD.B	D2,D2			;02D6: D402
	BEQ.S	.lab_000F		;02D8: 67AE
.lab_001C:
	BCC.S	.lab_0022		;02DA: 641A
	ADD.B	D2,D2			;02DC: D402
	BEQ.S	.lab_0010		;02DE: 67AE
.lab_001D:
	ADDX	D1,D1			;02E0: D341
	ADD.B	D2,D2			;02E2: D402
	BEQ.S	.lab_0011		;02E4: 67AE
.lab_001E:
	BCS.S	.lab_002E		;02E6: 656E
	TST	D1			;02E8: 4A41
	BNE.S	.lab_0021		;02EA: 6608
	ADDQ	#1,D1			;02EC: 5241
.lab_001F:
	ADD.B	D2,D2			;02EE: D402
	BEQ.S	.lab_0012		;02F0: 67A8
.lab_0020:
	ADDX	D1,D1			;02F2: D341
.lab_0021:
	ROL	#8,D1			;02F4: E159
.lab_0022:
	MOVE.B	(A0)+,D1		;02F6: 1218
	MOVEA.L	A1,A2			;02F8: 2449
	SUBA	D1,A2			;02FA: 94C1
	SUBQ	#1,A2			;02FC: 534A
	LSR	#1,D0			;02FE: E248
	BCC.S	.lab_0023		;0300: 6402
	MOVE.B	(A2)+,(A1)+		;0302: 12DA
.lab_0023:
	SUBQ	#1,D0			;0304: 5340
	TST	D1			;0306: 4A41
	BNE.S	.lab_0025		;0308: 660C
	MOVE.B	(A2),D1			;030A: 1212
.lab_0024:
	MOVE.B	D1,(A1)+		;030C: 12C1
	MOVE.B	D1,(A1)+		;030E: 12C1
	DBF	D0,.lab_0024		;0310: 51C8FFFA
	BRA.S	.lab_0028		;0314: 6012
.lab_0025:
	MOVE.B	(A2)+,(A1)+		;0316: 12DA
	MOVE.B	(A2)+,(A1)+		;0318: 12DA
	DBF	D0,.lab_0025		;031A: 51C8FFFA
	BRA.S	.lab_0028		;031E: 6008
.lab_0026:
	MOVE.B	(A0)+,D2		;0320: 1418
	ADDX.B	D2,D2			;0322: D502
	BCS.S	.lab_002A		;0324: 650E
.lab_0027:
	MOVE.B	(A0)+,(A1)+		;0326: 12D8
.lab_0028:
	ADD.B	D2,D2			;0328: D402
	BCS.S	.lab_0029		;032A: 6506
	MOVE.B	(A0)+,(A1)+		;032C: 12D8
	ADD.B	D2,D2			;032E: D402
	BCC.S	.lab_0027		;0330: 64F4
.lab_0029:
	BEQ.S	.lab_0026		;0332: 67EC
.lab_002A:
	MOVEQ	#2,D0			;0334: 7002
	MOVEQ	#0,D1			;0336: 7200
	ADD.B	D2,D2			;0338: D402
	BEQ.S	.lab_0031		;033A: 672C
.lab_002B:
	BCC	.lab_0017		;033C: 6400FF7E
	ADD.B	D2,D2			;0340: D402
	BEQ.S	.lab_0032		;0342: 672A
.lab_002C:
	BCC.S	.lab_0022		;0344: 64B0
	ADDQ	#1,D0			;0346: 5240
	ADD.B	D2,D2			;0348: D402
	BEQ.S	.lab_0033		;034A: 6728
.lab_002D:
	BCC.S	.lab_001B		;034C: 6488
	MOVE.B	(A0)+,D0		;034E: 1018
	BEQ.S	.lab_0036		;0350: 6734
	ADDQ	#8,D0			;0352: 5040
	BRA.S	.lab_001B		;0354: 6080
.lab_002E:
	ADD.B	D2,D2			;0356: D402
	BEQ.S	.lab_0034		;0358: 6720
.lab_002F:
	ADDX	D1,D1			;035A: D341
	ORI	#$0004,D1		;035C: 00410004
	ADD.B	D2,D2			;0360: D402
	BEQ.S	.lab_0035		;0362: 671C
.lab_0030:
	BCS.S	.lab_0021		;0364: 658E
	BRA.S	.lab_001F		;0366: 6086
.lab_0031:
	MOVE.B	(A0)+,D2		;0368: 1418
	ADDX.B	D2,D2			;036A: D502
	BRA.S	.lab_002B		;036C: 60CE
.lab_0032:
	MOVE.B	(A0)+,D2		;036E: 1418
	ADDX.B	D2,D2			;0370: D502
	BRA.S	.lab_002C		;0372: 60D0
.lab_0033:
	MOVE.B	(A0)+,D2		;0374: 1418
	ADDX.B	D2,D2			;0376: D502
	BRA.S	.lab_002D		;0378: 60D2
.lab_0034:
	MOVE.B	(A0)+,D2		;037A: 1418
	ADDX.B	D2,D2			;037C: D502
	BRA.S	.lab_002F		;037E: 60DA
.lab_0035:
	MOVE.B	(A0)+,D2		;0380: 1418
	ADDX.B	D2,D2			;0382: D502
	BRA.S	.lab_0030		;0384: 60DE
.lab_0036:
	ADD.B	D2,D2			;0386: D402
	BNE.S	.lab_0037		;0388: 6604
	MOVE.B	(A0)+,D2		;038A: 1418
	ADDX.B	D2,D2			;038C: D502
.lab_0037:
	BCS.S	.lab_0028		;038E: 6598
	RTS				;0390: 4E75




;--------------------------------

_resload	dc.l	0		;address of resident loader


version
	dc.l	0

save_name:
	dc.b	"saves",0
hisc_name:
	dc.b	"highs",0
_tag		dc.l	WHDLTAG_CUSTOM1_GET
_trainer:
        dc.l    0
		dc.l	0
