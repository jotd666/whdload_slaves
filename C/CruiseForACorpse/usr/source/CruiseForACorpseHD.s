;*---------------------------------------------------------------------------
;  :Program.	CruiseForACorpseHD.asm
;  :Contents.	Slave for "CruiseForACorpse"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: CruiseForACorpseHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"CruiseForACorpse.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

;DEBUG

	IFND	DEBUG
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $A0000
BLACKSCREEN
	ELSE
CHIPMEMSIZE	= $120000
FASTMEMSIZE	= $0000
HRTMON
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 30000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
;BOOTDOS
CBDOSLOADSEG
CACHE


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulDivZero
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	whdload/kick13.s

;============================================================================

;todo:
; - fix sound dma problem in intro

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

jff_assign
	dc.b	"JFF",0

ram_string:
	dc.b	"RAM:",0


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

slv_name		dc.b	"Cruise for a corpse / Croisiere pour un cadavre"
	IFD	DEBUG
	dc.b	" (DEBUG MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1991 Delphine Software",0
slv_info		dc.b	"adapted & fixed by JOTD",10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

	EVEN


; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#'c',1(a0)
	bne.b	.skip_prog
	cmp.b	#'r',2(a0)
	bne.b	.skip_prog

	addq.l	#1,a0
	bsr	get_version

	move.l	d1,d7
	bsr	patch_exe

	;get tags
	move.l	(_resload,pc),a2		;A2 = resload
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)
	
	rts

.skip_prog
	; disable all other programs (cracktros, add21k, etc...)
	move.l	d7,a0
	move.l	#$70004E75,(a0)	
	rts

; patch according to version

VERSION_PL:MACRO
.\1
	lea	current_drive_offset(pc),a0
	move.l	#-\2,(a0)
	lea	pl_\1(pc),a0	
	bra	.out
	ENDM

; < A0: executable name
; > A0: patchlist entry

get_version:
	movem.l	d0-d1/a1,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#104640,D0
	beq.b	.french

	cmp.l	#105080,D0
	beq		.italian

	cmp.l	#104864,d0
	beq.b	.spanish

	cmp.l	#104728,d0
	beq.b	.english

	cmp.l	#105168,d0
	beq.b	.german

    cmp.l   #104856,d0
    beq.b   .american
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

	VERSION_PL	french,31896
	VERSION_PL	english,31896
	VERSION_PL	spanish,31892
	VERSION_PL	german,31892
	VERSION_PL	american,31892
	VERSION_PL	italian,31892


.out
	movem.l	(a7)+,d0-d1/a1
	rts


pl_american:
	PL_START
	PL_P	$00240,quit_to_dos
	PL_P	$00610,fake_open_trd	; do not detect DFx: for save games
	PL_NOP	$00c0e,4		; access fault
	PL_PS	$02e08,intena_flush
	PL_PS	$02e2a,intena_flush
	PL_PS	$030a0,intena_flush
	PL_PS	$030c2,intena_flush
	PL_L	$05a64,$4EB80100		; crack
	PL_PS	$0c1ea,dma_sound_wait
	PL_PS	$0c218,dma_sound_wait
	PL_PS	$0c27e,dma_sound_wait
	PL_PS	$0342e,active_ffff_loop
	PL_END

; english also works for cracked italian (same length, almost identical binary)

pl_english:
	PL_START
	PL_P	$25E,quit_to_dos
	PL_P	$54A,fake_open_trd	; do not detect DFx: for save games
	PL_L	$B44,$4E714E71		; access fault
	PL_PS	$2E64,intena_flush
	PL_PS	$2E86,intena_flush
	PL_PS	$30FC,intena_flush
	PL_PS	$311E,intena_flush
	PL_L	$5B36,$4EB80100		; crack
	PL_PS	$C1E2,dma_sound_wait
	PL_PS	$C20E,dma_sound_wait
	PL_PS	$C282,dma_sound_wait
	PL_PS	$348A,active_ffff_loop
	PL_END

pl_french:
	PL_START
	PL_P	$246,quit_to_dos
	PL_P	$566,fake_open_trd	; do not detect DFx: for save games
	PL_L	$B64,$4E714E71		; fix access fault
	PL_PS	$2DAA,intena_flush
	PL_PS	$2DCC,intena_flush
	PL_PS	$3042,intena_flush
	PL_PS	$3064,intena_flush
	PL_PS	$33D0,active_ffff_loop
	PL_L	$5A06,$4EB80100		; crack
	PL_PS	$C1D0,dma_sound_wait
	PL_PS	$C1FE,dma_sound_wait
	PL_PS	$C264,dma_sound_wait
	PL_END

pl_german:
	PL_START
	PL_P	$264,quit_to_dos
	PL_P	$5C8,fake_open_trd	; do not detect DFx: for save games
	PL_L	$BC2,$4E714E71		; fix access fault
	PL_PS	$2ECE,intena_flush
	PL_PS	$2EF0,intena_flush
	PL_PS	$3166,intena_flush
	PL_PS	$3188,intena_flush
	PL_PS	$34F4,active_ffff_loop
	PL_L	$5BA0,$4EB80100		; crack
	PL_PS	$C24C,dma_sound_wait
	PL_PS	$C278,dma_sound_wait
	PL_PS	$C2EC,dma_sound_wait
	PL_END

pl_spanish:
	PL_START
	PL_P	$246,quit_to_dos
	PL_P	$610,fake_open_trd	; do not detect DFx: for save games
	PL_L	$C0E,$4E714E71		; fix access fault
	PL_PS	$2E08,intena_flush
	PL_PS	$2E2A,intena_flush
	PL_PS	$30A0,intena_flush
	PL_PS	$30C2,intena_flush
	PL_PS	$342E,active_ffff_loop
	PL_L	$5A64,$4EB80100		; crack
	PL_PS	$C1EA,dma_sound_wait
	PL_PS	$C218,dma_sound_wait
	PL_PS	$C27E,dma_sound_wait
	PL_END

pl_italian:
	PL_START
	PL_P	$240,quit_to_dos
	PL_P	$00610,fake_open_trd	; do not detect DFx: for save games
	PL_NOP	$00c0e,$4		; access fault
	PL_PS	$02e38,intena_flush
	PL_PS	$2E86,intena_flush
	PL_PS	$02e5a,intena_flush
	PL_PS	$030f2,intena_flush
	PL_L	$05a94,$4EB80100		; crack
	PL_PS	$0c25c,dma_sound_wait
	PL_PS	$0c28a,dma_sound_wait
	PL_PS	$0c2f0,dma_sound_wait
	PL_PS	$0345e,active_ffff_loop
	PL_END
	
; < d7: seglist (APTR)
; < a0: patchlist

patch_exe
	patch	$100.W,do_crack
	patch	$106.W,dbf_d0
	patch	$10C.W,dbf_d1
	patch	$11E.W,dbf_d7


	move.l	D7,A1
	addq.l	#4,a1

	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	; Fix CPU dependent DBF D0,D1,D7 loops

	bsr	.getbounds

	move.l	#$51C8FFFE,D0
	move.l	#$4EB80106,D1
	bsr	hexreplacelong
	move.l	#$51C9FFFE,D0
	move.l	#$4EB8010C,D1
	bsr	hexreplacelong
	move.l	#$51CFFFFE,D0
	move.l	#$4EB8011E,D1
	bsr	hexreplacelong


	; patch ram string in data section, replace by JFF:
	; which we assign to current dir: HD saves are now possible

.next2
	bsr	.getbounds_data
	lea	ram_string(pc),a2
	moveq.l	#4,d0
.l2
	bsr	hexsearch
	cmp.l	#0,A0
	beq.b	.exitend
	move.b	#'J',(a0)+
	move.b	#'F',(a0)+
	move.b	#'F',(a0)+
	bra.b	.l2

.exitend
	rts

.getbounds:
	move.l	D7,A1
	move.l	A1,A0
	add.l	#$17000,A1

	rts
.getbounds_data
	move.l	D7,A1
	move.l	(a1),a1
	add.l	a1,a1
	add.l	a1,a1
	move.l	a1,a0
	add.l	#$2000,a1
	rts

active_ffff_loop
	bsr	emulate_dbf
	add.l	#2,(a7)
	rts

fake_open_trd
	move.l	#$21,d0	; no drive present, for all 4 drives
	rts

quit_to_dos
	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

dma_sound_wait
	movem.l	d0,-(a7)
	move.l	#$12C,d0
	bsr	emulate_dbf	
	movem.l	(a7)+,d0
	rts

intena_flush
	bsr	_flushcache
	move.w	#$C000,$DFF09A
	add.l	#2,(a7)
	rts

dbf_d0
	bra	emulate_dbf

dbf_d1:
	movem.l	D0,-(a7)
	move.l	D1,D0
	bsr	emulate_dbf
	movem.l	(a7)+,d0
	rts
dbf_d7:
	movem.l	D0,-(a7)
	move.l	D7,D0
	bsr	emulate_dbf
	movem.l	(a7)+,d0
	rts


;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

hexsearch:
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

my_delete:
	moveq.l	#-1,D0		; always OK, but don't perform the delete
	rts



hexreplacelong:
	movem.l	A0-A1/D0-D1,-(A7)
.srch
	cmp.l	(A0),D0
	beq.b	.found
.next
	addq.l	#2,A0
	cmp.l	A1,A0
	bcc.b	.exit
	bra.b	.srch
.found
	move.l	D1,(A0)+
	bra	.next
.exit
	movem.l	(A7)+,A0-A1/D0-D1
	rts

emulate_dbf:
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	rts


; routine entered on a mouse click

do_crack
	bsr	assign_jff

	MOVEM.L	D0-D7/A0-A6,-(A7)	;3FF62: 48E7FFFE
	MOVEA.L	A3,A0			;3FF66: 204B
	LEA	-12(A0),A1		;3FF7A: 43E8FFF4

	; UK/german versions
	cmp.b	#'O',0(a3)
	bne.b	.try_french
	cmp.b	#'.',1(a3)
	bne.b	.try_french
	CMPI.B	#'0',13(A3)		;3FF7E: 0C2B0030000D
	BEQ.S	.code_entered		;3FF84: 670E
	BRA	.not_ok		;3FF92: 6060

	; french version
.try_french
	cmp.b	#'o',0(a3)
	bne.b	.try_spanish
	cmp.b	#'k',1(a3)
	bne.b	.try_spanish

	CMPI.B	#'1',13(A3)		;3FF7E: 0C2B0030000D
	BEQ.S	.code_entered		;3FF84: 670E
	BRA.S	.not_ok		;3FF92: 6060

	; spanish version
.try_spanish
	CMPI.B	#'V',(A3)		;3FF68: 0C130056
	BNE	.not_ok		;3FF6C: 66000086
	CMPI.B	#'a',1(A3)		;3FF70: 0C2B00610001
	BNE	.not_ok		;3FF76: 6600007C
	CMPI.B	#'0',13(A3)		;3FF7E: 0C2B0030000D
	BEQ.S	.code_entered		;3FF84: 670E
	LEA	-15(A0),A1		;3FF86: 43E8FFF1
	CMPI.B	#'0',10(A3)		;3FF8A: 0C2B0030000A
	BEQ.S	.code_entered		;3FF90: 6702
	BRA.S	.not_ok		;3FF92: 6060
.code_entered:

	LEA	-76(A1),A2		;3FF94: 45E9FFB4
	MOVEQ	#0,D0			;3FF98: 7000
	CMPI	#$FFFE,(A2)+		;3FF9A: 0C5AFFFE
	BEQ.S	.lab_0003		;3FF9E: 6708
	MOVE	-2(A2),(A1)+		;3FFA0: 32EAFFFE
	ADDQ	#1,D0			;3FFA4: 5240
	BRA.S	.lab_0004		;3FFA6: 6004
.lab_0003:
	MOVE	#$FFFF,(A1)+		;3FFA8: 32FCFFFF
.lab_0004:
	CMPI	#$FFFE,(A2)+		;3FFAC: 0C5AFFFE
	BEQ.S	.lab_0005		;3FFB0: 6708
	MOVE	-2(A2),(A1)+		;3FFB2: 32EAFFFE
	ADDQ	#1,D0			;3FFB6: 5240
	BRA.S	.lab_0006		;3FFB8: 6004
.lab_0005:
	MOVE	#$FFFF,(A1)+		;3FFBA: 32FCFFFF
.lab_0006:
	CMPI	#$FFFE,(A2)+		;3FFBE: 0C5AFFFE
	BEQ.S	.lab_0007		;3FFC2: 6708
	MOVE	-2(A2),(A1)+		;3FFC4: 32EAFFFE
	ADDQ	#1,D0			;3FFC8: 5240
	BRA.S	.lab_0008		;3FFCA: 6004
.lab_0007:
	MOVE	#$FFFF,(A1)+		;3FFCC: 32FCFFFF
.lab_0008:
	CMPI	#$FFFE,(A2)+		;3FFD0: 0C5AFFFE
	BEQ.S	.lab_0009		;3FFD4: 6708
	MOVE	-2(A2),(A1)+		;3FFD6: 32EAFFFE
	ADDQ	#1,D0			;3FFDA: 5240
	BRA.S	.lab_000A		;3FFDC: 6004
.lab_0009:
	MOVE	#$FFFF,(A1)+		;3FFDE: 32FCFFFF
.lab_000A:
	MOVE	D0,(A1)+		;3FFF2: 32C0
.not_ok:
	MOVEM.L	(A7)+,D0-D7/A0-A6	;3FFF4: 4CDF7FFF
	MOVEA.L	-4(A5),A2		;3FFF8: 246DFFFC
	RTS				;3FFFC: 4E75
.lab_000C:
	DC.W	$0000			;3FFFE

assign_jff:
	movem.l	d0-a6,-(a7)
	move.l	doslib(pc),d0
	bne.b	.skip

	; stop sound (start sound glitch workaround)

	move.w	#$0,$dff0a8
	move.w	#$0,$dff0b8
	move.w	#$0,$dff0c8
	move.w	#$0,$dff0d8

	; only done once

	move.l	current_drive_offset(pc),d0
	move.w	#4,(a4,d0.l)		; set default save drive to 'maxnumdrives'

	; open doslib

	lea	(_dosname,pc),a1
	move.l	(4),a6
	jsr	(_LVOOldOpenLibrary,a6)
	lea	doslib(pc),a0
	move.l	d0,a6
	move.l	d0,(a0)

	lea	jff_assign(pc),a0
	sub.l	a1,a1
	bsr	_dos_assign
.skip
	MOVEM.L	(A7)+,D0-A6
	rts

doslib
	dc.l	0

current_drive_offset
	dc.l	0

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

;============================================================================

	END
