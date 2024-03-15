;*---------------------------------------------------------------------------
;  :Program.	TornadoHD.asm
;  :Contents.	Slave for "Tornado"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: TornadoHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/graphics.i
        INCLUDE lvo/timer.i
        INCLUDE devices/timer.i

	IFD BARFLY
	OUTPUT	"TornadoAGA.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

DEBUG=0

;============================================================================

CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $200000
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
INITAGA
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
CBDOSLOADSEG
BOOTDOS
SEGTRACKER

;============================================================================

slv_Version	= 18
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5c	; numpad '/' (asterisk is used for "Master warning reset")

;============================================================================

	INCLUDE	Whdload/kick31.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_name		dc.b	"Tornado AGA",0
slv_copy		dc.b	"1994 Digital Integration",0
slv_info		dc.b	"adapted & fixed by JOTD & paraj",10
                        dc.b    "Version 2.0 RC2",10
		        INCBIN	datetime
		        dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

	IFGE slv_Version-17
slv_config	dc.b	"C1:X:Original rendering code:0;"
                dc.b    "C1:X:Frame rate limit:1;"
                dc.b    "C1:X:Show FPS:2;"
                dc.b	"C4:L:Auto start:None,Drone,IDS Easy,IDS Hard,ADV Easy,ADV Hard;"
                dc.b    0
	ENDC
	EVEN

_program:
	dc.b	"shell",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================

	;initialize kickstart and environment


; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
        move.l  d7,-(sp)
        move.l  d1,d7

	add.l	D1,D1		
	add.l	D1,D1	
	addq.l	#4,d1	

	; now D1 is start address

        lea     Section0Start(pc),a0
        move.l  d1,(a0)

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#3,(a0)
	bne.b	.nosmv
	cmp.b	#'m',2(A0)
	bne.b	.nosmv

	; SMV

	move.l	d1,a0
	move.w	#$4EB9,$7C94(a0)
	pea	fix_af_smv(pc)
	move.l	(a7)+,$7C96(a0)

        movem.l d0-a6,-(sp)
        lea     smv_ClickState(pc),a0
        clr.w   (a0)
        lea     smv_patch(pc),a0
        move.l  d7,a1
        move.l  (_resload,pc),a2
        jsr     (resload_PatchSeg,a2)
        movem.l (sp)+,d0-a6

        bra     .out

.nosmv
	cmp.b	#'f',1(a0)
	bne.b	.out
	cmp.b	#'l',2(a0)
	bne.b	.out

	; 'flight': main flight simulation

        movem.l d0-a6,-(sp)
        move.l  (_resload,pc),a2

        lea     flight_patch(pc),a0
        move.l  d7,a1
        jsr     (resload_PatchSeg,a2)

        btst.b  #0,custom1+3
        bne     .noblitlist

        lea     pl_blits(pc),a0
        move.l  d7,a1
        jsr     (resload_PatchSeg,a2)
.noblitlist
        movem.l (sp)+,d0-a6

	bsr	.getbounds
	lea	.unrolled_loop(pc),a2
	move.l	#42,d0
.unroll
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.out
	move.l	#20,d0
	lea	.unrolled_loop_fast(pc),a3
.cp
	move.w	(a3)+,(a0)+
	dbf	d0,.cp

	bra.b	.unroll
.out
        move.l  (sp)+,d7
	rts	


.getbounds
	move.l	d1,a0
	move.l	a0,a1
	add.l	#$59000,a1
	rts

.unrolled_loop:
	dc.w	$2368,$0118,$0118
	dc.w	$2368,$00F0,$00F0
	dc.w	$2368,$00C8,$00C8
	dc.w	$2368,$00A0,$00A0
	dc.w	$2368,$0078,$0078
	dc.w	$2368,$0050,$0050
	dc.w	$2368,$0028,$0028

.unrolled_loop_fast:
	dc.w	$2368,$0028,$0028
	dc.w	$2368,$0050,$0050
	dc.w	$2368,$0078,$0078
	dc.w	$2368,$00A0,$00A0
	dc.w	$2368,$00C8,$00C8
	dc.w	$2368,$00F0,$00F0
	dc.w	$2368,$0118,$0118


fix_af_smv:
	MOVE	D1,D3			;07C94: 3601
	BMI.B	.negative
	MULU	#$0140,D3		;07C96: C6FC0140
	rts
.negative
	; avoids access fault
	moveq	#0,d3
	rts

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

_hexsearch:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts


_bootdos
	clr.l	$0.W

	move.l	(_resload),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)

                lea     tags(pc),a0
                jsr     resload_Control(a2)

                bsr     init

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
                lea     patch_shell(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist



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
	jsr	(a5)
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

******************************************************************************

        IFNE DEBUG
PRINTF  MACRO
        movem.l a0/a2,-(sp)
CARG set 9
        rept 8
        ifnb \.
        move.l  \.,-(sp)
        endc
CARG set CARG-1
        endr
        lea     .fmt\@(pc),a0
        move.l  (_resload,pc),a2
        jsr     (resload_Log,a2)
        bra     .done\@
.fmt\@: dc.b    \1
        dc.b    0
        even
.done\@:
        add     #4*(NARG-1),sp
        movem.l (sp)+,a0/a2
        ENDM

DUMPREGS MACRO
        movem.l a0/a2,-(sp)
        movem.l d0-a6,-(sp)
        lea     regfmt(pc),a0
        move.l  _resload(pc),a2
        jsr     resload_Log(a2)
        add.l   #15*4,sp
        movem.l (sp)+,a0/a2
        ENDM

regfmt:
        dc.b "D0=%08lX D1=%08lX D2=%08lX D3=%08lX D4=%08lX D5=%08lX D6=%08lX D7=%08lX "
        dc.b "A0=%08lX A1=%08lX A2=%08lX A3=%08lX A4=%08lX A5=%08lX A6=%08lX",0
        even

        ENDC ; DEBUG

******************************************************************************

patch_shell
                movem.l d0-a6,-(sp)
                lea     shell_patch(pc),a0
                move.l  d7,a1
                move.l  (_resload,pc),a2
                jsr     (resload_PatchSeg,a2)
                movem.l (sp)+,d0-a6
                rts

shell_patch     PL_START
                PL_IFC4
                PL_S    $10c,26         ; Skip logo + delay
                PL_ENDIF
                PL_END

******************************************************************************

smv_ClickState  dc.w 0
GetMouseCoords
                movem.l d0-a6,-(sp)
                move.l  smv_MouseCoordPtr(pc),a1
                move.l  autostart(pc),d0
                move.l  .coords-4(pc,d0.w*4),(a1)

                lea     smv_ClickState(pc),a1
                move.w  (a1),d0
                addq.w  #1,(a1)

                sub.w   #35,d0 ; Wait for menu to appear
                bcs     .out

                moveq   #1,d1
                cmp.w   #1,d0
                beq     .button
                cmp.w   #10,d0
                beq     .button
                moveq   #2,d1
                cmp.w   #5,d0
                beq     .button
                cmp.w   #15,d0
                bne     .out

.button
                move.l  smv_MouseButtonPtr(pc),a1
                move.b  d1,(a1)
                move.l  ([smv_ButtonSigMaskPtr,pc]),d0
                move.l  ([smv_ThisProcPtr,pc]),a1
                move.l  4.w,a6
                jsr     _LVOSignal(a6)

.out
                movem.l (sp)+,d0-a6
                add.l   #10,(sp)
                rts
.coords         dc.l $001400c6  ; Drone
                dc.l $00ea00b1  ; Quickstart IDS Easy
                dc.l $00ea00bd  ; Quickstart IDS Hard
                dc.l $00ea00c9  ; Quickstart ADV Easy
                dc.l $00ea00d5  ; Quickstart ADV Hard

smv_patch       PL_START
                PL_IFC4
                PL_PS   $0a6f0,GetMouseCoords
                PL_GA   $431f8,smv_MouseCoordPtr
                PL_GA   $43877,smv_MouseButtonPtr ; Value set by input handler
                PL_GA   $4320e,smv_ButtonSigMaskPtr
                PL_GA   $431fe,smv_ThisProcPtr
                PL_ENDIF
                ; Swap JoyX and JoyY in calibrartion screen
                PL_AL   $298ae+2, -2
                PL_AL   $298b4+2, 2
                PL_AL   $298cc+2, -2
                PL_AL   $298d2+2, 2
                PL_AL   $2991e+2, -2
                PL_AL   $29924+2, 2
                PL_END

smv_MouseCoordPtr dc.l 0
smv_MouseButtonPtr dc.l 0
smv_ButtonSigMaskPtr dc.l 0
smv_ThisProcPtr dc.l 0

******************************************************************************

NPLANES=8
SCREENW=320
SCREENH=256
ROWDELTA=SCREENW
PLANEDELTA=SCREENW/8


init:
                move.l  $4.w,a6

                move.l  #(SCREENW/8)*SCREENH*NPLANES+16,d0
                move.l  #MEMF_CLEAR!MEMF_PUBLIC,d1
                jsr     _LVOAllocMem(a6)
                lea     TempBufPtr(pc),a0
                add.l   #15,d0
                and.b   #-16,d0
                move.l  d0,(a0)

                lea     .timername(pc),a0
                moveq   #UNIT_MICROHZ,d0
                lea     timerreq(pc),a1
                moveq   #0,d1
                jsr     _LVOOpenDevice(a6)
		lea	.gfxname(pc),a1
		jsr	_LVOOldOpenLibrary(a6)
                move.l  d0,a6
                move.l  #$00080000,-(a7)
                pea     .topazname(pc)
                move.l  a7,a0
                jsr     _LVOOpenFont(a6)
                add.w   #8,a7
                move.l  d0,a0
                lea     topazdata(pc),a1
                move.l  34(a0),(a1) ; tf_CharData
                rts


.gfxname        dc.b 'graphics.library',0
.timername      dc.b 'timer.device',0
.topazname      dc.b 'topaz.font',0
                even

; d0 = char
; a2 = screenptr
; a3 = topaz char data
putchar
                move.l  a2,a0
                and.w   #$ff,d0
                lea     -32(a3,d0.w),a1
                moveq   #NPLANES-1,d0
.y
                move.b  (a1),d1
                REPT    8
                move.b  d1,REPTN*PLANEDELTA(a0)
                ENDR
                lea     ROWDELTA(a0),a0
                lea     192(a1),a1
                dbf     d0,.y
                rts

; d3 = digits
onedigit
                divu.w  #10,d3
                swap    d3
                moveq   #'0',d0
                add.b   d3,d0
                clr.w   d3
                swap    d3
                subq.w  #1,a2
                bra     putchar

showfps
                sub.w   #TV_SIZE,sp
                move.l  timerreq+IO_DEVICE(pc),a6
                move.l  sp,a0
                jsr     _LVOReadEClock(a6)
                lea     lasttime(pc),a0
                movem.l (sp)+,d1-d2
                movem.l (a0),d3-d4
                movem.l d1-d2,(a0)
                sub.l   d4,d2
                ;subx.l  d3,d1
                ; d0 = EClockRate, d1:d2 = Delta time
                moveq   #10,d3
                mulu.l  d3,d0
                divu.l  d2,d0
                ; d0 = fps*10

                move.l  ([BackBufferPtr,pc]),a2
                lea     SCREENW/8(a2),a2
                move.l  topazdata(pc),a3
                move.l  d0,d3
                bsr     onedigit
                subq.w  #1,a2
                moveq   #'.',d0
                bsr     putchar
.final
                bsr     onedigit
                tst.l   d3
                bne     .final
                rts

SwapBuffersOrigFps
                move.w  d0,$dff09a ; original code
                movem.l d0-a6,-(sp)
                bsr     showfps
                movem.l (sp)+,d0-a6
                rts

FrameEnd
                movem.l d1-a6,-(sp)

                btst.b  #2,custom1+3(pc)
                beq     .nofps
                bsr     showfps
.nofps

                move.l  BackBufferPtr(pc),a2
                move.l  SavedBackBuf(pc),a1
                move.l  (a2),a0

                IFNE DEBUG
                cmp.l   TempBufPtr(pc),a0
                beq     .ok
                illegal
                ;movem.l (sp)+,d0-a6
                ;rts
.ok
                ENDC ; DEBUG

                move.l  a1,(a2)

                move.l  Section0Start(pc),a2
                add.l   #$23e9c,a2
.waitvbl
                tst.b   (a2)
                bne     .waitvbl

                move.w  #(SCREENW*SCREENH)/4,d0
.copy
                move.l  (a0)+,(a1)+
                subq.w  #1,d0
                bne     .copy

                move.l  Section0Start(pc),d0
                add.l   #$23b4e,d0      ; Start of SwapBuffers
                btst.b  #1,custom1+3(pc)
                bne     .limit
                add.l   #10,d0          ; After frame limit
.limit
                movem.l (sp)+,d1-a6
                move.l  d0,-(sp)
                rts

FrameStart
                movem.l d0-d2/a0-a2,-(sp)
                lea     SavedBackBuf(pc),a0
                move.l  BackBufferPtr(pc),a1
                move.l  (a1),(a0)
                move.l  TempBufPtr(pc),(a1)

                IFNE    DEBUG
                PRINTF  <"New frame">
                ENDC

                IFNE DEBUG
                lea     Protected(pc),a0
                tst.l   (a0)
                bne     .protected
                not.l   (a0)

                lea     ProtectTags(pc),a0
                move.l  _resload(pc),a2
                jsr     resload_Control(a2)
.protected

                ENDC ; DEBUG
                movem.l (sp)+,d0-d2/a0-a2

                ; Original code
                move.l  Section0Start(pc),a6
                move.l  $6b2(a6),a6
                rts

; Y0=D0, Y1=D1, X0=D2, X1=D3, ColorIndex=D4, Dest=A5
FillRect:
                ; TODO: Optimize which registers are saved
                movem.l d0-a6,-(sp)
                move.l  ([BackBufferPtr,pc]),a0
                exg.l   d0,d1
                exg.l   d0,d3
                exg.l   d0,d2
                bsr     DrawRect
                movem.l (sp)+,d0-a6
                rts

; Like FillRect, but d4 = color1<<8!color2
GradientRect:
                ; XXX Coordinates are not inclusive here??

                movem.l d0-a6,-(sp)
                move.l  ([BackBufferPtr,pc]),a6
                sub.w   d0,d1
                move.w  d1,d7   ; d7 = ycount-1

                ; Get list of "change points"
                move.l  Section0Start(pc),a5
                add.l   #$54f62,a5
                lea     (a5,d0.w*2),a5

                mulu.w  #ROWDELTA,d0
                add.l   d0,a6
.y
                move.w  d2,d0
                move.w  (a5),d1
                subq.w  #1,d1
                cmp.w   d0,d1
                blo     .skip1
                move.l  a6,a0
                movem.l d1-d4/d7,-(sp)
                lsr.w   #8,d4
                bsr     DrawHorizLine
                movem.l (sp)+,d1-d4/d7
.skip1
                move.w  (a5),d0
                move.w  d3,d1
                subq.w  #1,d1
                blo     .skip2
                move.l  a6,a0
                movem.l d1-d4/d7,-(sp)
                bsr     DrawHorizLine
                movem.l (sp)+,d1-d4/d7
.skip2
                addq.w  #2,a5
                add.w   #ROWDELTA,a6
                dbf     d7,.y
                movem.l (sp)+,d0-a6
                rts


PolyColor=$513e8
LeftEdges=$54f62
RightEdges=$55162


; A0 = Dest, A1 = Left Edges, A2 = Right Edges, D0 = Y0, D7 = Y1
SemiTransparentPoly
                movem.l d0-a6,-(sp)

                move.l  ([BackBufferPtr,pc]),a0

                move.l  Section0Start(pc),a4
                move.b  PolyColor(a4),d4
                lea     LeftEdges(a4),a1
                lea     RightEdges(a4),a2

                bsr     DrawSemiTransparentPoly
                movem.l (sp)+,d0-a6
                rts

SemiTransparentPoly2
                movem.l d0-a6,-(sp)

                move.l  ([BackBufferPtr,pc]),a0

                move.l  Section0Start(pc),a4
                move.b  PolyColor(a4),d4
                lea     LeftEdges(a4),a1
                lea     RightEdges(a4),a2

                bsr     DrawSemiTransparentPoly2
                movem.l (sp)+,d0-a6
                rts

                include draw.s

BLIT_ENTER      MACRO
                movem.l d0-a6,-(sp)
                lea     fake_cust(pc),a6
                ENDM

BLIT_LEAVE      MACRO
                movem.l (sp)+,d0-a6
                rts
                ENDM

                include blits.s

doblit
                BLIT_ENTER
                moveq   #0,d0
                move.w  bltsize(a6),d0
                moveq   #$3f,d1
                and.l   d0,d1
                beq     doblit_todo
                eor.l   d1,d0
                lsr.w   #6,d0
                bne     doblit_hassize
                move.w  #1024,d0
doblit_hassize
                cmp.l   #-1,bltafwm(a6)
                bne     doblit_todo
                tst.w   bltcon1(a6)
                bne     doblit_todo
                cmp.w   #$09f0,bltcon0(a6)
                beq     blitcopy
                cmp.w   #$0fca,bltcon0(a6)
                beq     blitcookie
doblit_todo
                ; XXX special case for the indicator characters
                move.w  bltcon0(a6),d2
                and.w   #$fff,d2
                cmp.w   #2,d1
                bne     .notchar1
                cmp.w   #$fca,d2
                beq     blitchar
.notchar1
                ; XXX: And text on review screen..
                cmp.w   #$bfa,d2
                beq     blitchar2

                IFNE    DEBUG
                moveq   #0,d2
                move.w  bltsize(a6),d2
                move.l  bltcon0(a6),d3
                move.l  bltafwm(a6),d4
                move.l  15*4(sp),d7
                sub.l   Section0Start(pc),d7
                move.l  bltapt(a6),a0
                move.l  bltbpt(a6),a1
                move.l  bltcpt(a6),a2
                move.l  bltdpt(a6),a3
                PRINTF <"$%05lx: Blit %ld x %ld (%04lx), bltcon=%08lx Mask=%08lx A=%lx B=%lx C=%lx D=%lx">,d7,d1,d0,d2,d3,d4,a0,a1,a2,a3

                move.l  bltdpt(a6),a0
                move.w  d0,d3
                lsr.w   #3,d3
                move.w  d1,d2
                lsl.w   #4,d2
                moveq   #15,d4
                moveq   #0,d0
                moveq   #0,d1
                bsr     DrawRect

                ENDC    ;DEBUG
                BLIT_LEAVE

doblith
                BLIT_ENTER
                move.w  bltsizv(a6),d0
                move.w  bltsizh(a6),d1
                bra     doblit_hassize

blitcookie
                move.l  bltdpt(a6),a0
                move.l  bltapt(a6),a1
                move.l  bltbpt(a6),a2
                move.l  bltcpt(a6),a3
                move.w  bltdmod(a6),a4
                move.w  bltamod(a6),d5
                move.w  bltbmod(a6),d6
                move.w  bltcmod(a6),d7
.y
                move.l  d1,d2
.x
                lsr.w   #1,d2
                bcc     .longs
                move.w  (a2)+,d3        ; d3 = b
                move.w  (a3)+,d4        ; d4 = c
                eor.w   d4,d3           ; d3 = b ^ c
                and.w   (a1)+,d3        ; d3 = (b ^ c) & a
                eor.w   d4,d3           ; d3 = ((b ^ c) & a) ^ c = (c & ~a) | (b & a)
                move.w  d3,(a0)+
                tst.w   d2
                beq     .next
.longs
                move.l  (a2)+,d3
                move.l  (a3)+,d4
                eor.l   d4,d3
                and.l   (a1)+,d3
                eor.l   d4,d3
                move.l  d3,(a0)+
                subq.w  #1,d2
                bne     .longs
.next
                add.w   a4,a0
                add.w   d5,a1
                add.w   d6,a2
                add.w   d7,a3
                subq.w  #1,d0
                bne     .y
                BLIT_LEAVE

blitcopy
                move.l  bltdpt(a6),a0
                move.l  bltapt(a6),a1
                move.w  bltdmod(a6),d3
                move.w  bltamod(a6),d4
.y
                move.l  d1,d2
.x
                lsr.w   #1,d2
                bcc     .longs
                move.w  (a1)+,(a0)+
                tst.l   d2
                beq     .next
.longs
                move.l  (a1)+,(a0)+
                subq.w  #1,d2
                bne     .longs
.next
                add.w   d3,a0
                add.w   d4,a1
                subq.w  #1,d0
                bne     .y
                BLIT_LEAVE

; Temp handler for characters in heading/veritcal indicator
;[3110] $51280: Blit 2 x 8 (0202), bltcon=07AC0000 Mask=0003FFFF A=0 B=5FF08A52 C=0 D=4A854
;[3111] $51280: Blit 4 x 8 (0204), bltcon=07AC0000 Mask=0007C000 A=0 B=5FF08B92 C=0 D=4A854
;[3112] $51280: Blit 2 x 8 (0202), bltcon=07AC0000 Mask=3FFFFFF8 A=0 B=5FF08916 C=0 D=4A854
;[3113] $51280: Blit 5 x 8 (0205), bltcon=07AC0000 Mask=0003F800 A=0 B=5FF08A52 C=0 D=4A854
;[3114] $51280: Blit 2 x 8 (0202), bltcon=07AC0000 Mask=001FFFFF A=0 B=5FF08910 C=0 D=4A854
;[3115] $51280: Blit 1 x 8 (0201), bltcon=07AC0000 Mask=07FFFFFE A=0 B=5FF08A52 C=0 D=4A854
;[3116] $51280: Blit 4 x 8 (0204), bltcon=07AC0000 Mask=07FFFFFE A=0 B=5FF08A4C C=0 D=4A854
blitchar
                move.l  bltdpt(a6),a0
                move.l  bltapt(a6),a1
                move.l  bltbpt(a6),a2
                move.l  bltcpt(a6),a3
                move.w  bltdmod(a6),d6
                move.w  bltamod(a6),d7
                move.w  bltbmod(a6),a4
                move.w  bltcmod(a6),a5
                move.w  bltcon0(a6),d1
                rol.w   #4,d1
                and.w   #15,d1          ; d1 = shift
                move.l  bltafwm(a6),d2  ; d2 = amask
.y
                move.l  d2,d3
                and.l   (a1)+,d3
                lsr.l   d1,d3           ; d3 = a
                move.l  (a2)+,d4
                lsr.l   d1,d4           ; d4 = b
                move.l  (a3)+,d5        ; d5 = c
                eor.l   d5,d4
                and.l   d3,d4
                eor.l   d5,d4
                move.l  d4,(a0)+
                add.w   d6,a0
                add.w   d7,a1
                add.w   a4,a2
                add.w   a5,a3
                subq.w  #1,d0
                bne     .y
                BLIT_LEAVE

; Used in review screen (A/C/D enabled, minterm=A+C)
;[444] $23426: Blit 1 x 128 (2001), bltcon=0BFA0000 Mask=FFFFFFFF A=5FFA1624 B=0 C=5FFA1624 D=84580
;[445] $23426: Blit 2 x 128 (2002), bltcon=CBFA0000 Mask=FFFF0000 A=5FFA3E18 B=0 C=5FFA3E18 D=84580
;[446] $23426: Blit 3 x 176 (2C03), bltcon=8BFA0000 Mask=FFFF0000 A=5FF9AFAC B=0 C=5FF9AFAC D=98A82
;[447] $23426: Blit 3 x 176 (2C03), bltcon=9BFA0000 Mask=FFFF0000 A=5FF9AF98 B=0 C=5FF9AF98 D=98A84
;[448] $23426: Blit 3 x 176 (2C03), bltcon=DBFA0000 Mask=FFFF0000 A=5FF9AFA4 B=0 C=5FF9AFA4 D=98A86
;[449] $23426: Blit 3 x 176 (2C03), bltcon=EBFA0000 Mask=FFFF0000 A=5FF9AF94 B=0 C=5FF9AF94 D=98A88
blitchar2
                move.l  bltdpt(a6),a0
                move.l  bltapt(a6),a1
                move.l  bltcpt(a6),a2
                move.w  bltcon0(a6),d3
                rol.w   #4,d3
                and.w   #15,d3
.y
                move.l  d1,d2
                move.w  bltafwm(a6),d4  ; d4 = amask
.x
                subq.w  #1,d2
                bne     .notlast
                and.w   bltalwm(a6),d4
.notlast
                and.w   (a1)+,d4        ; d4 = a
                swap    d5
                move.w  d4,d5           ; d5 = aold << 16 | a
                move.l  d5,d4
                lsr.l   d3,d4
                or.w    (a2)+,d4
                move.w  d4,(a0)+
                moveq   #-1,d4
                tst.w   d2
                bne     .x

                add.w   bltdmod(a6),a0
                add.w   bltamod(a6),a1
                add.w   bltcmod(a6),a2
                subq.w  #1,d0
                bne     .y
                BLIT_LEAVE

; Dirty (attempt) at working around crash when ScrollVPort is called from interrupt at the same time...
LoadRGB32WorkAround
                move.w  #$4000,_custom+intena
                jsr     _LVOLoadRGB32(a6)
                move.w  #$c000,_custom+intena
                rts

flight_patch    PL_START
                PL_GA   $0067e,BackBufferPtr

                PL_IFC1X 0 ; Original rendering code

                PL_IFC1X 2 ; Show FPS
                PL_PS   $00023b94,SwapBuffersOrigFps
                PL_ENDIF ; FPS

                PL_ELSE ; New rendering code

                PL_PS   $072da,FrameStart
                PL_PS   $0735e,FrameEnd

                PL_IFC1X 1 ; Frame rate limit

                PL_ELSE

                PL_NOP  $1c0fa,4        ; Skip WaitTOF in UpdatePalette
                PL_R    $23bfc          ; Don't wait for vblank to have happened
                PL_NOP  $279c6,2        ; Scan keyboard every frame (avoid flicker with glace left/right - numpad 1/3)
                PL_P    $1c110,LoadRGB32WorkAround

                PL_ENDIF ; Frame rate limit

                PL_B    $00031,1        ; Allocate graphics buffers in fast mem

                PL_P    $4165c,FillRect
                PL_P    $51c34,GradientRect

                PL_P    $511a2,SemiTransparentPoly ; Used for e.g. Helicopter rotor blades
                PL_P    $51290,SemiTransparentPoly2 ; Used for smoke

                ; $583ac ; TODO Replace me... $584A0: Blit 2 x 40 (0A02), bltcon=5FCA5000 Mask=CFFF0000, Blits characters for the rotating heading strip / vertical attack indicator
                ; $51de6 ; TODO: This seems slow

                PL_ENDIF ; Rendering code

                PL_END



                dc.b    'TAGSHERE' ; Make this section easier to find in .whdl_dump
                ; And make sure all tags are saved
tags
custom1=*+4
                dc.l    WHDLTAG_CUSTOM1_GET,0
                dc.l    WHDLTAG_CUSTOM2_GET,0
                dc.l	WHDLTAG_CUSTOM3_GET,0
autostart=*+4
                dc.l	WHDLTAG_CUSTOM4_GET,0
                dc.l	0


Section0Start   ds.l 1
BackBufferPtr   ds.l 1
topazdata       ds.l 1
timerreq        ds.b IOTV_SIZE
lasttime        ds.l 2
SavedBackBuf    ds.l 1
TempBufPtr      ds.l 1

fake_cust       ds.w 256


                IFNE DEBUG
Protected       ds.l 1
ProtectTags
                dc.l    WHDLTAG_CUST_DISABLE,bltsize
                dc.l    WHDLTAG_CUST_DISABLE,bltsizh
                dc.l    0
                ENDC DEBUG
