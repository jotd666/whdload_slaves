;*---------------------------------------------------------------------------
;  :Program.	PortalHD.asm
;  :Contents.	Slave for "FA18Interceptor" from 
;  :Author.	JOTD
;  :Original	
;  :Version.	$Id: battleisle.asm 0.5 2000/11/26 21:13:41 jah Exp $
;  :History.	23.05.01 started
;		23.05.01 finished
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

	IFD BARFLY
	OUTPUT	"Portal.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

; number of floppy drives:
;	sets the number of floppy drives, valid values are 0-4.
;	0 means that the number is specified via option Custom1/N
NUMDRIVES=1

; protection state for floppy disks:
;	0 means 'write protected', 1 means 'read/write'
;	bit 0 means drive DF0:, bit 3 means drive DF3:
WPDRIVES=%1111

; enable SetPatch
;	include all patches (nearly all) done by the SetPatch program, usually
;	that is not neccessary and disabling that option makes the Slave
;	around 400 bytes shorter
SETPATCH

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

HDINIT
DOSASSIGN
BLACKSCREEN
BOOTDOS
CACHE
IOCACHE = 10000
STACKSIZE = 4000

; note to self: on V3, to match memory layout with CHIP_ONLY, the
; data files must have "devs" in them. Official installation
; omits it so it boots with a black screen but shifts the
; disassemblies I made
;CHIP_ONLY
; amount of memory available for the system
	IFD	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $50000
	ENDC
	
;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'


;============================================================================

	INCLUDE	whdload/kick13.s
	
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"2.0"
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
	dc.b	$A,0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Dungeon Master"
			IFD		CHIP_ONLY
			dc.B	" (debug/chip mode)"
			ENDC
			
			dc.b	0
slv_copy		dc.b	"1986-1992 FTL/Software Heaven",0
slv_info		dc.b	"Adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_assign1:
	dc.b	"DF0",0
_dm_assign:
	dc.b	"DungeonMaster",0


slv_config:
	dc.b	"BW;"
    dc.b    "C1:X:trainer no damage:0;"
    dc.b    "C5:L:save slot:0,1,2,3,4,5,6,7,8,9:0;"
	dc.b	0

_procname:
	dc.b	"BJELoad",0

_program:
	dc.b	"BJELoad_R",0
_args:
	dc.b	10
_args_end:
	dc.b	0
	even
	
;============================================================================

	;initialize kickstart and environment

_bootdos
		lea		_stacksize(pc),a0
		move.l	(4,a7),(a0)		; store stacksize
		sub.l	#5*4,(a0)			;required for MANX stack check
	
		move.l	(_resload,pc),a2	;a2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
		
		; set slot selected by CUSTOM5
		lea	_savegame_char(pc),a0
		move.l	_savegame_slot(pc),d0
		add.b	#'0',d0
		move.b	d0,(a0)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_dm_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign


	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patchexe(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)




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


	move.l	4,a6
	moveq.l	#0,d0
	jsr		_LVOWait(a6)
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

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.w  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

_patchexe
	move.l	d7,a1		; seglist
	lea		_bjeload_seglist(pc),a0
	move.l	a1,(a0)	; save for later
	add.l	a1,a1
	add.l	a1,a1
	addq.w	#4,a1	; first segment
	
	move.l	_resload(pc),a2
	lea		pl_bjeload(pc),a0
	jsr		resload_Patch(a2)
	
	rts
    
   
	
; don't know if it's any use...
end_bje_patch
	MOVE.L	#$4afc4e73,12(A2)	;006c: 257c4afc4e73000c
	MOVE.L	D4,24(A2)		;0074: 25440018
	add.l	#6,(A7)
	bsr	_flushcache
	rts

c_create_proc
	; fix kickemu issue with bootdos: game fetches
	; whdboot fake exe seglist, when it should fetch
	; the "bjeload_r" seglist
	move.l	_bjeload_seglist(pc),d3
	lea		_procname(pc),a0
	move.l	a0,d1
	JSR	_LVOCreateProc(A6)	;(dos.library)
	MOVE.L	(A7)+,D4		;197e: 281f
	RTS				;1980: 4e75

c_open:
	MOVEM.L	4(A7),D1-D2
	MOVEA.L	-32510(a4),A6	; prog dosbase
	move.l	d1,a0
	move.l	(A0),d0
	lea	last_opened_file(pc),a0
	move.l	d0,(A0)		; save last opened file
	JMP	_LVOOpen(A6)	;(dos.library)

last_opened_file:
	dc.l	0

buttonwait
.loop
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.out
	bra.b	.loop
.out
	rts
	
; for V3.6
; called each time a ".FTL" file is loaded
; runs it

subprogram_jump:
	movem.l	D0-D1/A0-A2,-(A7)
	move.l	_resload(pc),a2
	
	MOVEA.L	24(A6),A5		;original

	move.l	last_opened_file(pc),d0
	cmp.l	#'KAOS',D0
	bne.b	.nokaos

	move.l	_buttonwait(pc),d0
	beq.b	.no_bw
	bsr		buttonwait
.no_bw
	move.l	a0,a1
	lea		pl_kaos(pc),a0
	jsr		resload_Patch(a2)
	bra.b	.out
.nokaos
	cmp.l	#'CNFG',d0
	bne.b	.noconfig
	; just before "FTL" swoosh logo
	; need to fix drive access
	move.l	a0,a1
	lea		pl_cnfg(pc),a0
	jsr		resload_Patch(a2)
;	bra.b	.out
.noconfig
;	cmp.l	#'APPB',d0
;	bne.b	.noappb
;	
;.noappb

.out
	bsr	_flushcache
	movem.l	(A7)+,D0-D1/A0-A2

	jmp	(A0)
	
set_disk_name
	move.l	4(a7),a0
	move.l	a1,-(a7)
	lea		_dm_assign(pc),a1
	moveq	#0,d0
.copy
	move.b	(a1)+,(a0)+
	beq.b	.out
	addq	#1,d0
	bra.b	.copy
.out
	move.l	(a7)+,a1
	
 	MOVE.W	D0,D7			;3c3d6: 3e00
	MOVEQ	#0,D0			;3c3d8: 7000
	MOVE.W	D7,D0			;3c3da: 3007
	rts
	
pl_kaos
	PL_START
    PL_P      $406b8-$3a4ee,check_disk_in_drive
	;;PL_PS	$3c3d2-$3a4ee,set_disk_name
	PL_PSS	$3c486-$3a4ee,check_main_disk_for_savegame,2
	PL_PS	$5ba3e-$3a4ee,check_main_disk
	; don't delete backup file
	PL_NOP	$5c00e-$3a4ee,4
	; don't rename backup to save file
	; (I don't know when it should happen but if it does
	; it will crash the game so it has to go)
	PL_NOP	$5ce6c-$3a4ee,4
	; don't rename current save file to backup
	; whdload doesn't support Rename and it crashes kickemu
	; at this point so skip it
	PL_NOP	$5c01a-$3a4ee,4
	; set proper savegame slot from "resume"
	; (main disk not checked when quit+restart)
	PL_PS	$5cb12-$3a4ee,set_savegame_slot_from_resume_v3
	; trainer
    PL_IFC1X    0
    PL_NOP      $47c56-$3a4ee,4   ; no damage when hitting walls
    PL_ENDIF
    PL_END
	
pl_bjeload
	PL_START
	PL_PS	$6C,end_bje_patch
	PL_PS	$E8C,subprogram_jump
	PL_P	$19BA,c_open
	PL_P	$197A,c_create_proc
    ;;PL_PSS  $0820,loader_routine_wrap,10
    PL_B    $084c,$60 ; remove checksum check so we can modify the main proggy...
    PL_B    $0752,$60 ; remove checksum check so we can modify the main proggy...
    PL_R    $0be0   ; remove checksum routine to save time!
	PL_NOP	$0a68,6	; remove delay at startup
	PL_END
	
pl_cnfg
	PL_START
	; skip useless "disk in drive" check
	;PL_NOP	$250a0-$24c4a,6
	;PL_B	$250a6-$24c4a,$60
	PL_P	$24f9a-$24c4a,check_disk_in_drive	; D0 != 0: disk in drive
	PL_END
	
	
check_main_disk
	; check if main disk is inserted
	; at the same time, change savegame filename to put
	; our savename instead, from now on game uses that pointer
	; (done there because it's called at game start)
	bsr		set_proper_savegame_slot_v3
	
	moveq.l	#0,d0	; main disk inserted
	move.w	d0,-16446(A5)
	rts
	
set_savegame_slot_from_resume_v3
	; original code
	JSR	154(A5)			;5cb12: 4ead009a
	SUBQ.W	#1,D0			;5cb16: 5340
	bsr		set_proper_savegame_slot_v3
	tst.w	d0
	rts
	
set_proper_savegame_slot_v3
	movem.l	A1,-(a7)
	lea		_savegame_name(pc),a1
	move.l	a1,-9084(A5)
	movem.l	(a7)+,A1
	rts
	
check_main_disk_for_savegame
	moveq	#1,d0		; save disk inserted
	move.w	d0,-16446(A5)
	MOVE.W	D0,-2(A6)		;3c48a: 3d40fffe
	rts
	
check_disk_in_drive
	moveq	#1,d0
	rts
	
_tag		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_BUTTONWAIT_GET
_buttonwait	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_savegame_slot
		dc.l	0
		dc.l	0
_seglist:
	dc.l	0
_msq:
	dc.w	0
_saveregs
	ds.l	16,0
_stacksize
	dc.l	0
_bjeload_seglist
	dc.l	0
_gfxname
	dc.b	"graphics.library",0
_savegame_name
	dc.b	"save/DMGAME_"
_savegame_char
	dc.b	"0.DAT",0
	