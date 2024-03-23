;============================================================================
;$VER: HardDrivinWHD slave source 2.03 © 2001-2008 Halibut Software;
; This file may not be distributed, reproduced or altered, in full or in
; part, in any way, without prior written permission from the author.
;
; Special license is granted to the administrators of the WHDLoad project
; to dispose of this file as required in the case where reasonable attempts
; to obtain permission from the author have failed.
;
;============================================================================


	INCDIR	INCLUDE:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	whdgirv.i
	;INCLUDE	rawkeys.i
	;INCLUDE	exec/exec_lib.i
	;INCLUDE	dos/dos_lib.i
	INCLUDE	exec/libraries.i
	INCLUDE	exec/memory.i

	INCLUDE	exec/memory.i
	INCLUDE	lvo/exec.i
;============================================================================

WHDL_REQVER:	equ 16
WHDL_REQREV:	equ 5

;============================================================================

	; kickstart booter

CHIPMEMSIZE:	equ $80000
FASTMEMSIZE:	equ $80000
NUMDRIVES:	equ 1
WPDRIVES:	equ %0000
BLACKSCREEN
;BOOTBLOCK
;BOOTDOS
BOOTEARLY
CBDOSLOADSEG
;CBDOSREAD
CACHE
;DEBUG
;DISKSONBOOT
;DOSASSIGN
;FONTHEIGHT:	equ 8
HDINIT
;HRTMON
IOCACHE:	equ 1024
;MEMFREE:	equ $200
;NEEDFPU
;POINTERTICKS: equ 1
SETPATCH
STACKSIZE:	equ 16384
;TRDCHANGEDISK

RAWKEY_F10 = $59
RAWKEY_Q = $10

slv_Version:	equ	WHDL_REQVER
slv_Flags:	equ	WHDLF_ClearMem|WHDLF_Examine
slv_keyexit:	equ	RAWKEY_F10

	INCLUDE	whdload/kick13.s



DECL_VERSION:MACRO
	dc.b	"3.0"
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

	dc.b	"$VER: Hard Drivin' WHDLoad Slave "
	DECL_VERSION
	dc.b	0
	EVEN

;============================================================================

_bootearly:	movem.l	d0-7/a0-6,-(a7)

	; get config tags

	lea	_ctl_tags(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_Control(a2)

	; delay loop patches need to jump to somewhere < $10000 so they
             ; can fit into 4 bytes.
             ; try to AllocAbs a small chunk of memory between $400
             ; and $10000 to hold the redirect code

	moveq	#32,d0	; d0 = size
	lea	$1000,a1	; a1 = address
	move.l	4.w,a6	; a6 = execbase
.be_alloclow:
	movem.l	d0/a1/a6,-(a7)	; try to alloc
	jsr	_LVOAllocAbs(a6)
	tst.l	d0
	bne.s	.beql_gotit	; skip if success
.beql_next:	movem.l	(a7)+,d0/a1/a6
	lea	$10(a1),a1	; try address $10 bigger
	cmp.l	#$10000,a1
	blt.s	.be_alloclow
	bra	_failmem

.beql_gotit:	lea	12(a7),a7	; forget variables

	lea	_dbfw_ptr(pc),a0	; store address
	addq.l	#8,d0
	move.l	d0,(a0)

	move.l	d0,a0	; patch in redirect jump
	move.w	#$4ef9,(a0)+
	pea.l	_dbfwait(pc)
	move.l	(a7)+,(a0)+

	movem.l	(a7)+,d0-7/a0-6	; all done
	rts

;==========================================================================
; d0 = BSTR name of the loaded program as BCPL string
; d1 = BPTR segment list of the loaded program as BCPL pointer

_cb_dosLoadSeg:
	movem.l	d0-1/a0-1,-(a7)

	lsl.l	#2,d0	; a0 = name
	move.l	d0,a0
	moveq	#0,d0	; d0 = length
	move.b	(a0)+,d0

	cmp.b	#10,d0	; looking for "HardDrivin"
	bne.s	.dls_done
	cmp.b	#"H",(a0)+
	bne.s	.dls_done
	cmp.b	#"a",(a0)+
	bne.s	.dls_done
	cmp.b	#"r",(a0)+
	bne.s	.dls_done
	cmp.b	#"d",(a0)+
	bne.s	.dls_done
	cmp.b	#"D",(a0)+
	bne.s	.dls_done
	cmp.b	#"r",(a0)+
	bne.s	.dls_done
	cmp.b	#"i",(a0)+
	bne.s	.dls_done
	cmp.b	#"v",(a0)+
	bne.s	.dls_done
	cmp.b	#"i",(a0)+
	bne.s	.dls_done
	cmp.b	#"n",(a0)+
	bne.s	.dls_done

	; exec.OldOpenLibrary is called after game has loaded and decrunched
	; redirect exec.OldOpenLibrary to _p0_OldOpenLibrary

	move.l	4.w,a0
	lea	_LVOOldOpenLibrary+2(a0),a0
	lea	_exec_OldOpenLibrary(pc),a1
	move.l	(a0),(a1)
	pea.l	_p0_OldOpenLibrary(pc)
	move.l	(a7)+,(a0)
	bsr	_fcache

.dls_done:	movem.l	(a7)+,d0-1/a0-1	; all done
	tst.l	d0
	rts

;==========================================================================
; A1 = library name CSTR

_p0_OldOpenLibrary:
	movem.l	d0-7/a0-6,-(a7)

	cmp.b	#"d",(a1)+	; looking for "dos.library"
	bne		.ool_do_open
	cmp.b	#"o",(a1)+
	bne		.ool_do_open
	cmp.b	#"s",(a1)+
	bne		.ool_do_open
	cmp.b	#".",(a1)+
	bne		.ool_do_open

	move.l	4.w,a0	; restore original library vector
	lea	_LVOOldOpenLibrary+2(a0),a0
	move.l	_p0_OldOpenLibrary(pc),(a0)
	bsr	_fcache

	; get game version

	bsr	_getcrc	; get crc of main executable
	cmp.w	#$4027,d0
	beq.s	.ool_isv1
	cmp.w	#$b2f6,d0
	beq.s	.ool_isv2
	cmp.w	#$cbe0,d0
	beq.s	.ool_isv3
	cmp.w	#$9f0a,d0
	beq.s	.ool_isv4
	cmp.w	#$19e2,d0
	beq.s	.ool_isv5
	illegal
	bra	_badver
.ool_isv1:	lea	_pl0_v1(pc),a0	; v1 - original release
	move.l	#-$11a4e,a1
	bra.s	.ool_gotver
.ool_isv2:	lea	_pl0_v2(pc),a0	; v2 - TNT compilation release
	move.l	#-$1176a,a1
	bra.s	.ool_gotver
.ool_isv3:	lea	_pl0_v3(pc),a0	; v3 - WOF compilation release
	move.l	#-$1176a,a1
	bra.s	.ool_gotver
.ool_isv4:	lea	_pl0_v4(pc),a0	; v4 - ReSpray budget release
	move.l	#-$11760,a1
	bra.s	.ool_gotver
.ool_isv5:	lea	_pl0_v5(pc),a0	; v5 - RM compilation release
	move.l	#-$1176a,a1
.ool_gotver:

	; patch executable
	; a1 = -code length
	; a0 = patch list

	move.l	a1,-(a7)
	add.l	$40(a7),a1	; a1 = return address-code length = code start
	move.l	a1,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_Patch(a2)
	;move.l	(a7)+,a0
	;bra	_debug

	move.l	(a7)+,a0	; a0 = code start
	move.l	(a7)+,d0	; d0 = code length
	neg.l	d0
	bsr	_p0_fix_blitwait	; patch blit waits
	bsr	_p0_fix_dbfdelay	; patch dbf loops

	lea	_code_start(pc),a1
	move.l	a0,(a1)+
	move.l	d0,(a1)+

	; set CPU and cache options for program

	move.l	#WCPUF_Base_WT|WCPUF_Exp_WT|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_SB|WCPUF_BC|WCPUF_SS,d0
	move.l	#WCPUF_All,d1
	move.l	_resload(pc),a2
	jsr	resload_SetCPU(a2)

.ool_do_open:	
	bsr	_fcache	; call original library vector
	movem.l	(a7)+,d0-7/a0-6
	move.l	_exec_OldOpenLibrary(pc),-(a7)
	rts

;==========================================================================

_pl0_v1:	PL_START
	PL_P	$48e2,_copylock	; patch copylock

	PL_R	$440	; remove startup message
	PL_B	$64ab,0	; remove "look out for more tracks next year" message

	PL_NOP	$1426,6	; remove blthog use
	PL_NOP	$1508,6
	PL_NOP	$15ae,6
	PL_NOP	$177e,6

	PL_L	$74,$256c8fd2	; remove sprpt read access
	PL_L	$7a,$256c8fd2	; = move.l -$702e(a4),$xxxx(a2)
	PL_L	$80,$256c8fd2
	PL_L	$8c,$256c8fd2
	PL_L	$92,$256c8fd2
	PL_L	$98,$256c8fd2

	PL_PSS	$4e8,_dbfwait1,8	; patch dbf delay loops
	PL_PSS	$c32,_dbfwait2,8
	PL_PSS	$6f34,_dbfwait3,8

	PL_P	$3e90,_smc_txt1_set	; patch smc text printing
	PL_PSS	$3f58,_smc_txt1,10
	PL_PSS	$403a,_smc_txt1,10

	PL_P	$3af6,_smc_gfx1_set	; patch smc line drawing
	PL_PSS	$3cc2,_smc_gfx1,8
	PL_PSS	$3d00,_smc_gfx1,8
	PL_PSS	$3d48,_smc_gfx1,8
	PL_PSS	$3dca,_smc_gfx1,8
	PL_PSS	$3e74,_smc_gfx1,8

	PL_PS	$476e,_fixaud2vol	; patch aud2vol byte access

	PL_PSS	$11982,_fixbcd_v1,8	; patch bad bcd-add call

	PL_PS	$7cbe,_cgear1_v1	; patch new gear selection
	PL_PS	$7cc6,_cgear2_v1
	PL_PS	$7cce,_cgear3_v1
	PL_PS	$7cd6,_cgear4_v1
	PL_PS	$7cde,_cgear5_v1

	PL_PS	$1222,_quitkey_v1	; install game quit key (Q)

	PL_PS	$86d6,_hiscore_load_v1	; install hiscore loading & saving
	PL_PSS	$5f7c,_hiscore_save_v1,4
	PL_END

;--------------------

_pl0_v2:	PL_START
	PL_P	$492c,_copylock

	PL_R	$44e
	PL_B	$60eb,0

	PL_NOP	$1440,6
	PL_NOP	$1522,6
	PL_NOP	$15c8,6
	PL_NOP	$1798,6

	PL_L	$7e,$256c8fc6
	PL_L	$84,$256c8fc6
	PL_L	$8a,$256c8fc6
	PL_L	$96,$256c8fc6
	PL_L	$9c,$256c8fc6
	PL_L	$a2,$256c8fc6

	PL_PSS	$4f6,_dbfwait1,8
	PL_PSS	$c40,_dbfwait2,8
	PL_PSS	$6bba,_dbfwait3,8

	PL_P	$3ed0,_smc_txt1_set
	PL_PSS	$3f98,_smc_txt1,10
	PL_PSS	$407a,_smc_txt1,10

	PL_P	$3b36,_smc_gfx1_set
	PL_PSS	$3d02,_smc_gfx1,8
	PL_PSS	$3d40,_smc_gfx1,8
	PL_PSS	$3d88,_smc_gfx1,8
	PL_PSS	$3e0a,_smc_gfx1,8
	PL_PSS	$3eb4,_smc_gfx1,8

	PL_PS	$47ae,_fixaud2vol

	PL_PSS	$1169e,_fixbcd_v2,8

	PL_PS	$7a50,_cgear1_v2
	PL_PS	$7a58,_cgear2_v2
	PL_PS	$7a60,_cgear3_v2
	PL_PS	$7a68,_cgear4_v2
	PL_PS	$7a70,_cgear5_v2

	PL_PS	$123c,_quitkey_v2

	PL_PS	$8494,_hiscore_load_v2
	PL_PSS	$5b9e,_hiscore_save_v2,4

	PL_END

;--------------------

_pl0_v3:	PL_START

	PL_P	$126c0,_gk90Examine	; patch data unpacker trap# instructions
	PL_P	$126ee,_gk90Lock
	PL_P	$1271a,_gk90Read

	PL_NEXT	_pl0_v2	; v3 is otherwise identical to v2

	PL_END

;--------------------

_pl0_v4:	PL_START
	PL_P	$4922,_copylock

	PL_R	$44e	;* = same as v2
	PL_B	$60e1,0

	PL_NOP	$1440,6	;*
	PL_NOP	$1522,6	;*
	PL_NOP	$15c8,6	;*
	PL_NOP	$1798,6	;*

	PL_L	$7e,$256c8fd2	;*
	PL_L	$84,$256c8fd2	;*
	PL_L	$8a,$256c8fd2	;*
	PL_L	$96,$256c8fd2	;*
	PL_L	$9c,$256c8fd2	;*
	PL_L	$a2,$256c8fd2	;*

	PL_PSS	$4f6,_dbfwait1,8	;*
	PL_PSS	$c40,_dbfwait2,8	;*
	PL_PSS	$6bb0,_dbfwait3,8

	PL_P	$3ed0,_smc_txt1_set	;*
	PL_PSS	$3f98,_smc_txt1,10	;*
	PL_PSS	$407a,_smc_txt1,10	;*

	PL_P	$3b36,_smc_gfx1_set	;*
	PL_PSS	$3d02,_smc_gfx1,8	;*
	PL_PSS	$3d40,_smc_gfx1,8	;*
	PL_PSS	$3d88,_smc_gfx1,8	;*
	PL_PSS	$3e0a,_smc_gfx1,8	;*
	PL_PSS	$3eb4,_smc_gfx1,8	;*

	PL_PS	$47ae,_fixaud2vol	;*

	PL_PSS	$11694,_fixbcd_v4,8

	PL_PS	$7a46,_cgear1_v4
	PL_PS	$7a4e,_cgear2_v4
	PL_PS	$7a56,_cgear3_v4
	PL_PS	$7a5e,_cgear4_v4
	PL_PS	$7a66,_cgear5_v4

	PL_PS	$123c,_quitkey_v4	;*

	PL_PS	$848a,_hiscore_load_v4
	PL_PSS	$5b94,_hiscore_save_v4,4
	PL_END

;--------------------

_pl0_v5:	PL_START

	PL_NEXT	_pl0_v2	; v5 is identical to v2

	PL_END

;----------------------------------------
; search for blitter wait loops and replace
; > a0=search address
; > d0=search length

_p0_fix_blitwait:
	movem.l	d0-2/a0,-(a7)

	move.l	#$00060002,d1
	move.l	#$670260f6,d2

.p0bw_loop:	cmp.l	(a0),d1
	bne.s	.p0bw_next
	cmp.l	4(a0),d2
	bne.s	.p0bw_next

	move.w	#$4eb9,-2(a0)	; jsr _blitwait : nop : nop
	pea	_blitwait(pc)
	move.l	(a7)+,(a0)
	move.l	#$4e714e71,4(a0)

.p0bw_next:	addq.l	#2,a0
	subq.l	#2,d0
	bpl.s	.p0bw_loop

	movem.l	(a7)+,d0-2/a0
	rts	

;--------------------
; search for dbf delay loops and replace
; > a0=search address
; > d0=search length

_p0_fix_dbfdelay:
	movem.l	d0-1/a0,-(a7)

	move.l	#$51c8fffe,d1

.p0dd_loop:	cmp.l	(a0),d1
	bne.s	.p0dd_next

	move.w	#$4eb8,(a0)	; jsr $xxxx.w
	move.w	_dbfw_ptr+2(pc),2(a0)

.p0dd_next:	addq.l	#2,a0
	subq.l	#2,d0
	bpl.s	.p0dd_loop

	movem.l	(a7)+,d0-1/a0
	rts	

;==========================================================================

	; fake copylock & return

_copylock:	move.l	#$2a113417,d0
	move.l	d0,$24.w
	rts

;--------------------------------

	; proper blitter wait

_blitwait:	movem.l	d0-1/a0,-(a7)

	lea	_custom,a0

	move.l	_ct_ct2(pc),d0	; do speed control delay
	ble.s	.bw_nodelay
.bw_delay1:	move.b	vhposr(a0),d1
.bw_delay2:	cmp.b	vhposr(a0),d1
	beq.s	.bw_delay2
	dbf	d0,.bw_delay1

.bw_nodelay:	BLITWAIT	a0

	movem.l	(a7)+,d0-1/a0
	rts

;--------------------------------

	; emulate dbf delay loops

_dbfwait1:	move.l	d0,-(a7)
	move.l	#$c350,d0
	move.l	d0,-$4(a5)
	bsr		_dbfwait
	move.l	(a7)+,d0
	rts

;----------

_dbfwait2:	move.l	d0,-(a7)
	move.l	#$186a0,d0
	move.l	d0,-$a(a5)
	bsr		_dbfwait
	move.l	(a7)+,d0
	rts
;----------

_dbfwait3:	move.l	d0,-(a7)
	move.l	#$3e8,d0
	move.l	d0,-$e(a5)
	bsr		_dbfwait
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

	; fix for byte write to aud2vol

_fixaud2vol:	move.l	d0,-(a7)
	move.b	3(a6),d0
	lsl.w	#8,d0
	move.w	d0,8(a5)
	move.l	(a7)+,d0
	rts

;--------------------------------

	; fix for call to bcd-add that wrongly passes .w instead of .l

_fixbcd_v1:	pea	-$686c(a4)
	move.l	#5,-(a7)	; was: move.w #1,-(a7)
	jsr	-$7f02(a4)
	addq.l	#8,a7	; was: addq.w #6,a7
	rts

;----------

_fixbcd_v2:	pea	-$6838(a4)
	move.l	#5,-(a7)
	jsr	-$7f08(a4)
	addq.l	#8,a7
	rts

;----------

_fixbcd_v4:	pea	-$6838(a4)
	move.l	#5,-(a7)
	jsr	-$7f08(a4)
	addq.l	#8,a7
	rts

;--------------------------------

	; fix for gear changing
	; if you change gear to the gear you are currently in
	; you get screen corruption

_cgear1_v1:	moveq	#1,d0	; want to change to 1st
	bra.s	_cgear_main_v1
_cgear2_v1:	moveq	#2,d0	;  "        "       2nd
	bra.s	_cgear_main_v1
_cgear3_v1:	moveq	#3,d0	;  "        "       3rd
	bra.s	_cgear_main_v1
_cgear4_v1:	moveq	#4,d0	;  "        "       4th
	bra.s	_cgear_main_v1
_cgear5_v1:	moveq	#5,d0	;  "        "       neutral
_cgear_main_v1:
	movem.l	a0-2,-(a7)
	lea	-$66ca(a4),a1	; a1 = current gear
	lea	-$66e3(a4),a2	; a2 = new gear
	bra.s	_cgear_main

;----------

_cgear1_v2:	moveq	#1,d0
	bra.s	_cgear_main_v2
_cgear2_v2:	moveq	#2,d0
	bra.s	_cgear_main_v2
_cgear3_v2:	moveq	#3,d0
	bra.s	_cgear_main_v2
_cgear4_v2:	moveq	#4,d0
	bra.s	_cgear_main_v2
_cgear5_v2:	moveq	#5,d0
_cgear_main_v2:
	movem.l	a0-2,-(a7)
	lea	-$6696(a4),a1
	lea	-$66af(a4),a2
	bra.s	_cgear_main

;----------

_cgear1_v4:	moveq	#1,d0
	bra.s	_cgear_main_v4
_cgear2_v4:	moveq	#2,d0
	bra.s	_cgear_main_v4
_cgear3_v4:	moveq	#3,d0
	bra.s	_cgear_main_v4
_cgear4_v4:	moveq	#4,d0
	bra.s	_cgear_main_v4
_cgear5_v4:	moveq	#5,d0
_cgear_main_v4:
	movem.l	a0-2,-(a7)
	lea	-$6696(a4),a1
	lea	-$66af(a4),a2

;----------

_cgear_main:	cmp.w	(a1),d0	; already in requested gear?
	beq.s	.cg_nochg	; skip if yes

	move.b	d0,(a2)	; set new gear
	bra.s	.cg_done

.cg_nochg:	clr.b	(a2)	; no new gear

.cg_done:	movem.l	(a7)+,a0-2
	rts

;--------------------------------

	; abort game key handler

_quitkey_v1:	move.w	-$7038(a4),d0	; get rawkey
	ext.l	d0
	cmp.b	#RAWKEY_Q,d0	; clear flag if Q pressed
	bne.s	.qk_done
	clr.b	-$522c(a4)
.qk_done:	rts

;----------

_quitkey_v2:	move.w	-$7044(a4),d0
	ext.l	d0
	cmp.b	#RAWKEY_Q,d0
	bne.s	.qk_done
	clr.b	-$51fe(a4)
.qk_done:	rts

;----------

_quitkey_v4:	move.w	-$7044(a4),d0
	ext.l	d0
	cmp.b	#RAWKEY_Q,d0
	bne.s	.qk_done
	clr.b	-$51fe(a4)
.qk_done:	rts

;--------------------------------

	; hiscore table loader / initialiser

_hiscore_load_v1:
	lea	-$64de(a4),a0	; a0 = hiscore data
	bra.s	_hsl_main

;----------

_hiscore_load_v2:
	lea	-$64b0(a4),a0
	bra.s	_hsl_main

;----------

_hiscore_load_v4:
	lea	-$64b0(a4),a0

;----------

_hsl_main:	move.l	a0,a3
	movem.l	d0-7/a0-2/a4-6,-(a7)
	move.l	a3,-(a7)

	lea	.hsl_did_load(pc),a0	; skip if already loaded
	tst.w	(a0)
	bne.s	.hsl_done
	st	(a0)

	lea	_hiscore_name(pc),a0	; load hiscore data
	move.l	(a7),a1
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)
	tst.l	d1	; create default table if couldnt load
	bne.s	.hsl_use_default_table
	cmp.l	#380,d0
	bne.s	.hsl_use_default_table

	move.l	(a7),a0	; decrypt loaded table
	bsr	_hiscore_crypt

	bra.s	.hsl_done

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

;--------------------------------

	; hiscore saver

_hiscore_save_v1:
	move.l	d6,-(a7)	; call the hiscore name entry function
	move.w	d4,-(a7)
	pea.l	.hss_upd(pc)	; fake return address
	move.l	_code_start(pc),-(a7)
	add.l	#$5e74,(a7)
	rts

.hss_upd:	addq.l	#6,a7
	movem.l	d0-7/a0-6,-(a7)
	lea	-$64de(a4),a0	; a0 = hiscore data
	bra.s	_hss_main

;----------

_hiscore_save_v2:
	move.l	d6,-(a7)
	move.w	d4,-(a7)
	pea.l	.hss_upd(pc)
	move.l	_code_start(pc),-(a7)
	add.l	#$5a94,(a7)
	rts

.hss_upd:	addq.l	#6,a7
	movem.l	d0-7/a0-6,-(a7)
	lea	-$64b0(a4),a0
	bra.s	_hss_main

;----------

_hiscore_save_v4:
	move.l	d6,-(a7)
	move.w	d4,-(a7)
	pea.l	.hss_upd(pc)
	move.l	_code_start(pc),-(a7)
	add.l	#$5a8a,(a7)
	rts

.hss_upd:	addq.l	#6,a7
	movem.l	d0-7/a0-6,-(a7)
	lea	-$64b0(a4),a0

;----------

_hss_main:	; encrypt hiscore table in-place, save it and decrypt it again
	; a0 = hiscore table

	move.l	a0,-(a7)	; encrypt
	bsr	_hiscore_crypt

	move.w	#380,d0	; save
	lea	_hiscore_name(pc),a0
	move.l	(a7),a1
	move.l	_resload(pc),a2
	jsr	resload_SaveFile(a2)

	move.l	(a7)+,a0	; decrypt
	bsr	_hiscore_crypt

	moveq	#100,d0	; short delay (looks better :)
.hss_wait:	waitvb
	dbf	d0,.hss_wait

	movem.l	(a7)+,d0-7/a0-6
	rts

;--------------------------------

	; hiscore lame-o-crypt to stop the file editor kiddies

_hiscore_crypt:
	movem.l	d0-1/a0,-(a7)
	move.w	#380-1,d0
	move.l	#$2a113417,d1
.hsct_loop:	eor.b	d1,(a0)+
	eor.w	d0,d1
	ror.l	d0,d1
	dbf	d0,.hsct_loop
	movem.l	(a7)+,d0-1/a0
	rts

;--------------------------------

_hiscore_name:
	dc.b	"hiscore.dat",0
	EVEN

;==========================================================================
; GK90 unpacker routines
; Only used by v3, originally called from TRAP instructions in the game

	; dos.Lock (trap #0)

_gk90Lock:	move.l	-$34a(a4),a6
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	#MODE_OLDFILE,d2
	jsr	_LVOOpen(a6)
	tst.l	d0
	beq.s	.done
	move.l	d0,d1
	move.l	d0,-(a7)
	lea	_gk90Info(pc),a2
	move.l	a2,d2
	moveq	#$C,d3
	jsr	_LVORead(a6)
	move.l	(a7)+,d1
	jsr	_LVOClose(a6)
.done:	movem.l	(a7)+,d0-d7/a0-a6
	jsr	_LVOLock(a6)
	rts

;--------------------------------

	; dos.Examine (trap #1)

_gk90Examine:
	move.l	-$34a(a4),a6
	move.l	d2,$100.w
	jsr	_LVOExamine(a6)
	tst.l	d0
	beq	_failGK90
	movem.l	d0/a0,-(a7)
	lea	_gk90Info(pc),a0
	cmpi.l	#"GK90",(a0)
	bne.s	.done
	moveq	#$78,d0
	add.l	8(a0),d0
	move.l	$100.w,a0
	move.l	d0,$7C(a0)
.done:	movem.l	(a7)+,d0/a0
	rts

;--------------------------------

	; dos.Read (trap #2)

_gk90Read:	move.l	-$34a(a4),a6
	move.l	d2,$100.w
	jsr	_LVORead(a6)
	movem.l	d0-d7/a0-a6,-(a7)
	movea.l	$100.w,a0
	lea	$78(a0),a1
	cmpi.l	#"GK90",(a0)+
	bne	.done
	move.l	a1,-(a7)
	movea.l	a1,a4
	movea.l	a1,a6
	move.l	(a0)+,d0
	lea	0(a0,d0.l),a5
	adda.l	(a0),a6
	move.l	(a0),d5
	lea	-$78(a6),a0
	movea.l	a0,a3
	lea	_gk90Info(pc),a1
	moveq	#$77,d0
.lb110	move.b	(a0)+,(a1)+
	dbf	d0,.lb110
	moveq	#3,d0
.lb118	move.b	-(a5),d7
	ror.l	#8,d7
	dbf	d0,.lb118
.lb120	bsr.s	.lb178
	bcc.s	.lb146
	moveq	#0,d1
	bsr.s	.lb178
	bcc.s	.lb140
	lea	.lb224(pc),a1
	moveq	#4,d3
.lb130	move.l	-(a1),d0
	bsr.s	.lb19E
	swap	d0
	cmp.w	d0,d1
	dbne	d3,.lb130
	add.l	$14(a1),d1
.lb140	move.b	-(a5),-(a6)
	dbf	d1,.lb140
.lb146	cmpa.l	a4,a6
	bgt.s	.lb1AC
	movea.l	(a7)+,a0
	lea	-$78(a0),a1
	move.l	d5,$100.w
.lb154	move.b	(a0)+,(a1)+
	subq.l	#1,d5
	bne.s	.lb154
	lea	_gk90Info(pc),a0
	moveq	#$77,d0
.lb160	move.b	(a0)+,(a3)+
	dbf	d0,.lb160
	clr.l	(a0)
.done	movem.l	(a7)+,d0-d7/a0-a6
	move.l	$100.w,d0
	rts

;----------

.lb172	pea	.lb1A4(pc)
	bra.s	.lb17E
.lb178	add.l	d7,d7
	beq.s	.lb17E
	rts
.lb17E	move.w	a5,d7
	andi.b	#1,d7
	bne.s	.lb18C
	move.l	-(a5),d7
	addx.l	d7,d7
	rts
.lb18C	move.l	-5(a5),d7
	lsl.l	#8,d7
	move.b	-(a5),d7
	subq.l	#3,a5
	add.l	d7,d7
	bset	#0,d7
	rts
.lb19E	moveq	#0,d1
.lb1A0	add.l	d7,d7
	beq.s	.lb172
.lb1A4	addx.w	d1,d1
	dbf	d0,.lb1A0
	rts
.lb1AC	lea	.lb238(pc),a1
	moveq	#3,d2
.lb1B2	bsr.s	.lb178
	dbcc	d2,.lb1B2
	moveq	#0,d4
	moveq	#0,d1
	move.b	1(a1,d2.w),d0
	ext.w	d0
	bmi.s	.lb1C6
	bsr.s	.lb19E
.lb1C6	move.b	6(a1,d2.w),d4
	add.w	d1,d4
	beq.s	.lb1EC
	lea	.lb242(pc),a1
	moveq	#1,d2
.lb1D4	bsr.s	.lb178
	dbcc	d2,.lb1D4
	moveq	#0,d1
	move.b	1(a1,d2.w),d0
	ext.w	d0
	bsr.s	.lb19E
	add.w	d2,d2
	add.w	6(a1,d2.w),d1
	bra.s	.lb1FE
.lb1EC	moveq	#0,d1
	moveq	#5,d0
	moveq	#0,d2
	bsr.s	.lb178
	bcc.s	.lb1FA
	moveq	#8,d0
	moveq	#$40,d2
.lb1FA	bsr.s	.lb19E
	add.w	d2,d1
.lb1FE	lea	2(a6,d4.w),a1
	adda.w	d1,a1
	move.b	-(a1),-(a6)
.lb206	move.b	-(a1),-(a6)
	dbf	d4,.lb206
	bra	.lb120

	dc.w	$7FFF,$000E,$00FF,$0007
	dc.w	$0007,$0002,$0003,$0001
	dc.w	$0003,$0001
.lb224:	dc.w	$0000,$010D
	dc.w	$0000,$000E,$0000,$0007
	dc.w	$0000,$0004,$0000,$0001

.lb238:	dc.w	$0901,$00FF,$FF08,$0402,$100

.lb242:	dc.w	$0b04,$0700,$0120,$0000,$0020

_gk90Info:	dcb.b	12

;==========================================================================
; get crc of main executable
; v2 and v3 are nearly identical so we crc the whole file to be safe

_getcrc:	movem.l	d1-7/a0-6,-(a7)

	lea	.gc_nam(pc),a0	; get file size
	move.l	_resload(pc),a2
	jsr	resload_GetFileSizeDec(a2)
	lea	.gc_siz(pc),a0
	move.l	d0,(a0)
	beq	_failexe

	moveq	#0,d1	; allocate memory to hold file
	move.l	4.w,a6
	jsr	_LVOAllocMem(a6)
	tst.l	d0
	beq	_failmem
	lea	.gc_mem(pc),a0
	move.l	d0,(a0)

	lea	.gc_nam(pc),a0	; load file
	move.l	d0,a1
	move.l	_resload(pc),a2
	jsr	resload_LoadFileDecrunch(a2)

	move.l	.gc_siz(pc),d0	; calculate crc
	move.l	.gc_mem(pc),a0
	move.l	_resload(pc),a2
	jsr	resload_CRC16(a2)
	lea	.gc_crc(pc),a0	; store pointer
	move.w	d0,(a0)

	move.l	.gc_mem(pc),a1	; free memory
	move.l	.gc_siz(pc),d0
	move.l	4.w,a6
	jsr	_LVOFreeMem(a6)
	lea	.gc_mem(pc),a0
	clr.l	(a0)

	movem.l	(a7)+,d1-7/a0-6

	moveq	#0,d0	; set crc for return
	move.w	.gc_crc(pc),d0
	rts

.gc_siz:	dc.l	0
.gc_mem:	dc.l	0
.gc_crc:	dc.w	0
.gc_nam:	dc.b	"HardDrivin",0
	EVEN

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
; flush caches

_fcache:	movem.l	d0-7/a0-6,-(a7)
	move.l	_resload(pc),a0
	jsr	resload_FlushCache(a0)
	movem.l	(a7)+,d0-7/a0-6
	rts

;==========================================================================

_badver:	and.l	#$ffff,d0
	move.l	#TDREASON_WRONGVER,-(a7)
	bra		_abort

;-----

_failGK90:	lea	.msg(pc),a0
	bra.s	_failmsg
.msg:	dc.b	"GK90 unpacker failed",0
	EVEN

_failmem:	lea	.msg(pc),a0
	bra.s	_failmsg
.msg:	dc.b	"Failed to allocate memory",0
	EVEN

_failexe:	lea	.msg(pc),a0
	bra.s	_failmsg
.msg:	dc.b	"Failed to load main executable",0
	EVEN

_failmsg:	clr.l	-(a7)
	move.l	a0,-(a7)
	move.l	#TDREASON_FAILMSG,-(a7)
	bra.s	_abort
;-----

_debug:	clr.l	-(a7)
	clr.l	-(a7)
	move.l	#TDREASON_DEBUG,-(a7)
	bra.s	_abort

;-----

_exit:	move.l	#TDREASON_OK,-(a7)

_abort:      move.l	_resload(pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

;==========================================================================

	CNOP	0,4
_ctl_tags:	dc.l	WHDLTAG_CUSTOM2_GET
_ct_ct2:	dc.l	0
	dc.l	0

_exec_OldOpenLibrary:
	dc.l	0

_dbfw_ptr:	dc.l	0

_code_start:	dc.l	0
_code_len:	dc.l	0

;--------------------------------

	CNOP	0,4
slv_CurrentDir:
	dc.b	"data",0

slv_name:	dc.b	"Hard Drivin'",0

slv_copy:	dc.b	"1989 Tengen / Atari / Domark",0

slv_info:	dc.b	10,"Installer by Girv & JOTD",10,10
	INCLUDE	Copyright.i
	dc.b	10
	dc.b	"Version "
	DECL_VERSION
	dc.b	10,0

;==========================================================================
