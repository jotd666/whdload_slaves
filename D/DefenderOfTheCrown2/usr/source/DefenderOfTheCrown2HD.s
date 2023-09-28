;*---------------------------------------------------------------------------
;  :Program.	DefenderOfTheCrown2HD.asm
;  :Contents.	Slave for "DefenderOfTheCrown2"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: DefenderOfTheCrown2HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"DefenderOfTheCrown2.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;struct CDTVPrefs
;{
;	WORD 	DisplayX;	/* Default display View offset	*/
;	WORD	DisplayY;	/* Default display View offset	*/
;	UWORD	Language;	/* Human interface language	*/
;	UWORD	AudioVol;	/* Default audio volume		*/
;	UWORD	Flags;		/* Preference flags		*/
;	UBYTE	SaverTime;	/* In Minuites 			*/
;	UBYTE	Reserved;	/* Future function		*/
;};


;============================================================================

;;DEBUG
	IFD	DEBUG
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $0
HRTMON
	ELSE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
CACHE
;INITAGA
HDINIT
;IOCACHE		= 1000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 10000
BOOTDOS
;;CBDOSLOADSEG = 1
NO68020

;============================================================================

slv_Version	= 17
slv_Flags =	WHDLF_NoError|WHDLF_Examine
slv_keyexit =	$5D			;ws_keyexit = F10

;============================================================================

	INCLUDE	whdload/kick13.s	; 13 also works but sound is strange

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
DECL_VERSION:MACRO
	dc.b	"1.2"
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


_assign1
	dc.b	"Defender_2",0
_assign2
	dc.b	"CD0",0

slv_name		dc.b	"Defender Of The Crown 2 CD³²/CDTV"
	IFD	DEBUG
	dc.b	" (debug mode)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1993 Commodore Electronics",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	10,"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config		
	dc.b	"C1:B:force english language;"
	dc.b	"C2:L:language:auto,english,english,german,french,spanish,italian;"
	dc.b	0	

;_joymouse
;	dc.b	"joymouse",0

_bookit
	dc.b	"bookit",0
_biargs
	dc.b	"j",10
_biargs_end
	dc.b	0
_program:
	dc.b	"proj2",0
_args		
	dc.b	"open.film",10
_args_end
	dc.b	0
	EVEN


; < D0: BSTR filename
; < D1: seglist
	IFEQ	1
_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	add.l	#1+8,a0
	cmp.b	#'c',(a0)+
	bne.b	.out
	cmp.b	#'d',(a0)+
	bne.b	.out
	cmp.b	#'t',(a0)+
	bne.b	.out
	cmp.b	#'v',(a0)+
	bne.b	.out
	cmp.b	#'s',(a0)+
	bne.b	.out
	
	; cdtvs_mod program
	illegal
.out
	rts
	ENDC

_bootdos
	clr.l	$0.W

	move.l	(_resload,pc),a2		;A2 = resload


	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open playerprefs lib
		lea	(_playerprefsname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		tst.l	d0
		beq	_pperror
.ok
		move.l	d0,a3

		move.l	a3,a0
		add.w	#-54+2,a0	; FillCDTVPrefs to set current system language
		lea	_fillcdtv_save(pc),a1
		move.l	(a0),(a1)
		lea	_fillcdtv(pc),a1
		move.l	a1,(a0)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;check for correct language directory

		bsr	_check_language_dir

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	patch_cdtv
	;load exe
		lea	_bookit(pc),a0
		lea	_biargs(pc),a1
		moveq	#_biargs_end-_biargs,d0
		sub.l	a5,a5
		bsr	_load_exe

;		lea	_joymouse(pc),a0
;		bsr	_execute_exe

	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patch_proj2(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

_fillcdtv_save:
	dc.l	0

_fillcdtv:
	move.l	a0,-(a7)
	pea	.next(pc)
	move.l	_fillcdtv_save(pc),-(a7)
	rts
.next
	move.l	(a7)+,a0
	move.w	_language+2(pc),4(a0)	; set user-required language
	rts


; < d7: seglist

_patch_proj2
	move.l	d7,a1
	addq.l	#4,a1
	move.l	a1,$100
	rts

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
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
	movem.l	d2/d7/a2/a4,-(a7)
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	movem.l	(a7)+,d2/d7/a2/a4
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
	jsr	(_LVOIoErr,a6)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

; < a0: progs+args to execute
; < a6: dosbase

;_execute_exe:
;	movem.l	d1-a6,-(a7)
;	move.l	a0,d1
;	moveq.l	#0,d2
;	moveq.l	#0,d3
;	jsr	(_LVOExecute,a6)
;	movem.l	(a7)+,d1-a6
;	rts

;.end
;	move.l	a3,-(a7)
;	pea	205			; file not found
;	pea	TDREASON_DOSREAD
;	move.l	(_resload,pc),-(a7)
;	add.l	#resload_Abort,(a7)
;	rts

_check_language_dir:
	lea	.language_dir(pc),a1
	move.l	_custom2(pc),d1
	beq.b	.notforced
	lea	_language(pc),a0
	move.l	d1,(a0)
.notforced
	move.l	_custom1(pc),d1
	bne.b	.forced_to_english	; CUSTOM1!=0: force english
	move.l	_language(pc),D1
.forced
	cmp.b	#1,d1
	beq.b	.english
	cmp.b	#2,d1
	beq.b	.english
	cmp.b	#3,D1
	beq.b	.german
	cmp.b	#4,D1
	beq.b	.french
	cmp.b	#5,D1
	beq.b	.spanish
	cmp.b	#6,D1
	beq.b	.italian

.forced_to_english
	lea	_language(pc),a0
	move.l	#2,(a0)		; set english by default
.english:
	move.w	#'EN',(A1)
	bra.b	.out
.spanish:
	move.w	#'SP',(A1)
	bra.b	.out
.italian:
	move.w	#'IT',(A1)
	bra.b	.out
.french:
	move.w	#'FR',(A1)
	bra.b	.out
.german
	move.w	#'GE',(A1)
	bra	.out
.out
	move.l	a1,d1
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	tst.l	d0
	beq.b	.notfound
	move.l	d0,d1
	jsr	_LVOUnLock(a6)
	rts

.notfound
	lea	.language_dir(pc),a1
	move.l	a1,-(a7)
	pea	205			; language directory not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts	

.language_dir:
	dc.b	"XX",0
	even


; exit with error if playerprefs libs is not there

_pperror
	jsr	(_LVOIoErr,a6)
	pea	_fullppname(pc)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


_fullppname:
	dc.b	"libs/"
_playerprefsname
	dc.b	"playerprefs.library",0

	even
_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	WHDLTAG_LANG_GET
_language	dc.l	0
		dc.l	0
	;;IFEQ	1

PATCH_IO:MACRO
	move.l	$4.W,a0
	add.w	#_LVO\1+2,a0
	lea	.\1_save\@(pc),a1
	move.l	(a0),(a1)
	lea	.\1\@(pc),a1
	move.l	a1,(a0)
	bra.b	.cont\@
.\1_save\@:
	dc.l	0
.\1\@:
	lea	_fake_cdtvbase(pc),A0
	cmp.l	IO_DEVICE(a1),A0
	beq.b	.ignore\@
	bra.b	.org\@
;;	cmp.l	#$B0DEB0DE,IO_DEVICE(a1)
;;	beq.b	_handle_bookmark
	; ignore (cdtv.device)
.ignore\@
	moveq.l	#0,D0
	rts
.org\@
	move.l	.\1_save\@(pc),-(A7)
	rts
.cont\@
	ENDM

patch_cdtv:
	movem.l	d0-A6,-(a7)
	move.l	4.W,a0
	add.w	#_LVOOpenDevice+2,a0
	lea	_opendev_save_2(pc),a1
	move.l	(a0),(a1)
	lea	_opendev_2(pc),a1
	move.l	a1,(a0)

	move.l	4.W,a0
	add.w	#_LVOCloseDevice+2,a0
	lea	_closedev_save_2(pc),a1
	move.l	(a0),(a1)
	lea	_closedev_2(pc),a1
	move.l	a1,(a0)

	PATCH_IO	DoIO
	PATCH_IO	SendIO
	; patch so CheckIO always returns 0: cdtvs_mod exe believes that
	; the cd track is still playing and the "go raiding" section works
	; (else, since there's no CD audio, the game thinks the track is over
	; and there's a timeout => you lose)

	PATCH_IO	CheckIO
	PATCH_IO	WaitIO
	PATCH_IO	AbortIO
	movem.l	(A7)+,D0-A6
	rts

_closedev_2:
	move.l	IO_DEVICE(a1),D0
	lea	_fake_cdtvbase(pc),a0
	cmp.l	a0,d0
	beq.b	.out
	cmp.l	#$B0DEB0DE,D0
	beq.b	.out

.org
	move.l	_closedev_save_2(pc),-(a7)
	rts

.out
	moveq	#0,D0
	rts

GETLONG:MACRO
		move.b	(\1),\2
		lsl.l	#8,\2
		move.b	(1,\1),\2
		lsl.l	#8,\2
		move.b	(2,\1),\2
		lsl.l	#8,\2
		move.b	(3,\1),\2
		ENDM

_opendev_2:
	movem.l	D0,-(a7)
	GETLONG	A0,D0
	cmp.l	#'cdtv',D0
	beq.b	.cdtv
	cmp.l	#'book',D0
	beq.b	.bookmark
	bra.b	.org

	; cdtv device
.cdtv
	pea	_fake_cdtvbase(pc)
	move.l	(A7)+,IO_DEVICE(a1)
.exit
	movem.l	(A7)+,D0
	moveq.l	#0,D0
	rts

.org
	movem.l	(A7)+,D0
	move.l	_opendev_save_2(pc),-(a7)
	rts

.bookmark:
	move.l	#$B0DEB0DE,IO_DEVICE(a1)
	bra.b	.exit

; all functions do nothing

	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
	rts
	nop
	nop
_fake_cdtvbase:
	illegal

	
_opendev_save_2:
	dc.l	0
_closedev_save_2:
	dc.l	0
	
;============================================================================

	END
