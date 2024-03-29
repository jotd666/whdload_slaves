	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	IFD BARFLY
	OUTPUT	"SpaceCrusade.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC
_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 11)
	dc.w	WHDLF_NoError|WHDLF_ClearMem
	dc.l	$80000					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$0					; ws_keydebug
_keyexit
	dc.b	$5d					; ws_keyexit
_expmem
	dc.l	$0					; ws_expmem
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;---
_config
;	dc.b	"BW;"
	dc.b    "C3:B:Boot on expansion disk;"
	dc.b    "C4:B:Skip gremlin logo;"
	dc.b	0
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC
	
DECL_VERSION:MACRO
	dc.b	"3.1"
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
_name	dc.b	'Space Crusade',0
_copy	dc.b	'1991 Gremlin',0
_info
    dc.b   'adapted by JOTD',10
	dc.B	"Version "
	DECL_VERSION
	dc.b	0

	even
	
start:
	clr.l	$4.W
	lea		_resload(pc),a1
	move.l	a0,(a1)
	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)
	
	move.l	expansion(pc),d0
	bne.b	.expansion
	
	moveq	#1,D2
	move.l	#$1600,D0		; offset
	move.l	#$4D000,D1		; len
	lea	$8000,A0
	jsr		resload_DiskLoad(a2)

	sub.l	a1,a1
	lea		pl_boot(pc),a0
	jsr		resload_Patch(a2)
	
	IFD	SEARCH_FAULTS
	bsr	Install24BitCheck
	ENDC

	move.w	#$83D0,dmacon+$DFF000
	jmp	$8006

.expansion
	moveq	#3,D2
	move.l	#$2E32,D0
	move.l	#$4700,D1
	lea	$10000,A0
	jsr		resload_DiskLoad(a2)
	
	lea	$10000,A0
	lea	$235C.W,A1
	jsr		resload_Decrunch(a2)

	
	; *** blitter

	bsr	PatchBlitExp

	sub.l	a1,a1
	lea		pl_boot_expansion(pc),a0
	jsr		resload_Patch(a2)


	; *** transfer boot

	lea	$8296,A6
	LEA	$73542,A5
	MOVE	#$00E1,D7
LAB_0000:
	MOVE	(A6)+,(A5)+
	DBF	D7,LAB_0000

	move.w	#$2700,SR
	bsr	_flushcache
	move.w	#$8210,dmacon+$DFF000
	jmp	$73542

PatchBlitExp:
	MOVEM.L	D0-A6,-(a7)

	move.l	#$35400058,D0
	move.l	#$4EB800C6,D1
	lea	$2A00.W,A0
	lea	$2C00.W,A1
	bsr	HexReplaceLong

	move.l	#$35410058,D0
	move.l	#$4EB800CC,D1
	lea	$2A00.W,A0
	lea	$2C00.W,A1
	bsr	HexReplaceLong

	move.l	#$35470058,D0
	move.l	#$4EB800D2,D1
	lea	$6E00.W,A0
	lea	$7C00.W,A1
	bsr	HexReplaceLong

	MOVEM.L	(a7)+,d0-a6
	rts

jump_2366
	CLR.L	$17A.W
	JMP	$2366.W

	
decrunch_exp:

	move.l	_resload(pc),a2
	jsr		resload_Decrunch(a2)

	cmp.w	#$4EB9,$834C
	bne	.patched

	; unpacked from $8270 to $5F252
	lea		pl_main_exp(pc),a0
	sub.l	a1,a1
	jsr		resload_Patch(a2)

.patched
	rts
pl_main_exp
	PL_START
	PL_PS	$834C,SkipCheckDisk
	PL_PS	$8360,SkipPassword

	; *** remove format check

	PL_W	$9BC6,$600E

	; *** replace load dir

	PL_PS	$991E,ReadSaveData
	
	PL_PSS	$0bc4a,soundtracker_loop,2
	PL_PSS	$0bc5e,soundtracker_loop,2
	
	PL_END
	
SkipCheckDisk:
	move.b	#1,$189.W
	rts

SkipPassword:
	move.b	#1,$187.W
	rts


pl_boot_expansion
	PL_START
	PL_P	$2566,ReadSectorsExp

	; *** keyboard quit key

	PL_PS	$69EC,KbInt

	; *** kb fix acknowledge kb

	PL_NOP	$6A06,2

	; *** decrunch relocated, and patch after decrunch

	PL_P	$7FAE,decrunch_exp
	
	; code to be relocated in 73xxx
	PL_P	$833c,jump_2366
	
	; rest
	PL_P	$C6,WaitBlitD0
	PL_P	$CC,WaitBlitD1
	PL_P	$D2,WaitBlitD7
	PL_PS	$6F26,PatchBlitD7A5
	PL_PS	$6F34,PatchBlitD7A5
	PL_PS	$6F42,PatchBlitD7A5
	PL_PS	$6F50,PatchBlitD7A5
	PL_PS	$6F64,PatchBlitD7A5

	PL_PS	$71E8,PatchBlitD7A6
	PL_PS	$71F6,PatchBlitD7A6
	PL_PS	$7204,PatchBlitD7A6
	PL_PS	$7212,PatchBlitD7A6
	PL_PS	$7220,PatchBlitD7A6

	PL_PS	$74AC,PatchBlitD7A6
	PL_PS	$74BA,PatchBlitD7A6
	PL_PS	$74C8,PatchBlitD7A6
	PL_PS	$74D6,PatchBlitD7A6
	PL_PS	$74E4,PatchBlitD7A6
	PL_END
	

pl_boot
	PL_START
	PL_P	$43F2C,_robread
	PL_P	$43EC8,PatchProg1

	PL_PS	$8614,vbl_hook
	PL_PA	$7FFC,PatchProg2
	
	PL_PSS	$092a8,soundtracker_loop,2
	PL_PSS	$092bc,soundtracker_loop,2
	
	PL_IFC4
	PL_NOP	$0852e,2
	PL_ENDIF
	
	PL_END
	
FlushNJump:
	bsr	PatchBlit
	
	JMP	$73668
	
soundtracker_loop
	move.w  d0,-(a7)
	move.w	#4,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
	rts 

vbl_hook
    addq.w #$01,$00008690
	move.b	$BFEC01,d0
	not.b	d0
	ror.b	#1,d0
	cmp.b	_keyexit(pc),d0
	beq	_quit
	rts
	
PatchBlit:
	MOVEM.L	D0-A6,-(a7)

	move.l	#$35400058,D0
	move.l	#$4EB800C6,D1
	lea	$2000.W,A0
	lea	$7FFC.W,A1
	bsr	HexReplaceLong

	move.l	#$35410058,D0
	move.l	#$4EB800CC,D1
	lea	$2000.W,A0
	lea	$7FFC.W,A1
	bsr	HexReplaceLong

	move.l	#$35470058,D0
	move.l	#$4EB800D2,D1
	lea	$2000.W,A0
	lea	$7FFC.W,A1
	bsr	HexReplaceLong

	sub.l	a1,a1
	lea		pl_blit(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)

	MOVEM.L	(a7)+,d0-a6
	rts

pl_blit:
	PL_START

	PL_PS	$7D14,Patch24Bit
	PL_PS	$6A10,KbInt
	PL_PS	$2380,PatchProtect

	PL_P	$80AC,jumper	; never reached...
	
	PL_L	$7366A,$7FF00		; changes stack location

	PL_P	$07b74,flush_and_jump_a6


	PL_P	$C6,WaitBlitD0
	PL_P	$CC,WaitBlitD1
	PL_P	$D2,WaitBlitD7
	PL_PS	$6F4A,PatchBlitD7A5
	PL_PS	$6F58,PatchBlitD7A5
	PL_PS	$6F66,PatchBlitD7A5
	PL_PS	$6F74,PatchBlitD7A5
	PL_PS	$6F88,PatchBlitD7A5

	PL_PS	$720C,PatchBlitD7A6
	PL_PS	$721A,PatchBlitD7A6
	PL_PS	$7228,PatchBlitD7A6
	PL_PS	$7236,PatchBlitD7A6
	PL_PS	$7244,PatchBlitD7A6
	PL_PS	$74D0,PatchBlitD7A6
	PL_PS	$74DE,PatchBlitD7A6
	PL_PS	$74EC,PatchBlitD7A6
	PL_PS	$74FA,PatchBlitD7A6
	PL_PS	$7508,PatchBlitD7A6

	PL_PSS	$6A24,KbAck,2

	
	PL_PSS	$7AE2,CheckA0AA,2	
	PL_END
	
jumper
	jmp	$234A.W
	
flush_and_jump_a6
	ADDA.L	D7,A6			;07b74: ddc7
	JMP	(A6)			;07b76: 4e96

CheckA0AA:
	cmp.w	#$3E30,$A0AA
	bne.b	.sk
	movem.l	d0-d1/a0-a2,-(a7)
	sub.l	a1,a1
	lea		pl_a0aa(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	
.sk
	clr.b	$2B5.W
	move.b	$28E.W,d0
	rts

pl_a0aa
	PL_START
	PL_PS	$A0AA,AvoidAf
	PL_END
	
AvoidAf:
	cmp.l	#0,a0
	beq.b	.sk
	move.w	(0,a0,d2.w),d7
	and.w	d1,d7
.sk
	rts


HexReplaceLong:

;< A0: start
;< A1: end
;< D0: longword to search for
;< D1: longword to replace by

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
	
PatchBlitD7A5:
	move.w	D7,(A5)
	bra	WaitBlit

KbAck:
	move.b	#1,($500,a0)
	move.w	#2,d0
	bsr	beamdelay
	rts

PatchBlitD7A6:
	move.w	D7,(A6)
	bra	WaitBlit

WaitBlitD0:
	move.w	D0,$58(A2)
	bra	WaitBlit

WaitBlitD1:
	bsr	WaitBlit
	move.w	D1,$58(A2)
	rts

WaitBlitD7:
	move.w	D7,$58(A2)
	bra	WaitBlit



PatchProtect:
	; at this point, the program at $8000 something has been loaded
	; with protection & save/load, keeping the middleware below $8000
	; active
	movem.l	d0-d1/a0-a2,-(a7)
	sub.l	a1,a1
	lea		pl_protect(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2

	rts

pl_protect
	PL_START
	PL_W	$17C,1	; protection passed
	PL_W	$80C4,$6004; removes protection
	PL_W	$98FC,$6048; skip format check for saves
	PL_PSS	$9648,WriteSaveData,2
	PL_PSS	$9676,ReadSaveData,2

;	PL_W	$845E,$7002; activates expansion mission disk
	PL_END


ReadSectorsExp:
	cmp.b	#1,D3
	beq	WriteSectors
	cmp.b	#2,D3
	beq	FormatSectors

	moveq	#2,d0		; disk #3
	bsr	_robread
.exit
	moveq	#0,D0
	rts

WriteSectors:
	cmp.b	#$B,D1
	bne	WrongSave
	cmp.b	#$1,D2
	bne	WrongSave

	bsr	WriteSaveData
	moveq	#0,D0
	rts

FormatSectors:
	moveq	#0,d0
	rts

WrongSave
	pea	.ErrTxt(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	_resload(pc),a0
	jmp	resload_Abort(a0)
.ErrTxt
	dc.b	"Corrupt savegame",0
	even
	
WriteSaveData:
	MOVEM.L	D1-A6,-(a7)
	move.l	a0,a1
	lea	savename(pc),A0
	move.l	#$200,D0
	move.l	_resload(pc),a2
	jsr		resload_SaveFile(a2)
	MOVEM.L	(a7)+,d1-a6
	moveq	#0,D0
	rts

ReadSaveData:
	MOVEM.L	D0-A6,-(a7)
	move.l	_resload(pc),a2
	move.l	a0,a3		; save
	lea	savename(pc),A0
	jsr		resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.quit
	
	lea	savename(pc),A0
	move.l	a3,a1
	jsr		resload_LoadFile(a2)

	MOVEM.L	(a7)+,d0-a6
	moveq	#0,D0
	rts

.quit
	MOVEM.L	(a7)+,d0-a6
	moveq	#-1,D0
	rts

Patch24Bit:
	movem.l	($364).W,A1-A3
	move.l	D0,-(a7)
	move.l	A1,D0
	and.l	#$FFFFFF,D0	; remove higher byte
	move.l	D0,A1
	move.l	(a7)+,D0
	rts

KbInt:
	move.l	D0,-(sp)
	ror.b	#1,D0
	not.b	D0

	cmp.b	_keyexit(pc),D0
	beq		_quit
	moveq	#2,D0
	bsr		beamdelay

	move.l	(sp)+,D0
	rts

PatchProg2:
	bsr	_flushcache
	jmp	$43EA2


PatchProg1:
.loop
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	dbf	D7,.loop

	
	movem.l	d0-d1/a0-a2,-(a7)
	sub.l	a1,a1
	lea		pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	jmp	(A2)
	
pl_main
	PL_START
	PL_P	$251A,ReadSectors2
	PL_P	$7FFC,FlushNJump
	; "fix" trashed bottom of display in menu, lame but
	; works by hiding the 2 last lines
	PL_W	$3028,$28C1	
	PL_END
	
ReadSectors2:
	bsr	GetDiskId
	bsr	_robread
	rts

GetDiskId
	cmp.l	#'SPC2',$176.W
	bne	.nod2
	moveq	#1,D0
.nod2
	cmp.l	#'SPCR',$176.W
	bne	.quit
	moveq	#0,D0
.quit
	rts


	IFD	SEARCH_FAULTS

Install24BitCheck:
	GETUSRADDR	Check24Bit
	move.l	D0,$24.W
	PL_R	$D0
	rts

Check24Bit:
	move	#$2700,SR
	movem.l	D0-A6,-(A7)
	move.l	$3E(A7),D0	; return PC
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.ok

	move.l	A1,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A0,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A2,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A3,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A5,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault

	move.l	A6,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	bne	.fault


	move.l	A4,D0
	and.l	#$FF000000,D0	; is PC in 24bit RAM
	beq	.ok

.fault
	move.l	$3E(A7),D0	; incriminated PC
	nop
	nop
	jsr	$D0.W
	nop			; breakpoint here
	nop

.ok
	movem.l	(A7)+,D0-A6
	rte
	ENDC

; Rob Northen track loading routine
; < A0: buffer
; < D0: disk number
; < D1: sector offset (*$200)
; < D2: sector length (*$200)
; < D3: command (ignored)
; > D0: 0 if ok (which is all the time :))

_robread:
	movem.l	d1-d3/a0-a2,-(A7)
	and.b	#$FF,D3
	bne.b	.exit

	move.l	d0,d3		; disk number stored
	
	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.exit		; length=0: out

	move.l	D1,D0
	ext.l	d0
	lsl.l	#7,d0			;diskoffset
	lsl.l	#2,d0

	move.l	D2,D1			;len to read
	ext.l	d1
	lsl.l	#7,d1
	lsl.l	#2,d1

	move.l	D3,D2
	addq.l	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)
.exit
	movem.l	(A7)+,d1-d3/a0-a2
	moveq.l	#0,D0
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

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

WaitBlit:
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts


_resload
	dc.l	0
_tag		dc.l	WHDLTAG_CUSTOM3_GET
expansion	dc.l	0

		dc.l	0	
savename:
	dc.b	"spcrus.sav",0
	even
