;*---------------------------------------------------------------------------
;  :Program.	TFXHD.asm
;  :Contents.	Slave for "TFX"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: TFXHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"TFX.slave"
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
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $600000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $600000
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
STACKSIZE = 20000
BOOTDOS
CACHE
SEGTRACKER

slv_Version	= 18
; if WHDLF_ClearMem is set the TFX.FPU version crashes when starting the game
; this is probably a programming error with this version, made up by non-zero memory
; (sometimes it's the other way round): check the compiler warnings a*holes...

; EmulLineF should be necessary with FPU emulation but it's even better
; to set private7 and be able to write in whdload vbr
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_Req68020|WHDLF_ReqAGA
slv_keyexit	= $67	; right amiga (as num pad is used)

	include	whdload/kick31.s
IGNORE_JOY_DIRECTIONS    
    include ReadJoyPad.s
    
;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.0"
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

assign
	dc.b	"did",0
slv_config
	dc.b	"C3:L:executable:auto,TFX (plain 68020),TFX.FPU (68020+FPU),TFX.020 (68020+FPU 1997),TFX.040 (68020+FPU beta);"
	dc.b	"C4:X:run configuration program first:0;"
	dc.b	"C4:X:skip intro:1;"
	dc.b	"C5:B:no FPU direct fixes;"
	dc.b	0	
	EVEN
slv_name		dc.b	"TFX"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1995-1997 Digital Image Design",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

    even
program_table:
    dc.w    program-program_table
    dc.w    program_fpu-program_table
    dc.w    program_new_fpu-program_table
    dc.w    program_040-program_table   ; that one isn't really a 68040 version
    
config:
    dc.b    "config",0
; 68020, no fpu, version on CD
program:
    dc.b    "TFX",0
; this is not the version on CD, and wrongly called "TFX.040"
; (renamed from TFX.???) Basically this is a 68020 FPU development version
; with symbols left in (thanks to the programmer who leaked it, helped a lot!)
program_040:
	dc.b	"TFX.040",0
; 68020 with FPU, version is on CD
program_fpu:
	dc.b	"TFX.FPU",0
; 68020 with FPU, newer
program_new_fpu:
	dc.b	"TFX.020",0

args		dc.b	10
args_end
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN

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
    
_bootdos
		clr.l	$0.W

        bsr _detect_controller_types
    ; install vbl hook which counts vblank
    ; and also reads controllers
        lea old_level3_interrupt(pc),a0
        move.l  $6C.W,(a0)
        lea new_level3_interrupt(pc),a0
        move.l  a0,$6C.W
       
        
	; saves registers (needed for BCPL stuff, global vector, ...)

		lea	(_saveregs,pc),a0
		movem.l	d1-d7/a1-a2/a4-a6,(a0)
		lea	_stacksize(pc),a2
		move.l	4(a7),(a2)

		move.l	_resload(pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)
	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

        move.l  executable(pc),d1
        bne   .noauto
    ;automatic mode
        move.l  attnflags(pc),d0
        btst    #AFB_68040,d0
        beq   .test_fpu
        ; is this a 68060?
        btst    #AFB_68060,d0
        beq.b   .plain_040
        movem.l a6,-(a7)
        move.l  $4,a6
        lea get_060_id(pc),a5
        jsr (_LVOSupervisor,a6)
        movem.l (a7)+,a6

;68060 has ID register that shows the type of CPU (PCR) which also includes FPU-disabled bit.
;PCR=0430xxxx = 68060
;PCR=0431xxxx = 68EC060 or 68LC060
        swap    d0        
        cmp.w   #$431,d0
        beq.b   .nofpu      ; 680EC060 or 68LC060
        bra.b   .assume_fpu
.plain_040
        ; 68040. Check if we have FPU available
      ; check for 040 FPU, fails on 68060 atm there's no
      ; way to make 060 run a FPU version anyway
        btst    #AFB_FPU40,d0
        beq.b   .nofpu
        ; 68040/060 with FPU, we can automatically select one of the FPU
        ; executables, the best being the newest one from 1997 hosted on
        ; hall of light (https://is.gd/A6yk2T)
        move.l  #3,d1   ; set 68020+FPU executable, 1997
        bra.b   .noauto
.test_fpu
        move.l  attnflags(pc),d0
        btst    #AFB_68881,d0
        beq.b   .nofpu
.assume_fpu
        ; set 68020+FPU latest executable
        ; this is the optimal case because the latest executable...
        ; contains the latest fixes, and also uses FPU
        move.l  #3,d1
        bra.b   .noauto
.nofpu
        moveq.l #1,d1   ; 68020 or higher but no fpu
.noauto
        subq.l  #1,d1
        cmp.l   #4,d1
        bcs.b   .inrange

        pea	wrongcustom(pc)
        pea	(TDREASON_FAILMSG).w
        move.l	_resload(pc),a0
        jmp	resload_Abort(a0)
.inrange
        add.w   d1,d1
        lea program_table(pc),a0
        move.w  (a0,d1.w),a1
        add.l   a1,a0       ; program name
        lea program_to_run(pc),a1
        move.l  a0,(a1)
        
        ; for 68040/68060 only, FPU assumed (we have checked it in the "auto"
        ; executable selection, but the user can force it, note that it will probably
        ; fail but just in case of a strange Vampire-like board that isn't properly detected...
        ; now we have to enable FPU on 68060, whdload turns it off
        ; by default (thanks Bert for reminding it to me BEFORE I waste
        ; a lot of time on that issue)        

        move.l  attnflags(pc),d0
        btst    #AFB_68060,d0
        beq.b   .no060

        lea program(pc),a0
        ; 68060, if the user asked for the nofpu version, let them have it
        cmp.l  program_to_run(pc),a0
        beq.b   .no060

        ; FPU executable, on 060
        ; install 68881/68882 emulation program
        
        bsr install_fp_exe_060

        
		move.l	#WCPUF_FPU,d0
		move.l	#WCPUF_FPU,d1
        move.l  _resload(pc),a2
		jsr	(resload_SetCPU,a2)
        bra.b   .no040fpu       ; no need to test for 68040 FPU
.no060
    ; check for 040 FPU (not 060 FPU!)
        move.l  attnflags(pc),d0
        btst    #AFB_FPU40,d0
        beq.b   .no040fpu
        lea program(pc),a0
        ; if the user asked for the nofpu version, let them have it
        cmp.l  program_to_run(pc),a0
        beq.b   .no040fpu
        ; FPU executable, on 040/060 equipped with FPU
        ; install 68881/68882 emulation program
        bsr install_fp_exe_040
.no040fpu
        
        move.l  sequence_control(pc),d0
        btst    #0,d0
        beq.b   .skipconf
    
        lea config(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		sub.l   a5,a5
		bsr	load_exe    
.skipconf    
        ; disable mouse
        ; at the same time enable bitplane DMA
        ; this isn't done on 040 version for some reason
        ; which explains black screen at start
        ;
        ; code copied from a non 040 version
        MOVE.W	#$83c0,$dff096
        CLR.W	$dff140
        MOVE.W	#$0020,$dff096

    IFD CHIP_ONLY
        movem.l a6,-(a7)
		move.l	$4.w,a6
        move.l  #MEMF_PUBLIC,d1
        move.l  #$6D00,d0
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
    ENDC


        move.l  program_to_run(pc),a0
        jsr (resload_GetFileSize,a2)
        cmp.l   #571008,d0
        bne.b   _nomempatch

        movem.l a6,-(a7)
		move.l	$4.w,a6
        PATCH_XXXLIB_OFFSET AllocMem
        movem.l (a7)+,a6
        lea mem_patched(pc),a0
        st.b    (a0)
_nomempatch
        
        move.l program_to_run(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

get_060_id:
    mc68060
    movec  pcr,d0
    mc68020
    rte
    
get_version
        move.l  program_to_run(pc),a0
        jsr (resload_GetFileSize,a2)
        
        sub.l   a1,a1   ; default: no fpu patchlist
        
        cmp.l   #554340,d0
        beq.b   .v020
        cmp.l   #599152,d0
        beq.b   .v040
        ; versions processed with "hunk wizard" are
        ; completely fucked up!!!
;        cmp.l   #709968,d0
;        beq.b   .v040_orig
        cmp.l   #503340,d0
        beq.b   .vfpu
        ; FPU "new" (1997) was (almost) spared by
        ; this junk wizard shit
        cmp.l   #571008,d0
        beq.b   .vfpu_new
        
        pea	TDREASON_WRONGVER
        move.l	_resload(pc),-(a7)
        addq.l	#resload_Abort,(a7)
        rts    
.v020
        lea pl_020(pc),a0
        move.w  #12958,d0
        move.l  #$410f0,d1
        rts
.vfpu
        lea pl_fpu(pc),a0
        move.w  #12838,d0
        move.l  #$396d4,d1
        rts
.v040
        lea pl_040(pc),a0
        move.w  #13574,d0
        move.l  #$3f70c,d1
        rts
    
.v040_orig
        lea pl_040_orig(pc),a0
        move.w  #13574,d0
        move.l  #$3f70c,d1
        rts
.vfpu_new
    ; this version needs patching (data/bss hunks)

        lea pl_fpu_new(pc),a0
        lea pl_fpu_new_040(pc),a1
        move.w  #13574,d0
        move.l  #$40c44,d1
        rts

    

new_AllocMem
    cmp.l   #$270FC,d0
    beq.b   .chip
    cmp.l   #$000182C8,d0
    bne.b   .no_dataseg
.chip
    or.w    #MEMF_CHIP,d1   ; wrong hunk, fix it
.no_dataseg
    move.l  old_AllocMem(pc),-(a7)
    rts
    
; < d7: seglist (APTR)


patch_main
        bsr get_version
        lea fpu_patchlist(pc),a2
        move.l  a1,(a2)     ; store for later use
        
        ; proper offset to be able to reuse the same patch
        ; code for text/image skip
        lea offset(pc),a2        
        move.w  d0,(a2)

        move.l  d7,a1
        add.l   a1,a1
        add.l   a1,a1
        addq.l  #4,a1   ; first seg
        IFD CHIP_ONLY
        move.l  a1,$FC.W
        ENDC
        
        add.l   d1,a1   ; get keyboard handler end address
        lea int2_hook_address(pc),a2
        move.l  a1,(a2)


        move.l  d7,a1
        move.l  _resload(pc),a2        
        jsr	resload_PatchSeg(a2)
        
        move.l  fpu_patchlist(pc),d0
        beq.b   .no_fpu_patches
        move.l  d0,a0
        move.l  d7,a1
        jsr	resload_PatchSeg(a2)
        
.no_fpu_patches
        rts

pl_020
        PL_START
        ; skip images/text from intro
        PL_IFC4X    1
        ; we have to skip images/text until we reach 16 displays (amounts
        ; to the number of text/images screen shown during the intro
        ; because this routine is also used to display images in menu
        PL_PSS  $44510,pre_display_text_or_image,2
        PL_PSS  $44520,pre_display_text_or_image,2
        ;PL_NOP  $44518,4   ; this works but skips also stuff from main menu!
        ;PL_NOP  $44528,4
        PL_ENDIF
        
        PL_PS   $4CC02,fix_smc
        ;PL_P    $4111c,end_level2_int
        
        ; read joy1
        PL_PSS  $41504,test_fire,2

        
        PL_END
    
pl_040
        PL_START
        ; force FPU as we already checked that with whdload
        ; and kickstart isn't configured properly for that
        ; (game uses the OS to check that, big mistake :))
        PL_B    $4ea14,$60

        ; skip images & text from intro
        PL_IFC4X    1
        PL_PSS  $43a58,pre_display_text_or_image,2
        PL_PSS  $43a68,pre_display_text_or_image,2
        PL_ENDIF
        
        PL_PS   $4c38a,fix_smc
        
        ; faster blitwait
        PL_PS   $4ba4c,wait_blit
        PL_S    $4ba52,$4ba68-$4ba52
        PL_PS   $4bb08,wait_blit
        PL_S    $4bb0E,$4bb24-$4bb0E
        
        ; read joy1
        PL_PSS  $3fb1c,test_fire,2
        PL_END

pl_040_orig     ; this crap doesn't work
        PL_START
        ; force FPU as we already checked that with whdload
        ; and kickstart isn't configured properly for that
        ;;PL_B    $4ea14,$60

        ; skip images & text from intro
;        PL_IFC5
;        PL_PSS  $43a58,pre_display_text_or_image,2
;        PL_PSS  $43a68,pre_display_text_or_image,2
;        PL_ENDIF
        
 ;       PL_PS   $6464e,fix_smc
        
        ; faster blitwait
;        PL_PS   $4ba4c,wait_blit
;        PL_S    $4ba52,$4ba68-$4ba52
;        PL_PS   $4bb08,wait_blit
;        PL_S    $4bb0E,$4bb24-$4bb0E
        
        ; read joy1
;        PL_PSS  $3fb1c,test_fire,2
        PL_END

JSR_FINTRZ_X_FP0_FP1 = $100
JSR_FINTRZ_X_FP1_FP0 = $106
JSR_FINTRZ_X_FP1_FP2 = $10c
JSR_FINTRZ_X_FP2_FP1 = $112
JSR_FMOVECR_X_0x0f_0_000000e_00_FP0 = $118
JSR_FMOVECR_X_0x0f_0_000000e_00_FP6 = $11e
JSR_FMOVECR_X_0x32_1_000000e_00_FP0 = $124
JSR_FMOVECR_X_0x32_1_000000e_00_FP1 = $12a
JSR_FMOVECR_X_0x32_1_000000e_00_FP2 = $130
JSR_FMOVECR_X_0x32_1_000000e_00_FP5 = $136
JSR_FMOVECR_X_0x0f_0_000000e_00_FP1 = $13C

; opcodes for fsub.x dx,dx (4 bytes, fit in FMOVECR code space)
ZERO_FP0 = $F2000028
ZERO_FP1 = $F20004A8
ZERO_FP2 = $F2000928
ZERO_FP3 = $F2000DA8
ZERO_FP4 = $F2001228
ZERO_FP5 = $F20016A8
ZERO_FP6 = $F2001B28
ZERO_FP7 = $F2001FA8

pl_fpu
        PL_START
        ; force FPU
        PL_B    $48f1c,$60
        ; skip images from intro
        PL_IFC4X    1
        PL_PSS  $3d8d8,pre_display_text_or_image,2
        PL_PSS  $3d8e8,pre_display_text_or_image,2
        PL_ENDIF
        
        PL_PS   $46272,fix_smc

        ; read joy1
        PL_PSS  $39ae4,test_fire,2

        PL_END


pl_fpu_new
        PL_START
        ; force FPU
        PL_B    $50eec,$60
        ; skip images from intro
        PL_IFC4X    1
        PL_PSS  $45368,pre_display_text_or_image,2
        PL_PSS  $45378,pre_display_text_or_image,2
        PL_ENDIF
        
        PL_PS   $4e7ae,fix_smc

        ; read joy1
        PL_PSS  $41054,test_fire,2
        PL_END
       
pl_fpu_new_040:
        PL_IFC5
        PL_ELSE
        ; fpu patches
        ; those are computed by running the game with CHIP_ONLY
        ; (to align memory segment) then running a script that does
        ;m $FC 1
        ;w 0 $3FC
        ;g
        ;d rA0 1
        ;g
        ;d rA0 1
        ;g 
        ; and so on...
        ; then capture the winuae debugger console output, save as "debug_trace.txt"
        ; and run the analyse_fpu_excepts.py to generate patchlist,
        ; zeropage patches and offsets. Manually it's just horrible and error prone
        ;
        ; trig operations aren't considered
        ; all operations that are not seen (because not played enough)
        ; are processed by FPU emulation. Slower, but will work
        
        PL_L	$4874,$4EB80000+JSR_FINTRZ_X_FP1_FP0
        PL_L	$4890,$4EB80000+JSR_FINTRZ_X_FP1_FP0
        PL_L	$48ac,$4EB80000+JSR_FINTRZ_X_FP1_FP0
        PL_L	$d386,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$d65a,$4EB80000+JSR_FINTRZ_X_FP1_FP0
        PL_L	$e928,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$ebc6,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$ec0e,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$ed7c,$4EB80000+JSR_FINTRZ_X_FP1_FP0
        PL_L	$10b4a,$4EB80000+JSR_FINTRZ_X_FP1_FP0
        PL_L	$15fd0,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$1600e,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$16072,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$160da,$4EB80000+JSR_FINTRZ_X_FP1_FP0
        PL_L	$1ab84,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP0
        PL_L	$1ab84,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP0
        PL_L	$1ee6c,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$29b76,$4EB80000+JSR_FINTRZ_X_FP1_FP0
        PL_L	$2afe2,$4EB80000+JSR_FINTRZ_X_FP1_FP2
        PL_L	$2b042,$4EB80000+JSR_FINTRZ_X_FP1_FP2
        PL_L	$2b0a0,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$2d376,$4EB80000+JSR_FINTRZ_X_FP1_FP2
        PL_L	$2d388,$4EB80000+JSR_FINTRZ_X_FP1_FP2
        PL_L	$2d394,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$2d84c,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP0
        PL_L	$2de7e,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP0
        PL_L	$2e202,$4EB80000+JSR_FINTRZ_X_FP1_FP0
        PL_L	$2e36a,$4EB80000+JSR_FINTRZ_X_FP2_FP1
        PL_L	$2e6c6,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP2
        PL_L	$2e79c,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$2e7c0,$4EB80000+JSR_FINTRZ_X_FP2_FP1
        PL_L	$30c54,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$30c72,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$30c90,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$316d8,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP0
        PL_L	$318d8,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP0
        PL_L	$3228a,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP1   
        PL_L	$310b0,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP0
        PL_L	$31bd8,$4EB80000+JSR_FMOVECR_X_0x32_1_000000e_00_FP5
        PL_L	$1d54c,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$1d55e,$4EB80000+JSR_FINTRZ_X_FP0_FP1
        PL_L	$1d570,$4EB80000+JSR_FINTRZ_X_FP0_FP1
;        PL_L	$2f30e,ZERO_FP0
;        PL_L	$2f336,ZERO_FP0
;        PL_L	$2f3d6,ZERO_FP0
;        PL_L	$34b8a,ZERO_FP0
;        PL_L	$5182a,ZERO_FP1
;        PL_L	$34d5a,ZERO_FP0
;        PL_L	$35438,ZERO_FP1
;        PL_L	$5106e,ZERO_FP0
;        PL_L	$5181e,ZERO_FP0
;        PL_L	$2b08e,ZERO_FP6

    ; old patches needed a jsr then a jump, when a sub with itself is enough
        PL_L	$2f30e,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP0
        PL_L	$2f336,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP0
        PL_L	$2f3d6,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP0
        PL_L	$34b8a,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP0
        PL_L	$5182a,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP1
        PL_L	$34d5a,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP0
        PL_L	$35438,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP1
        PL_L	$5106e,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP0
        PL_L	$5181e,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP0
        PL_L	$2b08e,$4EB80000+JSR_FMOVECR_X_0x0f_0_000000e_00_FP6

        PL_ENDIF
        PL_END

install_zero_page_patches:
    movem.l a1,-(a7)
    lea needs_fpu_patches(pc),a1
    st.b    (a1)
    movem.l (a7)+,a1
    
	patch	JSR_FINTRZ_X_FP0_FP1,FINTRZ_X_FP0_FP1
	patch	JSR_FINTRZ_X_FP1_FP0,FINTRZ_X_FP1_FP0
	patch	JSR_FINTRZ_X_FP1_FP2,FINTRZ_X_FP1_FP2
	patch	JSR_FINTRZ_X_FP2_FP1,FINTRZ_X_FP2_FP1
	patch	JSR_FMOVECR_X_0x32_1_000000e_00_FP0,FMOVECR_X_0x32_1_000000e_00_FP0
	patch	JSR_FMOVECR_X_0x32_1_000000e_00_FP1,FMOVECR_X_0x32_1_000000e_00_FP1
	patch	JSR_FMOVECR_X_0x32_1_000000e_00_FP2,FMOVECR_X_0x32_1_000000e_00_FP2
    patch   JSR_FMOVECR_X_0x32_1_000000e_00_FP5,FMOVECR_X_0x32_1_000000e_00_FP5
    
	patch	JSR_FMOVECR_X_0x0f_0_000000e_00_FP0,FMOVECR_X_0x0f_0_000000e_00_FP0
	patch	JSR_FMOVECR_X_0x0f_0_000000e_00_FP6,FMOVECR_X_0x0f_0_000000e_00_FP6
    patch   JSR_FMOVECR_X_0x0f_0_000000e_00_FP1,FMOVECR_X_0x0f_0_000000e_00_FP1
	rts
    
    
    IFEQ    1
FMOVECR_X_0x32_1_000000e_00_FP:MACRO
FMOVECR_X_0x32_1_000000e_00_FP\1:
     FMOVECR    #$32,FP\1
     rts
     ENDM
FMOVECR_X_0x0f_0_000000e_00_FP:MACRO
FMOVECR_X_0x0f_0_000000e_00_FP\1:
     FMOVECR    #$f,FP\1
     rts
     ENDM    
     ENDC
    ; direct FPU emulated calls, without run-time decoding
    ; or trap overhead, a drag for small calls like those

FMOVECR_X_0x32_1_000000e_00_FP:MACRO
FMOVECR_X_0x32_1_000000e_00_FP\1:
     ;; fmove.x #1,fp\1 works only on 68040 not 060
     ;; (unimplemented effective address)
     ;; fmove.s is okay in that case
     fmove.s		#1,fp\1
     ;move.l a0,-(a7)
     ;lea    one_80bits(pc),a0
     ;fmovem.x  (a0),fp\1
     ;move.l (a7)+,a0
     rts
     ENDM

FMOVECR_X_0x0f_0_000000e_00_FP:MACRO
FMOVECR_X_0x0f_0_000000e_00_FP\1:
     fmove.s		#0,fp\1
     rts
     ENDM

FINTRZ_X_FPx_FPy:MACRO
FINTRZ_X_FP\1_FP\2:
    move.l  d0,-(a7)
    fmove   fpcr,-(a7)
    fmove   #$10,fpcr   ; rounding toward zero
    fmove.l fp\1,d0
    fmove.l d0,fp\2
    fmove   (a7)+,fpcr
    move.l  (a7)+,d0
    rts
    ENDM
     mc68040
     FMOVECR_X_0x32_1_000000e_00_FP 0
     FMOVECR_X_0x32_1_000000e_00_FP 1
     FMOVECR_X_0x32_1_000000e_00_FP 2
     FMOVECR_X_0x32_1_000000e_00_FP 5
     
     FMOVECR_X_0x0f_0_000000e_00_FP 0
     FMOVECR_X_0x0f_0_000000e_00_FP 1
     FMOVECR_X_0x0f_0_000000e_00_FP 5
     FMOVECR_X_0x0f_0_000000e_00_FP 6

    FINTRZ_X_FPx_FPy 0,1
    FINTRZ_X_FPx_FPy 1,0
    FINTRZ_X_FPx_FPy 1,2
    FINTRZ_X_FPx_FPy 2,1
    
;one_80bits:
;    dc.l    $3fff0000,$80000000,$00000000

    mc68020



; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

install_fp_exe_040:
    lea fpsp_name_040(pc),a0
    bra install_fp_exe
install_fp_exe_060:
    lea fpsp_name_060(pc),a0
install_fp_exe:
    ; direct patches to avoid using emulation
    bsr install_zero_page_patches
	movem.l	d0-a6,-(a7)
	move.l	a0,d1
    move.l  a0,a3
	jsr	(_LVOLoadSeg,a6)
	move.l	d0,d7			;D7 = segment
	beq	.end			;file not found
    add.l   d7,d7
    add.l   d7,d7
    move.l  d7,a3
	move.l	_stacksize(pc),-(a7)	; original stack format
	movem.l	(_saveregs,pc),d1-d7/a1-a2/a4-a6	; original registers (BCPL stuff)
    move.l  4,A6
    lea .do_super(pc),a5
    jsr _LVOSupervisor(A6)
	addq.l	#4,a7
    ; do NOT UnloadSeg as the program needs to remain loaded

    IFEQ    1
    mc68040
    fmove.x   #24.56,fp0
    bsr FINTRZ_X_FP0_FP1
    dc.l    $F2000083
    fmove.x   #-24.56,fp0
    bsr FINTRZ_X_FP0_FP1
    dc.l    $F2000083
    ENDC

    IFD CHIP_ONLY
    ; redirect to our version (only for debug)
    lea fpvec(pc),a0
    movec   vbr,a1
    move.l  ($2C,a1),(a0)
    lea customvec(pc),a0
    move.l  a0,($2C,a1)
    ENDC
    
	movem.l	(a7)+,d0-a6

	rts
    
.do_super:
    jsr (4,a3)
    rte
    
.end    
	jsr	(_LVOIoErr,a6)
    move.l  a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
 
    IFD CHIP_ONLY
fpvec
    dc.l    0
customvec
    movem.l  d0/a0,-(a7)
    move.l  10(a7),a0
    move.l  -(a0),d0
    clr.b   d0
    cmp.l   #$f2001c00,d0    ; fcos/fsin/fatan ... FP7,FP0
    beq.b   .ok
    move.l  (a0),d0
    cmp.l   #$f200068a,d0    ;                 FATAN.X FP1,FP5
    beq.b   .ok

    move.w  #$F00,$3FC    
.ok
    movem.l (a7)+,D0/a0
    ; jump to fpvec
    move.l  fpvec(pc),-(a7)
    rts
    ENDC

test_fire:
     movem.l    d0,-(a7)
     move.l buttons_state(pc),d0
     not.l  d0
     btst   #JPB_BTN_RED,d0
     movem.l    (a7)+,d0
     rts
wait_blit
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
    
pre_display_text_or_image
    lea counter(pc),a0
    cmp.l   #$10,(a0)
    bcs.b   .skip
.out
    move.w  d0,-(a7)
    move.w  offset(pc),d0
	MOVEA.L	(A4,d0.W),A0		;44510: 206c329e
    move.w  (a7)+,d0
	MOVEA.L	(10,A0),A0		;44514: 2068000a
    rts
.skip
    addq.l  #1,(a0)
    add.l   #6,(a7)
    bra.b   .out
    
counter
    dc.l    0

end_level2_int
    moveq.l #0,d0   ; set Z
	MOVEM.L	(A7)+,D0-D7/A0-A6	;: 4cdf7fff
	RTS				;40c70: 4e75
   
; a LOT of SMC alternating between OR.W D3,... and AND.W D4,...
; SHAME for a game using 68020+ instructions so not designed for 68000
; 	ex: BFCLR	D7{8:D2}		;4cce0: ecc70222
;
;        MOVE.B  #$c9,LAB_2088           ;4cb1c: 13fc00c90004ce06
;        MOVE.B  #$87,LAB_2088           ;4cb28: 13fc00870004ce06
;        MOVE.B  #$c9,LAB_2089           ;4cb3a: 13fc00c90004ce08
;        MOVE.B  #$87,LAB_2089           ;4cb46: 13fc00870004ce08
;        MOVE.B  #$c9,LAB_208A           ;4cb58: 13fc00c90004ce0c
;        MOVE.B  #$87,LAB_208A           ;4cb64: 13fc00870004ce0c
;        MOVE.B  #$c9,LAB_208B           ;4cb76: 13fc00c90004ce10
;        MOVE.B  #$87,LAB_208B           ;4cb82: 13fc00870004ce10
;        MOVE.B  #$c9,LAB_208C           ;4cb94: 13fc00c90004ce14
;        MOVE.B  #$87,LAB_208C           ;4cba0: 13fc00870004ce14
;        MOVE.B  #$c9,LAB_208D           ;4cbb2: 13fc00c90004ce16
;        MOVE.B  #$87,LAB_208D           ;4cbbe: 13fc00870004ce16
;        MOVE.B  #$c9,LAB_208E           ;4cbd0: 13fc00c90004ce1a
;        MOVE.B  #$87,LAB_208E           ;4cbdc: 13fc00870004ce1a
;        MOVE.B  #$c9,LAB_208F           ;4cbee: 13fc00c90004ce1e
;        MOVE.B  #$87,LAB_208F           ;4cbfa: 13fc00870004ce1e
; targets:
;LAB_2088:
;	OR.W	D3,(A3)			;4ce06: 8753
;LAB_2089:
;	OR.W	D3,(8000,A3)		;4ce08: 876b1f40
;LAB_208A:
;	OR.W	D3,(16000,A3)		;4ce0c: 876b3e80
;LAB_208B:
;	OR.W	D3,(24000,A3)		;4ce10: 876b5dc0
;LAB_208C:
;	OR.W	D3,(A4)			;4ce14: 8754
;LAB_208D:
;	OR.W	D3,(8000,A4)		;4ce16: 876c1f40
;LAB_208E:
;	OR.W	D3,(16000,A4)		;4ce1a: 876c3e80
;LAB_208F:
;	OR.W	D3,(24000,A4)		;4ce1e: 876c5dc0


; so the easy solution is to flush the cache when it's done
; this seems to fix the otherwise trashed fonts / wrong color ...
; but it's done constantly during game and maybe hinders speed
fix_smc	
	MOVEA.L	(20,A6),A0		;4cc04: 206e0014
    bra _flushcache
    
TEST_BUTTON:MACRO
    btst    #JPB_BTN_\1,d2
    beq.b   .nochange_\1
    move.b  #\2,d3
    btst    #JPB_BTN_\1,d0
    bne.b   .pressed_\1
    bset    #7,d3   ; released
.pressed_\1
    pea .nochange_\1(pc)
    MOVEM.L	D0-D7/A0-A6,-(a7)   ; save regs
    move.b  d3,d0
    ; jsr to hook to set key properly
    move.l  a1,-(a7)            
    rts
.nochange_\1
    ENDM
   
new_level3_interrupt
    movem.l d0-d3/a0-a1,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq   .novbl
    ; vblank interrupt, read joystick/mouse
    lea buttons_state(pc),a0
    move.l  (a0),d1     ; get previous state
	moveq	#1,d0
	bsr	_read_joystick
    move.l  d0,(a0)     ; save previous state for next time
    ; now D0 is current joypad state
    ;     D1 is previous joypad state
    ; xor to d2 to get what has changed quickly
    move.l  d0,d2
    eor.l   d1,d2
    beq   .novbl
    btst    #JPB_BTN_REVERSE,d0
    beq.b   .noquit
    btst    #JPB_BTN_FORWARD,d0
    beq.b   .noquit
    btst    #JPB_BTN_YEL,d0
    bne     _quit
.noquit    
    move.l int2_hook_address(pc),a1
    ; d2 bears changed bits (buttons pressed/released)
    TEST_BUTTON FORWARD,$5E ; thrust +
    TEST_BUTTON REVERSE,$4A ; thrust -
    TEST_BUTTON BLU,$44     ; return switch weapons
    TEST_BUTTON YEL,$31     ; lock to target
    TEST_BUTTON RED,$40     ; fire
    TEST_BUTTON GRN,$5D     ; after burner increase
    TEST_BUTTON PLAY,$0     ; status screen / pause
.novbl
    movem.l (a7)+,d0-d3/a0-a1
    move.l  old_level3_interrupt(pc),-(a7)
    rts
        
old_level3_interrupt
    dc.l    0
buttons_state
    dc.l    0
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
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a3
	add.l	a3,a3
	add.l	a3,a3

	move.l	a4,a0

    ; restore old allocmem now that the hunks have been
    ; read in chipmem only for FPU new version (TFX.020)
	movem.l	d7/a6,-(a7)
    move.b  mem_patched(pc),d0
    beq.b   .norestore
    movem.l a6,-(a7)
    move.l	$4.w,a6
    move.l  old_AllocMem(pc),(_LVOAllocMem+2,A6)
    movem.l (a7)+,a6
.norestore

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

    
tag		dc.l	WHDLTAG_CUSTOM3_GET
executable	dc.l	0
    dc.l	WHDLTAG_CUSTOM4_GET
sequence_control	dc.l	0
        dc.l    WHDLTAG_ATTNFLAGS_GET
attnflags
        dc.l    0
        dc.l    WHDLTAG_Private7     
        dc.l    -1   ; allow to write in vbr directly
		dc.l	0
        
program_to_run
		dc.l	0
offset
    dc.w    0
int2_hook_address
    dc.l    0
fpu_patchlist
    dc.l    0
fpsp_name_040
    dc.b    "fpsp040",0
fpsp_name_060
    dc.b    "fpsp060",0
wrongcustom
    dc.b    "custom exe value out of range 0-4",0
mem_patched
    dc.b    0
needs_fpu_patches
    dc.b    0
    cnop    0,4
;============================================================================

