
		INCDIR	sc:include/
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"TinToyAdventure.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
	dc.w	17					; ws_version (was 10)
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_NoKbd|WHDLF_Req68020|WHDLF_ReqAGA	;ws_flags
		dc.l	$1f0000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	_Data-_base		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5d			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
;---
	dc.w	slv_config-_base
	
slv_config:
        dc.b    "C1:X:trainer infinite lives:0;"
        dc.b    "C1:X:trainer invincibility:1;"
        dc.b    "C2:B:second button for jump;"
		dc.b	0
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
    

_name		dc.b	"Tin Toy Adventure",0
_copy		dc.b	"1996 Mutation Software",0
_info		dc.b	"Installed by Codetapper/Action!",10
            dc.b    "update & joypad support by JOTD",10,10
		dc.b	"Version "
        DECL_VERSION
        dc.b    0
		dc.b	-1,"Please be patient during initial decrunching!"
		dc.b	-1,"Thanks to Adrian Simpson for the original!",0
_MainFile_v1	dc.b	"tt",0
_MainFile_v2	dc.b	"TinToy",0
_Data		dc.b	"data",0
		EVEN

    include ReadJoyPad.s
    
BASEADDR = $400

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later use

        lea	_MainFile_v1(pc),a0	;Check if this is crunched
		move.l	_resload(pc),a2		;with RNC or not
		jsr	resload_GetFileSize(a2)

        tst.l   d0
        bne   .v1
        
        lea	_MainFile_v2(pc),a0	;Check if this is crunched
		move.l	_resload(pc),a2		;with RNC or not
		jsr	resload_GetFileSize(a2)
        tst.l   d0
        beq _wrongver
        
        
		cmp.l	#930724,d0
		beq	_LoadUncrunched_V2
   
		lea	_MainFile_v2(pc),a0	;name
		lea	BASEADDR,a1			;destination address
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)

		lea	$61C,a0			;Start of RNC data
		lea	$374,a1			;Destination address

		cmp.l	#('RNC'<<8)+2,(a0)
		bne	_wrongver

		move.l  _resload(pc),a2
        jsr (resload_Decrunch,a2)
		bra	_GameDecrunched_V2
   
.v1
		cmp.l	#930760,d0
		beq	_LoadUncrunched_V1

		lea	_MainFile_v1(pc),a0	;name
		lea	BASEADDR,a1			;destination address
		move.l	a1,a5
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)

		lea	$5fa,a0			;Start of RNC data
		lea	$374,a1			;Destination address

		cmp.l	#('RNC'<<8)+1,(a0)
		bne	_wrongver

		bsr	_OldPropack
		bra	_GameDecrunched_V1

_LoadUncrunched_V1
        lea	_MainFile_v1(pc),a0	;name
		lea	$354.w,a1			;destination address
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)

_GameDecrunched_V1:
        sub.l   a1,a1
        lea pl_main_v1(pc),a0
        jsr resload_Patch(a2)
        
        lea RAWKEYTABLE(pc),a0
        move.l  #$99c8,(a0)
        lea LEVEL_NUMBER(pc),a0
        move.l  #$b6f6,(a0)
        
		move.l	#CACRF_EnableI,d0	;new status
		move.l	d0,d1			;status to change
		move.l	_resload(pc),a2
		jsr	resload_SetCACR(a2)

		jmp	BASEADDR		;Start game

_LoadUncrunched_V2
        lea	_MainFile_v2(pc),a0	;name
		lea	$354.w,a1			;destination address
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)

_GameDecrunched_V2:
        sub.l   a1,a1
        lea pl_main_v2(pc),a0
        jsr resload_Patch(a2)
        
        lea RAWKEYTABLE(pc),a0
        move.l  #$099a4,(a0)
        lea LEVEL_NUMBER(pc),a0
        move.l  #$b6d2,(a0)

		move.l	#CACRF_EnableI,d0	;new status
		move.l	d0,d1			;status to change
		move.l	_resload(pc),a2
		jsr	resload_SetCACR(a2)

		jmp	BASEADDR		;Start game

RAWKEYTABLE:
    dc.l    0
    
LEVEL_NUMBER:
    dc.l    0
    
    
pl_main_v1
    PL_START
    PL_R    $98b8   ;Disable CACR modification (safety only)
    PL_NOP  $9840,6 ;Write to $dff1fc
    PL_NOP  $b604,8 ;Word write to beamcon0
    PL_NOP  $a14a,8 ;Word write to beamcon0
    PL_NOP  $22694,6 ;Word clear beamcon0 (switch to NTSC)
    PL_NOP  $226ac,8 ;Word write to beamcon0 (switch to PAL)
    PL_NOP  $0b626,6    ; no reset of cheat key
    PL_NOP  $1bafe,6    ; no reset of cheat key
    PL_NOP  $1bc9c,6    ; no reset of cheat key
    PL_P    $258f2,_loader
    PL_L    $95be,$6000012e 	;Skip all the disk shite
    PL_IFC2
    PL_PS   $0002297E,_joypad_controls
    PL_ENDIF
    PL_PSS  $229be,_test_joyfire,2
    
    PL_NOP  $0002255C,4     ; enable in-game keys: F1-F5 select level, 1-3 select section
    
    ; re-enable vblank interrupt, we cannot read the joypad from copper
    ; interrupt because it's BOF interrupt, not TOF interrupt
    ; also re-enable keyboard interrupt as else quitkey doesn't work at all
    PL_W    $982A,$c038
    PL_PSS  $098ce,_level3_int_hook,2
    
    ; generic routine which reads both ports and both buttons
    ; (but the second button read is wrong because it uses a BTST.W
    ; on a memory address, which doesn't work)
    PL_S    $2292a,$2297e-$2292a    ; skip port 0 read
    PL_R    $229ce      ; skip 2nd button read (which is wrong too)
    
    PL_PSS   $9750,menu_subroutine_wrapper_v1,2
    
    ; a real keyboard interrupt!!
    PL_PA    $09812,keyboard_interrupt
    ; completely replaces keyboard handler
    PL_P   $9954,handle_keyboard
    
    PL_IFC1X    0
    PL_NOP  $0001B902,4 ; infinite lives
    PL_ENDIF
    PL_IFC1X    1
    PL_B  $22907,1 ; invincibility (original cheat)
    PL_ENDIF
    PL_END
    
pl_main_v2
    PL_START
    
    PL_NOP  $0981c,6 ;Write to $dff1fc
    PL_R    $09894   ;Disable CACR modification (safety only)
    PL_NOP  $0a126,8 ;Word write to beamcon0
    PL_NOP  $0b5e0,8 ;Word write to beamcon0
    PL_NOP  $22670,6 ;Word clear beamcon0 (switch to NTSC)
    PL_NOP  $22688,8 ;Word write to beamcon0 (switch to PAL)
    PL_NOP  $0b602,6    ; no reset of cheat key
    PL_NOP  $1bada,6    ; no reset of cheat key
    PL_NOP  $1bc78,6    ; no reset of cheat key
    PL_P    $258ce,_loader
    PL_L    $095be,$6000012e 	;Skip all the disk shite
    PL_IFC2
    PL_PS   $2295a,_joypad_controls
    PL_ENDIF
    PL_PSS  $2299a,_test_joyfire,2
    
    PL_NOP  $22538,4     ; enable in-game keys: F1-F5 select level, 1-3 select section
    
    ; re-enable vblank interrupt, we cannot read the joypad from copper
    ; interrupt because it's BOF interrupt, not TOF interrupt
    ; also re-enable keyboard interrupt as else quitkey doesn't work at all
    PL_W    $09806,$c038
    PL_PSS  $098aa,_level3_int_hook,2
    
    ; generic routine which reads both ports and both buttons
    ; (but the second button read is wrong because it uses a BTST.W
    ; on a memory address, which doesn't work)
    PL_S    $22906,$2295A-$22906    ; skip port 0 read
    PL_R    $2294c      ; skip 2nd button read (which is wrong too)
   
    PL_PSS   $0972c,menu_subroutine_wrapper_v2,2
    
    ; a real keyboard interrupt!!
    PL_PA    $097ee,keyboard_interrupt
    ; completely replaces keyboard handler
    PL_P   $09930,handle_keyboard
    
    PL_IFC1X    0
    PL_NOP  $1b8de,4 ; infinite lives
    PL_ENDIF
    PL_IFC1X    1
    PL_B  $228e3,1 ; invincibility (original cheat)
    PL_ENDIF    
    PL_END
    
menu_subroutine_wrapper_v1:
    jsr $0b634      ; ???
    movem.l a0,-(a7)
    lea enable_up(pc),a0
    move.w  #1,(a0)
    movem.l (a7)+,a0
    jsr $09ac8  ; menu
    movem.l a0,-(a7)
    lea enable_up(pc),a0
    clr.w   (a0)
    movem.l (a7)+,a0
    rts
    
menu_subroutine_wrapper_v2:
    jsr $0b610      ; ???
    movem.l a0,-(a7)
    lea enable_up(pc),a0
    move.w  #1,(a0)
    movem.l (a7)+,a0
    jsr $09aa4  ; menu
    movem.l a0,-(a7)
    lea enable_up(pc),a0
    clr.w   (a0)
    movem.l (a7)+,a0
    rts

keyboard_interrupt
	movem.l	D0/A0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here
    lea current_key(pc),a0
    move.b  d0,(a0)
    
    ; handle keyexit (even if needs a 68020+/AGA anyway, at least quits with NOVBRMOVE)
    cmp.b	_keyexit(pc),d0
    beq	_exit

	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a0/a5
	move.w	#8,$dff09c
	rte

handle_keyboard:
    moveq.l #0,d0
    move.b  current_key(pc),d0
	move.l	RAWKEYTABLE(pc),A0		;0999e: 41fa0028    keypress table
	BCLR	#7,D0			;099a2: 08800007
	BNE.S	.released		;099a6: 6606
	ST	0(A0,D0.W)		;099a8: 50f00000
	rts
.released:
	SF	0(A0,D0.W)		;099ae: 51f00000
    rts
    
current_key
        dc.w    0
        
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
    
TESTKEY:MACRO
    tst.b   (\2,a0)
    beq.b   .no_press_\1
    sub.b   #1,(\2,a0)
.no_press_\1
	btst	#JPB_BTN_\1,d0
	beq.b	.no_\1
	move.b    #10,(\2,a0)	; play pressed
.no_\1
    ENDM
    
TESTKEY_2:MACRO
    tst.b   (\3,a0)
    beq.b   .no_press_\1\2
    sub.b   #1,(\3,a0)
.no_press_\1\2
	btst	#JPB_BTN_\1,d0
	beq.b	.no_\1\2
	btst	#JPB_BTN_\2,d0
	beq.b	.no_\1\2
	move.b    #10,(\3,a0)	; play pressed
.no_\1\2
    ENDM


F1_RAW_CODE = $50

_level3_int_hook:
    move.w  _custom+intreqr,d0
    btst    #4,d0
    bne   .copper

    bsr _joystick
    move.l  joy1(pc),d0
    
    move.l RAWKEYTABLE(pc),a0

    TESTKEY PLAY,$19
    TESTKEY_2 REVERSE,FORWARD,$45

    ; decrease keypress counter for function keys
    move.w  #4,d1
.sub
    tst.b   F1_RAW_CODE(a0,d1.w)
    beq.b   .nos
    sub.b   #1,F1_RAW_CODE(a0,d1.w)
.nos
    dbf d1,.sub

    ; it has to be vblank
    move.w  #$20,_custom+intreq


    btst    #JPB_BTN_FORWARD,d0
    beq.b   .nofwd
    btst    #JPB_BTN_YEL,d0
    beq.b   .nofwd
    ; skip level
    clr.w   d1
    move.l  LEVEL_NUMBER(pc),a1
    move.b  (a1),d1
	cmp.b   #5,d1
    bcc.b   .nofwd
    
    ; press key corresponding to next level
    move.b  #10,F1_RAW_CODE(a0,d1.w)
.nofwd    
    ; end vblank interrupt
    add.l   #4,a7   ; pop-up stack
    movem.l (a7)+,D0-D7/A0-A6   ; original restore registers
    rte
.copper
	MOVE.W	#$10,_custom+intreq
    rts
    

_test_joyfire:
	movem.l	d1,-(a7)
	move.l	joy1(pc),d1
	btst	#JPB_BTN_RED,d1
	movem.l	(a7)+,d1
    eor.w   #4,CCR      ; invert Z condition
    rts
    

    
_joypad_controls:
    MOVE.W $00dff00c,D0
    
	movem.l	d1,-(a7)
    move.w enable_up(pc),d1
    bne.b   .no_blue
    
	move.l	joy1(pc),d1
		
	; cancel UP from joydat. Copying bit 9 to bit 8 so EOR yields 0
	bclr	#8,d0
	btst	#9,d0
	beq.b	.noneed
	bset	#8,d0	; xor 8 and 9 yields 0 cos bit9=1
.noneed
	btst	#JPB_BTN_BLU,d1
	beq.b	.no_blue
	; set UP because blue pressed
	bclr	#8,d0
	btst	#9,d0
	bne.b	.no_blue
	bset	#8,d0	; xor 8 and 9 yields 1 cos bit9=0
.no_blue:

	movem.l	(a7)+,d1
    rts
    
previous_joy
	dc.l	0
    
enable_up
    dc.w    0
    
;======================================================================

_loader
        bsr _detect_controller_types
        movem.l	d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		movem.l	(sp)+,d1/a0-a2
		moveq	#0,d0
		rts

;======================================================================

_OldPropack	movem.l	d0-d7/a0-a6,-(sp)
;		lea	(_Data,pc),a0		;a0 = Source data
;		lea	(_OldPropack,pc),a1	;a1 = Destination address
		bsr.b	_OldReadLongA0
		cmp.l	#$524E4301,d0
		bne.b	_NotRNC
		bsr.b	_OldReadLongA0
		lea	(4,a0),a4
		lea	(a4,d0.l),a2
		adda.w	#$100,a2
		movea.l	a2,a3
		bsr.b	_OldReadLongA0
		lea	(a4,d0.l),a6
		move.b	-(a6),d3
_Old1		bsr.b	_Old6
		addq.w	#1,d5
		cmpa.l	a4,a6
		ble.b	_Old3
		bsr.w	_Old17
		bsr.w	_Old24
		subq.w	#1,d6
		lea	(a3,d7.w),a0
		ext.l	d6
		adda.l	d6,a0
		tst.w	d7
		bne.b	_Old2
		lea	(1,a3),a0
_Old2		move.b	-(a0),-(a3)
		dbra	d6,_Old2
		bra.b	_Old1

_Old3		move.l	a2,d0
		sub.l	a3,d0
		movea.l	a3,a0
		bra.b	_Old4

_NotRNC		moveq	#0,d0
_Old4		bra.w	_Old32

_OldReadLongA0	moveq	#3,d1
_Old5		lsl.l	#8,d0
		move.b	(a0)+,d0
		dbra	d1,_Old5
		rts

_Old6		moveq	#-1,d5
		bsr.b	_Old15
		bcc.b	_Old12
		moveq	#0,d5
		bsr.b	_Old15
		bcc.b	_Old10
		moveq	#3,d1
_Old7		clr.w	d5
		move.b	(_Old13,pc,d1.w),d0
		ext.w	d0
		moveq	#-1,d2
		lsl.w	d0,d2
		not.w	d2
		subq.w	#1,d0
_Old8		bsr.b	_Old15
		roxl.w	#1,d5
		dbra	d0,_Old8
		tst.w	d1
		beq.b	_Old9
		cmp.w	d5,d2
		dbne	d1,_Old7
_Old9		move.b	(_Old14,pc,d1.w),d0
		ext.w	d0
		add.w	d0,d5
_Old10		move.w	d5,-(sp)
_Old11		move.b	-(a6),-(a3)
		dbra	d5,_Old11
		move.w	(sp)+,d5
_Old12		rts

_Old13		dc.b	10
		dc.b	3
		dc.b	2
		dc.b	2
_Old14		dc.b	14
		dc.b	7
		dc.b	4
		dc.b	1

_Old15		lsl.b	#1,d3
		bne.b	_Old16
		move.b	-(a6),d3
		roxl.b	#1,d3
_Old16		rts

_Old17		moveq	#3,d0
_Old18		bsr.b	_Old15
		bcc.b	_Old19
		dbra	d0,_Old18
_Old19		clr.w	d6
		addq.w	#1,d0
		move.b	(_Old22,pc,d0.w),d1
		beq.b	_Old21
		ext.w	d1
		subq.w	#1,d1
_Old20		bsr.b	_Old15
		roxl.w	#1,d6
		dbra	d1,_Old20
_Old21		move.b	(_Old23,pc,d0.w),d1
		ext.w	d1
		add.w	d1,d6
		rts

_Old22		dc.b	10
		dc.b	2
		dc.b	1
		dc.b	0
		dc.b	0
_Old23		dc.b	10
		dc.b	6
		dc.b	4
		dc.b	3
		dc.b	2

_Old24		moveq	#0,d7
		cmp.w	#2,d6
		beq.b	_Old28
		moveq	#1,d0
_Old25		bsr.b	_Old15
		bcc.b	_Old26
		dbra	d0,_Old25
_Old26		addq.w	#1,d0
		move.b	(_Old30,pc,d0.w),d1
		ext.w	d1
_Old27		bsr.b	_Old15
		roxl.w	#1,d7
		dbra	d1,_Old27
		lsl.w	#1,d0
		add.w	(_Old31,pc,d0.w),d7
		rts

_Old28		moveq	#5,d0
		clr.w	d1
		bsr.b	_Old15
		bcc.b	_Old29
		moveq	#8,d0
		moveq	#$40,d1
_Old29		bsr.b	_Old15
		roxl.w	#1,d7
		dbra	d0,_Old29
		add.w	d1,d7
		rts

_Old30		dc.b	11
		dc.b	4
		dc.b	7
		dc.b	0
_Old31		dc.w	$120
		dc.w	0
		dc.w	$20
		dc.w	0

_Old32		movea.l	a0,a3
		move.l	d0,d3
		cmpi.l	#$3E9,(a3)+
		bne.b	_Old37
		move.l	(a3)+,d0
		lsl.l	#2,d0
		lea	(a3,d0.l),a2
		cmpi.l	#$3EC,(a2)+
		bne.b	_Old37
_Old33		move.l	(a2)+,d1
		beq.b	_Old37
		move.l	a1,d2
		move.l	(a2)+,d0
		beq.b	_Old34
		bsr.b	_Old35
_Old34		move.l	(a2)+,d0
		add.l	d2,(a3,d0.l)
		subq.l	#1,d1
		bne.b	_Old34
		bra.b	_Old33

_Old35		movea.l	a1,a4
		subq.l	#4,a4
_Old36		movea.l	(a4),a4
		adda.l	a4,a4
		adda.l	a4,a4
		subq.l	#1,d0
		bne.b	_Old36
		addq.l	#4,a4
		move.l	a4,d2
		rts

_Old37		move.l	d3,d0
		move.l	d0,-(sp)
		move.l	a0,d1
		sub.l	a1,d1
		move.l	(4,a0),d0
		lsl.l	#2,d0
		lea	(8,a0),a0
		sub.l	d0,(sp)
		add.l	(sp)+,d1

_OldMove	move.b	(a0)+,(a1)+
		subq.l	#1,d0
		bne.b	_OldMove
_OldClear	clr.b	(a1)+
		subq.l	#1,d1
		bne.b	_OldClear

		movem.l	(sp)+,d0-d7/a0-a6
		rts

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================


_exit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================
		END

;26816 = loader
;b6f6 = World (1-5)
;b6f7 = Level of world (1-5)
;b960 = loading
;26530: hash
;26574: hash
;26350: Hash (div $48)
;2594c loader?
;95fa: all searches have failed so ask for disk 2 in df0:
