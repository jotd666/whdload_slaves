;*---------------------------------------------------------------------------
;  :Program.	DungeonMasterHD.asm
;  :Contents.	Slave for "Dungeon Master" from 
;  :Author.	JOTD
;  :Original	
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14, Barfly 2.9, vasm
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/intuition.i
	INCLUDE	intuition/intuitionbase.i

	IFD BARFLY
	OUTPUT	"DungeonMaster.slave"
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
CHIPMEMSIZE	= $120000
FASTMEMSIZE	= $0000
SEGTRACKER
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
BLACKSCREEN
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
_dmsave_assign:
	dc.b	"DungeonSave",0


slv_config:
	dc.b	"BW;"
    dc.b    "C1:X:trainer no damage:0;"
    dc.b    "C5:L:save slot:disabled,"
	REPT	9
	dc.b	"slot ",REPTN+'0',','
	ENDR
	dc.b	"slot 9;"
	dc.b	0

_procname_v3:
	dc.b	"BJELoad",0

_dm_name
	dc.b	"dm",0
_program_v2:
	dc.b	"exec",0
_program_v36:
	dc.b	"BJELoad_R",0
_args:
	dc.b	10
_args_end:
	dc.b	0
	even

;               startup name          exec patchlist       savename  buttonwait
_patch_table
	dc.w	_program_v36-_patch_table,pl_bjeload-_patch_table,-9084,0	; v36
	dc.w	_program_v2-_patch_table,pl_exec_v22-_patch_table,-7858,-31482	; v22 (uk)
	dc.w	_program_v2-_patch_table,pl_exec_6036-_patch_table,-7810,-31482	; v20 (fr)
	dc.w	_program_v2-_patch_table,pl_exec_6036-_patch_table,-7902,-31482	; v20 (uk)
	dc.w	_program_v2-_patch_table,pl_exec_6036-_patch_table,-7810,-31482	; v22
	
VERSION_36 = 0
VERSION_22_uk = 1
VERSION_20_fr = 2
VERSION_20_uk = 3
VERSION_22_de = 4


PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
    ENDM
	
	
;============================================================================

	;initialize kickstart and environment

_bootdos
		lea		_stacksize(pc),a0
		move.l	(4,a7),(a0)		; store stacksize
		sub.l	#5*4,(a0)			;required for MANX stack check
	
		; get current task
		move.l	4.W,a6
		sub.l	a1,a1
		jsr		(_LVOFindTask,a6)
		lea		_current_task(pc),a0
		move.l	d0,(a0)
		
		move.l	(_resload,pc),a2	;a2 = resload

	;get tags
		lea	(_tag,pc),a0
		jsr	(resload_Control,a2)
		
		; set slot selected by CUSTOM5
		lea	_savegame_char(pc),a0
		move.l	_savegame_slot(pc),d0
		add.b	#'0'-1,d0
		move.b	d0,(a0)

		lea		_gfxname(pc),a1
		move.l	$4.w,a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6

		; wait after graphics.library calls, else
		; some graphics can be trashed. RectFill is
		; probably the culprit (top left character name
		; sometimes trashed on fast machines).
		;
		; this is very common mistake in games, seen
		; multiple times. All hardware banging calls are
		; done properly (calling WaitBlit each time it's needed)
		; but most devs at the time ignored/forgot that even if
		; the OS handles the blitter, you're still responsible
		; for it not being active when you call the functions
		; (which is a design flaw retrospectively, but also maybe
		; in order to maximize performance)
		;
		; or it's a mixup between syscalls & hardware banging
		; which is responsible. Nevermind, this is now fixed.
		
        PATCH_XXXLIB_OFFSET RectFill
        PATCH_XXXLIB_OFFSET BltBitMap

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
		lea		_dosbase(pc),a0
		move.l	a6,(a0)
		
	;assigns
		lea	_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_dm_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_dmsave_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	_check_version

		; align exe memory on round value
        IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6		
		move.l	_dosbase(pc),$100.W	; debug Dos calls
		move.l	_version(pc),d0
		cmp.l	#VERSION_22_uk,d0
		bne.b	.no_align
        move.l  #$20000-$1B778,d0		; align	"exec" on $20000
        move.l  #$30000-$1B778-$F0F0,d0	; align "swoosh" on $30000
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)		
.no_align
        movem.l (a7)+,a6

        ENDC
		; pre-fetch some properties for later
		; > A0: boot exe name
		; sets savename offset & buttonwait patch
		; routine offset (which is overwritten by buttonwait)
		lea		_patch_table(pc),a1
		move.l	_version(pc),d0
		add.l	d0,d0
		add.l	d0,d0
		add.l	d0,d0	; *8
		move.w	(a1,d0.w),a0
		add.l	a1,a0
		add.w	d0,a1	; set proper version structure
		move.l	_savegame_slot(pc),d0
		beq.b	.slot_disabled
		move.w	(4,a1),d0
		lea		_savename_offset(pc),a3
		move.w	d0,(a3)
.slot_disabled
		move.w	(6,a1),d0
		lea		_bw_patch_offset(pc),a3
		move.w	d0,(a3)
	;load exe
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	_patchexe(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


_check_version
	lea	_version(pc),a3
	lea		_program_v2(pc),a0
	jsr		resload_GetFileSize(a2)
	tst.l	d0
	bne.b	.v2x
	lea		_program_v36(pc),a0
	jsr		resload_GetFileSize(a2)
	tst.l	d0
	beq.b	.unknown
	; v36?
	cmp.l	#7912,d0
	beq.b	.v36
.unknown
	; unsupported/unknown
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.v36
	move.l	#VERSION_36,(a3)
	rts

.v2x:
	cmp.l	#6036,d0
	beq.b	.v20
	move.l	#VERSION_22_uk,(a3)
	rts
.v20
	; 2.0 has 3 languages
	lea		_dm_name(pc),a0
	jsr		resload_GetFileSize(a2)
	cmp.l	#177304,d0
	beq.b	.v20_fr
	cmp.l	#177324,d0
	beq.b	.v20_uk
	cmp.l	#177352,d0
	beq.b	.v22_de
	bra.b	.unknown
.v20_uk
	move.l	#VERSION_20_uk,(a3)
	rts
.v20_fr
	move.l	#VERSION_20_fr,(a3)
	rts
.v22_de
	move.l	#VERSION_22_de,(a3)
	rts

zap_pointer:
	movem.l	d0-d3/a0-a2/a6,-(a7)
	move.l	4.W,a6
	move.l	#MEMF_CHIP|MEMF_CLEAR,d1
	move.l	#12,d0
	jsr	(_LVOAllocMem,a6)
	move.l	d0,a2		; save for later
	
	lea	(_intname,pc),a1
	jsr	(_LVOOldOpenLibrary,a6)
	move.l	d0,a6
	move.l	ib_ActiveWindow(a6),a0
	move.l	a2,a1
	moveq	#1,d0
	moveq	#1,d1
	moveq	#0,d2
	moveq	#0,d3
	jsr	_LVOSetPointer(a6)
	
	movem.l	(a7)+,d0-d3/a0-a2/a6
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

	; change task so boot program finds its own segments
	;move.l	_current_task(pc),a0
	;move.l	d7,pr_SegList(a0)
	
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
.unload
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
	lea		_bootup_seglist(pc),a0
	move.l	a1,(a0)	; save for later
	add.l	a1,a1
	add.l	a1,a1
	addq.w	#4,a1	; first segment
	
	lea		_patch_table(pc),a2
	move.l	_version(pc),d0
	add.l	d0,d0
	add.l	d0,d0
	add.l	d0,d0
	move.l	a2,a0
	add.w	(2,a2,d0.l),a0		; proper patchlist
	
	move.l	_resload(pc),a2
	jmp		resload_Patch(a2)
	
    
  
buttonwait
.loop
	btst	#6,$bfe001
	beq.b	.out
	btst	#7,$bfe001
	beq.b	.out
	bra.b	.loop
.out
	rts
	
; version 2.0 & some 2.2: same "exec" file

pl_exec_6036:
	PL_START
	PL_NOP	$762,4	; stupid delay
	PL_R	$16ac	; can't close workbench
	PL_PSS	$236,fix_autodetach_v2x,2
	PL_P	$134e,loadseg_hook
	PL_END

; version 2.2 (uk) smaller "exec" file

pl_exec_v22:
	PL_START
	PL_NOP	$744,4	; stupid delay
	PL_R	$168e	; can't close workbench
	PL_PSS	$236,fix_autodetach_v2x,2
	PL_P	$1330,loadseg_hook
	PL_END
	
pl_swoosh
	PL_START
	PL_B	$00348,$60
	PL_NOP	$0039c,6
	PL_END
	
pl_dm_v22_uk
	PL_START
	; trackdisk patch
	PL_P	$2402e,check_disk_in_drive
	; able to save on current dir
	PL_P	$24456,which_disk_test
	
	PL_PSS	$1a74e,expect_save_disk,4
	PL_PSS	$1b72e,expect_game_disk,4
	; skip another "is savedisk in drive" flag check
	; right after savegame file has been opened
	; but don't skip if savegame not found else it crashes
	PL_W	$1b7d4+2,$3
	PL_B	$1b7da,$67
	
	; skip hardware disk read
	; (encountered when saving game)
	; meynaf didn't patch it so it probably does
	; nothing, but requires floppy in drive
	PL_S	$1a8e8,$1ab32-$1a8e8
	
	PL_NOP	$24470,2		; force savedisk
	; remove dos.Rename for saves (whdload doesn't support rename)
	; useless as we use the bytes of the caller to select save slot
	;PL_R	$2b218
	PL_PSS	$1ac60,set_proper_savegame_slot,8
	
	; other protection??? leave as is ATM
	; if users report lockups, it's probably the issue
	;PL_I	$24448
	;PL_I	$2352e
	
	; meynaf crack
	PL_B	$0bf08,$60
	PL_R	$13976
	PL_B	$1787c,$60
	PL_B	$18bf2,$60
	PL_B	$19e58,$60
	PL_B	$1a2d4,$60
	PL_L	$2411c,$7004E75
	; jotd addons to be able to disable prot routine
	PL_NOP	$1b4ee,4	; skip checksum
	PL_NOP	$1b4f8,4	; skip test (BNE)
	; 3 checksum routines, should not be called
	; meynaf & jotd patches should avoid them, but
	; if they're activated at least it will crash loudly
	PL_I	$16d30
	PL_I	$1a0b4
	PL_I	$1a0e0

	PL_IFBW
	PL_PSS	$2b1b4,buttonwait_title,6
	PL_ENDIF

    PL_IFC1X    0
    PL_NOP      $1eea6,4   ; no damage when hitting walls
    PL_ENDIF	
	PL_END
	
pl_dm_v20_fr
	PL_START
	; trackdisk patch
	PL_P	$23E8A,check_disk_in_drive
	; able to save on current dir
	PL_P	$242b2,which_disk_test
	
	PL_PSS	$1a6ca,expect_save_disk,4
	PL_PSS	$1b68e,expect_game_disk,4
	; skip another "is savedisk in drive" flag check
	; right after savegame file has been opened
	; but don't skip if savegame not found else it crashes
	PL_W	$1b734+2,3	; test for "3": no savegame found
	PL_B	$1b73a,$67	; invert condition
	; skip hardware disk read
	; (encountered when saving game)
	; meynaf didn't patch it so it probably does
	; nothing, but requires floppy in drive
	PL_S	$1a864,$1aaae-$1a864
	
	PL_NOP	$242cc,2		; force savedisk
	; remove dos.Rename for saves (whdload doesn't support rename)
	; useless as we use the bytes of the caller to select save slot
	;PL_R	$2b218
	PL_PSS	$1abdc,set_proper_savegame_slot,8
	
	; other protection??? leave as is ATM
	; if users report lockups, it's probably the issue
	;PL_I	$242a4
	;PL_I	$235d0
	
	; meynaf crack
	PL_B	$0bf18,$60
	PL_R	$1399e
	PL_B	$177f0,$60
	PL_B	$18b66,$60
	PL_B	$19dd4,$60
	PL_B	$1a250,$60
	PL_L	$23f78,$7004E75
	; jotd addons to be able to disable prot routine
	PL_NOP	$1b46a,4	; skip checksum
	PL_NOP	$1b474,4	; skip test (BNE)

	PL_IFBW
	PL_PSS	$2af54,buttonwait_title,6
	PL_ENDIF

	; 3 checksum routines, should not be called
	; meynaf & jotd patches should avoid them, but
	; if they're activated at least it will crash loudly
	PL_I	$16ca4
	PL_I	$1a030
	PL_I	$1a05c
	; fix spelling "ANNULLER" => "ANNULER"
	; by patching strlen and check for string
	PL_P	$2af74,strlen_fr

    PL_IFC1X    0
    PL_NOP      $1edf4,4   ; no damage when hitting walls
    PL_ENDIF


	PL_END
	
pl_dm_v20_uk
	PL_START
	; trackdisk patch
	PL_P	$23e9a,check_disk_in_drive
	; able to save on current dir
	PL_P	$242c2,which_disk_test
	
	PL_PSS	$1a5d6,expect_save_disk,4
	PL_PSS	$1b59a,expect_game_disk,4
	; skip another "is savedisk in drive" flag check
	; right after savegame file has been opened
	; but don't skip if savegame not found else it crashes
	PL_W	$1b640+2,3	; test for "3": no savegame found
	PL_B	$1b646,$67	; invert condition
	
	; skip hardware disk read
	; (encountered when saving game)
	; meynaf didn't patch it so it probably does
	; nothing, but requires floppy in drive
	; strangely in the uk version this looks like it's disabled
	PL_S	$1a770,$1a9ba-$1a770
	
	PL_NOP	$242dc,2		; force savedisk
	; we use the bytes of the rename caller to select save slot
	PL_PSS	$1aae8,set_proper_savegame_slot,8

	; other protection??? leave as is ATM
	; if users report lockups, it's probably the issue
	;PL_I	$24294
	;PL_I	$234dc
	
	; meynaf crack
	PL_B	$0bebc,$60
	PL_R	$13942
	PL_B	$177f0,$60
	PL_B	$17704,$60
	PL_B	$19ce0,$60
	PL_B	$1a15c,$60
	PL_L	$23f88,$7004E75
	; jotd addons to be able to disable prot routine
	PL_NOP	$1b376,4	; skip checksum
	PL_NOP	$1b380,4	; skip test (BNE)
	
	PL_IFBW
	PL_PSS	$2af64,buttonwait_title,6
	PL_ENDIF

	; 3 checksum routines, should not be called
	; meynaf & jotd patches should avoid them, but
	; if they're activated at least it will crash loudly
	PL_I	$16bb8
	PL_I	$19f3c
	PL_I	$19f68
	
    PL_IFC1X    0
    PL_NOP      $1ed12,4   ; no damage when hitting walls
    PL_ENDIF
	PL_END
	
pl_dm_v22_de
	PL_START
	; trackdisk patch
	PL_P	$23eba,check_disk_in_drive
	; able to save on current dir
	PL_P	$242e2,which_disk_test
	
	PL_PSS	$1a6b2,expect_save_disk,4
	PL_PSS	$1b5fc,expect_game_disk,4
	; skip another "is savedisk in drive" flag check
	; right after savegame file has been opened
	; but don't skip if savegame not found else it crashes
	PL_W	$1b71c+2,$3
	PL_B	$1b722,$67
	
	; skip hardware disk read
	; (encountered when saving game)
	; meynaf didn't patch it so it probably does
	; nothing, but requires floppy in drive
	PL_S	$1a84c,$1aaae-$1a864
	
	PL_NOP	$242fc,2		; force savedisk
	; remove dos.Rename for saves (whdload doesn't support rename)
	; useless as we use the bytes of the caller to select save slot
	;PL_R	$2bxxxx218
	PL_PSS	$1abc4,set_proper_savegame_slot,8

	
	; other protection??? leave as is ATM
	; if users report lockups, it's probably the issue
	;PL_I	$242d4
	;PL_I	$23600	

	; meynaf crack
	PL_B	$0bf18,$60		; same as fr 20
	PL_R	$1399e	; same as fr 20
	PL_B	$177dc,$60
	PL_B	$18b52,$60
	PL_B	$19db8,$60
	PL_B	$1a238,$60
	PL_L	$23fa8,$7004E75
	; jotd addons to be able to disable prot routine
	PL_NOP	$1b452,4	; skip checksum
	PL_NOP	$1b45c,4	; skip test (BNE)
	; 3 checksum routines, should not be called
	; meynaf & jotd patches should avoid them, but
	; if they're activated at least it will crash loudly
	PL_I	$16c90
	PL_I	$1a01a
	PL_I	$1a044

	PL_IFBW
	PL_PSS	$2af84,buttonwait_title,6
	PL_ENDIF


    PL_IFC1X    0
    PL_NOP      $1edfc,4   ; no damage when hitting walls
    PL_ENDIF
	PL_END

; call graphics.library function then wait
DECL_GFX_WITH_WAIT:MACRO
new_\1
    pea .next(pc)
	move.l	old_\1(pc),-(a7)
	rts
.next:
    bra wait_blit
    ENDM
    

    ; the calls where a wait is useful
    DECL_GFX_WITH_WAIT  RectFill
    DECL_GFX_WITH_WAIT  BltBitMap
	
wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
	
strlen_fr
	MOVEA.L	4(A7),A0		;2af74: 206f0004
	cmp.b	#'A',(a0)
	bne.b	.no
	cmp.b	#'N',(1,a0)
	bne.b	.no
	cmp.b	#'N',(2,a0)
	bne.b	.no
	cmp.b	#'U',(3,a0)
	bne.b	.no
	cmp.b	#'L',(4,a0)
	bne.b	.no
	; fix typo
	move.b	#'E',(5,a0)
	move.b	#'R',(6,a0)
	move.b	#0,(7,a0)
.no
	; original code
	MOVE.L	A0,D0			;2af78: 2008
.lb_2af7a:
	TST.B	(A0)+			;2af7a: 4a18
	BNE.S	.lb_2af7a		;2af7c: 66fc
	SUBA.L	D0,A0			;2af7e: 91c0
	MOVE.L	A0,D0			;2af80: 2008
	SUBQ.L	#1,D0			;2af82: 5380
	RTS				;2af84: 4e75
	
buttonwait_title
	move.l	D0,-(a7)
	move.w	_bw_patch_offset(pc),d0
	PEA	$000239c0		;2af64: 4879000239c0
	JSR	(A4,d0.W)		;2af6a: 4eac8506 (links:jmp=lb_24632)
	ADDQ.W	#4,A7			;2af6e: 584f
	move.l	(a7)+,d0
	bra		buttonwait
	
set_proper_savegame_slot
	movem.l	d0-d1/A1,-(a7)
	lea		_savegame_name(pc),a1
	move.w	_savename_offset(pc),d0
	beq.b	.skip
	move.l	_version(pc),d1
	cmp.l	#VERSION_36,d1
	beq.b	.a5
	move.l	a1,(A4,d0.w)
	bra.b	.skip
.a5
	move.l	a1,(A5,d0.w)
.skip
	movem.l	(a7)+,d0-d1/A1
	rts



expect_save_disk:
expect_game_disk:
	bsr	set_proper_savegame_slot
	moveq.l	#1,d0		; save disk is present
	rts
which_disk_test:
	moveq.l	#1,d0		; save disk is present
	rts
	
loadseg_hook:
	move.l	(4,a7),d1
	move.l	_dosbase(pc),a6
	jsr		(_LVOLoadSeg,A6)
	move.l	(4,a7),a0		; now check name
	move.l	d0,a1			; save seglist in a1
	movem.l	d0/a2,-(a7)
	move.l	_resload(pc),a2
	add.w	#14,a0
	cmp.b	#'s',(a0)
	beq.b	.patch_swoosh
	cmp.b	#'d',(a0)
	beq.b	.patch_dm
	bra.b	.end
.patch_swoosh
	lea		pl_swoosh(pc),a0
	jsr		resload_PatchSeg(a2)
.end
	movem.l	(a7)+,d0/a2
	rts
.patch_dm
	bsr		zap_pointer
	move.l	_version(pc),d0
	add.l	d0,d0
	lea		pl_dm_list(pc),a0
	add.w	(a0,d0.l),a0
	jsr		resload_PatchSeg(a2)
	bra.b	.end

pl_dm_list:
	dc.w	0
	dc.w	pl_dm_v22_uk-pl_dm_list
	dc.w	pl_dm_v20_fr-pl_dm_list
	dc.w	pl_dm_v20_uk-pl_dm_list
	dc.w	pl_dm_v22_de-pl_dm_list


fix_autodetach_v2x
	move.l	(a7)+,a0
	move.l	_bootup_seglist(pc),d5
	MOVE.L	D5,-(A7)		;0236: 2f05
	CLR.L	-(A7)			;0238: 42a7
	PEA	-32750(A4)		;023a: 486c8012
	move.l	a0,-(a7)
	rts
	
; version 3.6 (SPS833)

pl_kaos
	PL_START
    PL_P      $406b8-$3a4ee,check_disk_in_drive
	PL_PSS	$3c486-$3a4ee,check_main_disk_for_savegame_kaos,2
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
	move.l	_bootup_seglist(pc),d3
	lea		_procname_v3(pc),a0
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
	
	
check_main_disk
	; check if main disk is inserted
	; at the same time, change savegame filename to put
	; our savename instead, from now on game uses that pointer
	; (done there because it's called at game start)
	bsr		set_proper_savegame_slot
	
	moveq.l	#0,d0	; main disk inserted
	move.w	d0,-16446(A5)
	rts
	
set_savegame_slot_from_resume_v3
	; original code
	JSR	154(A5)			;5cb12: 4ead009a
	SUBQ.W	#1,D0			;5cb16: 5340
	bsr		set_proper_savegame_slot
	tst.w	d0
	rts
	
	
check_main_disk_for_savegame_kaos
	moveq	#1,d0		; save disk inserted
	move.w	d0,-16446(A5)
	MOVE.W	D0,-2(A6)		;3c48a: 3d40fffe
	rts
	
check_disk_in_drive
	bsr		set_proper_savegame_slot
	moveq	#1,d0
	rts

; variables
	
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

_savename_offset
	dc.w	0
_bw_patch_offset
	dc.w	0
_saveregs
	ds.l	16,0
_stacksize
	dc.l	0
_version
	dc.l	0
_bootup_seglist
	dc.l	0
_current_task
	dc.l	0
_dosbase
	dc.l	0
_intname
	dc.b	"intuition.library",0
_gfxname
	dc.b	"graphics.library",0
_savegame_name
	dc.b	"save/DMGAME_"
_savegame_char
	dc.b	"0.DAT",0
	