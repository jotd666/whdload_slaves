;*---------------------------------------------------------------------------
;  :Program.	BoppinHD.asm
;  :Contents.	Slave for "Boppin"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BoppinHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;CHIP_ONLY
	IFD BARFLY
	OUTPUT	"TestDrive.slave"
	IFND	CHIP_ONLY
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


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $A0000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $20000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

FONTHEIGHT	= 8

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
;CACHECHIPDATA
CACHE
SEGTRACKER

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.0b"
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
	dc.b	0

_tdboot
	dc.b	"TEST DRIVE",0

slv_name		dc.b	"Test Drive"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1987 Accolade",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

sysconf:
	dc.b	"devs/system-configuration",0
	; if this file is missing then game get strange fonts
	; and even crashes
sysconf_error:
	dc.b	"File devs/system-configuration is missing!",0
program:
	dc.b	"TD",0
args		dc.b	"p",10
args_end
	dc.b	0
slv_config
	dc.b "C2:B:Enhanced framerate;"
	IFD VERIFY
	dc.b "C1:X:automatic recovery verification:1;C1:X:five field simulation verification:2;C1:X:original blitter interrupts verification:3;"
	dc.b "C3:B:reproducible verification RNG;"
	dc.b "C4:B:slow drawing verification;"
	dc.b "C5:X:scripted player race:0;C5:X:force crash:1;C5:X:force radar:2;C5:X:straight acceleration braking tape:4;"
	ENDC
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

_bootdos
		clr.l	$0.W

		
        lea    old_kbint(pc),a1
        lea kbint_hook(pc),a0
        cmp.l   (a1),a0
        beq.b   .done
        move.l  $68.W,(a1)
        move.l  a0,$68.W
.done
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload
		lea		sysconf(pc),a0
		jsr		resload_GetFileSize(a2)
		tst.l	d0
		bne.b	.scok
	pea	sysconf_error(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	_resload(pc),a0
	jmp	resload_Abort(a0)
		
.scok
	bsr		get_version
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_tdboot(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_main
	movem.l	D0-A6,-(A7)
	bsr sim_init
	IFD VERIFY
	bsr verify_init
	ENDC
	move.l  d7,A1
	lea	_patchlist_1(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(A2)
    bsr	_patch_trackdisk
	movem.l	(A7)+,D0-A6
	rts

; for version 1, size 90112

_patchlist_1:
	PL_START
    PL_P $06390,overlay_unload_end
    PL_P $06916,overlay_load_end
	PL_R	$1D10	; dma stuff
	PL_R	$1CBC	; dma/drive stuff
	PL_L	$434,$DFF002
	PL_L	$444,$DFF096
	PL_S	$59A,$52
	PL_PS	$00188a,read_joydat
	PL_PS	$00541a,read_joydat
    PL_PS   $005402,read_fire1
    PL_PS   $001872,read_fire1

	IFD VERIFY
	PL_IFC3
	; Intro RNG call counts vary with CPU speed. Reset at demo selection too,
	; so all profiling CPUs start with the same car and subsequent RNG state.
	PL_PS $00230,verify_demo_rng
	PL_ENDIF
	PL_IFC4
	; VERIFY_RANGE root 07aaa 8 C4 verify_slow_view
	PL_PSS $07aaa,verify_slow_view,2
	PL_ENDIF
	ENDC
    ; C2 removes beam entropy in normal builds too. C3 retains its independent
    ; original-game fixture when C2 is off. Both branches install identical bytes.
    PL_IFC2
    PL_L $05314,$397C1234
    PL_L $05318,$9BD84E71
    PL_W $05334,$4240
    PL_NOP $05336,4
    IFD VERIFY
    PL_ELSE
    PL_IFC3
    PL_L $05314,$397C1234
    PL_L $05318,$9BD84E71
    PL_W $05334,$4240
    PL_NOP $05336,4
    PL_ENDIF
    ENDC
    PL_ENDIF
	PL_END

	IFD VERIFY
verify_demo_rng:
	move.w #$1234,-25640(a4)
	jsr -32442(a4)            ; displaced TD:$230, original RNG entry
    move.l d1,-(sp)
    move.l verify_c5(pc),d1
    btst #0,d1
    beq.b .car_done
    lsr.l #8,d1              ; VERIFY C5 bits 8..10: car 0..4
    and.w #7,d1
    cmp.w #4,d1
    bhi.b .car_done
    move.w d1,d0            ; original caller keeps low word and takes modulo 5
.car_done
    move.l (sp)+,d1
	swap d0                  ; displaced TD:$234
	rts
	ENDC

; The Aztec overlay manager rewrites executable BSR/JMP stubs in the data
; hunk after DOS LoadSeg has flushed the caches. Flush again after both
; completed rewrites, before returning to a stub that may still be cached.
; _flushcache uses resload_FlushCache, which preserves all registers and
; handles the 68040/060 data and instruction caches as well as older CPUs.
overlay_unload_end:
    bsr _flushcache
    movem.l (a7)+,a2-a3/a6    ; displaced TD:06390
    rts

overlay_load_end:
    movem.l (a7)+,d0-d2/a0-a4 ; displaced TD:06916
	IFD VERIFY
    bsr verify_overlay_loaded
	ENDC
    bsr sim_overlay_loaded
    bsr _flushcache
    rts

_patch_trackdisk
	movem.l	D0-A6,-(A7)
	lea	_trackdisk_device(pc),A0
	tst.l	(A0)
	bne.b	.out		; already patched
	lea	_trdname(pc),A0

	move.l	$4.W,A6

	lea	-$30(A7),A7
	move.l	A7,A1
	moveq	#0,D0
	moveq	#0,D1
	jsr	_LVOOpenDevice(A6)
	
	lea	_trackdisk_device(pc),A1
	move.l	IO_DEVICE(A7),(A1)		; save trackdisk device pointer

	lea	$30(A7),A7

	move.l	$4.W,A0
	add.w	#_LVODoIO+2,a0
	lea	_doio_save(pc),a1
	move.l	(a0),(a1)
	lea	_doio(pc),a1
	move.l	a1,(a0)
	move.l	$4.W,A0
	add.w	#_LVOSendIO+2,a0
	lea	_sendio_save(pc),a1
	move.l	(a0),(a1)
	lea	_sendio(pc),a1
	move.l	a1,(a0)

.out
	movem.l	(A7)+,D0-A6

	rts


_doio:
	move.l	_trackdisk_device(pc),D0
	cmp.l	IO_DEVICE(A1),D0
	bne.b	.org
	bra.b	.skipit		; skip accesses to trackdisk device
	move.w	$1C(A1),D0
	cmp.w	#$800A,D0	; seek
	beq.b	.skipit
;	cmp.w	#$00A,D0	; seek
;	beq.b	.skipit
.org
	move.l	_doio_save(pc),-(A7)
	rts
.skipit:
	clr.b	$1F(A1)
	moveq.l	#0,D0
	rts

_sendio:
	move.l	_trackdisk_device(pc),D0
	cmp.l	IO_DEVICE(A1),D0
	bne.b	.org
	move.w	$1C(A1),D0
	cmp.w	#$800A,D0	; seek
	beq.b	.skipit
;	cmp.w	#$00A,D0	; seek
;	beq.b	.skipit
.org
	move.l	_sendio_save(pc),-(A7)
	rts
.skipit:
	clr.b	$1F(A1)
	moveq.l	#0,D0
	rts

read_fire1:
    MOVE.B  $00BFE001,D0
    move.l  a0,-(a7)
    lea keyboard_table(pc),a0
    tst.b   ($40,a0)    ; space key
    beq.b   .no_space
    bclr    #7,d0
.no_space    
    move.l  (a7)+,a0
	IFD VERIFY
    bsr verify_fire
	ENDC
    rts

read_fire2:
     move.w d0,-(a7)
     bsr    read_fire1
     btst   #7,d0
     movem.w    (a7)+,d0
     rts
	 
read_joydat
    move.w  _custom+joy1dat,d0
    move.l  a0,-(a7)
    lea keyboard_table(pc),a0
    tst.b   ($4C,a0)    ; up key
    beq.b   .no_up
	; set UP
	bset	#8,d0
	bclr	#9,d0
    bra.b   .no_down
.no_up    
    tst.b   ($4D,a0)    ; down key
    beq.b   .no_down
	; set DOWN
	bset	#0,d0
	bclr	#1,d0
.no_down    
    tst.b   ($4F,a0)    ; left key
    beq.b   .no_left
	; set LEFT
	bset	#9,d0
    tst.b   ($4C,a0)    ; up key
    bne.b   .diag_left_up
    bset    #8,d0
    bra.b   .no_right
.diag_left_up
	bclr	#8,d0
    bra.b   .no_right    
.no_left
    tst.b   ($4E,a0)    ; right key
    beq.b   .no_right
	; set RIGHT
	bset	#1,d0
    tst.b   ($4D,a0)    ; down key
    bne.b   .diag_right_down
    bset    #0,d0
    bra.b   .no_right    
.diag_right_down
	bclr	#0,d0
    
.no_right   
    move.l  (a7)+,a0
	IFD VERIFY
    bsr verify_joy
	ENDC
    rts
	
get_version:
	movem.l	d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#90112,D0
	beq.b	.crack


	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.crack
	moveq	#1,d0
	bra.b	.out
.alt
	moveq	#2,d0
	bra	.out
.out
	movem.l	(a7)+,d1/a1
	rts
	even


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
	movem.l	d2/d7/a4,-(a7)


	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
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
	bsr render_interrupt_option
	jsr	(4,a3)		; call program
	bsr render_interrupt_restore
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

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0
_trackdisk_device:
	dc.l	0
_doio_save:
	dc.l	0
_sendio_save:
	dc.l	0

    
kbint_hook:
    movem.l  a5/d0,-(a7)
	LEA	$00BFD000,A5
    ; we can't test this as this clears ICR and fucks up ROM code
;	MOVEQ	#$08,D0
;	AND.B	$1D01(A5),D0
;	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
    ror.b   #1,d0
    not.b   d0
    and.w   #$FF,d0
    lea keyboard_table(pc),a5
    bclr    #7,d0
    seq (a5,d0.w) ; D1 = $FF if key up

.nokey    
    movem.l  (a7)+,a5/d0
    
    move.l  old_kbint(pc),-(a7)
    rts
    
keyboard_table:
    ds.b    $100,0
        
old_kbint:
    dc.l    0
	
_trdname:
	dc.b	"trackdisk.device",0
	even

;============================================================================

	include "simulation.s"
	include "render.s"
	IFD VERIFY
	include "simulation-verify.s"
	ENDC

	END
