;*---------------------------------------------------------------------------
;  :Program.	MonkeyIsland2HD.asm
;  :Contents.	Slave for "MonkeyIsland2"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: MonkeyIsland2HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"MonkeyIsland2.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
HDINIT
HRTMON
IOCACHE		= 5000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE
CBDOSREAD
POINTERTICKS=1

; whd/kickemu magic
; without it, game does not start because it requires the
; executable name to match (and not whdboot.exe)
; it's specific to Lucasgames (Indy4 has the same issue)

BOOTFILENAME:MACRO
	dc.b	"monkey2.exe"
	ENDM

	; Vasm makes a difference between macro and equate
	; barfly doesn't, so IFD BOOTFILENAME works on BARFLY
	; but not on vasm. The following trick makes the source build
	; on both assemblers
	IFND BARFLY
BOOTFILENAME = 1
	ENDC
;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s


;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"Secret Of Monkey Island 2",0
slv_copy		dc.b	"1992 Lucasfilm Games",0
slv_info		dc.b	"Install & fix by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"monkey2"
	dc.b	0
_args		dc.b	10
_args_end
	dc.b	0
_df0:
	dc.b	"DF0",0
	even


;============================================================================

PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	old_\1(pc),a0
	move.l	A1,(A0)+

	move.l	A6,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)		; moves to d0_value_xxx

	move.w	#$4EF9,(A1)+	
	pea	new_\1_init(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
new_\1_init
	move.l	d0_value_\1(pc),d0
	bra	new_\1
old_\1:
	dc.l	0
d0_value_\1
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
	ENDM

	
	;initialize kickstart and environment

_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		
		PATCH_DOSLIB_OFFSET	Open

		lea	_df0(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign


	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end			;file not found

	;patch here
		bsr	_patchit
		bsr	_flushcache

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		lea	(_args,pc),a0
		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0/d7/a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		jsr	(4,a1)
		movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
		move.l	d7,d1
		jsr	(_LVOUnLoadSeg,a6)

		pea	TDREASON_OK
		jmp	(resload_Abort,a2)

_end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

new_Open:
	move.l	D0,-(A7)
	cmp.l	#MODE_NEWFILE,d2
	bne	.end
	; D1: df0:filename of the savegame.
	; First check that it's really a savegame (who knows???)
	move.l	d1,a0
	addq.l	#4,a0
	bsr	get_long
	cmp.l	#"save",d0
	bne	.end
	; it's a savegame. In A0 we have the name. Check if the size is okay
	movem.l	d1/a2/a3,-(a7)
	move.l	a0,a3		; save filename
	move.l	_resload(pc),a2
	jsr	(resload_GetFileSize,a2)
	cmp.l	#30000,d0	
	bcc.b	.big_enough
	; file is smaller than 30kb, means that it will flash on gamesave
	; (because it's a stub or it doesn't exist). Create the file beforehand
	; with trash in it, the contents don't matter as it'll be overwritten
    move.l  #40000,d0                 ;size
	move.l 	a3,a0           ;name
	sub.l	a1,a1            ;source
	jsr     (resload_SaveFile,a2)	
.big_enough
	movem.l	(a7)+,d1/a2/a3
.end
	move.l	(a7)+,d0
	move.l	old_Open(pc),-(a7)
	rts
	
; < A0: address
; > D0: longword
get_long
	move.l	a0,-(a7)
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	move.l	(a7)+,a0
	rts
; < d1 - file pos
; < a0 - name
; < a1 - buffer

_cb_dosRead
	cmp.b	#'1',10(a0)
	bne.b	.skip
	cmp.b	#'0',9(a0)
	bne.b	.skip
	cmp.l	#$49000,d1
	bcs.b	.skip
	cmp.l	#$4A000,d1
	bcc.b	.skip
	movem.l	d0/a0-a3,-(a7)
	move.l	a1,a3		; store buffer start

	move.l	.crack_offset(pc),d0
	bmi.b	.do_search

	move.l	a1,a0
	add.l	d0,a0
	lea	8(a0),a1
	bra.b	.bypass

	; not found already: search for the pattern
.do_search
	move.l	a1,a0
	lea	$1000(a0),a1
.bypass
	lea	.protect(pc),a2
	moveq.l	#4,d0
	bsr	_hexsearch
	cmp.l	#0,a0
	beq.b	.nocrk
	
	; save offset for later (saves time)

	move.l	a0,a1
	sub.l	a3,a1
	lea	.crack_offset(pc),a3
	move.l	a1,(a3)

	move.b	#$71,(a0)+
	move.b	#$4F,(a0)+
	move.b	#$69,(a0)+
	move.b	#$11,(a0)+
.nocrk
	movem.l	(a7)+,d0/a0-a3
.skip
	rts
.protect:
	dc.l	$E16F6B83

.crack_offset:
	dc.l	-1

_patchit:
	move.l	A2,-(A7)
	move.l	D7,A5
	add.l	A5,A5
	add.l	A5,A5
	move.l	A5,A0
	move.l	A5,A1
	add.l	#$30000,A1
	lea	.version(pc),A2
	moveq.l	#4,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip
	move.l	#0,(A0)		; avoid access fault
.skip
	move.l	A5,A0
	move.l	A5,A1
	add.l	#$30000,A1
	lea	.avoid_af(pc),A2
	moveq.l	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.skip2
	subq	#8,a0
	move.w	#$4EF9,(a0)+
	pea	_entry(pc)
	move.l	(a7)+,(a0)
.skip2
	move.l	(A7)+,A2
	rts

.version:
	dc.b	"5.2."
	dc.w	$B240

.avoid_af:
	dc.l	$E64E5346,$34064A19

	; stolen code

TESTA1:MACRO
	cmp.l	_expmem(pc),a1
	bcc.S	.ok\@
	cmp.l	#CHIPMEMSIZE,a1
	bcc.S	.out2		; avoids access fault
.ok\@
	TST.B	(A1)+
	BNE.S	.out
	ENDM

_entry:
	LSR	#3,D6			;08: E64E
	SUBQ	#1,D6			;0A: 5346
.LAB_0001:
	MOVE	D6,D2			;0C: 3406
.LAB_0002:
	TESTA1
	TESTA1
	TESTA1
	TESTA1
	DBF	D2,.LAB_0002		;1E: 51CAFFEE
	SUBA	D1,A1			;22: 92C1
	DBF	D5,.LAB_0001		;24: 51CDFFE6
	MOVEQ	#0,D0			;28: 7000
	MOVEM.L	(A7)+,D2-D6		;2A: 4CDF007C
	RTS				;2E: 4E75
.out2:
.out:
	MOVEQ	#1,D0			;00: 7001
	MOVEM.L	(A7)+,D2-D6		;02: 4CDF007C
	RTS				;06: 4E75


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

;============================================================================


;============================================================================

	END
