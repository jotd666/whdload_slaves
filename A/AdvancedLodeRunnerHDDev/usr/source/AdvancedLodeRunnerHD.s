; slave for "Tiny Bobble"
;
; history
; - first release used kickstart emulation
; - next release got rid of kickstart but failed
;   relocating exec hunks properly, resulting in some
;   (not all) trashed graphics due to improper blits from fastmem
; - last update fixed that chunk reloc: game runs properly

		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
        INCLUDE	exec/io.i
        INCLUDE	exec/memory.i
        INCLUDE	lvo/exec.i

		IFD BARFLY
		OUTPUT	"TinyBobble.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC


CHIP_ONLY

STACKSIZE = $1000


    IFD CHIP_ONLY
CHIPMEM = $E0000
EXPMEM = STACKSIZE*2

    ELSE
CHIPMEM = $80000
EXPMEM = $70000+STACKSIZE*2
    ENDC
    
;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem 		;ws_flags
		dc.l	CHIPMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
; add $1000 so game doesn't go access fault by overwriting
; top of stack...
_expmem		dc.l	EXPMEM+$1000			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
		
;============================================================================
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"1.3"
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
	
_name		dc.b	"Advanced Lode Runner"
    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
_copy		dc.b	"1988 xx",0
_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_data		dc.b	"data",0
program:
	dc.b	"AdvancedLodeRunner",0

_config

        ;dc.b    "C3:B:keep LMB as quit button;"
		dc.b	0

		EVEN




;======================================================================
_start						;a0 = resident loader
;======================================================================
        lea _custom,a6
        move.w  #$7FFF,dmacon(a6)
        move.l  #$FFFFFFFE,$100.W
        move.l  #$100,cop1lc(a6)
        move.w  #$200,bplcon0(a6)
        
        
		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

        ; install fake exec for DoIO
        lea $1000.W,A6
        move.l  A6,4.W
        move.l  #$FF,d0
        move.l  #$4AFC4AFC,d1   ; trash other vectors just in case...
.loop
        move.l  d1,-(a6)
        dbf d0,.loop
        move.l  4.W,a6
        lea (_LVODoIO,a6),a0
        move.w  #$4EF9,(a0)+
		pea		_doio(pc)
		move.l	(a7)+,(a0)

        move.l  _expmem(pc),A7
        add.l   #EXPMEM,A7 ; ssp stack on top of fastmem
        move.l  A7,A0        
        sub.l   #STACKSIZE,A0   ; usb stack just below
        move.l  A0,USP
        move.w  #0,SR
        
		lea		game_address(pc),a0
		IFD	CHIP_ONLY
		move.l	#$1000,(a0)
		ELSE
		move.l	_expmem(pc),(a0)
		ENDC
		
		
		lea	program(pc),a0	;Load main file
		move.l	game_address(pc),a1
        sub.l   #8,a1   ; for segments + align
		move.l	a1,a5
		bsr	_LoadFile
        bsr	_Relocate
        ; patch

		move.l	_resload(pc),a2
        move.l  game_address(pc),d0
        subq.l  #4,d0
        lsr.l   #2,d0
        move.l  d0,a1
        lea pl_main(pc),a0
        jsr resload_PatchSeg(a2)      
 		move.l	game_address(pc),-(a7)
        rts


pl_main
	PL_START
	PL_S	0,$98		; skip OS startup shit
	PL_PSS	$07152,dbf_delay,2
	PL_PS	$002fc,sync
	PL_PS	$00810,sync
	PL_PS	$00960,sync
	PL_PS	$01320,sync
	PL_PS	$01398,sync
	PL_PS	$01514,sync
	PL_PS	$0157a,sync
	PL_PS	$01b60,sync
	PL_PS	$051e6,sync

	PL_P	$013f0,_quit
    PL_END

; TODO: smc
;VIOLATION:AdvancedLodeRunner.asm:7977:self-modifying code
;        MOVE.B  D0,LAB_0328+3           ;07352: 13c000006f83
;VIOLATION:AdvancedLodeRunner.asm:7679:self-modifying code target here
;LAB_0328:
;        CMPI.W  #$0006,LAB_0358         ;06f80: 0c790006000073ca
		

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

; < D0: value of D0 in line
; .x: DBF D0,x
dbf_delay
	move.w	#12,d0
	bra	beamdelay
	
sync:
	move.b	$BFEC01,D0
	ror.b	#1,d0
	not.b	d0
	cmp.b	_keyexit(pc),d0
	beq	_quit
	MOVE.L	$DFF004,D0		;01320: 203900dff004
	rts
	
_doio
	movem.l	d0-d2/a0-a2,-(sp)
	move.w	IO_COMMAND(a1),d0
	cmp.w	#2,d0
	beq.b	.read
	cmp.w	#9,d0
	beq	.out
	cmp.w	#14,d0
	beq.b	.out
	cmp.w	#15,d0
	beq.b	.out
	blitz
.read
	move.l	_resload(pc),a2
	move.l	IO_DATA(A1),a0
	move.l	IO_OFFSET(a1),d0
	move.l	IO_LENGTH(a1),d1
	moveq.l	#1,d2
	jsr	resload_DiskLoad(a2)
.out
	movem.l	(sp)+,d0-d2/a0-a2
	clr.l	d0
	rts
		
;======================================================================
_LoadFile	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Relocate	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		move.l	a5,a0
        clr.l   -(a7)                   ;TAG_DONE
        pea     -1                      ;true
        pea     WHDLTAG_LOADSEG
    IFND CHIP_ONLY        
        move.l  #$1000,-(a7)       ;chip area
        pea     WHDLTAG_CHIPPTR        
    ENDC
        pea     8                       ;8 byte alignment
        pea     WHDLTAG_ALIGN
        move.l  a7,a1                   ;tags		move.l	_resload(pc),a2
		jsr	resload_Relocate(a2)
    IFND CHIP_ONLY        
        add.w   #7*4,a7
    ELSE
        add.w   #5*4,a7
    ENDC
        movem.l	(sp)+,d0-d1/a0-a2
		rts

 
		
		
;======================================================================
_resload	dc.l	0			;Resident loader
game_address
    dc.l    0
    
tag
		dc.l	WHDLTAG_CUSTOM2_GET
button_config	dc.l	0
    dc.l    0
        dc.l   0
;======================================================================

_quit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts
prev_joy1   dc.l    0
loaded_highscore
    dc.l    0
highname
    dc.b    "highscore",0
		END
