
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"SpacePort.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

;DEBUG
;FILERIP
;BW

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
	IFND DEBUG
		dc.w	17			;ws_Version
	ELSE
		dc.w	18			;ws_Version
	ENDC
		dc.w	WHDLF_NoError|WHDLF_ClearMem|WHDLF_EmulTrap;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	Start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug = F9
_keyexit	dc.b	$5F;ws_keyexit = help
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

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

_name		dc.b	"Space Port",0
_copy		dc.b	"1987 ReLine",0
_info		dc.b	"Adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_data		dc.b	"data",0
_config
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C2:X:Trainer Infinite Fuel:0;"
		dc.b    "C3:X:Turn off all speed throttling:0;"			
		dc.b	0

	EVEN

BOOT_ADDRESS = $30000

;======================================================================
Start	;	A0 = resident loader
;======================================================================

		bsr	calibrate_delay_loop
		lea	$1000,a7
		MOVE	#$2000,SR
		
		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		move.l	a0,a2			;A2 = resload
				
		pea	int3(pc)
		move.l	(a7)+,$6C.W
		pea keyboard_interrupt(pc)
		move.l	(a7)+,$68.W
		
		lea	_boot(pc),a0
		lea	BOOT_ADDRESS,a1
		move.l	a1,a3
		jsr	(resload_LoadFileDecrunch,a2)

		lea	pl_main(pc),a0
		lea	BOOT_ADDRESS,a1
		jsr	(resload_Patch,a2)

		jmp	BOOT_ADDRESS
		

int3
	movem.l	a0,-(a7)
	lea	vbl_int_counter(pc),a0
	addq.l	#1,(a0)
	movem.l	(a7)+,a0
	move.w	#$7FFF,$DFF09C
	RTE
calibrate_delay_loop
	lea	_custom,a2
	move.w	#$4000,(intena,a2)
.vbl
	btst	#5,(intreqr+1,a2)
	beq.b	.vbl
	
	move.w	#$3FFF,(intreq,a2)
	move.l	#0,d0
.loop
	add.l	#1,d0
	btst	#5,(intreqr+1,a2)
	beq.b	.loop
	
	move.w	#$C000,(intena,a2)
	lea	vbl_counter(pc),a2
	sub.l	#$D37,D0
	bpl.b	.pos
	moveq.l	#0,d0
.pos
	; on a real amiga (well rather WinUAE A500 real speed), value is roughly $D37
	; so now vbl_counter contains 0 or more
	move.l	d0,(a2)
	rts	
vbl_counter
	dc.l	0
vbl_int_counter
	dc.l	0
	
keyboard_interrupt
	movem.l	D0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
	; free 68000 quitkey
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
.noquit
	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a5
	move.w	#8,$dff09c
	rte
	
pl_main
	PL_START
	PL_PS	$F2A,get_fake_dosbase	; "emulate" doslib
	PL_R	$16fe	; disk "protection"
	; patch interrupt handler
	PL_NOP	$6fa0,4		; remove save registers
	PL_P	$6fc8,end_level3_interrupt
	PL_P	$6f3a,end_install_interrupts
	PL_W	$6f4e,$C02C
	PL_I	$6f94	; no interrupts other than level 3
	; cpu dependent loops (19 hits over 7 different types,
	; must be some kind of a record!!!)
	PL_PSS	$119e,subq_d7_loop,2
	PL_PSS	$2988,subq_d7_loop,2
	PL_PSS	$2a4c,subq_d7_loop,2
	PL_PSS	$2c24,subq_d7_loop,2
	PL_PSS	$2c48,subq_d7_loop,2
	PL_PSS	$2c6c,subq_d7_loop,2
	PL_PSS	$2ed6,subq_d7_nop_loop,4
	PL_PSS	$2fb4,subq_d7_loop,2
	PL_PSS	$3170,subq_d7_loop,2
	PL_PSS	$33dc,subq_d7_loop,2
	PL_PSS	$3442,subq_d7_loop,2
	PL_PSS	$38CE,subq_d7_loop,2
	PL_PSS	$58b2,subq_d4_loop,2
	PL_PSS	$58d2,subq_d4_loop,2
	PL_PSS	$6c48,subq_d5_loop,2
	PL_PS	$57fc,dbf_d6_nop_loop
	PL_PS	$2138,dbf_d7_nop_loop
	PL_PS	$214c,dbf_d7_nop_loop
	PL_PS	$1904,dbf_d2_nop_loop
	PL_IFC1
	PL_NOP	$2970,6
	PL_NOP	$2792,6
	PL_ENDIF
	PL_IFC2
	PL_NOP	$2aa6,6
	PL_ENDIF
	PL_IFC3
	PL_ELSE
	PL_PS	$1bc4,game_loop
	PL_PS	$288a,heli_crash_loop

	PL_ENDIF
	
	PL_END
heli_crash_loop:
	move.w	d0,d1
	bsr	random
	and.w	#$0FFF,d0
	or.w	d1,d0
	MOVE.W	D0,$dff0d8
	movem.l	a0,-(a7)
	lea		.crash_count(pc),a0
	subq.w	#1,(a0)
	bne.b	.out
.wait
	move.w	#500,(a0)
	; now wait a little while
	move.l	vbl_counter(pc),d0
	lsr.l	#8,d0
	lsr.l	#2,d0
	addq.l	#1,d0
	bsr	beamdelay
.out
	movem.l	(a7)+,a0
	rts
.crash_count
	dc.w	1

; < D0: pseudo random value (32 bits)
random:
	movem.l	a0,-(a7)
	lea	.seed(pc),a0
	move.l	(a0),d0
	; thanks meynaf
	mulu #$a57b,d0
	addi.l #$bb40e62d,d0
	rol.l #6,d0	
	move.l	d0,(a0) 
	movem.l	(a7)+,a0
	rts
.seed
	dc.l	$12345678
	
game_loop:
	movem.l	d0/a0,-(a7)
	lea	step(pc),a0
	sub.w	#1,(a0)
	bne.b	.skip
	move.w	#40,(a0)
	lea	prev_value(pc),a0
.wait
	move.l	vbl_int_counter(pc),d0
	cmp.w	(a0),d0
	beq.b	.wait
	move.w	d0,(a0)
.skip	
	movem.l	(A7)+,d0/a0
	JMP	$3218a

prev_value
	dc.w	0
step
	dc.w	1
	
; not sure of the timings, completely random :)
; Used the ones of empty dbfs
; with a lower division factor (for DBF without nop
; the value is $28)

CPU_LOOP:MACRO
	move.l	d0,-(a7)
	move.l	\1,d0
	lsr.l	#3,d0
	swap	D0
	clr.w	D0
	swap	D0
	divu.w	#\2,D0
	swap	D0
	clr.w	D0
	swap	D0
	lsl.l	#3,d0
	bsr	beamdelay
	move.l	(a7)+,d0
	rts
	ENDM
	
subq_d7_nop_loop
	CPU_LOOP	d7,$C
subq_d7_loop
	CPU_LOOP	d7,$10
subq_d4_loop
	CPU_LOOP	d4,$10
subq_d5_loop
	CPU_LOOP	d5,$10
	
dbf_d2_nop_loop
	CPU_LOOP	d2,$24
dbf_d6_nop_loop
	CPU_LOOP	d6,$24
dbf_d7_nop_loop
	CPU_LOOP	d7,$24

	
	
end_level3_interrupt
	MOVE.W	#$7fff,$DFF09C		;36fa4: 33fc7fff00dff09c
	RTE
	
end_install_interrupts
	move.w	#$C020,$DFF09A
	move.w	#$C3F0,$DFF096
	rts
	
get_fake_dosbase:
	lea	fake_dosbase(pc),a0
	; install fake
	lea	(-30,a0),a1
	pea	fake_open(pc)
	move.w	#$4EF9,(a1)+
	move.l	(a7)+,(a1)+
	lea	(-36,a0),a1
	pea	fake_close(pc)
	move.w	#$4EF9,(a1)+
	move.l	(a7)+,(a1)+
	lea	(-42,a0),a1
	pea	fake_read(pc)
	move.w	#$4EF9,(a1)+
	move.l	(a7)+,(a1)+
	; return fake base
	move.l	a0,d0
	rts

; enough for Read/Open/Close in sequence and that's it
	ds.b	42
fake_dosbase:

fake_read:
	movem.l	a2,-(a7)
	; < D1: handle (ignored)
	; < D2: buffer
	; < D3: length
	move.l	_resload(pc),a2
	move.l	filename(pc),a0	
	jsr	resload_GetFileSize(A2)
	cmp.l	d3,d0
	bcc.b	.ok
	move.l	d0,d3	; max out to file size
.ok
	move.l	d2,a1	; destination
	move.l	d3,d0	; size
	moveq.l	#0,d1	; offset
	move.l	filename(pc),a0	
	jsr	resload_LoadFileOffset(A2)
	movem.l	(a7)+,a2
	rts
	
fake_close:
	RTS
fake_open:
	lea	filename(pc),a0
	move.l	d1,(a0)
	RTS
		
kbint:
	move.b	$BFEC01,D0
	move.l	D0,-(sp)
	ror.b	#1,D0
	not.b	D0
	
	cmp.b	_keyexit(pc),D0
	bne	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	move.l	(sp)+,D0
	rts	



; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	tst.l	d0
	beq.b	.out
	move.l  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	subq.l	#1,d0
	bne.b	.bd_loop1
.out
	rts
	



;======================================================================
_boot:
	dc.b	"portcode",0

	cnop	0,4
filename
		dc.l	0
_resload	dc.l	0		;address of resident loader
	END
