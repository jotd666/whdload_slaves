	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
	DOSCMD	"WDate  >T:date"

;DEBUG

	OUTPUT	"Castles.slave"
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


	IFD	DEBUG
CHIPMEMSIZE	= $17F000
FASTMEMSIZE	= 0
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $FF000
FASTMEMSIZE	= $80000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
;DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

;============================================================================

DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Castles"
	IFD	DEBUG
	dc.b	"(DEBUG MODE) "
	ENDC
	dc.b	0
slv_copy		dc.b	"1991 Interplay",0
slv_info		dc.b	"installed & fixed by Bored Seal & JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_file		dc.b	"Castles",0
_args		dc.b	10
_args_end
		dc.b	0
		even

;============================================================================

	;initialize kickstart and environment

_bootdos	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;load exe
		lea	_file(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	_end

		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1
		move.l	a1,d7
		movem.l	D0-A6,-(a7)
		bsr	patchexe
		movem.l	(a7)+,d0-a6
		add.l	#4,a1

		move.l	(4,a7),d0		;stacksize
		sub.l	#5*4,d0			;required for MANX stack check
		movem.l	d0-d2/d7/a0-a2/a6,-(a7)
		moveq	#_args_end-_args,d0
		lea	(_args,pc),a0
		jsr	(a1)
		movem.l	(a7)+,d0-d2/d7/a0-a2/a6


WaitForEver	moveq	#0,D0
		move.l	$4.W,A6
		jsr	_LVOWait(a6)		; wait forever
		illegal				; never reached

_end		pea	TDREASON_OK
		move.l	_resload(pc),a2
		jmp	(resload_Abort,a2)



patchexe

	moveq.l	#2,d2
	bsr	get_section

	move.l	(a1),d0
	cmp.l	#$48E73120,d0
	beq.b	.english ; english version: code section is section 2

	; german?

.german
	moveq.l	#3,d2
	bsr	get_section
	move.l	(a1),d0
	cmp.l	#$48E73120,d0
	bne	wrong_version

	lea	pl_german(pc),a0
	bra.b	.patch_s2
.english
	moveq.l	#0,d2
	bsr	get_section
	lea	pl_section_0_english(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	moveq.l	#2,d2
	bsr	get_section
	lea	pl_english(pc),a0
.patch_s2
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	rts

wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

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

fix_af_3
	MOVE	D0,(-20,A5)		;1F036: 3B40FFEC

	cmp.l	#$0,A1
	beq.b	.skip
	
	MOVEA.L	(64,A1),A3		;1F032: 26690040

	; still problem here: sometimes A3 not valid

	movem.l	d0/d1,-(a7)

	move.b	(64,a1),d0
	beq.b	.ok
	
	move.b	_expmem(pc),d1
	cmp.b	d1,d0
	beq.b	.ok

	; not 0, not expmem MSB: access fault: we do nothing an avoid it
	movem.l	(a7)+,d0/d1
	bra.b	.skip
	
.ok
	movem.l	(a7)+,d0/d1

	rts
.skip
	moveq.l	#0,d0
	add.l	#$4C-38,(a7)	; skip, since pointer is null, would trigger AF
	rts



fix_af_2
	cmp.l	#$DFF000,a0
	bne.b	.ok
	; avoid access fault
	clr.l	(a6)
	ADDQ.L	#4,D1			;250DC: 5881
	rts
.ok
	MOVE.L	(0,A0,D1.L),(A6)	;250D8: 2CB01800
	ADDQ.L	#4,D1			;250DC: 5881
	rts

fix_af_1:
	move.l	A0,A3

	move.l	A3,-(A7)
	tst.l	(A7)
	bmi.b	.avoid

	tst.b	($12,A3)
.out
	addq.l	#4,A7
	rts

.avoid:
	moveq.l	#0,D0
	bra.b	.out

avoid_kill_vbl
	cmp.l	#0,A0
	beq.b	.avoid
	clr.b	($6C,A0)
.avoid
	clr	(-6682,A4)
	rts

avoid_kill_vbl_german
	cmp.l	#0,A0
	beq.b	.avoid
	clr.b	($6C,A0)
.avoid
	clr	(-6546,A4)
	rts

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

flush_and_forbid
	MOVEA.L	4.W,A6	;00130: 2C780004
	JSR	(_LVOForbid,A6)		;00134: 4EAEFF7C
	addq.l	#2,(a7)
	bsr	_flushcache
	rts

dmacon_wait
	movem.l	d0,-(a7)
	move.l	#8,d0
	bsr	beamdelay
	movem.l	(a7)+,d0
	addq.l	#2,(a7)
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


pl_section_0_english
	PL_START
	; avoid SMC / cache problem (not present in german version which does a cacheclear!)

	PL_PS	$130,flush_and_forbid
	PL_END
	
pl_english
	PL_START

	; quit without access fault

	PL_P	$2738C-$98D8,quit

	; VBL interrupt was cleared

	PL_PS	$106AC-$98D8,avoid_kill_vbl
	PL_W	$106AC+6-$98D8,$4E71
	
	; protection

	PL_W	$260F0-$98D8,$297C
	PL_B	$260F8-$98D8,$50

	; access fault #1

	PL_PS	$16DCC-$98D8,fix_af_1

	; access fault #2: read to $DFFxxx

	PL_PS	$250D8-$98D8,fix_af_2

	; access fault #3: null pointer read

	PL_PS	$1F032-$98D8,fix_af_3
	PL_W	$1F038-$98D8,$4E71

	; fix music dbfs

	PL_PS	$1A774-$98D8,dmacon_wait
	PL_PS	$25244-$98D8,dmacon_wait
	PL_PS	$2525A-$98D8,dmacon_wait
	PL_PS	$25996-$98D8,dmacon_wait
	PL_PS	$259AC-$98D8,dmacon_wait

	PL_END

pl_german
	PL_START
	; quit without access fault

	PL_P	$281D2-$9E14,quit

	; VBL interrupt was cleared

	PL_PS	$10FCA-$9E14,avoid_kill_vbl_german
	PL_W	$10FCA+6-$9E14,$4E71
	
	; protection

	PL_W	$26EC0-$9E14,$297C
	PL_B	$26EC8-$9E14,$50

	; access fault #1

	PL_PS	$179D4-$9E14,fix_af_1

	; access fault #2

	PL_PS	$25EA8-$9E14,fix_af_2

	; access fault #3: null pointer read

	PL_PS	$1FD22-$9E14,fix_af_3
	PL_W	$1FD28-$9E14,$4E71

	; fix music dbfs

	PL_PS	$1B3F8-$9E14,dmacon_wait
	PL_PS	$26014-$9E14,dmacon_wait
	PL_PS	$2602A-$9E14,dmacon_wait
	PL_PS	$26766-$9E14,dmacon_wait
	PL_PS	$2677C-$9E14,dmacon_wait

	PL_END
