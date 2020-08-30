; Generic Sierra Trackdisk patches
; used in:
;
; - Colonel's Bequest
; - Conquest Of Camelot
; - Codename Iceman


	INCDIR	Include:
	INCDIR	osemu:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/intuition.i
	INCLUDE	lvo/dos.i
	INCLUDE	dos/dos.i

;define SAVEDISK_NUMBER here, usually 6 or 7
;unit for the diskimage containing the gamesaves

DISKSONBOOT
TRDCHANGEDISK
NUMDRIVES	= 4
WPDRIVES	= %1000	; unit 4 (disk.SAVEDISK_NUMBER...) is save game


KICKSIZE	= $40000		;34.005
BASEMEM		= CHIPMEMSIZE
EXPMEM		= KICKSIZE+FASTMEMSIZE

;============================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	11			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulPriv	;ws_flags
		dc.l	BASEMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

_data		dc.b	"data",0
	even

;============================================================================
_start	;	A0 = resident loader
;============================================================================

	lea	_trd_disk+3(pc),a1
	move.b	#SAVEDISK_NUMBER,(a1)			; set save disk on df3:

		move.l	a0,a2
	;enable cache
		move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
		move.l	#WCPUF_All,d1
		jsr	(resload_SetCPU,a2)
		move.l	a2,a0

	;initialize kickstart and environment
		bra	_boot

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	cmp.b	#4,(a0)
	bne.b	.skip_prog
	cmp.b	#'X',1(a0)
	beq.b	.skip_xlan
	cmp.b	#'p',1(a0)
	bne.b	.skip_prog

	; prog

	movem.l	d1-a6,-(a7)
	bsr	_specific_patch
	movem.l	(a7)+,D1-a6
	tst.l	d0
	bne.b	.nootherpatches

	bsr	_generic_patches

.nootherpatches
	bsr	_open_dos
	bsr	_patch_kb
.skip_prog
	; sound driver patch

	cmp.b	#$C,(a0)
	bne.b	.out

	move.l	d1,a0
	add.l	#$4+$148C,a0
	cmp.l	#$22B62020,(a0)
	bne.b	.nosnd1

	move.l	d1,a0
	add.l	#$4+$149E,a0
	move.w	#$4EB9,(a0)+
	pea	_patch_sound(pc)
	move.l	(a7)+,(a0)
	bra.b	.out
.nosnd1
	move.l	d1,a0
	add.l	#$4+$1498,a0
	cmp.l	#$22B62020,(a0)
	bne.b	.nosnd2

	move.l	d1,a0
	add.l	#$4+$14AA,a0
	move.w	#$4EB9,(a0)+
	pea	_patch_sound(pc)
	move.l	(a7)+,(a0)

.nosnd2
.out
	rts


.skip_xlan
	move.w	#0,d2
	bsr	_get_section
	move.l	#$70004E75,(a0)
	rts

; < d1 seglist
; < d2 section #
; > a0 segment
_get_section
	move.l	d1,a0
	subq	#1,d2
	bmi.b	.out
.loop
	move.l	(a0),a0
	add.l	a0,a0
	add.l	a0,a0
	dbf	d2,.loop
.out
	addq.l	#4,a0
	rts

; < D1: seglist APTR

_generic_patches:
	; section 3

	move.w	#3,d2
	bsr	_get_section

	; close stuff: quit

	add.l	#$28E-$78,a0
	move.w	#$4EF9,(a0)+
	pea	_quit(pc)
	move.l	(a7)+,(a0)

	; section 11: savedisk

	move.l	#11,d2
	bsr	_get_section
	add.l	#$BEA-$870,a0
	move.l	#$4E714EB9,(a0)+
	pea	_savedrive(pc)
	move.l	(a7)+,(a0)

	; section 57:disk change

	move.w	#57,d2
	bsr	_get_section
	lea	_disk_offset(pc),a1
	move.w	310(a0),(a1)		; save disk offset variable for later
	add.l	#444,a0
	move.l	#$4E714EB9,(a0)+
	pea	_set_disk(pc)
	move.l	(a7)+,(a0)
	rts

_savedrive:
	move.l	(8,a5),a1
.copy
	move.b	(a0)+,(a1)+
	bne.b	.copy

	; change DF0 -> DF3

	cmp.b	#'0',-3(a1)
	bne.b	.sk
	move.b	#'3',-3(a1)
.sk	
	rts

_patch_sound:
	movem.l	D0,-(a7)
	move.b	$8(a1),d0
	cmp.b	_expmem(pc),d0
	movem.l	(a7)+,d0
	beq.b	.skip
	MOVE.B	$0020(A6),$0008(A1)
.skip
	rts


; disk swap routine was a bitch!!
; swap disks on df2:
SWAP_DRIVE = 2

_set_disk
;	cmp.l	#0,-20(a5)
;	bne.b	.skip

	; not found: set disk required

	movem.l	D0-D1/D3/A0-A1/A6,-(a7)
	move.w	_disk_offset(pc),d0
	move.w	(a4,d0.w),d3	; disk number required
	cmp.w	#3,d3
	bcs.b	.noneed		; disks 1 & 2 are always available

	move.b	_trd_disk+SWAP_DRIVE(pc),d0
	cmp.b	d0,d3
	beq.b	.noneed
	moveq.l	#SWAP_DRIVE,d0
	move.w	d3,d1
	bsr	_trd_changedisk	; from kick13.s

	; wait 1 second (while the system updates disk stuff)
	; or else system displays a requester:
	; replace volume xxx in unit SWAP_DRIVE
.retry
	move.l	_dosbase(pc),a6
	move.l	#50,d1
	jsr	_LVODelay(a6)

	; try to open file resource.00x

	lea	.resourceidx(pc),a0
	move.b	d3,(a0)	; disk number required, resource.00x
	add.b	#'0',(a0)

	lea	.resourcename(pc),a0
	move.l	a0,d1
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	move.l	d0,d1
	bne.b	.unlock








	bra.b	.retry
.dfname
	dc.b	"DF",SWAP_DRIVE+'0',0
.resourcename
	dc.b	"DF",SWAP_DRIVE+'0',":resource.00"
.resourceidx
	dc.b	"x",0
	even
.unlock
	jsr	_LVOUnLock(a6)


.noneed
	movem.l	(a7)+,D0-D1/D3/A0-A1/A6
.skip
	cmp.l	#5,-20(a5)	; original code
	rts

_wrong_version:
		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

_quit
		PEA	TDREASON_OK
		MOVE.L	_resload(PC),-(A7)
		add.l	#resload_Abort,(a7)
		rts

_open_dos:
	movem.l	D0-A6,-(A7)
	move.l	$4.W,A6
	lea	_dosname(pc),a1
	moveq	#0,d0
	JSR	_LVOOpenLibrary(a6)
	lea	_dosbase(pc),a1
	move.l	d0,(a1)
	movem.l	(A7)+,D0-A6
	rts

_patch_kb
	IFEQ	KICKSIZE-$40000

	lea	.ackkb(pc),A0
	lea	.oldkb(pc),A1
	move.l	$68.W,(A1)
	move.l	A0,$68.W
	rts

.ackkb:
	bset	#6,$BFEE01
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	_beamdelay
	bclr	#6,$BFEE01
	movem.l	(A7)+,D0
	move.l	.oldkb(pc),-(A7)
	rts

.oldkb:
	dc.l	0

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
	ELSE
	rts
	ENDC


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0

_disk_offset:
	dc.l	0

_dosbase:
	dc.l	0
_dosname:
	dc.b	"dos.library",0
	even

;============================================================================

	INCLUDE	kick13.s

;============================================================================
