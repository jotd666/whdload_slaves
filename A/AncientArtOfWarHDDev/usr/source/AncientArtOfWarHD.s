
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;DEBUG
	IFD BARFLY
	OUTPUT	"AncientArtOfWar.slave"
	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;CHIPONLY

	IFD	CHIPONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

DOSASSIGN

;DISKSONBOOT
;INITAGA
HDINIT
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoKbd
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_config:
	dc.b	"BW;"
	dc.b    "C3:B:Enable english translation;"
	dc.b	0
	
slv_name		dc.b	"Ancient Art Of War"
	IFD	CHIPONLY
	dc.b	" (CHIPONLY MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1990 Broderbund",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"war.prg",0
args		dc.b	10
args_end
	dc.b	0
data_assign
	dc.b	"data",0
	
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	data_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	check_version 
	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_exe(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)
		
check_version:
	movem.l	d0-d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	moveq.l	#1,d1
	cmp.l	#138032,D0	; french
	beq.b	.ok
	moveq.l	#2,d1
	cmp.l	#137868,D0	; spanish
	beq.b	.ok
	cmp.l	#0,D0
	beq.b	.ok		; let LoadSeg fail if file not found


	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok
	lea	_version(pc),a1
	move.l	d1,(a1)
	movem.l	(a7)+,d0-d1/a1
	rts
; < d7: seglist (APTR)

patch_exe
	patch	$100,_wait_button
	
	move.l	(_resload,pc),a2
	move.l	_version(pc),d0
	cmp.l	#1,d0
	beq.b	.fr
	lea	pl_main_sp(pc),a0
	bra.b	.do
	
.fr
	moveq.l	#1,d2
	bsr		get_section
	add.l	#$17F6-$910,a1
	lea	flag_address(pc),a0
	move.l	(a1),(a0)

	moveq.l	#3,d2
	bsr		get_section
	move.l	a1,a3
	add.l	#$29DFC-$4764,a3
	lea	key_pressed_address(pc),a0
	move.l	a3,(a0)
	
	lea	bitplane_pointer_address(pc),a0
	move.l	a1,(a0)+
	addq.l	#4,a1
	move.l	a1,(a0)

	lea	pl_main_fr(pc),a0
.do
	move.l	d7,a1
	jsr	(resload_PatchSeg,a2)

	rts

; < d7 seglist (BPTR!!!)
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	dbf	d2,.loop
.out
	addq.l	#4,a1
	rts
	
pl_main_fr
	PL_START
	; quit to WB using original quit button
	PL_P	$15C,_quit
	; password protection
	PL_L	$3106E,$600000A8
	; button wait for title
	PL_IFBW
	PL_L	$30D64,$4EB80100
	PL_ENDIF
	; always tell the program that the original disk is in drive
	;;PL_NOP	$3458A,2
	
	; -- hacks to avoid overwriting the original disk
	; -- and to detect a writable non original DATA disk
	; -- those involve trackdisk.device and CIA A/B read...
	
	; routine that tells if the original disk is in drive
	; (calls lower level +$3D88E routine)
	;;PL_P $34244,really_check_if_original_disk_in_drive
	; force game to believe that DATA disk is in drive
	PL_B	$34664,$60
	
	PL_P	$3D88E,is_original_disk_in_drive
	PL_P	$3D904,check_floppy_write_protection
	
	; self-modifying code
	PL_P	$3D5E6,cache_flush
	; keyboard
	PL_PSS	$3D56C,kb_delay,10

	; cpu dependent loop (I was lucky to find that one!)
	PL_P	$3DAB2,_delay_loop
	; programming error: wrong system base (exec instead of intuition)
	; leads to a GURU but only with fastmem at some addresses
	; (works on WinUAE because fastmem addresses are $1xxxxxxx
	; whereas on my config fastmem addresses are $79xxxxxx)
	;
	; very weird bug, I had the same type of trouble with Gee Bee Air Rally
	;
	PL_R	$3D4EE
	
	PL_IFC3
	; install copperlist
	PL_PSS	$3D2EE,install_copperlist,4
	
	PL_P	$3CE98,end_image_display
	
	; status bar icon replacement (cancel route)
	PL_PS	$3E4E4,intercept_icon_status_copy
	; status bar icon replacement (clear message)
	PL_PS	$3E4F0,intercept_icon_status_copy_2
	; fighter & others icon replacement
	PL_PSS	$17F4,intercept_panel_copy,2
	
	; ouest/west text: disabled as it trashes the display???
	;;PL_P	$2A422,intercept_west
		
	PL_PSS	$35568,you_lost_image_display,6
	PL_ENDIF
	
	PL_END
	
wait_keypress:
	movem.l	D0/a0,-(a7)
	move.l	key_pressed_address(pc),a0
.nopress
	tst.w	(a0)
	beq.b	.nopress
	; here we add a "wait for release" loop
.norelease
	tst.w	(a0)
	bne.b	.norelease
	
	movem.l	(a7)+,d0/a0
	rts
	
kb_delay:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
	rts

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
	
intercept_west:
	movem.l	a0-a3,-(a7)
	move.l	bitplane_pointer_address(pc),a3
	bsr	.w
	move.l	bitplane_pointer_address+4(pc),a3
	bsr	.w
	movem.l	(a7)+,a0-a3
	ADDQ	#8,A7			;2A422: 504F
	MOVEM.L	(A7)+,D2-D7		;2A424: 4CDF00FC
	RTS				;2A428: 4E75
.w
	move.l	(a3),a3
	move.b	(13661,a3),d0

	cmp.b	#$97,d0
	bne.b	.no_west
	lea	west_icon(pc),a0
	lea	(13661,a3),a1
	bsr	paste_image

.no_west
	rts
	
intercept_icon_status_copy_2:
	movem.l	a0-a3,-(a7)
	; +7508+0,+7508+8000 ... : F000 0000 F000 0000 1000 0000 01CE 73D0  (efface message)
	; +7508+0,+7508+8000 ... : F020 0000 F020 4020 1240 4021 0060 0000  (another icon)
	move.l	bitplane_pointer_address(pc),a3
	bsr	.replace_clear_message
	move.l	bitplane_pointer_address+4(pc),a3
	bsr	.replace_clear_message
	movem.l	(a7)+,a0-a3
	
	; original
	MOVE.B	(A4),D0			;3E4F0: 1014
	CMPI.B	#$FF,D0			;3E4F2: 0C0000FF
	rts
	
.replace_clear_message	
	move.l	(a3),a3
	cmp.l	#$01CE73D0,(7508+24000,A3)
	bne.b	.no_clear_message
	lea	clear_message_icon(pc),a0
	lea	(7508,a3),a1
	lea	-280(a1),a1
	bsr	paste_image
.no_clear_message
	rts
	

	; < A0: screen bitplanes
intercept_panel_copy:
	movem.l	d0/a0-a3,-(a7)
	
	bsr	replace_fighter_labels
	
.wait
	move.l	flag_address(pc),a0	; changes CCR fpr the net test
	tst	(a0)
	beq.b	.wait
	movem.l	(a7)+,d0/a0-a3
	rts
	
replace_fighter_labels:
	move.l	bitplane_pointer_address(pc),a1
	move.l	(a1),a3
	move.b	(2811,a3),d0
	cmp.b	#$32,d0
	bne.b	.no_panel_1
	bsr	.p
	move.l	bitplane_pointer_address+4(pc),a1
	move.l	(a1),a3
	bsr	.p
	rts
.no_panel_1
	cmp.b	#$90,d0
	bne.b	.no_panel_2
	move.l	bitplane_pointer_address(pc),a1
	move.l	(a1),a3
	bsr	.p2
	move.l	bitplane_pointer_address+4(pc),a1
	move.l	(a1),a3
	bsr	.p2
	
	nop
	
.no_panel_2
	rts
.p2:
	; static "when moving"
	lea	(135*40+12,a3),a1
	lea when_moving_icon(pc),a0
	bsr	paste_image
	lea	(40*8+2,a1),a1
	lea march_icon(pc),a0
	bsr	paste_image


	lea	(5056,a3),a1
	lea	(-122,a1),a2
	cmp.l	#$C30F7F00,(a1)
	bne.b	.no_stopped
	lea	stopped_icon(pc),a0
	move.l	a2,a1
	bsr	paste_image
	bra	.smcont
.no_stopped
	cmp.l	#$37C10F00,(a1)
	bne	.smcont
	lea	marching_icon(pc),a0
	move.l	a2,a1
	bsr	paste_image
.smcont
	lea	(6336,a3),a1
	lea	(-202,a1),a2
	move.w	(a1),d0
	cmp.w	#$6777,d0
	bne.b	.no_speed_slow
	lea	moving_slow_icon(pc),a0
	move.l	a2,a1
	bsr	paste_image
	bra.b	.speed_end
.no_speed_slow
	cmp.w	#$FBEE,d0
	bne.b	.no_speed_veryslow
	lea	moving_very_slow_icon(pc),a0
	move.l	a2,a1
	bsr	paste_image
	bra.b	.speed_end
.no_speed_veryslow
	cmp.w	#$FDDD,d0
	bne.b	.no_speed_fast
	lea	moving_fast_icon(pc),a0
	move.l	a2,a1
	bsr	paste_image
.no_speed_fast

.speed_end
	rts
	
.p
	lea	(2811,a3),a1
	lea	fighter_1_icon(pc),a0
	bsr	paste_image	
	add.l	#65*40+1,a1
	lea	fighter_2_icon(pc),a0
	bsr	paste_image
	add.l	#9,a1
	lea	fighter_3_icon(pc),a0
	bsr	paste_image
	rts
intercept_icon_status_copy:
	MOVE	-2(A6),D1		;3E4E4: 322EFFFE
	MOVEQ	#1,D2			;3E4E8: 7401
	; A1 is the pointer on the first bitplane (double buffering is used)
	movem.l	D0/a0-a3,-(a7)
	move.l	a1,a3	; save A1
	; cancel route OK
	move.l	a3,a1
	lea	(180*40+$D8,a1),a1
	cmp.w	#$4A52,(a1)
	bne.b	.no_cancel_route
	lea	cancel_route_icon(pc),a0
	sub.l	#161,a1	; adjust to start
	bsr	paste_image
.no_cancel_route
	movem.l	(a7)+,d0/a0-a3
	rts
	
; < A1: dest
; < A0: image X.W, Y.W, data
paste_image:
	movem.l	d0-d4/a0-a3,-(a7)
	move.l	a0,a2
	addq.l	#4,a2
	moveq.l	#3,d2	; number of planes
	move.w	(a0),d0	; bytes width
	move.w	d0,d3
	move.l	a1,a3
.nextp
	move.l	a3,a1
	move.w	(2,a0),d1	; height
	subq.w	#1,d1
.copyy
	move.w	d3,d0	; bytes width
	subq.w	#1,d0
.copyx
	move.b	(a2)+,(a1)+
	dbf	d0,.copyx
	; next line
	add.l	#40,a1
	sub.w	d3,a1
	dbf	d1,.copyy
	
	add.l #8000,a3	; planesize
	dbf	d2,.nextp
	movem.l	(a7)+,d0-d4/a0-a3
	rts
	
you_lost_image_display
	movem.l	a0-a3,-(a7)	
	move.l	bitplane_pointer_address+4(pc),a1
	move.l	(a1),a1
	lea	(5+38*40,a1),a1
	lea	stats(pc),a0
	bsr	paste_image
.lmb
	btst	#6,$bfe001
	bne.b	.lmb
.lmbr
	btst	#6,$bfe001
	beq.b	.lmbr
	movem.l	(a7)+,a0-a3
	rts
	
end_image_display:
	lea	-$7D00(a4),a4
	cmp.l	#$06E7CEE7,($1040,a4)
	bne.b	.noloadingpic
	
	move.l	_resload(pc),a2
	lea	.ukloadingpicname(pc),a0
	move.l	a4,a1
	jsr	(resload_LoadFileDecrunch,a2)
.noloadingpic
	cmp.l	#$FEB0007F,(a4)
	bne.b	.notitle
	cmp.l	#$FFFC00FF,(4,a4)
	bne.b	.notitle
	move.l	_resload(pc),a2
	lea	.ukpicname(pc),a0
	move.l	a4,a1
	jsr	(resload_LoadFileDecrunch,a2)
.notitle

	MOVEM.L	(A7)+,D0-D4/A0-A5	;3CE98: 4CDF3F1F
	UNLK	A6			;3CE9C: 4E5E
	RTS				;3CE9E: 4E75
.ukpicname
	dc.b	"aaow_title.raw",0
.ukloadingpicname:
	dc.b	"aaow_loading.raw",0
	even
install_copperlist:
	MOVE.L	A0,128(A1)		;3D2EE: 23480080
	MOVE	#$0000,136(A1)		;3D2F2: 337C00000088
	RTS
	
pl_main_sp
	PL_START
	; quit to WB using original quit button
	PL_P	$15C,_quit
	; password protection, not found yet, maybe the version I have is cracked?
	;;PL_L	$3106Exxxxxxxxxxx,$600000A8
	; button wait for title
	PL_IFBW
	PL_L	$30cc4,$4EB80100
	PL_ENDIF
	; always tell the program that the original disk is in drive
	;;PL_NOP	$3458A,2
	
	; -- hacks to avoid overwriting the original disk
	; -- and to detect a writable non original DATA disk
	; -- those involve trackdisk.device and CIA A/B read...
	
	; routine that tells if the original disk is in drive
	; (calls lower level is_original_disk_in_drive routine)
	;;PL_P $34244xxxxxxxxxxxxx,really_check_if_original_disk_in_drive
	; force game to believe that DATA disk is in drive
	PL_B	$343fe,$60
	; file loader/file hardware checker (what's the bloody purpose?)
	PL_P	$3d790,is_original_disk_in_drive
	PL_P	$3d806,check_floppy_write_protection
	
	; cpu dependent loop (I was lucky to find that one!)
	PL_P	$3d9b6,_delay_loop
	
	;	this seems unreachable from the spanish version
	;   since it does nothing useful, it's for the best
	PL_R	$3d41c
	
	; self-modifying code
	;;PL_P	$3D5E6xxx,cache_flush
	; keyboard
	PL_PSS	$3d4ae,kb_delay,10

	PL_END
	
cache_flush:
	MOVE	#$8020,154(A5)		;3D5E6: 3B7C8020009A
	bra	_flushcache
	
	
check_floppy_write_protection
	moveq	#1,d0	; unprotected
	rts
really_check_if_original_disk_in_drive
	moveq	#1,d0	; original
	rts
is_original_disk_in_drive
	moveq	#1,d0	; original
	rts

; < D0: numbers of vertical positions to wait
_beam_delay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	subq.l	#1,d0
	bne.b	.bd_loop1
	rts


_wrong_version:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

_wait_button
.bw
	btst	#6,$BFE001
	bne.b	.bw

	move.l	(A7)+,d0	; trash D0, we don't care
	pea	1402.W		; original code
	move.l	D0,-(a7)	; original return address
	rts

_delay_loop
	LINK	A6,#0			;3DAB2: 4E560000
	move.l	D0,-(a7)
	move.l	8(A6),d0
	divu.w	#$10,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	_beam_delay

	move.l	(a7)+,d0
	UNLK	A6			;3DAC8: 4E5E
	RTS				;3DACA: 4E75


		
; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/a4,-(a7)
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3
	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

	;remove exe

	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
_version
	dc.l	0
tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0
		
; address of a "window is closed / event" stuff from the game
flag_address
	dc.l	0
bitplane_pointer_address
	dc.l	0,0
key_pressed_address
	dc.l	0
	
cancel_route_icon:
	incbin	"cancel_route.raw"
clear_message_icon:
	incbin	"clear_message.raw"
fighter_1_icon:
	incbin	"barbarian.raw"
fighter_2_icon:
	incbin	"spy.raw"
fighter_3_icon:
	incbin	"warrior.raw"
when_moving_icon:
	incbin	"when_moving.raw"
moving_very_slow_icon:
	incbin	"very_slow.raw"
moving_slow_icon:
	incbin	"slow.raw"
moving_fast_icon:
	incbin	"fast.raw"
west_icon:
	incbin	"west.raw"
march_icon:
	incbin	"march.raw"
stopped_icon:
	incbin	"stopped.raw"
marching_icon:
	incbin	"marching.raw"
stats:
	incbin	"stats.raw"
	
;============================================================================

	END
