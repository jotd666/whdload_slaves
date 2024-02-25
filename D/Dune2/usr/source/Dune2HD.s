

        INCDIR  Include:
        INCLUDE whdload.i
        INCLUDE whdmacros.i

        IFD BARFLY
        OUTPUT  "dune2.Slave"
        BOPT    O+                              ;enable optimizing
        ;BOPT    OG+                             ;enable optimizing
        BOPT    ODd-                            ;disable mul optimizing
        BOPT    ODe-                            ;disable mul optimizing
        BOPT    w4-                             ;disable 64k warnings
        SUPER
        ENDC

;============================================================================


_FastLoader
;_Flash

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $120000
FASTMEMSIZE	= $0000
HRTMON
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $A0000
; no blackscreen!!! select language at start...
	ENDC
	

NUMDRIVES       = 1
WPDRIVES        = %1111

;DISKSONBOOT
;HRTMON
;MEMFREE        = $100
;NEEDFPU
SETPATCH
BOOTDOS
HDINIT
IOCACHE=50000
POINTERTICKS=10
;DOSASSIGN
 
slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit	= $5D	; num '*'

;============================================================================

       INCLUDE whdload/kick13.s

;============================================================================

        IFD BARFLY
        DOSCMD  "WDate  >T:date"
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
	
slv_name           dc.b    "Dune 2",0


slv_copy           dc.b    "1992 Westwood Studios",0

slv_info           dc.b    "adapted by C-Fou! & JOTD",10,10
                dc.b    "Version "
			DECL_VERSION
                dc.b    0
slv_CurrentDir:           dc.b    "data",0
_runit          dc.b    "DuneII",0
_args           dc.b    10,0
_args_end

        EVEN
        ;initialize kickstart and environment

   
_bootdos

        ;open doslib
                lea     (_dosname,pc),a1
                move.l  (4),a6
                jsr     (_LVOOldOpenLibrary,a6)
                move.l  d0,a6                   ;A6 = dosbase
                
        ;load exe
                lea     (_runit,pc),a0
                move.l  a0,d1
                jsr     (_LVOLoadSeg,a6)
                move.l  d0,d7                   ;D7 = segment
                beq     .end

                bsr crack
        ;call
                move.l  d7,a1
                add.l   a1,a1
                add.l   a1,a1
                moveq   #_args_end-_args,d0
                lea     (_args,pc),a0
                move.l  (4,a7),d1               ;stacksize
                sub.l   #5*4,d1                 ;required for MANX stack check
                movem.l d1/d7/a2/a6,-(a7)

	IFD _Flash
.t:
   move.w #$0f,$dff180
    btst #6,$bfe001
    bne .t
	ENDC


                jsr     (4,a1)
                movem.l (a7)+,d1/d7/a2/a6

                pea     TDREASON_OK
		move.l	_resload(pc),a2
                jmp     (resload_Abort,a2)

        ifeq 1
        ;remove exe
                move.l  d7,d1
                jsr     (_LVOUnLoadSeg,a6)
        endc

.end            moveq   #0,d0
                rts

crack
                movem.l d0-d7/a0-a6,-(a7)
                lsl.l #2,d7
                move.l d7,a0
                move.l a0,a1
;.t:
;   move.w #$0f,$dff180
;    btst #6,$bfe001
;    bne .t

;;;;;;;;;;;;;;;;******* Crack dune 2 ******************
                move.l a1,d0
                add.l #$134a4-$40+$4,d0
                move.l d0,a0
                cmp.l #$67260812,(a0)
                bne .pas1
                move.b #$60,(a0); crack1 div / 0
                move.w #$f0,$dff180
                move.w #$f0,$dff180
                move.w #$f0,$dff180
                move.w #$f0,$dff180
                move.w #$f0,$dff180
                move.w #$f0,$dff180
                move.w #$f0,$dff180
                move.w #$f0,$dff180
                move.w #$f0,$dff180
                move.w #$f0,$dff180
                move.w #$f0,$dff180

.pas1
   ;disable cache
   move.l   _resload(pc),A2
   move.l   #WCPUF_Exp_NCS,d0
   move.l   #WCPUF_Exp,d1
   jsr   (resload_SetCPU,a2)        
                            


               movem.l (a7)+,d0-d7/a0-a6
                rts





;============================================================================

;_dosname        dc.b    "dos.library",0
        EVEN


