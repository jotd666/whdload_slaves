;*---------------------------------------------------------------------------
;  :Modul.      kick31.asm
;  :Contents.   kickstart 3.1 booter
;  :Author.     Wepl
;  :Version.    $Id: kick31.asm 1.2 2003/04/06 20:30:52 wepl Exp $
;  :History.    04.03.03 started
;               22.06.03 rework for whdload v16
;  :Requires.   kick31.s
;  :Copyright.  Public Domain
;  :Language.   68000 Assembler
;  :Translator. Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*


;CHIP_ONLY
        INCDIR  Includes:
        INCLUDE whdload.i
        INCLUDE whdmacros.i
        INCLUDE lvo/dos.i

        IFD BARFLY
        OUTPUT  "cedric.Slave"
        BOPT    O+                              ;enable optimizing
        BOPT    OG+                             ;enable optimizing
        BOPT    ODd-                            ;disable mul optimizing
        BOPT    ODe-                            ;disable mul optimizing
        BOPT    w4-                             ;disable 64k warnings
        BOPT    wo-                             ;disable optimize warnings
        SUPER
        ENDC

;  ============================================================================

 IFD CHIP_ONLY
CHIPMEMSIZE     = $200000
FASTMEMSIZE     = $00000
HRTMON
 else
CHIPMEMSIZE     = $100000
FASTMEMSIZE     = $100000

 ENDC

NUMDRIVES       = 1
WPDRIVES        = %1000

BLACKSCREEN
;BOOTBLOCK
BOOTDOS
;BOOTEARLY
;CBDOSLOADSEG
;CBDOSREAD
;CACHE
DOSASSIGN
;DISKSONBOOT
;;FONTHEIGHT     = 8
HDINIT
;INIT_AUDIO
;INIT_GADTOOLS
;INIT_MATHFFP
IOCACHE        = 1024
;MEMFREE        = $200
;NEEDFPU
;POINTERTICKS   = 1
;STACKSIZE      = 6000
;TRDCHANGEDISK
SETPATCH
;============================================================================

slv_Version     = 19
slv_Flags       = WHDLF_NoError|WHDLF_NoKbd|WHDLF_Examine|WHDLF_EmulTrap
slv_keyexit     = $59   ;F10

;============================================================================


        INCLUDE whdload/kick13.s

        include ReadJoyPad.s

;============================================================================


DECL_VERSION:MACRO
	dc.b	"2.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM
	


slv_CurrentDir          dc.b    "data",0
slv_name                dc.b    "Cedric"
    IFD CHIP_ONLY
    dc.b    " (CHIP/DEBUG MODE)"
    ENDC
    dc.b    0
slv_copy                dc.b    "1995/1996 NEO",0
slv_info                dc.b    "Adapted by CFou! & JOTD",10,10
                dc.b    "Version "
				DECL_VERSION

                dc.b    0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
slv_config		
	dc.b	"C1:X:trainer infinite lives:0;"
	dc.b	"C1:X:trainer HELP levelskips:1;"
	dc.b	"C2:B:button 2 for jump;"
	dc.b	"C3:B:skip introduction;"
	dc.b	"C4:L:Language:default,german,english;"
    dc.b	"C5:L:Start Level:default,01,02,03,04,05,06,07,08,09,10,11;"
	dc.b	0	
	even

;============================================================================
; like a program from "startup-sequence" executed, full dos process,
; HDINIT is required

; the following example is extensive because it saves all registers and
;   restores them before executing the program, the reason for this that some
;   programs (e.g. MANX Aztec-C) require specific registers properly setup on
;   calling
; in most cases a simpler routine is sufficient :-)


_bootdos      

        clr.l   $0.W
        move.l  (_resload,pc),a2           ;A2 = resload

        bsr _detect_controller_types
        
        ;get tags
		lea     (_tag,pc),a0
		jsr     (resload_Control,a2)
	    ;do not get the tags at reboot
		lea	(_tag,pc),a0
		clr.l	(a0)
        
      ;  ;enable cache
      ;          move.l  #WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
      ;          move.l  #WCPUF_All,d1
      ;          jsr     (resload_SetCPU,a2)



        ;open doslib

		lea     (_dosname,pc),a1
		move.l  (4),a6
		jsr     (_LVOOldOpenLibrary,a6)
		move.l  d0,a6                   ;A6 = dosbase

        ;assigns
		lea     (_disk0,pc),a0
		sub.l   a1,a1
		bsr     _dos_assign
		lea     (_disk1,pc),a0
		sub.l   a1,a1
		bsr     _dos_assign
		lea     (_disk2,pc),a0
		sub.l   a1,a1
		bsr     _dos_assign

		move.l _skip_intro(pc),d0
		tst.l d0
        bne .skip

		lea     _program1(pc),a0        ; "cedricintro"
		lea     _args0(pc),a1
        moveq   #_args_end0-_args0,d0
		lea _patch_intro(pc),a5
		bsr     _load_exe
.skip
		lea     _program2(pc),a0        ; "cedricmain HD"
		lea     _args2(pc),a1
		moveq   #_args_end2-_args2,d0
		lea _patch_game(pc),a5
		bsr     _load_exe

_quit
       pea     TDREASON_OK
		move.l  (_resload,pc),a2
		jmp     (resload_Abort,a2)


universal_vbr_patch
   move.l a1,a3
   add.l #$110,a3
   cmp.w #$0801,2(a3)
   bne .pas
   move.l #$70004e71,(a3)  ; vbr move
.pas
   move.l a1,a3
   add.l #$1f2,a3
   cmp.w #$0801,2(a3)
   bne .pas1
   move.l #$70004e71,(a3)  ; vbr move
.pas1
   move.l a1,a3
   add.l #$1f8,a3
   cmp.w #$0801,2(a3)
   bne .pas1b
   move.l #$70004e71,(a3)  ; vbr move
.pas1b

   move.l a1,a3
   add.l #$2584,a3
   cmp.w #$0801,2(a3)
   bne .pas1t
   move.l #$70004e71,(a3)  ; vbr move
.pas1t
  
  ; JOTD: added RTS
  RTS

_patch_intro
   add.l d7,d7
   add.l d7,d7
   move.l d7,a1
   add.l #4,a1
   ; first segment
   
   bsr	universal_vbr_patch
   rts
   
_patch_game
   move.l d7,a1
   lea	pl_english(pc),a0

   
   move.l   _lang_forced(pc),d0
   beq.b    .choose_from_locale
   cmp.l    #1,d0   ; german
   beq.b    .german
   bra.b    .no_german  ; forced english
   
.choose_from_locale   
   move.l   _language(pc),d0
   cmp.b	#3,D0
   bne.b	.no_german
.german
   lea	pl_main(pc),a0
.no_german
   move.l	_resload(pc),a2
   jsr	(resload_PatchSeg,a2)
   
   rts
   
   ; first segment
 
pl_english
    PL_START
    ; language = english
    PL_NOP  $1E,2
    PL_NEXT pl_main
pl_main
	PL_START
	; zero VBR
	PL_L	$1F2,$70004E71
	PL_R	$1F8
    PL_L    $2584,$70004E71
    ; skip cache handling
    ; (calls to CacheControl land in the woods with kick 1.3, why???)
    PL_S    $001a0,$1BA-$1a0
    PL_NOP  $000ca,4
    ; code copy end
    PL_P    $02cf2,code_copy_end_floppy

    
    PL_IFC5
    PL_PS   $02732,level_select
    PL_ENDIF
	PL_END



level_select
  	clr.w 	$dff088
  	cmp.w 	#1,$1a(a2)
  	bne 	.pas
  	move.l 	d0,-(a7)
  	move.l _start_level(pc),d0
  	beq 	.pas2
  	cmp.l 	#11,d0
  	bhi 	.pas2
  	cmp.l 	#2,d0
  	blo 	.pas2
  	move.w	d0,$1a(a2)
.pas2
  	move.l (a7)+,d0
.pas
  	rts



code_copy_end_floppy:
    ; D4 contains start buffer address
    ; A2 contains end of buffer
    movem.l a0-a2,-(a7)
    move.l  d4,a0
    cmp.w   #$4e92,($192,a0)
    bne.b   .no_loader
    move.l  _resload(pc),a2
    
    lea pl_loader_2C488(pc),a0
    move.l  d4,a1
    jsr resload_Patch(a2)
.no_loader
    movem.l (a7)+,a0-a2
    MOVEM.L	(A7)+,D0-D2		;: 4cdf0007
	RTS				;02cf6: 4e75
 
pl_loader_2C488
    PL_START
    PL_PSS   $2C616-$2C488,jump_a2_floppy,4
    PL_END

; JOTD: various parts of the code are run from the JSR (a2) here
; much better to change them here rather than patch dosread
jump_a2_floppy
	MOVEM.L	D4/A0-A1,-(A7)		;2c616: 48e708c0

    move.l  A2,$100
   
    lea ladder_flag_offset(pc),a0
    clr.l   (a0)
    
    cmp.l   #$FC0000,($12447e-$122B20,a2)
    bne   .no_menu_floppy
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    ; replace $FC0000 by kick start + $8000
    ; (seems that the game accesses rom out of bounds too)
    ; this is used for the flames random effect
    ; with 1.3 + $8000 values the flame effect is very good
    move.l  _expmem(pc),d0
    add.l   #$8000,d0
    move.l  d0,($124360+2-$122B20,a2) 
    move.l  d0,($12447c+2-$122B20,a2) 
    move.l  d0,($1244b0+2-$122B20,a2) 

    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_menu_floppy(pc),a0
    jsr resload_Patch(a2)
    
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310
    bra .jump
.no_menu_floppy
    cmp.l   #$FC0000,($12448e-$122B20,a2)
    bne   .no_menu_cd
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    ; replace $FC0000 by kick start + $8000
    ; (seems that the game accesses rom out of bounds too)
    ; this is used for the flames random effect
    ; with 1.3 + $8000 values the flame effect is very good
    move.l  _expmem(pc),d0
    add.l   #$8000,d0
    move.l  d0,($124360+2-$122B20,a2) 
    move.l  d0,($12448c+2-$122B20,a2) 
    move.l  d0,($1244c0+2-$122B20,a2) 

    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_menu_cd(pc),a0
    jsr resload_Patch(a2)
    
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310
    bra .jump
.no_menu_cd
    cmp.l   #$3B6E000C,($116034-$113428,a2)
    bne.b   .no_level_1_or_2
    ; ***********
    ; LEVEL 1 & 2
    ; ***********
    ; in-game code:
    ; A2 = 00113428
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_level_1_or_2(pc),a0
    jsr resload_Patch(a2)
    lea joy_offset(pc),a0
    move.l  #20462,(a0)
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310   
    bra .jump
.no_level_1_or_2
    cmp.l   #$3B6E000C,($10e126-$10aee0,a2)
    bne.b   .no_level_3_or_4
    ; ***********
    ; LEVEL 3 & 4
    ; ***********
    ; in-game code:
    ; A2 = 10e126
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_level_3_or_4(pc),a0
    jsr resload_Patch(a2)
    lea joy_offset(pc),a0
    move.l  #18934,(a0)
    lea ladder_flag_offset(pc),a0
    move.l  #19192,(a0)
    lea unknown_flag_offset(pc),a0
    move.l  #16726,(a0)
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310   
    bra .jump
.no_level_3_or_4
    cmp.l   #$3B6E000C,($116d16-$113360,a2)
    bne.b   .no_level_5_or_6
    ; ***********
    ; LEVEL 5 & 6
    ; ***********
    ; in-game code:
    ; A2 = 113360
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_level_5_or_6(pc),a0
    jsr resload_Patch(a2)
    lea joy_offset(pc),a0
    move.l  #15760,(a0)
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310   
    bra .jump
.no_level_5_or_6
     cmp.l   #$3b6e000c,($1185f2-$114E68,a2)
    bne.b   .no_level_7
    ; ***********
    ; LEVEL 7
    ; ***********
    ; in-game code:
    ; A2 = 114E68
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_level_7(pc),a0
    jsr resload_Patch(a2)
    lea joy_offset(pc),a0
    move.l  #19020,(a0)
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310   
    bra .jump
.no_level_7
    cmp.l   #$3b6e000c,($11ff46-$11DDC0,a2)
    bne.b   .no_level_8
    ; ***********
    ; LEVEL 8
    ; ***********
    ; in-game code:
    ; A2 = 11DDC0
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_level_8(pc),a0
    jsr resload_Patch(a2)
    lea joy_offset(pc),a0
    move.l  #7744,(a0)
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310   
    bra .jump
.no_level_8
    cmp.l   #$3b6e000c,($116ba6-$113be0,a2)
    bne.b   .no_level_9
    ; ***********
    ; LEVEL 9
    ; ***********
    ; in-game code:
    ; A2 = 113be0
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_level_9(pc),a0
    jsr resload_Patch(a2)
    lea joy_offset(pc),a0
    move.l  #22024,(a0)
    lea ladder_flag_offset(pc),a0
    move.l  #22228,(a0)
    lea unknown_flag_offset(pc),a0
    move.l  #19980,(a0)
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310   
    bra .jump
    
.no_level_9
    cmp.l   #$3b6e000c,($118b46-$1159F8,a2)
    bne.b   .no_level_10
    ; ************
    ; LEVEL 10
    ; ************
    ; in-game code:
    ; A2 = 1159E0
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_level_10(pc),a0
    jsr resload_Patch(a2)
    lea joy_offset(pc),a0
    move.l  #18550,(a0)
    lea ladder_flag_offset(pc),a0
    move.l  #18814,(a0)
    lea unknown_flag_offset(pc),a0
    move.l  #16182,(a0)
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310   
    bra .jump
.no_level_10
    cmp.l   #$3b6e000c,($119264-$1159E0,a2)
    bne.b   .no_level_11
    ; in-game code:
    ; A2 = 1159E0
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_level_11(pc),a0
    jsr resload_Patch(a2)
    lea joy_offset(pc),a0
    move.l  #15668,(a0)
    lea ladder_flag_offset(pc),a0
    move.l  #15926,(a0)
    lea unknown_flag_offset(pc),a0
    move.l  #13460,(a0)
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310   
    bra .jump
    
.no_level_11
    cmp.l   #$4a6d0004,($123534-$1223A0,a2)
    bne.b   .no_end
	MOVEM.L	D0-D1/A2,-(A7)		;2c616: 48e708c0
    move.l  A2,A1
    move.l  _resload(pc),a2
    lea pl_end(pc),a0
    jsr resload_Patch(a2)
	MOVEM.L	(A7)+,D0-D1/A2		;2c61c: 4cdf0310   
    bra .jump
    
    
.no_end
    ; nothing to do (game over)
    bsr _flushcache
.jump
	JSR	(A2)			;2c61a: 4e92
	MOVEM.L	(A7)+,D4/A0-A1		;2c61c: 4cdf0310
    rts

RANDOM_BASE = $8000

pl_menu_floppy
    PL_START
;    PL_L   $124360+2-$122B20,RANDOM_BASE
;    PL_L   $12447c+2-$122B20,RANDOM_BASE
;    PL_L   $1244b0+2-$122B20,RANDOM_BASE
    PL_PS  $00125336-$122B20,read_keyboard
    PL_END
pl_menu_cd
    PL_START
    PL_PS  $12535e-$122B20,read_keyboard
    PL_END

pl_end
    PL_START
    PL_PS   $123534-$1223A0,sync        ; just insert quitkey
    PL_END
    
pl_level_1_or_2
    PL_START
    PL_IFC1X    0
    PL_NOP  $11c858-$113428,4
    PL_B    $11c85c-$113428,$60
    PL_ENDIF

    PL_IFC1X    1
    PL_NOP  $11612e-$113428,2
    PL_ENDIF
    
    PL_IFC2
    PL_P    $116034-$113428,read_joy_directions_jump_button
    PL_PSS   $116164-$113428,test_second_fire_jump_blue,2
    PL_ELSE
    PL_P    $116034-$113428,read_joy_directions_jump_up   
    PL_PSS   $116164-$113428,test_second_fire_jump_up,2
    PL_ENDIF
    
    PL_PSS  $1153a6-$113428,test_fire,2
    PL_PSS  $1153e2-$113428,test_fire,2
    PL_PSS  $1153fc-$113428,test_fire,2
    PL_PSS  $11540e-$113428,test_fire,2
    PL_PSS  $115552-$113428,test_fire,2
    PL_PSS  $116050-$113428,test_fire,2
    PL_PSS  $1163cc-$113428,test_fire,2
    PL_PSS  $11643e-$113428,test_fire,2
    PL_PSS  $116ffa-$113428,test_fire,2
    PL_PSS  $11700c-$113428,test_fire,2
    PL_PSS  $11701e-$113428,test_fire,2
    PL_PSS  $1181b6-$113428,test_fire,2
    PL_PSS  $118394-$113428,test_fire,2
    PL_PSS  $11951a-$113428,test_fire,2
    PL_PSS  $11954c-$113428,test_fire,2
    
    ; keyboard & quitkey
    PL_PS  $115c30-$113428,read_keyboard
    PL_PS  $115e22-$113428,read_keyboard
    PL_PS  $11611c-$113428,read_keyboard
    ; ack keyboard
    PL_PS  $115cb8-$113428,ack_keyboard
    PL_PS  $115cde-$113428,ack_keyboard
    PL_PS  $115ee8-$113428,ack_keyboard
    PL_PS  $115f18-$113428,ack_keyboard
    PL_PS  $116148-$113428,ack_keyboard
    
    PL_END
    
pl_level_3_or_4
    PL_START
    PL_IFC1X    0
    PL_NOP  $114d12-$10aee0,4
    PL_B    $114d16-$10aee0,$60
    PL_ENDIF
    
    PL_IFC1X    1
    PL_NOP  $10e21a-$10aee0,2
    PL_ENDIF
    
    PL_IFC2
    PL_P    $10e126-$10aee0,read_joy_directions_jump_button_ladder
    PL_PSS  $10e250-$10aee0,test_second_fire_jump_blue,2
    PL_PS   $113d98-$10aee0,ready_to_climb_ladder
    PL_PSS  $113df4-$10aee0,ready_to_jump,2
    PL_ELSE
    PL_P    $10e126-$10aee0,read_joy_directions_jump_up   
    PL_PSS   $10e250-$10aee0,test_second_fire_jump_up,2
    PL_ENDIF
    
    PL_PSS   $10d800-$10aee0,test_fire,2
    PL_PSS   $10dfba-$10aee0,test_fire,2
    PL_PSS   $10dff6-$10aee0,test_fire,2
    PL_PSS   $10e010-$10aee0,test_fire,2
    PL_PSS   $10e022-$10aee0,test_fire,2
    PL_PSS   $10e13c-$10aee0,test_fire,2
    PL_PSS   $10e548-$10aee0,test_fire,2
    PL_PSS   $10e55a-$10aee0,test_fire,2
    PL_PSS   $10e56c-$10aee0,test_fire,2
    PL_PSS   $10f152-$10aee0,test_fire,2
    PL_PSS   $10f1c4-$10aee0,test_fire,2
    PL_PSS   $10fe9c-$10aee0,test_fire,2
    PL_PSS   $11007a-$10aee0,test_fire,2
    PL_PSS   $111560-$10aee0,test_fire,2
    PL_PSS   $111592-$10aee0,test_fire,2
        

    PL_PS  $10e208-$10aee0,read_keyboard
    PL_PS  $10e234-$10aee0,ack_keyboard

    PL_END

pl_level_5_or_6
    PL_START
    PL_IFC1X    0
    PL_NOP  $11d5c0-$113360,4
    PL_B    $11d5c4-$113360,$60
    PL_ENDIF
    
    PL_IFC1X    1
    PL_NOP  $116e0a-$113360,2
    PL_ENDIF
    
    PL_IFC2
    PL_P    $116d16-$113360,read_joy_directions_jump_button
    PL_PSS   $116e40-$113360,test_second_fire_jump_blue,2
    PL_ELSE
    PL_P    $116d16-$113360,read_joy_directions_jump_up   
    PL_PSS   $116e40-$113360,test_second_fire_jump_up,2
    PL_ENDIF
    
    PL_PSS  $115d04-$113360,test_fire,2
    PL_PSS  $116500-$113360,test_fire,2
    PL_PSS  $11653c-$113360,test_fire,2
    PL_PSS  $116556-$113360,test_fire,2
    PL_PSS  $116568-$113360,test_fire,2
    PL_PSS  $116d2c-$113360,test_fire,2
    PL_PSS  $117138-$113360,test_fire,2
    PL_PSS  $11714a-$113360,test_fire,2
    PL_PSS  $11715c-$113360,test_fire,2
    PL_PSS  $117d42-$113360,test_fire,2
    PL_PSS  $117db4-$113360,test_fire,2
    PL_PSS  $1188b2-$113360,test_fire,2
    PL_PSS  $118a90-$113360,test_fire,2
    PL_PSS  $119f18-$113360,test_fire,2
    PL_PSS  $119f4a-$113360,test_fire,2
    
    ; keyboard & quitkey
    PL_PS  $1167be-$113360,read_keyboard
    PL_PS  $1169b0-$113360,read_keyboard
    PL_PS  $116df8-$113360,read_keyboard
    ; ack keyboard
    PL_PS  $116848-2-$113360,ack_keyboard
    PL_PS  $11686e-2-$113360,ack_keyboard
    PL_PS  $116a78-2-$113360,ack_keyboard
    PL_PS  $116aa8-2-$113360,ack_keyboard
    PL_PS  $116e26-2-$113360,ack_keyboard
    
    ; change the "Take this black root from me" message
    ; because it misses the control codes to award the black root
    ; Size is important so I have to shorten the message
    PL_DATA $126f72-$113360,$1C
    dc.b    "Accept this black root",9,4,"...."
    even
    PL_END

pl_level_7
    PL_START
    PL_IFC1X    0
    PL_NOP  $11f258-$114E68,4
    PL_B    $11f25C-$114E68,$60
    PL_ENDIF

    PL_IFC1X    1
    PL_NOP  $1186e6-$114E68,2
    PL_ENDIF
    
    PL_IFC2
    PL_P    $1185f2-$114E68,read_joy_directions_jump_button
    PL_PSS   $11871c-$114E68,test_second_fire_jump_blue,2
    PL_ELSE
    PL_P    $1185f2-$114E68,read_joy_directions_jump_up   
    PL_PSS   $11871c-$114E68,test_second_fire_jump_up,2
    PL_ENDIF

    PL_PSS  $117660-$114E68,test_fire,2
    PL_PSS  $118380-$114E68,test_fire,2
    PL_PSS  $1183bc-$114E68,test_fire,2
    PL_PSS  $1183d6-$114E68,test_fire,2
    PL_PSS  $1183e8-$114E68,test_fire,2
    PL_PSS  $118608-$114E68,test_fire,2
    PL_PSS  $118a14-$114E68,test_fire,2
    PL_PSS  $118a26-$114E68,test_fire,2
    PL_PSS  $118a38-$114E68,test_fire,2
    PL_PSS  $11961e-$114E68,test_fire,2
    PL_PSS  $119690-$114E68,test_fire,2
    PL_PSS  $119f6e-$114E68,test_fire,2
    PL_PSS  $11a14c-$114E68,test_fire,2
    PL_PSS  $11ba02-$114E68,test_fire,2
    PL_PSS  $11ba34-$114E68,test_fire,2

    
    ; keyboard & quitkey
    PL_PS  $117f8a-$114E68,read_keyboard
    PL_PS  $11817c-$114E68,read_keyboard
    PL_PS  $1186d4-$114E68,read_keyboard
    ; ack keyboard
    PL_PS  $118014-2-$114E68,ack_keyboard
    PL_PS  $11803a-2-$114E68,ack_keyboard
    PL_PS  $118244-2-$114E68,ack_keyboard
    PL_PS  $118274-2-$114E68,ack_keyboard
    PL_PS  $118702-2-$114E68,ack_keyboard
    PL_END

pl_level_8
    PL_START
    PL_IFC1X    0
    PL_NOP  $1219e6-$11DDC0,4
    PL_B    $1219ea-$11DDC0,$60
    PL_ENDIF

    PL_IFC1X    1
    PL_NOP  $11ff6e-$11DDC0,2
    PL_ENDIF
    
    PL_P    $11ff46-$11DDC0,read_joy_directions_jump_up   
    PL_PSS   $11ffa4-$11DDC0,test_second_fire_jump_up,2

    PL_PSS  $11f878-$11DDC0,test_fire,2
    PL_PSS  $120710-$11DDC0,test_fire,2

    
    ; keyboard & quitkey
    PL_PS  $11fb92-$11DDC0,read_keyboard
    PL_PS  $11fd84-$11DDC0,read_keyboard
    PL_PS  $11ff5c-$11DDC0,read_keyboard
    ; ack keyboard
    PL_PS  $11fc1c-2-$11DDC0,ack_keyboard
    PL_PS  $11fc42-2-$11DDC0,ack_keyboard
    PL_PS  $11fe4c-2-$11DDC0,ack_keyboard
    PL_PS  $11fe7c-2-$11DDC0,ack_keyboard
    PL_PS  $11ff8a-2-$11DDC0,ack_keyboard
    PL_END

pl_level_9
    PL_START
    PL_IFC1X    0
    PL_NOP  $11c8ac-$113BE0,4
    PL_B    $11c8b0-$113BE0,$60
    PL_ENDIF
    
    PL_IFC1X    1
    PL_NOP  $116bce-$113BE0,2
    PL_ENDIF
    
    PL_IFC2
    PL_P    $116ba6-$113BE0,read_joy_directions_jump_button_ladder
    PL_PSS  $116c04-$113BE0,test_second_fire_jump_blue,2
    PL_PS   $11bd3a-$113BE0,ready_to_climb_ladder
    PL_PS  $11bcbe-$113BE0,ready_to_jump_alt
    PL_ELSE
    PL_P    $116ba6-$113BE0,read_joy_directions_jump_up   
    PL_PSS   $116c04-$113BE0,test_second_fire_jump_up,2
    PL_ENDIF
    
    PL_PSS   $115e9e-$113BE0,test_fire,2
    PL_PSS   $116296-$113BE0,test_fire,2
    PL_PSS   $1162d2-$113BE0,test_fire,2
    PL_PSS   $1162ec-$113BE0,test_fire,2
    PL_PSS   $1162fe-$113BE0,test_fire,2
    PL_PSS   $116eee-$113BE0,test_fire,2
    PL_PSS   $116f60-$113BE0,test_fire,2
    PL_PSS   $117694-$113BE0,test_fire,2
    PL_PSS   $1176a6-$113BE0,test_fire,2
    PL_PSS   $1176b8-$113BE0,test_fire,2
    PL_PSS   $118b1e-$113BE0,test_fire,2
    PL_PSS   $118cfc-$113BE0,test_fire,2
    PL_PSS   $119e08-$113BE0,test_fire,2
    PL_PSS   $119e3a-$113BE0,test_fire,2

    PL_PS  $11674e-$113BE0,read_keyboard
    PL_PS  $116940-$113BE0,read_keyboard
    PL_PS  $116bbc-$113BE0,read_keyboard

    PL_PS  $1167fe-2-$113BE0,ack_keyboard
    PL_PS  $116a08-2-$113BE0,ack_keyboard
    PL_PS  $116a38-2-$113BE0,ack_keyboard
    PL_PS  $116bea-2-$113BE0,ack_keyboard

    PL_END
    
pl_level_10
    PL_START
    PL_IFC1X    0
    PL_NOP  $11fce4-$1159F8,4
    PL_B    $11fce8-$1159F8,$60
    PL_ENDIF

    PL_IFC1X    1
    PL_NOP  $118c3a-$1159F8,2
    PL_ENDIF

    
    PL_IFC2
    PL_P    $118b46-$1159F8,read_joy_directions_jump_button_ladder
    PL_PSS  $118c70-$1159F8,test_second_fire_jump_blue,2
    PL_PS   $11eb94-$1159F8,ready_to_climb_ladder
    PL_PSS  $11ebe8-$1159F8,ready_to_jump,2
    PL_ELSE
    PL_P    $118b46-$1159F8,read_joy_directions_jump_up   
    PL_PSS   $118c70-$1159F8,test_second_fire_jump_up,2
    PL_ENDIF
    
    PL_PSS   $117da0-$1159F8,test_fire,2
    PL_PSS   $11848a-$1159F8,test_fire,2
    PL_PSS   $1184c6-$1159F8,test_fire,2
    PL_PSS   $1184e0-$1159F8,test_fire,2
    PL_PSS   $1184f2-$1159F8,test_fire,2
    PL_PSS   $118b5c-$1159F8,test_fire,2
    PL_PSS   $118f68-$1159F8,test_fire,2
    PL_PSS   $118f7a-$1159F8,test_fire,2
    PL_PSS   $118f8c-$1159F8,test_fire,2
    PL_PSS   $119b76-$1159F8,test_fire,2
    PL_PSS   $119be8-$1159F8,test_fire,2
    PL_PSS   $11ab86-$1159F8,test_fire,2
    PL_PSS   $11ad64-$1159F8,test_fire,2
    PL_PSS   $11c150-$1159F8,test_fire,2
    PL_PSS   $11c182-$1159F8,test_fire,2
        
    PL_PS  $118748-$1159F8,read_keyboard
    PL_PS  $11893a-$1159F8,read_keyboard
    PL_PS  $118c28-$1159F8,read_keyboard

    PL_PS  $1187d2-2-$1159F8,ack_keyboard
    PL_PS  $1187f8-2-$1159F8,ack_keyboard
    PL_PS  $118a02-2-$1159F8,ack_keyboard
    PL_PS  $118a32-2-$1159F8,ack_keyboard
    PL_PS  $118c56-2-$1159F8,ack_keyboard
    PL_END

pl_level_11
    PL_START
    PL_IFC1X    0
    PL_NOP  $11fa46-$1159E0,4
    PL_B    $11fa4A-$1159E0,$60
    PL_ENDIF

    PL_IFC1X    1
    PL_NOP  $119358-$1159E0,2
    PL_ENDIF

    
    PL_IFC2
    PL_P    $119264-$1159E0,read_joy_directions_jump_button_ladder
    PL_PSS   $11938e-$1159E0,test_second_fire_jump_blue,2
    PL_PS   $11eac6-$1159E0,ready_to_climb_ladder
    PL_PSS  $11eb22-$1159E0,ready_to_jump,2
    PL_ELSE
    PL_P    $119264-$1159E0,read_joy_directions_jump_up   
    PL_PSS   $11938e-$1159E0,test_second_fire_jump_up,2
    PL_ENDIF

    PL_PSS  $1167bc-$1159E0,test_fire,2
    PL_PSS  $1183bc-$1159E0,test_fire,2
    PL_PSS  $118b72-$1159E0,test_fire,2
    PL_PSS  $118bae-$1159E0,test_fire,2
    PL_PSS  $118bc8-$1159E0,test_fire,2
    PL_PSS  $118bda-$1159E0,test_fire,2
    PL_PSS  $11927a-$1159E0,test_fire,2
    PL_PSS  $119686-$1159E0,test_fire,2
    PL_PSS  $119698-$1159E0,test_fire,2
    PL_PSS  $1196aa-$1159E0,test_fire,2
    PL_PSS  $11a32c-$1159E0,test_fire,2
    PL_PSS  $11a39e-$1159E0,test_fire,2
    PL_PSS  $11ad22-$1159E0,test_fire,2
    PL_PSS  $11af00-$1159E0,test_fire,2
    PL_PSS  $11c36a-$1159E0,test_fire,2
    PL_PSS  $11c39c-$1159E0,test_fire,2    
    
    ; keyboard & quitkey
    PL_PS  $118e30-$1159E0,read_keyboard
    PL_PS  $119022-$1159E0,read_keyboard
    PL_PS  $119346-$1159E0,read_keyboard
    ; ack keyboard
    PL_PS  $118eba-2-$1159E0,ack_keyboard
    PL_PS  $118ee0-2-$1159E0,ack_keyboard
    PL_PS  $1190ea-2-$1159E0,ack_keyboard
    PL_PS  $11911a-2-$1159E0,ack_keyboard
    PL_PS  $119374-2-$1159E0,ack_keyboard
    PL_END

sync
    movem.l D0,-(a7)
    move.b  $BFEC01,d0
    ror.b   #1,d0
    not.b   d0
    cmp.b   _keyexit(pc),d0
    beq _quit
    movem.l (a7)+,d0
	TST.W	4(A5)			;123534: 4a6d0004
	BEQ.S	sync		;123538: 67fa
    rts
    
ack_keyboard
	movem.l	D0,-(A7)
	moveq.l	#2,D0
	bsr	beamdelay
	movem.l	(A7)+,D0
	rts

; here after having tested the map, 
; the game has been instructed to go "up" (or button 2)
; we're going to make sure that "up" was pressed and not button 2
; else we'll jump instead
ready_to_climb_ladder:
	movem.l	D0/D1/a0,-(A7)
    move.l  button_states(pc),d0
    btst    #JPB_BTN_UP,d0
    beq.b   .no_up
    ; climb normally
    move.l  ladder_flag_offset(pc),d1
    move.w  #1,(a5,d1.L)      ; set climb ladder flag
    bra.b   .out
.no_up
    movem.l (a7)+,d0/d1/a0
    addq.l  #4,a7
    rts
.out
    movem.l (a7)+,d0/d1/a0
    rts

ready_to_jump
    ; or already jumping...
    
	movem.l	D0,-(A7)
    move.l  unknown_flag_offset(pc),d0
    TST.W	(A5,d0.L)
    bne.b   .pop
    move.l  button_states(pc),d0
    btst    #JPB_BTN_BLU,d0
    movem.l (a7)+,d0
    beq.b   .pop    ; if blue is not pressed, don't do anything
    rts
    
.pop
    movem.l (a7)+,d0
    addq.l  #4,a7
    rts

ready_to_jump_alt
    ; or already jumping...
    
	movem.l	D0,-(A7)
    move.l  unknown_flag_offset(pc),d0
    MOVE.W	#$0001,(A5,D0.L)
    movem.l (a7)+,d0
    rts
    
test_fire:
	movem.l	D0,-(A7)
    move.l  button_states(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
	movem.l	(A7)+,D0
    rts

test_second_fire_jump_up:
	movem.l	D0,-(A7)
    move.l  button_states(pc),d0
    not.l   d0
    btst    #JPB_BTN_BLU,d0
	movem.l	(A7)+,D0
    RTS
    
test_second_fire_jump_blue:
	movem.l	D0,-(A7)
    move.l  button_states(pc),d0
    not.l   d0
    btst    #JPB_BTN_GRN,d0
	movem.l	(A7)+,D0
    RTS
    
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
    
read_keyboard:
    MOVE.B	$bfec01,D1		;: 123900
    movem.l d1,-(a7)
    not.b   d1
    ror.b   #1,d1
    cmp.b   _keyexit(pc),d1
    beq _quit
	cmp.B	#$12,d1
	bne	.noHt
	move.w	#1,$94.W			; english E
.noHt

	cmp.B	#$22,d1
	bne	.noH
	move.w	#0,$94.W		; deutsch G

.noH
    
    movem.l (a7)+,d1
    RTS

read_joy_directions:
	movem.l	d1-d3/a0-a1/a5,-(a7)
	lea	button_states(pc),a0
	lea	previous_button_states(pc),a1
	move.l	(a0),(a1)		; save previous state
	moveq.l	#1,d0
	bsr	_read_joystick      ; also trashes d1
	move.l	d0,(a0)
	
	; quit slave
	btst	#JPB_BTN_PLAY,d0
	beq.b	.nq
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.nq
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.nq
	bra		_quit
.nq	    
	; F2: quits
	btst	#JPB_BTN_REVERSE,d0
	beq.b	.noquit
	btst	#JPB_BTN_FORWARD,d0
	beq.b	.noquit
	nop
.noquit

	
	movem.l	(a7)+,d1-d3/a0-a1/a5
    rts
    
read_joy_directions_jump_up:
	movem.l	d2,-(a7)
    move.l  joy_offset(pc),d2
	bsr	read_joy_directions
	move.w	12(A6),(A5,D2.L)
	movem.l	(a7)+,d2
	rts
    
; for stages where there are ladders
read_joy_directions_jump_button_ladder:
	bsr	read_joy_directions
	movem.l	d0-d3,-(a7)
    move.l  joy_offset(pc),d2
    move.l  ladder_flag_offset(pc),d3
	move.l	button_states(pc),d0
	moveq.l	#0,d1
	move.w	12(A6),D1
    tst.l   d3
    beq.b   .skip
    tst.w   (a5,d3.l) ; on ladder: no second button ever
    bne.b   .no_blue
.skip
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	move.l	d1,d0
	MOVE.W	D1,(A5,d2.L)	;: 3b6e000c4fee
	movem.l	(a7)+,d0-d3
	RTS    
    
; for stages where there aren't any ladders
read_joy_directions_jump_button:
	bsr	read_joy_directions
	movem.l	d0-d2,-(a7)
    move.l  joy_offset(pc),d2
	move.l	button_states(pc),d0
	moveq.l	#0,d1
	move.w	12(A6),D1

	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d1
	btst	#9,d1
	beq.b	.noneed
	bset	#8,d1	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d0
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d1
	btst	#9,d1
	bne.b	.no_blue
	bset	#8,d1	; xor 8 and 9 yields 1 cos bit9=1
.no_blue:
	move.l	d1,d0
	MOVE.W	D1,(A5,d2.L)	;: 3b6e000c4fee
	movem.l	(a7)+,d0-d2
	RTS    


; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
	movem.l d0-a6,-(a7)
	move.l  d0,d2
	move.l  a0,a3
	move.l  a1,a4
	move.l  a0,d1
	jsr     (_LVOLoadSeg,a6)
	move.l  d0,d7                   ;D7 = segment
	beq     .end                    ;file not found

	;get tags
    movem.l d0-d1/a0-a2,-(a7)
    lea bcplptr(pc),a1
    move.l  d7,(a1)
    lea	(segtag,pc),a0
    move.l  _resload(pc),a2
	jsr	(resload_Control,a2)
    movem.l (a7)+,d0-d1/a0-a2
    
	;patch here
	cmp.l   #0,A5
	beq.b   .skip
	movem.l d2/d7/a4,-(a7)
	jsr     (a5)
	movem.l (a7)+,d2/d7/a4
.skip
	;call
	move.l  d7,a1
	add.l   a1,a1
	add.l   a1,a1

	move.l  a4,a0
	move.l  ($44,a7),d0             ;stacksize
	sub.l   #5*4,d0                 ;required for MANX stack check
	movem.l d0/d7/a2/a6,-(a7)
	move.l  d2,d0                   ; argument string length
;-----
	jsr     (4,a1)
;-----
	movem.l (a7)+,d1/d7/a2/a6



	;remove exe
	move.l  d7,d1
	jsr     (_LVOUnLoadSeg,a6)

	movem.l (a7)+,d0-a6
	rts
			

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


_disk0          dc.b    "Cedric",0
_disk1          dc.b    "Cedric_CD",0
_disk2          dc.b    "cd0",0
              even
_program1
      dc.b    "cedricintro",0
_program2
      dc.b    "cedricmain",0
_args0           dc.b  '',10
_args_end0       dc.b    0
_args2           dc.b  'HD',10
_args_end2       dc.b    0
        EVEN



segtag
    dc.l    WHDLTAG_DBGSEG_SET
bcplptr:
    dc.l    0
    dc.l    0

 
;---------------------- patch dos read


_fix_accessfault
  move.w #$8020,$dff09a
  move.l d0,-(a7)
  add.l a1,d0
  and.l #$1fffff,d0
  move.l d0,a1
  move.l (a7)+,d0
  move.b (a1)+,d0
  lsr.w #4,d0
  add.w (a0),d0

  rts



_tag            dc.l    WHDLTAG_CUSTOM1_GET
_trainer        dc.l    0
                dc.l    WHDLTAG_CUSTOM2_GET
_custom2        dc.l    0
                dc.l    WHDLTAG_CUSTOM3_GET
_skip_intro        dc.l    0
		dc.l	WHDLTAG_LANG_GET
_language	dc.l	0
                dc.l    WHDLTAG_CUSTOM4_GET
_lang_forced                
				dc.l	0
                dc.l    WHDLTAG_CUSTOM5_GET
_start_level                
				dc.l	0
				dc.l	0
                               
button_states
	dc.l	0
previous_button_states
	dc.l	0
joy_offset
    dc.l    0
ladder_flag_offset
    dc.l    0
unknown_flag_offset:
    dc.l    0
;============================================================================
