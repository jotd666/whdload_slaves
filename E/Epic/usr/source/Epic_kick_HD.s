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
;
; this source is only provided for debug of HD version
; official HD version whdload slave doesn't use kickemu

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

CHIP_ONLY
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
CHIPMEMSIZE	= $200000
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
slv_Flags	= WHDLF_NoError|WHDLF_EmulTrap|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick31.s

    
;============================================================================

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
	dc.b	0



slv_name		dc.b	"Epic (Kickemu)"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"199x Ocean",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	0


program:
	dc.b	"epic",0
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
        move.l  #$80000-$00018d98-$30-$1FC8,d0
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
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1
	blitz
	
	jsr	resload_Patch(a2)

	rts

; apply on SEGMENTS
pl_unp
pl_prog_v3
	PL_START
	; skip manual protection
	PL_B	$09bbe,$60
	
	; skip cpu detection, assuming 68000
	PL_S	$2eb0e,$6c-$0e	
	; quit to os
	PL_P	$2e510,_abort_ok
	
		
	PL_PS	$06f8e,_xkeyboard
	
	; patches reloc at startup
	PL_PS	$0cc30,_reloc_loop
	PL_S	$0cc30+6,$ac-$94
	
	; jotd: added fixes for SMC
	; (else as cpu detection has been fixed as 68000,
	; game crashes)
	PL_P	$2ebbe,_flushcache_trap
	; flush cache after reading THREEDEE.BIN code file
	PL_S	$2ef2a,$48-$2a
	PL_P	$2ef4a,_flushcache
	
	; flush smc to avoid alien-like text
	; when key is pressed (text display speedup)
	PL_PS	$7f8e,_char_smc

	; dma sound loops
	PL_PSS	$2d586,_sound_wait,2
	PL_PSS	$2d59c,_sound_wait,2
	PL_PSS	$2dcce,_sound_wait,2
	PL_PSS	$2dce4,_sound_wait,2

	; fixes sound
	PL_PS	$26e50,_sound_wait_2
	PL_S	$26e56,$f4-$e4

	PL_END
 

_reloc_loop
.lb_0491:
	ADDA.L	D1,A0			;8ba8e: d1c1
	MOVE.L	(A0),D4			;8ba90: 2810
	SUB.L	D5,D4			;8ba92: 9885
	BPL.S	.lb_0492		;8ba94: 6a06
	MOVE.L	4(A2,D4.W),D4		;8ba96: 28324004
	BRA.S	.lb_0493		;8ba9a: 6002
.lb_0492:
	ADD.L	D0,D4			;8ba9c: d880
.lb_0493:
	; changes some jumps dynamically (at start)
	MOVE.L	D4,(A0)			;8ba9e: 2084
.lb_0494:
	MOVE.B	(A1)+,D1		;8baa0: 1219
	CMP.B	D2,D1			;8baa2: b202
	BHI.S	.lb_0491		;8baa4: 62e8
	LEA	254(A0),A0		;8baa6: 41e800fe
	BEQ.S	.lb_0494		;8baaa: 67f4
	bra		_flushcache

_xkeyboard	moveq	#0,d2
	move.b	(ciasdr,a1),d2
	move.l	d2,-(sp)
	not.b	d2
	ror.b	#1,d2
	cmp.b	(_keyexit,pc),d2
	beq.w	_abort_ok
	move.l	(sp)+,d2
	rts

_abort_ok	move.l	#TDREASON_OK,-(sp)
	movea.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)
	
_char_smc
	; original
	ANDI.W	#$003f,D0		;86f4e: 0240003f
	ADD.W	D0,D0			;86f52: d040
	bra		_flushcache
	
	
_sound_wait_2
	move.w  d0,-(a7)
	move.w	#2,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
	rts


_flushcache_trap
	bsr	_flushcache
	rte
		
_sound_wait
	move.w  d0,-(a7)
	move.w	#4,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
	rts 
	
	
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
