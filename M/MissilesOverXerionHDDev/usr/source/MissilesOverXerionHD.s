	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;============================================================================

; number of floppy drives:
;	sets the number of floppy drives, valid values are 0-4.
;	0 means that the number is specified via option Custom1/N
NUMDRIVES=1

; protection state for floppy disks:
;	0 means 'write protected', 1 means 'read/write'
;	bit 0 means drive DF0:, bit 3 means drive DF3:
WPDRIVES=%1111

; disable fpu support:
;	results in a different task switching routine, if fpu is enabled also
;	the fpu status will be saved and restored.
;	for better compatibility and performance the fpu should be disabled
NOFPU

; enable debug support for hrtmon:
;	hrtmon reads to much from the stackframe if entered, if the ssp is at
;	the end hrtmon will create a access fault.
;	for better compatibility this option should be disabled
;HRTMON

; calculate minimal amount of free memory
;	if the symbol MEMFREE is defined after each call to exec.AllocMem the
;	size of the largest free memory chunk will be calculated and saved at
;	the specified address if lower than the previous saved value (chipmem
;	at MEMFREE, fastmem at MEMFREE+4)
;MEMFREE=$100

; amount of memory available for the system


HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000

    
BOOTBLOCK
TRDCHANGEDISK
DISKSONBOOT

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	kick13.s
IGNORE_JOY_DIRECTIONS
    include ReadJoyPad.s
    
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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
    
slv_name		dc.b	"Missiles Over Xerion",0
slv_copy		dc.b	"1994 Kingsoft",0
slv_info		dc.b	"Adapted by Bored Seal & JOTD",10,10
		dc.b	"Version "
        DECL_VERSION
        dc.b    0
slv_CurrentDir:
	dc.b	"data",0
    
slv_config:
    dc.b    "BW;"
    dc.b    0
    EVEN

	;a1 = ioreq ($2c+a5)
	;a4 = buffer (1024 bytes)
	;a6 = execbase
_bootblock
		movem.l	a0-a2,-(sp)
        bsr _detect_controller_types
        lea controller_joypad_0(pc),a0
        clr.b   (a0)        ; forces joystick/mouse (no need for pad)
        move.l _resload(pc),a2

	;call bootblock
        move.l  a4,a1
        lea pl_boot(pc),a0
        jsr (resload_Patch,a2)
        
		movem.l	(sp)+,a0-a2
		lea	($2c,a5),a1

		jmp	(12,a4)

pl_boot:
    PL_START
    PL_W    $5A,$6030		;skip menu
    PL_IFBW
    PL_PS    $12E,PatchPicWait
    PL_ELSE
    PL_PS    $12E,PatchPic
    PL_ENDIF
    PL_P    $17C,PatchGame
    PL_END
    
PatchPicWait
        bsr	PicWait
PatchPic
		move.w	#$01fe,$309c4		;snoop bug fix
		jmp	$30000

PatchGame
    movem.l	a0-a2/d0-d1,-(sp)
    lea	gamedata(pc),a0
    lea	$d0000,a1
    move.l	_resload(pc),a2
    jsr	resload_LoadFile(a2)

    lea	$d0000,a1
    lea pl_main(pc),a0
    jsr resload_Patch(a2)
    movem.l	(sp)+,a0-a2/d0-d1
    jmp	$d0000

pl_main
    PL_START
    PL_PS   $92,InsertDisk2
    PL_PSS  $31C0,ack_keyboard,6    ; replace ack which seems loopy!
    PL_PS   $31DC,test_quit
    PL_PS   $333c,read_joypad
    PL_S    $3342,$4C-$42
    PL_PSS  $2cde,test_fire,2
    PL_END

test_fire:
    movem.l  d0,-(a7)
    move.l  joy1_buttons(pc),d0
    not.l   d0
    btst    #JPB_BTN_RED,d0
    movem.l (a7)+,d0
    rts
    
ack_keyboard
    move.l  d0,d1
	move.l	#2,d0
	bsr	beamdelay
    move.l  d1,d0
    rts

FIRE_WEAPON:MACRO
    btst    #JPB_BTN_\1,d0
    beq.b   .no\1
	MOVE.W	#\2,$e1540
    MOVE.B	#$01,$e1614
.no\1
   ENDM
    
read_joypad
    bsr _read_joysticks_buttons
    movem.l d0-d1/a0,-(a7)
    move.l  joy1_buttons(pc),d0
    FIRE_WEAPON   BLU,0     ; F1
    FIRE_WEAPON   YEL,4     ; F2
    FIRE_WEAPON   GRN,8     ; F3
    FIRE_WEAPON   REVERSE,$C     ; F4
    FIRE_WEAPON   FORWARD,$10     ; F5
    FIRE_WEAPON   PLAY,$14     ; F6
    move.l  joy0_buttons(pc),d0
    lea previous_joy0_buttons(pc),a0
    move.l  (a0),d1
    btst    #JPB_BTN_RED,d1
    bne.b   .lmb_prev_press
    btst    #JPB_BTN_RED,d0
    beq.b   .lmb_prev_press
    eor.b   #1,$e1638       ; pause
.lmb_prev_press
    move.l  d0,(a0)
    movem.l (a7)+,d0-d1/a0
    rts
    
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

_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)
    
test_quit:
    ror.b   #1,d0
    cmp.b   _keyexit(pc),d0
    beq.b     _quit
    cmp.b   #$45,d0
    rts
    
PicWait		movem.l	a0,-(sp)
		lea	$bfe001,a0
test		btst	#6,(a0)
		beq.b	ButtonPressed
		btst	#7,(a0)
		bne.b	test
ButtonPressed	movem.l	(sp)+,a0
		rts

InsertDisk2	movem.l	a0-a2/d0,-(sp)
		moveq	#0,d0
		moveq	#2,d1
		bsr	_trd_changedisk
		movem.l	(sp)+,a0-a2/d0
		rts
previous_joy0_buttons
    dc.l    0
gamedata	dc.b	"Xerion",0
