
	INCDIR	Includes:
	INCLUDE	exec/execbase.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	hd2:util/dev/whdload/overdrive/Overdrive.slave
	ENDC

;CHIPONLY
	IFD	CHIPONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = $0
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
	ENDC
RECORDSIZE = $18CA
BOOTBASE = $78000

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_whd_expmem	dc.l	FASTMEMSIZE		;ws_ExpMem

			dc.w	_name-_base		;ws_name
			dc.w	_copy-_base		;ws_copy
			dc.w	_info-_base		;ws_info
			dc.w	0			;ws_kickname
			dc.l	0			;ws_kicksize
			dc.w	0			;ws_crc
			dc.w	_config-_base		;ws_config


	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_name		dc.b	"Overdrive",0
_copy		dc.b	"1993 Team 17 & Psionic Systems",0
_info		dc.b	"installed & fixed by JOTD",10,10
			dc.b	"Trainer added by Arise from Decay",10,10		 

		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_config
	dc.b	"C1:X:Unlimited Fuel:0;"
	dc.b	"C1:X:Unlimited Time:1;"
	dc.b	"C1:X:Unlimited Money:2;"
	dc.b	"C1:X:Unlimited Turbo-time:3;"
	dc.b	"C1:X:Always win:4;"
	dc.b	"C1:X:Ingame keys:5;"
	dc.b	"C4:B:Skip Team17 & Psionic logos"
	dc.b	0

_CheatFlag	dc.b 0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
		even
_start	
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload
	IFND	CHIPONLY
	lea	_expmem(pc),a1
	move.l	_whd_expmem(pc),a0

	add.w	#$10,a0
	move.l	a0,(a1)
	ENDC

	lea	CHIPMEMSIZE-$100,A7

	moveq.l	#0,D3
	moveq.l	#0,D0		; disk 1
	move.l	#1,d2
	move.l	#0,d1
	lea	BOOTBASE,A0
	bsr	read_rob_sectors

	; just check that old images are not used

	move.l	(a0),d0
	cmp.l	#$444F5300,d0
	beq.b	.ok
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.ok

	moveq.l	#0,D3
	moveq.l	#0,D0		; disk 1
	move.l	#11,d2
	move.l	#11,d1
	lea	BOOTBASE,A0
	bsr	read_rob_sectors

	movem.l	A5/A6,-(sp)
	lea	read_sectors_12b(pc),A5
	lea	BOOTBASE+$A50,A6
	move.w	#$4EF9,(A6)+
	move.l	A5,(A6)
	movem.l	(sp)+,A5/A6
	movem.l	A5/A6,-(sp)
	lea	read_sectors_11b(pc),A5
	lea	BOOTBASE+$2DA,A6
	move.w	#$4EF9,(A6)+
	move.l	A5,(A6)
	movem.l	(sp)+,A5/A6
	movem.l	A5/A6,-(sp)
	lea	patch_loader_1(pc),A5
	lea	BOOTBASE+$0C8,A6
	move.w	#$4EF9,(A6)+
	move.l	A5,(A6)
	movem.l	(sp)+,A5/A6

	move.l	_expmem(pc),$FFC.W	; like in Assassin

;Check if any trainer is on (custom1)
		clr.l	-(a7)
		clr.l	-(a7)
		pea	WHDLTAG_CUSTOM1_GET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		tst.l	(4,a7)
		beq	.cont
		lea	_CheatFlag(pc),a0			;Set flag to say user is a cheater
		move.b	#-1,(a0)

.cont	 
	bsr		flushcaches
	jmp	BOOTBASE+$034

flushcaches:
	move.l  a0,-(A7)
	move.l	_resload(PC),a0
	jsr	resload_FlushCache(A0)	;preserves all registers
	move.l	(A7)+,a0
	rts
	
; standard DOS read

read_sectors_11b:
	cmp.w	#2,D1
	bne	.nodir
	cmp.w	#2,D2
	bne	.nodir

	movem.l	d0-a6,-(a7)

	bsr	read_rob_sectors
	
	movem.l	(a7)+,d0-a6
	moveq.l	#0,D0
	rts

.nodir
	tst.l	D0
	bne	.exit

	MOVEM.L	D1-D7/A0-A5,-(A7)
	LINK	A6,#$FFFFFFDC
	move.l	_expmem(pc),-(A7)
	add.l	#$14FF4,(A7)
	rts			; jumps to rob northern loading routine

.exit
	moveq.l	#0,D0
	rts

pl_1
	PL_START
	PL_IFC4
	PL_S	$e,$7e					;skip logos
	PL_ENDIF
	PL_P	$0154,patch_loader_2
	PL_P	$1BFA,read_sectors_12b
	PL_P	$1484,read_sectors_11b
	PL_P	$200E,decrunch
	PL_END

patch_loader_1
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	lea	$10000,a1
	lea	pl_1(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	$10000

decrunch:
	movem.l	D0-D1/A0-A2,-(A7)
	MOVE.L	_resload(PC),A2
	JSR	(resload_Decrunch,a2)
	movem.l	(A7)+,D0-D1/A0-A2
	rts

patch_loader_2
	move.l	_expmem(pc),A0
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	move.l	a0,a1
	lea	pl_2(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	jmp	(A0)

pl_2
	PL_START
	PL_IFC1X 0
	PL_B	$5f2a,$4a				;Unlimited fuel
	PL_ENDIF
	PL_IFC1X 1
	PL_NOPS	$ad04,1        			;Unlimited time
	PL_ENDIF
	PL_IFC1X 2
	PL_NOPS $c976,4					;Unlimited money
	PL_ENDIF
	PL_IFC1X 3
	PL_B	$7fba,$4a				;Unlimited Turbo Time
	PL_B	$a4fe,$4a
	PL_B	$a61a,$4a
	PL_B	$a66c,$4a
	PL_B	$a850,$4a
	PL_ENDIF
	PL_IFC1X 4
	PL_NOPS $625e,2					;Always win
	PL_NOPS $6264,2
	PL_ENDIF
	PL_IFC1X 5
	PL_PS	$1174,kbinttrainer
	PL_ELSE
	PL_PS	$1174,kbint
	PL_ENDIF
	PL_P	$14BD8,read_sectors_12b
	PL_P	$14FEC,read_sectors_11b
	PL_W	$14A8A,$6024	; remove a flash during 'accessing disk message'
	PL_P	$13854,load_records
	PL_P	$13956,save_records
	PL_END

load_records:
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	lea	record_name(pc),a0
	jsr	resload_GetFileSize(a2)
	tst.l	D0
	beq.b	.skip

	lea	record_name(pc),a0
	move.l	_expmem(pc),A1
	add.l	#$EAC2,A1
	jsr	resload_LoadFileDecrunch(a2)
.skip
	movem.l	(a7)+,d0-a6
	rts

save_records:
	movem.l	d0-a6,-(a7)
	move.b	_CheatFlag(pc),d0
	bne	nosave
	lea	record_name(pc),a0
	move.l	_expmem(pc),A1
	add.l	#$EAC2,A1
	move.l	_resload(pc),a2
	move.l	#RECORDSIZE,d0
	jsr	resload_SaveFile(a2)
nosave	  movem.l (a7)+,d0-a6
	rts


read_sectors_12b:
	movem.l	d0-a6,-(a7)

	moveq.l	#0,D3
	sub.l	#$2,D1
	bsr	read_rob_sectors
	movem.l	(a7)+,d0-a6
	moveq.l	#0,D0
	rts

kbint:
	clr.b	$BFEE01
	cmp.b	_keyexit(pc),D0
	bne		.exit

	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)  

.exit rts

kbinttrainer:
	clr.b	$BFEE01
	
	cmp.b	_keyexit(pc),D0
	bne.b	.noquit

	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)

.noquit
	movem.l	a1-a2,-(a7)
	move.l	_expmem(pc),a1
	cmp.b	#$23,d0					;check f key = fuel
	bne		.noF
	eor.b	#$db,$5f2a(a1)			;subq <-> tst
	bra	.flush

.noF	
	cmp.b	#$14,d0        			;check t key = time
	bne		.noT
	move.l	_expmem(pc),a1
	add.l	#$a000,a1
	eori.w	#$8d7b,$d04(a1)         ;abcd <-> nop
	bra	.flush

.noT
	cmp.b	#$32,d0  				;check x key = turbo time
	bne		.noX
	move.l	_expmem(pc),a1
	eori.b	#8,$7fba(a1)
	add.l	#$a000,a1
	eor.b	#$19,$4fe(a1)
	eori.b	#8,$61a(a1)
	eori.b	#8,$66c(a1)
	eori.b	#8,$850(a1)
	bra	.flush

.noX
	cmp.b	#$11,d0					;check w key = always win
	bne 	.noW
	move.l	_expmem(pc),a1
	eori.l	#$20714e7d,$625e(a1)    ;-> 2x nop
	eori.l	#$20714e5b,$6264(a1)    ;-> 2x nop
	bra	.flush

.noW
	cmp.b	#$5f,d0					;check help key = skip,win race
	bne		.noHELP
	move.l	_expmem(pc),a1
	move.w	#0,$7d4(a1)
	add.l	#$6e000,a1
	move.w	#9,$32a(a1)
	bra.b	.flush

.noHELP
	cmp.b	#$37,d0					;check m key = money
	bne		.noM
	move.l	_expmem(pc),a1
	add.l	#$c000,a1
	eori.w	#$cf78,$976(a1)         ;sbcd <-> nop x4
	eori.w	#$cf78,$978(a1)
	eori.w	#$cf78,$97a(a1)
	eori.w	#$cf78,$97c(a1)
	bra.b	.flush

.noM
	cmp.b	#$1,d0 					;check 1 key = tyre
	bne		.no1
	move.l	_expmem(pc),a1
	add.l	#$10000,a1
	move.w	#7,$976(a1)
	bra.b	.flush

.no1
	cmp.b	#$2,d0					;check 2 key = steering
	bne		.nokey
	move.l	_expmem(pc),a1
	add.l	#$10000,a1
	move.w	#7,$97c(a1)
	bra.b	.flush
.nokey:
	movem.l (a7)+,a1-a2
	rts

.flush
	bsr	flushcaches
	bra.b	.nokey
	
read_rob_sectors:
	movem.l	d1-d2/a0-a2,-(A7)

	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.readnothing		; length=0: out

	exg.l	d0,d2
	addq.l	#1,d2	; disk number

	exg.l	d0,d1

	ext.l	d0
	lsl.l	#7,d0
	lsl.l	#2,d0
	ext.l	d1
	lsl.l	#7,d1			;diskoffset
	lsl.l	#2,d1
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)
.readnothing
	movem.l	(a7)+,d1-d2/a0-a2
_read_nothing:
	moveq	#0,d0
	rts

record_name:
	dc.b	"overdrive.rec",0
	even

_resload:
	dc.l	0
_expmem
	dc.l	$80000

