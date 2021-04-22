
		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"TinyGalaga.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

    IFD CHIP_ONLY
CHIPMEM = $100000
EXPMEM = 0
MEMBASE = $30000
    ELSE
CHIPMEM = $80000
EXPMEM = $40000
MEMBASE = $100
    ENDC
    
;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError 		;ws_flags
		dc.l	CHIPMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
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
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	
_name		dc.b	"Tiny Galaga"
    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
_copy		dc.b	"2020 pink^abyss",0
_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_data		dc.b	"data",0
program:
	dc.b	"aYS_Tiny_Galaga",0

_config
        dc.b    "C3:B:keep LMB as quit button;"
		dc.b	0

		EVEN

;======================================================================
_start						;a0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

        bsr _SetupKeyboard
        
        lea game_address(pc),a0
        IFD CHIP_ONLY
        move.l   #$100,d0
        ELSE        
        move.l  _expmem(pc),d0
        ENDC
        add.l   #8,d0
        move.l  d0,(a0)
        
        lea	_Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		
		lea	program(pc),a0	;Load main file
		move.l	game_address(pc),a1
        sub.l   #8,a1   ; for segments + align
		move.l	a1,a5
		bsr	_LoadFile
        bsr	_Relocate
        ; patch decrunch

        move.l  game_address(pc),d0
        subq.l  #4,d0
        lsr.l   #2,d0
        move.l  d0,a1
        lea pl_boot(pc),a0
        jsr resload_PatchSeg(a2)      
 		move.l	game_address(pc),-(a7)
        rts

pl_boot
	PL_START
    PL_P    $1736e,end_unpack
    PL_P $16,jump_decrunch
	PL_END

pl_main
	PL_START
    ; skip OS shit
    PL_S    $7c,$b8-$7C
    PL_PS   $136,alloc_chipmem_1
    PL_PS   $688,alloc_chipmem_2
    PL_PS   $16c,alloc_fastmem
    PL_S    $1A6,$1cc-$1A6
    PL_S    $220,$240-$220
    
    PL_ORW  $2bc+2,8    ; enable keyboard
    PL_ORW  $6e2+2,8    ; enable keyboard
    PL_S    $262,$6a6-$262  ; this is a 68000, don't touch vbr, mmu...
    PL_R    $2532              ; skip debug code
    PL_IFC3
    PL_ELSE
    PL_NOP  $4ac,2                ; skip LMB quit
    PL_B    $510,$60            ; skip LMB quit
    PL_ENDIF
    PL_STR  $13885,<FIGHTER CAPTURED>   ; fix text
    PL_P    $512,_quit
	PL_END
    
alloc_chipmem_1
    move.l  #MEMBASE,D0
    rts
alloc_chipmem_2
    move.l  #MEMBASE+$4B008,D0
    rts
alloc_fastmem    
    ; chip only mode
    IFD    CHIP_ONLY
    move.l  #MEMBASE+$5B010,D0
    ELSE
    move.l  _expmem(pc),d0
    add.l   #$2F000,d0
    ENDC
    
    rts

jump_decrunch
    jmp (a4)
    
CIAA_PRA = $bfe001
CIAA_SDR = $BFEC01


    
end_unpack
    move.l  (8,a7),a0   ; return address: patch base
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    move.l  a0,a1
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)
    
    movem.l (a7)+,d0-d1/a0-a2
	MOVEM.L	(A7)+,D0/A0		;17388: 4cdf0101
	rts
    
    include whdload/keyboard.s

;======================================================================
_LoadFile	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Relocate	movem.l	d0-d1/a0-a2,-(sp)
		move.l	a5,a0
        clr.l   -(a7)                   ;TAG_DONE
        pea     -1                      ;true
        pea     WHDLTAG_LOADSEG
        pea     8                       ;8 byte alignment
        pea     WHDLTAG_ALIGN
        move.l  a7,a1                   ;tags		move.l	_resload(pc),a2
		jsr	resload_Relocate(a2)
        add.w   #5*4,a7
        movem.l	(sp)+,d0-d1/a0-a2
		rts


		
		
;======================================================================
_resload	dc.l	0			;Resident loader
_FreeMem	dc.l	$30000
game_address
    dc.l    0
    
_Tags		dc.l	WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_Custom1	dc.l	0
		dc.l	TAG_DONE
;======================================================================

_quit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
