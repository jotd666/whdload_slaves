;*---------------------------------------------------------------------------
;  :Program.    DeathMaskHD.asm
;  :Contents.   Slave for "DeathMask" from 
;  :Author.     Keith Krellwitz
;  :History.    09.05.98
;  :Requires.   -
;  :Copyright.  Public Domain
;  :Language.   68000 Assembler
;  :Translator. Phxass
;  :To Do.
;---------------------------------------------------------------------------*

        INCDIR  Include:
        INCLUDE whdload.i

        IFD    BARFLY
        IFD AGA
        OUTPUT  DeathMaskAGA.slave
        ELSE
        OUTPUT  DeathMaskECS.slave
        ENDC
        OPT     O+ OG+                  ;enable optimizing
        ENDC
        
BASEFLAGS = WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd 
    IFD AGA
CHIPMEMSIZE = $200000
FLAGS = BASEFLAGS|WHDLF_ReqAGA 
    ELSE*
CHIPMEMSIZE = $100000
FLAGS = BASEFLAGS 
    ENDC
;======================================================================

base
                SLAVE_HEADER            ;ws_Security + ws_ID
                dc.w    10               ;ws_Version
                dc.w    FLAGS   ;ws_flags
                dc.l    CHIPMEMSIZE         ;ws_BaseMemSize
                dc.l    0               ;ws_ExecInstall
                dc.w    Start-base      ;ws_GameLoader
                dc.w    0               ;ws_CurrentDir
                dc.w    0               ;ws_DontCache
_keydebug       dc.b    $58             ;ws_keydebug = F9
_keyexit        dc.b    $59             ;ws_keyexit = F10
_expmem         dc.l    $0              ;ws_ExpMem
                dc.w    _name-base      ;ws_name
                dc.w    _copy-base      ;ws_copy
                dc.w    _info-base      ;ws_info

;======================================================================
DECL_VERSION:MACRO
	dc.b	"1.2"
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
_name           dc.b    "Death Mask "
            IFD AGA
            dc.b    "AGA"
            ELSE
            dc.b    "ECS"
            ENDC
            dc.b    0
_copy           dc.b    "1995 Alternative",0
_info           dc.b    "Installed by Abaddon & JOTD",10,10
                dc.b    "Version "
                DECL_VERSION
                dc.b    0
                EVEN
_trainer
       	    dc.b    $5f
                EVEN

;======================================================================
Start   ;       A0 = resident loader
;======================================================================

        lea     _resload(pc),a1
        move.l  a0,(a1)                                 ;save for later use

        move.w  #$7fff,$dff096
        move.w  #$7fff,$dff09a
        move.w  #$7fff,$dff09c


	lea     $422,a0
	moveq	  #$1,d2
	move.l  #$b*$200,d0
	move.l  #$21*$200,d1
	move.l  (_resload,pc),a2
	jsr     (resload_DiskLoad,a2)
    
    move.l  _resload(pc),a2
    sub.l   a1,a1
    lea _pl_intro(pc),a0
    jsr resload_Patch(a2)

	lea     $a498,a5
;	move.l  #$200000,$400
;	move.l  #$100000,$404
      move.l  #CHIPMEMSIZE,$400
      move.l  #$0,$404
	move.l  #$ffffffff,$408
	move.l  #$ffffffff,$40c
	move.l  #$ffffffff,$410
	move.l  #$ffffffff,$414
	move.l  #$ffffffff,$418
	move.l  #$ffffffff,$41c
	lea     $ffffc,a6
	move.l  a6,a7
	move.l  #$100000,d7
	move.l  #$110000,d6
	move.l  #$80000,d3
	bsr	  _FlushCache
	jmp     $422.w

_pl_intro:
    PL_START
	PL_P $ab6,_LoadTracksIntro
	PL_P $4ee,_PatchLoader
	PL_P	$1cf4,_Decrunch
    PL_END
    
_LoadTracksIntro
        move.l  d0,$a78
        move.l  d1,$a7c
        move.l  d1,$a6a
        movem.l d0-a6,-(a7)
.notyet
        addi.l  #$4,d0
        moveq   #$4,d1
        moveq   #$1,d2
        movem.l d0/a0,-(a7)
        move.l  (_resload,pc),a2
        jsr     (resload_DiskLoad,a2)
        movem.l (a7)+,d0/a0
        cmpi.l  #$46494c45,(a0)
        beq     .notyet
        move.l  (a0),d7
        move.l  d7,$a6a
        divu    #$4,d7
        andi.l  #$ffff,d7
        subi.l  #$1,d7
.keeploading
        addi.l  #$4,d0
        moveq   #$4,d1
        moveq   #$1,d2
        movem.l d0/a0,-(a7)
        move.l  (_resload,pc),a2
        jsr     (resload_DiskLoad,a2)
        movem.l (a7)+,d0/a0
        cmpi.l  #$444d5f41,(a0)
        beq     .keeploading
        cmpi.l  #$444d5f42,(a0)
        beq     .keeploading
        cmpi.l  #$444d5f43,(a0)
        beq     .keeploading
        cmpi.l  #$444d5f44,(a0)
        beq     .keeploading
        add.l   #$4,a0
        dbf     d7,.keeploading
        bra     .finish
.finish
        move.l  $a6a,d7
        divu    #$4,d7
        swap    d7
        andi.l  #$ffff,d7
        tst.w   d7
        beq     .alldone
        move.l  d7,d1
        addi.l  #$4,d0
        moveq   #$1,d2
        movem.l d0/a0,-(a7)
        move.l  (_resload,pc),a2
        jsr     (resload_DiskLoad,a2)
        movem.l (a7)+,d0/a0
.alldone
        movem.l (a7)+,d0-a6
        move.w  $a74,(a3)
        bsr		_FlushCache
        rts

_PatchLoader
      cmpi.l  	#$48e7fffe,$3a6b6
      beq     	.patchloader
	bra		_exit
.patchloader
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    sub.l   a1,a1
    lea _pl_loader(pc),a0
    jsr resload_Patch(a2)
	move.w	$508,d0
	movem.l (a7)+,d0-d1/a0-a2
	jmp		(a6)

_pl_loader
    PL_START
	PL_R    $6cc2	;Bypass AGA check
    IFD AGA
	PL_W    $de80,-1		;0 for ECS (FFFF for AGA)
    ELSE
	PL_CW   $de80		;0 for ECS (FFFF for AGA)
    ENDC
    
	PL_P	$6226,_Decrunch
    PL_P    $3a6b6,_LoadTracksMain
    
    PL_PS   $37C4A,quit_test
    
    PL_END

quit_test:
    move.w  d0,-(a7)
    ror.b   #1,d0
    not.b   d0
    cmp.b   _keyexit(pc),d0
    beq     _exit
    move.w  (a7)+,d0
    BSET.B #$0006,($0e01,a0)
    rts

_Decrunch
        move.l  	(_resload,pc),a2
        jsr       (resload_Decrunch,a2)
        rts

_LoadTracksMain
        move.l  d0,$3a678
        move.l  d1,$3a67c
        move.l  d1,$3a66a
        movem.l d0-a6,-(a7)
        move.l  #$2,d6
        cmpi.l  #$444d5f41,d2
        bne     .diskset
        move.l  #$1,d6
.diskset
.notyet
        addi.l  #$4,d0
        moveq   #$4,d1
        move.l  d6,d2
        movem.l d0/d6/a0,-(a7)
        move.l  (_resload,pc),a2
        jsr     (resload_DiskLoad,a2)
        movem.l (a7)+,d0/d6/a0
        cmpi.l  #$46494c45,(a0)
        beq     .notyet
        move.l  (a0),d7
        move.l  d7,$3a66a
        divu    #$4,d7
        andi.l  #$ffff,d7
        subi.l  #$1,d7
.keeploading
        addi.l  #$4,d0
        moveq   #$4,d1
        move.l  d6,d2
        movem.l d0/d6/a0,-(a7)
        move.l  (_resload,pc),a2
        jsr     (resload_DiskLoad,a2)
        movem.l (a7)+,d0/d6/a0
        cmpi.l  #$444d5f41,(a0)
        beq     .keeploading
        cmpi.l  #$444d5f42,(a0)
        beq     .keeploading
        cmpi.l  #$444d5f43,(a0)
        beq     .keeploading
        cmpi.l  #$444d5f44,(a0)
        beq     .keeploading
        add.l   #$4,a0
        dbf     d7,.keeploading
        bra     .finish
.finish
        move.l  $3a66a,d7
        divu    #$4,d7
        swap    d7
        andi.l  #$ffff,d7
        tst.w   d7
        beq     .alldone
        move.l  d7,d1
        addi.l  #$4,d0
        move.l  d6,d2
        movem.l d0/d6/a0,-(a7)
        move.l  (_resload,pc),a2
        jsr     (resload_DiskLoad,a2)
        movem.l (a7)+,d0/d6/a0
.alldone
        movem.l (a7)+,d0-a6
        move.w  $3a674,(a3)
 	  bsr		_FlushCache
        rts


_exit     pea     TDREASON_OK
          bra     _end
_debug    pea     TDREASON_DEBUG
          bra     _end
_wrongver pea     TDREASON_WRONGVER
_end      move.l  (_resload,pc),-(a7)
          add.l   #resload_Abort,(a7)
          rts

_FlushCache     movem.l d0-d1/a0-a2,-(sp)
                move.l  _resload(pc),a2
                jsr     resload_FlushCache(a2)
                movem.l (sp)+,d0-d1/a0-a2
                rts

;--------------------------------
save:
        dc.b    "hs.bin",0
        even
_resload        dc.l    0               ;address of resident loader

;--------------------------------
; IN:   d0=offset d1=size d2=disk a0=dest
; OUT:  d0=success


;======================================================================

        END
