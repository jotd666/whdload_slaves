;*---------------------------------------------------------------------------
;  :Program.	DangerFreakHD.asm
;  :Contents.	Slave for "DangerFreak" from
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	DangerFreak.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = 0

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_ClearMem	;ws_flags
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem	
	IFD	USE_FASTMEM	
	dc.l	EXPMEMSIZE			;ws_ExpMem
	ELSE
	dc.l	0
	ENDC
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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

_name		dc.b	"Danger Freak"
		dc.b	0
_copy		dc.b	"1989 Rainbow Arts",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

;======================================================================
start	;	A0 = resident loader
;======================================================================

		move.w	#$2700,SR
        lea CHIPMEMSIZE-$10,a7
        
		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

		move.l	a0,a2
	;	lea	(_tag,pc),a0
	;	jsr	(resload_Control,a2)

		lea	$400,a0
		move.l	#$1600,D0		; offset
		move.l	#$640,D1		; length
		moveq	#1,D2
		jsr	resload_DiskLoad(a2)

		lea	pl_boot(pc),a0
		sub.l	a1,a1
		jsr	resload_Patch(a2)
        
		jmp	$400.W

pl_boot
	PL_START
	PL_P	$526,read_tracks
;;	PL_S	$452,$7E-$52	; skip protection
	PL_S	$44E,$7E-$4E	; skip load of a zone with protected tracks + protection check
	PL_P	$514,jump_1000
    PL_PS    $0448,set_keyboard_interrupt
	PL_END

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
    
set_keyboard_interrupt
    pea keyboard_interrupt(pc)
    move.l  (a7)+,$68.W
    rts
    
keyboard_interrupt
	movem.l	D0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here

    cmp.b   _keyexit(pc),d0
    beq.b   quit
        
	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a5
	move.w	#8,$dff09c
	rte
   
jump_1000
    
	movem.l	d0-a6,-(a7)
	move.l	(_resload,pc),a2

	; wait 3 seconds to show title screen

	move.l	#30,d0
	jsr	(resload_Delay,a2)

	; patch main proggy

	lea	pl_1000(pc),a0
	sub.l	A1,A1
	jsr	(resload_Patch,a2)

	movem.l	(a7)+,d0-a6
    
    jmp $1000
    ; to skip all save context code, keep our stack in fastmem
	; jmp	$1050.W

pl_1000
	PL_START
    PL_P    $42D8,af_loop
	PL_PSS	$4CE0,run_program,4
    PL_PS   $4824,run_menu
    PL_W    $47FA,$C028 ; enable our keyboard handler
    

	PL_END

af_loop
.loop
    move.l  a0,d1
    bmi.b   .out
	MOVE	(A1)+,D1		;42D8: 3219
	LSL	#4,D1			;42DA: E949
	MOVE	D1,(A0)			;42DC: 3081
	ADDA.L	#$00000010,A0		;42DE: D1FC00000010
	DBF	D0,.loop		;42E4: 51C8FFF2
.out
	RTS				;42E8: 4E75
    
run_menu
    ; patch menu
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	lea	pl_menu(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6

    JMP $00007398

; 73D4 : there was a bsr 77F2 nasty crash. 14 years later, I found
; that was because of stealthy self-modifying code on JMP that could have been
; avoided very easily by just pushing data register in the stack and RTS
; (like I did). Less cycles, no more writes... plain stupid to use SMC
; specially there.

pl_menu:
	PL_START
	PL_PSS  $078d2,move_dmacon_82,2
	PL_PSS  $078de,move_dmacon_80,2

    ; stupid SMC in music routine that crash the game
    ; but only on real 020+ machines or with "more compatible" winuae option
    ; (prefetch is different depending on CPUs / prefetch compat)
    PL_P    $07564,avoid_smc_d0
    PL_P    $07740,avoid_smc_d1
    PL_P    $078b2,avoid_smc_d1
	PL_END

restore_regs
    movem.l (a7)+,d0-a6
    addq.l  #4,a7
    rts
    
    
avoid_smc_d0:
    move.l  d0,-(a7)
    rts
avoid_smc_d1:
    move.l  d1,-(a7)
    rts
    
restore_and_flush
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	MOVEM.L	(A7)+,A0/A6		;07d6e: 4cdf4100
	rts    
    
move_dmacon_82:
    MOVE.W	(82,A5),_custom+dmacon		;: 33ed005200dff096
    bra.b wait_dma
    
move_dmacon_80:
    MOVE.W	(80,A5),_custom+dmacon		;: 33ed005200dff096
    ;bra.b wait_dma
    
 
wait_dma
	move.w  d0,-(a7)
	move.w	#4,d0
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
    

run_program

	cmp.l	#$C024,a0
	beq	j_c024
next    
	jsr	(a0)
	rts


j_c024
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	lea	pl_c024(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
    bra.b   next

	move.l	#1600,d0
	bsr	beamdelay
	rts

pl_c024:
	PL_START
	PL_P	$C0CE,jmp_21000
	PL_END

jmp_21000
	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	lea	pl_21000(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)

	movem.l	(a7)+,d0-a6

	jmp	$21000

kb_delay:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	bclr	#6,$BFEE01
	rts

end_kb
	MOVEM.L	(A7)+,D0-D2/A0-A1	;229D6: 4CDF0307
	move.w	#$8,$dff09C
	RTE				;229DA: 4E73

pl_21000
	PL_START
	PL_S	$2297A,$82-$7A
	PL_PSS	$229A4,kb_delay,4
	PL_P	$229D6,end_kb
    
    ; dma wait, like in menu
    
	PL_PSS  $2A428,move_dmacon_82,2
	PL_PSS  $2A434,move_dmacon_80,2
    
    
    ; replaces the strange way to wait for blitter
    ; (ANDI	#$4000,DMACONR)
    PL_PSS   $293CE,wait_blit,2
    
    PL_W    $29414,$8440    ; enable blitter dma besides blitpri
 
    IFEQ    1
    PL_W    $29414,$8040    ; remove blitter priority/enable blitter dma
	PL_PS	$2943A,blit_d3
	PL_PS	$29446,blit_d3
	PL_PS	$2945A,blit_d3
	PL_PS	$29466,blit_d3
	PL_PS	$29472,blit_d3
	PL_PS	$2947E,blit_d3
	PL_PS	$2948A,blit_d3
	PL_PS	$29496,blit_d3
	PL_PS	$29642,blit_d7
	PL_PS	$29726,blit_d7
	PL_PS	$29756,blit_d7
	PL_PS	$297C4,blit_d7
	PL_PS	$2981A,blit_d7

	PL_PS	$293CE,blit_wait_1
	PL_PS	$295A4,blit_wait_1
	PL_PS	$2964A,blit_wait_1
    ENDC

    ; stupid SMC in music routine that crash the game
    PL_P    $2A0BA,avoid_smc_d0
    PL_P    $2A408,avoid_smc_d1
    PL_P    $2A296,avoid_smc_d1
    
	PL_END

    
blit_wait_1
	bsr	wait_blit
	add.l	#4,(a7)
	rts

blit_d3
	move.w	d3,bltsize+$DFF000
	bsr	wait_blit
	rts

blit_d7
	move.w	d7,bltsize+$DFF000
	bsr	wait_blit
	rts
	
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts

; < A0: load address
; < D0: index in the "file" table

read_tracks
	movem.l	d0-a6,-(a7)
	lea	$9B4.W,a1	; file table
	and.l	#$F,d0
	lsl.l	#3,d0
	move.l	0(a1,d0.L),d5	
	move.l	d5,d1		; length

	moveq	#0,d2
	move.b	4(a1,d0.L),d2
	mulu	#$2800,d2	
	tst.b	5(a1,d0.l)
	beq.b	.sk
	add.l	#$1400,d2	; side 1
.sk
	add.l	#$200,d2	; first track is dos $1600

	move.l	d2,d0		; offset
	moveq	#1,d2		; first (and only) disk

	move.l	(_resload,pc),a2
	jsr	(resload_DiskLoad,a2)

	movem.l	(a7)+,d0-a6
	rts


;--------------------------------

_resload	dc.l	0		;address of resident loader

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
