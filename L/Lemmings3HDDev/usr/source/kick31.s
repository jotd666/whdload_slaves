;*---------------------------------------------------------------------------
;  :Modul.	kick31.s
;  :Contents.	interface code and patches for kickstart 3.1 (40068)
;  :Author.	JOTD, adapting most of Wepl kickstart 1.3 code
;  :Version.	$Id: 
;  :History.	
;
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly 2.9, Asm-Pro 1.16, PhxAss 4.38
;  :To Do.	.buildname: support for relative paths
;		more dos packets (maybe)
;---------------------------------------------------------------------------*

	INCLUDE	lvo/exec.i
	INCLUDE	lvo/graphics.i
	INCLUDE	devices/trackdisk.i
	INCLUDE	exec/memory.i
	INCLUDE	exec/resident.i
	INCLUDE	graphics/gfxbase.i

KICK31 = 1

;============================================================================

_boot
		lea	(_resload,pc),a1
		move.l	a0,(a1)				;save for later use
		move.l	a0,a5				;A5 = resload

	;relocate some addresses
		lea	(_cbswitch,pc),a0
		lea	(_cbswitch_tag,pc),a1
		move.l	a0,(a1)
		
	;get tags
		lea	(_tags,pc),a0
		jsr	(resload_Control,a5)
	
	;load kickstart
		move.l	#KICKSIZE,d0			;length
		move.w	#$9FF5,d1			;crc16
		lea	(_kick,pc),a0			;name
		jsr	(resload_LoadKick,a5)

	;patch the kickstart
		lea	(kick_patch,pc),a0
		move.l	(_expmem,pc),a1

	;	lea	CHIPMEMSIZE-$100,A7
	;	illegal

		jsr	(resload_Patch,a5)

	; install CD32 extended rom if needed
	; not working yet, do not use

		IFD	CD32EXT
		move.l	(_expmem,pc),a0
		add.l	#KICKSIZE,a0
		lea	CHIPMEMSIZE,a0		; TEMP
		move.l	_expmem(pc),a1
		bsr	_cd32_init
		ENDC
	;call
		move.l	(_expmem,pc),a0
;;		jmp	(2,a0)				;original entry
		moveq	#-1,D5
		lea	$400.W,A7
		jmp	($166,a0)			;this entry saves some patches

		IFD	CD32EXT
		include	"cd32ext.s"
		ENDC

kick_patch	PL_START
		PL_P	$38e,kick_detectfast	; 3.1
		PL_PS	$242,kick_detectchip	; 3.1
;	IFD HRTMON
;		PL_PS	$286,kick_hrtmon	; ?? around $5CC
;	ENDC
		PL_P	$d36,_flushcache	; cachecontrol -> flushcache
		PL_P	$c1c,kick_detectcpu	; 3.1
		PL_P	$d5e,_flushcache	; 3.1
		PL_I	$db8			; reset, trap it
		PL_B	$1EC,$60		; forces exec install

		PL_PS	$B4AA,exec_snoop1
		PL_S	$F7E0,6			; skip write to todlow ($bfd800)
;		PL_PS	$422,exec_flush
	IFD MEMFREE
;		PL_P	$1826,exec_AllocMem
	ENDC
		PL_I	$404				; 3.1 JFF unexpected interrupt
		PL_I	$364				; 3.1 JFF blue screen
		PL_L	$376,-1				; 3.1 disable search for residents at $f00000
		PL_P	$46A,skip_de1000		; 3.1 skip strange memtest ???
		PL_S	$38FE,$3A00-$38FE		; 3.1 skip autoconfiguration at $e80000
		PL_L	$329A,$70004E71			; 3.1 get VBR -> 0
		PL_W	$CD0,$4E71			; 3.1 JFF
		PL_P	$CD2,_flushcache		; 3.1 JFF
		PL_P	$3DF3C,battclock_init		; 3.1 JFF
		PL_P	$3704A,de1000_init		; 3.1 JFF what is it???
		PL_S	$b73C,6				; 3.1 JFF ChkBltWait problem
		PL_PS	$b758,clrwait			; 3.1 JFF ChkBltWait problem
;		PL_PS	$6d70,gfx_vbserver
;		PL_PS	$6d86,gfx_snoop1
;		PL_PS	$ad5e,gfx_setcoplc
;		PL_S	$ad7a,6				;avoid ChkBltWait problem
;		PL_S	$aecc,$e4-$cc			;skip color stuff & strange gb_LOFlist set
		PL_P	$bb7e,gfx_detectgenlock		; 3.1
;		PL_P	$bc48,gfx_detectdisplay		; patched at a lower level (NTSC/PAL)
;		PL_PS	$d5be,gfx_fix1			; gfx_LoadView

;		PL_PS	$8568,gfx_read_vpos		; gfx_VBeamPos, unpatched
		PL_PS	$B484,gfx_read_vpos		; patched to set NTSC/PAL
		PL_PS	$14B4E,gfx_read_vpos		; patched to set NTSC/PAL

	IFD _bootearly
		PL_P	$4794,do_bootearly		; 3.1
	ENDC
	IFD _bootdos
		PL_PS	$22814,dos_bootdos		; 3.1
	ENDC
	IFD	HDINIT
		PL_P	$42F4,hd_init			; 3.1
	ENDC
	IFD _bootblock
		PL_PS	$489A,_bootblock		; 3.1 a1=ioreq a4=buffer a6=execbase
	ENDC
		PL_P	$40D3A,timer_init		; 3.1
		PL_P	$4598C,trd_readwrite		; 3.1
		PL_P	$4569C,trd_motor		; 3.1
		PL_P	$45258,trd_format		; 3.1
		PL_PS	$45D5A,trd_protstatus		; 3.1
	;	PL_I	$2af68				;trd_rawread
	;	PL_I	$2af6e				;trd_rawwrite
	;	PL_I	$2a19c				;empty dbf-loop in trackdisk.device
		PL_P	$44A5A,trd_task			; 3.1
	;	PL_L	$29c54,-1			;disable asynchron io
		PL_P	$40442,disk_getunitid		; 3.1
	IFD	_cb_dosLoadSeg
		PL_PS	$2726A,dos_LoadSeg		; 3.1 loadseg entrypoint
	ENDC
		PL_END

; not done as in kick13.s at all!
; sorry Bert, but anyway doslib was completely rewritten after all :)

	IFD	_cb_dosLoadSeg
dos_LoadSeg
	move.l	(A7)+,a0
	movem.l	D2-D3,-(A7)
	move.l	d1,d2			;save name
	pea	.cont(pc)
	MOVEM.L	D2/D7/A6,-(A7)		;original
	MOVEA.L	4.W,A6	;code
	jmp	(2,a0)
.cont:
	move.l	d0,d3			;save seglist
	movem.l	d0/d1/d4-d6/a0-a6,-(A7)	; save rest of registers

	; allocate some stack space

	lea	-120(a7),a7

	move.l	a7,d4
	addq.l	#2,d4
	and.l	#$FFFFFFFC,d4	; longword aligned
	move.l	d4,a0
	move.l	d2,a1
	addq.l	#1,a0
.copy
	move.b	(a1)+,(a0)+
	bne.b	.copy
	sub.l	d4,a0
	move.l	d4,a1
	move.l	a0,d5
	subq.l	#2,d5
	move.b	d5,(a1)		; BSTR length
	
	move.l	d4,d0
	lsr.l	#2,d0		; BSTR name
	move.l	d3,d1		; seglist

	; call user routine

	bsr	_cb_dosLoadSeg

	; free the stack space

	lea	120(a7),a7

	; cache flush

	bsr	_flushcache

	; restore registers and return to caller

	movem.l	(a7)+,d0/d1/d4-d6/a0-a6
	movem.l	(a7)+,D2-D3
	tst.l	d0
	rts
		
	ENDC

	IFD	INITAGA
init_aga
	movem.l	d0-d1/a0-a1/a6,-(a7)

	; enable enhanced gfx modes

	lea	.gfxname(pc),A1
	moveq	#0,D0
	move.l	$4.W,A6
	jsr	_LVOOpenLibrary(a6)
	move.l	D0,a6
	move.l	#SETCHIPREV_BEST,D0
	jsr	_LVOSetChipRev(a6)

	movem.l	(a7)+,d0-d1/a0-a1/a6
	rts

.gfxname:
	dc.b	"graphics.library",0
	even

	ENDC

	IFD _bootearly
do_bootearly:
	IFD	INITAGA
	bsr	_INITAGA
	ENDC

	; initialize audio device

	IFD	INIT_AUDIO
	lea	.audioname(pc),a1
	bsr	.init_resident
	ENDC
	IFD	INIT_GADTOOLS
	lea	.gadtoolsname(pc),a1
	bsr	.init_resident
	ENDC
	IFD	INIT_INPUT
	lea	.inputname(pc),a1
	bsr	.init_resident
	ENDC
	IFD	INIT_MATHFFP
	lea	.mathffpname(pc),a1
	bsr	.init_resident
	ENDC
	bra	_bootearly

	IFD	INIT_AUDIO
.audioname:
	dc.b	"audio.device",0
	ENDC
	IFD	INIT_GADTOOLS
.gadtoolsname:
	dc.b	"gadtools.library",0
	ENDC
	IFD	INIT_MATHFFP
.mathffpname:
	dc.b	"mathffp.library",0
	ENDC
	IFD	INIT_INPUT
.inputname:
	dc.b	"input.device",0
	ENDC

	even
.init_resident:
	move.l	$4.W,A6
	jsr	_LVOFindResident(a6)
	tst.l	D0
	bne.b	.ok
	illegal
.ok
	move.l	D0,A1
	moveq.l	#0,D1
	jsr	_LVOInitResident(a6)
	rts
	ENDC

;============================================================================

clrwait:
	tst.b	$bfe001
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	bra.s	.end
.wait
	tst.b	$bfe001
	tst.b	$bfe001
	BTST	#6,dmaconr+_custom
	BNE.S	.wait
	TST.B	dmaconr+_custom
.end
	move.w	#0,bltsizv
	rts

skip_de1000:
	moveq	#0,D0
	rte

de1000_init
battclock_init
	moveq	#0,D0
	rts

kick_detectfast
	IFEQ FASTMEMSIZE
		sub.l	a4,a4
	ELSE
		move.l	A0,-(a7)

		move.l	4(A7),A0	; return address
		move.l	(_expmem,pc),a4

		IFD	CD32EXTXXX
		add.l	#CD32EXT_KICKSIZE,a4
		ENDC

		add.l	#KICKSIZE,a4
		move.l	a4,6(A0)
		add.l	#FASTMEMSIZE,a4
		bsr	_flushcache

		move.l	(a7)+,A0
	ENDC
		rts

kick_detectchip
	move.l	#CHIPMEMSIZE,a3
	add.l	#$22,(A7)
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

; ROM makes move.b into bitplane registers

exec_snoop1:
	addq.l	#1,d1
	lsr.l	#1,d1
	subq.l	#1,d1
.loop
	move.w	D2,(A0)+
	dbf	D1,.loop
	rts

	;move.w (a7)+,($dff09c) does not work with Snoop/S on 68060
exec_snoopx	move.w	(a7),($dff09c)
		addq.l	#2,a7
		rts

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


;============================================================================

gfx_vbserver	lea	(_cbswitch_cop2lc,pc),a6
		move.l	d0,(a6)
		lea	($bfd000),a6		;original
		rts

_cbswitch	move.l	(_cbswitch_cop2lc,pc),(_custom+cop2lc)
		jmp	(a0)

; JFF: fake PAL (resp NTSC) on a NTSC (resp PAL) amiga
gfx_read_vpos
	move	(vposr+_custom),d0
	IFD	FORCEPAL
	bclr	#12,d0
	ELSE
		IFD	FORCENTSC
		bset	#12,d0
		ELSE
	
		; no FORCEPAL or FORCENTSC: change agnus ID
		; according to tooltypes

		move.l	d1,-(a7)
		move.l	(_monitor,pc),d1
		cmp.l	#PAL_MONITOR_ID,d1
		beq.b	.pal
		; ntsc
		bset	#12,d0
		bra.b	.sk
.pal
		bclr	#12,d0
.sk
		move.l	(a7)+,d1
		ENDC
	ENDC
	

	rts


	;move (custom),(cia) does not work with Snoop/S on 68060
gfx_snoop1	move.b	(vhposr,a0),d0
		move.b	d0,(ciatodlow,a6)
		rts

gfx_detectgenlock
		moveq	#0,d0
		rts

gfx_detectdisplay
		moveq	#4,d0			;pal
		move.l	(_monitor,pc),d1
		cmp.l	#PAL_MONITOR_ID,d1
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
		add.l	#$ad72-$ad5e-6,(a7)
		rts

	;somewhere there will used a empty view, too stupid
gfx_fix1	move.l	(v_LOFCprList,a1),d0
		beq	.s1
		move.l	d0,a0
		move.l	(4,a0),(gb_LOFlist,a3)
.s1		move.l	(v_SHFCprList,a1),d0
		beq	.s2
		move.l	d0,a0
		move.l	(4,a0),(gb_SHFlist,a3)
.s2		add.l	#$d5d2-$d5be-6,(a7)
		rts

;============================================================================

disk_getunitid
	; compute number of drives

	IFEQ NUMDRIVES
		; NUMDRIVES = 0: try to read CUSTOM1
		clr.l	-(a7)
		subq.l	#4,a7
		pea	WHDLTAG_CUSTOM1_GET
		move.l	a7,a0
		move.l	(_resload,pc),a1
		jsr	(resload_Control,a1)
		addq.l	#4,a7
		move.l	(a7),d1
		addq.l	#8,a7
		tst.l	d1
		bne.b	.nz
		moveq.l	#1,d1	; 0 or less: set 1		
.nz
		cmp.l	#5,d1
		bcs.b	.le4
		moveq.l	#4,d1	; 5 or more: set 4
.le4
	ELSE
		moveq	#NUMDRIVES,d1
	ENDC
		moveq.l	#1,d0
		addq.l	#2,d1
		lsl	d1,d0	; 2^(numdrive+3-1)

		moveq	#-1,D1
		cmp.b	d3,d0
		bcs.b	.d	; no more drives
		moveq	#0,D1
.d
		move.l	D1,(A3)+
		move.l	D1,D0
		rts

;============================================================================

timer_init	move.l	(_time),a0
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
		movem.l	(a7)+,d2/a2-a3		;original
		rts

;============================================================================

trd_format
trd_readwrite	movem.l	d2/a1-a2,-(a7)

		moveq	#0,d1
		move.b	(99,a3),d1		;unit number (67 in kick 1.3)
		clr.b	(IO_ERROR,a1)

		btst	#1,(96,a3)		;disk inserted? (64 in 1.3)
		beq	.diskok

		move.b	#TDERR_DiskChanged,(IO_ERROR,a1)
		
.end		movem.l	(a7),d2/a1-a2
		bsr	trd_endio
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

trd_motor	moveq	#0,d0
		bchg	#7,(97,a3)		;motor status (65 in 1.3)
		seq	d0
		rts

trd_protstatus	moveq	#0,d0
		move.b	(99,a3),d1		;unit number
		move.b	(_trd_prot,pc),d0
		btst	d1,d0
		seq	d0
		move.l	d0,(IO_ACTUAL,a1)

		add.l	#$d74-$d5a-6,(a7)	;skip unnecessary code
		rts

trd_endio	move.l	(_expmem,pc),-(a7)	;jump into rom

		add.l	#$453A4,(a7)
		rts

tdtask_cause	move.l	(_expmem,pc),-(a7)	;jump into rom

		add.l	#$44BDC,(a7)
		rts

trd_task
	IFD DISKSONBOOT
		bclr	#1,(96,a3)		;set disk inserted (40 in 1.3)
		beq	.1
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause
.1
	ENDC
		move.b	(67,a3),d1		;unit number
		lea	(_trd_chg,pc),a0
		bclr	d1,(a0)
		beq	.2			;if not changed skip

		bset	#1,(64,a3)		;set no disk inserted
		bne	.3
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause
.3
		bclr	#1,(64,a3)		;set disk inserted
		addq.l	#1,($126,a3)		;inc change count
		bsr	tdtask_cause

.2		rts

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

;============================================================================

	IFND _bootearly
	IFND _bootblock

dos_init	move.l	#$10001,d1
		bra	_flushcache

dos_1		move.l	#$118,d1		;original
		bra	_flushcache

	ENDC
	ENDC

	IFD  _bootdos
dos_bootdos
	IFD	INITAGA
	bsr	init_aga
	ENDC

	;init boot exe
		lea	(_bootdos,pc),a0
		move.l	a0,(bootfile_exe_j+2-_bootdos,a0)

	;fake startup-sequence
		lea	(bootname_ss_b,pc),a0	;bstr
		addq.l	#1,a0
		move.l	a0,d1

	;return
		rts

	IFND	BOOTFILE_MACRO
BOOTFILE_MACRO:MACRO
	dc.b	"WHDBoot.exe"
	ENDM
	ENDC

	CNOP 0,4
bootname_ss_b	dc.b	10		; strlen(bootname_ss)
bootname_ss	dc.b	"WHDBoot.ss",0
bootfile_ss	BOOTFILE_MACRO
	dc.b	10
bootfile_ss_e
bootname_exe	BOOTFILE_MACRO
	dc.b	0
	EVEN
bootfile_exe	dc.l	$3f3,0,1,0,0,2,$3e9,2
bootfile_exe_j	jmp	$99999999
		dc.w	0
		dc.l	$3f2
bootfile_exe_e
	ENDC


;============================================================================
;
; BootNode
; 08 LN_TYPE = NT_BOOTNODE
; 0a LN_NAME -> ConfigDev
;		10 cd_Rom+er_Type = ERTF_DIAGVALID
;		1c cd_Rom+er_Reserved0c -> DiagArea
;					   00 da_Config = DAC_CONFIGTIME
;					   06 da_BootPoint -> .bootcode
;					   0e da_SIZEOF
;		44 cd_SIZEOF
; 10 bn_DeviceNode -> DeviceNode (exp.MakeDosNode)
*		      04 dn_Type = 2
;		      24 dn_SegList -> .seglist
;		      2c dn_SIZEOF
; 14 bn_SIZEOF


;============================================================================

	IFD HDINIT

hd_init:
	movem.l	D2/A2-A6,-(A7)	
	move.l	#-1,A2
	bsr	.init
	movem.l	(A7)+,D2/A2-A6
;;	moveq	#0,D0		; original
	rts

.init
	INCLUDE	kickfs.s

	ENDC

;============================================================================

_flushcache	move.l	(_resload,pc),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

_waitvb
.1		btst	#0,(_custom+vposr+1)
		beq	.1
.2		btst	#0,(_custom+vposr+1)
		bne	.2
		rts

	IFD DEBUG
_debug1		tst	-1	;unknown packet (=d2) for dos handler
_debug2		tst	-2	;no lock given for a_copy_dir (dos.DupLock)
_debug3		tst	-3	;error in _dos_assign
_debug4		tst	-4	;wrong mode while read
_debug5		tst	-5	;wrong mode while write
		illegal		;security if executed without mmu
	ENDC

;---------------
; performs a C:Assign
; IN:	A0 = BSTR destination name (null terminated BCPL string, at long word address!)
;	A1 = CPTR directory (could be 0 meaning SYS:)
; OUT:	-

	IFD	DOSASSIGN
_dos_assign	movem.l	d2/a3-a6,-(a7)
		move.l	a0,a3			;A3 = name
		move.l	a1,a4			;A4 = directory

	;get memory for node
		move.l	#DosList_SIZEOF,d0
		move.l	#MEMF_CLEAR,d1
		move.l	(4),a6
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

_kick		dc.b	"40068.a1200",0
	EVEN
_tags		dc.l	WHDLTAG_CBSWITCH_SET
_cbswitch_tag	dc.l	0
		dc.l	WHDLTAG_ATTNFLAGS_GET
_attnflags	dc.l	0
		dc.l	WHDLTAG_MONITOR_GET
_monitor	dc.l	0
		dc.l	WHDLTAG_TIME_GET
_time		dc.l	0
		dc.l	0
_resload	dc.l	0
_cbswitch_cop2lc	dc.l	0

;============================================================================

