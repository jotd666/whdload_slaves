; Cadaver demo slave by JOTD

; Assembled with Barfly

	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	whdload.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	CadaverDemo.slave

	DOSCMD	"WDate  >T:date"
	ENDC
	IFD BARFLY
	DOSCMD	"WDate	>T:date"
	ENDC
	
DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_DontCache
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
		dc.l	$0			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0		;ws_kickname
		dc.l	0		;ws_kicksize
		dc.w	0		;ws_kickcrc
		dc.w	_config-_base	;ws_config   		; V17


_name		dc.b	"Cadaver Bonus Levels",0
_copy		dc.b	"1990 The Bitmap Brothers",0
_info		dc.b	"installed & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_config		DC.B	"C1:X:Infinite energy:0;"
			dc.b    "C2:L:Level:Temple (Zero magazine),The Last Supper (Zero Coverdisk #15),Gatehouse (Amiga Format #13);"
			dc.b    0

		even

_start	
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	;enable cache
	move.l	#WCPUF_Base_NCS|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	;get tags
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	lea	$7FF00,A7

	lea	$B8.W,A3
	move.l	_level(pc),D0
	cmp.l	#0,D0
	beq.b	.v1_addr
	cmp.l	#1,D0
	beq.b	.v2_addr

.v3_addr:
	lea	$3E0.W,A3
	move.l	A3,$80.W
	bra.b	.v1_addr
.v2_addr
	lea	$84.W,A3
.v1_addr
	lea	_fileindex(pc),A0
	add.b	#'1',D0
	move.b	D0,(A0)

	lea	_filename(pc),A0
	move.l	A3,A1
	jsr	(resload_LoadFileDecrunch,a2)

	move.l	_level(pc),D0
	cmp.l	#1,D0
	beq.b	.v2
	cmp.l	#0,D0
	beq.b	.v1
	bra.b	_v3
.v1:
	; *** trainer?

	move.l	_trainer(pc),D0
	beq	.go
	move.l	#$4E714E71,D0
	move.l	D0,$A02C
	move.l	D0,$14172
.go

	move.l	#CACRF_EnableI,D0
	move.l	D0,D1
	jsr	(resload_SetCACR,a2)

	bsr	_flushcache
	jmp	(A3)

.v2:
	; *** trainer?

	move.l	_trainer(pc),D0
	beq	.skip2
	move.l	#$4E714E71,D0
	move.l	D0,$B1BC
	move.l	D0,$151E2
.skip2
	bra.b	.go

_v3:
	move.l	_trainer(pc),D0
	beq	.go
	move.w	#$4E71,$8976
.go

	bsr	_flushcache

	move.w	#$2700,SR

	JSR	$C184			;0007C: 4EB90000C184
	MOVE	#$0FA8,D7		;00082: 3E3C0FA8
	MOVEA.L	#$00012E66,A0		;00086: 207C00012E66
	JSR	$9700			;0008C: 4EB900009700
	MOVE	D6,$4B6			;00092: 33C6000004B6
	LEA	$12E66,A5		;00098: 4BF900012E66
	ADDA.L	#$00001000,A5		;0009E: DBFC00001000
	MOVEA.L	A5,A7			;000A4: 2E4D
	MOVE.L	#$000FE000,D5		;000A6: 2A3C000FE000
	SUB.L	A5,D5			;000AC: 9A8D

	bsr	_patch_it

	JMP	$4CE.W

_patch_it:
	movem.l	D0-A6,-(A7)
	lea	_patchlist_v3(pc),a0
	sub.l	A1,A1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	movem.l	(a7)+,D0-A6
	rts

_patchlist_v3:
	PL_START
	PL_B	$C298,$66	; inverts interrupt 3 VBL check (was wrong)
	PL_L	$C4EA,$4E714E71
	PL_W	$C4EE,$4E71	; removes kb interrupt acknowledge (was too early)
	PL_P	$C506,_ack_kb	; properly acknowledge interrupt
	PL_END

_ack_kb:
	movem.l	(A7)+,D0/A0-A1
	move.w	#8,$DFF09C
_rte:
	rte


; ----------------------------------------------

_flushcache:
	move.l	A2,-(A7)
	move.l	(_resload,pc),a2
	jsr	(resload_FlushCache,a2)
	move.l	(A7)+,A2
	rts

_wrong_version:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; -------------------------------------------------------

_tag		dc.l	WHDLTAG_CUSTOM2_GET
_level	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_trainer	dc.l	0
		dc.l	0

_resload:
	dc.l	0
_version:
	dc.l	0
_filename:
	dc.b	"cadprog"
_fileindex:
	dc.b	"1.RNC",0
