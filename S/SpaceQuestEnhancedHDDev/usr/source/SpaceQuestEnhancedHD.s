;*---------------------------------------------------------------------------
;  :Program.	SpaceQuestEnhancedHD.asm
;  :Contents.	Slave for "SpaceQuestEnhanced"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: SpaceQuest5HD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	INCLUDE	lvo/intuition.i

	IFD BARFLY
	OUTPUT	"SpaceQuestEnhanced.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================
    IFD HALFMEG
CHIPMEMSIZE	= $80000   ; 512k works but sound is crap
    ELSE
CHIPMEMSIZE	= $100000
    ENDC
FASTMEMSIZE	= $80000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
;DOSASSIGN
;DEBUG
;INITAGA
HDINIT
;HRTMON
IOCACHE		= 20000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 7000
CBDOSLOADSEG
SEGTRACKER

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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
slv_name		dc.b	"Space Quest I (Enhanced)"
    IFD HALFMEG
    dc.b    " (512k chip)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1991 Sierra",0
slv_info		dc.b	"adapted & fixed by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Thanks to BTTR for disk images",10,10
		dc.b	"Hold F2 to display cartridge codes",10
		dc.b	"Hold F3 to display steering codes",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	10,0
slv_config:
    dc.b    "C4:B:MT-32 sound;"
	dc.b	0
progname
    dc.b    "prog",0
	EVEN

;============================================================================

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg

	move.l	d0,a0
	add.l	a0,a0
	add.l	a0,a0
	cmp.b	#4,(a0)
	bne.b	.skip_prog

	; prog
    
    move.l  d1,a1
    lea pl_main(pc),a0
    move.l  _resload(pc),a2
    movem.l d0-d1/a0-a1,-(a7)
    lea progname(pc),a0
    jsr (resload_GetFileSize,a2)
    cmp.l   #158764,d0
    beq.b   .okay
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
   
   
.okay
    movem.l (a7)+,d0-d1/a0-a1
    
    jsr (resload_PatchSeg,a2)
    lea _tag(pc),a0
    jsr (resload_Control,a2)
    
    bsr _patch_mt32_open
	bsr	_patch_kb
	bsr	_patch_vbl
;;	bra.b	.outcb
.skip_prog
.outcb
	rts

pl_main
	PL_START
    ; section 6
    PL_PS   $6546,_copy_savedir
    ; section 23
    PL_PS   $0f7d0,_check_a0    ; other version F7C4
    ; section 60
	PL_PS	$22B84,_move_a0_1
	PL_PS	$22BA2,_move_a0_2
	PL_P	$22B6A,_and_8_a0
	PL_END

_and_8_a0:
	movem.l	d0,-(a7)
	move.l	a0,d0
	movem.l	(a7)+,d0
	bmi.b	.skip	; a0=$FFFFFFF6 -> AF
	ANDI	#$FFFE,8(A0)		;22B6A: 0268FFFE0008
.skip
	UNLK	A5			;22B70: 4E5D
	RTS				;22B72: 4E75

_move_a0_1:
	; on some memory configs, could trigger an access fault

	cmp.l	#0,a0
	beq.b	.sk

	move.w	(-2,a0),(-6,a5)
	rts
.sk
	clr.w	(-6,a5)
	rts

_move_a0_2:
	; access fault if a0 = 0

	cmp.l	#0,a0
	beq.b	.sk

	move.w	(-6,a5),(-2,a0)
.sk
	rts

_check_a0:
	cmp.l	#0,a0
	beq.b	.sk
	cmp.w	#$1234,-10(a0)
	rts
.sk
	cmp.l	#1,a0	; wrong test
	rts



_wrong_version:
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

_copy_savedir
	movem.l	a0/a1,-(a7)
	move.l	(12,A7),a1	; dest
	cmp.l	(16,A7),a1	; source
	beq.b	.skip


    lea _save(pc),a0
.copy    
	move.b  (a0)+,(a1)+
    bne.b   .copy

	;;;bsr	_patchintuition
.skip
	movem.l	(a7)+,a0/a1

	rts

_save
    dc.b    "SYS:save",0
    even
    
_patchintuition:
	movem.l	D0-A6,-(a7)
	lea	.intname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6

	move.l	a6,a0
	add.w	#_LVOCloseScreen+2,a0
	pea	_quit(pc)
	move.l	(a7)+,(a0)
	
	movem.l	(a7)+,D0-A6
	rts

.intname:
	dc.b	"intuition.library",0
	even

_quit
	PEA	TDREASON_OK
	MOVE.L	_resload(PC),-(A7)
	add.l	#resload_Abort,(a7)
	rts



PLANESIZE=80*200
SCREENSIZE=PLANESIZE
COPPERLIST_SIZE=$40

_patch_kb
	movem.l	D0/D1/A0/A1/A2/A6,-(A7)

	move.l	$68.W,D0
	lea	_kb_routine(pc),A0
	cmp.l	D0,A0
	beq.b	.patched

	lea	_oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
.patched:
	movem.l	(A7)+,D0/D1/A0/A1/A2/A6
	rts

_patch_vbl
	movem.l	D0/D1/A0/A1/A2/A6,-(A7)

	move.l	$6C.W,D0
	lea	_vbl_routine(pc),A0
	cmp.l	D0,A0
	beq.b	.patched

	move.l	$4.W,A6
	lea	_gfxname(pc),a1
	moveq	#0,D0
	JSR	_LVOOpenLibrary(A6)
	lea	_gfxbase(pc),A0
	move.l	D0,(A0)


	lea	.codesraw_1(pc),a3
	lea	_screenbuf_1(pc),a0
	bsr	.makescreen
	lea	.codesraw_2(pc),a3
	lea	_screenbuf_2(pc),a0
	bsr	.makescreen

	lea	_vbl_routine(pc),A0
	lea	_oldvbl(pc),A1
	move.l	$6C.W,(A1)
	move.l	A0,$6C.W
.patched:
	movem.l	(A7)+,D0/D1/A0/A1/A2/A6
	rts

.codesraw_1:
	dc.b	"codes1_640200.raw",0
.codesraw_2:
	dc.b	"codes2_640200.raw",0
	even

; < a0: &screenbuf
; < a3: name of code file to load

.makescreen:
	move.l	A0,-(a7)
	move.l	#MEMF_CHIP|MEMF_CLEAR,D1
	move.l	#SCREENSIZE+COPPERLIST_SIZE,D0
	JSR	_LVOAllocMem(A6)
	move.l	(a7)+,a0
	tst.l	D0
	bne.b	.ok
	ILLEGAL
.ok

	move.l	D0,(a0)

	move.l	D0,A1
	add.l	#COPPERLIST_SIZE,D0
	move.l	D0,A2

	move.w	#color+2,(A1)+
	move.w	#$0,(A1)+
	move.l	#$2001FF00,(A1)+
	move.w	#bplcon0,(A1)+
	move.w	#$9200,(A1)+
	move.w	#color,(A1)+
	move.w	#$0,(A1)+
	move.w	#color+2,(A1)+
	move.w	#$EE3,(A1)+
	move.w	#bplpt,(A1)+
	swap	D0		; LSW
	move.w	D0,(A1)+
	swap	D0		; MSW
	move.w	#bplpt+2,(A1)+
	move.w	D0,(A1)+
	move.l	#$E60FFFFE,(a1)+	; limit display height
	move.w	#color+2,(A1)+
	move.w	#$0,(A1)+

	move.l	#$FFFFFFFE,(A1)+

	move.l	a3,a0
	move.l	a2,a1
	move.l	_resload(pc),A2
	jsr	resload_LoadFile(a2)
	rts

	even


_vbl_routine:
	movem.l	D0/A0,-(A7)
	move.w	$DFF01E,D0
	and.w	#$20,D0
	beq.b	.novbl

	move.b	$bfec01,d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	#$51,d0		; F2
	bne.b	.nocode1
	move.w	SR,-(A7)
	move.w	#$2700,SR
	move.l	_screenbuf_1(pc),A0
	bsr	.toggle	
	move.w	(A7)+,SR
	bra.b	.novbl
.nocode1
	cmp.b	#$52,d0		; F3
	bne.b	.nocode2
	move.w	SR,-(A7)
	move.w	#$2700,SR
	move.l	_screenbuf_2(pc),A0
	bsr	.toggle	
	move.w	(A7)+,SR
;;	bra.b	.novbl
.nocode2
.novbl:
	movem.l	(A7)+,D0/A0
	move.l	_oldvbl(pc),-(A7)
	rts

; < A0: screen buffer

.toggle:
	bsr	_ack_kb
	move.w	#8,$DFF01E

	movem.l	D0-A6,-(A7)

	move.w	$DFF000+dmaconr,D0
	move.l	D0,-(A7)
	move.w	#$2F,$DFF000+dmacon	; stop sprite+sound

	move.l	A0,$DFF080
;;;;	move.w	#0,$DFF088

.wait1
	move.b	$bfec01,d0
	ror.b	#1,d0
	not.b	d0
	cmp.b	#$51+$80,d0
	beq.b	.go
	cmp.b	#$52+$80,d0
	beq.b	.go
	bra.b	.wait1
.go

	bsr	_ack_kb

	move.l	_gfxbase(pc),A0
	move.l	$26(A0),$DFF080
;;;;	move.w	#0,$DFF088

	move.l	(A7)+,D0
	or.w	#$8000,D0
	move.w	D0,dmacon+$dff000

	movem.l	(A7)+,D0-A6
	rts


_kb_routine:
	bsr	_ack_kb
	move.l	_oldkb(pc),-(A7)
	rts


_ack_kb:
	movem.l	D0,-(A7)
	bset	#6,$BFEE01
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	rts

_oldkb:
	dc.l	0
_oldvbl:
	dc.l	0

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
    cmp.w	#$4EF9,(A1)
    beq.b   end_patch_\1    ; already done
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	old_\1(pc),a0
	move.l	A1,(A0)+

	move.l	A6,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)		; moves to d0_value_xxx

	move.w	#$4EF9,(A1)+	
	pea	new_\1_init(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
new_\1_init
	move.l	d0_value_\1(pc),d0
	bra	new_\1
old_\1:
	dc.l	0
d0_value_\1
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
	ENDM
    
_patch_mt32_open
    movem.l d0-d1/a0-a1/a6,-(a7)
    move.l  _mt32_support(pc),d0
    beq   .nomt32
    lea  .dosname(pc),a1
    moveq.l #0,d0
    move.l  4,a6
    jsr (_LVOOpenLibrary,a6)
    move.l  d0,a6
    
    bsr .patchdos
    
    lea	.mt32_driver(pc),a0
    move.l	_resload(pc),a2
    jsr	resload_GetFileSize(a2)
    tst.l   d0
    bne.b   .okay
    pea	.missingmt32_message(pc)
    pea	TDREASON_FAILMSG
    move.l	(_resload,pc),-(a7)
    add.l	#resload_Abort,(a7)
    rts
.okay
    lea	.serial(pc),a0
    move.l	_resload(pc),a2
    jsr	resload_GetFileSize(a2)
    tst.l   d0
    bne.b   .okay2
    pea	.missingserial_message(pc)
    pea	TDREASON_FAILMSG
    move.l	(_resload,pc),-(a7)
    add.l	#resload_Abort,(a7)
    rts
.okay2
    lea	.mt32_res(pc),a0
    move.l	_resload(pc),a2
    jsr	resload_GetFileSize(a2)
    tst.l   d0
    bne.b   .okay3
    pea	.missingmt32res_message(pc)
    pea	TDREASON_FAILMSG
    move.l	(_resload,pc),-(a7)
    add.l	#resload_Abort,(a7)
    rts
.okay3
.nomt32
    movem.l (a7)+,d0-d1/a0-a1/a6
    rts

.mt32_driver:
    dc.b    "mt32.drv",0
.missingmt32_message
    dc.b    "file mt32.drv is missing.",10
    dc.b    "Make sure that game was properly installed",0
.mt32_res:
    dc.b    "res_mt32.cfg",0
.missingmt32res_message
    dc.b    "file res_mt32.cfg is missing.",10
    dc.b    "Make sure that game was properly installed",0
.serial:
    dc.b    "devs/serial.device",0
.missingserial_message
    dc.b    "file serial.device is missing in devs.",10
    dc.b    "Make sure that game was properly installed",0
.dosname
    dc.b    "dos.library",0
    even
.patchdos
    PATCH_DOSLIB_OFFSET Open
    PATCH_DOSLIB_OFFSET Lock
    rts
    
new_Lock
    bsr strip_colon
    bsr _rename_file        ; must be defined by specific program
    bsr _rename_mt32
    move.l  a0,d1
    move.l  old_Lock(pc),-(a7)
    rts
   
new_Open
    bsr strip_colon
    bsr _rename_file
    bsr _rename_mt32
    move.l  a0,d1
    move.l  old_Open(pc),-(a7)
    rts
    
; < A0: filename
; > A0: new name
_rename_file:
    rts
    
_rename_mt32:
    cmp.b   #'C',(9,a0)   ; RESOURCE.CFG
    bne.b   .nores
    cmp.b   #'F',(10,a0)
    bne.b   .nores
    cmp.b   #'R',(a0)
    bne.b   .nores
    lea .mt32resname(pc),a0
.nores
    rts
.mt32resname
    dc.b    "res_mt32.cfg",0
        even
strip_colon
    ; strip colon if volume name is whdload
    move.l  d1,a0
    rts
    cmp.b   #':',(7,a0)
    bne.b   .nocolon
    addq.l  #8,a0
.nocolon
    rts


_gfxbase
	dc.l	0
_screenbuf_1
	dc.l	0
_screenbuf_2
	dc.l	0
_gfxname:
	dc.b	"graphics.library",0
	even

_tag		dc.l	WHDLTAG_CUSTOM4_GET
_mt32_support	dc.l	0
		dc.l	0

