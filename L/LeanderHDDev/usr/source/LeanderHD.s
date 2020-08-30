;*---------------------------------------------------------------------------
;  :Program.	LeanderHD.asm
;  :Contents.	Slave for "Leander" from Psygnosis
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
	OUTPUT	Leander.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

USE_FASTMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000

VERSION_PAL = 1
VERSION_NTSC = 2

;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_EmulTrap|WHDLF_NoError|WHDLF_ClearMem
		IFD	USE_FASTMEM
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		ELSE
		dc.l	CHIPMEMSIZE+EXPMEMSIZE
		ENDC
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	dir-_base		;ws_CurrentDir
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
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
dir
	dc.b	"data",0
_config
	dc.b	"BW;"
        dc.b    "C1:X:Trainer Infinite Lives:0;"
        dc.b    "C2:X:Keep intro music skip option:0;"
        dc.b    "C3:X:Skip introduction:0;"
		dc.b	0
	even

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.5"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM


_name		dc.b	"Leander"
		dc.b	0
_copy		dc.b	"1991 Psygnosis & Traveller Tales",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

DO_JUMP:MACRO
	jmp	\1
	ENDM

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	lea	CHIPMEMSIZE-$100,a7

	bsr	detect_version

	moveq.l	#0,d0
	moveq.l	#0,d1
	moveq.l	#0,d2

	move.w	#$7FFF,$dff096
	move.w	#$7FFF,$dff09a
	move.w	#$7FFF,$dff09C

	MOVE.L	D0,$4.W		; extension base pointer
	MOVE.L	D1,$8.W		; memory extension size

	lea	boot(pc),A0
	lea	$400.W,A1
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)

	lea	pl_boot(pc),a0
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	
	DO_JUMP	$400.W


disk_routine:
	move.l	_resload(pc),a2

	cmp.b	#5,D1
	beq	dr_DirRead
	cmp.b	#0,D1
	beq	dr_FileRead

	cmp.b	#1,D1
	beq	dr_FileWrite

	moveq.l	#0,D0
	ILLEGAL
	bra	dr_End

	; load the file

dr_FileRead:
	moveq.l	#0,D0
	moveq.l	#-1,D1
	
	movem.l	a0-a1,-(a7)
	jsr	resload_LoadFileDecrunch(a2)
	movem.l	(a7)+,a0-a1

	bsr	wait_on_level

	move.l	D0,D1	; file length
	moveq.l	#0,D0
	bra	dr_End

; read directory

dr_DirRead:
	moveq.l	#0,D1
	moveq.l	#0,D0	

dr_End:
	MOVEM.L	(A7)+,D2-D7/A0-A6
	RTS

; *** other commands, still not supported

dr_Other:
	cmp.w	#1,D1
	beq	dr_FileWrite

	illegal

; write file (only score)
; D0 holds the length to write but we ignore it
; because we write only the scores

dr_FileWrite:
	; if something else than the scorefile is written, ignore it

	movem.l	a0,-(a7)
	lea	scorename(pc),a0
	bsr	get_long
	movem.l	(a7)+,a0

	cmp.l	#'SCOR',d0
	bne	.notscore

	move.l	trainer(pc),d0
	bne.b	.nowrite

	bsr	write_scores
.nowrite
	moveq.l	#0,D0
	move.l	#$C8,D1
	bra	dr_End

.notscore
	ILLEGAL
	moveq.l	#-1,D0
	moveq.l	#0,D1
	bra	dr_End

get_long
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	rts

wait_on_level
	movem.l	D0-D1/A0-A2,-(a7)
	move.l	buttonwait(pc),D0
	beq	.sk

	bsr	get_long
	; start of level
	cmp.l	#'LEVE',d0
	beq.b	.wb
	cmp.l	#'QUES',d0
	bne.b	.sk
	; wait 2 seconds when loading worlds
	move.l	#20,d0
	move.l 	_resload(pc),a2
	jsr	resload_Delay(a2)
	bsr	.release
	bra.b	.sk
.wb
	btst	#6,$bfe001
	beq	.sk
	btst	#7,$bfe001
	bne	.wb
	bsr	.release
.sk
	movem.l	(a7)+,D0-D1/A0-A2
	rts
	
.release
	btst	#6,$bfe001
	beq.b	.release
	btst	#7,$bfe001
	beq.b	.release
	rts
	
; < A1: buffer

write_scores:
	movem.l	d0-d1/a0-a2,-(a7)
	lea	scorename(pc),A0
	move.l	#$C8,D0
	move.l	_resload(pc),a2
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	rts

patch_loader_1:
	movem.l	d0-a6,-(a7)
	lea	pl_loader_1_pal(pc),a0
	move.l	version(pc),d0
	cmp.l	#VERSION_PAL,d0
	beq.b	.p
	lea	pl_loader_1_ntsc(pc),a0
.p
	move.l	_resload(pc),a2
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	DO_JUMP	$5AA0.W


patch_loader_2_pal:
	movem.l	d0-a6,-(a7)

	bsr	fix_game_blits

	lea	pl_loader_2_pal(pc),a0
	move.l	_resload(pc),a2
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	DO_JUMP	$609F8


patch_loader_2_ntsc:
	movem.l	d0-a6,-(a7)

	bsr	fix_game_blits

	lea	pl_loader_2_ntsc(pc),a0
	move.l	_resload(pc),a2
	sub.l	a1,a1
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-a6
	DO_JUMP	$609F8

kbint:
	move.b	#0,$C00(A0)	; stolen
	cmp.b	_keyexit(pc),D0
	beq	quit
	rts

fix_game_blits
	lea	wait_blit_a1a5(pc),a3
	lea	.blit_a1a5(pc),a2
	bsr	.fixit

	lea	wait_blit_d2d6_a4a6(pc),a3
	lea	.blit_a4a6(pc),a2
	bsr	.fixit

	lea	wait_blit_a0_50(pc),a3
	lea	.blit_a0_50(pc),a2
	bsr	.fixit

	lea	wait_blit_a1_50(pc),a3
	lea	.blit_a1_50(pc),a2
	bsr	.fixit
	rts

.fixit
	lea	$60000,a0
	lea	$7FF00,a1
	move.l	#6,d0
.loop
	bsr	hex_search
	cmp.l	#0,a0
	beq.b	.out
	move.w	#$4EB9,(a0)+
	move.l	a3,(a0)+
	bra.b	.loop
.out
	rts

.blit_a1a5
	dc.w	$6602,$3A89,$D1C5
.blit_a4a6
	dc.w	$2882,$3C86,$D7C1

.blit_a0_50
	dc.w	$23C8
	dc.l	$DFF050
.blit_a1_50
	dc.w	$23C9
	dc.l	$DFF050

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A0: address or 0 if not found

hex_search:
	movem.l	D1/D3/A1-A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A0,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	addq.l	#1,A0	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A0,A0
.exit:
	movem.l	(A7)+,D1/D3/A1-A2
	rts

scorename:
	dc.b	"SCORES",0
	even

_tag		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
buttonwait	dc.l	0
		dc.l	0

quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

detect_version
	lea	leander(pc),a0
	lea	$10000,a1
	jsr	resload_LoadFileDecrunch(a2)
	lea	$10000,a0
	jsr	resload_CRC16(a2)
	lea	version(pc),a0
	cmp.w	#$25a5,d0
	beq.b	.ntsc
	cmp.w	#$00af,d0
	beq.b	.pal
	bra	wrong_version
.pal
	move.l	#VERSION_PAL,(a0)
	rts
.ntsc
	move.l	#VERSION_NTSC,(a0)
	rts

wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
	
; sound stop is already done in $7106, but it doesn't set the flag
; "music" to false, so there are glitches because the DMA is set again
; by the music routine in the VBL

stop_dma_sound
	; tell music routine to stop (wasn't done in the game)
	clr.w	$6F46.W
	; now stop DMA
	movem.l	d0-d1/a6,-(a7)
	lea	_custom,a6
	move.w	#$F,(dmacon,a6)
	moveq.l	#0,d0
	;move.w	d0,(aud0+ac_len,a6)
	;move.w	d0,(aud2+ac_len,a6)
	;move.w	d0,(aud1+ac_len,a6)
	;move.w	d0,(aud3+ac_len,a6)
	move.w	d0,(aud0+ac_vol,a6)
	move.w	d0,(aud2+ac_vol,a6)
	move.w	d0,(aud1+ac_vol,a6)
	move.w	d0,(aud3+ac_vol,a6)
	movem.l	(a7)+,d0-d1/a6
	rts
	
second_button
	addq.l	#2,(a7)
	movem.l	d0,-(a7)
	move.w	$dff016,d0
	btst	#14,d0
	bne.b	.sk
	move.w	#$cc01,$dff034
	cmp.b	d0,d0	; clears Z flag
.sk
	movem.l	(a7)+,d0
	rts

wait_blit_a1_50
	bsr	wait_blit
	move.l	a1,($dff050)
	rts

wait_blit_a0_50
	bsr	wait_blit
	move.l	a0,($dff050)
	rts

wait_blit_d4_64
	bsr	wait_blit
	move.w	d4,($dff064)
	rts
wait_blit_d1_64
	bsr	wait_blit
	move.w	d1,($dff064)
	rts


BUILD_WAIT_BLIT_L:MACRO
wait_blit_\1_\2
	bsr	wait_blit
	move.l	#$\1,($dff0\2)
	addq.l	#4,(a7)
	rts
	ENDM

BUILD_WAIT_BLIT_W:MACRO
wait_blit_\1_\2
	bsr	wait_blit
	move.w	#$\1,($dff0\2)
	addq.l	#2,(a7)
	rts
	ENDM

	BUILD_WAIT_BLIT_W	0000,42
	BUILD_WAIT_BLIT_W	0000,64
	BUILD_WAIT_BLIT_W	01fe,64

	BUILD_WAIT_BLIT_W	fffe,64
	BUILD_WAIT_BLIT_W	0028,66

	BUILD_WAIT_BLIT_L	01fe0028,64
	BUILD_WAIT_BLIT_L	ffffffff,44

wait_blit_d2d6_a4a6:
	bsr	wait_blit
	move.l	d2,(a4)                        ;$00dff050
	move.w	d6,(a6)                        ;$00dff058
	adda.l	d1,a3
	rts

wait_blit_a1a5:
	bne.b	.skip
	bsr	wait_blit
	move.w	a1,(a5)                        ;$00dff056
.skip
	adda.l	d5,a0
	rts

wait_blit:
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts

	IFEQ	1
	TST.B	dmaconr+$DFF000
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	TST.B	$BFE001
	TST.B	$BFE001
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	TST.B	dmaconr+$DFF000
.end
	rts
	ENDC

jmp_36C
	;;bsr	stop_dma_sound
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	sub.l	a1,a1
	lea	pl_36c(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	DO_JUMP	$36C.W

music_pal
music_ntsc
	movem.l	d0-d1/a0-a2,-(a7)
	move.l	_resload(pc),a2
	sub.l	a1,a1
	lea	pl_music(pc),a0
	jsr	resload_Patch(a2)
	movem.l	(a7)+,d0-d1/a0-a2
	DO_JUMP	$7076.W

fix_int_level_6
	move.l	$78.w,($c,a5)	; stolen
	move.l	#$1D06C,$78.w	; stolen
	move.w	#$e000,$dff09a	; stolen, done after setting interrupt vector
	add.l	#$10,(a7)	; skip rest of code
	rts

fix_music_1
	move.w	d0,-(a7)
	clr.w	d0
	move.b	(3,a6),d0
	move.w	d0,(8,a5)
	move.w	(a7)+,d0
	rts

pl_music
	PL_START
	PL_PS	$7590,fix_music_1
	PL_END

PATCH_A1_DFF050:MACRO
	PL_PS	$\1,wait_blit_a1_50
	ENDM

PATCH_A0_DFF050:MACRO
	PL_PS	$\1,wait_blit_a0_50
	ENDM

PATCH_Z_BLTAMOD:MACRO
	PL_PS	$\1,wait_blit_0000_64
	ENDM

; intro

pl_36c
	PL_START
	PATCH_A1_DFF050	053A
	PATCH_A1_DFF050	055A
	PATCH_A1_DFF050	057A
	PATCH_A1_DFF050	060C
	PATCH_A1_DFF050	062C
	PATCH_A1_DFF050	064C
	PATCH_A1_DFF050	0BE0
	PATCH_A1_DFF050	0C00
	PATCH_A1_DFF050	0C20
	PATCH_A1_DFF050	0CFA
	PATCH_A1_DFF050	0D1A
	PATCH_A1_DFF050	0D3A
	PATCH_A1_DFF050	10DE
	PATCH_A1_DFF050	10FC
	PATCH_A1_DFF050	111A
	PATCH_Z_BLTAMOD	512
	PATCH_Z_BLTAMOD	5E4
	PATCH_Z_BLTAMOD	BB8
	PL_PS	$cd4,wait_blit_fffe_64
	PL_PS	$1638,wait_blit_0028_66
	PL_PS	$10AA,wait_blit_d4_64

	; interrupt bug: intena set before vector is set

	PL_PS	$1CC9A,fix_int_level_6
	PL_END

pl_boot
	PL_START
	PL_P	$66E,disk_routine
	PL_P	$500,patch_loader_1

	; remove PAL/NTSC region detection

	PL_NOP	$42C,2

	; remove cache handling

	PL_W	$44A,$6020

	PL_END
pl_loader_1_all
	PL_START
	; remove the "press fire now to skip intro music"
	PL_IFC2
	PL_ELSE
	PL_S	$5AC2,$F0-$C2
	PL_W	$6F6E,$4299	; clear dest instead of copy "PRESS FIRE ..." gfx text
	PL_ENDIF
	; skip introduction
	PL_IFC3
	PL_S	$5B0A,$CC-$0A
	PL_W	$6ABC,0		; don't start the intro music VBL handler at all
	PL_ENDIF

	; better dma sound stop
	PL_P	$7106,stop_dma_sound
	PL_END
pl_loader_1_pal
	PL_START

	; remove another disk routine

	PL_L	$7778,$60000204

	; patch the disk routine

	PL_P	$5CC0,disk_routine	

	; set up the new patch
	; at 2 locations

	PL_P	$5C1E,patch_loader_2_pal
	PL_P	$5BE8,patch_loader_2_pal

	; patch music

	PL_PS	$6AC2,music_pal
	PL_NEXT	pl_loader_1_all

pl_loader_1_ntsc
	PL_START

	; remove another disk routine

	PL_L	$777A,$60000204

	; patch the disk routine

	PL_P	$5CC0,disk_routine	

	; set up the new patch
	; at 2 locations

	PL_P	$5C1E,patch_loader_2_ntsc
	PL_P	$5BE8,patch_loader_2_ntsc

	; patch music

	PL_PS	$6AC2,music_ntsc

	PL_NEXT	pl_loader_1_all


pl_loader_2_pal
	PL_START
	; remove the "press fire now to skip intro music"
;	PL_IFC2
;	PL_ELSE
;	PL_S	$5AC2,$F0-$C2
;	PL_ENDIF
	PL_IFC1
	; lose one life
	PL_L	$6BE58,$4E714E71
	PL_L	$6BE5C,$4E714E71
	; suicide life subber
	PL_S	$7DD32,$3E-$32
	PL_ENDIF
	
	; remove another disk routine (probably protection, but not very good since I removed it without noticing...)
	PL_L	$7121A,$60000216

	; patch the disk routine

	PL_P	$704EC,disk_routine	

	; install the quit key

	PL_PS	$7FEA0,kbint

	; remove force PAL mode (not present in NTSC version)

	PL_W	$650B0,$6006

	; install trap for intro sequence

	PL_PS	$7FC74,jmp_36C
	PL_NOP	$7FC7A,6

	; sound snoop fix (byte write)

	PL_P	$63d5c,fix_music_1

	; blitter waits (other than the ones auto-replaced by hex_search)

	PATCH_Z_BLTAMOD	7E240
	PL_PS	$66e60,wait_blit_01fe_64
	PL_PS	$67038,wait_blit_01fe0028_64

	PATCH_Z_BLTAMOD	72b42
	PL_PS	$726ac,wait_blit_fffe_64
	PL_PS	$72aaa,wait_blit_fffe_64
	PL_PS	$72cd4,wait_blit_d1_64
	PL_PS	$72e94,wait_blit_d1_64

	PL_PS	$7b3b8,wait_blit_ffffffff_44
	PL_PS	$6af82,wait_blit_ffffffff_44

	PL_PS	$7d7fc,wait_blit_0000_42

	PL_END

pl_loader_2_ntsc
	PL_START
	; remove the "press fire now to skip intro music"
;	PL_IFC2
;	PL_ELSE
;	PL_S	$5AC2,$F0-$C2
;	PL_ENDIF
	PL_IFC1
	PL_L	$6BDC6,$4E714E71
	PL_L	$6BDCA,$4E714E71
	; another smart life subber
	PL_S	$7DAD8,$E4-$D8
	PL_ENDIF
	
	; remove another disk routine (protection)

	PL_L	$711B4,$60000216

	; patch the disk routine

	PL_P	$70486,disk_routine	

	; install the quit key

	PL_PS	$7FC84,kbint

	; second button patch

;	PL_PS	$7EC00,second_button
;	PL_S	$7FA44,8		; skip potgo reset

	; install trap for intro sequence

	PL_PS	$7FA58,jmp_36C
	PL_L	$7FA58+6,$4E714E71
	PL_W	$7FA58+10,$4E71

	; sound snoop fix (byte write)

	PL_P	$63d5c,fix_music_1

	; blitter waits (other than the ones auto-replaced by hex_search)

	PATCH_Z_BLTAMOD	7dff8
	PL_PS	$66e5a,wait_blit_01fe_64
	PL_PS	$67032,wait_blit_01fe0028_64

	PATCH_Z_BLTAMOD	72adc
	PL_PS	$72646,wait_blit_fffe_64
	PL_PS	$72a44,wait_blit_fffe_64
	PL_PS	$72C6E,wait_blit_d1_64
	PL_PS	$72E2E,wait_blit_d1_64

	PL_PS	$7b15c,wait_blit_ffffffff_44
	PL_PS	$6af88,wait_blit_ffffffff_44

	PL_PS	$7D5A2,wait_blit_0000_42

	PL_END


_resload
	dc.l	0

version
	dc.l	0

boot:
	incbin	"chip.rnc"
leander
	dc.b	"LEANDER",0
	even
