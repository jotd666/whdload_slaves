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
	OUTPUT	"Tinyus.slave"
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
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
;;BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

    
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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0



slv_name		dc.b	"Tinyus"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"2021 Pink^abyss",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	0


program:
	dc.b	"tinyus_beta",0
args		dc.b	10
args_end
	dc.b	0
slv_config
    ;dc.b    "C2:X:blue/second button jumps player 1:0;"
    ;dc.b    "C2:X:blue/second button jumps player 2:1;"
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN


_bootdos
		clr.l	$0.W

;        bsr _detect_controller_types
;        lea controller_joypad_0(pc),a0
;        clr.b   (a0)        ; no need to read port 0 extra buttons...
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload
        lea	(tag,pc),a0
        jsr	(resload_Control,a2)

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
        
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$10000-$BA70,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

    ; store exe file size once and for all
		lea	program(pc),a0
		jsr		resload_GetFileSize(a2)
		lea	file_size(pc),a0
		move.l	d0,(a0)
		
	;load exe
		lea		program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


patch_main
	lea	pl_unp(pc),a0
    move.l  d7,a1
	jsr	resload_PatchSeg(a2)
	
	rts

; apply on SEGMENTS
pl_unp
    PL_START
	; catch the end of unpacking routine
    PL_P    $0015e,end_unpack
	
	; remove all packet/async shit handling, replace by whdload calls
	PL_S	$00130,6	; remove flush
	PL_P	$0017a,readbuffer
	PL_P	$001cc,seek
	PL_P	$001ac,waitpacket

	; remove exec calls (signals init/free/set, useless now)
	PL_NOP	$00048,4
	PL_NOP	$0005a,4
	PL_NOP	$0013e,4
	PL_NOP	$0038c,4
	PL_NOP	$004ea,4
	PL_R	$0052c
	; remove intro text write
	PL_NOP	$0051e,4
	;ENDC
	
    PL_END
 
pl_main
    PL_START
    ; vbr at 0
    PL_S    $34c,$78-$4C
    PL_W    $37C,$7000
    ; inactivate debug code / avoid access fault
    PL_CL    $17be+2
    PL_CL    $17de+2
    PL_CL    $25ca+2
    PL_END


;	>	d2	pos
;		d3	whence
seek
	; called once with D3 = 1: from end (D2 negative)
	movem.l	d1-d2/a0-a2,-(a7)
	move.l	file_size(pc),d0
	add.l	d2,d0	; new offset
	lea		file_offset(pc),a0
	move.l	d0,(a0)		; update offset
	movem.l	(a7)+,d1-d2/a0-a2
	rts

waitpacket
	move.l	packet_reply(pc),d0
	rts
	
readbuffer

;	>	a0	dest
;		d0.l	len
;	<	d0.l	numbytes read (0=async)

	movem.l	d1-d2/a0-a3,-(a7)
	move.l	d0,d2	; save len
	move.l	A0,A1	; buffer
	move.l	a0,a3	; save buffer
	move.l	file_size(pc),d0
	move.l	file_offset(pc),d1
	sub.l	d1,d0		; remaining bytes to read
	cmp.l	d2,d0
	bcs.b	.endoffile
	move.l	d2,d0		; limit to block size
.endoffile
	move.l	d0,d2		; save size
	lea		program(pc),a0
	move.l	a3,a1
	move.l	_resload(pc),a2
	jsr		resload_LoadFileOffset(a2)
	move.l	d2,d0		; size
	lea		file_offset(pc),a0
	add.l	d0,(a0)		; update offset
	lea		packet_reply(pc),a0
	move.l	d0,(a0)		; store size
	movem.l	(a7)+,d1-d2/a0-a3
	rts

	
end_unpack
    move.l  a1,-(a7)
    lea pl_main(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_PatchSeg,a2)
    move.l  (a7)+,a1
	ADDQ.L	#1,A1			;0015e: 5289
	ADDA.L	A1,A1			;00160: d3c9
	ADDA.L	A1,A1			;00162: d3c9
	JMP	(A1)			;00164: 4ed1
    
    ; not really super-helpful as game already has "ESC"
    ; as a quit key
keyboard:
	MOVE.B	$bfec01,D1		;22448: 123900
    movem.l d1,-(a7)
    ror.b   #1,d1
    not.b   d1
    cmp.b   _keyexit(pc),d1
    beq _quit
    movem.l (a7)+,d1
    RTS
    
    
get_version:
	movem.l	d1/a0/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#$1BD0C,D0
	beq.b	.original
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.original
	moveq	#1,d0
    bra.b   .out
    nop


.out
	movem.l	(a7)+,d1/a0/a1
	rts


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

	;get tags
    move.l  _resload(pc),a2
    lea (segments,pc),a0
    move.l  d7,(a0)
    lea	(tagseg,pc),a0
	jsr	(resload_Control,a2)


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
orig_vbl
    dc.l    0
	

packet_reply
	dc.l	0
	
file_offset
	dc.l	0

file_size
	dc.l	0
	
tag
		dc.l	WHDLTAG_CUSTOM2_GET
button_config	dc.l	0
    dc.l    0
tagseg
        dc.l    WHDLTAG_DBGSEG_SET
segments:
		dc.l	0
		dc.l	0
prev_joy1   dc.l    0
loaded_highscore
    dc.l    0
highname
    dc.b    "highscore",0
    
;============================================================================

	END
