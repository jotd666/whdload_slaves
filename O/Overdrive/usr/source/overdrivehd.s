
	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	whdload.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	Overdrive.slave
	ENDC

CHIPONLY
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
		dc.w	13			;ws_Version
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


	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_name		dc.b	"Overdrive",0
_copy		dc.b	"1993 Team 17 & Psionic Systems",0
_info		dc.b	"installed & fixed by JOTD",10
		dc.b	"Version 2.0 "
	IFD BARFLY
		INCBIN	"T:date"
	ENDC
		dc.b	0

		even

_start	
	IFND	CHIPONLY
	lea	_expmem(pc),a1
	move.l	_whd_expmem(pc),(a1)
	ENDC
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

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

	move.l	a0,-(A7)
	move.l	_resload(PC),a0
	jsr	resload_FlushCache(A0)	;preserves all registers
	move.l	(A7)+,a0
	jmp	BOOTBASE+$034

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
	PL_P	$14BD8,read_sectors_12b
	PL_P	$14FEC,read_sectors_11b
	PL_PS	$1174,kbint
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
	lea	record_name(pc),a0
	move.l	_expmem(pc),A1
	add.l	#$EAC2,A1
	move.l	_resload(pc),a2
	move.l	#RECORDSIZE,d0
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
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
	bne.b	.noquit

	pea	TDREASON_OK
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
.noquit
	rts

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

