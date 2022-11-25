;*---------------------------------------------------------------------------
;  :Program.	IndyAtlantisHD.asm
;  :Contents.	Slave for "IndyFateOfAtlantis"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: IndyFateOfAtlantisHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

;;DEBUG
	IFD BARFLY
	OUTPUT	"IndyFateOfAtlantis.slave"
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


	IFD	DEBUG
HRTMON
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
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
;STACKSIZE = 8000
BOOTDOS
CACHE
CBDOSREAD

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

; whd/kickemu magic
; without it, game does not start because it requires the
; executable name to match (and not whdboot.exe)
; it's specific to Lucasgames (MI2 has the same issue)

BOOTFILENAME:MACRO
	dc.b	"atlantis.exe"
	ENDM
	; Vasm makes a difference between macro and equate
	; barfly doesn't, so IFD BOOTFILENAME works on BARFLY
	; but not on vasm. The following trick makes the source build
	; on both assemblers
	IFND BARFLY
BOOTFILENAME = 1
	ENDC
	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.3"
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

df0name:
	dc.b	"df0",0
savedir:
	dc.b	"",0

slv_name		dc.b	"Indiana Jones & The Fate Of Atlantis"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1992 Lucasfilm",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0


program:
	dc.b	"atlantis",0
args		dc.b	10
args_end
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

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)

    ; create iq points file if non existing or empty
    ; non-existing: makes game swap like crazy at some points
    ; empty: makes game display "cannot allocate ... shit at startup
    
        lea iq_1(pc),a0        
        bsr create_iq_file
        lea iq_2(pc),a0        
        bsr create_iq_file
        lea iq_3(pc),a0        
        bsr create_iq_file
        lea iq_4(pc),a0        
        bsr create_iq_file

    
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		; no more delete (to avoid OS swaps on savegames)

		move.l	a6,a0
		add.w	#_LVODeleteFile+2,a0
		lea	_deletefile(pc),a1
		move.l	a1,(a0)

		lea	df0name(pc),a0
		lea	savedir(pc),a1
		bsr	_dos_assign

	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l	a5,a5
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

create_iq_file
        move.l  (_resload,pc),a2
        move.l a0,a3
        jsr (resload_GetFileSize,a2)
        tst.l   d0
        bne.b   .notempty
        ; 0 or empty file: create it now or get problems later
        lea iq_points(pc),a1
        move.l  a3,a0
        move.l  #iq_points_end-iq_points,d0
        jsr (resload_SaveFile,a2)
.notempty
        rts
    
; < d1 - file pos
; < a0 - name
; < a1 - buffer

_cb_dosRead:
	cmp.b	#'1',11(a0)
	bne.b	.skip
	cmp.b	#'0',10(a0)
	bne.b	.skip
	cmp.l	#$60000,d1	; french version reads block at $640D5
	bcs.b	.skip
	cmp.l	#$76000,d1
	bcc.b	.skip
	; file atlantis.001 around the patch offset
	movem.l	d0/a0-a3,-(a7)
	move.l	a1,a3		; store buffer start

	move.l	.crack_offset(pc),d0
	bmi.b	.do_search

	move.l	a1,a0
	add.l	d0,a0
	lea	60(a0),a1
	bra.b	.bypass

	; not found already: search for the pattern
.do_search
	move.l	a1,a0
	add.l	#$16000,a1
.bypass
	lea	.protect(pc),a2
	moveq.l	#.end_protect-.protect,d0
	bsr	_hexsearch_crypt
	cmp.l	#0,a0
	beq.b	.nocrk

	; save offset for later (saves time)

	move.l	a0,a1
	sub.l	a3,a1
	lea	.crack_offset(pc),a3
	move.l	a1,(a3)

	; good answers all the time!!
	move.b	(1,a0),(3,a0)
	move.b	(1+7,a0),(3+7,a0)
	move.b	(1+7+7,a0),(3+7+7,a0)
.nocrk
	movem.l	(a7)+,d0/a0-a3
.skip
	rts

  
;* thanks to http://sed.free.fr who provided the patch .c source code!!
 ; we look for:
   ;* c8 f4 00 d3 00 19 00 c8 f5 00 d4 00 12 00 c8 f6 00 d5 00 0b 00
   ;* which corresponds to:
   ;*     [0040] (C8)     if (Var[244] == Var[211]) {
   ;*     [0047] (C8)       if (Var[245] == Var[212]) {
   ;*     [004E] (C8)         if (Var[246] == Var[213]) {
   ;* and replace 211 by 244, 212 by 245 and 213 by 246
   ;* so that the test passes whatever the user sets as response
   ;* to the question.
   ;*
.protect:
	dc.b	$c8,$f4,$00,$d3,$00,$19,$00,$c8,$f5
.end_protect:
	dc.b	$00,$d4,$00,$12,$00,$c8,$f6,$00,$d5,$00,$0b,$00
	even
.crack_offset:
	dc.l	-1

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

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

_hexsearch_crypt:
	movem.l	D1-D3/A1-A3,-(A7)
	; limit len if risk of access fault
	move.l	A0,A3
	add.l	D0,A3
	cmp.l	#CHIPMEMSIZE,A0
	beq.b	.exitfail		; A0 is exactly chipsize!!
	bcc.b	.chkfast
	; starts in chipmem
	cmp.l	#CHIPMEMSIZE,A1
	bcs.b	.maxchipok
	; end is above maxchip, whereas start is below: limit end
	move.l	#CHIPMEMSIZE,A1
	sub.l	D0,A1
.maxchipok:
	cmp.l	#CHIPMEMSIZE,A3
	bcs.b	.addrloop	; A3 < CHIPMEMSIZE too: OK
	; A3 > CHIPMEMSIZE: will trigger access fault
	sub.l	#CHIPMEMSIZE,A3
	sub.l	A3,D0	; remove extra length
	bra.b	.addrloop
	
.chkfast:
	; A0 is not in chipmem, check for in between chip and fast!
	move.l	_expmem(pc),D2
	add.l	#$40000,D2	; add kicksize
	cmp.l	d2,a0
	bcs		.exitfail   ; not fast, above maxchip: access fault: skip
	; in fastmem
	add.l	#FASTMEMSIZE,D2
	cmp.l	A3,D2
	bcc.b	.addrloop	; A3 < D2 (top fast): OK
	sub.l	d2,a3
	sub.l	a3,d0	; remove extra length
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A2,D3.L),D1	; compares it to the user string
	eor.b	#$69,D1		; XOR with magic 0x69 lucas key
	cmp.b	(A0,D3.L),D1	; gets byte
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
.exitfail
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1-D3/A1-A3
	rts

; < d7: seglist (APTR)


patch_main
	movem.l	d0-d1/a0-a2,-(a7)
	lea	program(pc),A0
	moveq.l	#0,D2
	bsr	get_section
	move.l	A1,A0
	add.l	#$30000,A1
	lea	.version(pc),A2
	moveq.l	#4,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip
	move.l	#0,(A0)		; avoid access fault
.skip
	movem.l	(a7)+,d0-d1/a0-a2
	rts

.version:
	dc.b	"5.2."
	even


; < d7 seglist
; < d2 section #
; > a1 segment
get_section
	move.l	d7,a1
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

	bsr	update_task_seglist

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
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

update_task_seglist
	movem.l	d0/a0/a6,-(a7)
	move.l	$4,A6
	sub.l	a1,a1
	jsr	(_LVOFindTask,a6)
	move.l	d0,a0
	move.l	pr_CLI(a0),d0
	asl.l	#2,d0
	move.l	d0,a0

	; store loaded segments in current task

	move.l	d7,cli_Module(a0)

	movem.l	(a7)+,d0/a0/a6
	rts

_deletefile:
	moveq.l	#-1,D0
	rts

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1		dc.l	0
		dc.l	0

iq_1
    dc.b    "iq-points",0
iq_2
    dc.b    "iq-punkte",0
iq_3
    dc.b    "points-IQ",0
iq_4
    dc.b    "punti-iq",0
    
iq_points:
	dc.b	$aa,$00,$00,$00,$66,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64
	dc.b	$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$64,$00
iq_points_end:

;============================================================================

	END
