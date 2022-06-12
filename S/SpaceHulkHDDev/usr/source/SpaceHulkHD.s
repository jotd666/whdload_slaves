	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	hardware/custom.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	SpaceHulk.slave
	ENDC

;CHIP_ONLY

	IFD	CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = $000
	ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000	
	ENDC
	
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_whddata-_base	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
		dc.l	FASTMEMSIZE			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
_config
	;dc.b    "C1:X:Boot on expansion disk:0;"
	dc.b	0

DECL_VERSION:MACRO
	dc.b	"2.0"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_whddata:
		dc.b	"data",0
_name		dc.b	"Space Hulk",0
_copy		dc.b	"1993 Electronic Arts",0
_info		dc.b	"installed & fixed by JOTD",10,10
	dc.b	'Thanks to Frank for installer and icons',10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

_Start
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	IFD	CHIP_ONLY
	lea	_expmem(pc),a0
	move.l	#$80000,(a0)
	ENDC
	
	lea	expmem_mask(pc),a0
	move.l	_expmem(pc),d0
	and.l	#$C0000000,d0	; keep 2 last bits
	move.l	d0,(a0)
	
;	move.l	#CACRF_EnableI,D0
;	move.l	D0,D1
;	jsr	(resload_SetCACR,a2)

	move.l	_expmem(pc),A3

	; init: freezes all interrupts

	MOVEA.L	#$7FF00,A7

	lea	_exename(pc),a0
	move.l	A3,A1
	jsr	(resload_LoadFile,a2)

	move.l	A3,A0
	sub.l	A1,A1
	jsr	(resload_Relocate,a2)

	lea	_pmain(pc),a0
	move.l	A3,A1
	jsr	(resload_Patch,a2)
	
	move.w	#$2700,SR
	lea		game_address(pc),a0
	move.l	a3,a1
	add.l	#$11514,a1
	move.l	a1,(a0)
	blitz
	jmp	$94(a3)

_resload:
	dc.l	0

_pmain:		PL_START
		PL_W	$1C92,$6006		; avoid SNOOP bug (potgo)
		PL_R	$E7C		; skip drive stuff
		PL_P	$2F52,_readfile		; disk read routine
		PL_W	$172,$6004
		PL_NOP	$AA,2
		PL_PSS	$FED6,soundtracker_loop,2
		PL_PSS	$0feec,soundtracker_loop,2


		PL_P	$CD34,_blit1		; blitter wait
		PL_P	$CD56,_blit1		; blitter wait

		PL_NOP	$CF3C,2		; blitter wait
		PL_PS	$CF3E,_blit2		; blitter wait
		PL_NOP	$CCF2,2		; blitter wait
		PL_PS	$CCF4,_blit4		; blitter wait

		PL_PS	$CD14,_blit3

		PL_P	$24E9E,_avoid_af	; access fault

		PL_PS	$01470,_kbint

		; below are the fixes for 32-bit expansion memory
		PL_PS	$0d7ac,get_masked_base_address
		; fixes addresses when drawing the map (5 bitplanes)
		PL_PS	$0de3c,fix_d6_1
		PL_PS	$0df82,fix_d6_1
		PL_PS	$0e07e,fix_d6_1
		PL_PS	$0df06,fix_d6_2
		PL_PS	$0e036,fix_d6_2
		
		;;PL_PS	$0df86,restore_msb_1
		;;PL_PS	$0dfa0,restore_msb_2
		;;PL_PS	$0dfae,restore_msb_3
		;;PL_PS	$0dfbc,restore_msb_4
		;;PL_PS	$0dfca,restore_msb_5
		;;
		;;PL_PS	$0dffa,restore_msb_10
		;;PL_PS	$0e002,restore_msb_11
		;;PL_PS	$0e00a,restore_msb_12
		;;PL_PS	$0e012,restore_msb_13
		;;PL_PS	$0e01a,restore_msb_14		
		PL_END
		
fix_d6_1
	; re-add bits 30 and 31
	or.l	expmem_mask(pc),d6
	; original code
	MOVE.B	(A0)+,D6		;0de3c: 1c18
	MOVEA.L	D6,A1			;0de3e: 2246
	OR.B	(A1),D0			;0de40: 8011
	rts

fix_d6_2
	; re-add bits 30 and 31
	or.l	expmem_mask(pc),d6
	; original code
	MOVE.B	(A0)+,D6		;0df06: 1c18
	MOVEA.L	D6,A1			;0df08: 2246
	MOVE.B	(A1),D0			;0df0a: 1011
	rts


fix_a1
	move.l	d1,-(a7)
	move.l	a1,d1
	or.l	expmem_mask(pc),d1
	move.l	d1,a1
	move.l	(a7)+,d1
	rts
fix_a1_and_a5
	move.l	d1,-(a7)
	move.l	a1,d1
	or.l	expmem_mask(pc),d1
	move.l	d1,a1
	move.l	a5,d1
	or.l	expmem_mask(pc),d1
	move.l	d1,a5
	move.l	(a7)+,d1
	rts
	
restore_msb_1
	bsr.b	fix_a1
	
	OR.B	(A1),D0			;0df86: 8011
	MOVE.B	D0,-8000(A6)		;0df88: 1d40e0c0
	rts

restore_msb_2
	bsr.b	fix_a1
	OR.B	(A1),D2			;0dfa0: 8411
	MOVE.B	D2,8000(A6)		;0dfa2: 1d421f40
	rts
restore_msb_3
	bsr.b	fix_a1
	OR.B	(A1),D3			;0dfae: 8611
	MOVE.B	D3,16000(A6)		;0dfb0: 1d433e80
	rts

restore_msb_4	
	bsr.b	fix_a1
	OR.B	(A1),D4			;0dfbc: 8811
	MOVE.B	D4,24000(A6)		;0dfbe: 1d445dc0
	rts
	
restore_msb_5
	bsr.b	fix_a1_and_a5	; also fix A5
	OR.B	(A1),D5			;0dfca: 8a11
	MOVE.B	D5,32000(A6)		;0dfcc: 1d457d00
	rts
	

restore_msb_10
	bsr.b	fix_a1
	MOVEA.L	D6,A1			;0dffa: 2246
	MOVE.B	256(A1),D1		;0dffc: 12290100
	rts
restore_msb_11
	bsr.b	fix_a1
	MOVEA.L	D6,A1			;0e002: 2246
	MOVE.B	256(A1),D2		;0e004: 14290100
	rts
restore_msb_12
	bsr.b	fix_a1
	MOVEA.L	D6,A1			;0e00a: 2246
	MOVE.B	256(A1),D3		;0e00c: 16290100
	rts
restore_msb_13
	bsr.b	fix_a1
	MOVEA.L	D6,A1			;0e012: 2246
	MOVE.B	256(A1),D4		;0e014: 18290100
	rts
restore_msb_14
	bsr.b	fix_a1
	MOVEA.L	D6,A1			;0e01a: 2246
	MOVE.B	256(A1),D5		;0e01c: 1a290100
	rts
	
get_masked_base_address
	move.l	a0,-(a7)
	move.l	game_address(pc),a0
	move.l	(a0),d3
	and.l	#$3FFFFFFF,d3	; remove bits 30 and 31 as they're flags
	move.l	(a7)+,a0
	rts
	
	
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
	

_quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
_kbint
	cmp.b	_keyexit(pc),d0
	beq.b	_quit
	MOVE.B	D0,D1			;01470: 1200
	BCLR	#7,D1			;01472: 08810007
	rts
	
_blit3:
	bsr	_waitblit
	add.l	A3,A4
	move.l	A4,($50,A5)
	rts


_avoid_af:
	move.l	D1,-(A7)
	cmp.l	#$80000,A2
	bcs.b	.ok	; in chipmem
	move.l	_expmem(pc),D1
	cmp.l	D1,A2	; below expansion mem
	bcs.b	.pb
	add.l	#$80000,D1
	cmp.l	D1,A2	; above expansion mem
	bcc.b	.pb
.ok:
	move.w	(A2),D0
.end:
	and.w	#$3F00,D0
	move.l	(A7)+,D1
	rts
.pb:
	move.w	#-1,D0
	bra.b	.end


_blit1:
	bsr	_waitblit

	move.w	D6,($58,A5)
	rts

_blit2:
	bsr	_waitblit
	
	move.l	A0,($54,A5)
	move.l	A0,($50,A5)
	rts

_blit4:
	bsr	_waitblit
	
	move.l	A0,($54,A5)
	move.l	A0,($48,A5)
	rts

_waitblit
	BTST	#6,dmaconr+$DFF000
.wait
	BNE.S	.wait
.end
	rts

_readfile:
	cmp.w	#1,d0
	beq.b	_savefile
	tst.w	D0
	bne.b	.exit
	movem.l	d1/a0-a2,-(A7)
	addq.l	#4,A0			; skips 'DFx:'
	move.l	_resload(pc),a2
	JSR	(resload_LoadFile,a2)
	movem.l	(A7)+,d1/a0-a2
.exit
	moveq	#0,D0
	rts

_savefile:
	movem.l	d1/a0-a2,-(A7)
	addq.l	#4,A0			; skips 'DFx:'
	move.l	d1,d0			; size
	move.l	_resload(pc),a2
	JSR	(resload_SaveFile,a2)
	movem.l	(A7)+,d1/a0-a2
.exit
	moveq	#0,D0
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

_cacheflush:
	move.l	A2,-(A7)
	move.l	(_resload,pc),a2
	jsr	(resload_FlushCache,a2)
	move.l	(A7)+,A2
	rts
game_address
	dc.l	0
expmem_mask
	dc.l	0
_exename:
	dc.b	"hulk",0

