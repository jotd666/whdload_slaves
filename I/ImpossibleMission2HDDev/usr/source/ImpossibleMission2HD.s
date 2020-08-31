;*---------------------------------------------------------------------------
;  :Program.    elvira.asm
;  :Contents.   Slave for "Elvira" from Accolade
;  :Author.     Wepl
;  :Original    v1 
;  :Version.    $Id: elvira.asm 1.1 2001/11/10 21:13:07 wepl Exp wepl $
;  :History.    03.08.01 started
;               10.11.01 beta version for whdload-dev ;)
;  :Requires.   -
;  :Copyright.  Public Domain
;  :Language.   68000 Assembler
;  :Translator. Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

        INCDIR  Include:
        INCLUDE whdload.i
        INCLUDE whdmacros.i


        IFD BARFLY
        OUTPUT  "ImpossibleMission2.Slave"

        BOPT    O+                              ;enable optimizing
        BOPT    OG+                             ;enable optimizing
        BOPT    ODd-                            ;disable mul optimizing
        BOPT    ODe-                            ;disable mul optimizing
        BOPT    w4-                             ;disable 64k warnings
        SUPER
        ENDC

;============================================================================

CHIPMEMSIZE     = $80000           ; debug access FALSE
FASTMEMSIZE     = $40000
NUMDRIVES       = 1
WPDRIVES        = %1111
CBDOSLOADSEG
DISKSONBOOT
BLACKSCREEN
;HRTMON
;MEMFREE        = $100
;NEEDFPU
SETPATCH

;============================================================================

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

        INCLUDE kick13.s


;============================================================================
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

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

slv_name           dc.b    "Impossible Mission 2",0
slv_copy           dc.b    "1988 Epyx ",0
slv_info           dc.b    "adapted by C-Fou! using Wepl's KickEmul",10
                dc.b    "Version "
				DECL_VERSION
                dc.b    0
slv_CurrentDir           dc.b    0
_runit          dc.b    "Im2",0
        EVEN
_runitb          dc.b    "im2",0
        EVEN
;============================================================================
_start  ;       A0 = resident loader
;============================================================================

        ;initialize kickstart and environment
                bra     _boot

_cb_dosLoadSeg
                move.l d0,d7
                lsl.l   #2,d0
                move.l  d0,a0
                moveq   #0,d0
                add.b   (a0)+,d0
                subq.w  #1,d0
                lea     (_runit,pc),a1
.cmp            cmp.b   (a0)+,(a1)+
                dbne    d0,.cmp
                bne     .no
                lsl.l   #2,d1
                move.l  d1,a0
                bsr crack
.no
                move.l d7,d0
                lsl.l   #2,d0
                move.l  d0,a0
                moveq   #0,d0
                add.b   (a0)+,d0
                subq.w  #1,d0
                lea     (_runitb,pc),a1
.cmpb            cmp.b   (a0)+,(a1)+
                dbne    d0,.cmpb
                bne     .nob
                lsl.l   #2,d1
                move.l  d1,a0
                bsr crack
.nob
               rts

crack
                movem.l d0-d7/a0-a6,-(a7)
                move.l a0,a1
                move.l _expmem(pc),a2
      
;t:
;   bra t
;       btst #$6,$bfe001
;       bne t

;;;;;;;;;;;;;;;;******* Crack v1 ******************

                move.l a1,d0
                add.l #$1fa92-$10174,d0
                move.l d0,a0
                cmp.l #$4eaefe38,(a0)
                bne .pas
                move.w #$4e75,(a0)               ; crack1  ripp illegall inst -$1c8 
.pas

                move.l a1,d0
                add.l #$6ae2-$24,d0
                move.l d0,a0
                cmp.l #$33fc0075,(a0)   ; 33$fc$00$75$00$1$
                bne .pas1
                move.w #$6006,(a0)               ; crack
.pas1

                move.l a1,d0
                add.l #$1c046-$10174,d0
                move.l d0,a0
                cmp.w #$6620,(a0)   ;
                bne .pas1b
                move.w #$6020,(a0)     ; cia accse
.pas1b


;;;;;;;;;;;;;;;;******* Crack v2 ******************

                move.l a1,d0
                add.l #$1fa92-$10174-$68,d0
                move.l d0,a0
                cmp.l #$4eaefe38,(a0)
                bne .pas2
                move.w #$4e75,(a0)               ; crack1  ripp illegall inst -$1c8 
.pas2

                move.l a1,d0
                add.l #$6ae2-$24-$74,d0
                move.l d0,a0
                cmp.l #$33fc0075,(a0)   ; 33$fc$00$75$00$1$
                bne .pas2a
                move.w #$6006,(a0)               ; crack
.pas2a

                move.l a1,d0
                add.l #$1c046-$10174-$74,d0
                move.l d0,a0
                cmp.w #$6620,(a0)   ;
                bne .pas2b
                move.w #$6020,(a0)     ; cia accse
.pas2b


               movem.l (a7)+,d0-d7/a0-a6
                rts

;============================================================================
