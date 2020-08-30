;*---------------------------------------------------------------------------
;  :Program.	Goblins3HD.asm
;  :Contents.	Slave for "Goblins3"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: Goblins3HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"Goblins3.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;;CHIP_ONLY

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $110000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $90000
BLACKSCREEN
IOCACHE		= 10000
	ENDC
	
NUMDRIVES	= 1
WPDRIVES	= %0000

;INITAGA
HDINIT
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 8000
BOOTDOS
CACHE
;HD_Cyls = 1000


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"3.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"Goblins 3"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG MODE)"
	ENDC
	
	dc.b	0
slv_copy		dc.b	"1993 Coktel Vision",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Thanks to Bert Jahn, Adrian, Frank",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b    "C2:L:language:autodetect,select,english,german,french;" ; ,spanish,italian;" ; both left out cos they don't seem to work
    dc.b    "C3:X:Disable blitter fixes:0;"
	dc.b	0

_program:
	dc.b	"loader",0

gfxname
	dc.b	"graphics.library",0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

	EVEN

    
PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1

	ENDM
    
MUST_EXIST_TEST:MACRO
	lea	.mu\1(pc),a0
	bsr	must_exist
	bra.b	.cont\1
.mu\1
	dc.b	"DISK0",\1+'0',".STK",0
	even
.cont\1
	ENDM

_bootdos
	clr.l	$0.W


    IFD CHIP_ONLY
    move.l  _expmem(pc),$110.W
    ; so executable start maps to $20000
    move.l  4,a6
    move.l  #MEMF_CHIP,d1
    move.l  #$6178,d0
    jsr (_LVOAllocMem,a6)
    ENDC
    
	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;version
		movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		lea	_program(pc),a0
		jsr	resload_GetFileSize(a2)
		movem.l	(a7)+,d1/a0-a2
		lea	version(pc),a0

		cmp.l	#163804,d0
		bne.b	.nov1
		move.l	#1,(a0)
		bra.b	.cont
.nov1
		cmp.l	#164100,d0
		bne.b	.nov2
		move.l	#2,(a0)
		bra.b	.cont
		bra.b	.cont
.nov2
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.cont

		
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

        ;;PATCH_DOSLIB_OFFSET Open

		MUST_EXIST_TEST	1
		MUST_EXIST_TEST	2
		MUST_EXIST_TEST	3
		MUST_EXIST_TEST	4
		MUST_EXIST_TEST	5

	;load exe
		bsr	_set_arguments
		move.l	a0,a1
		lea	_program(pc),a0

		lea	_patch_exe(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


; < d7: seglist (APTR)
	
_patch_exe:
	patch	$100,crackit
	lea	gfxname(pc),a1
	moveq	#0,d0
	move.l	$4.W,a6
	jsr	_LVOOpenLibrary(a6)

	move.l	d0,a6
	PATCH_XXXLIB_OFFSET	RectFill    ; fix params + add blitter wait
	PATCH_XXXLIB_OFFSET	BltBitMap   ; add blitter wait

    ; in Coktel games, we must wait a while on fast machines
    ; first noticed a few weeks ago in "Asterix and the Magic Carpet"
    ; it seems that the intuition CloseWindow call trashes the memory if we don't wait
    ; it doesn't happen on slow or floppy systems of course!
    ;
    ; this is very weird and I found this fix by chance (just inserting a "blitz" lmb clicker 
    ; to debug the code fixed the issue)
    
    move.l  _resload(pc),a2
    move.l  #5,d0
    jsr (resload_Delay,a2)

	move.l	D7,A1
	add.l	#4,a1

    IFND    CHIP_ONLY
    move.l  _expmem(pc),$110.W
    move.l  a1,$114
    ENDC
    
	move.l	version(pc),d0

	lea	pl_main_v2292(pc),a0
	cmp.l	#1,d0
	beq.b	.do
	lea	pl_main_v370(pc),a0
.do
	move.l	_resload(pc),a2
	jsr	resload_Patch(A2)
	
	rts


pl_main_v370
	PL_START

	; quit before access fault

	PL_P	$345A,_quit

    ; click for the user when "insert disk x" requester appears
    
	PL_PS   $14918,fake_mouse_click

	; protection

	PL_L	$11E9A,$4EB80100

    ; another missing blitwait
    ; the graphics library blitter fixes wait for blitter in the end
    ; (no blitwaits were done at all in the original game)
    ; but game performs another blit, that waits at the start
    ; added a wait at the last blitted plane so it doesn't consume too much cpu
    ; result is: no more gfx glitches
    PL_IFC3    
    PL_ELSE
	PL_PSS  $20544,extra_blitwait,2
    PL_ENDIF

    PL_PS   $21E02,fix_wrong_rectfill_xmax

	PL_END



    
   
pl_main_v2292
	PL_START

	; quit before access fault

	PL_P	$345A,_quit

    ; click for the user when "insert disk x" requester appears
    
	PL_PS   $14876,fake_mouse_click
	
	; protection

	PL_L	$11DF8,$4EB80100

    PL_IFC3    
    PL_ELSE
	PL_PSS  $20438,extra_blitwait,2
    PL_ENDIF

    PL_PS   $21CF6,fix_wrong_rectfill_xmax

	; double WaitTOF (removed, could slow down the game, why did I put that???)

	;;PL_L	$25610,$4EF80106

	PL_END

fix_wrong_rectfill_xmax
    ; sometimes A0 points partly on correct data
    ; but at 40(A0) there is an address in expansion
    ; memory, so xmax is wrong and it trashes the game
    ; problem is: it's very difficult to detect it when
    ; reaching RectFill because expmem is sometimes 24 bit
    ; memory and it can mix up with real values, causing
    ; issues too
    ;
    ; my idea: when this is wrong, there are several expmem
    ; addresses following:
    ; A0+40 : 47F4 AC40 47F4 7CF0 47F4 2550
    ; when it's correct it's not like that at all
    ; 00021C6E 0140 0002 2674 0000
    ; just mask A0+40 and A0+44 with $FFF0
    ; and if they're identical, just put 0 in xmax
    ; so nothing happens in RectFill
    movem.l d1,-(a7)
	MOVE	40(A0),D0		;21E02: 30280028
	MOVE	44(A0),D1		;21E02: 30280028
    and.w   #$FFF0,d0
    and.w   #$FFF0,d1
    cmp.w   d0,d1
    movem.l (a7)+,d1
    beq.b   .access_fault
    
    ; normal operation
	MOVE	40(A0),D0		;21E02: 30280028
	SUBQ	#1,D0			;21E06: 5340
    rts
    
.access_fault
    clr.w   D0
    rts

extra_blitwait
	MOVEA.L	-30592(A4),A0		;20544: 206C8880
	MOVE	#$0400,(A0)		;20548: 30BC0400
    bra wait_blit


; hard to find 6 bytes without A4 offsets, so patch is generic
fake_mouse_click
    move.l  (a7),12(a7) ; move return address up the stack
	LEA	12(A7),A7		; pop up the parameters now
    move.l  ($42,a7),a0 ; get some caller up the stack
    cmp.w   #$FFFA,(6,a0) ; code from next caller instructions, "insert disk" context
    bne.b   .normal
    ; "insert disk" context: click/unclick every x updates to simulate user
    bsr fake_read_mouse
.normal
	MOVEA.L	D4,A0			;1491C: 2044
	TST	(A0)			;1491E: 4A50
    RTS
    
fake_read_mouse
    lea .toggle(pc),a0
    add.w   #1,(a0)
    cmp.w   #2,(a0)
    move.l  d4,a0
    bne.b   .no_click
    clr.w   (a0)
    move.w  #1,(a0)
    rts
.no_click
    clr.w   (a0)
    rts
.toggle
    dc.w    0
 


new_RectFill
    pea .next(pc)
	move.l	old_RectFill(pc),-(a7)
	rts
.next
    ; wait for blitter operation to complete
    bra wait_blit

    
    
wait_blit
    movem.l D0,-(a7)
    movem.l _blitter_fixes(pc),d0
    btst    #1,d0
    bne.b   .nowait
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
.nowait
    movem.l (a7)+,d0
	rts
    
; call graphics.library function then wait
DECL_GFX_WITH_WAIT:MACRO
new_\1
    pea .next(pc)
	move.l	old_\1(pc),-(a7)
	rts
.next:
    bra wait_blit
    ENDM    

    DECL_GFX_WITH_WAIT  BltBitMap


; < A0 filename
; < A6 dosbase

must_exist
	movem.l	d0-d1/a0-a1/a3,-(a7)
	move.l	a0,d1
	move.l	a0,a3
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	move.l	d0,d1
	beq.b	.error
	jsr	_LVOUnLock(a6)
	movem.l	(a7)+,d0-d1/a0-a1/a3
	rts

.error
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

crackit:
	MOVE	D0,-(A7)		;16: 3F00
	CMPI.B	#$12,(A0)+		;18: 0C180012
	BNE.S	.lab_0002		;1C: 6652
	CMPI.B	#$55,(A0)+		;1E: 0C180055
	BNE.S	.lab_0002		;22: 664C
	CMPI.B	#$0E,(A0)+		;24: 0C18000E
	BNE.S	.lab_0002		;28: 6646
	CMPI.B	#$24,(A0)+		;2A: 0C180024
	BNE.S	.lab_0002		;2E: 6640
	CMPI.B	#$15,(A0)+		;30: 0C180015
	BNE.S	.lab_0002		;34: 663A
	ADDQ.L	#1,A0			;36: 5288
	CMPI.B	#$63,(A0)+		;38: 0C180063
	BNE.S	.lab_0002		;3C: 6632
	CMPI.B	#$01,(A0)+		;3E: 0C180001
	BNE.S	.lab_0002		;42: 662C
	CMPI.B	#$01,(A0)+		;44: 0C180001
	BNE.S	.lab_0002		;48: 6626
	CMPI.B	#$09,(A0)+		;4A: 0C180009
	BNE.S	.lab_0002		;4E: 6620
	SUBQ.L	#5,A0			;50: 5B88
	MOVEQ	#0,D0			;52: 7000
	MOVE.B	(A0),D0			;54: 1010
	MOVEA.L	-28320(A4),A0		;56: 206C9160
	MOVE.B	D0,0(A0,D1.L)		;5A: 11801800
	MOVE	(A7)+,D0		;5E: 301F
	MOVEA.L	(A7),A0			;60: 2057
	SUBQ.L	#4,A0			;62: 5988
	MOVE.L	#$206C9160,(A0)		;64: 20BC206C9160
	MOVEA.L	-28320(A4),A0		;6A: 206C9160
	bsr	_flushcache
	RTS				;6E: 4E75
.lab_0002:
	MOVE	(A7)+,D0		;70: 301F
	MOVEA.L	-28320(A4),A0		;72: 206C9160
	RTS				;76: 4E75

    
_set_arguments:	
	lea	_arg_lang_sel(pc),A0
	move.l	_language_forced_selection(pc),D1
	cmp.b	#1,D1
	beq.b	.out			; custom2=1: ask for language
	lea	_arg_presel(pc),A0
	lea	_arg_lang(pc),A1

    tst.b   d1
    bne.b   .select
.autodetect
	move.l	_language(pc),D1
.select
	cmp.b	#3,D1
	beq.b	.german
	cmp.b	#4,D1
	beq.b	.french
	cmp.b	#5,D1
	beq.b	.spanish
	cmp.b	#6,D1
	beq.b	.italian
	bra.b	.english		; not found: english
.spanish:
	move.w	#'SP',d0
	bra.b	.out
.italian:
	move.w	#'IT',d0
	bra.b	.out
.french:
	move.w	#'FR',d0
	bra.b	.out
.german
	move.w	#'DE',d0
	bra	.out
.english:
	move.w	#'GB',d0
.out
	move.b	d0,(1,a1)
	lsr.w	#8,d0
	move.b	d0,(a1)
	bsr	_strlen
	rts

_arg_lang_sel:
	dc.b	"MENU",10,0

_arg_presel:
	dc.b	"MENU LG_"
	; in case arg_lang is on an odd address: problems on 68000/68010 CPUs
_arg_lang:
	dc.b	"GB",10,0
	even

_strlen:
	moveq.l	#0,D0
.loop
	tst.b	(A0,D0.L)
	beq.b	.out
	addq.l	#1,D0
	bne.b	.loop
.out
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

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

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
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

version
	dc.l	0

;---------------

_tag		dc.l	WHDLTAG_CUSTOM3_GET
_blitter_fixes	dc.l	0
		dc.l	WHDLTAG_LANG_GET
_language	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_language_forced_selection	dc.l	0
		dc.l	0

;============================================================================

	END
