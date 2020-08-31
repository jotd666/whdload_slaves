
	incdir	include:
	include	whdload.i
	include	whdmacros.i

pullall:MACRO
	movem.l	(a7)+,d0-a6
	ENDM
pushall:MACRO
	movem.l	d0-a6,-(a7)
	ENDM


	IFD BARFLY
	OUTPUT	"Shinobi.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

one_id	=$ca5b					; arcade smash hits
two_id	=$b6c8					; super sega

basemem	=$80000

rts_opcode = $4E75
nopnop_opcode = $4E714E71
slv_keyexit	= $5D	; num '*'

;--- power to the people

_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	14					; ws_version
	dc.w	WHDLF_EmulTrap|WHDLF_NoError	; ws_flags
	dc.l	basemem					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	slave-_base				; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
	dc.b	0					; ws_keydebug
_keyexit:
	dc.b	slv_keyexit				; ws_keyexit [numl]
	dc.l	0					; ws_expmem
	dc.w	_name-_base		;ws_name
	dc.w	_copy-_base		;ws_copy
	dc.w	_info-_base		;ws_info

;--- version id


	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

_name		dc.b	"Shinobi"
		dc.b	0
_copy		dc.b	"1989 Sega",0
_info		dc.b	"adapted & fixed by Dark Angel & JOTD",10,10
		dc.b	"CUSTOM1=1 enables levelskipper (F1)",10
		dc.b	"CUSTOM2=1 enables unlimited Ninja Magic",10
		dc.b	"CUSTOM3=1 enables 2nd button to trigger Magic",10,10

		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0


;--- shinobi

slave	lea	_resload(pc),a1
	move.l	a0,(a1)

	lea	tags(pc),a0
	move.l	_resload(pc),a6
	jsr	resload_Control(a6)


;--- version one?

notrn	moveq	#40,d6
	move.l	#$b57,d7
	lea	$30000,a0
	bsr.w	loader

	move.l	#$b57*4,d0
	lea	$30000,a0
	move.l	_resload(pc),a6
	jsr	resload_CRC16(a6)

	cmp	#one_id,d0
	beq.b	.known


;--- version two?

	moveq	#40,d6
	move.l	#$b62,d7
	lea	$30000,a0
	bsr.w	loader

	move.l	#$b62*4,d0
	lea	$30000,a0
	move.l	_resload(pc),a6
	jsr	resload_CRC16(a6)

	cmp	#two_id,d0
	beq.b	.known


;--- unsupported version

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts


;--- patch game

.known	lea	version(pc),a0
	move	d0,(a0)

	cmp	#two_id,d0
	beq.w	.v2


;--- decode main file

.v1	LEA	$00030004,A6
	LEA	$00003FE0,A3
	MOVE.W	#$02DA,D7
	MOVE.W	#$0085,D4
	EOR.W	D4,D7
	MOVE.L	A6,A5
	ADDA.W	D7,A5
	MOVE.L	A5,A4
	ADDA.W	D7,A4
	LEA	$0200(A6),A5
	LEA	$0200(A5),A4
	MOVEQ	#$00,D7
	MOVE.W	$01FE(A6),D4
.l_C96E	MOVEQ	#$00,D1
	MOVE.W	D4,D5
.l_C972	DBF	D7,.l_C97A
	MOVEQ	#$1F,D7
	MOVE.L	(A4)+,D6
.l_C97A	LSR.L	#1,D6
	BCC.B	.l_C986
	MOVE.W	(A5,D5.W),D5
	BPL.B	.l_C972
	BRA.B	.l_C98C
.l_C986	MOVE.W	(A6,D5.W),D5
	BPL.B	.l_C972
.l_C98C	MOVE.B	D5,D0
	BEQ.W	patch_2354
	MOVE.B	D0,D1
	BPL.B	.l_C9C0
	BCLR	#$07,D1
	SUBQ.B	#1,D1
	MOVE.W	D4,D5
.l_C99C	DBF	D7,.l_C9A4
	MOVEQ	#$1F,D7
	MOVE.L	(A4)+,D6
.l_C9A4	LSR.L	#1,D6
	BCC.B	.l_C9B0
	MOVE.W	(A5,D5.W),D5
	BPL.B	.l_C99C
	BRA.B	.l_C9B6
.l_C9B0	MOVE.W	(A6,D5.W),D5
	BPL.B	.l_C99C
.l_C9B6	MOVE.B	D5,D0
.l_C9B8	MOVE.B	D0,(A3)+
	DBF	D1,.l_C9B8
	BRA.B	.l_C96E
.l_C9C0	SUBQ.B	#1,D1
.l_C9C2	MOVE.W	D4,D5
.l_C9C4	DBF	D7,.l_C9CC
	MOVEQ	#$1F,D7
	MOVE.L	(A4)+,D6
.l_C9CC	LSR.L	#1,D6
	BCC.B	.l_C9D8
	MOVE.W	(A5,D5.W),D5
	BPL.B	.l_C9C4
	BRA.B	.l_C9DE
.l_C9D8	MOVE.W	(A6,D5.W),D5
	BPL.B	.l_C9C4
.l_C9DE	MOVE.B	D5,D0
	MOVE.B	D0,(A3)+
	DBF	D1,.l_C9C2
	BRA.B	.l_C96E
;---

.v2	lea	$30000,a0
	move	#0,d0
	moveq	#70,d6
	move	#$2d83,d7
.eor	eor.b	d6,(a0)
	move.b	(a0)+,d1
	eor.b	d1,d0
	addq.b	#1,d6
	dbf	d7,.eor

	LEA	$00030004,A6
	LEA	$00003FE0,A3
	MOVE.W	#$02DA,D7
	MOVE.W	#$00DA,D4
	EOR.W	D4,D7
	MOVE.L	A6,A5
	ADDA.W	D7,A5
	MOVE.L	A5,A4
	ADDA.W	D7,A4
.l_8E28	MOVEQ	#$00,D7
	MOVE.W	$01FE(A6),D4
.l_8E2E	MOVEQ	#$00,D1
	MOVE.W	D4,D5
.l_8E32	DBF	D7,.l_8E3A
	MOVEQ	#$1F,D7
	MOVE.L	(A4)+,D6
.l_8E3A	LSR.L	#1,D6
	BCC.B	.l_8E46
	MOVE.W	$00(A5,D5.W),D5
	BPL.B	.l_8E32
	BRA.B	.l_8E4C
.l_8E46	MOVE.W	$00(A6,D5.W),D5
	BPL.B	.l_8E32
.l_8E4C	MOVE.B	D5,D0
	BEQ.B	patch2
	MOVE.B	D0,D1
	BPL.B	.l_8E80
	BCLR	#$07,D1
	SUBQ.B	#1,D1
	MOVE.W	D4,D5
.l_8E5C	DBF	D7,.l_8E64
	MOVEQ	#$1F,D7
	MOVE.L	(A4)+,D6
.l_8E64	LSR.L	#1,D6
	BCC.B	.l_8E70
	MOVE.W	$00(A5,D5.W),D5
	BPL.B	.l_8E5C
	BRA.B	.l_8E76
.l_8E70	MOVE.W	$00(A6,D5.W),D5
	BPL.B	.l_8E5C
.l_8E76	MOVE.B	D5,D0
.l_8E78	MOVE.B	D0,(A3)+
	DBF	D1,.l_8E78
	BRA.B	.l_8E2E
.l_8E80	SUBQ.B	#1,D1
.l_8E82	MOVE.W	D4,D5
.l_8E84	DBF	D7,.l_8E8C
	MOVEQ	#$1F,D7
	MOVE.L	(A4)+,D6
.l_8E8C	LSR.L	#1,D6
	BCC.B	.l_8E98
	MOVE.W	$00(A5,D5.W),D5
	BPL.B	.l_8E84
	BRA.B	.l_8E9E
.l_8E98	MOVE.W	$00(A6,D5.W),D5
	BPL.B	.l_8E84
.l_8E9E	MOVE.B	D5,D0
	MOVE.B	D0,(A3)+
	DBF	D1,.l_8E82
	BRA.B	.l_8E2E


;--- patch exe files

; NTSC version AKA "v1"

patch_2354
	lea	$4004.w,a0

	cmp.l	$6378.w,a0
	beq.b	intro1
	cmp.l	$53ce.w,a0
	beq.w	lvlx1
	cmp.l	$58ee.w,a0
	beq.w	bonus1
	cmp.l	$9846,a0
	beq.w	boss21
	bra.b	debug
;---

patch2
	lea	$4004.w,a0

	cmp.l	$63a6.w,a0
	beq.b	intro2
	cmp.l	$53f4.w,a0
	beq.w	lvlx2
	cmp.l	$591a.w,a0
	beq.w	bonus2
	cmp.l	$9840,a0
	beq.w	boss22
;---

debug	
	pea	TDREASON_DEBUG
	move.l	_resload(pc),-(sp)
	add.l	#resload_Abort,(sp)
	rts


;--- patch intro

intro1	patchs	$77b2.w,afi

	move	#rts_opcode,$40f2.w			; no drive ready
	patch	$459c.w,loader

	patch	$7126.w,save

	patch	$6376.w,patch_2354

	bsr	_flushcache

	jmp	(a0)
;---

intro2	patchs	$77e0.w,afi

	patch	$4d2c.w,chk12

	move	#rts_opcode,$40f2.w			; no drive ready
	patch	$459c.w,loader

	patch	$7154.w,save

	patch	$63a4.w,patch2

	bsr	_flushcache

	jmp	(a0)


;--- patch level

lvlx1	lea	custom2(pc),a1
	tst.l	(a1)
	beq.b	noum11
	move	#$50f9,$11a62			; unlimited ninja magic

noum11	
	pushall
	move.l	_resload(pc),a2
	sub.l	a1,a1

	lea	pl_lx1(pc),a0

	move.l	custom3(pc),d0
	beq.b	.sk

	lea	pl_lx1_banzai(pc),a0
.sk
	jsr	resload_Patch(a2)
	pullall
	jmp	(a0)

banzai_1
	move.b	#0,$5B3F
	move.w	$DFF016,d0
	btst	#14,d0
	bne.b	.nosp
	move.b	#1,$5B3F
	move.w	#$CC01,$DFF034
.nosp
	move.l	$CFE4,D0	; original		
	rts

banzai_2
	move.b	#0,$5B45
	move.w	$DFF016,d0
	btst	#14,d0
	bne.b	.nosp
	move.b	#1,$5B45
	move.w	#$CC01,$DFF034
.nosp
	move.l	$CFCA,D0	; original		
	rts

pl_lx1
	PL_START
	; avoid address error

	PL_L	$F9CE,$4E714E71
	PL_L	$F9CE+4,$4E714E71

	
	PL_PS	$4960,afg

	PL_P	$14f70,done1

	PL_P	$15080,chk21

	PL_PS	$5988,key11

	PL_R	$40ca			; no drive ready
	PL_P	$4574,loader

	PL_P	$53cc,patch_2354

	PL_W	$13294,$4E71		; stupid infinite loop after losing a life

	PL_P	$100,emulate_dbf

	PL_L	$10382,$4EB80100
	PL_L	$109D0,$4EB80100
	PL_L	$10B32,$4EB80100
	PL_L	$1349E,$4EB80100
	PL_L	$134AC,$4EB80100

	PL_PS	$40FA,emulate_dbf_nop
	PL_PS	$54A0,emulate_dbf_nop
	PL_PS	$10C84,emulate_dbf_nop

	PL_END
pl_lx1_banzai
	PL_START

	; joystick 2 button throws banzai

	PL_PS	$54F2,banzai_1
	PL_END

;---

lvlx2
	lea	custom2(pc),a1
	tst.l	(a1)
	beq.b	noum12
	move	#$50f9,$11990			; unlimited ninja magic

noum12
	pushall
	move.l	_resload(pc),a2
	sub.l	a1,a1
	lea	pl_lx2(pc),a0
	move.l	custom3(pc),d0
	beq.b	.sk

	lea	pl_lx2_banzai(pc),a0
.sk
	jsr	resload_Patch(a2)
	pullall
	jmp	(a0)

pl_lx2
	PL_START
	; avoid address error
	PL_L	$F9B4,nopnop_opcode
	PL_L	$F9B4+4,nopnop_opcode

	PL_PS	$4960,afg

	PL_P	$14e86,done2

	PL_P	$14f96,chk22

	PL_PS	$598e,key12

	PL_R	$40ca			; no drive ready
	PL_P	$4574,loader

	PL_P	$53f2,patch2


	PL_P	$100,emulate_dbf

	PL_L	$10330,$4EB80100
	PL_L	$10988,$4EB80100
	PL_L	$10AEA,$4EB80100
	PL_L	$133C6,$4EB80100
	PL_L	$133D4,$4EB80100
	PL_END

pl_lx2_banzai
	PL_START
	; joystick 2 button throws banzai

	PL_PS	$5510,banzai_2
	PL_NEXT	pl_lx2


emulate_dbf_nop
	add.l	d0,d0

; < D0: value of D0 in line
; .x: DBF D0,x
emulate_dbf
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#$28,D0
	swap	D0
	clr.w	D0
	swap	D0
	bsr	beamdelay
	move.w	#$FFFF,d0
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

;--- patch bonus stage

bonus1	patchs	$6e32.w,key21

	move	#rts_opcode,$5d76.w			; no drive ready
	patch	$6228.w,loader

	patch	$58ec.w,patch_2354

	bsr	_flushcache

	jmp	(a0)
;---

bonus2	patchs	$6e5e.w,key22

	move	#rts_opcode,$5da2.w			; no drive ready
	patch	$6254.w,loader

	patch	$33484,chk32

	patch	$5918.w,patch2

	bsr	_flushcache

	jmp	(a0)


;--- patch 2nd stage boss

boss21	lea	custom2(pc),a1
	tst.l	(a1)
	beq.b	noum21
	move	#$50f9,$a40c			; unlimited ninja magic

noum21	lea	$9b3a,a1			; remove access fault
	move.l	#nopnop_opcode,d0
	move.l	d0,(a1)+
	move	d0,(a1)

	patch	$936a,chk41

	patchs	$4444.w,key31

	move	#rts_opcode,$5050.w			; no drive ready
	patch	$54fa.w,loader

	patch	$9844,patch_2354

	bsr	_flushcache
	jmp	(a0)
;---

boss22	lea	custom2(pc),a1
	tst.l	(a1)
	beq.b	noum22
	move	#$50f9,$a3f2			; unlimited ninja magic

noum22	lea	$9b34,a1			; remove access fault
	move.l	#nopnop_opcode,d0
	move.l	d0,(a1)+
	move	d0,(a1)

	patch	$936a,chk42

	patchs	$4444.w,key32

	move	#rts_opcode,$5050.w			; no drive ready
	patch	$54fa.w,loader

	patch	$983e,patch2

	bsr	_flushcache

	jmp	(a0)


;--- avoid access fault intro

afi	move.l	d0,-(sp)
	move.l	a1,d0
	and.l	#$7ffff,d0
	move.l	d0,a1
	move.l	(sp)+,d0

	move.b	(a0)+,d0
	move.b	d0,d1
	not.b	d1
	rts


;--- avoid access fault game

afg	move.l	d0,-(sp)
	move.l	a1,d0
	and.l	#$7ffff,d0
	move.l	d0,a1
	move.l	(sp)+,d0

	not.l	d7
	and.l	d7,-1(a1)
	rts


;--- play all samples after level done

done1	patch	$6d456,sample

	move.l	#$5b47,$3ff8.w

	bsr	_flushcache

	jmp	(a0)
;---

done2	patch	$6335a,sample

	move.l	#$5b4d,$3ff8.w

	bsr	_flushcache

	jmp	(a0)
;---

sample	moveq	#5,d1
.hshake	move.b	$dff006,d0
.same	cmp.b	$dff006,d0
	beq.b	.same
	dbf	d1,.hshake
	rts


;--- skip copy protection

chk21	jmp	$1509e
;---

chk41	jmp	$93aa
;---

chk12	jmp	$4d40.w
;---

chk22	jmp	$14fae
;---

chk32	jmp	$334be
;---

chk42	jmp	$93a4


;--- trainer key

key11	
	bsr.w	lvljmp
	bne.b	nof1

	cmp.b	#$5f,d0				; F1
	bne.b	nof1
	lea	$15ed2,a0
	cmp	#-2,(a0)
	bne.b	noboss
	move	#-1,$1333c
noboss	move	#-2,(a0)
	rts
;---

key21	bsr.b	lvljmp
	bne.b	nof1

	cmp.b	#$5f,d0				; f1
	bne.b	nof1
	move	#$1e,$33444
	rts
;---

key31	bsr.b	lvljmp
	bne.b	nof1

	cmp.b	#$5f,d0				; f1
	bne.b	nof1
	move	#-1,$ab14
nof1	rts
;---

key12	bsr.b	lvljmp
	bne.b	nof1

	cmp.b	#$5f,d0				; f1
	bne.b	nof1
	lea	$15de8,a0
	cmp	#-2,(a0)
	bne.b	noboss
	move	#-1,$1326a
	move	#-2,(a0)
	rts
;---

key22	bsr.b	lvljmp
	bne.b	nof1

	cmp.b	#$5f,d0				; f1
	bne.b	nof1
	move	#$1e,$33470
	rts
;---

key32	bsr.b	lvljmp
	bne.b	nof1

	cmp.b	#$5f,d0				; f1
	bne.b	nof1
	move	#-1,$aafa
	rts


;--- level jump enabled?

lvljmp	move.b	$bfec01,d0			; original command
	movem.l	d0,-(a7)
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
; quitkey on 68000
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	movem.l	(a7)+,d0

	lea	custom1(pc),a0
	tst.l	(a0)
	beq.b	nolvj

	cmp	#$0504,$184.w			; no jump on last stage
	beq.b	nolvj
	moveq	#0,d7
	rts

nolvj	moveq	#-1,d7
	rts


;--- universal loader

loader	pushall

	move.l	d6,d0
	mulu	#$1600,d0
	move.l	d7,d1
	lsl.l	#2,d1
	moveq	#1,d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

	move	#%1000001000000000,$dff096	; game relies on main dma on

	clr.l	$dff108

	pullall
	rts


;--- save highscores

save	pushall

	lea	custom1(pc),a0			; uncheated only...
	tst.l	(a0)
	bne.b	.nosave
	lea	custom2(pc),a0
	tst.l	(a0)
	bne.b	.nosave

	move.l	#260,d0
	move.l	#159*$1600,d1
	lea	disk1(pc),a0
	lea	$7f000,a1
	move.l	_resload(pc),a6
	jsr	resload_SaveFileOffset(a6)

	lea	$dff000,a6			; to avoid sprite stripes
	clr.l	$144(a6)
	clr.l	$14c(a6)
	clr.l	$154(a6)
	clr.l	$15c(a6)
	clr.l	$164(a6)
	clr.l	$16c(a6)
	clr.l	$174(a6)
	clr.l	$17c(a6)
.nosave

	pullall
	rts

_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

;--------------------------------
_resload	dc.l	0	;	=

version	dc.w	0	;	=
;--------------------------------


;--- tag list

tags	dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
	dc.l	WHDLTAG_CUSTOM2_GET
custom2	dc.l	0
	dc.l	WHDLTAG_CUSTOM3_GET
custom3	dc.l	0
	dc.l	0


;--- file names

disk1	dc.b	'Disk.1',0

rip
