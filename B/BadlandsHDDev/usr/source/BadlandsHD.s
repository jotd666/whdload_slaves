; Resourced by whdslave_resourcer
; a program written by JOTD in 2016
;
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"Badlands.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC


_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	16					; ws_version (was 4)
	dc.w	WHDLF_NoError
	dc.l	$80000					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	0					; ws_keydebug
_keyexit
	dc.b	$59					; ws_keyexit
_expmem
	dc.l	0					; ws_expmem
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
;---

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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

_data   dc.b    0
_name	dc.b	'Badlands',0
_copy	dc.b	'1990 Tengen',0
_info
    dc.b   'by John Selck & JOTD',10,10
	dc.b	"Version "
	DECL_VERSION
	dc.b	0

_kickname   dc.b    0
;--- version id

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0
    even

; IRA V2.00 (Nov  2 2010) (c)1993-95 Tim Ruehsen, (c)2009 Frank Wille

EXT_0000	EQU	$400
EXT_0001	EQU	$1000
EXT_0002	EQU	$1002
EXT_0003	EQU	$11B2
EXT_0004	EQU	$123C
EXT_0005	EQU	$1280
EXT_0006	EQU	$1282
EXT_0007	EQU	$12CC
EXT_0008	EQU	$1340
EXT_0009	EQU	$1DE6
EXT_000a	EQU	$1E06
EXT_000b	EQU	$1E08
EXT_000c	EQU	$2136
EXT_000d	EQU	$1AA56
EXT_000e	EQU	$1AA58
EXT_000f	EQU	$1AA80
EXT_0010	EQU	$1AA82
EXT_0011	EQU	$1AAC8
EXT_0012	EQU	$1AACC
EXT_0013	EQU	$1AAE6
EXT_0014	EQU	$1AAEA
EXT_0015	EQU	$1AB04
EXT_0016	EQU	$1AB08
EXT_0017	EQU	$1AB98
EXT_0018	EQU	$1AB9A
EXT_0019	EQU	$1ABEA
EXT_001a	EQU	$1ABEE
EXT_001b	EQU	$1AC08
EXT_001c	EQU	$1AC0C
EXT_001d	EQU	$1AC26
EXT_001e	EQU	$1AC2A
EXT_001f	EQU	$1AC44
EXT_0020	EQU	$1AC46
EXT_0021	EQU	$284D8
EXT_0022	EQU	$284DA
EXT_0023	EQU	$28E60
EXT_0024	EQU	$29626
EXT_0025	EQU	$29628
EXT_0026	EQU	$2A40C
EXT_0027	EQU	$2A418
EXT_0028	EQU	$2A652
EXT_0029	EQU	$2A6FE
EXT_002a	EQU	$2AB64
EXT_002b	EQU	$2B73C
EXT_002c	EQU	$2B73E
EXT_002d	EQU	$2BEB6
EXT_002e	EQU	$2C26C
EXT_002f	EQU	$2C270
EXT_0030	EQU	$2C474
EXT_0031	EQU	$58000
CIAA_PRA	EQU	$BFE001
HARDBASE	EQU	$DFF000
DMACONR		EQU	$DFF002
INTREQ		EQU	$DFF09C



start:
	LEA	EXT_0000,A7		;052: 4ff900000400
	MOVE.L	A7,USP			;058: 4e67
	LEA	_resload(PC),A1		;05a: 43fa029c
	MOVE.L	A0,(A1)			;05e: 2288
	BSR.W	LAB_0008		;060: 610000b0
	LEA	EXT_0031,A0		;064: 41f900058000
	MOVE.W	#$9fff,D0		;06a: 303c9fff
LAB_0001:
	CLR.L	(A0)+			;06e: 4298
	DBF	D0,LAB_0001		;070: 51c8fffc
	MOVE.L	#$000011b2,D0		;074: 203c000011b2
	MOVE.L	#$0005a550,D1		;07a: 223c0005a550
	MOVE.W	#$03ff,D2		;080: 343c03ff
	BSR.W	LAB_0007		;084: 6100006e
	LEA	LAB_0014(PC),A0		;088: 41fa0272
	MOVEA.L	_resload(PC),A2		;08c: 247a026a
	JSR	resload_GetFileSize(A2)	;90
	CMP.L	#$00000078,D0		;094: b0bc00000078
	BNE.S	LAB_0002		;09a: 6618
	LEA	LAB_0014(PC),A0		;09c: 41fa025e
	LEA	EXT_0023,A1		;0a0: 43f900028e60
	MOVEA.L	_resload(PC),A2		;0a6: 247a0250
	JSR	resload_LoadFile(A2)	;aa
LAB_0002:
	MOVE.W	#$4e71,EXT_0004.W	;0b4: 31fc4e71123c
	CLR.W	EXT_000c.W		;0ba: 42782136
	MOVE.W	#$4eb9,EXT_0005.W	;0be: 31fc4eb91280
	LEA	LAB_000C(PC),A0		;0c4: 41fa00a2
	MOVE.L	A0,EXT_0006.W		;0c8: 21c81282
	
	move.w	#$C029,$12C6.W	; enables VBL interrupt again (does nothing)
	move.w	#$6004,$132E.W	; enables VBL interrupt again (does nothing)
	
	bsr	_flushcache
	LEA	EXT_002d,A7		;0cc: 4ff90002beb6
	JMP	EXT_0003.W		;0d2: 4ef811b2

		IFEQ	1
	; in $1F14: quit (F9)
; $2B5B4 and $2B5D0
pause_test:
    tst.b  $1EE1
    rts
	ENDC

fire_test:
    tst.b   $1EFC
    bne.b   .fire

    btst	#6,$DFF016	;check button blue (normal fire2)
	bne.b  .nofire
    bclr    #1,d7
.nofire
    move.w	#$ffff,$DFF034
    bra.b   .out
.fire
    bclr    #1,d7
.out
    addq.l  #6,(A7) ; skip beq+bclr since already done here
    rts
	
LAB_0003:
	BSR.S	LAB_0007		;0d6: 611c
	CLR.W	D0			;0d8: 4240
	RTS				;0da: 4e75

LAB_0004:
	BSR.S	LAB_0007		;0dc: 6116
	BSET	#1,CIAA_PRA		;0de: 08f9000100bfe001
	RTS				;0e6: 4e75

LAB_0005:
	MOVE.L	EXT_0008.W,D0		;0e8: 20381340
	BRA.S	LAB_0007		;0ec: 6006
LAB_0006:
	BSR.S	LAB_0007		;0ee: 6104
	MOVEQ	#0,D0			;0f0: 7000
	RTS				;0f2: 4e75

LAB_0007:
	MOVEM.L	D1-D7/A0-A6,-(A7)	;0f4: 48e77ffe
	MOVEA.L	D0,A0			;0f8: 2040
	MOVE.W	D2,D0			;0fa: 3002
	MULU	#$0200,D0		;0fc: c0fc0200
	MOVEQ	#1,D2			;100: 7401
	MOVEA.L	_resload(PC),A2		;102: 247a01f4
	JSR	resload_DiskLoad(A2)	;106
	MOVEM.L	(A7)+,D1-D7/A0-A6	;10a: 4cdf7ffe
	MOVEQ	#0,D0			;10e: 7000
	RTS				;110: 4e75

LAB_0008:
	MOVE.W	#$7fff,D0		;112: 303c7fff
	LEA	HARDBASE,A0		;116: 41f900dff000
	MOVE.W	D0,154(A0)		;11c: 3140009a
	MOVE.W	D0,156(A0)		;120: 3140009c
	MOVE.W	D0,150(A0)		;124: 31400096
	MOVE.W	D0,158(A0)		;128: 3140009e
	RTS				;12c: 4e75

kb_int:
	CMP.B	_keyexit(pc),D0			;12e: b03c0078
	BEQ.S	quit	;132: 6726
	bsr	kb_delay
	MOVE.W	#$0008,INTREQ		;144: 33fc000800dff09c
	RTS				;158: 4e75

quit:
	PEA	TDREASON_OK	;15a: 2f3cffffffff
	MOVEA.L	_resload(PC),A0		;160: 207a0196
	JMP	resload_Abort(A0)	;164

LAB_000C:
	MOVE.L	#$0002b466,EXT_0007.W	;168: 21fc0002b46612cc
	MOVE.L	#$3c89612c,EXT_002a	;170: 23fc3c89612c0002ab64
	MOVE.L	#$4e714eb9,D0		;17a: 203c4e714eb9
	MOVE.W	D0,EXT_0021		;180: 33c0000284d8
	LEA	LAB_000D(PC),A1		;186: 43fa0122
	MOVE.L	A1,EXT_0022		;18a: 23c9000284da
	MOVE.W	D0,EXT_000a.W		;190: 31c01e06
	LEA	kb_int(PC),A1		;194: 43faff98
	MOVE.L	A1,EXT_000b.W		;198: 21c91e08
	MOVE.W	D0,EXT_0024		;19c: 33c000029626
	LEA	LAB_0003(PC),A1		;1a2: 43faff32
	MOVE.L	A1,EXT_0025		;1a6: 23c900029628
	MOVE.W	#$4ef9,EXT_002b		;1ac: 33fc4ef90002b73c
	LEA	LAB_0004(PC),A1		;1b4: 43faff26
	MOVE.L	A1,EXT_002c		;1b8: 23c90002b73e
	MOVE.L	D0,EXT_002e		;1be: 23c00002c26c
	LEA	LAB_0005(PC),A1		;1c4: 43faff22
	MOVE.L	A1,EXT_002f		;1c8: 23c90002c270
	MOVE.L	#$4eb81000,EXT_0030	;1ce: 23fc4eb810000002c474
	MOVE.W	#$4ef9,EXT_0001.W	;1d8: 31fc4ef91000
	LEA	LAB_0006(PC),A1		;1de: 43faff0e
	MOVE.L	A1,EXT_0002.W		;1e2: 21c91002
	LEA	LAB_000E(PC),A1		;1e6: 43fa00e6
	MOVE.W	D0,EXT_000d		;1ea: 33c00001aa56
	MOVE.L	A1,EXT_000e		;1f0: 23c90001aa58
	MOVE.W	D0,EXT_0017		;1f6: 33c00001ab98
	MOVE.L	A1,EXT_0018		;1fc: 23c90001ab9a
	LEA	LAB_000F(PC),A1		;202: 43fa00d2
	MOVE.W	D0,EXT_000f		;206: 33c00001aa80
	MOVE.L	A1,EXT_0010		;20c: 23c90001aa82
	LEA	LAB_0010(PC),A1		;212: 43fa00ca
	MOVE.L	D0,EXT_0011		;216: 23c00001aac8
	MOVE.L	A1,EXT_0012		;21c: 23c90001aacc
	MOVE.L	D0,EXT_0013		;222: 23c00001aae6
	MOVE.L	A1,EXT_0014		;228: 23c90001aaea
	MOVE.L	D0,EXT_0015		;22e: 23c00001ab04
	MOVE.L	A1,EXT_0016		;234: 23c90001ab08
	MOVE.L	D0,EXT_0019		;23a: 23c00001abea
	MOVE.L	A1,EXT_001a		;240: 23c90001abee
	MOVE.L	D0,EXT_001b		;246: 23c00001ac08
	MOVE.L	A1,EXT_001c		;24c: 23c90001ac0c
	MOVE.L	D0,EXT_001d		;252: 23c00001ac26
	MOVE.L	A1,EXT_001e		;258: 23c90001ac2a
	LEA	LAB_0011(PC),A1		;25e: 43fa0088
	MOVE.W	#$4ef9,EXT_001f		;262: 33fc4ef90001ac44
	MOVE.L	A1,EXT_0020		;26a: 23c90001ac46
	LEA	EXT_0009.W,A1		;270: 43f81de6
	MOVE.L	#$20780204,(A1)+	;274: 22fc20780204
	MOVE.L	#$4e714e71,(A1)+	;27a: 22fc4e714e71
	MOVE.L	#$4e714e90,(A1)		;280: 22bc4e714e90
	MOVE.W	#$4e75,D0		;286: 303c4e75
	MOVE.W	D0,EXT_0026		;28a: 33c00002a40c
	MOVE.W	D0,EXT_0027		;290: 33c00002a418
	MOVE.W	D0,EXT_0028		;296: 33c00002a652
	MOVE.W	D0,EXT_0029		;29c: 33c00002a6fe
    
	move.w  #$4EB9,$1F686
    pea fire_test(pc)
    move.l  (a7)+,$1F688

	LEA	CIAA_PRA,A1		;2a2: 43f900bfe001
	bsr	_flushcache
	RTS				;2a8: 4e75

LAB_000D:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;2aa: 48e7fffe
	LEA	LAB_0014(PC),A0		;2ae: 41fa004c
	LEA	EXT_0023,A1		;2b2: 43f900028e60
	MOVEQ	#120,D0			;2b8: 7078
	MOVEA.L	_resload(PC),A2		;2ba: 247a003c
	JSR	resload_SaveFile(A2)	;2be
	MOVEM.L	(A7)+,D0-D7/A0-A6	;2c2: 4cdf7fff
	BTST	#3,45(A0)		;2c6: 08280003002d
	RTS				;2cc: 4e75

LAB_000E:
	MOVE.W	D7,88(A6)		;2ce: 3d470058
	ADDQ.W	#4,A1			;2d2: 5849
	BRA.S	LAB_0012		;2d4: 6016
LAB_000F:
	MOVE.W	D7,88(A6)		;2d6: 3d470058
	ADDQ.W	#1,D7			;2da: 5247
	BRA.S	LAB_0012		;2dc: 600e
LAB_0010:
	MOVE.W	D7,88(A6)		;2de: 3d470058
	ADDA.W	#$1f40,A0		;2e2: d0fc1f40
	BRA.S	LAB_0012		;2e6: 6004
LAB_0011:
	MOVE.W	D7,88(A6)		;2e8: 3d470058
LAB_0012:
	BTST	#6,DMACONR		;2ec: 0839000600dff002
	BNE.S	LAB_0012		;2f4: 66f6
	RTS				;2f6: 4e75

_resload:
	dc.l	0			;2f8: 00000000
LAB_0014:
	dc.b	"Badlands.hi",0
	even

kb_delay:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
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


_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
