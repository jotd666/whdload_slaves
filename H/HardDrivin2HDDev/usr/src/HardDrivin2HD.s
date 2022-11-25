;============================================================================
;$VER: Hard Drivin' 2 slave source 2.01 © 2001-2006 Halibut Software
; This file may not be distributed, reproduced or altered, in full or in
; part, in any way, without prior written permission from the author.
;
; Special license is granted to the administrators of the WHDLoad project
; to dispose of this file as required in the case where reasonable attempts
; to obtain permission from the author have failed.
;
;============================================================================


	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	exec/exec.i
	INCLUDE	dos/dos.i
	INCLUDE	exec/libraries.i
	INCLUDE	exec/memory.i
	INCLUDE	devices/input.i
	INCLUDE	devices/inputevent.i

;============================================================================
CHIP_ONLY
USE_PROFILING

	; kickstart booter
	IFD	CHIP_ONLY
CHIPMEMSIZE = $120000
FASTMEMSIZE = 0
	ELSE
CHIPMEMSIZE	equ $80000
FASTMEMSIZE	equ $80000
	ENDC
NUMDRIVES	equ 1
WPDRIVES	equ %0000
BLACKSCREEN
;BOOTBLOCK
BOOTDOS
BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
CACHE
;DEBUG
;DISKSONBOOT
DOSASSIGN
FONTHEIGHT	equ 8
HDINIT
;HRTMON
IOCACHE	equ 1024
;MEMFREE	equ $200
;NEEDFPU
;POINTERTICKS equ 1
SETPATCH
STACKSIZE	equ 16384
;TRDCHANGEDISK

slv_Version	equ	17
slv_Flags	equ	WHDLF_ClearMem|WHDLF_Examine
slv_keyexit	equ	$59

	INCLUDE	whdload/kick13.s


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
;============================================================================

	dc.b	"$VER: Hard Drivin' II WHDLoad Slave "
	DECL_VERSION
	dc.b	0
	
slv_config
	dc.b	"BW;"
    dc.b    "C2:B:load track editor;"
    dc.b    "C3:B:disable speed regulation;"			
    dc.b	0
	
	EVEN

;============================================================================

_bootearly:	movem.l	d0-7/a0-6,-(a7)

	; get config tags

	lea	_ctl_tags(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Control(a2)

	; get crc and version of main executable
	bsr	_getcrc

	lea	_code_ver(pc),a0
	cmp.w	#$535e,d0
	beq	.be_isv1
	cmp.w	#$aa49,d0
	beq	.be_isv2
	cmp.w	#$704b,d0
	beq	.be_isv3
	cmp.w	#$b65f,d0
	beq	.be_isv4
	cmp.w	#$fedb,d0
	beq	.be_isv4
	cmp.w	#$ba1b,d0
	beq	.be_isv5
	bra	_badver
.be_isv1:	move.w	#1,(a0)
	bra	.be_done
.be_isv2:	move.w	#2,(a0)
	bra	.be_done
.be_isv3:	move.w	#3,(a0)
	bra	.be_done
.be_isv4:	move.w	#4,(a0)
	bra	.be_done
.be_isv5:	move.w	#5,(a0)

.be_done:	movem.l	(a7)+,d0-7/a0-6	; all done
	rts

;==========================================================================

_bootdos:	; open dos.library

	lea	_dosname(pc),a1
	moveq	#0,d0
	move.l	4.w,a6
	jsr	_LVOOpenLibrary(a6)
	lea	_dosbase(pc),a0
	move.l	d0,(a0)
	beq	_faildos


		; align exe memory on round value
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #$20000-$1D658,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC

	
	; load game or track editor depending on CUSTOM2 value
	lea	_game_nam(pc),a0
	move.l	load_track_editor(pc),d0
	beq	.bd_got_progname
	lea	_edit_nam(pc),a0
.bd_got_progname:
	move.l	a0,d1	; d1 = filename
	move.l	_dosbase(pc),a6
	jsr	_LVOLoadSeg(a6)
	lea	_code_seg(pc),a0
	move.l	d0,(a0)+	; store seglist bcpl pointer
	beq	_failexe

	lsl.l	#2,d0	; store start address
	addq.l	#4,d0
	blitz
	nop
	move.l	d0,(a0)

	IFD	USE_PROFILING
	move.l	#$10000,d0
	lea		$100.W,a1
	bsr		init_allocated_address	
	bsr		install_profiler_vbl_hook
	ENDC

	; patch loaded program

	move.l	load_track_editor(pc),d0
	beq	.bd_patch_game

	; patch track editor

.bd_patch_editor:
	move.w	_code_ver(pc),d0	; get patchlist for editor version
	cmp.w	#1,d0
	beq	.bdpe_isv1
	cmp.w	#2,d0
	beq	.bdpe_isv2
	cmp.w	#3,d0
	beq	.bdpe_isv3
	cmp.w	#4,d0
	beq	.bdpe_isv4
	cmp.w	#5,d0
	beq	.bdpe_isv5
	bra	_badver
.bdpe_isv1:	lea	_bd_ple_v1(pc),a0
	bra	.bdpe_patch
.bdpe_isv2:	lea	_bd_ple_v2(pc),a0
	bra	.bdpe_patch
.bdpe_isv3:	lea	_bd_ple_v3(pc),a0
	bra	.bdpe_patch
.bdpe_isv4:	bsr	_bd_v4_preproc	; v4 specific pre-process
	lea	_bd_ple_v4(pc),a0
	bra	.bdpe_patch
.bdpe_isv5:	bsr	_bd_v5_preproc	; v5 specific pre-process
	lea	_bd_ple_v5(pc),a0

.bdpe_patch:	move.l	_code_seg(pc),a1	; patch editor
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)

	move.l	_code_exe(pc),a1	; patch editor blitter waits
	move.l	#116000,d0
	;bsr	_bd_patch_blitwait

	bra	.bd_start

	; patch game

.bd_patch_game:
	move.w	_code_ver(pc),d0	; get patchlist for game version
	cmp.w	#1,d0
	beq	.bdpg_isv1
	cmp.w	#2,d0
	beq	.bdpg_isv2
	cmp.w	#3,d0
	beq	.bdpg_isv3
	cmp.w	#4,d0
	beq	.bdpg_isv4
	cmp.w	#5,d0
	beq	.bdpg_isv5
	bra	_badver
.bdpg_isv1:	lea	_bd_plg_v1(pc),a0
	bra	.bdpg_patch
.bdpg_isv2:	lea	_bd_plg_v2(pc),a0
	bra	.bdpg_patch
.bdpg_isv3:	bsr	_bd_v3_preproc	; v3 specific pre-process
	lea	_bd_plg_v3(pc),a0
	bra	.bdpg_patch
.bdpg_isv4:	bsr	_bd_v4_preproc	; v4 specific pre-process
	lea	_bd_plg_v4(pc),a0
	bra	.bdpg_patch
.bdpg_isv5:	bsr	_bd_v5_preproc	; v5 specific pre-process
	lea	_bd_plg_v5(pc),a0

.bdpg_patch:	move.l	_code_seg(pc),a1	; patch game
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)

	move.l	_code_exe(pc),a1	; patch game blitter waits
	move.l	#91600,d0
	;bsr	_bd_patch_blitwait

.bd_start:	; set CPU and cache options for program

	; start game

	moveq	#0,d0	; argc
	sub.l	a0,a0	; argv

	pea.l	_exit(pc)	; push whdl exit address
	move.l	_code_exe(pc),-(a7)	; push game start address
	rts

;--------------------
; search for blitter wait loops and replace with jsr/nop/nop
; > a1=search address
; > d0=search length

_bd_patch_blitwait:
	movem.l	d0-7/a0-6,-(a7)

.pbw_loop:	cmp.l	#$00060002,(a1)
	bne	.pbw_next
	cmp.l	#$670260f6,4(a1)
	bne	.pbw_next

	move.w	#$4eb9,-2(a1)
	pea	_blitwait(pc)
	move.l	(a7)+,(a1)
	move.l	#$4e714e71,4(a1)

.pbw_next:	addq.l	#2,a1
	subq.l	#2,d0
	bpl	.pbw_loop

	; all done

	bsr	_fcache
	movem.l	(a7)+,d0-7/a0-6
	rts	

;--------------------
; preprocess v3 executable
; decryption / relocation routine from v3 copylock

_bd_v3_preproc:
	movem.l	d0-7/a0-6,-(a7)

	; setup decryption key

	move.l	#$7B8669F8,d0	; d0 = copylock key
	move.l	#$00000000,d1
	move.l	#$CC548C5C,d2
	move.l	#$FFFFFFDA,d3
	move.l	#$CF3B0040,d4
	move.l	#$BF200400,d5

	move.l	_code_exe(pc),a6	; a6 = encrypted data
	add.l	#$95c,a6
	move.l	a6,-(a7)

	move.l	#$5000,d6	; d6 = length to decrypt

	; decryption loop

.v3pp_loop:	rol.l	d0,d1
	add.l	d1,d2
	ror.l	d2,d3
	add.l	d3,d4
	ror.l	d4,d5
	add.l	d5,d0
	add.l	d0,(a6)+
	subq.l	#4,d6
	bne	.v3pp_loop

	; relocate decrypted exe

	move.l	(a7),a6	; a6 = start of (now decrypted) hunks
	move.l	_code_exe(pc),d6	; d6 = destination address

	cmp.w	#$3e9,2(a6)
	bne	.v3pp_reloc_done
	move.l	4(a6),d0
	lsl.l	#2,d0
	lea	8(a6),a1
	lea	0(a1,d0.l),a2
	cmp.l	#$3ec,(a2)+	; check for RELOC32
	bne	.v3pp_reloc_done

.v3pp_884:	move.l	(a2)+,d1	; d1 = number of offsets
	beq	.v3pp_reloc_done	; exit on zero
	move.l	(a2)+,d0	; d0 = hunk number offsets apply to
	bsr	.v3pp_8a2	; a0 = hunk start address

	move.l	a0,d2
	tst.l	-4(a2)
	bne	.v3pp_896
	move.l	d6,d2
.v3pp_896:	move.l	(a2)+,d0	; d0 = offset
	add.l	d2,0(a1,d0.l)
	subq.l	#1,d1
	bne	.v3pp_896
	bra	.v3pp_884

	; get start address for hunk number in d0
	; > d0 = hunk number
	; < a0 = start address
.v3pp_8a2:	move.l	d6,a0
   	subq.l	#4,a0
   	tst.l	d0
   	beq	.v3pp_8b4
.v3pp_8aa:	move.l	(a0),a0
   	add.l	a0,a0
   	add.l	a0,a0
   	subq.l	#1,d0
   	bne	.v3pp_8aa
.v3pp_8b4:	addq.l	#4,a0
   	rts

.v3pp_reloc_done:
	; copy relocated code to final address
	; this copies the game code over the copylock code

	move.l	(a7)+,a0	; a0 = source
	addq.l	#8,a0
	move.l	_code_exe(pc),a1	; a1 = dest
	move.l	#$1537c,d0	; d0 = length
.v3pp_move:	move.l	(a0)+,(a1)+
	subq.l	#4,d0
	bne	.v3pp_move

	; all done

	bsr	_fcache
	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------
; preprocess v4 executable
; decrunch packed (propack rnc1) exe file

_bd_v4_preproc:
	movem.l	d0-7/a0-6,-(a7)

	; intercept after decrunch

	move.l	_code_exe(pc),a0
	add.l	#$25c,a0
	move.w	#$4ef9,(a0)+
	pea.l	.v4pp_1(pc)
	move.l	(a7)+,(a0)

	; run decrunch

	move.l	_code_exe(pc),-(a7)
	rts

.v4pp_1:	movem.l	(a7)+,d0-7/a0-6	; discard decrunch regs

	; update game seglist and exe pointers with address of decrunched data

	move.l	(a7)+,d0	; d0 = new exe address

	lea	_code_exe(pc),a0	; store new start address
	move.l	d0,(a0)

	lea	_code_seg(pc),a0	; store new seglist bcpl pointer
	subq.l	#4,d0
	lsr.l	#2,d0
	move.l	d0,(a0)

	; all done

	bsr	_fcache
	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------
; preprocess v5 executable
; decrunch packed (imploder) exe file

_bd_v5_preproc:
	movem.l	d0-7/a0-6,-(a7)

	; intercept at decrunch call to explode.library

	move.l	_code_exe(pc),a0
	add.l	#$16,a0
	move.w	#$4ef9,(a0)+
	pea.l	.v5pp_1(pc)
	move.l	(a7)+,(a0)

	; start game

	move.l	_code_exe(pc),-(a7)
	rts

.v5pp_1:	; about to call explode.library-$1e
	; d0 = explode.library base

	move.l	d0,a6	; a6 = explode.library base
	move.l	-$1e+2(a6),a0	; a0 = addr of decrunch code

	move.w	#$4e71,4(a0)	; nop out "move.l (a7)+,a5" = get addr of crunched data

	move.w	#$4ef9,$1c(a0)	; intercept after decrunch
	pea	.v5pp_2(pc)
	move.l	(a7)+,$1e(a0)

	move.l	_code_exe(pc),a5	; a5 = addr of crunched data
	add.l	#$1c,a5

	jmp	(a0)	; decrunch

.v5pp_2:	; after decrunch, code starts at _code_exe

	bsr	_fcache	; flush caches, explode.library has problems on 040/060

	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------
	; game patchlists

_bd_plg_common:
	PL_START

	PL_L	$6a,$256c8fd2	; remove sprpt read access
	PL_L	$70,$256c8fd2	; = move.l -$702e(a4),$xxxx(a2)
	PL_L	$76,$256c8fd2
	PL_L	$82,$256c8fd2
	PL_L	$88,$256c8fd2
	PL_L	$8e,$256c8fd2

	PL_PS	$d4,_fixscreenflip	; patch screen flipper

	PL_END

;--------------------

_bd_plg_v1:	PL_START

	PL_P	$4b5e,_copylock	; patch copylock

	PL_NOP	$14010,28	; remove stack access weirdness during startup

	PL_PSS	$a2a,_dbfwait1,8	; patch dbf delay loops
	PL_PSS	$725a,_dbfwait2,8

	PL_P	$477a,_smc_txt1_set	; patch smc text printing
	PL_PSS	$484c,_smc_txt1,10
	PL_PSS	$492e,_smc_txt1,10

	PL_P	$4386,_smc_gfx1_set	; patch smc line drawing
	PL_PSS	$4552,_smc_gfx1,8
	PL_PSS	$4590,_smc_gfx1,8
	PL_PSS	$45d8,_smc_gfx1,8
	PL_PSS	$465a,_smc_gfx1,8
	PL_PSS	$4704,_smc_gfx1,8

	PL_PSS	$13e74,_fixbcd,8	; patch bad bcd-add call

	PL_PS	$88a4,_chggear1	; patch new gear selection
	PL_PS	$88ac,_chggear2
	PL_PS	$88b4,_chggear3
	PL_PS	$88bc,_chggear4
	PL_PS	$88c4,_chggear5

	PL_PS	$977a,_hiscore_load	; install hiscore loading & saving
	PL_PSS	$6270,_hiscore_save_v1,4

	PL_NEXT	_bd_plg_common
	PL_END

;----------
; v2 identical to v3, except v3 exe is encrypted by copylock, rather than having
; copylock embedded in it. after decryption, v2 and v3 exes are the same apart
; from v3 having the embedded copylock disabled.
;
; v3 identical to v4, except v4 exe is not encrypted but is packed by propack rnc1.
; after decrunch, v4 exe is identical to v3 apart from v4 using trap# vectors to call
; ICE! decrunch routines for game data.
;
; v3 identical to v5, except v5 exe is not encrypted but is packed by explode.library (Turbo Imploder 4.0)
; after decrunch, v5 exe is identical to v3.
;
; so, basically, v2-5 are the same
;

_bd_plg_v2345_common:
	PL_START
	PL_P	$4bb4,_copylock	; this copylock isn't run in v3-5 but the result is checked!
			; the original code has already patched out the protection
			; and hardcoded a sucessful result
	PL_NOP	$14110,28
	PL_PSS	$a80,_dbfwait1,8
	PL_PSS	$72ba,_dbfwait2,8
	PL_P	$47d0,_smc_txt1_set
	PL_PSS	$48a2,_smc_txt1,10
	PL_PSS	$4984,_smc_txt1,10
	PL_P	$43dc,_smc_gfx1_set
	PL_PSS	$45a8,_smc_gfx1,8
	PL_PSS	$45e6,_smc_gfx1,8
	PL_PSS	$462e,_smc_gfx1,8
	PL_PSS	$46b0,_smc_gfx1,8
	PL_PSS	$475a,_smc_gfx1,8
	PL_PSS	$13f74,_fixbcd,8
	PL_PS	$8904,_chggear1
	PL_PS	$890c,_chggear2
	PL_PS	$8914,_chggear3
	PL_PS	$891c,_chggear4
	PL_PS	$8924,_chggear5
	PL_PS	$9854,_hiscore_load
	PL_PSS	$62d0,_hiscore_save_v2,4
	PL_NEXT	_bd_plg_common
	PL_END

;-----

_bd_plg_v2:	PL_START
	PL_NEXT	_bd_plg_v2345_common
	PL_END

;-----

_bd_plg_v3:	PL_START
	PL_NEXT	_bd_plg_v2345_common
	PL_END

;-----

_bd_plg_v4:	PL_START
	PL_P	$14fe6,_ice_trap2	; patch data unpacker trap vector usage
	PL_P	$15014,_ice_trap3
	PL_P	$15040,_ice_trap0
	PL_NEXT	_bd_plg_v2345_common
	PL_END

;-----

_bd_plg_v5:	PL_START
	PL_NEXT	_bd_plg_v2345_common
	PL_END
	
;--------------------
	; track editor patchlists

_bd_ple_common:
	PL_START

	PL_P	$42a6,_copylock	; patch copylock

	PL_L	$7e,$256c9898	; remove sprpt read access
	PL_L	$84,$256c9898	; = move.l -$6768(a4),$xxxx(a2)
	PL_L	$8a,$256c9898
	PL_L	$96,$256c9898
	PL_L	$9c,$256c9898
	PL_L	$a2,$256c9898

	PL_R	$454	; remove startup message

	PL_NOP	$124c,6	; remove blthog use
	PL_NOP	$132e,6
	PL_NOP	$13d4,6
	PL_NOP	$15a4,6

	PL_P	$34a8,_smc_gfx1_set	; patch smc line drawing
	PL_PSS	$3674,_smc_gfx1,8
	PL_PSS	$36b2,_smc_gfx1,8
	PL_PSS	$36fa,_smc_gfx1,8
	PL_PSS	$377c,_smc_gfx1,8
	PL_PSS	$3826,_smc_gfx1,8

	PL_P	$3a36,_smc_txt1_set	; patch smc text printing
	PL_PSS	$3862,_smc_txt1,10
	PL_PSS	$3930,_smc_txt1,10

	PL_END

;----------
; v2 & v3 are identical
; v1,2,3 have the same patch list even though the v1 exe is different from v2 & v3
; v4 has mostly the same patchlist apart from one

_bd_ple_v1:	PL_START
	PL_NOP	$196d0,28	; remove stack access weirdness during startup
	PL_NEXT	_bd_ple_common
	PL_END
;----------

_bd_ple_v2:	PL_START
	PL_NEXT	_bd_plg_v1
	PL_END

;----------

_bd_ple_v3:	PL_START
	PL_NEXT	_bd_plg_v1
	PL_END

;----------

_bd_ple_v4:	PL_START

	PL_NOP	$196da,28	; remove stack access weirdness during startup

	PL_P	$1a5b0,_ice_trap2	; patch data unpacker trap vector usage
	PL_P	$1a5de,_ice_trap3
	PL_P	$1a60a,_ice_trap0

	PL_NEXT	_bd_ple_common
	PL_END

;----------

_bd_ple_v5:	PL_START
	PL_NEXT	_bd_plg_v1
	PL_END

;==========================================================================
; fake copylock & return

_copylock:	move.l	#$70b60e8e,d0
	move.l	d0,$24.w
	rts

;--------------------------------
; proper blitter wait

_blitwait:	movem.l	d0-1/a0,-(a7)
	lea	_custom,a0

	; no speed control for unregged

	; do speed control delay

	move.l	speed_regulation(pc),d0
	bra	.bw_nodelay
.bw_delay1:	move.b	vhposr(a0),d1
.bw_delay2:	cmp.b	vhposr(a0),d1
	beq	.bw_delay2
	dbf	d0,.bw_delay1
.bw_nodelay

	; wait for blitter now too

	BLITWAIT	a0

	movem.l	(a7)+,d0-1/a0
	rts

;--------------------------------
; emulate A500 speed dbf delay loop

_dbfwait:	movem.l	d0-1/a0,-(a7)

	lea	vhposr+_custom,a0
	divu	#40,d0
	bra	.dw_loop_start
.dw_loop1:	move.b	(a0),d1
.dw_loop2:	cmp.b	(a0),d1
	beq	.dw_loop2
.dw_loop_start:
	dbf	d0,.dw_loop1

.dw_done:	movem.l	(a7)+,d0-1/a0
	move.w	#$ffff,d0
	rts


;----------

_dbfwait1:	move.l	d0,-(a7)
	move.l	#$186a0,d0
	move.l	d0,-$a(a5)
	bsr.s	_dbfwait
	move.l	(a7)+,d0
	rts
;----------

_dbfwait2:	move.l	d0,-(a7)
	move.l	#$3e8,d0
	move.l	d0,-$c(a5)
	bsr.s	_dbfwait
	move.l	(a7)+,d0
	rts

;--------------------------------

	; set colour for smc_txt1 code to print in = d0
_smc_txt1_set:
	movem.l	d0/a0-1,-(a7)

	lea	_smc_txt1_tab(pc),a0	; a0 = per-colour function list
	and.w	#$f,d0
	add.w	d0,d0
	add.w	d0,d0
	lea	0(a0,d0.w),a1
	add.l	(a1),a0	; a0 = function pointer

	lea	_smc_txt1_ptr(pc),a1	; store pointer
	move.l	a0,(a1)

	movem.l	(a7)+,d0/a0-1

	move.l	(a7)+,a2	; back to original code
	rts	

;----------

_smc_txt1:	move.l	_smc_txt1_ptr(pc),-(a7)	; call smc replacement
	rts

;----------

	CNOP	0,4
_smc_txt1_ptr:
	dc.l	0	; current smc_txt1 function

_smc_txt1_tab:
	dc.l	_smc_txt1_0-_smc_txt1_tab	; list of all smc_txt1 functions
	dc.l	_smc_txt1_1-_smc_txt1_tab
	dc.l	_smc_txt1_2-_smc_txt1_tab
	dc.l	_smc_txt1_3-_smc_txt1_tab
	dc.l	_smc_txt1_4-_smc_txt1_tab
	dc.l	_smc_txt1_5-_smc_txt1_tab
	dc.l	_smc_txt1_6-_smc_txt1_tab
	dc.l	_smc_txt1_7-_smc_txt1_tab
	dc.l	_smc_txt1_8-_smc_txt1_tab
	dc.l	_smc_txt1_9-_smc_txt1_tab
	dc.l	_smc_txt1_a-_smc_txt1_tab
	dc.l	_smc_txt1_b-_smc_txt1_tab
	dc.l	_smc_txt1_c-_smc_txt1_tab
	dc.l	_smc_txt1_d-_smc_txt1_tab
	dc.l	_smc_txt1_e-_smc_txt1_tab
	dc.l	_smc_txt1_f-_smc_txt1_tab

	INCLUDE	slave_smc_txt1.s	; code for all smc_txt1 functions

	IFD	USE_PROFILING
	include	profiler.s
	ENDC
	
;--------------------------------

	; set colour for smc_gfx1 code to print in = d4
_smc_gfx1_set:
	movem.l	d4/a0-1,-(a7)

	lea	_smc_gfx1_tab(pc),a0	; a0 = per-colour function list
	and.w	#$f,d4
	add.w	d4,d4
	add.w	d4,d4
	lea	0(a0,d4.w),a1
	add.l	(a1),a0	; a0 = function pointer

	lea	_smc_gfx1_ptr(pc),a1	; store pointer
	move.l	a0,(a1)

	movem.l	(a7)+,d4/a0-1

	move.l	(a7)+,d4	; back to original code
	rts	

;----------

_smc_gfx1:	move.l	_smc_gfx1_ptr(pc),-(a7)	; call smc replacement
	rts

;----------

	CNOP	0,4
_smc_gfx1_ptr:
	dc.l	0	; current smc_gfx1 function

_smc_gfx1_tab:
	dc.l	_smc_gfx1_0-_smc_gfx1_tab	; list of all smc_gfx1 functions
	dc.l	_smc_gfx1_1-_smc_gfx1_tab
	dc.l	_smc_gfx1_2-_smc_gfx1_tab
	dc.l	_smc_gfx1_3-_smc_gfx1_tab
	dc.l	_smc_gfx1_4-_smc_gfx1_tab
	dc.l	_smc_gfx1_5-_smc_gfx1_tab
	dc.l	_smc_gfx1_6-_smc_gfx1_tab
	dc.l	_smc_gfx1_7-_smc_gfx1_tab
	dc.l	_smc_gfx1_8-_smc_gfx1_tab
	dc.l	_smc_gfx1_9-_smc_gfx1_tab
	dc.l	_smc_gfx1_a-_smc_gfx1_tab
	dc.l	_smc_gfx1_b-_smc_gfx1_tab
	dc.l	_smc_gfx1_c-_smc_gfx1_tab
	dc.l	_smc_gfx1_d-_smc_gfx1_tab
	dc.l	_smc_gfx1_e-_smc_gfx1_tab
	dc.l	_smc_gfx1_f-_smc_gfx1_tab

	INCLUDE	slave_smc_gfx1.s	; code for all smc_gfx1 functions

;--------------------------------
; game screen flipper
; this sledgehammer fixes a bug in the game

_fixscreenflip:
	movem.l	d0/a0-1,-(a7)

	lea	.fc1a_count(pc),a0
	tst.b	(a0)
	bmi	.fc1a_copydone
	subq.b	#1,(a0)
	bpl	.fc1a_copydone

	; copy back screen contents to front screen

	move.w	#DMAF_RASTER|DMAF_COPPER,_custom+dmacon

	move.l	-$50f4(a4),a0
	move.l	-$50f0(a4),a1
	move.w	#1000-1,d0
.fc1a_copyloop:
	REPT	8
	move.l	(a0)+,(a1)+
	ENDR
	dbf	d0,.fc1a_copyloop

	move.w	#DMAF_SETCLR|DMAF_RASTER|DMAF_COPPER,_custom+dmacon

.fc1a_copydone:
	movem.l	(a7)+,d0/a0-1

	move.l	-$50f0(a4),-$50f4(a4)
	rts

.fc1a_count:	dc.b	1
	EVEN

;--------------------------------

	; fix for call to bcd-add that wrongly passes .w instead of .l

_fixbcd:	pea.l	-$4eec(a4)
	move.l	#1,-(a7)	; was: move.w #1,-(a7)
	jsr	-$7ee4(a4)
	addq.l	#8,a7	; was: addq.w #6,a7
	rts

;--------------------------------

	; fix for gear changing - dont change if already in chosen gear
	;                         else you get screen corruption

_chggear1:	moveq	#1,d0	; want to change to 1st
	bra	_chggear_main

_chggear2:	moveq	#2,d0	;  "        "       2nd
	bra	_chggear_main

_chggear3:	moveq	#3,d0	;  "        "       3rd
	bra	_chggear_main

_chggear4:	moveq	#4,d0	;  "        "       4th
	bra	_chggear_main

_chggear5:	moveq	#5,d0	;  "        "       neutral

_chggear_main:
	cmp.w	-$4f34(a4),d0	; already in requested gear?
	beq	.ngm_nochange	; skip if yes
	move.b	d0,-$4f4d(a4)	;   otherwise store
	rts

.ngm_nochange:
	clr.b	-$4f4d(a4)	; no "new" gear
	rts

;--------------------------------

	; hiscore table loader / initialiser

_hiscore_load:
	lea	-$4ba4(a4),a0	; get pointer to hiscore data
	move.l	a0,a3

	movem.l	d0-7/a0-2/a4-6,-(a7)
	move.l	a3,-(a7)

	lea	.hsl_did_load(pc),a0	; skip if already loaded
	tst.w	(a0)
	bne	.hsl_done
	st	(a0)

	lea	_hiscore_name(pc),a0	; load hiscore data
	move.l	(a7),a1
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)
	tst.l	d1	; create default table if couldnt load
	bne	.hsl_use_default_table
	cmp.l	#380,d0
	bne	.hsl_use_default_table

	move.l	(a7),a0	; decrypt loaded table
	bsr	_hiscore_crypt

	bra	.hsl_done

.hsl_use_default_table:
	lea	.hsl_default_table(pc),a0 ; initialise to default table
	move.l	(a7),a1
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)

.hsl_done:	move.l	(a7)+,a3
	movem.l	(a7)+,d0-7/a0-2/a4-6
	rts

;-----

.hsl_did_load:
	dc.w	0	; did we load already?

.hsl_default_table:
	INCBIN	default_hiscore.RNC	; compressed default empty table
	EVEN

;-----

	; hiscore saver

_hiscore_save_v1:
	move.l	d6,-(a7)	; call the hiscore name entry function
	move.w	d4,-(a7)
	pea.l	_hss_updated_table(pc)	; return address
	move.l	_code_exe(pc),-(a7)
	add.l	#$615e,(a7)
	rts

_hiscore_save_v2:
	move.l	d6,-(a7)
	move.w	d4,-(a7)
	pea.l	_hss_updated_table(pc)
	move.l	_code_exe(pc),-(a7)
	add.l	#$61be,(a7)
	rts

_hss_updated_table:
	addq.l	#6,a7
	movem.l	d0-7/a0-6,-(a7)

	lea	-$4ba4(a4),a0	; get pointer to hiscore data
	move.l	a0,-(a7)

	bsr	_hiscore_crypt	; encrypt and save table

	move.w	#380,d0
	lea	_hiscore_name(pc),a0
	move.l	(a7),a1
	move.l	_resload(pc),a2
	jsr	resload_SaveFile(a2)

	move.l	(a7)+,a0
	bsr	_hiscore_crypt

	move.w	#100,d0	; short delay (looks better :)
.hss_delay:	waitvb
	dbf	d0,.hss_delay

.hss_done:	movem.l	(a7)+,d0-7/a0-6
	rts

;-----

	; hiscore lame-o-crypter

_hiscore_crypt:
	movem.l	d0-1/a0,-(a7)
	move.w	#380-1,d0
	move.l	#$70b60e8e,d1
.hsct_loop:	eor.b	d1,(a0)+
	eor.w	d0,d1
	ror.l	d0,d1
	dbf	d0,.hsct_loop
	movem.l	(a7)+,d0-1/a0
	rts

;-----

_hiscore_name:
	dc.b	"hiscore.dat",0
	EVEN

;--------------------------------
; flush caches

_fcache:	movem.l	d0-7/a0-6,-(a7)
	move.l	_resload(pc),a0
	jsr	resload_FlushCache(a0)
	movem.l	(a7)+,d0-7/a0-6
	rts

;==========================================================================
; data depacker (ICE!) routines for v4, originally hooked in via trap# vectors

	; trap #0
	; dos.Read replacement
	; transparently unpacks ICE! packed files loaded through dos.Read

_ice_trap0:	move.l	_dosbase(pc),a6

	; > d1 = filehandle
	; > d2 = buffer
	; > d3 = length
	pea	(a0)
	lea	.t0_ptr(pc),a0
	move.l	d2,(a0)
	move.l	(a7)+,a0
	jsr	_LVORead(a6)
	; < d0 = length read

	pea	(a0)
	lea	.t0_len(pc),a0
	move.l	d0,(a0)
	move.l	.t0_ptr(pc),a0
	bsr	.t0_unpack_main
	tst.l	d0
	bne	.l13A
	move.l	.t0_len(pc),d0
.l13A	move.l	(a7)+,a0
	rts

	; ICE! data unpacker
	; > a0 = packed data
	; < d0 = unpacked length, 0 on error

.t0_unpack_main
	movem.l	d0-d7/a0-a6,-(a7)
	lea	$78(a0),a4
	move.l	a4,a6
	bsr	.t0_getlong
	cmpi.l	#$49434521,d0	; "ICE!"
	bne	.t0_done
	bsr	.t0_getlong
	lea	-8(a0,d0.l),a5
	bsr	.t0_getlong
	move.l	d0,(a7)
	add.l	d0,a6
	move.l	a6,a1
	lea	.l348(pc),a3
	moveq	#$77,d0
.l170	move.b	-(a1),-(a3)
	dbf	d0,.l170
	move.l	a6,a3
	move.b	-(a5),d7
	bsr	.l1E4
	move.l	a3,a5
	bsr	.l210
	bcc	.l1BC
	move.w	#$F9F,d7
	bsr	.l210
	bcc	.l196
	moveq	#$F,d0
	bsr	.l21A
	move.w	d1,d7
.l196	moveq	#3,d6
.l198	move.w	-(a3),d4
	moveq	#3,d5
.l19C	add.w	d4,d4
	addx.w	d0,d0
	add.w	d4,d4
	addx.w	d1,d1
	add.w	d4,d4
	addx.w	d2,d2
	add.w	d4,d4
	addx.w	d3,d3
	dbf	d5,.l19C
	dbf	d6,.l198
	movem.w	d0-d3,(a3)
	dbf	d7,.l196
.l1BC	movem.l	(a7),d0-d7/a0-a3
.l1C0	move.b	(a4)+,(a0)+
	subq.l	#1,d0
	bne	.l1C0
	lea	.l348(pc),a3
	moveq	#$77,d0
.l1CC	move.b	-(a3),-(a5)
	dbf	d0,.l1CC

.t0_done	movem.l	(a7)+,d0-d7/a0-a6
	rts

	; unaligned safe read next 4 bytes from (a0)+ -> d0
.t0_getlong	moveq	#3,d1
.l1DA	lsl.l	#8,d0
	move.b	(a0)+,d0
	dbf	d1,.l1DA
	rts

.l1E4	bsr	.l210
	bcc	.l20A
	moveq	#0,d1
	bsr	.l210
	bcc	.l204
	lea	.l2A8(pc),a1
	moveq	#4,d3
.l1F4	move.l	-(a1),d0
	bsr	.l21A
	swap	d0
	cmp.w	d0,d1
	dbne	d3,.l1F4
	add.l	$14(a1),d1
.l204	move.b	-(a5),-(a6)
	dbf	d1,.l204
.l20A	cmpa.l	a4,a6
	bgt	.l22C
	rts

.l210	add.b	d7,d7
	bne	.l218
	move.b	-(a5),d7
	addx.b	d7,d7
.l218	rts

.l21A	moveq	#0,d1
.l21C	add.b	d7,d7
	bne	.l224
	move.b	-(a5),d7
	addx.b	d7,d7
.l224	addx.w	d1,d1
	dbf	d0,.l21C
	rts

.l22C	lea	.l2BC(pc),a1
	moveq	#3,d2
.l232	bsr	.l210
	dbcc	d2,.l232
	moveq	#0,d4
	moveq	#0,d1
	move.b	1(a1,d2.w),d0
	ext.w	d0
	bmi	.l246
	bsr	.l21A
.l246	move.b	6(a1,d2.w),d4
	add.w	d1,d4
	beq	.l270
	lea	.l2C6(pc),a1
	moveq	#1,d2
.l254	bsr	.l210
	dbcc	d2,.l254
	moveq	#0,d1
	move.b	1(a1,d2.w),d0
	ext.w	d0
	bsr	.l21A
	add.w	d2,d2
	add.w	6(a1,d2.w),d1
	bpl	.l282
	sub.w	d4,d1
	bra	.l282

.l270	moveq	#0,d1
	moveq	#5,d0
	moveq	#-1,d2
	bsr	.l210
	bcc	.l27E
	moveq	#8,d0
	moveq	#$3F,d2
.l27E	bsr	.l21A
	add.w	d2,d1
.l282	lea	2(a6,d4.w),a1
	add.w	d1,a1
	move.b	-(a1),-(a6)
.l28A	move.b	-(a1),-(a6)
	dbf	d4,.l28A
	bra	.l1E4

	dc.w	$7FFF,$000E
	dc.w	$00FF,$0007
	dc.w	$0007,$0002
	dc.w	$0003,$0001
	dc.w	$0003,$0001
.l2A8:
	dc.b	$00,$00,$01,$0D,$00,$00,$00,$0E
	dc.b	$00,$00,$00,$07,$00,$00,$00,$04
	dc.b	$00,$00,$00,$01

.l2BC	dc.b	$09,$01,$00,$FF,$FF,$08,$04,$02,$01,$00
.l2C6	dc.b	$0B,$04,$07,$00,$01,$1F,$FF,$FF,$00,$1F

	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
	dc.w	0,0,0,0
.l348:

.t0_len	dc.l	0
.t0_ptr	dc.l	0

;--------------------------

	; trap #2
	; dos.Examine replacement
	; normal dos.Examine, but fileinfoblock will be initialised with *unpacked* file length

_ice_trap2:	move.l	_dosbase(pc),a6

	; > d1 = lock
	; > d2 = fileinfoblock
	pea	(a0)
	lea	_ice_fib(pc),a0
	move.l	d2,(a0)
	move.l	(a7)+,a0
	jsr	_LVOExamine(a6)
	; < d0 = success

	movem.l	d0-d7/a0-a6,-(a7)	; save dos.Examine results

	; open file

	move.l	_ice_nam(pc),d1	; d1 = filename
	move.l	#MODE_OLDFILE,d2	; d2 = mode
	jsr	_LVOOpen(a6)
	move.l	d0,d7	; d7 = filehandle

	; read 12 byte file header

	lea	_ice_hdrbuf(pc),a0	; a0 = header buffer
	clr.l	(a0)

	move.l	d0,d1	; d1 = filehandle
	move.l	a0,d2	; d2 = header buffer
	moveq	#12,d3	; d3 = header length
	jsr	_LVORead(a6)	; dos.Read

	; close file

	move.l	d7,d1
	jsr	_LVOClose(a6)

	; examine file header for packer tag
	; if packed then put unpacked length into fib_Size

	lea	_ice_hdrbuf(pc),a0
	cmpi.l	#$49434521,(a0)	; "ICE!"
	bne	.t2_done
	move.l	_ice_fib(pc),a1
	move.l	8(a0),$7C(a1)

.t2_done:	; restore dos.Examine results and return

	movem.l	(a7)+,d0-d7/a0-a6
	rts

;--------------------------

	; trap #3
	; dos.Lock replacement

_ice_trap3:	move.l	_dosbase(pc),a6

	; > d1 = name
	; > d2 = access mode
	pea	(a0)
	lea	_ice_nam(pc),a0	; save name
	move.l	d1,(a0)
	move.l	(a7)+,a0
	jsr	_LVOLock(a6)
	; < d0 = lock
	rts

;--------------------------

	CNOP	0,4
_ice_fib:	dc.l	0
_ice_nam:	dc.l	0
_ice_hdrbuf:	dcb.b	12

;==========================================================================
; get crc of main executable

_getcrc:	movem.l	d1-7/a0-6,-(a7)

	lea	_game_nam(pc),a0	; get file size
	move.l	_resload(pc),a2
	jsr	resload_GetFileSizeDec(a2)
	lea	_code_siz(pc),a0
	move.l	d0,(a0)
	beq	_failcrc

	moveq	#0,d1	; allocate memory to hold file
	move.l	4.w,a6
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	beq	_failmem
	lea	_code_mem(pc),a0
	move.l	d0,(a0)

	lea	_game_nam(pc),a0	; load file
	move.l	d0,a1
	move.l	_resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)

	move.l	_code_siz(pc),d0	; calculate crc
	move.l	_code_mem(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	lea	_code_crc(pc),a0	; store pointer
	move.w	d0,(a0)

	move.l	_code_mem(pc),a1	; free memory
	move.l	_code_siz(pc),d0
	move.l	4.w,a6
	jsr	_LVOFreeMem(a6)
	lea	_code_mem(pc),a0
	clr.l	(a0)

	movem.l	(a7)+,d1-7/a0-6

	moveq	#0,d0	; set crc for return
	move.w	_code_crc(pc),d0
	rts

;==========================================================================

_badver:	and.l	#$ffff,d0
	move.l	#TDREASON_WRONGVER,-(a7)
	bra	_abort

;-----

_failmem:	lea	.msg(pc),a0
	bra	_failmsg
.msg:	dc.b	"Failed to allocate memory",0
	EVEN

_faildos:	lea	.msg(pc),a0
	bra	_failmsg
.msg:	dc.b	"Failed to open dos.library",0
	EVEN

_failcrc:	lea	.msg(pc),a0
	bra	_failmsg
.msg:	dc.b	"Failed to CRC executable",0
	EVEN

_failexe:	lea	.msg(pc),a0
	bra	_failmsg
.msg:	dc.b	"Failed to load executable",0
	EVEN

_failmsg:	clr.l	-(a7)
	move.l	a0,-(a7)
	move.l	#TDREASON_FAILMSG,-(a7)
	bra	_abort
;-----

_debug:	clr.l	-(a7)
	clr.l	-(a7)
	move.l	#TDREASON_DEBUG,-(a7)
	bra	_abort

;-----

_exit:	move.l	#TDREASON_OK,-(a7)

_abort:      move.l	_resload(pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

;==========================================================================

	CNOP	0,4
_ctl_tags:	dc.l	WHDLTAG_BUTTONWAIT_GET
_ct_bwait:	dc.l	0
	dc.l	WHDLTAG_CUSTOM2_GET
load_track_editor:	dc.l	0
	dc.l	WHDLTAG_CUSTOM3_GET
speed_regulation:	dc.l	0
	dc.l	TAG_DONE,TAG_DONE

_dosbase:	dc.l	0

_code_seg:	dc.l	0
_code_exe:	dc.l	0

_code_siz:	dc.l	0
_code_mem:	dc.l	0
_code_crc:	dc.w	0
_code_ver:	dc.w	0
_game_nam:	dc.b	"hd2",0	; game program name
_edit_nam:	dc.b	"edit",0	; track editor program name
	EVEN

;--------------------------------

	CNOP	0,4
slv_CurrentDir:
	dc.b	"data",0

slv_name:	dc.b	"Hard Drivin' II: Drive Harder"
		IFD	CHIP_ONLY
		dc.b	" (debug/chip mode)"
		ENDC
		dc.b	0

slv_copy:	dc.b	"1991 Tengen / Atari / Domark",0

slv_info:	dc.b	10,"adapted by Girv",10
	DECL_VERSION
	dc.b	10
	
	dc.b	10,0

;==========================================================================
