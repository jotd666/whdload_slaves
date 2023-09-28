;*---------------------------------------------------------------------------
;  :Program.	BallRaiderIIHD.asm
;  :Contents.	Slave for "BallRaiderII"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BallRaiderIIHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"BallRaiderII.slave"
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
	IFD	DEBUG
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE = $80000
FASTMEMSIZE = $40000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %1111

DISKSONBOOT
BOOTBLOCK
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
;;CBDOSLOADSEG

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	INCLUDE	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

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
; 4e15e ???
; 0004E173=000C: nb bricks

slv_name		dc.b	"BallRaider II",0
slv_copy		dc.b	"1988 US Action - Worldwide",0
slv_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Press HELP to skip levels when ball is in motion",10,10

		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
slv_config:
	dc.b	"BW;"
	dc.b    "C1:B:Infinite lives;"
	dc.b	0

	dc.b	"$","VER: slave "
	DECL_VERSION

	EVEN

;============================================================================


; < A4: bootblock pointer

_bootblock


	;;movem.l	a6,-(A7)

	movem.l	a0-a2/d0-d1,-(A7)
	move.l	_resload(pc),a2
	lea	_tag(pc),a0
	jsr	(resload_Control,a2)
	lea	pl_bootblock(pc),a0
	move.l	a4,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,a0-a2/d0-d1
	jsr	($C,a4)
	
	moveq.l	#0,D0
	rts
	
pl_bootblock
	PL_START
	PL_P	$38,jump_4003E
	PL_END
	
jump_4003E
	movem.l	a0-a2/d0-d1,-(A7)
	lea	pl_40000(pc),a0
	lea	$40000,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,a0-a2/d0-d1
	jmp	$4003E
	

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
	
pl_40000:
	PL_START
	; skip hardware banging write protection test
	PL_S	$E4,$112-$E4
	PL_P	$138,jump_1
	PL_END

jump_1:
	; shows title picture and waits for F1/F2
	movem.l	a0-a2/d0-d1,-(A7)
	move.l	_buttonwait(pc),d0
	beq.b	.nobw
.loop
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.out
	bra.b	.loop
.out	
	btst	#6,$bfe001
	beq.b	.out
.nobw
	move.l	$4,A6
	LEA	GraphicsName(pc),A1
	JSR	(_LVOOldOpenLibrary,A6)
	move.l	d0,a6
	PATCH_XXXLIB_OFFSET	Text
	
	lea	pl_titlepic(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,a0-a2/d0-d1
	
	JMP $00068938
   
 ; patch graphics.Text as it seems that several calls to Text give incorrect
 ; result if machine is too fast. Found in 2019, never heard of that
 ; bug before...
new_Text:
	movem.l	a0-a1/d0-d1/a6,-(A7)
	move.l	#10,d0
	bsr	_beamdelay
	movem.l	(a7)+,a0-a1/d0-d1/a6
	move.l	old_Text(pc),-(A7)
	rts
	
pl_titlepic
	PL_START
	PL_PS	$68A84,read_keyboard
	PL_P	$68C34,start_game
	PL_P	$68D08,start_editor
	PL_END
	
read_keyboard:
	btst	#6,$bfe001
	beq.b	.game
	MOVE.B $00bfec01,D0
	movem.l	d1,-(a7)
	move.w	$DFF016,d1
	btst	#10,d1	; RMB
	bne.b	.normb
	move.l	#$5d,D0
.normb
	movem.l	(a7)+,d1
	movem.l	d0,-(a7)
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq	_quit
	movem.l	(a7)+,d0
	rts
.game:
	; release
.out
	btst	#6,$bfe001
	beq.b	.out
	move.b	#$5F,D0
	rts
	
start_editor:
	movem.l	a0-a2/d0-d1,-(A7)
	lea	pl_editor(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,a0-a2/d0-d1
	JMP $00024910

start_game:
	movem.l	a0-a2/d0-d1,-(A7)
	lea	pl_main(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
	movem.l	(a7)+,a0-a2/d0-d1	
	JMP $247c8
	
wait_blit
	BTST	#6,dmaconr+$DFF000
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait

	rts
pl_editor
	PL_START
	PL_PS	$25484,blitwait_ra1_050
	PL_PS	$262a8,blitwait_ra1_050

	PL_END
	
pl_main
	PL_START
	PL_IFC1
	PL_NOP	$35264,10
	PL_NOP	$3534e,10
	PL_ENDIF
	
	PL_PS	$25670,game_menu_keyboard
	; kickstart has 68000 quitkey too, used for cheat
	PL_PS	$32B8A,game_keyboard
	PL_PS	$35650,blitwait_ra1_050
	PL_PS	$356a4,blitwait_ra3_050
	PL_PS	$356e0,blitwait_ra5_050
	PL_PS	$35728,blitwait_ra5_050
	PL_PS	$35770,blitwait_ra5_050
	PL_PSS	$357e2,blitwait_imm_4dca8_050,4
	PL_PSS	$35846,blitwait_imm_4dcc8_050,4
	PL_PS	$3595c,blitwait_ra1_050
	PL_PS	$359b0,blitwait_ra3_050
	PL_PS	$359ec,blitwait_ra5_050
	PL_PS	$35a34,blitwait_ra5_050
	PL_PS	$35a7c,blitwait_ra5_050
	PL_PS	$35b0e,blitwait_ra0_050
	PL_PS	$35b62,blitwait_ra0_050
	PL_PS	$35c34,blitwait_ra1_050
	PL_PS	$35c88,blitwait_ra3_050
	PL_PS	$35cc4,blitwait_ra5_050
	PL_PS	$35d0c,blitwait_ra5_050
	PL_PS	$35d54,blitwait_ra5_050
	PL_PS	$35de6,blitwait_ra6_04c
	PL_PS	$35e42,blitwait_ra0_050
	PL_PS	$35f0e,blitwait_ra1_050
	PL_PS	$35f62,blitwait_ra3_050
	PL_PS	$35f9e,blitwait_ra5_050
	PL_PS	$35fe6,blitwait_ra5_050
	PL_PS	$3602e,blitwait_ra5_050
	PL_PSS	$4e27a,blitwait_4e592_064,4
	PL_PS	$4e302,blitwait_ra1_050
	PL_PSS	$4e338,blitwait_4e592_066,4
	PL_PS	$4e38a,blitwait_ra1_050
	PL_PSS	$4e3c6,blitwait_4e592_066,4
	PL_PS	$4e42e,blitwait_ra0_050
	PL_PSS	$4e47a,blitwait_4e59e_050,4
	PL_PS	$4e4f8,blitwait_rd3_066
	PL_PS	$4e50a,blitwait_ra0_050
	PL_PS	$4e54c,blitwait_ra0_050
	PL_PSS	$4e6e8,blitwait_4ea00_064,4
	PL_PS	$4e770,blitwait_ra1_050
	PL_PSS	$4e7a6,blitwait_4ea00_066,4
	PL_PS	$4e7f8,blitwait_ra1_050
	PL_PSS	$4e834,blitwait_4ea00_066,4
	PL_PS	$4e89c,blitwait_ra0_050
	PL_PSS	$4e8e8,blitwait_4ea0c_050,4
	PL_PS	$4e966,blitwait_rd3_066
	PL_PS	$4e978,blitwait_ra0_050
	PL_PS	$4e9ba,blitwait_ra0_050
	PL_PSS	$4eb56,blitwait_4ee6e_064,4
	PL_PS	$4ebde,blitwait_ra1_050
	PL_PSS	$4ec14,blitwait_4ee6e_066,4
	PL_PS	$4ec66,blitwait_ra1_050
	PL_PSS	$4eca2,blitwait_4ee6e_066,4
	PL_PS	$4ed0a,blitwait_ra0_050
	PL_PSS	$4ed56,blitwait_4ee7a_050,4
	PL_PS	$4edd4,blitwait_rd3_066
	PL_PS	$4ede6,blitwait_ra0_050
	PL_PS	$4ee28,blitwait_ra0_050

	PL_END

game_keyboard:
	MOVE.B	$bfec01,D0
	movem.l	d0,-(a7)
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq	_quit
	cmp.b	#$5F,D0	; help: levelskip
	bne.b	.nolskip
	clr.b	$4E173		; remaining bricks
.nolskip
	movem.l	(a7)+,d0
	rts
	
.normal_levels:
	move.b	#$fd,D2
	rts
game_menu_keyboard:
	MOVE.B	$bfec01,D2
	btst	#6,$bfe001
	beq.b	.normal_levels
	movem.l	d0,-(a7)
	move.w	$DFF016,d0
	btst	#10,d0	; RMB
	bne.b	.normb
	move.l	#$fb,D2
.normb
	move.w	#$CC01,$dff034
	MOVE.B d2,D0
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq	_quit
	movem.l	(a7)+,d0
	rts
.normal_levels:
	move.b	#$fd,D2
	rts
;  custom
	
_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
blitwait_ra1_050:
	bsr	wait_blit
	move.l	a1,$dff050
	rts

blitwait_ra3_050:
	bsr	wait_blit
	move.l	a3,$dff050
	rts

blitwait_ra5_050:
	bsr	wait_blit
	move.l	a5,$dff050
	rts

blitwait_imm_4dca8_050:
	bsr	wait_blit
	move.l	#$4dca8,$dff050
	rts
blitwait_imm_4dcc8_050:
	bsr	wait_blit
	move.l	#$4dcc8,$dff050
	rts
blitwait_ra0_050:
	bsr	wait_blit
	move.l	a0,$dff050
	rts

blitwait_ra6_04c:
	bsr	wait_blit
	move.l	a6,$dff04c
	rts

blitwait_4e592_064:
	bsr	wait_blit
	move.w	$4e592,$dff064
	rts
blitwait_4e592_066:
	bsr	wait_blit
	move.w	$4e592,$dff066
	rts
blitwait_4e59e_050:
	bsr	wait_blit
	move.l	$4e59e,$dff050
	rts
blitwait_rd3_066:
	bsr	wait_blit
	move.w	d3,$dff066
	rts

blitwait_4ea00_064:
	bsr	wait_blit
	move.w	$4ea00,$dff064
	rts
blitwait_4ea00_066:
	bsr	wait_blit
	move.w	$4ea00,$dff066
	rts
blitwait_4ea0c_050:
	bsr	wait_blit
	move.l	$4ea0c,$dff050
	rts
blitwait_4ee6e_064:
	bsr	wait_blit
	move.w	$4ee6e,$dff064
	rts
blitwait_4ee6e_066:
	bsr	wait_blit
	move.w	$4ee6e,$dff066
	rts
blitwait_4ee7a_050:
	bsr	wait_blit
	move.l	$4ee7a,$dff050
	rts
	


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


_tag		dc.l	WHDLTAG_BUTTONWAIT_GET
_buttonwait	dc.l	0
		dc.l	0

	
GraphicsName
	dc.b	"graphics.library",0

	
;============================================================================

	END
