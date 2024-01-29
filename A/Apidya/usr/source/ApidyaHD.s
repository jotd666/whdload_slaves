;============================================================================
;$VER: Apidya slave source 2.05 © 2008-2009 Halibut Software
;
; This file may not be distributed, reproduced or altered, in full or in
; part, in any way, without prior written permission from the author.
;
; Special license is granted to the administrators of the WHDLoad project
; to dispose of this file as required in the case where reasonable attempts
; to obtain permission from the author have failed.
;
;============================================================================

	SECTION	Slave,CODE

	INCDIR	INCLUDE:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	;INCLUDE	rawkeys.i
	INCLUDE	graphics/display.i

;==========================================================================

BASMEM_SIZE:	equ	$80000

WHDL_FLAGS:	equ WHDLF_ClearMem|WHDLF_EmulTrap
WHDL_REQVER:	equ 16
WHDL_REQREV:	equ 9

DEVMODE:	equ 0	; set to 1 to enable devmode cheats

;==========================================================================

	; WHDLoad slave header structure v16

_base:	SLAVE_HEADER		; ws_Security + ws_ID
	dc.w	WHDL_REQVER	; ws_Version
	dc.w	WHDL_FLAGS	; ws_flags
	dc.l	BASMEM_SIZE	; ws_BaseMemSize
	dc.l	0	; ws_ExecInstall
	dc.w	_start-_base	; ws_GameLoader
	dc.w	_wsdata-_base	; ws_CurrentDir
	dc.w	0
_keydebug:	dc.b	$58	; ws_keydebug
_keyexit:	dc.b	$59	; ws_keyexit
_expmem:	dc.l	0	; ws_ExpMem
	dc.w	_wsname-_base	; ws_name
	dc.w	_wscopy-_base	; ws_copy
	dc.w	_wsinfo-_base	; ws_info
	dc.w	0	; ws_kickname
	dc.l	0	; ws_kicksize
	dc.w	0	; ws_kickcrc

;==========================================================================

	dc.b	"$VER: Apidya WHDLoad Slave "
	INCLUDE	Version.i
	dc.b	0
	EVEN

;==========================================================================

	; patchlist macros to patch in jsr x.w to
	; copper fix (fixcop) jumps installed at $100
	; jsr x.w ($4eb8) is 4 bytes, replaces "move.l a0,cop1lc(a5)"

FIXCOP_S:	MACRO
	PL_L	\1,$4eb80100
	ENDM

FIXCOP_NS:	MACRO
	PL_L	\1,$4eb80106
	ENDM


	; fixed tfmx 7v replay mixer code snippet

TFMX_SMC:	MACRO
	move.l	a0,-(a7)

	move.l	_tfmx_smc_1(pc),a0	; replaces smc
	move.b	0(a0,d4.w),d4
	move.b	0(a1,d1.w),d5
	move.l	_tfmx_smc_2(pc),a0
	move.b	0(a0,d5.w),d5
	add.w	d5,d4
	move.b	0(a2,d2.w),d5
	move.l	_tfmx_smc_3(pc),a0
	move.b	0(a0,d5.w),d5
	add.w	d5,d4
	move.b	0(a3,d3.w),d5
	move.l	_tfmx_smc_4(pc),a0
	move.b	0(a0,d5.w),d5
	add.w	d5,d4
	swap	d5

	move.l	(a7)+,a0
	jmp	\1	; back to original code
	ENDM


	; other handy macros

CALLWHD:	MACRO
	move.l	_resload(pc),a2
	jsr	resload_\1(a2)
	ENDM

WHDPATCH:	MACRO
	movem.l	d0-7/a0-6,-(a7)
	lea	\1(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch
	movem.l	(a7)+,d0-7/a0-6
	ENDM

;==========================================================================

_start:	lea	$880,a1	; initialise stack
	move.l	a1,usp
	lea	$7e800,a7
	move.w	#0,sr

	bsr	_initialise	; initialise slave

	; determine game version

	lea	$10000,a0	; addr
	move.l	#$2e00,d0	; offset (track 2)
	move.l	#$1a00,d1	; length
	moveq	#1,d2	; disk number
	movem.l	a0/d1,-(a7)
	CALLWHD	DiskLoad
	movem.l	(a7)+,a0/d0
	CALLWHD	CRC16

	cmp.w	#$e269,d0
	beq.s	.st_isv1
	cmp.w	#$788b,d0
	beq.s	.st_isv2
	bra	_badver
.st_isv1:	moveq	#1,d0
	bra	.st_gotver
.st_isv2:	moveq	#2,d0
.st_gotver:	lea	_game_ver(pc),a0
	move.l	d0,(a0)

	; load loader

	lea	$7e800,a0	; addr
	move.l	#$1600,d0	; offset
	move.l	#$1800,d1	; length
	moveq	#1,d2	; disk number
	CALLWHD	DiskLoad

	; start level trainer

	move.l	_ct_cust4(pc),d0
	and.l	#7,d0
	beq	.st_tr_startlev_done
	cmp.l	#6,d0
	bgt	.st_tr_startlev_done
	subq.l	#2,d0
	bmi	.st_tr_startlev_done
	add.l	d0,d0
	move.w	.st_tr_startlev_ofs(pc,d0.l),d0
	lea	$7ec4a,a0
	move.w	#$6000,(a0)+	; $6000 = bra.l
	move.w	d0,(a0)	; bra offset
.st_tr_startlev_done:

	; patch loader

	lea	_pldr_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	; start loader

	jmp	$7e800

;-----
	; bra offsets for each start level 2-5
	; & "6" for end credits
.st_tr_startlev_ofs:
	dc.w	$0046,$006a,$008e,$00cc,$0100
	; level         2    3     4     5     end

;--------------------

	; loader patchlist

	CNOP	0,4
_pldr_pl:	PL_START

	PL_P	$100,_fixcop_s	; install copper fix jumptable
	PL_P	$106,_fixcop_ns
	PL_I	$10c

	PL_NOP	$7e800,8	; disable beamcon0 access

	FIXCOP_NS	$7f048	; fix copperlists
	FIXCOP_S	$7fbf0

	PL_PS	$7fa4c,_pldr_set_chip	; fix chipmem detection
	PL_L	$7fa64,$70004e71	; fix fastmem detection (= none)

	PL_L	$7ede6,$880	; fix stack to $880

	PL_P	$7f226,_trackload	; patch trackloader
	PL_R	$7f014	; remove floppy access
	PL_R	$7f6ca

	PL_PS	$7ec0c,_plgo	; patch logo jump
	PL_PS	$7ec20,_pmnu	; patch menu jump
	PL_PS	$7ec88,_plv1	; patch game level jumps
	PL_PS	$7eca4,_plv2
	PL_PS	$7ecc8,_plv3
	PL_PS	$7ecec,_plv4
	PL_PS	$7ed2a,_plv5
	PL_PS	$7ed7a,_pcnt	; patch continue screen jump
	PL_PS	$7ed68,_pend	; patch end credits jump

	PL_END

;--------------------
; set top of chip memory

_pldr_set_chip:
	move.l	#BASMEM_SIZE,d0
	cmp.l	d1,d0
	rts

;==========================================================================

_plgo:	; patch logo

	WHDPATCH	_plgo_pl

	; run logo
	jsr	$5c13c

	; logo cosmetic delay
	bsr	_wait2sec
	bsr	_wait2sec

	; back to loader
	rts

;--------------------

	; logo patchlist

	CNOP	0,4
_plgo_pl:	PL_START

	FIXCOP_NS	$5c1cc	; fix copperlists

	PL_END

;==========================================================================

_pmnu:	; patch menu

	movem.l	d0-7/a0-6,-(a7)

	; install corrected samples for title music

	lea	_smpl(pc),a0	; start
	lea	$538f2,a1	; destination
	CALLWHD	Decrunch

	; patches

	lea	_pmnu_pl(pc),a0	; other patches
	sub.l	a1,a1
	CALLWHD	Patch

	; load high scores and options

	bsr	_hiscore_load

	movem.l	(a7)+,d0-7/a0-6

	; run menu

	jsr	$a00

	; back to loader

	tst.l	d0
	rts

;--------------------

	; menu patchlist

	CNOP	0,4
_pmnu_pl:	PL_START

	PL_NOP	$a00,10	; remove stack buggering

	PL_PSS	$a54,_pmnu_fixcop_a,2	; fix copperlists

	PL_P	$4778,_hiscore_load	; patch hiscore load
	PL_P	$46e6,_hiscore_save	; patch hiscore save

	PL_W	$796e,$2282	; fix smc in tfmx7v replay
	PL_R	$7970
	PL_PSS	$79a8,_fix_tfmx_smc_1,2
	PL_PSS	$79b6,_fix_tfmx_smc_2,2
	PL_PSS	$79c6,_fix_tfmx_smc_3,2
	PL_PSS	$79d6,_fix_tfmx_smc_4,2
	PL_P	$7ac0,_pmnu_tfmx_smc
	
	PL_END

;--------------------

_pmnu_fixcop_a:
	move.l	a0,-(a7)
	lea	$4cb6,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

;--------------------

_pmnu_tfmx_smc:
	TFMX_SMC	$7af4

;==========================================================================

_plv1:	; patch level 1

	movem.l	d0-7/a0-6,-(a7)

	; trainers


	move.l	_ct_cust1(pc),d0	; infinite lives
	beq	.pl1_tr_1done
	move.b	#$4a,$979a
	move.b	#$4a,$ac88
.pl1_tr_1done:

	move.l	_ct_cust2(pc),d0	; invulnerability
	beq	.pl1_tr_2done
	move.b	#$60,$18be
.pl1_tr_2done:

	move.l	_ct_cust3(pc),d0	; keep weapons on die
	beq	.pl1_tr_3done
	move.l	#$6000009e,$97f6
.pl1_tr_3done:
.pl1_tr_done:

	; patches

	bsr	_fixbwait_main

	lea	_plv1_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run level

	IFNE	DEVMODE
	add.l	#$20000,$9a2	; add 20000 to initial score
	add.l	#$20000,$982
	ENDC
	jsr	$a00

	; back to loader

	tst.l	d0
	rts

;--------------------

	; level 1 patchlist

	CNOP	0,4
_plv1_pl:	PL_START

	IFNE	DEVMODE
	PL_PSS	$a140,_plv1_devmode,6	; install dev mode
	ENDC

	PL_PS	$aaa,_plv1_fixcop_b	; fix copperlists
	FIXCOP_NS	$cf2
	PL_PSS	$94fc,_plv1_fixcop_a,2
	PL_PSS	$9d2a,_plv1_fixcop_a,2
	PL_ORW	$9d58,COLORON
	PL_PSS	$ab44,_plv1_fixcop_a,2
	FIXCOP_NS	$ab9c

	PL_PS	$970a,_bwait_a	; fix blitter waits
	PL_PS	$229c,_bwait_b
	PL_PSS	$399e,_bwait_e,6

	PL_PSS	$3a68,_plv1_fixisf,2	; fix instruction stream fault

	PL_PS	$3ae4,_keyboard	; patch keyboard handler

	PL_PSS	$ab16,_plv1g,4	; patch guardian jump

	PL_PS	$5ae2,_pbhh	; patch 1-1 "heaven & hell" bonus game jump
	PL_PS	$5794,_pbug	; patch 1-2 "underground" bonus game jump

	PL_END

;--------------------

	IFNE	DEVMODE
_plv1_devmode:
	move.w	#$ac,$7baa	; set start pos: 00 44 ac 130 1cd
	move.w	#$ac,$7b72
	move.w	#2,$7c28	; max weapons
	move.w	#3,$7c22
	move.w	#3,$7c24
	move.w	#3,$7c26
	move.w	#-1,$7c2c
	move.w	#5,$7bbe
	move.w	#-1,$7bca
	rts
	ENDC

;--------------------

_plv1_fixcop_a:
	move.l	a0,-(a7)
	lea	$7ea4,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

_plv1_fixcop_b:
	move.l	a0,-(a7)
	lea	$8348,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0
	move.w	#$87e0,dmacon(a5)
	rts

;--------------------

	; fix instruction stream fault
	; sometimes calculated jump offset is -ve and jumps to middle of instruction

_plv1_fixisf:
	move.w	$7c20,d0	; get base value
	bne	.pl1isf_ok	; skip if ok

	move.w	#$12,d0	; set jump offset to go to RTS
	rts

.pl1isf_ok:	subq.w	#1,d0	; calculate normal jump offset
	add.w	d0,d0
	rts

;==========================================================================

_plv1g:	; patch level 1 guardian

	movem.l	d0-7/a0-6,-(a7)

	bsr	_fixbwait_main

	lea	_plv1g_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run guardian

	jsr	$ab6e

	; back to main game

	move.l	d0,$af38
	rts

;--------------------

	; level 1 guardian patchlist

	CNOP	0,4
_plv1g_pl:	PL_START

	IFNE	DEVMODE
	;PL_B	$ac62,$60	; skip guardian
	PL_B	$ac8c,$60	; skip to continue screen on lost life
	ENDC
	PL_PS	$ad96,_plv1g_scwait_a	; fix "stage complete" bonus delays
	PL_P	$ad30,_waitvb

	PL_PSS	$11e18,_plv1g_bwait_a,2	; fix blitter waits

	PL_END

;--------------------

_plv1g_bwait_a:
	bsr	_blitwait_a5
	move.l	a1,bltcpt(a5)
	lea	$36(a1),a1
	rts

;--------------------

_plv1g_scwait_a:
	bsr	_wait2sec
	jmp	$99d2

;==========================================================================

_plv2:	; patch level 2

	movem.l	d0-7/a0-6,-(a7)

	; trainers


	move.l	_ct_cust1(pc),d0	; infinite lives
	beq	.pl2_tr_1done
	move.b	#$4a,$8456
	move.b	#$4a,$b546
.pl2_tr_1done:

	move.l	_ct_cust2(pc),d0	; invulnerability
	beq	.pl2_tr_2done
	move.b	#$60,$17e2
.pl2_tr_2done:

	move.l	_ct_cust3(pc),d0	; keep weapons on die
	beq	.pl2_tr_3done
	move.l	#$6000009e,$84b8
.pl2_tr_3done:
.pl2_tr_done:

	; patches

	bsr	_fixbwait_main

	lea	_plv2_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run level

	jsr	$a00

	; back to loader

	tst.l	d0
	rts

;--------------------

	; level 2 patchlist

	CNOP	0,4
_plv2_pl:	PL_START

	IFNE	DEVMODE
	PL_PSS	$8e26,_plv2_devmode,2	; install dev mode
	ENDC

	PL_P	$180,_plv2_fixcop_a	; fix copperlists
	PL_PS	$aa4,_plv2_fixcop_c
	FIXCOP_NS	$b62
	FIXCOP_NS	$c4e
	FIXCOP_NS	$b44e
	PL_L	$8a18,$4eb80180
	PL_PSS	$8146,_plv2_fixcop_b,2
	PL_PSS	$89ec,_plv2_fixcop_b,2
	PL_PSS	$b2e6,_plv2_fixcop_b,2
	PL_PSS	$b3f6,_plv2_fixcop_b,2

	PL_PS	$db0,_bwait_b	; fix blitter waits
	PL_PS	$83c6,_bwait_a
	PL_PS	$247e,_bwait_b
	PL_PSS	$3bea,_bwait_e,6

	PL_PS	$441e,_plv2_fixaf	; fix sign extension related access fault

	PL_PSS	$3cc2,_plv2_fixisf,2	; fix instruction stream fault

	PL_PS	$17dc,_plv2_fix_colldet	; fix collision detection

	PL_PS	$3d44,_keyboard	; patch keyboard handler

	PL_PS	$6052,_pbug	; patch 2-2 "underground" bonus game jump

	PL_PSS	$b3c8,_plv2g,4	; patch guardian jump

	PL_END

;--------------------

	IFNE	DEVMODE
_plv2_devmode:
	move.w	#$f3,$7a28	; set start pos: 00 5a a2 f3 15a 1cd
	move.w	#$f3,$7a68
	move.w	#3,$7ae6	; max weapons
	move.w	#3,$7ae0
	move.w	#3,$7ae2
	move.w	#3,$7ae4
	move.w	#-1,$7ae8
	move.w	#5,$7a7c
	move.w	#-1,$7a88
	rts
	ENDC

;--------------------

_plv2_fixcop_a:
	move.w	#COLORON,bplcon0(a5)
	rts

_plv2_fixcop_b:
	move.l	a0,-(a7)
	lea	$8f64,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

_plv2_fixcop_c:
	move.l	a0,-(a7)
	lea	$94bc,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0
	move.w	#$87e0,dmacon(a5)
	rts

;--------------------

_plv2_fixaf:	moveq	#0,d2
	move.w	$16(a0),d2
	move.l	d2,a2
	rts

;--------------------

_plv2_fixisf:
	move.w	$7ade,d0
	bne	.pl2isf_ok

	move.w	#$12,d0
	rts

.pl2isf_ok:	subq.w	#1,d0
	add.w	d0,d0
	rts

;--------------------

_plv2_fix_colldet:
	; run player vs. scenery collision modules for level 2
	;
	; this is required to pick up entry to the underground 2
	; subgame when invulnerability trainer or flashing invulnerable
	; mode is active. we check all modules, but only run the subgame

	move.l	d7,-(a7)

	move.l	_ct_cust2(pc),d0	; run modules if invul trainer active
	bne	.pl2_cd_runmod
	btst	#1,$7aeb	; ...or "flashing invulnerable" active
	bne	.pl2_cd_done

.pl2_cd_runmod:
	; run the modules

	lea	$7eb30,a1	; mod_list
	move.w	$7a84,d0	; px
	move.w	$7a86,d1	; py
.pl2_cd_runloop:
	tst.w	(a1)	; skip if invalid or end of list
	bmi	.pl2_cd_done
	beq	.pl2_cd_runnext

	suba.l	a2,a2	; a2 = module address
	move.w	$a(a1),a2
	cmp.l	#$602e,a2	; skip if not subgame
	bne	.pl2_cd_runnext

	cmp.w	(a1),d0	; check for collision
	bgt	.pl2_cd_runnext
	cmp.w	2(a1),d0
	blt	.pl2_cd_runnext
	cmp.w	4(a1),d1
	blt	.pl2_cd_runnext
	cmp.w	6(a1),d1
	bgt	.pl2_cd_runnext

	jsr	(a2)	; run module

.pl2_cd_runnext:
	lea	$c(a1),a1
	bra.s	.pl2_cd_runloop

.pl2_cd_done:
	move.l	(a7)+,d7
	btst	#1,$7aeb	; set flags for return
	rts

;==========================================================================

_plv2g:	; patch level 2 guardian

	movem.l	d0-7/a0-6,-(a7)

	; redirect table accesses to slave memory

	lea	_plv2g_3e190_tab(pc),a0
	move.l	a0,$10212
	move.l	a0,$10d2c
	move.l	a0,$115b0
	move.l	a0,$11c14

	; patches

	bsr	_fixbwait_main

	lea	_plv2g_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run guardian

	jsr	$b420

	; back to main game

	move.l	d0,$b7f4
	rts

;--------------------

	; level 2 guardian patchlist

	CNOP	0,4
_plv2g_pl:	PL_START

	IFNE	DEVMODE
	;PL_B	$b520,$60	; skip guardian
	ENDC
	PL_PS	$b64e,_plv2g_scwait_a	; fix "stage complete" bonus delays
	PL_P	$b688,_waitvb

	PL_PSS	$102f6,_plv2g_bwait_a,2	; fix blitter waits

	PL_W	$10634,$20df	; fix copperlist generation

	PL_PS	$10a30,_pbps	; patch "pike stomach" bonus game jump

	PL_END

;--------------------

_plv2g_bwait_a:
	bsr	_blitwait_a5
	move.l	d0,bltdpt(a5)
	move.w	#0,bltdmod(a5)
	rts

;--------------------

_plv2g_scwait_a:
	bsr	_wait2sec
	jmp	$b0e

;==========================================================================

_plv3:	; patch level 3

	movem.l	d0-7/a0-6,-(a7)

	; determine code version in use

	move.l	_game_ver(pc),d0
	cmp.l	#1,d0
	beq	.pl3_isv1
	cmp.l	#2,d0
	beq	.pl3_isv2
	bra	_badver

.pl3_isv1:	; version 1 - SPSID 0764 "Kaiko" original release

	; trainers


	move.l	_ct_cust1(pc),d0	; infinite lives
	beq	.pl3a_tr_1done
	move.b	#$4a,$8aa0
	move.b	#$4a,$c17c
.pl3a_tr_1done:

	move.l	_ct_cust2(pc),d0	; invulnerability
	beq	.pl3a_tr_2done
	move.b	#$60,$1a54
.pl3a_tr_2done:

	move.l	_ct_cust3(pc),d0	; keep weapons on die
	beq	.pl3a_tr_3done
	move.l	#$6000009e,$8afc
.pl3a_tr_3done:
.pl3a_tr_done:

	; patches

	bsr	_fixbwait_main

	lea	_plv3a_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run level

	jsr	$a00

	; back to loader

	tst.l	d0
	rts


.pl3_isv2:	; version 2 - SPSID 2465 "AUDIOS" re-release

	; trainers


	move.l	_ct_cust1(pc),d0	; infinite lives
	beq	.pl3b_tr_1done
	move.b	#$4a,$8a88
	move.b	#$4a,$c164
.pl3b_tr_1done:

	move.l	_ct_cust2(pc),d0	; invulnerability
	beq	.pl3b_tr_2done
	move.b	#$60,$1a3c
.pl3b_tr_2done:

	move.l	_ct_cust3(pc),d0	; keep weapons on die
	beq	.pl3b_tr_3done
	move.l	#$6000009e,$8ae4
.pl3b_tr_3done:
.pl3b_tr_done:

	; patches

	bsr	_fixbwait_main

	lea	_plv3b_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run level

	jsr	$a00

	; back to loader

	tst.l	d0
	rts

;--------------------

	; level 3 patchlists

	; level 3 v1 patches

	CNOP	0,4
_plv3a_pl:	PL_START

	IFNE	DEVMODE
	PL_PS	$9306,_plv3a_devmode	; install dev mode
	ENDC

	PL_PS	$a98,_plv3a_fixcop_b	; fix copperlists
	PL_PSS	$8802,_plv3a_fixcop_a,2
	PL_PSS	$9056,_plv3a_fixcop_a,2
	PL_ORW	$9084,COLORON
	PL_PS	$90ac,_plv3_fixcop_c
	PL_PSS	$c034,_plv3a_fixcop_a,2
	FIXCOP_NS	$c08c

	PL_PS	$22ce,_bwait_b	; fix blitter waits
	PL_PSS	$3242,_plv3_bwait_a,2
	PL_PSS	$3ad2,_bwait_e,6
	PL_PS	$8a10,_bwait_a

	PL_PSS	$3ba8,_plv3a_fixisf,2	; fix instruction stream fault

	PL_W	$9280,$42b9	; => clr.l x.l (fix simultaneous mode)
	PL_W	$9286,$50f9	; => st $180.l
	PL_L	$9288,$180
	PL_W	$c1ba,$42b8	; => clr.l x.w
	PL_L	$c1be,$50f80180	; => st $180.w

	PL_PS	$3c2a,_keyboard	; patch keyboard handler

	PL_PS	$82c4,_pbrs	; patch 3-1 "rat stomach" bonus game jump

	PL_PSS	$c006,_plv3ag,4	; patch guardian jump

	PL_NEXT	_plv3com_pl	; do common patches

	PL_END


	; level 3 v2 patches

	CNOP	0,4
_plv3b_pl:	PL_START

	IFNE	DEVMODE
	PL_PS	$92ee,_plv3b_devmode
	ENDC

	PL_PS	$a98,_plv3b_fixcop_b
	PL_PSS	$87ea,_plv3b_fixcop_a,2
	PL_PSS	$903e,_plv3b_fixcop_a,2
	PL_ORW	$906c,COLORON
	PL_PS	$9094,_plv3_fixcop_c
	PL_PSS	$c01c,_plv3b_fixcop_a,2
	FIXCOP_NS	$c074

	PL_PS	$22b6,_bwait_b
	PL_PSS	$322a,_plv3_bwait_a,2
	PL_PSS	$3aba,_bwait_e,6
	PL_PS	$89f8,_bwait_a

	PL_PSS	$3b90,_plv3b_fixisf,2

	PL_W	$9268,$42b9
	PL_W	$926e,$50f9
	PL_L	$9270,$180
	PL_W	$c1a2,$42b8
	PL_L	$c1a6,$50f80180

	PL_PS	$3c12,_keyboard

	PL_PS	$82ac,_pbrs

	PL_PSS	$bfee,_plv3bg,4

	PL_NEXT	_plv3com_pl

	PL_END


	; level 3 common patches

	CNOP	0,4
_plv3com_pl:	PL_START

	FIXCOP_NS	$b32	; fix copperlists

	PL_NOP	$15e0,4	; fix simultaneous mode
	PL_L	$15e4,$4a380180	; => tst.b $180.w
	PL_W	$15e8,$6a00	; => bpl
	PL_NOP	$1a04,6
	PL_L	$1a0a,$4a380180
	PL_W	$1a0e,$6aec

	PL_END

;--------------------

	IFNE	DEVMODE
_plv3a_devmode:
	move.w	#$169,$7e7e	; start pos: 00 44 a5 c9 fb 169
	move.w	#$169,$7ed0
	move.w	#2,$7f1a	; max weapons
	move.w	#3,$7f14
	move.w	#3,$7f16
	move.w	#3,$7f18
	move.w	#-1,$7f1e
	move.w	#5,$7ee4
	move.w	#-1,$7ef0
	rts

_plv3b_devmode:
	move.w	#$169,$7e66
	move.w	#$169,$7eb8
	move.w	#2,$7f02
	move.w	#3,$7efc
	move.w	#3,$7efe
	move.w	#3,$7f00
	move.w	#-1,$7f06
	move.w	#5,$7ecc
	move.w	#-1,$7ed8
	rts
	ENDC

;--------------------

_plv3a_fixcop_a:
	move.l	a0,-(a7)
	lea	$a12e,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

_plv3b_fixcop_a:
	move.l	a0,-(a7)
	lea	$a116,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

_plv3a_fixcop_b:
	move.l	a0,-(a7)
	lea	$a12e,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0
	move.w	#$87e0,dmacon(a5)
	rts

_plv3b_fixcop_b:
	move.l	a0,-(a7)
	lea	$a116,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0
	move.w	#$87e0,dmacon(a5)
	rts

_plv3_fixcop_c:
	move.l	a0,-(a7)
	lea	$3c7b6,a0
	bsr	_fixcop_main
	lea	$3cd46,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0
	move.w	#$86e0,dmacon(a5)
	rts

;--------------------

_plv3_bwait_a:
	bsr	_blitwait_a5
	move.l	#$ffffffff,bltafwm(a5)
	rts

;--------------------

_plv3a_fixisf:
	move.w	$7f12,d0
	bne	.pl3isf_ok

	move.w	#$12,d0
	rts

.pl3isf_ok:	subq.w	#1,d0
	add.w	d0,d0
	rts

;--------------------

_plv3b_fixisf:
	move.w	$7efa,d0
	bne	.pl3isf_ok

	move.w	#$12,d0
	rts

.pl3isf_ok:	subq.w	#1,d0
	add.w	d0,d0
	rts

;==========================================================================

_plv3ag:	; patch level 3 v1 guardian

	movem.l	d0-7/a0-6,-(a7)

	bsr	_fixbwait_main

	lea	_plv3ag_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run guardian

	jsr	$c05e

	; back to main game

	move.l	d0,$c384
	rts

;--------------------

	; level 3 v1 guardian patchlist

	CNOP	0,4
_plv3ag_pl:	PL_START

	IFNE	DEVMODE
	;PL_B	$c156,$60	; skip guardian
	ENDC
	PL_PS	$c27a,_plv3ag_scwait_a	; fix "stage complete" bonus delays
	PL_P	$c2aa,_waitvb

	PL_END

;--------------------

_plv3ag_scwait_a:
	bsr	_wait2sec
	jmp	$8dca

;==========================================================================

_plv3bg:	; patch level 3 v2 guardian

	movem.l	d0-7/a0-6,-(a7)

	bsr	_fixbwait_main

	lea	_plv3bg_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run guardian

	jsr	$c046

	; back to main game

	move.l	d0,$c36c
	rts

;--------------------

	; level 3 v2 guardian patchlist

	CNOP	0,4
_plv3bg_pl:	PL_START

	IFNE	DEVMODE
	;PL_B	$c13e,$60	; skip guardian
	ENDC
	PL_PS	$c262,_plv3bg_scwait_a	; fix "stage complete" bonus delays
	PL_P	$c292,_waitvb

	PL_END

;--------------------

_plv3bg_scwait_a:
	bsr	_wait2sec
	jmp	$8db2

;==========================================================================

_plv4:	; patch level 4

	movem.l	d0-7/a0-6,-(a7)

	; trainers


	move.l	_ct_cust1(pc),d0	; infinite lives
	beq	.pl4_tr_1done
	move.b	#$4a,$993a
.pl4_tr_1done:

	move.l	_ct_cust2(pc),d0	; invulnerability
	beq	.pl4_tr_2done
	move.b	#$60,$1782
.pl4_tr_2done:

	move.l	_ct_cust3(pc),d0	; keep weapons on die
	beq	.pl4_tr_3done
	move.l	#$6000007e,$998a
.pl4_tr_3done:

.pl4_tr_done:

	; patches

	bsr	_fixbwait_main

	lea	_plv4_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	lea	_plv4_plr(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch
.pl4_pchr_done:

	movem.l	(a7)+,d0-7/a0-6

	; run level

	jsr	$a00

	; back to loader

	tst.l	d0
	rts

;--------------------

	; level 4 patchlist

	CNOP	0,4
_plv4_pl:	PL_START

	IFNE	DEVMODE
	PL_PS	$a2ec,_plv4_devmode	; install dev mode
	ENDC

	PL_PS	$ada,_plv4_fixcop_a	; fix copperlists
	FIXCOP_NS	$bb8
	PL_PSS	$9670,_plv4_fixcop_b,2
	PL_ORW	$9f82,COLORON
	PL_PS	$9faa,_plv4_fixcop_c
	FIXCOP_NS	$336e6

	PL_PS	$217c,_bwait_b	; fix blitter waits
	PL_PS	$3088,_plv4_bwait_a
	PL_PS	$60e8,_bwait_b
	PL_PS	$9832,_bwait_g
	PL_PSS	$98e8,_plv4_bwait_b,4

	PL_PSS	$3742,_plv4_fixisf,2	; fix instruction stream fault

	PL_PS	$9764,_plv4_fixaf_a	; fix access faults
	PL_PS	$9786,_plv4_fixaf_a
	PL_PSS	$a2d4,_plv4_fixaf_b,6

	PL_PS	$37c4,_keyboard	; patch keyboard handler

	PL_R	$5eae	; disable "speed of light" bonus game

	; level 4 guardian code is included with the main code
	; so there are no separate patch routines for it

	IFNE	DEVMODE
	;PL_NOP	$b5a,2	; skip guardian
	ENDC
	PL_PS	$c302,_plv4g_scwait_a	; fix "stage complete" bonus delays
	PL_PSS	$c2c0,_waitvb,14

	PL_END

;-----

	; level 4 patchlist for registered users only

	CNOP	0,4
_plv4_plr:	PL_START

	PL_PS	$177c,_plv4_fix_colldet	; fix collision detection

	PL_W	$5eae,$48e7	; enable "speed of light" bonus game

	PL_PS	$5eca,_pbsl	; patch "speed of light" bonus game jump

	PL_END

;--------------------

	IFNE	DEVMODE
_plv4_devmode:
	move.w	#$168,$7d44	; start pos: 00 3c 96 f2 14d 168 17f 1c7
	move.w	#$168,$7d80
	move.w	#2,$7e03	; max weapons
	move.w	#3,$7dfc
	move.w	#3,$7dfe
	move.w	#3,$7e00
	move.w	#-1,$7e06
	move.w	#5,$7d98
	move.w	#-1,$7da4
	rts
	ENDC

;--------------------

_plv4_fixcop_a:
	move.l	a0,-(a7)
	lea	$8078,a0
	bsr	_fixcop_main
	lea	$8400,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0
	move.w	#$87e0,dmacon(a5)
	rts

_plv4_fixcop_c:
	move.l	a0,-(a7)
	lea	$8078,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0
	move.w	#$86e0,dmacon(a5)
	rts

_plv4_fixcop_b:
	move.l	a0,-(a7)
	lea	$8078,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

;--------------------

_plv4_bwait_a:
	bsr	_blitwait_a5
	move.w	#$9f0,bltcon0(a5)
	rts

_plv4_bwait_b:
	bsr	_blitwait_a5
	move.l	d0,bltdpt(a5)
	move.w	#$1ff,bltcon0(a5)
	rts

;--------------------

_plv4_fixisf:
	move.w	$7dfa,d0
	bne	.pl4isf_ok

	move.w	#$12,d0
	rts

.pl4isf_ok:	subq.w	#1,d0
	add.w	d0,d0
	rts

;--------------------
; access fault
; blitter source address calculation going outside chipmem
; "and.w #$3ff,d7" should be "and.l"

_plv4_fixaf_a:
	and.l	#$3ff,d7
	asl.l	#7,d7
	rts

;--------------------
; access fault
; code is "move.w #0,xxxx.w" but xxxx is > $7fff, so it writes to -xxxx instead
; => writing to $ffff81ba and $ffff8542

_plv4_fixaf_b:
	move.w	#0,$81ba
	move.w	#0,$8542
	rts

;--------------------

_plv4g_scwait_a:
	bsr	_wait2sec
	jmp	$9c0a

;--------------------

_plv4_fix_colldet:
	; run player vs. scenery collision modules for level 4
	;
	; this is required to pick up entry to the speed of light
	; subgame when invulnerability trainer or flashing invulnerable
	; mode is active. we check all modules, but only run the subgame

	move.l	d7,-(a7)

	move.l	_ct_cust2(pc),d0	; run modules if invul trainer active
	bne	.pl4_cd_runmod
	btst	#1,$7e09	; ...or "flashing invulnerable" active
	bne	.pl4_cd_done

.pl4_cd_runmod:
	; run the modules

	lea	$7e840,a1	; mod_list
	move.w	$7da0,d0	; px
	move.w	$7da2,d1	; py
.pl4_cd_runloop:
	tst.w	(a1)	; skip if invalid or end of list
	bmi	.pl4_cd_done
	beq	.pl4_cd_runnext

	suba.l	a2,a2	; a2 = module address
	move.w	$a(a1),a2
	cmp.l	#$5eaa,a2	; skip if not subgame
	bne	.pl4_cd_runnext

	cmp.w	(a1),d0	; check for collision
	bgt	.pl4_cd_runnext
	cmp.w	2(a1),d0
	blt	.pl4_cd_runnext
	cmp.w	4(a1),d1
	blt	.pl4_cd_runnext
	cmp.w	6(a1),d1
	bgt	.pl4_cd_runnext

	jsr	(a2)	; run module

.pl4_cd_runnext:
	lea	$c(a1),a1
	bra.s	.pl4_cd_runloop

.pl4_cd_done:
	move.l	(a7)+,d7
	btst	#1,$7e09	; set flags for return
	rts

;==========================================================================

_plv5:	; patch level 5

	movem.l	d0-7/a0-6,-(a7)

	; trainers


	move.l	_ct_cust1(pc),d0	; infinite lives
	beq	.pl5_tr_1done
	move.b	#$4a,$9340
.pl5_tr_1done:

	move.l	_ct_cust2(pc),d0	; invulnerability
	beq	.pl5_tr_2done
	move.b	#$60,$1930
.pl5_tr_2done:

	move.l	_ct_cust3(pc),d0	; keep weapons on die
	beq	.pl5_tr_3done
	move.l	#$6000009e,$939c
.pl5_tr_3done:
.pl5_tr_done:

	; patches

	bsr	_fixbwait_main

	lea	_plv5_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run level

	jsr	$a00

	; back to loader

	tst.l	d0
	rts

;--------------------

	; level 5 patchlist

	CNOP	0,4
_plv5_pl:	PL_START

	IFNE	DEVMODE
	PL_PSS	$9cda,_plv5_devmode,4	; install dev mode
	ENDC

	PL_PS	$aa4,_plv5_fixcop_a	; fix copperlists
	FIXCOP_NS	$b96
	PL_PSS	$8f7a,_plv5_fixcop_b,2
	PL_ORW	$98d6,COLORON
	PL_PSS	$98a8,_plv5_fixcop_b,2

	PL_PS	$1cfa,_plv5_bwait_a	; fix blitter waits
	PL_PS	$2420,_bwait_b
	PL_P	$8ee4,_bwait_g
	PL_PS	$922e,_bwait_g

	PL_PSS	$3a30,_plv5_fixisf,2	; fix instruction stream fault

	PL_PS	$3aac,_keyboard	; patch keyboard handler

	PL_END

;--------------------

	IFNE	DEVMODE
_plv5_devmode:
	move.w	#$3e7,$7a8c	; start pos: 00 e7 1e7 2e7 3e7
	move.w	#$3e7,$7acc
	move.w	#2,$7b4d	; max weapons
	move.w	#3,$7b46
	move.w	#3,$7b48
	move.w	#3,$7b4a
	move.w	#-1,$7b50
	move.w	#5,$7ae2
	move.w	#-1,$7aee
	rts
	ENDC

;--------------------

_plv5_fixcop_a:
	move.l	a0,-(a7)
	lea	$7db8,a0
	bsr	_fixcop_main
	lea	$7fa8,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0
	move.w	#$87e0,dmacon(a5)
	rts

_plv5_fixcop_b:
	move.l	a0,-(a7)
	lea	$7db8,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

;--------------------

_plv5_bwait_a:
	bsr	_blitwait_a5
	move.w	#0,bltamod(a5)
	rts

;--------------------

_plv5_fixisf:
	move.w	$7b44,d0
	bne	.pl5isf_ok

	move.w	#$12,d0
	rts

.pl5isf_ok:	subq.w	#1,d0
	add.w	d0,d0
	rts

;==========================================================================

_pbhh:	; patch "heaven & hell" bonus game

	movem.l	d0-7/a0-6,-(a7)

	bsr	_fixbwait_main

	lea	_pbhh_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run bonus game

	jsr	$72980

	; fix bonus game copperlists before return

	move.l	a0,-(a7)
	lea	$73732,a0
	bsr	_fixcop_main
	lea	$73b5a,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0

	; back to main game

	rts

;--------------------

	; "heaven & hell" bonus game patchlist

	CNOP	0,4
_pbhh_pl:	PL_START

	FIXCOP_NS	$72e84	; fix copperlists
	PL_PSS	$7298c,_pbhh_fixcop_a,2

	PL_PS	$72c92,_pbhh_bwait_a	; fix blitter waits

	PL_END

;--------------------

_pbhh_bwait_a:
	bsr	_blitwait_a5
	move.l	#$50000,a1
	rts

;--------------------

_pbhh_fixcop_a:
	move.l	a0,-(a7)
	lea	$73732,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

;==========================================================================

_pbug:	; patch "underground" bonus game

	movem.l	d0-7/a0-6,-(a7)

	bsr	_fixbwait_main

	lea	_pbug_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run bonus game

	jsr	$740f0

	; fix bonus game copperlists before return

	move.l	a0,-(a7)
	lea	$75572,a0
	bsr	_fixcop_main
	lea	$75922,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0

	; back to main game

	rts

;--------------------

	; "underground" bonus game patchlist

	CNOP	0,4
_pbug_pl:	PL_START

	FIXCOP_NS	$74524	; fix copperlists
	PL_PSS	$740f6,_pbug_fixcop_a,2

	PL_PS	$74390,_bwait_c	; fix blitter waits
	PL_PSS	$74684,_bwait_d,2

	PL_END

;--------------------

_pbug_fixcop_a:
	move.l	a0,-(a7)
	lea	$75572,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

;==========================================================================

_pbps:	; patch "pike stomach" bonus game

	movem.l	d0-7/a0-6,-(a7)

	bsr	_fixbwait_main

	lea	_pbps_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run bonus game

	jsr	$740f0

	; fix bonus game copperlists before return

	move.l	a0,-(a7)
	lea	$754fc,a0
	bsr	_fixcop_main
	lea	$758ac,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0

	; back to main game

	rts

;--------------------

	; "pike stomach" bonus game patchlist

	CNOP	0,4
_pbps_pl:	PL_START

	FIXCOP_NS	$744a4	; fix copperlists
	PL_PSS	$740f6,_pbps_fixcop_a,2

	PL_PS	$743b0,_bwait_c	; fix blitter waits
	PL_PSS	$745be,_bwait_d,2

	PL_END

;--------------------

_pbps_fixcop_a:
	move.l	a0,-(a7)
	lea	$754fc,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

;==========================================================================

_pbrs:	; patch "rat stomach" bonus game

	movem.l	d0-7/a0-6,-(a7)

	bsr	_fixbwait_main

	lea	_pbrs_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run bonus game

	jsr	$3b800

	; fix bonus game copperlists before return

	move.l	a0,-(a7)
	lea	$3c7b6,a0
	bsr	_fixcop_main
	lea	$3cd46,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0

	; back to main game

	rts

;--------------------

	; "rat stomach" bonus game patchlist

	CNOP	0,4
_pbrs_pl:	PL_START

	FIXCOP_NS	$3bc10	; fix copperlists
	PL_PSS	$3b942,_pbrs_fixcop_a,2

	PL_END

;--------------------

_pbrs_fixcop_a:
	move.l	a0,-(a7)
	lea	$3c7b6,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

;==========================================================================

_pbsl:	; patch "speed of light" bonus game

	movem.l	d0-7/a0-6,-(a7)

	bsr	_fixbwait_main

	lea	_pbsl_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run bonus game

	jsr	$76318

	; fix bonus game copperlists before return

	move.l	a0,-(a7)
	lea	$7700e,a0
	bsr	_fixcop_main
	lea	$773be,a0
	bsr	_fixcop_main
	move.l	(a7)+,a0

	; back to main game

	rts

;--------------------

	; "speed of light" bonus game patchlist

	CNOP	0,4
_pbsl_pl:	PL_START

	FIXCOP_NS	$766ac	; fix copperlists
	PL_PSS	$7631e,_pbsl_fixcop_a,2

	PL_PS	$765b8,_bwait_c	; fix blitter waits
	PL_PSS	$7681a,_bwait_d,2

	PL_END

;--------------------

_pbsl_fixcop_a:
	move.l	a0,-(a7)
	lea	$7700e,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

;==========================================================================

_pcnt:	; patch continue screen

	movem.l	d0-7/a0-6,-(a7)

	bsr	_fixbwait_main

	lea	_pcnt_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	; enable keyboard ints so we can quit during continue screen
	move.w	#INTF_SETCLR|INTF_INTEN|INTF_PORTS,intena+_custom

	movem.l	(a7)+,d0-7/a0-6

	; run continue screen

	jmp	$4c340

;--------------------

	; continue screen patchlist

	CNOP	0,4
_pcnt_pl:	PL_START

	PL_PSS	$4c3ba,_pcnt_fixcop_a,8
	PL_PSS	$4c45e,_pcnt_fixcop_a,8
	PL_PS	$4d672,_fixcop_ns
	PL_PS	$4c35c,_bwait_f
	PL_PS	$4c3d8,_dbfwait
	PL_PS	$4c438,_dbfwait

	PL_END

;--------------------

_pcnt_fixcop_a:
	move.l	a0,-(a7)
	lea	$4c5bc,a0
	bsr	_fixcop_s
	move.l	(a7)+,a0
	move.w	#$87e0,dmacon(a5)
	rts

;==========================================================================

_pend:	; patch end game credits

	movem.l	d0-7/a0-6,-(a7)

	; patches

	bsr	_fixbwait_main

	lea	_pend_pl(pc),a0
	sub.l	a1,a1
	CALLWHD	Patch

	movem.l	(a7)+,d0-7/a0-6

	; run credits

	jmp	$a00

;--------------------

	; end game patchlist

	CNOP	0,4
_pend_pl:	PL_START

	PL_PSS	$a5e,_pend_fixcop_a,2	; fix copperlists
	PL_PSS	$d22,_pend_fixcop_b,2

	PL_W	$6d6e,$2282	; fix smc in tfmx7v replay
	PL_R	$6d70
	PL_PSS	$6da8,_fix_tfmx_smc_1,2
	PL_PSS	$6db6,_fix_tfmx_smc_2,2
	PL_PSS	$6dc6,_fix_tfmx_smc_3,2
	PL_PSS	$6dd6,_fix_tfmx_smc_4,2
	PL_P	$6ec0,_pend_tfmx_smc

	PL_END

;--------------------

_pend_fixcop_a:
	move.l	a0,-(a7)
	lea	$225e,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

_pend_fixcop_b:
	move.l	a0,-(a7)
	lea	$2346,a0
	bsr	_fixcop_ns
	move.l	(a7)+,a0
	rts

;--------------------

_pend_tfmx_smc:
	TFMX_SMC	$6ef4

;==========================================================================
; find and patch standard blitterwait loops

_fixbwait_main:
	movem.l	d6-7/a0-2,-(a7)

	lea	$a00,a0	; search start
	lea	$7fff8,a1	; search end
	lea	_blitwait_a5(pc),a2
	move.l	#$082d000e,d6	; search data
	move.l	#$000266f8,d7

.fbw_loop:	cmp.l	(a0),d6	; search for "btst #$e,2(a5) : bne -8"
	bne	.fbw_next
	cmp.l	4(a0),d7
	bne	.fbw_next

	move.w	#$4eb9,(a0)+	; replace with "jsr _blitwait_a5 : nop"
	move.l	a2,(a0)+
	move.w	#$4e71,(a0)

.fbw_next:	addq.l	#2,a0
	cmp.l	a0,a1
	bgt	.fbw_loop

	movem.l	(a7)+,d6-7/a0-2	; all done
	rts

;--------------------------------
; fix access faults in copperlists
; > a0 = copperlist

_fixcop_main:
	movem.l	d0/d6-7/a0,-(a7)

	move.w	#$ffff,d7
	move.w	#bplcon0,d6
	move.w	#$0ae,d5

.fc_loop:	move.w	(a0),d0	; get copper instruction

	cmp.w	d0,d7	; handle wait
	beq	.fc_is_wait
	cmp.w	d0,d6	; handle bplcon0
	beq	.fc_is_con0
	cmp.w	d0,d5	; handle weirdness $00ae,$00ba in level 3
	beq	.fc_is_0ae

.fc_next:	addq.l	#4,a0	; move to next
	bra	.fc_loop

.fc_is_con0:	or.w	#COLORON,2(a0)	; ensure COLBST bit is set
	bra	.fc_next

.fc_is_0ae:	move.l	#$01800000,(a0)	; change $0ae to color00
	bra	.fc_next

.fc_is_wait:	cmp.w	#$fffe,2(a0)	; loop for more if not end of list
	bne	.fc_next

	movem.l	(a7)+,d0/d6-7/a0	; all done
	rts

;-----
	; copper fix, load and strobe

_fixcop_s:	bsr	_fixcop_main
	move.l	a0,cop1lc(a5)
	move.w	#0,copjmp1(a5)
	rts

;-----
	; copper fix and load (no strobe)

_fixcop_ns:	bsr	_fixcop_main
	move.l	a0,cop1lc(a5)
	rts

;--------------------------------
; fix tfmx 7v replay self modifying code

_fix_tfmx_smc_1:
	lea	_tfmx_smc_1(pc),a1	; redirect smc modifications
	lea	0(a5),a2
	rts

_fix_tfmx_smc_2:
	lea	_tfmx_smc_2(pc),a1
	lea	4(a5),a2
	rts

_fix_tfmx_smc_3:
	lea	_tfmx_smc_3(pc),a1
	lea	8(a5),a2
	rts

_fix_tfmx_smc_4:
	lea	_tfmx_smc_4(pc),a1
	lea	12(a5),a2
	rts

;-----

	CNOP	0,4

_tfmx_smc_1:	dc.l	0
_tfmx_smc_2:	dc.l	0
_tfmx_smc_3:	dc.l	0
_tfmx_smc_4:	dc.l	0


;==========================================================================
; keyboard handler
;
; > d0 = undecoded rawkey
;
; < d0 = decoded rawkey

_keyboard:	; decode rawkey

	not.b	d0
	ror.b	#1,d0

	; check for whdload control keys

	cmp.b	_keydebug(pc),d0
	beq	_debug
	cmp.b	_keyexit(pc),d0
	beq	_exit

	; all done

	rts

;--------------------------------
; trackloader replacement
; > $7fe22.l = address
; > $7fe26.l = length
; > $7fe4f.b = $ff if disk 2, otherwise disk 1
; > $7fe50.b = side
; > $7fe51.b = cylinder

_trackload:	movem.l	d0-7/a0-6,-(a7)

	move.l	$7fe22,a0	; address
	move.l	$7fe26,d1	; length

	moveq	#0,d0	; calculate track number
	move.b	$7fe51,d0
	add.b	d0,d0
	add.b	$7fe50,d0

	cmp.b	#-1,$7fe4f
	beq	.tl_disk2

	; calculate offset for disk 1

	subq.l	#2,d0
	mulu.w	#$1a00,d0
	add.l	#$1600+$1800,d0
	moveq	#1,d2
	bra	.tl_load

.tl_disk2:	; calculate offset for disk 2

	mulu.w	#$1a00,d0
	moveq	#2,d2

.tl_load:	; do load

	move.l	_resload(pc),a2
	jsr	resload_DiskLoad(a2)

	; all done

	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------------------

_wait2sec:	movem.l	d0-7/a0-6,-(a7)
	moveq	#20,d0
	CALLWHD	Delay
	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------------------
; wait for vertical blank

_waitvb:	move.l	a0,-(a7)
	lea	_custom,a0
	move.w	#INTF_VERTB,intreq(a0)
.wvb_loop:	btst	#INTB_VERTB,intreqr+1(a0)
	beq	.wvb_loop
	move.w	#INTF_VERTB,intreq(a0)
	move.l	(a7)+,a0
	rts

;--------------------------------
; proper blitter waits

_blitwait_a5:
	tst.w	dmaconr(a5)
.bw_loop:	tst.b	_ciaa
	tst.b	_ciaa
	btst	#DMAB_BLTDONE-8,dmaconr(a5)
	bne	.bw_loop
	tst.w	dmaconr(a5)
	rts

;--------------------

_bwait_a:	bsr	_blitwait_a5
	move.w	#$100,bltcon0(a5)
	rts

_bwait_b:	bsr	_blitwait_a5
	move.w	#$ffff,bltalwm(a5)
	rts

_bwait_c:	bsr	_blitwait_a5
	move.w	#$1ff,bltcon0(a5)
	rts

_bwait_d:	and.w	#$3ff,d0
	bsr	_blitwait_a5
	move.l	a1,bltdpt(a5)
	rts

_bwait_e:	bsr	_blitwait_a5
	move.l	a0,bltdpt(a5)
	move.l	#$ffffffff,bltafwm(a5)
	rts

_bwait_f:	lea	_custom,a5
	bra	_blitwait_a5

_bwait_g:	bsr	_blitwait_a5
	move.w	#0,bltdmod(a5)
	rts

;==========================================================================
; emulate A500 speed dbf delay loop
; > d0 = dbf counter

_dbfwait:	movem.l	d0-1/a0,-(a7)

	lea	vhposr+_custom,a0
	divu	#40,d0
	bra.s	.dw_loop_start
.dw_loop1:	move.b	(a0),d1
.dw_loop2:	cmp.b	(a0),d1
	beq.s	.dw_loop2
.dw_loop_start:
	dbf	d0,.dw_loop1

.dw_done:	movem.l	(a7)+,d0-1/a0
	move.w	#$ffff,d0
	rts

;==========================================================================

	; load high scores & options

_hiscore_load:
	movem.l	d0-7/a0-6,-(a7)

	; no high score loading for unregged


	; load the high score file if it exists

	lea	_hiscore_name(pc),a0	; load file
	lea	$57a00,a1
	CALLWHD	LoadFileDecrunch
	cmp.l	#$e8,d0	; skip and set defaults if not found
	bne	.hsl_def
	tst.l	d1
	bne	.hsl_def

	; check high score file is ok

	bsr	_hiscore_sum1	; check 1.x legacy checksum
	sub.l	$57a00,d0
	beq	.hsl_done

	bsr	_hiscore_crypt	; decrypt and try again
	bsr	_hiscore_sum2	; check 2.x checksum
	sub.l	$57a00,d0
	beq	.hsl_done

.hsl_def:	lea	_hiscore_def(pc),a0	; initialise high scores to defaults
	lea	$57a00,a1
	CALLWHD	Decrunch
	bsr	_hiscore_save_core	; save new high score file

.hsl_done:	move.l	#"high",$57a00

	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------

	; save high scores & options

_hiscore_save:
	movem.l	d0-7/a0-6,-(a7)

	; no high score saving for unregged


	; if trainers used, save only options

	move.l	_tr_used(pc),d0
	bne	.hss_options_only

	bsr	_hiscore_save_core	; save both scores and options
	bra	.hss_done

.hss_options_only:
	lea	_hiscore_name(pc),a0	; save options only
	lea	$57a54,a1
	move.l	#$94,d0
	move.l	#$54,d1
	CALLWHD	SaveFileOffset

.hss_done:	movem.l	(a7)+,d0-7/a0-6
	rts

;-----

_hiscore_save_core:
	bsr	_hiscore_sum2	; set checksum
	move.l	d0,$57a00

	bsr	_hiscore_crypt	; encrypt

	lea	_hiscore_name(pc),a0	; save file
	lea	$57a00,a1
	move.l	#$e8,d0
	CALLWHD	SaveFile

	bsr	_hiscore_crypt	; decrypt

	move.l	#"high",$57a00	; clear checksum
	rts

;--------------------

	; hiscore lame-o-crypter

_hiscore_crypt:
	movem.l	d0-1/a0,-(a7)
	lea	$57a00,a0
	move.w	#$54-1,d0
	move.l	#$44c6b534,d1
.hsct_loop:	eor.b	d1,(a0)+
	eor.w	d0,d1
	ror.l	d0,d1
	dbf	d0,.hsct_loop
	movem.l	(a7)+,d0-1/a0
	rts

;--------------------

	; calculate the checksum of the high score table data
	; legacy v1.x slave version - sums entire file
	;
	; < d0 = checksum

_hiscore_sum1:
	movem.l	d1/a0,-(a7)

	lea	$57a04,a0
	moveq	#$e0/4-1,d1
	moveq	#0,d0
.hsls_loop:	add.l	(a0)+,d0
	dbf	d1,.hsls_loop

	movem.l	(a7)+,d1/a0
	rts

;-----

	; v2.x slave version - sums only high score data

_hiscore_sum2:
	movem.l	d1/a0,-(a7)

	lea	$57a04,a0
	moveq	#$50/4-1,d1
	moveq	#0,d0
.hsls_loop:	add.l	(a0)+,d0
	dbf	d1,.hsls_loop

	movem.l	(a7)+,d1/a0
	rts

;--------------------

_hiscore_name:
	dc.b	"apidyahigh",0
	EVEN

	; default high score table

	CNOP	0,4
_hiscore_def:
	INCBIN	apidyahighs.rnc
	EVEN

;==========================================================================

_initialise:	movem.l	d0-7/a0-6,-(a7)

	lea	_resload(pc),a1	; save resloader address
	move.l	a0,(a1)

	lea	_ctl_tags(pc),a0	; get config tags
	CALLWHD	Control

	; check we have required WHDLoad version & revision

	move.l	_ct_ver(pc),d0	
	cmp.b	#WHDL_REQVER,d0
	blt	_exit
	bgt	.ini_verok
	move.l	_ct_rev(pc),d0
	cmp.b	#WHDL_REQREV,d0
	blt	_exit
.ini_verok:

	; set CPU and cache options for program

	move.l	#WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_SB|WCPUF_BC|WCPUF_SS,d0
	move.l	#WCPUF_All,d1
	CALLWHD	SetCPU

	; set flag if any trainers active

	move.l	_ct_cust4(pc),d0	; cust4=0 or 1 means start at level 1 => not a trainer!
	beq	.ini_got_lev_tr
	subq.l	#1,d0
.ini_got_lev_tr:
	or.l	_ct_cust1(pc),d0
	or.l	_ct_cust2(pc),d0
	or.l	_ct_cust3(pc),d0
	lea	_tr_used(pc),a0
	move.l	d0,(a0)

	movem.l	(a7)+,d0-7/a0-6
	rts

;==========================================================================

_badver:	and.l	#$ffff,d0
	move.l	#TDREASON_WRONGVER,-(a7)
	bra	_abort

_debug:	clr.l	-(a7)
	clr.l	-(a7)
	move.l	#TDREASON_DEBUG,-(a7)
	bra	_abort

_exit:	move.l	#TDREASON_OK,-(a7)

_abort:      move.l	_resload(pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

;==========================================================================

	CNOP	0,4

	; variables

_resload:    dc.l	0
_game_ver:	dc.l	0
_tr_used:	dc.l	0	; trainers used flag

	; control tags

_ctl_tags:	dc.l	WHDLTAG_VERSION_GET
_ct_ver:	dc.l	0
	dc.l	WHDLTAG_REVISION_GET
_ct_rev:	dc.l	0
	dc.l	WHDLTAG_CUSTOM1_GET	; infinite lives
_ct_cust1:	dc.l	0
	dc.l	WHDLTAG_CUSTOM2_GET	; invulnerability
_ct_cust2:	dc.l	0
	dc.l	WHDLTAG_CUSTOM3_GET	; keep weapons on death
_ct_cust3:	dc.l	0
	dc.l	WHDLTAG_CUSTOM4_GET	; start level 1-5
_ct_cust4:	dc.l	0
	dc.l	WHDLTAG_CUSTOM5_GET
_ct_cust5:	dc.l	0
	dc.l	TAG_DONE,TAG_DONE

	; splash screen info

_wsdata:	dc.b	"data",0
_wsname:	dc.b	"Apidya",0
_wscopy:	dc.b	"1992 Play Byte",0
_wsinfo:	dc.b	"Developed by Kaiko / AUDIOS"
	dc.b	10
	dc.b	10
	dc.b	10
	dc.b	"Installer by Girv"
	dc.b	10
	INCLUDE	Copyright.i
	dc.b	10
	INCLUDE	Version.i
	dc.b	10
	dc.b	10
	dc.b	"1.x by Mr. Larmer and Harry"
	dc.b	10
	dc.b	0
	EVEN

;==========================================================================

	; corrected sample for menu title music

	CNOP	0,4
_smpl:	INCBIN	smpl.rnc
	EVEN

	; alternative memory for level 2 guardian table
	; at $3e190 - seems to be player firing related
	; but overflows and corrupts the next table at
	; $3e258 causing jumps to random locations.
	;
	; 4 tables in use: $3e000,$3e190,$3e258,$3c3e8
	; all are $190 bytes apart from $3e190 which is
	; $c8 bytes - exactly half! something sus there...
	;

	CNOP	0,4
_plv2g_3e190_tab:
	dcb.b	$1a0,-1


;==========================================================================

