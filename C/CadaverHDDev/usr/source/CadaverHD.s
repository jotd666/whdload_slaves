; Cadaver slave by JOTD
;
; history:
; - v2.1: TAB key toggles infinite energy if CUSTOM5=1
; - v2.0: supports v1.03-1/2, v0.01, original and payoff
; - v1.x: JST versions.
; - v0.x: floppy patch for v0.01

; version description:
; - v1.03-1: V1.03 1992,PAL without copy protection (still original)
; - v1.03-2: V1.03 1992,PAL with copylock copy protection and stackframe error
; - v0.01  : V0.01 1990     with copylock and stackframe error

; Assembled with Barfly

	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	whdload.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	Cadaver.slave


	ENDC
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.4"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem|WHDLF_EmulLineF
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_DontCache
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
		dc.l	$0			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config

_name		dc.b	"Cadaver & The Payoff",0
_copy		dc.b	"1990-1992 The Bitmap Brothers",0
_info		dc.b	"installed & fixed by JOTD",10,10
		dc.b	"Set CUSTOM2=1 to enable Payoff levels",10,10
		dc.b	"Set CUSTOM4=1 for free savegames",10,10
		dc.b	"Set CUSTOM5=1 for in-game keys:",10
		dc.b    "F3 = enable energy trainer",10
		dc.b	"F4 = disable energy trainer",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_config:
		dc.b    "C2:L:Level set:Original Game,The Payoff;"
		dc.b    "C4:X:Trainer - free savegames:0;"			
		dc.b    "C5:X:Trainer - in game keys:0;"			
		dc.b	0

		dc.b	"$","VER: slave "
	DECL_VERSION

		even

_start	
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	;enable cache
	move.l	#WCPUF_Base_NCS|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	;get tags
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;check & compute version

	bsr	_check_version

	;change savename

	move.l	_custom2(pc),D0
	beq.b	.skip
	lea	_savever(pc),A0
	move.b	#'p',(A0)		; payoff saves
.skip

	lea	$7FF00,A7

	MOVE.W	#$0100,$00DFF096
	MOVE.W	#$0000,$00DFF180
	CLR.B	$1C.W
	clr.l	$80.W

; if expansion memory
;	MOVE.B	#$02,$0000001C
;	MOVE.L	_expmem(pc),$80.W

	move.l	#$21000,D0
	MOVE.L	D0,A5
	MOVE.L	D0,$84.W

	move.l	D0,A0		; buffer
	moveq.l	#1,D2		; disk 1
	MOVE.L	#$0600,D0	; offset
	MOVE.L	#$0A00,d1	; length
	move.l	_resload(pc),A2
	jsr	resload_DiskLoad(a2)

	lea	_pl_boot_v103(pc),A0
	move.l	_version(pc),D0
	cmp.l	#3,D0
	bne.b	.patch
	lea	_pl_boot_v001(pc),A0
.patch
	move.l	A5,A1
	jsr	(resload_Patch,A2)
	
	jmp	(A5)

MONEY_TRAINER:MACRO
	move.l	_custom4(pc),d0
	beq.b	.skip\@
	move.l	#$4E714E71,\1
	move.b	#$60,\2
.skip\@
	ENDM

_jumper1_v103:
	lea	$84.W,A0

	movem.l	D0/D1/A0-A2,-(A7)

	move.l	A0,A1
	lea	_pl_jmp1_v103(pc),A0
	movem.l	_resload(pc),A2
	jsr	(resload_Patch,A2)

	movem.l	(A7)+,D0/D1/A0-A2

	jmp	(A0)

_jumper1_v001:
	lea	$84.W,A0
	movem.l	D0/D1/A0-A2,-(A7)
	move.l	A0,A1
	lea	_pl_jmp1_v001(pc),A0
	movem.l	_resload(pc),A2
	jsr	(resload_Patch,A2)

	movem.l	(A7)+,D0/D1/A0-A2

	jmp	(A0)

_diskload_1:
	moveq.l	#0,D0
	bsr	_robread
	cmp.l	#$B8,A0
	bne	.out

	; game just loaded (bitmap trick)

	movem.l	D0/D1/A0-A3,-(A7)

	move.l	_version(pc),D0

	cmp.w	#1,D0
	beq.b	.v103_1

	cmp.w	#2,D0
	beq.b	.v103_2

.v001:
	MONEY_TRAINER	$DC0A,$DBBA

	lea	_pl_jmp2_v001(pc),A0
	lea	$11686,A3
	bra.b	.common
.v103_2:
	MONEY_TRAINER	$DC06,$DBB6

	lea	_pl_jmp2_v103_2(pc),A0
	lea	$11682,A3
	bra.b	.common

.v103_1:
	MONEY_TRAINER	$DC64,$DC14

	lea	_pl_jmp2_v103_1(pc),A0
	lea	$116B6,A3

	; decrunch routine relocated
.common
	lea	_decrunch_data(pc),A1
	move.l	#368/4,D0
.copy
	move.l	(A3)+,(A1)+
	dbf	D0,.copy

	; patch

	sub.l	A1,A1
	movem.l	_resload(pc),A2
	jsr	(resload_Patch,A2)
	movem.l	(A7)+,D0/D1/A0-A3

.out
	tst.l	D0
	rts

_diskload_2:
	move.l	_custom2(pc),D0
	beq.b	.skip
	moveq.l	#1,D0		; will load on disk.3
.skip
	addq.l	#1,D0
	bsr	_robread

	; unpack routine at 11444 (v1.03_1)
	; packed data header: size + C66xxxxx
	rts


_check_version:
	lea	_version(pc),A3

	MOVE.L	_resload(PC),A2
	
	moveq.l	#1,D2		; disk 1
	move.l	#8,D1		; 8 bytes to read
	move.l	#$13A,D0	; offset $13A
	lea	-8(A7),A7
	move.l	A7,A0
	jsr	(resload_DiskLoad,a2)
	move.l	A7,A0
	cmp.l	#'V1.0',(A0)
	bne.b	.notv1
	cmp.l	#'3pal',4(A0)
	bne.b	.notv1

	; v1.03 detected, but there are at least 2 v1.03 around!!!

	moveq.l	#1,D2		; disk 1
	move.l	#2,D1		; 2 bytes to read
	move.l	#$2C0E,D0	; offset $2C0E
	move.l	A7,A0
	jsr	(resload_DiskLoad,a2)
	move.l	A7,A0
	cmp.w	#$EE4,(A0)
	bne.b	.v103_2
	move.l	#1,(A3)		; version 1, 1.03-1, I've lost it!
	bra.b	.exit
.v103_2	
	move.l	#2,(A3)		; version 1, 1.03-2
	bra.b	.exit
.notv1
	cmp.l	#'01  ',(A0)
	bne.b	.notv001	; unsupported right now
	
	move.l	#3,(A3)		; version 0.01
	bra.b	.exit

.notv001
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.exit
	lea	8(A7),A7
	rts

; *** gets the save/load number

_getsavenum:
	cmp.b	#1,D0
	bcs	.error
	cmp.b	#$A,D0
	bne	.notzero
	move.l	A0,-(sp)
	lea	_savenum(pc),A0
	move.b	#'0',(A0)
	move.l	(sp)+,A0
	rts
.notzero
	add.b	#'0',D0
	move.l	A0,-(sp)
	lea	_savenum(pc),A0
	move.b	D0,(A0)		; sets the correct filename
	move.l	(sp)+,A0
	sub.b	#'0',D0
	rts
.error
	move.b	#$C,D0		; to tell there's an error
	rts


; load first part

_loadgame_part1:
	movem.l	D0-D6/A0-A6,-(A7)
	move.l	#$4400,D0		; length
	move.l	#0,D1			; file offset
	bsr	_loadgame
	movem.l	(A7)+,D0-D6/A0-A6
	rts

; load second part

_loadgame_part2:
	movem.l	D0-D6/A0-A6,-(A7)
	move.l	#$9800,D0		; length
	move.l	#$4400,D1			; file offset
	bsr	_loadgame
	movem.l	(A7)+,D0-D6/A0-A6
	rts

; save first part

_savegame_part1:
	movem.l	D0-D6/A0-A6,-(A7)
	move.l	#$4400,D0		; length
	move.l	#0,D1			; file offset
	bsr	_savegame
	movem.l	(A7)+,D0-D6/A0-A6
	rts

; load second part

_savegame_part2:
	movem.l	D0-D6/A0-A6,-(A7)
	move.l	#$9800,D0		; length
	move.l	#$4400,D1			; file offset
	bsr	_savegame
	movem.l	(A7)+,D0-D6/A0-A6
	rts


; < A0: save data
; < D0: length
; < D1: offset

_savegame:
	move.l	A0,A1			; buffer
	lea	_savename(pc),A0	; name
	move.l	_resload(pc),A2
	jsr	resload_SaveFileOffset(a2)
	moveq.l	#0,D7		; always OK
	rts

; < A0: save data
; < D0: length
; < D1: offset

_loadgame:
	move.l	D0,D5
	move.l	D1,D6

	move.l	A0,A1			; buffer
	lea	_savename(pc),A0	; name
	move.l	_resload(pc),A2		; resident loader

	; first check if file is there

	movem.l	D1/A0-A1,-(a7)
	jsr	resload_GetFileSize(a2)
	movem.l	(A7)+,D1/A0-A1
	moveq.l	#-1,D7
	tst.l	D0
	beq.b	.out			; not there: error

	; file is there, load it

	move.l	D5,D0
	move.l	D6,D1
	jsr	resload_LoadFileOffset(a2)
	moveq.l	#0,D7
.out
	rts

_copylock:
	movem.l	(A7)+,D6-D7/A1/A3
	bsr	.cont

.cont
	eor.l	#$DC84624B,(A0)		; protection: access fault at jumping monsters

	; emulate the LINE-F by hand
	;
	; the copylock ended by an actual LINE-F, but
	; later it would trigger a kind of stackframe error because
	; the game thinks (because no stackframe on 68000) that
	; there is only 2 bytes to pop (the SR value), whereas there are 4
	; on 68020 and higher
        ;
	; another case where the protection fucks up the game...

	move.w	#$2700,-(A7)
	move.l	$2C.W,-(A7)
	rts

; ----------------------------------------------


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


_flushcache:
	move.l	A2,-(A7)
	move.l	(_resload,pc),a2
	jsr	(resload_FlushCache,a2)
	move.l	(A7)+,A2
	rts

_fix_access_fault_1:
	move.l	D1,-(A7)
	move.l	A0,D1
	and.l	#$7FFFF,D1
	move.l	D1,A0
	move.w	(A0),D0
	move.l	(a7)+,D1

	move.l	($AC,A5),A0
	rts

_fix_access_fault_2:
	lea	($EFA,A5),A1
	moveq.l	#0,D1
	move.l	A0,D2
	and.l	#$7FFFF,D2
	move.l	D2,A0
	rts

; happens in french mode, when reading a book sometimes
; in that case game goes out of chipmem bounds!
; that does not happen at the same place for english language

_fix_access_fault_3
.loop
	cmp.l	#$7FFFF,a1
	bcc.b	.out
	move.b	(a0)+,(a1)+
	dbf	D0,.loop
.out
	rts

KBINT_MACRO:MACRO
_kbint_v\1:
	tst.b	d0
	beq.b	.orig
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit

	; quit with quit key (useful if NOVBRMOVE is set or if 68000)

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	cmp.b	#$52,d0
	beq.b	.ok
	cmp.b	#$53,d0
	bne.b	.nok
.ok
	move.l	d1,-(A7)
	move.l	_custom5(pc),d1
	beq.b	.skip
	; toggle infinite energy

	cmp.b	#$52,d0
	beq.b	.infinite
	move.l	#$3B410496,\2	; original code: MOVE.W D1,($496,A5)
	bra.b	.flush
.infinite
	move.l	#$4E714E71,\2	; NOPNOP
.flush
	bsr	_flushcache
.skip
	move.l	(A7)+,d1
	; save current key value
.nok
.orig
	btst	#0,($d00,a0)	; stolen code
	rts
	ENDM

	KBINT_MACRO	001,$10872,$1EB90
	KBINT_MACRO	103_v1,$108CC,$1E594
	KBINT_MACRO	103_v2,$1086E,$1EB2A

;	eor.l	#$75304AE7,$10872	; NOPNOP ^ MOVE.W D1,($496,A5)


; ----------------------------------------------

; to patch bootblock

_pl_boot_v103:
		PL_START
		PL_P	$54,_jumper1_v103
		PL_P	$60,_diskload_1	; $4E56FFDC
		PL_END
_pl_boot_v001:
		PL_START
		PL_P	$54,_jumper1_v001
		PL_P	$5C,_diskload_1	; $4E56FFDC
		PL_END

; in order to load intro

_pl_jmp1_v103:
		PL_START
		PL_P	$98-$84,_diskload_1
		PL_END
_pl_jmp1_v001:
		PL_START
		PL_P	$94-$84,_diskload_1
		PL_END

; right after intro (main program)

_pl_jmp2_v103_1:
		PL_START
		PL_PS	$1482C,_kbint_v103_v1
		PL_P	$13B96,_diskload_2
		PL_P	$116B6,_decrunch_data
		PL_PS	$B444,_getsavenum	; 6700003C *0C000001

		PL_PS	$B34A,_savegame_part1
		PL_PS	$B388,_savegame_part2
		PL_PS	$B4D6,_loadgame_part1
		PL_PS	$B57C,_loadgame_part2

		PL_PS	$FA88,_fix_access_fault_1
		PL_PS	$FA9E,_fix_access_fault_2

		PL_PS	$112BE,_fix_access_fault_3
		
		;;PL_P	$11444,save_unpacked_file

		PL_END


	
; right after intro (main program)

_pl_jmp2_v103_2:
		PL_START
		PL_PS	$1473E,_kbint_v103_v2
		PL_P	$13B62,_diskload_2
		PL_P	$11682,_decrunch_data
		PL_PS	$B3FE,_getsavenum	; 6700003C *0C000001
	
		PL_P	$10ED6,_copylock

		PL_PS	$FA2A,_fix_access_fault_1
		PL_PS	$FA40,_fix_access_fault_2

		PL_PS	$B308,_savegame_part1
		PL_PS	$B342,_savegame_part2
		PL_PS	$B484,_loadgame_part1
		PL_PS	$B51E,_loadgame_part2

		PL_PS	$1128A,_fix_access_fault_3
		PL_END

_pl_jmp2_v001:
		PL_START
		PL_PS	$147C8,_kbint_v001
		PL_P	$13B62,_diskload_2
		PL_P	$11686,_decrunch_data
		PL_PS	$B400,_getsavenum	; 6700003C *0C000001

		PL_P	$10EDA,_copylock

		PL_PS	$FA2E,_fix_access_fault_1
		PL_PS	$FA44,_fix_access_fault_2

		PL_PS	$B30A,_savegame_part1
		PL_PS	$B344,_savegame_part2
		PL_PS	$B486,_loadgame_part1
		PL_PS	$B520,_loadgame_part2

		PL_PS	$1128E,_fix_access_fault_3

		PL_END


; ----------------------------------------------------------------------

_decrunch_data:
	ds.b	$200,0
_savename:
	dc.b	"saves/savegame_"
_savever:
	dc.b	"o."		; o for original, p for payoff
_savenum:
	dc.b	"0",0
	even

_tag		dc.l	WHDLTAG_CUSTOM2_GET
_custom2	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_custom5	dc.l	0
		dc.l	WHDLTAG_CUSTOM4_GET
_custom4	dc.l	0
		dc.l	0

_resload:
	dc.l	0
_version:
	dc.l	0


; ----------------------------------------------------------------------
; code below is not used in slave release

	IFD	XXXXXXX	
	; I believe I had added this to be able to rip data. Now it causes an issue
	; when the file number is too high. It also writes unnecessary files to disk
	; commenting it out just in case I need it again

save_unpacked_file
	move.l	a5,-(a7)
	lea	.sd(pc),a4
	move.l	a1,(a4)+
	move.l	d0,(a4)+

	move.l	a3,a4	; packed data
	move.l	a1,$11A26	; output address?
	move.l	D0,$11A2A	; unpacked length
	jsr	$1145C
	move.l	(a7)+,a5

	movem.l	d0-a6,-(a7)
	move.l	_resload(pc),a2
	lea	.savecount(pc),a0
	addq.b	#1,(a0)
	lea	.savename(pc),a0
	move.l	.sd(pc),a1
	move.l	.sd+4(pc),d0
	jsr	resload_SaveFile(a2)
	movem.l	(a7)+,d0-a6
	rts

.sd	
	dc.l	0,0
.savename
	dc.b	"cadrip_"
.savecount
	
	dc.b	"0.bin",0
	even
	; code used to break the copylock
	; !!!!!! to use: set NOCACHE tooltype
	
_copylock_debug:
	bsr	_install_newtrace

	movem.l	(A7)+,D6-D7/A1/A3
	jsr	(A2)
	rts


_install_newtrace:
	mc68020
	movec	VBR,A1
	mc68000
	lea	_old_whd_trace(pc),A3
	move.l	$24(A1),(A3)
	lea	_newtrace_checkpc(pc),A3
	move.l	A3,$24(A1)

	lea	_old_whd_illegal(pc),A3
	move.l	$24(A1),(A3)
	lea	_newillegal(pc),A3
	move.l	A3,$10(A1)

	bsr	_flushcache
	rts

_newtrace_checkpc:
	move.l	D0,$4.W
	move.l	2(A7),D0
;;	cmp.l	#$28C8C,D0	; end
	cmp.l	#$28BB8,D0	; EOR (A6)
	bne.b	.out
	dc.w	$AAAA	; line-A
.out:
	move.l	$4.W,D0
_newtrace:
	move.l	$24.W,-(A7)
	rts


_newillegal:
	; works only once

	move.l	A1,-(A7)
	mc68020
	movec	VBR,A1
	mc68000
	move.l	_old_whd_illegal(pc),$10(A1)	; restore old whd value
	move.l	(A7)+,A1
	bsr	_flushcache
	move.l	$10.W,-(A7)
	rts
		
_old_whd_trace:
	dc.l	0
_old_whd_illegal:
	dc.l	0
	ENDC
