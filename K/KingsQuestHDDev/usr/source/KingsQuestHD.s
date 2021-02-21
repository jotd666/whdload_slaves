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
	OUTPUT	"KingsQuest.slave"
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
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

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
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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

assign
	dc.b	" KQ1",0
assign2
	dc.b	"JKQ1",0

slv_name		dc.b	"King's Quest"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1986 Sierra",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Thanks to Tony Aksnes for disk image",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"sierra",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	dc.b    "C5:L:keyboard:us,fr,de;"	
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN
    
_bootdos
		clr.l	$0.W
        
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload
        lea	(_tag,pc),a0
        jsr	(resload_Control,a2)

        move.l  _keyboard_type(pc),d0
        cmp.l   #3,d0
        bcs.b   .kbbounds
        moveq.l #0,d0
.kbbounds
        
        lea    old_kbint(pc),a1
        lea kbint_hook(pc),a0
        cmp.l   (a1),a0
        beq.b   .done
        move.l  $68.W,(a1)
        move.l  a0,$68.W
.done	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase



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


    
; < d7: seglist (BPTR)

patch_main
	bsr	check_version

	move.l	d7,a5
	add.l	a5,a5
	add.l	a5,a5
	addq.l	#4,a5

    lea offset_table(pc),A2
    MOVE.W #$7354,D2    ; key
.loop
    MOVE.W (A2)+,D0
    MOVE.W (A2)+,D3
    BEQ.B .out
    lea ($4F0,a5),a0 ; start of prog
    ADDA.W D0,A0
    ADDA.W D0,A0
    LEA.L decrypt_keys(pc),A1
    SUBQ.W #$02,D3
.inner
    MOVE.W (A0)+,D0
    MOVE.B (A1)+,D1
    EOR.W D2,D0
    EOR.B D1,D0
    EOR.W D0,(A0)
    DBF D3,.inner
    bra.b   .loop
.out
    ; now that the code is decrypted, patch it
    ; (only a small part of it was encrypted actually,
    ; Herdon protection improved afterwards, like for instance
    ; in "Final Assault" where all the code was encrypted
    ;
    ; here, the code was very partially encrypted, around
    ; the relocations
    
    move.l  d7,a1
    move.l  _resload(pc),a2
    lea pl_main(pc),a0
    jsr resload_PatchSeg(a2)
    
	rts

; ripped from the decrypting part
offset_table
    dc.w  $0012,$0015,$002C,$000A,$003B,$0018,$006C,$0006
    dc.w  $0074,$0007,$007D,$000E,$0093,$0007,$009C,$0005
    dc.w  $00A3,$0005,$00AA,$0005,$00B7,$001B,$00D7,$0006
    dc.w  $0000,$0000
; part of the protection that double decrypts itself and is used
; as a key string afterwards, ripped just when the last part
; is decrypting the KQ program
; let me tell you that it's waaay easier with an emulator that
; has non-intrusive breakpoints and memory watches than on a real
; machine.
decrypt_keys:
    incbin  "decrypt_keys.bin"
    even

pl_main
    PL_START
    PL_S    $0,$4F0 ; jump to decrypted part, skip protection
    PL_END
    
check_version:
	movem.l	d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#86280,D0
	beq.b	.okay

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.okay

	movem.l	(a7)+,d1/a1
	rts

kbint_hook:
    movem.l  a0-a1/d0-d3,-(a7)
    move.b  $BFEC01,d0
    ror.b   #1,d0
    not.b   d0
    moveq.l #0,d1
    bclr    #7,d0
    sne     d1
    lea kb_table(pc),a0
    move.l  _keyboard_type(pc),d2
    add.l   d2,d2
    move.w  (a0,d2.w),a1
    add.w   a1,a0
    
.loop
    move.b  (a0)+,d2
    bmi.b   .noswap
    move.b  (a0)+,d3
    cmp.b   d0,d2
    bne.b   .loop
    move.b  d3,d0

.pack
    tst.b   d1
    beq.b   .norel
    bset    #7,d0   ; key released
.norel
    not.b   d0
    rol.b   #1,d0
    move.b  d0,$BFEC01    
.noswap
    movem.l  (a7)+,a0-a1/d0-d3
    
    move.l  old_kbint(pc),-(a7)
    rts

    
old_kbint:
    dc.l    0

kb_table:
    dc.w    us-kb_table,french-kb_table,deutsch-kb_table

us:
    dc.b    -1
french:
    dc.b    $10,$20   ; a <-> q
    dc.b    $20,$10   ; a <-> q
    dc.b    $11,$31   ; w <-> z
    dc.b    $31,$11   ; w <-> z
    dc.b    $29,$37   ; m <-> ,
    dc.b    $37,$38   ; m <-> ,
    dc.b    -1    
deutsch:
    dc.b    $15,$31   ; y -> z
    dc.b    $31,$15   ; z -> y
    dc.b    -1    
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

_tag		dc.l	WHDLTAG_CUSTOM5_GET
_keyboard_type	dc.l	0
		dc.l	0

;============================================================================

	END
