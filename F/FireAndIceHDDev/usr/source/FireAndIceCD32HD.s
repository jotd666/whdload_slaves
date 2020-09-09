;*---------------------------------------------------------------------------
;  :Program.	FireAndIceCD32HD.asm
;  :Contents.	Slave for "FireAndIceCD32"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: FireAndIceCD32HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/intuition.i


;CHIP_ONLY

	IFD BARFLY
	OUTPUT	"FireAndIceCD32.slave"

	IFND	DEBUG
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	ENDC

	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0
HRTMON
	ELSE
CHIPMEMSIZE	= $1E0000
FASTMEMSIZE	= $40000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %1111

;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
INITAGA
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

QUIT_JOYPAD_MASK = JPF_BUTTON_FORWARD|JPF_BUTTON_REVERSE|JPF_BUTTON_PLAY

DUMMY_CD_DEVICE = 1
;USE_DISK_LOWLEVEL_LIB
;USE_DISK_NONVOLATILE_LIB

; pal: +$013a4 train start level << 2 ($4: first world, $8 second, $C third, $10 fourth)
; seg0 +$cc02: nop any number of keys
;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"3.4"
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
slv_name		dc.b	"Fire And Ice CD³²"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
	dc.b	0
slv_copy	dc.b	"1992 Graftgold",0
slv_info	dc.b	"Install/fix by Harry/JOTD",10,10
			dc.b	"Joypad emulation keys",10,10
			dc.b	"F5: options screen",10
			dc.b	"Space: weapon",10
			dc.b	"P: pause",10
			dc.b	"ESC (while paused): give up game",10,10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
        dc.b    "C1:X:Trainer Infinite lives:0;"
        dc.b    "C1:X:Trainer Exit with incomplete key:1;"
        dc.b    "C2:B:blue/second button jumps;"
        dc.b    "C3:L:train start level:None,1,2,3,4,5,6,7;"
		dc.b	0
assign
	dc.b	"fire",0

_exename_pal:
	dc.b	"firepal",0
_exename_ntsc:
	dc.b	"firentsc",0
_args		dc.b	10
_args_end
	dc.b	0
lowlname:
    dc.b    "lowlevel.library",0    
	EVEN

; +$0542 read joy port 1 routine (firepal)
;============================================================================

	;initialize kickstart and environment

_bootdos
	; configure the button emulation

	bsr	_patch_cd32_libs

	IFND	USE_DISK_LOWLEVEL_LIB
	lea	OSM_JOYPAD1KEYS(pc),a0
	move.w	#$4019,2(a0)	; SPACE = bomb, P = pause
	move.w	#$4545,4(a0)	; both charcoal: ESC so ESC quits the game in pause mode

	move.l	_resload(pc),a2		;A2 = resload
    lea	(tag,pc),a0
    jsr	(resload_Control,a2)

    movem.l (a7)+,a6    
	ENDC


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load program

		lea	_exename_pal(pc),A0
		move.l	_monitor(pc),d0
		cmp.l	#PAL_MONITOR_ID,d0
		beq.b	.load
        ;;move.w  $0,$DFF1DC  ; force NTSC
		lea	is_ntsc(pc),a0
		move.w	#1,(a0)
		lea	_exename_ntsc(pc),A0
.load

	;load exe
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist

patch_exe:
	move.l	d7,a1
	add.l	#4,a1

	IFD	CHIP_ONLY
	move.l	a1,$100.W	; TEMP debug
	ENDC
    move.l trainer_start_level(pc),d0
    ; damn Andrew shifted level count so it was already optimized for
    ; (ax,dy) addressing probably. Result: harder to find too.
    lsl #2,d0      
    move.w  d0,($13A4,a1)       ; address is the same for both executables
	
	lea	pl_pal(pc),a0

	move.w	is_ntsc(pc),d0
	beq.b	.pal
	lea	pl_ntsc(pc),a0
.pal

	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts

set_and_wait_dma
	move	.dma_table(pc,d0.W),$DFF096
	move.l	d0,-(a7)
	move.l	#7,D0
	bsr	beamdelay
	move.l	(a7)+,d0
	rts

.dma_table
	dc.w	$8001,$8002,$8004,$8008

wait_audio_dma
	lea	$dff000,a0
	move.l	#7,D0
	bsr	beamdelay
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


pl_pal
	PL_START
	PL_L	$500,$91C84E71	; sub.l	A0,A0 + NOP, removes VBR access
;;	PL_PS	$16018,wait_dma	; sound stop: not needed
	PL_P	$15FFA,set_and_wait_dma
	; start with music on chip/maps on (2 bits set: 1:on chip,1:maps on)
	PL_B	$1489,3
	
	PL_IFC2
    PL_W    $0148a,4    ; joypad at startup, which amounts to button2 = jump
	PL_ENDIF
	
	; trainer
	PL_IFC1X    0
	PL_B	$C310,$4A   ; infinite lives
	PL_ENDIF
	PL_IFC1X    1
    PL_NOP  $cc02,2     ; any number of key parts match and open the door
	PL_ENDIF
	

    ; don't limit trainer to first 4 worlds
    PL_NOP  $035c0,2
    PL_W    $05098,$20
	PL_END

pl_ntsc
	PL_START
	PL_L	$500,$91C84E71	; sub.l	A0,A0 + NOP, removes VBR access
	PL_P	$15E90,set_and_wait_dma
	
    
	; start with music on chip / maps on
	PL_B	$1489,3
	
	PL_IFC2
    PL_W    $0148a,4    ; joypad at startup, which amounts to button2 = jump
	PL_ENDIF
	
	; trainer
	PL_IFC1X    0
	PL_B	$C1A4,$4A   ; infinite lives
	PL_ENDIF
	PL_IFC1X    1
    PL_NOP  $ca96,2     ; any number of key parts match and open the door
	PL_ENDIF
	
    ; don't limit trainer to first 4 worlds
    PL_NOP  $03478,2
    PL_W    $04f50,$20
    
	PL_END


fix_controller
	MOVEQ	#0,D0			;  joystick (4=joypad)
	rts
	
; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	add.l	d7,d7
	add.l	d7,d7

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	a3-a6/d7,-(a7)
	jsr	(a5)
	movem.l	(a7)+,a3-a6/d7
.skip
	;call
	move.l	d7,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

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

is_ntsc
	dc.w	0
  
tag		dc.l	WHDLTAG_CUSTOM3_GET
trainer_start_level	dc.l	0

		dc.l	0   
;============================================================================
