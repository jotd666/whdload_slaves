; Generic Sierra harddisk patches
; used in:
; - Codename: Iceman
; - Conquests of Camelot
; - Colonel's Bequest
; - Leisure Suit Larry 2
; - Leisure Suit Larry 3
; - Quest For Glory
; - ManHunter

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/intuition.i
	INCLUDE	lvo/dos.i
	INCLUDE	dos/dos.i

HDINIT
NUMDRIVES	= 1
WPDRIVES	= %0000
CBDOSLOADSEG


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

; if we don't set this, some games think they're running on floppy
; and ask for disks... (example: Leisure Suit Larry 3 latest version)
HD_Cyls			= 1000

;============================================================================

	INCLUDE	kick13.s

;============================================================================

PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
    cmp.w	#$4EF9,(A1)
    beq.b   end_patch_\1    ; already done
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	old_\1(pc),a0
	move.l	A1,(A0)+

	move.l	A6,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)		; moves to d0_value_xxx

	move.w	#$4EF9,(A1)+	
	pea	new_\1_init(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
new_\1_init
	move.l	d0_value_\1(pc),d0
	bra	new_\1
old_\1:
	dc.l	0
d0_value_\1
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
	ENDM
    
slv_config:
    IFD PATCH_MT32
    dc.b    "C4:B:MT-32 sound;"
    ENDC
    IFD PATCH_KEYBOARD
	dc.b    "C5:L:keyboard:us,fr,de;"	
    ENDC
	dc.b	0

slv_CurrentDir
	dc.b	"data",0
	even

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	; now D1 is start address

	lsl.l	#2,d0
	move.l	d0,a0

	; skip Kixx intro program

	cmp.b	#'X',1(a0)
	beq.w	.skip_xlan

	lea	.prog(pc),a1
	move.l	a0,a3
.cmpstr
	move.b	(a1)+,d2
	beq.b	.ok
	cmp.b	(a3)+,d2
	beq.b	.cmpstr

	IFD	MAINPROG
	lea	_mainprog(pc),a1
	move.l	a0,a3
.cmpstr2
	move.b	(a1)+,d2
	beq.b	.ok
	cmp.b	(a3)+,d2
	beq.b	.cmpstr2
	ENDC
	
	bra.b	.skip_prog

	; prog

.ok
	move.w	#0,d2
	bsr	_get_section
	cmp.w	#$4EF9,(a0)
	bne.b	.skip_prog	; Pixie frontend loaded instead of main interpreter

	movem.l	d1-a6,-(a7)
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    lea	(_tag,pc),a0
    jsr	(resload_Control,a2)
    IFD PATCH_KEYBOARD
    move.l  _keyboard_type(pc),d0
    cmp.l   #3,d0
    bcs.b   .kbbounds
    moveq.l #0,d0
.kbbounds
    
    lea    old_kbint(pc),a1
    lea kbint_hook(pc),a0
    cmp.l   (a1),a0
    beq.b   .done
    move.l  $68.W,(a1)
    move.l  a0,$68.W
.done
    ENDC
    movem.l (a7)+,d0-d1/a0-a2
    lsr.l   #2,d1
    move.l  d1,a1
    moveq.l #0,d0   ; so if specific patch is empty generic patches is done    
	bsr	_specific_patch
	movem.l	(a7)+,D1-a6
	tst.l	d0
	bne.b	.nootherpatches



    
	bsr	_generic_patches

.nootherpatches
.skip_prog
	; sound driver patch

	IFD	PATCH_SOUND

	cmp.b	#$C,(a0)
	bne.b	.out

	; sound driver patch: 2 offsets possible depending
	; on amigasnd.drv version

	move.l	#$20290010,d0
	move.l	d1,a0
	add.l	#$4+$18C4,a0
	cmp.l	(a0),d0
	beq.b	.patchsnd

	move.l	d1,a0
	add.l	#$4+$18D6,a0
	cmp.l	(a0),d0
	bne.b	.nosnd
.patchsnd
	move.l	#$4E714EB9,(a0)+
	pea	_patch_sound(pc)
	move.l	(a7)+,(a0)
	bra	.out
.nosnd
	ENDC

.out
	rts


.skip_xlan
	move.w	#0,d2
	bsr	_get_section
	move.l	#$70004E75,(a0)
	rts

.prog:
	dc.b	4,"prog",0
	even
    

    IFD PATCH_MT32
patch_mt32_open
    PATCH_DOSLIB_OFFSET Open
    PATCH_DOSLIB_OFFSET Lock
    
    lea	.mt32_driver(pc),a0
    move.l	_resload(pc),a2
    jsr	resload_GetFileSize(a2)
    tst.l   d0
    bne.b   .okay
    pea	.missingmt32_message(pc)
    pea	TDREASON_FAILMSG
    move.l	(_resload,pc),-(a7)
    add.l	#resload_Abort,(a7)
    rts
.okay
    rts

.mt32_driver:
    dc.b    "mt32.drv",0
.missingmt32_message
    dc.b    "file mt32.drv is missing.",10
    dc.b    "Make sure that game was properly installed",0
    even
    
new_Lock
    move.l  d1,a0
    bsr _rename_mt32
    bsr _rename_file        ; must be defined by specific program
    move.l  a0,d1
    move.l  old_Lock(pc),-(a7)
    rts
   
new_Open
    move.l  d1,a0
    bsr _rename_mt32
    bsr _rename_file
    move.l  a0,d1
    move.l  old_Open(pc),-(a7)
    rts

_rename_mt32:
    cmp.b   #'C',(9,a0)   ; RESOURCE.CFG
    bne.b   .nores
    cmp.b   #'F',(10,a0)
    bne.b   .nores
    cmp.b   #'R',(a0)
    bne.b   .nores
    lea .mt32resname(pc),a0
.nores
    rts
.mt32resname
    dc.b    "res_mt32.cfg",0
        even
strip_colon
    ; strip colon if volume name is whdload
    move.l  d1,a0
    cmp.b   #':',(7,a0)
    bne.b   .nocolon
    addq.l  #8,a0
.nocolon
    rts

    ENDC
    IFD PATCH_KEYBOARD
kbint_hook:
    movem.l  a0-a1/d0-d3,-(a7)
    move.b  $BFEC01,d0
    ror.b   #1,d0
    not.b   d0
    moveq.l #0,d1
    bclr    #7,d0
    sne     d1
    lea kb_table(pc),a0
    move.l  _keyboard_type(pc),d2
    add.l   d2,d2
    move.w  (a0,d2.w),a1
    add.w   a1,a0
    
.loop
    move.b  (a0)+,d2
    bmi.b   .noswap
    move.b  (a0)+,d3
    cmp.b   d0,d2
    bne.b   .loop
    move.b  d3,d0

.pack
    tst.b   d1
    beq.b   .norel
    bset    #7,d0   ; key released
.norel
    not.b   d0
    rol.b   #1,d0
    move.b  d0,$BFEC01    
.noswap
    movem.l  (a7)+,a0-a1/d0-d3
    
    move.l  old_kbint(pc),-(a7)
    rts

    
old_kbint:
    dc.l    0

kb_table:
    dc.w    us-kb_table,french-kb_table,deutsch-kb_table

us:
    dc.b    -1
french:
    dc.b    $10,$20   ; a <-> q
    dc.b    $20,$10   ; a <-> q
    dc.b    $11,$31   ; w <-> z
    dc.b    $31,$11   ; w <-> z
    dc.b    $29,$37   ; m <-> ,
    dc.b    $37,$38   ; m <-> ,
    dc.b    -1    
deutsch:
    dc.b    $15,$31   ; y -> z
    dc.b    $31,$15   ; z -> y
    dc.b    -1    
    even
    ENDC
	IFD	PATCH_SOUND
_patch_sound:
	cmp.l	#CHIPMEMSIZE,A1
	bcs.b	.ok
	cmp.l	_expmem(pc),a1
	bcc.b	.ok

	; address problem: MSB has been tampered with
	; restore it

	; MSB from 1 to 5
	
	move.l	a1,d0
	ror.l	#8,d0
	cmp.b	#5,d0
	bcc.b	.restore_msb	

	clr.b	d0
	rol.l	#8,d0
	bra.b	.out

.restore_msb
	; MSB completely broken

	move.l	a1,d0
	move.l	d1,-(a7)
	move.b	_expmem(pc),d1
	ror.l	#8,d1
	or.l	d1,d0
	move.l	(a7)+,d1
.out
	move.l	d0,a1
.ok
	MOVE.L	$0010(A1),D0
	MOVE.L	D0,$0008(A0)
	rts
	ENDC

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

	add.l	#$216,a0
	cmp.l	#$48E760E2,(a0)
	beq.b	.pq
	add.l	#$28-$16,a0
	cmp.l	#$48E760E2,(a0)
	beq.b	.pq
	bra.b	.spq
.pq
	move.w	#$4EF9,(a0)+
	pea	_quit(pc)
	move.l	(a7)+,(a0)
.spq
	; section 11: savedisk/unlock bug

	move.l	#11,d2
	bsr	_get_section
	add.l	#$37A,a0
    cmp.l   #$226d0008,(a0)
    beq.b   .nosave
	move.l	#$4E714EB9,(a0)+
	pea	_savedrive(pc)
	move.l	(a7)+,(a0)
.nosave

	move.l	#11,d2
	bsr	_get_section
	add.l	#$368,a0
    cmp.w   #$2f0e,(a0)
    bne.b   .nosunlock
	move.w	#$600A,(a0)	; skip unlock of root dir: crashes kickemu in dos mode
.nosunlock

	; no more dos.DeleteFile (avoids os swaps)

	movem.l	d0-d1/a0-a2/a6,-(a7)
	lea	.dosname(pc),a1
	move.l	$4.W,a6
	jsr	_LVOOldOpenLibrary(a6)
	
	move.l	d0,a6
    move.l  d0,a0
	add.w	#_LVODeleteFile,a0
	move.w	#$4EF9,(a0)+
	lea	_deletefile(pc),a1
	move.l	a1,(a0)

    IFD PATCH_MT32
    move.l  _mt32_support(pc),d0
    beq.b   .nomt32
    
    bsr patch_mt32_open
.nomt32
    ENDC
    
	; enable caches

	move.l	_resload(pc),a2
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	movem.l	(a7)+,d0-d1/a0-a2/a6

	rts


.dosname
	dc.b	"dos.library",0
	even

_deletefile:
	moveq.l	#-1,D0
	rts

_savedrive:
	move.l	a0,-(A7)
	move.l	(8,a5),a1
	lea	.s(pc),a0
.copy
	move.b	(a0)+,(a1)+
	bne.b	.copy
	move.l	(a7)+,a0
	rts

.s:
	dc.b	"SYS:save",0
	even
	
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

	IFEQ	1
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
	ENDC

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
    IFD PATCH_KEYBOARD
    dc.l	WHDLTAG_CUSTOM5_GET
_keyboard_type	dc.l	0
    ENDC
    IFD PATCH_MT32
    dc.l	WHDLTAG_CUSTOM4_GET
_mt32_support	dc.l	0
    ENDC
		dc.l	0
