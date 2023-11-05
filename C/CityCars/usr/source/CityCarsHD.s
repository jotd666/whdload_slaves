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
	OUTPUT	"CityCars.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================
CHIP_ONLY
	IFD	CHIP_ONLY
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
	ENDC
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
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

DECL_VERSION:MACRO
	dc.b	"1.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

slv_name		dc.b	"City Cars",0
slv_copy		dc.b	"1996 Allan Sturgess",0
slv_info		dc.b	"adapted by JOTD",10
			dc.b	"Version "
			DECL_VERSION
			dc.b	0
slv_CurrentDir:
	dc.b	0
slv_config:
        ;dc.b    "C5:B:skip introduction;"
		dc.b	0
		
libname:
	dc.b	"sturgess_disk.library",0
	EVEN


    ; for kick 3.1 use for dos too
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
	
;============================================================================
; bootblock from "Disk.1" has been loaded, no dos.library available

; A1 = ioreq ($2c+a5)
; A4 = buffer (1024 bytes)
; A6 = execbase

_bootblock:
	movem.l	d0-d1/a0-a2,-(a7)
	

	; align exe memory on round value
	IFD CHIP_ONLY
	movem.l a6,-(a7)
	move.l	$4.w,a6
	move.l  #$10000-$05A08-$4AB0,d0
	move.l  #MEMF_CHIP,d1
	jsr _LVOAllocMem(a6)
	movem.l (a7)+,a6
	ENDC
	
	move.l	a4,a1
	lea	pl_boot(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)
	
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	($c,a4)

pl_boot
	PL_START
	PL_P	$00102,jumper
	PL_END

	
jumper:
	move.l	a5,a1
	lea		pl_boot2(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	jmp		(a5)
	
pl_boot2:
	PL_START
	PL_P	$488,wait_and_return	; replaces dos.Delay, else it locks up!!
	;PL_NOP	$36c,4			; remove freemem
	PL_PS	$4ae,patch_intro
	PL_END

wait_and_return:
	move.w	#40,d1
.w
	move.w	#1000,d0
	bsr		beamdelay
	dbf		d1,.w
	rts


	
patch_intro:
	move.l	(a7),a1
	move.l	(a1),a1
	move.l	a1,(a7)
	lea		pl_intro(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	
	rts

; < A3: source
; < A5: end (redundant with D3=size)
; < A4: destination	
copy_program_memory:
	movem.l	d3/a3-a5,-(a7)
.loop
	CMPA.L	A3,A5			;3966e: bbcb
	BEQ.S	.out		;39670: 670c
	MOVE.B	(A3)+,(A4)+		;39672: 18db
	SUBQ.L	#1,D3			;39674: 5383
	ADDQ.L	#1,D0			;39676: 5280
	TST.L	D3			;39678: 4a83
	beq.b	.out
	BRA.S	.loop		;3967c: 60f0
.out
	movem.l	(a7)+,d3/a3-a5
	; check if something must be patched in what is been loaded
	; (use "S proggy rA1 rA5-rA3" to save)
	; only problem is that this loading copy routine comes BEFORE
	; relocation. Just be careful when patching. Fortunately there are
	; a lot of room with PC-relative shit
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	move.l	a4,a1
	add.l	#$27530,a4
	cmp.l	#$30390dff,(a4)
	bne.b	.not1
	lea		pl_main(pc),a0
	jsr		resload_Patch(a2)
	bra.b	.done
.not1
	cmp.l	#$496E7365,($E76-$9D8,a1)
	bne.b	.not2
	lea		required_disk(pc),a0
	lea		($e18-$9D8,a1),a4
	move.l	a4,(a0)
	lea		pl_loader2(pc),a0
	jsr		resload_Patch(a2)
	bra.b	.done
	nop
.not2
.done
	movem.l	(a7)+,d0-d1/a0-a2
	rts
	
disk_change:
	movem.l	a0/a1,-(a7)
	lea	_trd_disk(pc),a0
	move.l	required_disk(pc),a1
	move.b	(1,a1),(a0)		; currently requested disk
	lea	_trd_chg(pc),a0
	move.b	#%1111,(a0)	; disk changed
	movem.l	(a7)+,a0/a1
	rts
	
ecs_test:
	move.l	chiprev_bits(pc),d0
	and.l	#SETCHIPREV_ECS,d0
	bne.b	.ecs
	moveq	#0,d0	; ATM OCS
	rts
.ecs
	move.w	#$FC,d0		; ECS is all that this game supports
	rts
	
pl_loader2:
	PL_START
	PL_NOP	$2bf1a-$2b9d8,2
	PL_NOP	$2bf24-$2b9d8,2
	PL_P	$2bf26-$2b9d8,disk_change
	PL_END
	
pl_main:
	PL_START
	PL_PS	$c7470-$9FF40,ecs_test
	PL_PS	$c9440-$9FF40,keyboard_hook
	PL_END
	
pl_intro:
	PL_START
	;PL_NOP	$3803c-$37f40,4		; skip intro/protection, but doesn't work afterwards!
	
	PL_PSS	$3966e-$37f40,copy_program_memory,10
	PL_R	$38b62	; disk ready
	
	PL_NOP	$38b64-$37f40,16	; skip CIA floppy poke
	PL_NOP	$38b82-$37f40,8	; skip CIA floppy poke
	PL_R	$38c34-$37f40		; skip a whole routine full of CIA shit
	PL_R	$38c02-$37f40		; skip a whole routine full of CIA shit
	PL_R	$38b90-$37f40		; skip CIA floppy poke
	PL_R	$38ba2-$37f40		; skip CIA floppy poke
	
	PL_NOP	$4387a-$37f40,2		; skip protection check
	PL_I	$38052-$37f40		; skip infinite loop
	PL_END
	

keyboard_hook:
	move.b	$BFEC01,d0
	cmp.b	_keyexit(pc),d0
	beq.b	quit
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

quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


_tag		dc.l	WHDLTAG_CHIPREVBITS_GET
chiprev_bits
		dc.l	0
		dc.l	0

 

required_disk:
	dc.l	0
;============================================================================

	END

