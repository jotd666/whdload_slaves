;*---------------------------------------------------------------------------
;  :Program.	ExileAGAHD.s
;  :Contents.	Slave for "Exile AGA/CD32"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BoppinHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
;  :History.	%DATE% started
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;CHIP_ONLY

	IFD BARFLY
	OUTPUT	"ExileAGA.slave"
	IFND	CHIP_ONLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	ENDC
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================


	IFD	CHIP_ONLY
HRTMON
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $1E0000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE
CBDOSLOADSEG

QUIT_JOYPAD_MASK = JPF_BUTTON_FORWARD|JPF_BUTTON_REVERSE|JPF_BUTTON_PLAY

; patch to avoid crash when opening cd.device onCD32 version
DUMMY_CD_DEVICE = 1
; nonvolatile not used, bypassed on cd32 version
USE_DISK_NONVOLATILE_LIB = 1

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

	include	kick31cd32.s
    include savegame.s      ; only for CD32 version
    
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
	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0


slv_name		dc.b	"Exile AGA/CD32"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1995 Audiogenic",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

assign
	dc.b	"sav",0

savedir
    dc.b    "save",0
    
bootprog:
    dc.b    "disk1boot",0
program:
	dc.b	"exile",0
args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
slv_config
    dc.b    "BW;"
	dc.b	0
	EVEN

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg

	move.l	d0,a0
	add.l	a0,a0
	add.l	a0,a0

   
	cmp.b	#9,(a0)
	bne.b	.skip_exile
    cmp.b   #'e',(5,a0)
 	bne.b	.skip_exile
    move.l  d1,a1
   IFD  CHIP_ONLY
   add.l    d1,d1
   add.l    d1,d1
   move.l   d1,$FC.W
   
   ENDC
    bsr patch_aga
.skip_exile
	rts
    

_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

    ; in debug mode make "disk1boot" segment align to $20000
        IFD CHIP_ONLY
        movem.l  a0-a6,-(a7)
        move.l	4,a6
        move.l  #MEMF_CHIP,D1
        move.l  #$29D0,d0
        jsr (_LVOAllocMem,a6)
        lea memchunk(pc),a0
        move.l  d0,(a0)
        movem.l  (a7)+,a0-a6
        ENDC


		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	4,a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
        lea _dosbase(pc),a0
        move.l  a6,(a0)
        
	;assigns
		lea	assign(pc),a0
		lea savedir(pc),a1
		bsr	_dos_assign


	;load exe
		lea	bootprog(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_boot(pc),a5
		bsr	load_exe
	;quit

_exit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


    
; < d7: seglist (BPTR)

patch_boot
	bsr	get_version
    move.l  d7,a1
    add.l   d7,d7
    add.l   d7,d7
    addq.l  #4,d7
    move.l  _resload(pc),a2

    cmp.l   #2,d0
    beq.b   .cd32
    
	lea	pl_boot_aga(pc),a0
	jsr	resload_PatchSeg(a2)

    ; in debug mode make "exile" segment align to $90000
    IFD CHIP_ONLY
    movem.l  d0-a6,-(a7)
    move.l	4,a6
 ;   move.l  #$29D0,d0
 ;   move.l  memchunk(pc),a1
 ;   jsr (_LVOFreeMem,a6)

    move.l  #MEMF_CHIP,D1
    move.l  #$E1A0,d0
    jsr (_LVOAllocMem,a6)
    movem.l  (a7)+,a0-a6
    ENDC
    rts
    
.cd32
    ;;bsr _patch_cd32_libs
	lea	pl_boot_cd32(pc),a0
	jsr	resload_PatchSeg(a2)
   
	rts

patch_aga
	bsr	get_version
    cmp.l   #2,d0
    beq.b   .cd32

	lea	pl_aga(pc),a0
    move.l  _resload(pc),a2
	jsr	resload_PatchSeg(a2)

    rts
.cd32
	lea	pl_cd32(pc),a0
    move.l  _resload(pc),a2
	jsr	resload_PatchSeg(a2)

    movem.l  d0-a6,-(a7)
    move.l	4,a6
    move.l  #MEMF_CHIP,D1
    move.l  #$3000,d0
    jsr (_LVOAllocMem,a6)
    lea screen_memory(pc),a0
    move.l  d0,(a0)
    movem.l  (a7)+,d0-a6
    bsr _patch_cd32_libs

	rts

CRACK:MACRO
    MOVE.L	#$8cd00bc3,D5   ; copylock id
    dc.l    $600008c2       ; branch after copylock encrypted code
    ENDM
    
pl_boot_aga
	PL_START
	; crack
    PL_DATA $070c,10
    CRACK

    PL_AL   $1034,4     ; skip DF0: prefix
    
    ; skip/wait on intro screens
    PL_IFBW
    PL_PSS  $1E,show_credits,2
    PL_ENDIF
    ; no brief "insert disk 2"
    PL_NOP  $102e,4
	PL_END
    
pl_aga
	PL_START
	; crack
    PL_DATA $21cb2,10
    CRACK

    PL_PS   $2403A,dos_open_hook
    PL_PS   $23770,kbint_hook
    PL_L    $263fa,"SAV:"
    PL_L    $2640a,"SAV:"
    PL_L    $2643c,"SAV:"
    ; kickfs doesn't like MODE_READWRITE
    PL_L    $25d9A,MODE_NEWFILE
    PL_NOP  $25cfa,4    ; remove delays after read/write
    PL_NOP  $25d26,4    ; remove delays after read/write
    PL_NOP  $25de2,4    ; remove delays after read/write
    PL_NOP  $25e26,4    ; remove delays after read/write
	PL_END
    
pl_boot_cd32
	PL_START
    PL_IFBW
    PL_PSS  $0028,buttonwait,4
    PL_ENDIF
	PL_END
pl_cd32
	PL_START
	; crack
    PL_P    $24f98,check_nv_size

    ; quit with novbrmove
    PL_PS   $22efe,kbint_hook
    
    ; save game without nonvolatile
    PL_S   $24d5a,$80-$5a
    PL_P   $24de8,save_game

    ; load game without nonvolatile
    PL_S    $24c3e,$78-$3e
    PL_PSS  $24c82,load_game,8
    PL_L    $24cc6,$70FF4E75
	PL_END

check_nv_size
    moveq.l   #0,d0    ; returns "nonvolatile size is okay" !
    rts

show_credits
   move.l   (A7),a3 ; return address
   lea    $12A4(a3),A3
   jsr  (a3)        ; emulate bsr display credits
   move.l   (A7),a3 ; return address
   lea    $5AC(a3),A3   ; emulate lea
buttonwait
   btst    #7,$bfe001
   bne.b    buttonwait
   rts
   
; < A0: savegame buffer
; < D0: savegame size

save_game:
    move.l  #$360*2,d0
    move.l  screen_memory(pc),a1		;free mem for screen
    lea	(savename,pc),a2	;name of savegame file
	bsr	_sg_save
    ; don't wait for firepress after save
    ; (#0 => stupid firepress)
    moveq.l #-1,d0
    rts
    
load_game:
    move.l  #$360*2,d0
    move.l  a1,a0
    move.l  screen_memory(pc),a1		;free mem for screen
    lea	(savename,pc),a2	;name of savegame file
	bsr	_sg_load
    tst.l   d0
    bne.b   .ok
    moveq.l #-1,d0
    addq.l  #4,A7   ; pop stack, return immediately
.ok
    rts

savename
      dc.b     "savegame",0
      even
screen_memory
     dc.l    0
        
kbint_hook:
	LSR.B	#1,D0			;23770: e208
	SCC	(0,A0,D0.W)		;23772: 54f00000
    ; save status to be able to preserve carry when returning
    move  sr,-(a7)
    cmp.b   _keyexit(pc),d0
    beq _exit
    move  (a7)+,sr
    rts
    
dos_open_hook:
    ; strip off assigns
    move.l  d1,a0
.loop
    tst.b   (a0)
    beq.b   .end
    cmp.b   #':',(a0)+
    bne.b   .loop
    move.l  a0,d1
.end
	MOVE.L	#$000003ed,D2		;2403a: 243c000003ed
    rts

get_version:
	movem.l	d1/a0-a2,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#187828,D0
	beq.b	.aga
    cmp.l   #187048,d0
    beq.b   .cd32
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.aga
	moveq	#1,d0
	bra.b	.out
.cd32
	moveq	#2,d0
	bra	.out
.out
	movem.l	(a7)+,d1/a0-a2
	rts



; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe:
	movem.l	d0-a6,-(a7)
	move.l	d0,d2
	move.l	a0,a3
	move.l	a1,a4
	move.l	a0,d1
	jsr	(_LVOLoadSeg,a6)

	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found

	;patch here
	cmp.l	#0,A5
	beq.b	.skip
	movem.l	d2/d7/a4,-(a7)

	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

	movem.l	d7/a6,-(a7)

	move.l	d2,d0			; argument string length
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
	jsr	(4,a3)		; call program
	addq.l	#4,a7

	movem.l	(a7)+,d7/a6

	;remove exe

	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_saveregs
		ds.l	16,0
_stacksize
		dc.l	0
;_dosbase       ; defined in kick31cd32.s
;		dc.l	0

tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0
memchunk
    dc.l    0
    
;============================================================================

	END
