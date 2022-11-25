	incdir	include:
	include	whdload.i
	include	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	Indianapolis500.slave

	DOSCMD	"WDate  >T:date"

	ENDC

pushall:MACRO
	movem.l	d0-a6,-(A7)
	ENDM

pullall:MACRO
	movem.l	(a7)+,d0-a6
	ENDM
;;CHIP_ONLY
    IFD CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = $0000
    ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
    ENDC
    
;--- power to the people

_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	11					; ws_version
	dc.w	WHDLF_EmulTrap|WHDLF_NoError	; ws_flags
	dc.l	CHIPMEMSIZE					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	_slave-_base				; ws_gameloader
	dc.w	0					; ws_currentdir
	dc.w	0					; ws_dontcache
	dc.b	0					; ws_keydebug
_keyexit
	dc.b	$5a					; ws_keyexit [numl]
_expmem:
	dc.l	FASTMEMSIZE
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
    
_name		dc.b	"Indianapolis 500"
        IFD CHIP_ONLY
        dc.b    " (DEBUG/CHIP ONLY)"
        ENDC
        dc.b    0
_copy		dc.b	"1990 Papyrus Design Group",0
_info		dc.b	"installed & fixed by Dark Angel & JOTD",10,10
		dc.b	"Version "
        DECL_VERSION
		dc.b	0

		even



;--- bootblock

_slave	lea	_resload(pc),a1
	move.l	a0,(a1)

	lea	_expmem(pc),a0
	tst.l	(a0)
	bne.b	.skip
	move.l	#$80000,(a0)
.skip

	;enable cache
	move.l	_resload(pc),a2
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

	moveq	#0,d0
	move.l	#19*$1600,d1
	sub.l	a0,a0
	moveq	#1,d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

    lea pl_boot(pc),a0
    sub.l   a1,a1
    jsr resload_Patch(a6)
    
	lea	$dff000,a4
	lea	$bfe001,a5
	lea	$bfd000,a6
	move.l	_expmem(pc),d6			; start ext. mem
	move.l	#$100000,d7			; largest mem avail


;	LEA	CHIPMEMSIZE-$20,A7
	jmp	$a040
;---

part1	move.b	$ab7e,d3			; original

	pushall
	move.l	_expmem(pc),a1
	move.l	_resload(pc),a2
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)
	pullall
	rts


;--- disk routines

load1	pushall

	move	$ab80,d0
	mulu	#512,d0
	move.l	#$1600,d1
	moveq	#1,d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

	pullall
	rts
;---

load2	pushall

	mulu	#512,d0
	mulu	#512,d1
	moveq	#1,d2
	move.l	_resload(pc),a6
	jsr	resload_DiskLoad(a6)

	pullall
	rts
;---

saver	pushall

	lea	(a0),a1
	lea	disk1(pc),a0
	exg.l	d0,d1
	mulu	#512,d0
	mulu	#512,d1
	move.l	_resload(pc),a6
	jsr	resload_SaveFileOffset(a6)

	pullall
	rts

kbhook
    MOVE.B $00bfec01,D0
    move.w  d0,-(a7)
    ror.b   #1,D0
    not.b   d0
    cmp.b   _keyexit(pc),d0
    beq.b   quit
    move.w  (a7)+,d0
    rts
quit
    pea	TDREASON_OK
    move.l	(_resload,pc),a2
    jmp	(resload_Abort,a2)
    
pl_boot
	PL_START
	PL_W	0,$1373
	PL_P	$b0be,load1
	PL_PS	$a2a6,part1
        PL_PS   $ABD0,kbhook
	PL_W	$A054,$6004		; skip fastmem masking
    PL_END
    
pl_main
	PL_START
	PL_NOP	$341c6,2			; crack manual protection
	PL_P	$36084,load2
	PL_P	$360c4,saver
    PL_PS   $12750,kbhook
	PL_END


_flushcache:	move.l	(_resload,pc),-(a7)
		add.l	#resload_FlushCache,(a7)
		rts

;--------------------------------
_resload	dc.l	0	;	=
;--------------------------------

;--- file names

disk1	dc.b	'Disk.1',0
