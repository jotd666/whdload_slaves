
	; WHDLoad slave for Uridium 2
	; (c) 1997-2001 Halibut Software
	; reworked (a lot) by JOTD
	; (a lot of source files were missing, specially the multi-version
	; patchlist system, which can easily be replaced by a manual version system
	; and reduce useless dependencies
	
	INCDIR	INCLUDE:
	INCLUDE	graphics/gfxbase.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i


CHIPMEMSIZE = $100000
FASTMEMSIZE = 0

RAWKEY_F9 = $58
RAWKEY_F10 = $59
RAWKEY_1 = 1
RAWKEY_2 = 2
RAWKEY_3 = 3
RAWKEY_4 = 4
RAWKEY_5 = 5
RAWKEY_6 = 6

base_whdflags = WHDLF_ClearMem|WHDLF_NoError|WHDLF_EmulTrap|WHDLF_EmulTrapV

	IFD	AGA
whdflags = base_whdflags|WHDLF_ReqAGA
	ELSE
whdflags = base_whdflags
	ENDC
	
;==========================================================================

	;WHDLoad slave header structure

_base:	SLAVE_HEADER		;ws_Security + ws_ID
	dc.w	17	;ws_Version
	dc.w	whdflags	;ws_flags
	dc.l	CHIPMEMSIZE	;ws_BaseMemSize
	dc.l	0	;ws_ExecInstall
	dc.w	_start-_base	;ws_GameLoader
	dc.w	_cwdname-_base	;ws_CurrentDir
	dc.w	0
_keydebug:	dc.b	RAWKEY_F9	;ws_keydebug
_keyexit:	dc.b	RAWKEY_F10	;wa_keyexit
_expmem:	dc.l	FASTMEMSIZE	;ws_ExpMem
	dc.w	_wsname-_base	;ws_name
	dc.w	_wscopy-_base	;ws_copy
	dc.w	_wsinfo-_base	;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
    dc.w    _config-_base
;---
_config
	dc.b    "BW;"
	dc.b	0

_cwdname:	dc.b	"data",0
_wsname:	dc.b	"Uridium 2",0
_wscopy:	dc.b	"1993 Graftgold",0
_wsinfo:	dc.b	10,"adapted by Girv & JOTD",10
	dc.b	10,0
	EVEN
;==========================================================================


;==========================================================================

INTRO_MEM:	equ	$20000

;==========================================================================

_start:
	bsr	_initialise
	
	bsr	check_version

	move.l	#$400,d0	; load intro
	move.l	#$e00,d1
	moveq	#1,d2
	lea	INTRO_MEM,a0
	move.l	a0,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)
	
	lea	.p0_patchlist(pc),a0	; patch intro
	move.l	(a7),a1
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)

	move.l	(a7),a1
	move.w	_ct_attn+2(pc),$68+2(a1)	; set intro AttnFlags value

	move.l	_ct_chiprev(pc),d0	; set intro AGA flag
	and.l	#GFXF_AA_LISA|GFXF_AA_ALICE,d0
	sne	d0
	move.b	d0,$72+1(a1)

	rts		; start intro

;-----

.p0_patchlist:
	PL_START
	PL_P	$118,_intro_trackloader	; patch trackloader
	PL_P	$404,kill_copylock

	PL_L	$46,$70004e71	; patch fastmem check
	PL_L	$68,$3afc0000	; patch AttnFlags set
	PL_L	$72,$70004e71	; patch AGA check
	
	PL_NOP	$a6,6	; remove TRAP#0 switch-to-supervisor

	PL_W	$c2,$10c4	; fix dodgy jmp
	PL_PS	$d8,_butwait1	; add title picture display delay
	PL_P	$f0,_p1	; patch game exec jump
	PL_END

kill_copylock
	move.l #$0d180cd9,d5
	move.l d5,$f4.w
	rts
	
;--------------------------------

_p1:	move.w	$22(a5),d0
	sub.w	$20(a5),d0
	beq.s	.p1_gameloaded	; game loaded?

	lea	$1000.w,a5	; continue with intro
	lea	$4404(a5),a0
	jsr	(a0)

.p1_gameloaded:
	move.l	_p1_patchlist(pc),a0	; patch game
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	
	move.l	_setvars_call(pc),a0
	jsr		(a0)
	rts		; start game


;--------------------------------

_intro_trackloader:
	; Intro trackloader patch
	; d3=start sector, d5=num sectors, a3=dest

	movem.l	d0-7/a0-6,-(a7)

	mulu	#512,d3	;d0=offset
	move.l	d3,d0
	mulu	#512,d5	;d1=length
	move.l	d5,d1
	moveq	#1,d2	;d2=disk number
	move.l	a3,a0	;a0=dest

	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)
	
	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------------------

	; main game chipmem-detection routine

_game_chipmem:
	move.l	#CHIPMEMSIZE,d0
	rts

;--------------------------------

_game_disknum:
	dc.w	1

_game_trackloader:
	; Main game trackloader patch
	; d3=side 0/1, d4=cyl 0-39, d5=sec 1-11, d6=num sectors, a2=dest

	movem.l	d1-7/a0-6,-(a7)

	;Load requested data
	mulu	#$1600,d3	;d3=side offset
	mulu	#$2c00,d4	;d4=track offset
	subq.w	#1,d5	;d5=sector offset
	mulu	#512,d5
	add.l	d3,d5
	add.l	d4,d5
	move.l	d5,d0	;d0=offset

	mulu	#512,d6	;d1=length
	move.l	d6,d1

	move.w	_game_disknum(pc),d2	;d2=disk number

	move.l	a2,a0	;a0=dest

	movem.l	d1/a0,-(a7)
	move.l	_resload(pc),a2	;Do the load
	jsr	resload_DiskLoad(a2)

	move.l	_p1_patchlist(pc),a0	; re-apply patches to game code
	sub.l	a1,a1
	jsr		resload_Patch(a2)
	movem.l	(a7)+,d1/a0

	; search data just loaded for routines to patch
	; a0=start, d1=length

	lea	-8(a0,d1.l),a2	;a2=search area end
	moveq	#8,d0	;d0=no. of search bytes

	; "insert disk 2" patch
	lea	_vd_insdisk2_s1(pc),a1
	lea	.dodisk2pch(pc),a3
	bsr.s	_apply_dynamic_patch

	; anti manual protection patch
	lea	_vd_manprot_s1(pc),a1
	lea	.domanpch(pc),a3
	bsr.s	_apply_dynamic_patch

	movem.l	(a7)+,d1-7/a0-6	; all done
	moveq	#0,d0
	rts

;-----

.dodisk2pch:	move.w	#$601e,(a0)
	patch	$20(a0),.setdisk2
	rts

.setdisk2:	move.l	a0,-(a7)	; switch to loading from Disk 2
	lea	_game_disknum(pc),a0
	move.w	#2,(a0)
	sf	$3a57
	move.l	(a7)+,a0
	rts

;-----

.domanpch:	move.l	#$4e714e71,(a0)
	rts

;--------------------------------

_apply_dynamic_patch:	
	;Search for an 8 byte sequence and call patching
	;function with the address of the sequence.
	;Entry:	a0=search area start
	;	a1=byte sequence start
	;	a2=search area end
	;	a3=patch function
	;	d0=byte sequence length
	;
	;Patch routine called with a0=where sequence found

	movem.l	d0-7/a0-6,-(a7)
	subq.l	#1,d0

.adp_search:	movem.l	d0/a0-1,-(a7)	; save counter and pointers
.adp_loop:	cmp.b	(a0)+,(a1)+
	dbne	d0,.adp_loop
	bne.s	 .adp_next

	movem.l	(a7)+,d0/a0-1	; apply patch
	jsr	(a3)
	bra.s	.adp_done

.adp_next:	movem.l	(a7)+,d0/a0-1	; reset counter and pointers
	addq.l	#1,a0	; move on in memory
	cmp.l	a2,a0	; loop back if not done yet
	blt.s	.adp_search

.adp_done:	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------------------

_game_tracksaver:
	; Main game tracksaver patch
	; d3=side 0/1, d4=cyl 0-39, d5=sec 1-11, d6=num sectors (track multiple?)
	; a2=source

	movem.l	d1-7/a0-6,-(a7)

	move.w	_game_disknum(pc),d0	;d0=disk number
	cmp.w	#2,d0	;Only saves to disk 2
	bne.s	.gts_done

	mulu	#512,d6	;d0=length
	move.l	d6,d0

	mulu	#$1600,d3	;d3=side offset
	mulu	#$2c00,d4	;d4=track offset
	subq.w	#1,d5	;d5=sector offset
	mulu	#512,d5
	add.l	d3,d5
	add.l	d4,d5
	move.l	d5,d1	;d1=offset

	lea	.gts_name(pc),a0	;a0=filename

	move.l	a2,a1	;a1=source

	move.l	_resload(pc),a2	;Save the data
	jsr	resload_SaveFileOffset(a2)

.gts_done:	movem.l	(a7)+,d1-7/a0-6
	moveq	#0,d0
	rts

.gts_name:	dc.b	"Disk.2",0
	EVEN

;--------------------------------

	; game keyboard handler patch
	; called from game's own keyboard routine with d0=rawkeycode

_game_keyboard:
	movem.l	d0-d1/a1,-(a7)

	; check for trainer keys

	cmp.b	#RAWKEY_1+$80,d0	; 1=activate "land now"
	bne.s	.not_tr_landnow

	move.l	_vd_tr_landnow(pc),a1
	clr.w	(a1)
	bra.s	.kbd_done

.not_tr_landnow:
	cmp.b	#RAWKEY_2+$80,d0	; 2=refill lives
	bne.s	.not_tr_refilllives

	move.l	_vd_tr_p1lives(pc),a1
	move.w	#5,(a1)
	move.l	_vd_tr_p2lives(pc),a1
	move.w	#5,(a1)
	bra.s	.kbd_done

.not_tr_refilllives:
	cmp.b	#RAWKEY_3+$80,d0	; 2/3/4/5=weapon select
	beq.s	.is_tr_p1wepdown
	cmp.b	#RAWKEY_4+$80,d0
	beq.s	.is_tr_p1wepup
	cmp.b	#RAWKEY_5+$80,d0
	beq.s	.is_tr_p2wepdown
	cmp.b	#RAWKEY_6+$80,d0
	bne.s	.not_tr_weaponselect

.is_tr_p2wepup:
	move.l	_vd_tr_p2weapon(pc),a1
	moveq	#8,d1
	bra.s	.trws_select_weapon

.is_tr_p2wepdown:
	move.l	_vd_tr_p2weapon(pc),a1
	moveq	#-8,d1
	bra.s	.trws_select_weapon

.is_tr_p1wepup:
	move.l	_vd_tr_p1weapon(pc),a1
	moveq	#8,d1
	bra.s	.trws_select_weapon

.is_tr_p1wepdown:
	move.l	_vd_tr_p1weapon(pc),a1
	moveq	#-8,d1

.trws_select_weapon:
	add.w	(a1),d1	;d1=new weapon number
	blt.s	.kbd_done
	cmp.w	#11*8,d1
	bgt.s	.kbd_done
	move.w	d1,(a1)
	bra.s	.kbd_done

.not_tr_weaponselect:

	; check for control keys

	move.b	_keydebug(pc),d1	;debug key?
	or.b	#$80,d1
	cmp.b	d0,d1
	beq	_debug

	move.b	_keyexit(pc),d1	;exit key?
	or.b	#$80,d1
	cmp.b	d0,d1
	beq	_exit

.kbd_done:	movem.l	(a7)+,d0-d1/a1	;Return to original routine

	move.l	_vd_game_keycode(pc),a2
	move.b	d0,(a2)
	rts

;--------------------------------

_butwait1:	; display loading picture and optionally wait for button press

	lea	$4400(a5),a0	;Display picture
	jsr	(a0)

	bsr	_butwait
	rts

;----------

_butwait2:	; run loading copper display and optionally wait for button press

	bsr	_butwait
	move.l	_vd_game_butwait2b(pc),-(a7)
	rts

;----------

_butwait:	movem.l	d0-7/a0-6,-(a7)
	move.l	_ct_butwait(pc),d0
	beq.s	.bw_nobw

	lea	_custom,a0
	waitbutton	a0
	bra.s	.bw_done

.bw_nobw:	moveq	#20,d0
	move.l	_resload(pc),a2
	jsr	resload_Delay(a2)

.bw_done:	movem.l	(a7)+,d0-7/a0-6
	rts


;--------------------------------
;--------------------------------

_initialise:	movem.l	d0-7/a0-6,-(a7)

	lea	_resload(pc),a1	; save resloader address
	move.l	a0,(a1)

	lea	_ctl_tags(pc),a0	; get config tags
	move.l	_resload(pc),a2
	jsr	resload_Control(a2)


	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------------------

_badver:	and.l	#$ffff,d0
	pea	0.l
	pea	0.l
	pea	TDREASON_WRONGVER.l
	bra.s	_abort

_debug:	pea	0.l
	pea	0.l
	pea	TDREASON_DEBUG.l
	bra.s	_abort

_exit:       pea	TDREASON_OK.l
	

_abort:      move.l	_resload(pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

; Girv forgot to provide parts of the code / includes
; resourced version shows that a CRC16 is computed on a block of 
; the first disk

VD_DISK_OFS:	equ	$21ca0
VD_DISK_LEN:	equ	$2c00
VD_DISK_BUF:	equ	$10000

check_version:
	MOVE.L	#VD_DISK_OFS,D0		;440: 203c00021ca0
	MOVE.L	#VD_DISK_LEN,D1		;446: 223c00002c00
	MOVEQ	#1,D2			;44c: 7401
	LEA	VD_DISK_BUF,A0		;44e: 41f900010000
	MOVEA.L	_resload(PC),A2		;454: 247a0192
	MOVEM.L	D1/A0/A2,-(A7)		;458: 48e740a0
	JSR	resload_DiskLoad(A2)			;45c: 4eaa0028
	MOVEM.L	(A7)+,D0/A0/A2		;460: 4cdf0501
	JSR	resload_CRC16(A2)			;464: 4eaa0030
	lea		_p1_patchlist(pc),a0
	lea		_setvars_call(pc),a3
	cmp.w	#$f8a1,d0
	beq.b	version_1
	cmp.w	#$0cea,d0
	beq.b	version_2
	bra.b	_badver
	
version_1
	lea	_p1_patchlist_version_1(pc),a1
	move.l	a1,(a0)
	lea	_setvars_version_1(pc),a1
	move.l	a1,(a3)
	rts
version_2
	lea	_p1_patchlist_version_2(pc),a1
	move.l	a1,(a0)
	lea	_setvars_version_2(pc),a1
	move.l	a1,(a3)
	rts
	
;--------------------------------

	; version dependencies


;-----

 
;_vd_game_chipmem:	dc.l 0	; game chipmem detection
;_vd_game_diskaccess1:	dc.l 0	; left over floppy access code
;_vd_game_diskaccess2:	dc.l 0
;_vd_game_diskaccess3:	dc.l 0
;_vd_game_tkloader:	dc.l 0	; game trackloader (-4814c for actual address)
;_vd_game_tksaver:	dc.l 0	; game tracksaver
;_vd_game_keyboard:	dc.l 0	; keyboard
_vd_game_keycode:	dc.l 0	; rawkeycode store
;_vd_game_butwait2a:	dc.l 0	; copper loader button wait patch
_vd_game_butwait2b:	dc.l 0
_vd_insdisk2_s1:	dc.l 0	; insert disk 2 search key
_vd_insdisk2_s2:	dc.l 0
_vd_manprot_s1:	dc.l 0	; manual protection search key
_vd_manprot_s2:	dc.l 0
_vd_tr_landnow:	dc.l 0	; "land now" timer
_vd_tr_p1lives:	dc.l 0	; guess
_vd_tr_p1weapon:	dc.l 0
_vd_tr_p2lives:	dc.l 0
_vd_tr_p2weapon:	dc.l 0

RELOC_MOVEL:MACRO
		lea	\2(pc),a0
		move.l	#\1,(a0)
		ENDM
		
;-----

	CNOP	0,4
_p1_patchlist_version_1:
	PL_START
	PL_PS	$6428,_butwait2
	PL_P	$4b3ea,_game_chipmem
	PL_P	$4c9fa,_game_trackloader
	PL_P	$4cb0e,_game_tracksaver
	PL_PS	$491e,_game_keyboard
	PL_W	$4cd74,$6006
	PL_W	$4cd74+$c,$6006
	PL_W	$4cd74+$18,$6006
	PL_END
	
	
_setvars_version_1
	;VD_VERSION	1,$f8a1	; v1
	;RELOC_MOVEL	$4b3ea           ;  _vd_game_chipmem:	
	;RELOC_MOVEL	$4cd74           ;  _vd_game_diskaccess1
	;RELOC_MOVEL	$4cd74+$c        ;  _vd_game_diskaccess2
	;RELOC_MOVEL	$4cd74+$18       ;  _vd_game_diskaccess3
	;RELOC_MOVEL	$4c9fa           ;  _vd_game_tkloader:	
	;RELOC_MOVEL	$4cb0e           ;  _vd_game_tksaver:	
	;RELOC_MOVEL	$491e            ;  _vd_game_keyboard:	
	RELOC_MOVEL	$3cc6,_vd_game_keycode
	;RELOC_MOVEL	$6428,_vd_game_butwait2a:	
	RELOC_MOVEL	$4442,_vd_game_butwait2b	
	RELOC_MOVEL	$06000018,_vd_insdisk2_s1	
	RELOC_MOVEL	$13c00000,_vd_insdisk2_s2	
	RELOC_MOVEL	$61000c62,_vd_manprot_s1
	RELOC_MOVEL	$61001302,_vd_manprot_s2
	RELOC_MOVEL	$127c,_vd_tr_landnow
	RELOC_MOVEL	$17c4,_vd_tr_p1lives
	RELOC_MOVEL	$17ce,_vd_tr_p1weapon
	RELOC_MOVEL	$1794,_vd_tr_p2lives
	RELOC_MOVEL	$179e,_vd_tr_p2weapon
	rts
	
_p1_patchlist_version_2:
	PL_START
	PL_PS	$653e,_butwait2
	PL_P	$4b402,_game_chipmem
	PL_P	$4cb10,_game_trackloader
	PL_P	$4cc24,_game_tracksaver
	PL_PS	$4a00,_game_keyboard
	PL_W	$4ce8a,$6006
	PL_W	$4ce8a+$c,$6006
	PL_W	$4ce8a+$18,$6006
	PL_END

_setvars_version_2
	;VD_VERSION	2,$0cea	; v2
;	dc.l	$4b402          ;  _vd_game_chipmem:	
;	dc.l	$4ce8a          ;  _vd_game_diskaccess1
;	dc.l	$4ce8a+$c       ;  _vd_game_diskaccess2
;	dc.l	$4ce8a+$18      ;  _vd_game_diskaccess3
;	dc.l	$4cb10          ;  _vd_game_tkloader:	
;	dc.l	$4cc24          ;  _vd_game_tksaver:	
;	dc.l	$4a00           ;  _vd_game_keyboard:	
	RELOC_MOVEL	$3cd8,_vd_game_keycode
;	RELOC_MOVEL	$653e           ;  _vd_game_butwait2a:	
	RELOC_MOVEL	$4656,_vd_game_butwait2b	
	RELOC_MOVEL	$06000018,_vd_insdisk2_s1	
	RELOC_MOVEL	$13c00000,_vd_insdisk2_s2	
	RELOC_MOVEL	$61000c6c,_vd_manprot_s1
	RELOC_MOVEL	$61001330,_vd_manprot_s2
	RELOC_MOVEL	$1280,_vd_tr_landnow
	RELOC_MOVEL	$17d4,_vd_tr_p1lives
	RELOC_MOVEL	$17de,_vd_tr_p1weapon	
	RELOC_MOVEL	$17a2,_vd_tr_p2lives
	RELOC_MOVEL	$17ac,_vd_tr_p2weapon	
	rts
	

;--------------------------------

_resload:    dc.l 0

;-----

_ctl_tags:	dc.l	WHDLTAG_VERSION_GET
_ct_ver:	dc.l	0
	dc.l	WHDLTAG_REVISION_GET
_ct_rev:	dc.l	0
	dc.l	WHDLTAG_ATTNFLAGS_GET
_ct_attn:	dc.l	0
	dc.l	WHDLTAG_CHIPREVBITS_GET
_ct_chiprev:	dc.l	0
	dc.l	WHDLTAG_BUTTONWAIT_GET
_ct_butwait:	dc.l	0
	dc.l	0

_p1_patchlist
	dc.l	0
_setvars_call
	dc.l	0
;-----


;--------------------------------
