	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

	IFD BARFLY
    IFD TWOMEGS
	OUTPUT	"Worms2megs.slave"
    ELSE
	OUTPUT	"Worms.slave"
    ENDIF
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
    
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DEBUG
;DISKSONBOOT
;DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS
;============================================================================

    IFD TWOMEGS
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $80000
    ELSE
    ; any attempt to set $80000 chip makes game crash just before round starts
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
    ENDIF
    
slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s



;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

slv_name
	IFND	TWOMEGS
		dc.b	"Worms (1MB Chip)",0
	ELSE
		dc.b	"Worms (2MB Chip)",0
	ENDC
slv_copy		dc.b	"1992 Team 17",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version 1.1 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

_program:
	dc.b	"Worms",0
_args		dc.b	10
_args_end
	dc.b	0
	EVEN

;============================================================================
;============================================================================

	;initialize kickstart and environment

_bootdos	move.l	(_resload,pc),a2		;A2 = resload

	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_NC|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		
	;assigns
;		lea	_assign(pc),a0
;		sub.l	a1,a1
;		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	.end

	;patch
;		lea	_pl1,a0
;		move.l	d7,a1
;		jsr	(resload_PatchSeg,a2)

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

	;call
		move.l	d7,a1
		add.l	a1,a1
		add.l	a1,a1

		bsr	_patchexe

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

.end		moveq	#0,d0
		rts



_patchexe:
	movem.l	D0-A6,-(A7)
	move.l	A1,A0
	add.l	#$4000,A1
	lea	.protect(pc),a2
	moveq	#8,D0
	bsr	_hexsearch
	cmp.l	#0,A0
	beq.b	.noprot
	move.b	#$60,(A0)
.noprot
	bsr	_flushcache
	movem.l	(A7)+,D0-A6
	rts

.protect:
	dc.l	$670000BC,$102D81E0

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
