;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"MAyday.Slave"
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
FASTMEMSIZE	= $0
NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT
;HDINIT
;HRTMON
;MEMFREE	= $100
;NEEDFPU
;SETPATCH
BOOTBLOCK

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

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

slv_name		dc.b	"Mayday Squad",0
slv_copy		dc.b	"1989 Tynesoft",0
slv_info		dc.b	"adapted by Bored Seal & JOTD",10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	0
slv_config:
	dc.b	"BW;"

	EVEN


;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available

; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock:
	movem.l	d0-d1/a0-a2,-(a7)	
	move.l	a4,a1
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	jmp	($c,a4)

pl_boot
	PL_START
	PL_P	$104,patch_main
	PL_NOP	$5d18-$5c40,4	; skip superstate
	PL_NOP	$5d0a-$5c40,4	; skip userstate
	PL_END

patch_main
	move.l	$ED30,d0
	lea		pl_main_fr(pc),a0
	cmp.l	#$1F986,d0
	beq.b	.p
	lea	pl_main_v1(pc),a0
	cmp.l	#$1fa2a,d0
	beq.b	.p
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
.p
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		(resload_Patch,a2)
	jmp	$ed2e

pl_main_v1
	PL_START
	PL_W	$ed44,$6002		;remove resetproof code
	PL_W	$f0d2,$6002		;remove resetproof code
	PL_PS	$F578,crack_v1
	PL_IFBW
	PL_PS	$EF42,ButtonWait_v1
	PL_ENDIF
	PL_R	$1de58
	
	PL_PSS	$1983e,BeamDelay,2
	PL_PSS	$1e2a0,BeamDelay,2
	PL_PSS	$1e2f6,BeamDelay,2
	PL_PSS	$1eb06,BeamDelay,2

	PL_PSS	$0f124,big_delay_d7,2
	PL_PSS	$18334,big_delay,2
	
	PL_PSS	$11688,kbint_hook,4
	
	PL_P	$10558,wait_blit
	PL_P	$103b8,wrap_intro_blit_v1
	PL_END

pl_main_fr
	PL_START
	PL_W	$ed44,$6002		;remove resetproof code
	PL_W	$f0d2,$6002		;remove resetproof code
	PL_PS	$F578,crack_v1
	PL_IFBW
	PL_PS	$EF42,ButtonWait_fr
	PL_ENDIF
	PL_R	$1dd90
	
	PL_PSS	$1989a,BeamDelay,2
	PL_PSS	$1e1d6,BeamDelay,2
	PL_PSS	$1e22c,BeamDelay,2
	PL_PSS	$1ea3a,BeamDelay,2

	PL_PSS	$0f124,big_delay_d7,2
	PL_PSS	$18396,big_delay,2
	
	PL_PSS	$1169c,kbint_hook,4
	PL_P	$103f4,wrap_intro_blit_fr
	PL_END
	
wrap_intro_blit_fr
	move.l	$fcd4,A2
	jsr		$103fa
	bra.b	wait_blit
	
wrap_intro_blit_v1
	move.l	$FCDC,A2
	jsr		$103BE
	; at the end of the routine, blitter is running
	; I suspect that some other routine changes some blitter
	; register. Calling a blitwait here fixes graphical corruption
	; during the intro sequence
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts


kbint_hook
	BSET	#0,3584(A1)		;11688
	NOT.B	D2			;1168e: 4602
	ROR.B	#1,D2			;11690: e21a
	cmp.b	_keyexit(pc),d2
	beq.b		_quit
	rts


_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
	; if protection isn't cracked, you start the mission
	; but without any weapons!!
crack_v1
	movem.l	d0-d1/a0-a2,-(a7)
	lea		pl_crack_v1(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		(resload_Patch,a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	$24600
	
pl_crack_v1
	PL_START
	PL_W	$24616,$6016		;remove protection
	PL_B 	$24816,$60
	PL_B  	$2483e,$60
	PL_R	$24854
	PL_END


	
big_delay_d7
	move.l	d0,d7
	move.w	#$C000/28,d0
	bsr.b	BM_1
	
	move.l	d7,d0
	rts
	
ButtonWait_v1
		bsr	bw
		jmp	$18224
ButtonWait_fr
		bsr	bw
		jmp	$18286

bw
		movem.l	a0,-(sp)
		lea	$bfe001,a0
.test	
		btst	#6,(a0)
		beq	.ButtonPressed
		btst	#7,(a0)
		bne.b	.test
.ButtonPressed	movem.l	(sp)+,a0
	rts

big_delay
	move.w	#$8000/28,d0
	bra.b	BM_1

BeamDelay	moveq	#3,d0
BM_1		move.w  d0,-(sp)
		move.b	$dff006,d0	; VPOS
BM_2		cmp.b	$dff006,d0
		beq	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
		rts
		

