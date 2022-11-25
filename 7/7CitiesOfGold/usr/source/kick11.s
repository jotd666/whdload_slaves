;*---------------------------------------------------------------------------
;  :Modul.	kick11.s
;  :Contents.	interface code and patches for kickstart 1.1 (Amiga 1000 PAL)
;  :Author.	Wepl, JOTD, Psygore
;  :Version.	$Id: kick11.s 1.41 2021/08/04 21:21:47 wepl Exp wepl $
;  :History.	17.04.02 created from kick12.s from JOTD
;
;		02.08.21 patch for gfx_WaitBlit added
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	vasm, Barfly 2.9, Asm-Pro 1.16, PhxAss 4.38
;  :To Do.
;---------------------------------------------------------------------------*

; TODO: do not set $8->$64 except for $20

	INCLUDE	lvo/exec.i
	INCLUDE	lvo/graphics.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	exec/memory.i
	INCLUDE	graphics/gfxbase.i

KICKVERSION	= 31
KICKCRC		= $6490				;31.034

;============================================================================

	IFD	slv_Version
	IFLT	slv_Version-16
	FAIL	slv_Version must be 16 or higher
	ENDC

slv_FlagsAdd SET WHDLF_EmulPriv
	IFD HDINIT
slv_FlagsAdd SET slv_FlagsAdd|WHDLF_Examine
	ENDC

KICKSIZE	= $40000			
BASEMEM		= CHIPMEMSIZE
	IFND EXTROMSIZE
EXTROMSIZE	= 0
	ENDC
EXPMEM		= KICKSIZE+FASTMEMSIZE+EXTROMSIZE

slv_base	SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	slv_Version		;ws_Version
		dc.w	slv_Flags|slv_FlagsAdd	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_boot-slv_base		;ws_GameLoader
		dc.w	slv_CurrentDir-slv_base	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	slv_keyexit		;ws_keyexit
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	slv_name-slv_base	;ws_name
		dc.w	slv_copy-slv_base	;ws_copy
		dc.w	slv_info-slv_base	;ws_info
		dc.w	slv_kickname-slv_base	;ws_kickname
		dc.l	KICKSIZE		;ws_kicksize
		dc.w	KICKCRC			;ws_kickcrc
	IFGE slv_Version-17
		dc.w	slv_config-slv_base	;ws_config
	ENDC
	ENDC

;============================================================================
; the following is to avoid "Error 86: Internal global optimize error" with
; BASM, which is caused by "IFD _label" and _label is defined after the IFD

	IFND BOOTBLOCK
	IFD _bootblock
BOOTBLOCK = 1
	ENDC
	ENDC
	IFND BOOTDOS
	IFD _bootdos
BOOTDOS = 1
	ENDC
	ENDC
	IFND BOOTEARLY
	IFD _bootearly
BOOTEARLY = 1
	ENDC
	ENDC
	IFND BOOTCOOL
	IFD _bootcool
BOOTCOOL = 1
	ENDC
	ENDC
	IFND CBDOSLOADSEG
	IFD _cb_dosLoadSeg
CBDOSLOADSEG = 1
	ENDC
	ENDC
	IFND CBKEYBOARD
	IFD _cb_keyboard
CBKEYBOARD = 1
	ENDC
	ENDC

	IFD	BOOTDOS
	IFND	HDINIT
	FAIL	BOOTDOS/_bootdos requires HDINIT to be set
	ENDC
	ENDC

;============================================================================

_boot		lea	(_resload,pc),a1
		move.l	a0,(a1)				;save for later use
		move.l	a0,a5				;A5 = resload


WCPU_VAL SET 0
	IFD CACHE
WCPU_VAL SET WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB
	ENDC
	IFD CACHECHIP
WCPU_VAL SET WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_BC|WCPUF_SS|WCPUF_SB
	ENDC
	IFD CACHECHIPDATA
WCPU_VAL SET WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB
	ENDC
	IFD NEEDFPU
WCPU_VAL SET WCPU_VAL|WCPUF_FPU
	ENDC
	;setup cache/fpu
		move.l	#WCPU_VAL,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a5)

	;relocate some addresses
		lea	(_cbswitch,pc),a0
		lea	(_cbswitch_tag,pc),a1
		move.l	a0,(a1)

	;get tags
		lea	(_tags,pc),a0
		jsr	(resload_Control,a5)

	IFND slv_Version
	;load kickstart
		move.l	#KICKSIZE,d0			;length
		move.w	#KICKCRC,d1			;crc16
		lea	(slv_kickname,pc),a0		;name
		jsr	(resload_LoadKick,a5)
	ENDC

	;patch the kickstart
		lea	(kick_patch,pc),a0
		move.l	(_expmem,pc),a1
		jsr	(resload_Patch,a5)

	;call
kick_reboot	move.l	(_expmem,pc),a0
		jmp	(2,a0)				;original entry

kick_patch	PL_START
		PL_S	$ce,$fe-$ce
		PL_L	$106,$02390002			;skip LED power off (and.b #~CIAF_LED,$bfe001)
		PL_CW	$132				;color00 $444 -> $000
		PL_S	$136,$148-$136			;avoid overwriting vector table
		;;;PL_W	$22e,$400			;avoid overwriting vector table
		PL_CW	$1F6				;color00 $888 -> $000
	;IFD HRTMON
	;	PL_PS	$286,kick_hrtmon
	;ENDC
	;;	PL_PS	$3d6,kick_setvecs	; not needed in 1.1, already stops after trap 15
	;;	PL_S	$3ec,12				;avoid overwriting vector table
		PL_PS	$360,exec_flush
		PL_W	$382+2,$17			;correct calc of exec.ChkSum
		PL_L	$468,-1				;disable search for residents at $f00000
		PL_S	$474,$514-$50C			;skip LED power on
	IFD BOOTCOOL
		PL_PS	$480,_bootcool
	ENDC
		PL_P	$4B2,kick_detectcpu
		PL_P	$4de,kick_detectchip
		PL_PS	$1c8,kick_clearchip_fix	; fix wrong size when clearing memory
		PL_S	$2F8,$304-$2F8			; fix wrong write to $80010-$80016
		PL_P	$053c,kick_reboot		;reboot (reset)
		;; PL_P	$61a,kick_detectfast    ; fast not supported at least like in 1.2
		PL_PS	$ca4,exec_ExitIntr
		PL_PS	$121a,exec_SetFunction
		PL_PS	$1316,exec_MakeFunctions
	IFD MEMFREE
		PL_P	$1564,exec_AllocMem
	ENDC
		PL_S	$5dda,$4910-$48fc		;skip disk unit detect
		PL_P	$5f40,disk_getunitid

		PL_PS	$70ac,gfx_vbserver
		PL_PS	$70c2,gfx_snoop1
		PL_DATA	$7244,8				;snoop bug ('and.w #$20,$DFF01E')
			btst #5,$dff01f
		PL_PS	$b4ee,gfx_setcoplc
		PL_S	$b516,6				;avoid ChkBltWait problem
		;;PL_S	$af16,$36-$16			;skip color stuff & strange gb_LOFlist set
		PL_P	$b67a,gfx_detectgenlock
		;;PL_P	$b058,gfx_detectdisplay
		PL_P	$6650,gfx_WaitBlit		; patch actual routine instead of jump table
		PL_PS	$e196,gfx_fix1			;gfx_LoadView
	IFD FONTHEIGHT
		PL_B	$1ddb0,FONTHEIGHT
	ENDC
	IFD BLACKSCREEN
		PL_C	$1de16,6			;color17,18,19
		PL_C	$1de1e,8			;color0,1,2,3
	ENDC
	IFD POINTERTICKS
		PL_W	$1de1c,POINTERTICKS
	ENDC
		PL_PS	$26e98,keyboard_start
		PL_PS	$26faa,keyboard_end
		PL_PS	$27a42,input_task
	IFD HDINIT
;		PL_PS	$288e8,hd_init			;enter while starting strap
	ENDC
	IFD BOOTEARLY
;		PL_PS	$28986,kick_bootearly
	ELSE
	ENDC
	IFD BOOTBLOCK
		PL_PS	$41c6,kick_bootblock		;a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_P	$2a09c,timer_init
		PL_P	$2a75c,trd_task
		PL_P	$2ace0,trd_format
		PL_P	$2b07a,trd_motor
		PL_P	$2b308,trd_readwrite
		PL_PS	$2b658,trd_protstatus
	IFD DEBUG
;		PL_L	$29fd4,-1			;disable asynchron io
;		PL_I	$2a51c				;empty dbf-loop in trackdisk.device
;		PL_I	$2aa14				;trd_seek
;		PL_I	$2b2e8				;trd_rawread
;		PL_I	$2b2ee				;trd_rawwrite
	ENDC
		PL_PS	$34ad6,dos_init
		PL_PS	$3627e,dos_endcli
		PL_PS	$379e0,dos_LoadSeg
	IFD SEGTRACKER
; unsupported ATM
;		PL_PS	$37afa,dos_UnLoadSeg
;		PL_PS	$38a40,segtracker_init
	ENDC
	IFD BOOTDOS
;		PL_PS	$38a4a,dos_bootdos
	ENDC
	IFD STACKSIZE
		PL_L	$39358,STACKSIZE/4
	ENDC
		PL_PS	$3cd0e,dos_1
	;the following stuff is from SetPatch 1.38
	IFD SETPATCH
;		PL_P	$1174,exec_UserState
;		PL_P	$165a,exec_FindName
;		PL_P	$191e,exec_AllocEntry
;		PL_PS	$57c0,gfx_MrgCop
;		PL_PS	$7f26,gfx_SetFont
;		PL_P	$7f66,gfx_SetSoftStyle
	ENDC
		PL_END

;============================================================================



kick_detectfast
	IFEQ FASTMEMSIZE
		sub.l	a4,a4
	ELSE
		move.l	(_expmem,pc),a4
		add.l	#KICKSIZE,a4
		move.l	a4,($1f0-$1ea,a5)
		move.l	a4,($1fc-$1ea,a5)
		add.l	#FASTMEMSIZE,a4
		bsr	_flushcache
	ENDC
		jmp	(a5)

kick_detectchip	move.l	#CHIPMEMSIZE,D0
		jmp	(a5)

kick_clearchip_fix
	LSR.L	#2,D0			;0fc0606: e488
	SUBQ.L	#1,D0			;0fc01c8: 5380
	MOVE.L	D0,D1			;0fc01ca: 2200
	SWAP	D1			;0fc01cc: 4841
	rts
	
	
	IFD HRTMON
kick_hrtmon	move.l	a4,d0
		bne	.1
		move.l	a3,d0
.1		sub.l	#8,d0			;hrt reads too many from stack -> avoid af
		rts
	ENDC

kick_detectcpu	move.l	(_attnflags,pc),d0
	IFND NEEDFPU
		and.w	#~(AFF_68881|AFF_68882|AFF_FPU40),d0
	ENDC
		rts

exec_ExitIntr	tst.w	(_custom+intreqr)	;delay to make sure int is cleared
		btst	#5,($18+4,a7)		;original code
		rts

	;move.w (a7)+,($dff09c) does not work with Snoop/S on 68060
exec_snoop1	move.w	(a7),($dff09c)
		addq.l	#2,a7
		rts

exec_MakeFunctions
		subq.l	#8,a7
		move.l	(8,a7),(a7)
		move.l	a3,(4,a7)		;original
		lea	(_flushcache,pc),a3
		move.l	a3,(8,a7)
		moveq	#0,d0			;original
		move.l	a2,d1			;original
		rts

exec_SetFunction
		move.l	(a7)+,d1
		pea	(_flushcache,pc)
		move.l	d1,-(a7)
		bset	#1,(14,a1)		;original
		rts

exec_flush	lea	(_custom),a0		;original
		bra	_flushcache

	IFD MEMFREE
exec_AllocMem	movem.l	d0-d1/a0-a1,-(a7)
		move.l	#MEMF_LARGEST|MEMF_CHIP,d1
		jsr	(_LVOAvailMem,a6)
		move.l	(MEMFREE),d1
		beq	.3
		cmp.l	d1,d0
		bhi	.1
.3		move.l	d0,(MEMFREE)
.1		move.l	#MEMF_LARGEST|MEMF_FAST,d1
		jsr	(_LVOAvailMem,a6)
		move.l	(MEMFREE+4),d1
		beq	.4
		cmp.l	d1,d0
		bhi	.2
.4		move.l	d0,(MEMFREE+4)
.2		movem.l	(a7)+,d0-d1/a0-a1
		movem.l	(a7)+,d2-d3/a2
		rts
	ENDC

	IFD SETPATCH

exec_AllocEntry	movem.l	d2/d3/a2-a4,-(sp)
		movea.l	a0,a2
		moveq	#0,d3
		move.w	(14,a2),d3
		move.l	d3,d0
		lsl.l	#3,d0
		addi.l	#$10,d0
		move.l	#$10000,d1
		jsr	(-$C6,a6)
		movea.l	d0,a3
		movea.l	d0,a4
		tst.l	d0
		beq.b	.BD0
		move.w	d3,(14,a3)
		lea	($10,a2),a2
		lea	($10,a3),a3
		moveq	#0,d2
.B78		move.l	(0,a2),d1
		move.l	(4,a2),d0
		move.l	d0,(4,a3)
		beq.b	.B8E
		jsr	(_LVOAllocMem,a6)
		tst.l	d0
		beq.b	.BA4
.B8E		move.l	d0,(0,a3)
		addq.l	#8,a2
		addq.l	#8,a3
		addq.w	#1,d2
		subq.l	#1,d3
		bne.b	.B78
		move.l	a4,d0
.B9E		movem.l	(sp)+,d2/d3/a2-a4
		rts

.BA4		subq.w	#1,d2
		bmi.b	.BB8
		subq.l	#8,a3
		movea.l	(0,a3),a1
		move.l	(4,a3),d0
		jsr	(_LVOFreeMem,a6)
		bra.b	.BA4

.BB8		moveq	#0,d0
		move.w	(14,a4),d0
		lsl.l	#3,d0
		addi.l	#$10,d0
		movea.l	a4,a1
		jsr	(_LVOFreeMem,a6)
		move.l	(0,a2),d0
.BD0		bset	#$1F,d0
		bra.b	.B9E

exec_UserState	move.l	(sp)+,d1
		move.l	sp,usp
		movea.l	d0,sp
		movea.l	a5,a0
		lea	(.B18,pc),a5
		jmp	(_LVOSupervisor,a6)

.B18		movea.l	a0,a5
		move.l	d1,(2,sp)
		andi.w	#$DFFF,(sp)
		rte

exec_FindName	move.l	a2,-(sp)
		movea.l	a0,a2
		move.l	a1,d1
		move.l	(a2),d0
		beq.b	.FDC
.FBE		movea.l	d0,a2
		move.l	(a2),d0
		beq.b	.FDC
		tst.l	(10,a2)
		beq.b	.FBE
		movea.l	(10,a2),a0
		movea.l	d1,a1
.FD0		cmpm.b	(a0)+,(a1)+
		bne.b	.FBE
		tst.b	(-1,a0)
		bne.b	.FD0
		move.l	a2,d0
.FDC		movea.l	d1,a1
		movea.l	(sp)+,a2
		rts

	ENDC

	IFD BOOTEARLY
kick_bootearly	movem.l	d0-a6,-(a7)
		bsr	_bootearly
		movem.l	(a7)+,d0-a6
		LEA	0(A2),A1		;original
		moveq	#0,d0			;original
		rts
	ENDC

	IFD BOOTBLOCK
kick_bootblock	movem.l	d2-d7/a2-a6,-(a7)
		move.l	a3,a4	; kick 1.1 base address is a3, slaves expect a4
		bsr	_bootblock
		movem.l	(a7)+,d2-d7/a2-a6
		tst.l	d0			;original
		rts
	ENDC

;============================================================================

gfx_vbserver	lea	(_cbswitch_cop2lc,pc),a6
		move.l	d0,(a6)
		lea	($bfd000),a6		;original
		rts

_cbswitch	move.l	(_cbswitch_cop2lc,pc),(_custom+cop2lc)
		move.l	(input_norepeat,pc),d0
		beq	.norepeat
		exg	d0,a0
		st	(a0)				;set repeat key invalid
		move.l	d0,a0
.norepeat	jmp	(a0)

	;move (custom),(cia) does not work with Snoop/S on 68060
gfx_snoop1	move.b	(vhposr,a0),d0
		move.b	d0,(ciatodlow,a6)
		rts

gfx_detectgenlock
		move.l	(_bplcon0,pc),d0
		rts

gfx_detectdisplay
		moveq	#4,d0			;pal
		move.l	(_monitor,pc),d1
		cmp.l	#PAL_MONITOR_ID,d1
		beq	.1
		cmp.l	#DBLPAL_MONITOR_ID,d1
		beq	.1
		moveq	#1,d0			;ntsc
.1		rts

gfx_setcoplc	moveq	#-2,d0
		move.l	d0,(a3)+
		move.l	a3,(cop2lc,a4)		;original
		move.l	a3,(gb_LOFlist,a2)
		move.l	a3,(gb_SHFlist,a2)
		move.l	d0,(a3)+
		clr.w	(color+2,a4)
		add.l	#$adb6-$ad9e-6,(a7)
		rts

gfx_WaitBlit	tst.b	(_custom+dmaconr)
		btst	#DMAB_BLTDONE-8,(_custom+dmaconr)
		beq.b	.1
.2		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		tst.b	(_ciaa)		;this avoids blitter slow down
		btst	#DMAB_BLTDONE-8,(_custom+dmaconr)
		bne.b	.2
.1		tst.b	(_custom+dmaconr)
		rts

	;somewhere there will used a empty view, too stupid
gfx_fix1	move.l	(v_LOFCprList,a2),d0
		beq	.s1
		move.l	d0,a1
		move.l	(4,a1),(gb_LOFlist,a0)
.s1		move.l	(v_SHFCprList,a2),d0
		beq	.s2
		move.l	d0,a1
		move.l	(4,a1),(gb_SHFlist,a0)
.s2		add.l	#$d5e0-$d5cc-6,(a7)
		rts

	IFD SETPATCH

gfx_MrgCop	move.w	($10,a1),d0
		move.w	($9E,a6),d1
		eor.w	d1,d0
		andi.w	#4,d0
		beq.b	.F58
		and.w	($10,a1),d0
		beq.b	.F58
		movem.l	a2/a3,-(sp)
		movea.l	a1,a2
		movea.l	a1,a3
.F2E		move.l	(a3),d0
		beq.b	.F52
		movea.l	d0,a3
		move.w	($20,a3),d0
		move.w	#$2000,d1
		and.w	d0,d1
		beq.b	.F2E
		move.w	#4,d1
		and.w	d0,d1
		beq.b	.F2E
		movea.l	a2,a0
		movea.l	a3,a1
		jsr	(_LVOMakeVPort,a6)
		bra.b	.F2E
.F52		movea.l	a2,a1
		movem.l	(sp)+,a2/a3
.F58
		move.l	a1,-(a7)		;original
		pea	(.ret,pc)
		move.l	(8,a7),-(a7)
		add.l	#-6-$57c0+$a586,(a7)
		rts

.ret		addq.l	#8,a7
		rts

gfx_SetFont	move.l	a0,d0
		beq.b	.FAC
		move.l	a1,d0
		beq.b	.FAC
		move.w	($14,a0),($3a,a1)	;original
		rts

.FAC		addq.l	#4,a7
		rts

gfx_SetSoftStyle
		move.l	d2,-(sp)
		moveq	#0,d2
		movem.l	d0/d1/a0/a1,-(sp)
		jsr	(_LVOAskSoftStyle,a6)
		move.b	d0,d2
		movem.l	(sp)+,d0/d1/a0/a1
		movea.l	($34,a1),a0
		and.b	d2,d1
		move.b	($38,a1),d2
		and.b	d1,d0
		not.b	d1
		and.b	d1,d2
		or.b	d0,d2
		move.b	d2,($38,a1)
		or.b	($16,a0),d2
		move.l	d2,d0
		move.l	(sp)+,d2
		rts

	ENDC

;============================================================================

disk_getunitid
	IFLT NUMDRIVES
		cmp.l	#1,d0			;at least one drive
		bcs	.set
		cmp.l	(_custom1,pc),d0
	ELSE
		subq.l	#NUMDRIVES,d0
	ENDC
.set		scc	d0
		ext.w	d0
		ext.l	d0
		rts

;============================================================================
; kick11 does not provide fast and fine access to cia timers, therefore we
; use the rasterbeam, required minimum waiting is 75탎, one rasterline is
; 63.5탎, three loops results in min=127탎 max=190.5탎

keyboard_start	moveq	#0,d4
		not.b	d0
		ror.b	#1,d0
		beq	.continue
		cmp.b	(_keyexit,pc),d0
		beq	.exit
		cmp.b	(_keydebug,pc),d0
		beq	.debug
	IFD CBKEYBOARD
		movem.l	d0-a6,-(a7)
		bsr	_cb_keyboard
		movem.l	(a7)+,d0-a6
	ENDC
.continue	lea	(_keyboarddelay,pc),a1
		move.b	(_custom+vhposr),(a1)
		rts

.exit		pea	TDREASON_OK
		bra	.abort

.debug		addq.l	#4,a7			;rts from patchs
		movem.l	(a7)+,d2-d4/a6
		addq.l	#4,a7			;rts from keyboard int
		movem.l	(a7)+,d2/a2
		addq.l	#4,a7			;rts from ports int
		move.l	(a7)+,a2
		move.w	(a7),(_custom+intena)
		addq.l	#6,a7			;rts from int handler
		movem.l	(a7)+,d0-d1/a0-a1/a5-a6
		move.w	(a7),(6,a7)
		move.l	(2,a7),(a7)
		clr.w	(4,a7)
		pea	TDREASON_DEBUG
.abort		move.l	(_resload,pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

keyboard_end	move.b	(_keyboarddelay,pc),d1
		lea	(_custom),a1
.wait1		cmp.b	(vhposr,a1),d1
		beq	.wait1
		move.b	(vhposr,a1),d1
.wait2		cmp.b	(vhposr,a1),d1
		beq	.wait2
		move.b	(vhposr,a1),d1
.wait3		cmp.b	(vhposr,a1),d1
		beq	.wait3
		addq.l	#2,(a7)
		and.b	#~(CIACRAF_SPMODE),(_ciaa+ciacra)
		rts

;============================================================================

input_task	moveq	#0,d7				;original
		bset	d0,d7				;original
		move.l	d7,d6				;original
		pea	($1212,a5)			;last rawkey for repeat kick 1.2/1.3
		lea	(input_norepeat,pc),a0
		move.l	(a7)+,(a0)
		rts

input_norepeat	dc.l	0

;============================================================================

timer_init	move.l	(_time,pc),a0
		move.l	(whdlt_days,a0),d0
		mulu	#24*60,d0
		add.l	(whdlt_mins,a0),d0
		move.l	d0,d1
		lsl.l	#6,d0			;*64
		lsl.l	#2,d1			;*4
		sub.l	d1,d0			;=*60
		move.l	(whdlt_ticks,a0),d1
		divu	#50,d1
		ext.l	d1
		add.l	d1,d0
		move.l	d0,($c6,a2)
		movem.l	(a7)+,a2-a3		;original
		rts

;============================================================================

dsk_unit_number =  41 ; $43=67
dsk_motor_status = 39 ; $41=65
dsk_disk_inserted = 38 ; $40=64
dsk_change_count = 274 ; $126=294

trd_format
trd_readwrite	movem.l	d2/a1-a2,-(a7)
		moveq	#0,d1
		move.b	(dsk_unit_number,a3),d1		;unit number
		clr.b	(IO_ERROR,a1)

		btst	#1,(dsk_disk_inserted,a3)		;disk inserted?
		beq	.diskok

		move.b	#TDERR_DiskChanged,(IO_ERROR,a1)

.end		movem.l	(a7),d2/a1-a2
		bsr		trd_endio
		movem.l	(a7)+,d2/a1-a2
		moveq	#0,d0
		move.b	(IO_ERROR,a1),d0
		rts

.diskok		cmp.b	#CMD_READ,(IO_COMMAND+1,a1)
		bne	.write

.read		moveq	#0,d2
		move.b	(_trd_disk,pc,d1.w),d2	;disk
		move.l	(IO_OFFSET,a1),d0	;offset
		move.l	(IO_LENGTH,a1),d1	;length
		move.l	d1,(IO_ACTUAL,a1)	;actually read
		move.l	(IO_DATA,a1),a0		;destination
		move.l	(_resload,pc),a1
		jsr	(resload_DiskLoad,a1)
		bra	.end

.write		move.b	(_trd_prot,pc),d0
		btst	d1,d0
		bne	.protok
		move.b	#TDERR_WriteProt,(IO_ERROR,a1)
		bra	.end

.protok		lea	(.disk,pc),a0
		move.b	(_trd_disk,pc,d1.w),d0	;disk
		add.b	#"0",d0
		move.b	d0,(5,a0)		;name
		move.l	(IO_LENGTH,a1),d0	;length
		move.l	(IO_OFFSET,a1),d1	;offset
		move.l	(IO_DATA,a1),a1		;destination
		move.l	(_resload,pc),a2
		jsr	(resload_SaveFileOffset,a2)
		bra	.end

.disk		dc.b	"Disk.",0,0,0

_trd_disk	dc.b	1,2,3,4			;number of diskimage in drive
_trd_prot	dc.b	WPDRIVES		;protection status
_trd_chg	dc.b	0			;diskchanged

trd_motor
		moveq	#0,d0
		bchg	#7,(dsk_motor_status,a3)		;motor status
		seq	d0
		rts

trd_protstatus	moveq	#0,d0
		move.b	(dsk_unit_number,a3),d1		;unit number
		move.b	(_trd_prot,pc),d0
		btst	d1,d0
		seq	d0
		move.l	d0,(IO_ACTUAL,a1)
		add.l	#$686-$658-6,(a7)	;skip unnecessary code
		rts

trd_endio	
		move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$2ae1c,(a7)
		rts

tdtask_cause
		move.l	(_expmem,pc),-(a7)	;jump into rom
		add.l	#$2a832,(a7)	; not sure??
		rts

trd_task
	IFD DISKSONBOOT
		bclr	#1,(dsk_disk_inserted,a3)		;set disk inserted
		beq.b	.1
		addq.l	#1,(dsk_change_count,a3)		;inc change count
		bsr	tdtask_cause
.1
	ENDC
		move.b	(dsk_unit_number,a3),d1		;unit number
		lea	(_trd_chg,pc),a0
		bclr	d1,(a0)
		beq.b	.2			;if not changed skip

		bset	#1,(dsk_disk_inserted,a3)		;set no disk inserted
		bne.b	.3
		addq.l	#1,(dsk_change_count,a3)		;inc change count
		bsr	tdtask_cause
.3
		bclr	#1,(dsk_disk_inserted,a3)		;set disk inserted
		addq.l	#1,(dsk_change_count,a3)		;inc change count
		bsr	tdtask_cause

.2		rts

	IFD TRDCHANGEDISK
	;d0.b = unit
	;d1.b = new disk image number
_trd_changedisk	movem.l	a6,-(a7)

		and.w	#3,d0
		lea	(_trd_chg,pc),a0

		move.l	(4),a6
		jsr	(_LVODisable,a6)

		move.b	d1,(-5,a0,d0.w)
		bset	d0,(a0)

		jsr	(_LVOEnable,a6)

		movem.l	(a7)+,a6
		rts
	ENDC

;============================================================================

dos_init	move.l	#$10001,d1
		bra	_flushcache

dos_endcli	tst.l	D2			;is -1 with EndCLI
		bmi	.1
		move.b	(a0,d2.l),d3		;original
.1		move.l	d3,d1			;original
		rts

dos_1		move.l	#$114,d1		;original
		bra	_flushcache

dos_LoadSeg	clr.l	(12,a1)			;original
		moveq	#12,d4			;original
		lea	(.savea4,pc),a6
		move.l	a4,(a6)
		lea	(.bcplend,pc),a6
		rts

.savea4		dc.l	0

.bcplend	cmp.l	(.savea4,pc),a4		;are we in dos_51?
		beq	.end51
		jmp	($344a8-$344b4,a5)	;call original (same distance in 1.1 0ff4d30-0ff4d3c)

.end51		lea	($344a8-$344b4,a5),a6	;restore original
	IFD CBDOSLOADSEG
		movem.l	d0-a6,-(a7)
		move.l	(a1),d0			;d0 = BSTR FileName
		tst.l	d1			;d1 = BPTR SegList
		beq	.failed
		bsr	_cb_dosLoadSeg
.failed		movem.l	(a7)+,d0-a6
	ENDC
	IFD SEGTRACKER
		movem.l	d0-d1/a0-a1,-(a7)
		move.l	(a1),a0			;a0 = BSTR FileName
		add.l	a0,a0
		add.l	a0,a0
		moveq	#0,d0
		move.b	(a0)+,d0		;length
		clr.b	(a0,d0.w)		;terminate, hopefully doesn't overwrite anything
		move.l	d1,d0			;d0 = BPTR SegList
		beq	.failed2
		bsr	st_track
.failed2	movem.l	(a7)+,d0-d1/a0-a1
	ENDC
		bsr	_flushcache
		jmp	(a6)

	IFD SEGTRACKER
dos_UnLoadSeg	bsr	st_untrack
		addq.l	#2,(a7)
		cmp.l	#$abcd,(8,a0,d2.l)	;original
		rts
	ENDC

	IFD BOOTDOS
dos_bootdos

	;init boot exe
		lea	(_bootdos,pc),a3
		move.l	a3,(bootfile_exe_j+2-_bootdos,a3)

	;fake startup-sequence
		lea	(bootname_ss_b,pc),a3	;bstr
		move.l	a3,d1

	;return
		rts

	ENDC

;---------------
; performs a C:Assign
; IN:	A0 = CPTR destination name
;	A1 = CPTR directory (could be 0 meaning SYS:)
; OUT:	-

	IFD DOSASSIGN
_dos_assign	movem.l	d2/a3-a6,-(a7)
		move.l	a0,a3			;A3 = name
		move.l	a1,a4			;A4 = directory
		move.l	(4),a6

	;backward compatibilty (given BSTR instead CPTR)
		cmp.b	#" ",(a0)
		bls	.skipname

	;get length of name
		moveq	#-1,d2
.len		addq.l	#1,d2
		tst.b	(a0)+
		bne	.len

	;get memory for name
		move.l	d2,d0
		addq.l	#2,d0			;+ length and terminator
		move.l	#MEMF_ANY,d1
		jsr	(_LVOAllocMem,a6)
	IFD DEBUG
		tst.l	d0
		beq	_debug3
	ENDC
		move.l	d0,a0
		move.b	d2,(a0)+
.cpy		move.b	(a3)+,(a0)+
		bne	.cpy
		move.l	d0,a3
.skipname
	;get memory for node
		move.l	#DosList_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		jsr	(_LVOAllocMem,a6)
	IFD DEBUG
		tst.l	d0
		beq	_debug3
	ENDC
		move.l	d0,a5			;A5 = DosList

	;open doslib
		lea	(_dosname,pc),a1
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6

	;lock directory
		move.l	a4,d1
		move.l	#ACCESS_READ,d2
		jsr	(_LVOLock,a6)
		move.l	d0,d1
	IFD DEBUG
		beq	_debug3
	ENDC
		lsl.l	#2,d1
		move.l	d1,a0
		move.l	(fl_Task,a0),(dol_Task,a5)
		move.l	d0,(dol_Lock,a5)

	;init structure
		move.l	#DLT_DIRECTORY,(dol_Type,a5)
		move.l	a3,d0
		lsr.l	#2,d0
		move.l	d0,(dol_Name,a5)

	;add to the system
		move.l	(dl_Root,a6),a6
		move.l	(rn_Info,a6),a6
		add.l	a6,a6
		add.l	a6,a6
		move.l	(di_DevInfo,a6),(dol_Next,a5)
		move.l	a5,d0
		lsr.l	#2,d0
		move.l	d0,(di_DevInfo,a6)

		movem.l	(a7)+,d2/a3-a6
		rts
	ENDC

;============================================================================

	IFD HDINIT

hd_init		sub.l	#$7e,a5				;original

	INCLUDE	whdload/kickfs.s
	
	ENDC

;============================================================================

	IFD SEGTRACKER

segtracker_init	move.l	($18,a1),d2			;original
		lsl.l	#2,d2				;original

	INCLUDE whdload/segtracker.s

	ENDC

;============================================================================

_flushcache	move.l	(_resload,pc),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

;============================================================================

	IFD DEBUG
_debug1		tst	-1	;unknown packet (=d2) for dos handler
_debug2		tst	-2	;no lock given for a_copy_dir (dos.DupLock)
_debug3		tst	-3	;error in _dos_assign
_debug4		tst	-4	;invalid lock specified
		illegal		;security if executed without mmu
	ENDC

;============================================================================

slv_kickname	dc.b	"31034.a1000",0
_keyboarddelay	dc.b	0
	EVEN
_tags		dc.l	WHDLTAG_CBSWITCH_SET
_cbswitch_tag	dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attnflags	dc.l	0
		dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_BPLCON0_GET
_bplcon0	dc.l	0
		dc.l	WHDLTAG_TIME_GET
_time		dc.l	0
	IFLT NUMDRIVES
		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
	ENDC
		dc.l	0
_resload	dc.l	0
_cbswitch_cop2lc	dc.l	0

;============================================================================

