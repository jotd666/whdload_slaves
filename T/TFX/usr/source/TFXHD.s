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
        INCLUDE devices/timer.i

        IFND AFB_68060
AFB_68060=7
        ENDC
_LVOReadEClock=-60

FPS_COLOR=15

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
    include serial.s

;============================================================================


	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	dc.b	"1.x (EXPERIMENTAL) "
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
	dc.b	"C4:X:original rendering code:2;"
	dc.b	"C4:X:show frame rate:3;"
        dc.b    "C4:X:start action mode:4;"
        dc.b    "C4:X:uncapped frame rate:5;"
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

CHECK_NO_FAST_ALLOC macro
        btst.b #2,sequence_control+3(pc)
        endm

CHECK_SHOW_FPS macro
        btst.b #3,sequence_control+3(pc)
        endm


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
        CHECK_NO_FAST_ALLOC
        ; In "fast" mode, the plain 020 version is preferable. It has more features, and
        ; even on 060 TFX.040 (the other candidate) is only marginally faster.
        beq     .nofpu

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

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        CHECK_NO_FAST_ALLOC
        bne.b   .gotbuf

        ; Enable all caches (only CPU writes to chipmem)
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All&~WCPUF_FPU,d1
        move.l  _resload(pc),a2
	jsr	resload_SetCPU(a2)

        movem.l a6,-(a7)
	move.l	$4.w,a6
        move.l  #MEMF_PUBLIC!MEMF_CLEAR,d1
        move.l  #bplbytes*8+($72418-$71758)+16,d0 ; extra stuff is for sprites
        jsr _LVOAllocMem(a6)
        lea     fast_buf(pc),a6
        add.l   #15,d0
        and.b   #-16,d0
        move.l  d0,(a6)
        movem.l (a7)+,a6
        bne.b   .gotbuf

        pea	outofmemory(pc)
        pea	(TDREASON_FAILMSG).w
        move.l	_resload(pc),a0
        jmp	resload_Abort(a0)
.gotbuf:

        CHECK_SHOW_FPS
        beq     .nofps
        move.l  a6,-(sp)
        move.l  $4.w,a6
        lea     timer_name(pc),a0
        moveq   #UNIT_MICROHZ,d0
        lea     timerreq(pc),a1
        moveq   #0,d1
        jsr     _LVOOpenDevice(a6)
        move.l  (sp)+,a6
.nofps
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

timer_name:
        TIMERNAME
        even

get_version
        move.l  program_to_run(pc),a0
        jsr (resload_GetFileSize,a2)
        
        sub.l   a1,a1   ; default: no fpu patchlist
        sub.l   a2,a2   ; no 060 patches
        sub.l   a5,a5   ; no pointer list
        
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
        lea pl_020_060(pc),a2
        move.w  #12958,d0
        move.l  #$410f0,d1
        rts
.vfpu
        lea pl_fpu(pc),a0
        ;lea pl_fpu_060(pc),a2
        move.w  #12838,d0
        move.l  #$396d4,d1
        rts
.v040
        lea pl_040(pc),a0
        lea pl_040_060(pc),a2
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
        lea pl_fpu_new_060(pc),a2
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
        move.l  a2,-(sp) ; store 060 patch list
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

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


        movem.l d0-d3/a2-a3,-(sp)
        lea     sections(pc),a3
        move.l  a1,(a3)+
        move.l  -4(a1),a2
.sections:
        add.l   a2,a2
        add.l   a2,a2
        addq.l  #4,a2
        move.l  a2,(a3)+
        move.l  -4(a2),a2
        tst.l   a2
        bne.b   .sections

        movem.l (sp)+,d0-d3/a2-a3

        IFNE SER_OUTPUT
        move.w  #30,serper+$dff000
        ENDC

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

        move.l  (sp)+,d0
        beq.b   .no_060_patches
        btst.b  #AFB_68060,attnflags+3(pc)
        beq.b   .no_060_patches
        move.l  d0,a0
        move.l  d7,a1
        move.l  _resload(pc),a2
        jsr	resload_PatchSeg(a2)

.no_060_patches

        move.l  program_to_run(pc),a2
        lea     program(pc),a5
        cmp.l   a5,a2
        bne     .not020v
        ; Alright, one more stupid speedup
        ; We relocate _logbase to fast mem

        lea     logbase(pc),a3
        lea     _logbase_ptr(pc),a2
        move.l  a3,(a2)
        move.l  a3,d1

        lea     logbase_patchoffsets(pc),a2
        move.l  sections(pc),a3
.patch
        move.l  (a2)+,d0
        bmi.b   .not020v
        move.l  d1,(a3,d0.l)
        bra.b   .patch
.not020v
        rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

screenw=320
screenh=200
rowbytes=screenw/8
bplbytes=rowbytes*200

sections  ds.l 15 ; "040" version has 15 sections
fast_buf  ds.l 1
old_bufs  ds.l 2
logbase   ds.l 1
timerreq  ds.b IOTV_SIZE
last_time ds.l 2
last_fps  ds.l 1

_screen1_ptr ds.l 1
_vblank_clock_ptr ds.l 1
@Control_ptr ds.l 1
@HandleEjection_ptr ds.l 1
@RemoveDeadMissiles_ptr ds.l 1
@ThreeScreenSwap_ptr ds.l 1
_SetPage_ptr ds.l 1
_SetLogbase_ptr ds.l 1
_logbase_ptr ds.l 1
_current_page_ptr ds.l 1
PlotColour_ptr ds.l 1
_sprogtab_ptr ds.l 1
_PalNtsc_ptr ds.l 1

pl_040_060
        PL_START
        PL_P    $99e5c,_qmul
        PL_P    $67cea,xTranslate
        PL_PSS  $6a44e,_HorizonFadeProj_MulsL4256,2
        PL_PSS  $6a46e,_HorizonFadeProj_MulsL4253,2
        PL_PSS  $6a4a2,_HorizonFadeProj_MulsL4253,2
        PL_PSS  $6a47e,_HorizonFadeProj_DivsL,2
        PL_PSS  $6a4b2,_HorizonFadeProj_DivsL,2
        PL_END

pl_020_060
        PL_START
        PL_P    $6aea8,_qmul
        PL_P    $5a672,xTranslate
        PL_PSS  $619d2,_HorizonFadeProj_MulsL4256,2
        PL_PSS  $619f2,_HorizonFadeProj_MulsL4253,2
        PL_PSS  $61a26,_HorizonFadeProj_MulsL4253,2
        PL_PSS  $61a02,_HorizonFadeProj_DivsL,2
        PL_PSS  $61a36,_HorizonFadeProj_DivsL,2
        PL_END

logbase_patchoffsets:
        dc.l $0191c,$019f8,$0357e,$138a0,$13962,$17290,$172e4,$175ea
        dc.l $175f8,$31882,$3188c,$31894,$319c4,$319ce,$319d6,$32ea2
        dc.l $32ec4,$33088,$330b4,$33352,$33396,$33674,$336a8,$3383c
        dc.l $33854,$338b6,$338d8,$37604,$37624,$389ba,$389d8,$43914
        dc.l $4393a,$464ac,$464ba,$46d4a,$46d5a,$4aa7e,$4abd0,$4b000
        dc.l $4b012,$4b022,$4b038,$4b052,$4b088,$4b0de,$4b108,$4b1f6
        dc.l $4bcc6,$4bce2,$4bd16,$4bd1c,$4bddc,$4be0c,$4bf0e,$4c15c
        dc.l $4c402,$4c756,$4ca4e,$4cac8,$4cc5c,$4cd78,$4d2fe,$4d5c4
        dc.l $4d60a,$4d64a,$4d7d2,$4d84e,$4d906,$4dabe,$4dbcc,$4dcea
        dc.l $4df80,$6b0c8,$6b0f6,$6b940,$6ddec,-1

pl_fpu_new_060
        PL_START
        PL_P    $6a438,_qmul
        PL_P    $60002,xTranslate
        PL_PSS  $62766,_HorizonFadeProj_MulsL4256,2
        PL_PSS  $62786,_HorizonFadeProj_MulsL4253,2
        PL_PSS  $627ba,_HorizonFadeProj_MulsL4253,2
        PL_PSS  $62796,_HorizonFadeProj_DivsL,2
        PL_PSS  $627ca,_HorizonFadeProj_DivsL,2
        PL_END


CALLPTR macro
        jsr     ([\1_ptr,pc])
        endm
JMPPTR macro
        jmp     ([\1_ptr,pc])
        endm

one_digit macro
        divu    #10,d0
        swap    d0
        bsr     _drawdigit
        clr.w   d0
        swap    d0
        endm

start_frame:
	    ;BSR.W	LAB_0144		        ;01464: 610008c0 (@Control thunk)
	    ;BSR.W	@HandleEjection		    ;01468: 6100f1ea
        CALLPTR @Control
        CALLPTR @HandleEjection

        ; Swap chip mem buffers

        movem.l d0-d1/a0-a2,-(sp)
        move.w  ([_logbase_ptr,pc]),d0
        lea     ([_screen1_ptr,pc],d0.w),a0
        lea     old_bufs(pc),a1
        move.l  (a0),(a1)+
        move.l  fast_buf(pc),a2
        move.l  a2,(a0)
        add.l   #bplbytes*8,a2
        lea     ([_sprogtab_ptr,pc],d0.w),a0
        move.l  (a0),(a1)
        move.l  a2,(a0)
        movem.l (sp)+,d0-d1/a0-a2
        rts


do_swap_screen:
        movem.l d0-d7/a0-a6,-(sp)

        move.w  ([_logbase_ptr,pc]),d0
        lea     ([_screen1_ptr,pc],d0.w),a5
        lea     ([_sprogtab_ptr,pc],d0.w),a4

        CHECK_SHOW_FPS
        beq     .nofps

        sub.w   #TV_SIZE,sp
        move.l  timerreq+IO_DEVICE(pc),a6
        move.l  sp,a0
        jsr     _LVOReadEClock(a6)
        mulu.l  #10,d0          ; d0 = 10*EclockRate
        move.l  (sp),d2
        move.l  4(sp),d1        ; d2:d1 = current tim
        lea     last_time(pc),a0
        move.l  (a0),d4
        move.l  4(a0),d3        ; d4:d3 = last time
        move.l  d2,(a0)+
        move.l  d1,(a0)
        add.w   #TV_SIZE,sp

        sub.l   d3,d1
        subx.l  d4,d2
        tst.l   d2
        bne     .nofps   ; Don't update if it's been a long time

        divs.l  d1,d0

        ; apply simple low pass filter to fps
        lea     last_fps(pc),a2
        move.l  (a2),d1
        sub.l   d1,d0
        asr.l   #3,d0
        add.l   d1,d0
        move.l  d0,(a2)

        move.l  (a5),a2
        add.l   #rowbytes+4*bplbytes,a2
        one_digit
        move.l  d0,d5
        moveq   #10,d0
        bsr     _drawdigit
        move.l  d5,d0
        one_digit
        beq.b   .nofps ; Skip leading 0's
        one_digit
        beq.b   .nofps ; Skip leading 0's
        one_digit
.nofps:

        CHECK_NO_FAST_ALLOC
        bne     .nofast

        move.l  old_bufs(pc),a0
        move.l  fast_buf(pc),a1
        move.l  a0,(a5) ; Restore screen buffer
        move.w  #bplbytes*8/16-1,d0
.copy:
        move.l  (a1)+,(a0)+
        move.l  (a1)+,(a0)+
        move.l  (a1)+,(a0)+
        move.l  (a1)+,(a0)+
        dbf     d0,.copy

        ; a1 now points to spite buffer in fast mem

        move.l  4+old_bufs(pc),a0
        move.l  a0,(a4) ; Restore spritebuf

        ; a little tricky, copy sprite buffer back to chip mem, but avoid control words, etc.
        ; note: sprites only use 2 colors
        move.w  #100-1,d0
.copy2:
        move.l  (a1)+,(a0)+
        move.l  (a1)+,(a0)+
        addq.l  #8,a0
        addq.l  #8,a1
        dbf     d0,.copy2
        moveq   #32,d0
        add.l   d0,a0
        add.l   d0,a1
        move.w  #100-1,d0
.copy3:
        move.l  (a1)+,(a0)+
        move.l  (a1)+,(a0)+
        addq.l  #8,a0
        addq.l  #8,a1
        dbf     d0,.copy3

        ; Swap without sync
        move.l  _current_page_ptr(pc),a3
        moveq   #1,d0
        and.w   (a3),d0
        move.l  d0,-(sp)
        CALLPTR _SetPage
        move.w  (a3),d0
        eor.w   #1,d0
        move.w  d0,(a3)
        move.w  d0,2(sp)
        CALLPTR _SetLogbase
        addq.w  #4,sp
.nofast:
        movem.l (sp)+,d0-d7/a0-a6

        ; Original code
        CHECK_NO_FAST_ALLOC
        beq.b   .fast
        CALLPTR @ThreeScreenSwap
.fast:
        JMPPTR @RemoveDeadMissiles

_drawdigit:
        lea     (_char_data,pc,d0.w*8),a0
        subq.l  #1,a2
        move.l  a2,a1
        moveq   #8-1,d3
.l:
        move.b  (a0)+,d2
        move.b  d2,d4
        not.b   d4
        rept 8
        ifne (FPS_COLOR>>REPTN)&1
        or.b    d2,(REPTN-4)*bplbytes(a1)
        else
        and.b   d4,(REPTN-4)*bplbytes(a1)
        endc
        endr
        add.w   #rowbytes,a1
        dbf     d3,.l
        rts

_char_data:
        dc.b    %00111100, %01100110, %01101110, %01111110, %01110110, %01100110, %00111100, %00000000  ; 0
        dc.b    %00011000, %00111000, %01111000, %00011000, %00011000, %00011000, %00011000, %00000000  ; 1
        dc.b    %00111100, %01100110, %00000110, %00001100, %00011000, %00110000, %01111110, %00000000  ; 2
        dc.b    %00111100, %01100110, %00000110, %00011100, %00000110, %01100110, %00111100, %00000000  ; 3
        dc.b    %00011100, %00111100, %01101100, %11001100, %11111110, %00001100, %00001100, %00000000  ; 4
        dc.b    %01111110, %01100000, %01111100, %00000110, %00000110, %01100110, %00111100, %00000000  ; 5
        dc.b    %00011100, %00110000, %01100000, %01111100, %01100110, %01100110, %00111100, %00000000  ; 6
        dc.b    %01111110, %00000110, %00000110, %00001100, %00011000, %00011000, %00011000, %00000000  ; 7
        dc.b    %00111100, %01100110, %01100110, %00111100, %01100110, %01100110, %00111100, %00000000  ; 8
        dc.b    %00111100, %01100110, %01100110, %00111110, %00000110, %00001100, %00111000, %00000000  ; 9
        dc.b    %00000000, %00000000, %00000000, %00000000, %00000000, %00011000, %00011000, %00000000  ; .

click_state: dc.w 0
find_click_box:
        ; d7/a5 free
        lea     click_state(pc),a5
        move.w  (a5),d7
        cmp.w   #2,d7
        beq     .out

        addq.w  #1,(a5)
        moveq   #5,d0   ; Select arcade
        tst.w   d7
        beq     .ret
        moveq   #1,d0   ; Select start
.ret:
        addq.l  #4,a7 ; drop return adddress from stack
        ; and exit routine
	MOVEM.L	(A7)+,D2-D5/D7/A5	;45cd8: 4cdf20bc
	ADDA.W	#$001c,A7		;45cdc: defc001c

        ; Fake mouse button click
	bset.b  #0,(55+4,A7)

	RTS				;45ce0: 4e75
.out:
        ; original code
	CLR.B	(51+4,A7)			;45b94: 422f0033
	MOVE.L	D0,D7			;45b98: 2e00
	MOVEQ	#0,D5			;45b9a: 7a00
        rts

find_click_box_020:
        lea     click_state(pc),a0
        cmp.w   #2,(a0)
        beq     .out
        moveq   #5,d0   ; Select arcade
        tst.w   (a0)
        beq     .ret
        moveq   #1,d0   ; Select start
.ret:
        addq.w  #1,(a0)
        bset.b  #0,(63+4,a7) ; Mouse click
        rts
.out:
	;EXT.L	D1			;47d48: 48c1
	;BSR.W	LAB_2030		;47d4a: 6100f9ba
        ext.l   d1
        move.l  sections(pc),a0
        add.l   #$47706,a0
        jmp     (a0)

box:
        link.w  a6,#0
        movem.l d0-d7/a0-a3,-(sp)
        move.w  14(a6),d0       ; x0
        move.w  18(a6),d1       ; y0
        move.w  22(a6),d2       ; x1
        move.w  26(a6),d3       ; y1
        move.w  10(a6),d4       ; color

        ; _ClipBox
        cmp.w   #screenh,d1
        bcc.b   .out
        cmp.w   #screenh,d3
        bcs.b   .clipped
        move.w  #screenh-1,d3
.clipped:
        move.l  a6,a3   ; preserve a6
        bsr     draw_rect
        move.l  a3,a6
.out:
        movem.l (sp)+,d0-d7/a0-a3
        unlk    a6
        rts

; d0 = x0, d1 = y0, d2 = x1, d3 = y1, d4 = color
; Could be optimized further with dedicated functions (and using move.l for longer spans)
; But this will do for now.
; d0-d7/a0-a2/a6 trashed
draw_rect:
        cmp.w   d0,d2
        bls     .out
        sub.w   d1,d3
        move.w  d3,d5   ; d5 = yiter
        bmi     .out

        and.w   #$ff,d4
        lsl.w   #5,d4
        lea     ([PlotColour_ptr,pc],d4.w),a0 ; Plotting function

        ; Current screen buffer (can still be in chip mem in the menus)
        move.w  ([_logbase_ptr,pc]),d7
        move.l  ([_screen1_ptr,pc],d7.w),a1

        mulu.w  #rowbytes,d1
        add.l   d1,a1
        add.l   #3*bplbytes,a1 ; point to 3rd plane
        move.w  d2,d1

        moveq   #-32,d2
        move.w  d1,d3
        and.w   d2,d3
        and.w   d0,d2
        eor.w   d2,d0
        eor.w   d3,d1
        sub.w   d2,d3
        lsr.w   #5,d3   ; d3 = number of longs (non-inclusive)
        lsr.w   #3,d2
        add.w   d2,a1   ; starting long
        moveq   #-1,d4
        lsr.l   d0,d4   ; d4 = first long mask
        move.l  #$80000000,d0
        asr.l   d1,d0   ; d0 = last long mask

        moveq   #screenw/32,d7
        sub.w   d3,d7
        lsl.w   #2,d7   ; d7 = screen modulo

        subq.w  #1,d3
        bpl.b   .longer
        and.l   d4,d0
        move.l  d0,d2
        move.l  d0,d6
        not.l   d6
        lea     .yiter1(pc),a6
.yloop1:
        jmp     (a0)
.yiter1:
        add.w   d7,a1
        dbf     d5,.yloop1
.out:
        rts

.longer
        move.l  d3,a2   ; preseve d3
.yloop2:
        move.l  a2,d3   ; xiter count
        ; first long
        move.l  d4,d2
        move.l  d4,d6
        not.l   d6
        lea     .xiter(pc),a6
        jmp     (a0)
.xloop:
        ; this part could be replaced by move.l's
        moveq   #-1,d2
        moveq   #0,d6
        jmp     (a0)
.xiter:
        addq.w  #4,a1
        dbf     d3,.xloop
        ; final long
        move.l  d0,d2
        move.l  d0,d6
        not.l   d6
        lea     .yiter2(pc),a6
        jmp     (a0)
.yiter2:
        add.w   d7,a1
        dbf     d5,.yloop2
        rts

draw_line_normal:
        link.w  a6,#0
        movem.l d0-d7/a0-a3,-(sp)
        move.w  14(a6),d0       ; x0
        move.w  18(a6),d1       ; y0
        move.w  22(a6),d2       ; x1
        move.w  26(a6),d3       ; y1
        move.w  10(a6),d4       ; color
        moveq   #-1,d5          ; pattern
        bsr     draw_line
        movem.l (sp)+,d0-d7/a0-a3
        unlk    a6
        rts

draw_line_strip:
        link.w  a6,#0
        movem.l d0-d7/a0-a3,-(sp)
        move.w  14(a6),d0       ; x0
        move.w  18(a6),d1       ; y0
        move.w  22(a6),d2       ; x1
        move.w  26(a6),d3       ; y1
        move.w  10(a6),d4       ; color
        move.b  31(a6),d5       ; pattern
        move.b  d5,d6
        lsr.w   #8,d5
        move.b  d6,d5
        bsr     draw_line
        movem.l (sp)+,d0-d7/a0-a3
        unlk    a6
        rts

; d0 = x0, d1 = y0, d2 = x1, d3 = y1, d4 = color, d5 = pattern
; d0-d7/a0-a3 trashed
draw_line:
        cmp.w   #screenw,d0
        bcc     .out
        cmp.w   #screenw,d2
        bcc     .out
        cmp.w   #screenh,d1
        bcc     .out
        cmp.w   #screenh,d3
        bcs     .ok
.out:
        rts
.ok:
        ; Current screen buffer (can still be in chip mem in the menus)
        move.w  ([_logbase_ptr,pc]),d7
        move.l  ([_screen1_ptr,pc],d7.w),a0

        add.l   #3*bplbytes,a0 ; Third plane

        lsl.w   #5,d4
        lea     plot(pc,d4.w),a2
        move.w  d5,a3   ; preseve pattern

        move.w  d1,d4
        moveq   #rowbytes,d5
        mulu.w  d5,d4
        add.l   d4,a0

        moveq   #1,d4
        sub.w   d0,d2
        bcc.b   .xpos
        moveq   #-1,d4
        neg.w   d2
.xpos
        sub.w   d1,d3
        bcc.b   .ypos
        moveq   #-rowbytes,d5
        neg.w   d3
.ypos:
        move.w  a3,d1
        move.w  d5,a3

        ; d0=x, d1=pattern, d2 = abs(dx), d3=abs(dy), d4=sgn(dx), a3=sgn(dy)*rowbytes
        cmp.w   d3,d2
        bcc     .xdominant

        ; y dominant
        move.w  d3,d5
        move.w  d3,d6
        lsr.w   #1,d6   ; err = dyabs/2
.yloop:
        ror.w   #1,d1
        bcc.b   .noplot1
        move.w  d0,d7
        lsr.w   #3,d7
        lea     (a0,d7.w),a1
        move.w  d0,d7
        not.w   d7
        jsr     (a2)
.noplot1:
        add.w   d2,d6   ; err += dxabs
        cmp.w   d3,d6
        bcs.b   .noxstep
        sub.w   d3,d6
        add.w   d4,d0   ; x += sgn(dx)
.noxstep:
        add.w   a3,a0   ; y += sgn(dy)
        dbf     d5,.yloop
        rts

.xdominant:
        move.w  d2,d5
        move.w  d2,d6
        lsr.w   #1,d6 ; err = dxabs/2

.xloop:
        ror.w   #1,d1
        bcc.b   .noplot2
        move.w  d0,d7
        lsr.w   #3,d7
        lea     (a0,d7.w),a1
        move.w  d0,d7
        not.w   d7
        jsr     (a2)
.noplot2:
        add.w   d3,d6   ; err += dyabs
        cmp.w   d2,d6
        bcs.b   .noystep
        sub.w   d2,d6   ; err -= dxabs
        add.w   a3,a0   ; y += sgn(dy)
.noystep:
        add.w   d4,d0   ; x += sgn(dx)
        dbf     d5,.xloop

        rts

make_plot_func macro
        rept 8
        ifne ((\1>>REPTN)&1)
        ifeq (REPTN-3)
        bset.b  d7,(a1)
        else
        bset.b  d7,(REPTN-3)*bplbytes(a1)
        endc
        else
        ifeq (REPTN-3)
        bclr.b  d7,(a1)
        else
        bclr.b  d7,(REPTN-3)*bplbytes(a1)
        endc
        endc
        endr
        rts
        endm

plot:
.color set 0
        rept 256
        make_plot_func .color
.color set .color+1
        endr
.end_plot
        ifne (.end_plot-plot)-(256*32)
        error Invalid function size
        endc

draw_mono_image_setup:
        MOVEA.L	(20,A6),A0		;4c38c: 206e0014
        MOVE.W	(14,A6),D0		;4c390: 302e000e
        MOVE.W	(18,A6),D1		;4c394: 322e0012

        ; Grab  color (d2 is free)
        moveq   #0,d2
        move.b	(11,a6),d2
        mulu.w  #(apply_mask_end-apply_mask)/256,d2
        lea     apply_mask(pc,d2.l),a6

        add.l   #$4c398-$4c29e,(sp) ; fix return address
        rts

; d3 = ormask, d4 = andmask, a3/a4 bitbplanes
make_apply_mask macro
        rept 4
        ifne ((\1>>REPTN)&1)
        or.w    d3,REPTN*bplbytes(a3)
        else
        and.w   d4,REPTN*bplbytes(a3)
        endc
        endr
        rept 4
        ifne ((\1>>(4+REPTN))&1)
        or.w    d3,REPTN*bplbytes(a4)
        else
        and.w   d4,REPTN*bplbytes(a4)
        endc
        endr
        add.l   #$4c5aa-$4c590,(sp) ; fix return address
        rts
        endm

apply_mask:
.color set 0
        rept 256
        make_apply_mask .color
.color set .color+1
        endr
apply_mask_end:

_qmul:
        movem.l d2-d7,-(sp)
        bsr     smul64
        move.l  d0,(a0)+
        move.l  d1,(a0)
        movem.l (sp)+,d2-d7
        rts

; Dumb helper macro that uses memory to avoid register complications
; Assumes a1/a2 points to temp storage
MULS_L macro
        move.l  \1,(a1)
        move.l  \3,(a2)
        movem.l d0-d7,-(sp)
        move.l  (a1),d0
        move.l  (a2),d1
        bsr     smul64
        move.l  d0,(a1)
        move.l  d1,(a2)
        movem.l (sp)+,d0-d7
        move.l  (a1),\2
        move.l  (a2),\3
        endm

MULS_SETUP macro
        movem.l a1-a2,-(sp)
        lea     smulstore(pc),a1
        lea     4(a1),a2
        endm

MULS_CLEANUP macro
        movem.l (sp)+,a1-a2
        endm

smulstore: ds.l 2
xTranslate:
        MULS_SETUP
; Replace the following code. Could probably be optimized, but being
; too clever about which registers need to hold what values is risky...
;	MULS.L	D0,D3:D4		;5a672: 4c004c03
	MULS_L	D0,D3,D4
;	MULS.L	D1,D4:D5		;5a676: 4c015c04
 	MULS_L	D1,D4,D5
;	MULS.L	D2,D5:D6		;5a67a: 4c026c05
        MULS_L  D2,D5,D6
	ADD.L	D4,D3			;5a67e: d684
	ADD.L	D5,D3			;5a680: d685
	MOVEM.L	(A0)+,D4-D5/D7		;5a682: 4cd800b0
;	MULS.L	D0,D6:D4		;5a686: 4c004c06
	MULS_L	D0,D6,D4
;	MULS.L	D1,D4:D5		;5a68a: 4c015c04
	MULS_L	D1,D4,D5
;	MULS.L	D2,D5:D7		;5a68e: 4c027c05
	MULS_L	D2,D5,D7
	ADD.L	D4,D6			;5a692: dc84
	ADD.L	D5,D6			;5a694: dc85
;	MULS.L	(A0)+,D7:D0		;5a696: 4c180c07
	MULS_L	(A0)+,D7,D0
;	MULS.L	(A0)+,D4:D1		;5a69a: 4c181c04
	MULS_L	(A0)+,D4,D1
;	MULS.L	(A0)+,D5:D2		;5a69e: 4c182c05
	MULS_L	(A0)+,D5,D2
	ADD.L	D4,D7			;5a6a2: de84
	ADD.L	D5,D7			;5a6a4: de85
;	RTS				;5a6a6: 4e75
        MULS_CLEANUP
        rts


; More MULS.L's. There's even DIVS.L below that could be included.
; Probably could be simplified, but this will have to do for now...

_HorizonFadeProj_MulsL4256:
        MULS_SETUP
;	MULS.L	D0,D4:D2		;619d2: 4c002c04
;	MULS.L	D1,D5:D6		;619d6: 4c016c05
	MULS_L	D0,D4,D2
	MULS_L	D1,D5,D6
        MULS_CLEANUP
        rts
_HorizonFadeProj_MulsL4253:
        MULS_SETUP
;	MULS.L	D0,D4:D2		;619f2: 4c002c04
;	MULS.L	D1,D5:D3		;619f6: 4c013c05
	MULS_L	D0,D4,D2
	MULS_L	D1,D5,D3
        MULS_CLEANUP
        rts

; muls.l d0,d0:d1
; trashes d2-d7
; Adapted from https://web.archive.org/web/20190109005441/http://www.hackersdelight.org/hdcodetxt/muldws.c.txt
smul64:
        move.l  #$ffff,d7
        moveq   #16,d6
        move.l  d1,d2
        asr.l   d6,d2
        and.l   d7,d1
        move.l  d0,d4
        asr.l   d6,d4
        and.l   d7,d0
        move.l  d1,d3
        mulu.w  d0,d3
        move.l  d3,d5
        lsr.l   d6,d5
        muls.l  d2,d0
        add.l   d5,d0
        move.l  d0,d5
        and.l   d7,d5
        muls.l  d4,d1
        add.l   d5,d1
        muls.l  d4,d2
        asr.l   d6,d0
        add.l   d0,d2
        move.l  d1,d0
        asr.l   d6,d0
        add.l   d2,d0
        lsl.l   d6,d1
        and.l   d7,d3
        add.l   d3,d1
        rts


_HorizonFadeProj_DivsL:
        movem.l d0-d1/a0-a1,-(sp)
	BFEXTS	D2{0:1},D3		;61a36: ebc23001
	;DIVS.L	D6,D3:D2		;61a3a: 4c462c03
        move.l  d2,d0
        move.l  d3,d1
        move.l  d6,d2
        bsr     SDiv646
        move.l  d1,d3
        move.l  d0,d2
        movem.l (sp)+,d0-d1/a0-a1
        rts

        ; divs.l    d2,d1:d0
        ; Thanks to Thomas Richter
        ;https://eab.abime.net/showthread.php?t=104901
        ;; signed 64/32 divide, 68060 function
SDiv646:
    movem.l    d2-d7/a2-a5,-(sp)

    sub.l    a2,a2        ;sign flag divisor
    sub.l    a3,a3        ;sign flag dividend
    move.l    d0,a4
    move.l    d1,a5        ;save original contents

    move.l    d2,d7        ;save divisor
    bpl.s    1$        ;make positive
    addq.w    #1,a2        ;set flag
    neg.l    d7
1$:

    move.l    d0,d6
    move.l    d1,d5        ;save dividend
    bpl.s    2$
    addq.w    #1,a3        ;set flag
    neg.l    d6
    negx.l    d5        ;invert
2$:
    tst.l    d5        ;is the high non-zero? If so, full divide
    bne.s    3$

    tst.l    d6        ;is low zero?
    beq.s    10$        ;yes, we are done

    ;; here low <> 0
    cmp.l    d6,d7        ;is the divisor <= lo (dividend)
    bls.s    5$        ;yes, use a 32-bit divide

    exg.l    d5,d6        ;q = 0, r = dividend
    bra.s    6$        ;can't divide, done
5$:    
    divul.l    d7,d5:d6                    ;# it's only a 32/32 bit div!
    bra.b    6$
3$:    ;; full 64 bit case here. do we have an overflow?
    cmp.l    d5,d7
    bls.s    7$        ;yes
    ;; here full 64/32 divide
    bsr    AlgorithmD    ;perform classical algorithm D from Knuth
    ;; remainder in d6, quotient in d5
6$:    ;done here, check whether there is a sign switch
    cmp.w    #0,a3
    beq.s    8$
    neg.l    d5        ;remainder has the same sign as dividend
8$:
    cmp.w    a2,a3        ;same signs of divisor and dividend?
    beq.s    9$

    cmp.l    #$80000000,d6    ;representable as 32-bit negative number?
    bhi.s    7$        ;overflow
    neg.l    d6        ;make a 2s complement for quotient
    bra.s    10$
9$:                ;here positive
    tst.l    d6        ;will fit into 32 bits?
    bmi.s    7$        ;overflow if not
10$:                ;here done
    move.l    d5,d1        ;remainder -> d1
    move.l    d6,d0        ;quotient -> d0
    andi.b    #$fc,ccr    ;clear V and C
    bra.s    11$
7$:
    move.l    a4,d0        ;restore original register content
    move.l    a5,d1
    ori.b    #$2,ccr        ;set overflow bit
11$:
    movem.l    (sp)+,d2-d7/a2-a5
    rts

    ;; division algorithm. This is either a
    ;; full algorithmD from Knuth "The Art of Programming", Vol.2
    ;; or using a 32:16 division in case the divisor fits
    ;; into 16 bits.
    ;; This algorithm divides d5:d6 by d7
AlgorithmD:    
    swap    d7
    tst.w    d7
    bne.s    1$
    ;; ok, we only need to divide by 16 bits, so
    ;; things are somewhat simpler
    swap    d7        ; restore divisor
    ;; note that we already know that the division
    ;; does not overflow (checked upwards)
    moveq    #0,d1

    swap    d5        ; same as r*b if previous step rqd
    swap    d6        ; get u3 to lsw position
    move.w    d6,d5        ; rb + u3

    divu.w    d7,d5

    move.w    d5,d1        ; first quotient word
    swap    d6        ; get u4
    move.w    d6,d5        ; rb + u4

    divu.w    d7,d5

    swap    d1
    move.w    d5,d1        ; 2nd quotient 'digit'
    clr.w    d5        
    swap    d5        ;now remainder
    move.l    d1,d6        ; and quotient
    rts    
1$:
    swap d7            ; restore divisor
    ;; classical algorithm D.
    ;; In this algorithm, the divisor is treated as a 2 digit (word) number
    ;; which is divided into a 3 digit (word) dividend to get one quotient
    ;; digit (word). After subtraction, the dividend is shifted and the
    ;; process repeated. Before beginning, the divisor and quotient are
    ;; 'normalized' so that the process of estimating the quotient digit
    ;; will yield verifiably correct results..
    moveq    #0,d4                        ;all the flags in d4
ddnchk:
    ;; normalize/upshift the divisor to use full 32 bits, adjust dividend with it.
    ;; the number of shifts goes into d4
    ;; note that d7 is at least 0x00010000
    tst.l    d7
    bmi.b    ddnormalized
ddnchk2:
    addq.l    #$1,d4                        ;count in d4
    lsl.l    #$1,d6                        ;# shift u4,u3 with overflow to u2
    roxl.l    #$1,d5                        ;# shift u1,u2 
    lsl.l    #$1,d7                        ;# shift the divisor
    bpl.b    ddnchk2

    swap    d4                        ;keep lo-word free

ddnormalized:
    ;; Now calculate an estimate of the quotient words (msw first, then lsw).
    ;; The comments use subscripts for the first quotient digit determination.
    move.l    d7,d3                        ;# divisor
    move.l    d5,d2                        ;# dividend mslw
    swap    d3
    swap    d2
    move.w    #$ffff,d1                    ;# use max trial quotient word
    cmp.w    d3,d2                        ;# V1 = U1 ?
    beq.b    ddadj0

    move.l    d5,d1
    divu.w    d3,d1                        ;# use quotient of mslw/msw
ddadj0:

    ;; now test the trial quotient and adjust. This step plus the
    ;; normalization assures (according to Knuth) that the trial
    ;; quotient will be at worst 2 too large.
    ;; NOTE: We do not perform step D3 here. This is not required, as
    ;; D4 is sufficient for adjusting a quotient that has been guessed
    ;; "too large". At most, it can be off by two (easy to prove).

    move.l    d7,d2        ;V1V2->d2

    ;; at this stage, d1 is scaled by 1<<16. Evaluate the 32x32 product d1'0xd7->d2(hi),d3(lo)
    ;; d0,d2,d3,d6 are scratches

    move.l    d7,d0        ;V1V2->d0
    swap     d2        ;get hi of d7 = V1
    mulu.w    d1,d0        ;V2*q: scaled by 2^16, must be split in higher/lower pair
    mulu.w    d1,d2        ;V1*q: the upper 32 bit = V1*q, must be scaled by 2^32
    move.l    d0,d3        ;get lo
    clr.w    d0        ;clear lo
    swap    d3        ;part of it
    swap    d0        ;swap: scale by 2^16: This must be added to hi
    clr.w    d3        ;shift up by 16
    add.l    d0,d2        ;add to hi

    sub.l    d3,d6        
    subx.l    d2,d5        ; subtract double precision
    bcc.s    dd2nd        ; no carry, do next quotient digit

    ;; need to add back divisor longword to current ms 3 digits of dividend
    ;; - according to Knuth, this is done only 2 out of 65536 times for random
    ;; divisor, dividend selection.
    ;;
    ;; thor: computations show that this loop is run at most twice.
    ;; this is better than knuth in this specific case because we
    ;; avoid the multiplications in D3 and this step here (D4) is 
    ;; only addition.

    move.l    d7,d3
    move.l    d7,d2        ; add V1V20 back to U1U2U3U4
    swap    d3
    clr.w    d2
    clr.w    d3
    swap    d2        ; d3 now ls word of divisor
ddaddup:
    subq.l    #$1,d1        ; q is one too large
    add.l    d3,d6        ; aligned with 3rd word of dividend
    addx.l    d2,d5
    bcc    ddaddup        ; until we're positive again
dd2nd:
    tst.l    d4
    bmi.s    ddremain

;# first quotient digit now correct. store digit and shift the
;# (subtracted) dividend 
    move.w    d1,d4        ;keep hi-quotient
    swap    d5
    swap    d6
    move.w    d6,d5
    clr.w    d6        ;shift remainder up by 16 bits
    bset    #31,d4        ;second digit
    bra.s    ddnormalized
ddremain:
;# add 2nd word to quotient, get the remainder.
    swap    d1
    move.w    d4,d1        ;get result of previous division
    swap    d1        ;restore order
    swap    d4        ;restore normalization counter

;# shift down one word/digit to renormalize remainder.
    move.w    d5,d6
    swap    d6
    swap    d5
    clr.l    d7
    move.b    d4,d7
    beq.s    ddrn
    ;; shift d5:d6 to the right by d7 bits, d5 is high
    move.l    d5,d0
    lsr.l    d7,d6        ; shift low out
    ror.l    d7,d0        ; move low bits of high to high
    lsr.l    d7,d5        ; shift high down
    eor.l    d5,d0        ; high bits are in d0
    or.l    d0,d6        ; into d6
ddrn:
    move.l    d6,d5        ; remainder
    move.l    d1,d6
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PL_BRAW macro
        PL_L    \1,$60000000!((\2-(\1+2))&$ffff)
        endm

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
        
        ;PL_P    $4111c,end_level2_int
        
        ; read joy1
        PL_PSS  $41504,test_fire,2

        PL_IFC4X    2 ; "Original rendering code"

        PL_PS   $4CC02,fix_smc

        PL_IFC4X    3 ; "Show FPS"
        PL_PSS  $018a6,do_swap_screen,2
        PL_ENDIF

        PL_ELSE ; New rendering code

        ; Alternative SMC fix
        PL_W    $4cb0e,$3f3e    ; Also preserve A6
        PL_W    $4ce36,$7cfc    ; and restore it again
        PL_W    $4ce06,$4e96    ; jsr (a6)
        PL_PS   $4cb10,draw_mono_image_setup

        PL_NOP  $4c800,4                ; Never use blitter in _MaskSprite
        PL_P    $4bed8,box              ; _ClipBox
        PL_P    $4bf00,box              ; _Box
        PL_P    $4c138,draw_line_normal ; _DrawLine
        PL_P    $6dd04,draw_line_strip  ; _DrawStipLine

        ; @PlayLevel
        PL_PSS  $016b0,start_frame,2
        PL_PSS  $018a6,do_swap_screen,2
        PL_ENDIF

        PL_IFC4X        4 ; "Impatient mode"
        PL_BRAW $42bbe,$42c68           ; @fast_quit
        PL_L    $33904,$70017001        ; Choose to load old save
        PL_L    $337fa,$70007000        ; Choose save slot 0
        PL_PSS  $46586,find_click_box,2 ; Straight to arcade mode
        PL_R    $4b60a                  ; _VSync
        PL_ENDIF

        PL_IFC4X        5 ; Uncapped frame rate
        PL_W    $282b6,$0000 ; Disable frame rate limit
        PL_ENDIF

        PL_GA   $3ff92,@ThreeScreenSwap_ptr
        PL_GA   $4b1b8,_screen1_ptr
        PL_GA   $4bbd0,_vblank_clock_ptr
        PL_GA   $130ea,@Control_ptr
        PL_GA   $0072e,@HandleEjection_ptr
        PL_GA   $3463c,@RemoveDeadMissiles_ptr
        PL_GA   $4a992,_SetPage_ptr
        PL_GA   $4b028,_SetLogbase_ptr
        PL_GA   $4a9ce,_PalNtsc_ptr
        PL_GA   $6bd04,PlotColour_ptr
        PL_GA   $78d64,_logbase_ptr
        PL_GA   $78d68,_current_page_ptr
        PL_GA   $76c0a,_sprogtab_ptr

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

        ; read joy1
        PL_PSS  $3fb1c,test_fire,2

        PL_IFC4X    2 ; "Original rendering code"

        PL_PS   $4c38a,fix_smc

        ; faster blitwait
        PL_PS   $4ba4c,wait_blit
        PL_S    $4ba52,$4ba68-$4ba52
        PL_PS   $4bb08,wait_blit
        PL_S    $4bb0E,$4bb24-$4bb0E

        PL_IFC4X    3 ; "Show FPS"
        PL_PSS  $01632,do_swap_screen,2
        PL_ENDIF

        PL_ELSE ; New rendering code

        ; Remaning (major) accessers of chip mem:
        ; _DrawSpriteImage ($4d076) ~15000/sec (compared to ~192K/sec for copy of fast buffer to chip)
        ; _logbase (section 8) being in chip mem! >6000/sec

        ; Alternative SMC fix
        PL_W    $4c296,$3f3e    ; Also preserve A6
        PL_W    $4c5be,$7cfc    ; and restore it again
        PL_W    $4c58e,$4e96    ; jsr (a6)
        PL_PS   $4c298,draw_mono_image_setup

        PL_NOP  $4bf84,4                ; Never use blitter in _MaskSprite
        PL_P    $4b77c,box              ; _ClipBox
        PL_P    $4b7a4,box              ; _Box
        PL_P    $4b9dc,draw_line_normal ; _DrawLine
        PL_P    $4dc04,draw_line_strip  ; _DrawStipLine

        ; @PlayLevel
        PL_PSS  $01464,start_frame,2
        PL_PSS  $01632,do_swap_screen,2

        PL_ENDIF

        PL_IFC4X        4 ; "Impatient mode"
        PL_BRAW $42132,$421de           ; @fast_quit
        PL_L    $25a96,$70017001        ; Choose to load old save
        PL_L    $25970,$70007000        ; Choose save slot 0
        PL_PSS  $45b94,find_click_box,2 ; Straight to arcade mode
        PL_R    $4aeae                  ; _VSync
        ;PL_P    $462c0,debug_opt ; Script is saved in _text_file ((17730,A4),A0)
        PL_ENDIF

        PL_IFC4X        5 ; Uncapped frame rate
        ; @GetFramerate
        PL_W    $1a372,$7000 ; Disable frame rate limit
        PL_ENDIF

        PL_GA $4aa08,_screen1_ptr
        PL_GA $4b474,_vblank_clock_ptr
        PL_GA $14736,@Control_ptr
        PL_GA $00654,@HandleEjection_ptr
        PL_GA $26966,@RemoveDeadMissiles_ptr
        PL_GA $3e5c2,@ThreeScreenSwap_ptr
        PL_GA $4a052,_SetPage_ptr
        PL_GA $4a878,_SetLogbase_ptr
        PL_GA $4a08e,_PalNtsc_ptr
        PL_GA $71736,_sprogtab_ptr
        PL_GA $73890,_logbase_ptr
        PL_GA $73894,_current_page_ptr
        PL_GA $99edc,PlotColour_ptr

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

        ; read joy1
        PL_PSS  $39ae4,test_fire,2

        PL_IFC4X    2 ; "Original rendering code"

        PL_PS   $46272,fix_smc

        PL_IFC4X    3 ; "Show FPS"
        PL_PSS  $016f6,do_swap_screen,2
        PL_ENDIF

        PL_ELSE ; New rendering code

        ; Alternative SMC fix
        PL_W    $4617e,$3f3e    ; Also preserve A6
        PL_W    $464a6,$7cfc    ; and restore it again
        PL_W    $46476,$4e96    ; jsr (a6)
        PL_PS   $46180,draw_mono_image_setup

        PL_NOP  $45e6c,4                ; Never use blitter in _MaskSprite
        PL_P    $45544,box              ; _ClipBox
        PL_P    $4556c,box              ; _Box
        PL_P    $457a4,draw_line_normal ; _DrawLine
        PL_P    $47abc,draw_line_strip  ; _DrawStipLine

        ;; @PlayLevel
        PL_PSS  $0150c,start_frame,2
        PL_PSS  $016f6,do_swap_screen,2
        PL_ENDIF

        PL_IFC4X        4 ; "Impatient mode"
        PL_BRAW $3bfa2,$3c04c           ; @fast_quit
        PL_L    $21e04,$70017001        ; Choose to load old save
        PL_L    $21cfa,$70007000        ; Choose save slot 0
        PL_PS   $3f93e,find_click_box   ; Straight to arcade mode
        PL_R    $44c76                  ; _VSync
        PL_ENDIF


        PL_IFC4X        5 ; Uncapped frame rate
        PL_W    $17e20+2,$0000 ; Disable frame rate limit
        PL_ENDIF


        PL_GA   $38586,@ThreeScreenSwap_ptr
        PL_GA   $4407c,_screen1_ptr
        PL_GA   $4523c,_vblank_clock_ptr
        PL_GA   $12d1e,@Control_ptr
        PL_GA   $0060e,@HandleEjection_ptr
        PL_GA   $22b30,@RemoveDeadMissiles_ptr
        PL_GA   $43d2e,_SetPage_ptr
        PL_GA   $44526,_SetLogbase_ptr
        PL_GA   $43d6a,_PalNtsc_ptr
        PL_GA   $6b35a,_sprogtab_ptr
        PL_GA   $6d4b8,_current_page_ptr
        PL_GA   $6d4b4,_logbase_ptr
        PL_GA   $93ac8,PlotColour_ptr

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

        ; read joy1
        PL_PSS  $41054,test_fire,2

        PL_IFC4X    2 ; "Original rendering code"

        PL_PS   $4e7ae,fix_smc

        PL_IFC4X    3 ; "Show FPS"
        PL_PSS  $019fc,do_swap_screen,2
        PL_ENDIF

        PL_ELSE ; New rendering code

        ; Alternative SMC fix
        PL_W    $4e6ba,$3f3e    ; Also preserve A6
        PL_W    $4e9e2,$7cfc    ; and restore it again
        PL_W    $4e9b2,$4e96    ; jsr (a6)
        PL_PS   $4e6bc,draw_mono_image_setup

        PL_NOP  $4e3a8,4                ; Never use blitter in _MaskSprite
        PL_P    $4dba0,box              ; _ClipBox
        PL_P    $4dbc8,box              ; _Box
        PL_P    $4de00,draw_line_normal ; _DrawLine
        PL_P    $500dc,draw_line_strip  ; _DrawStipLine

        ;; @PlayLevel
        PL_PSS  $017f8,start_frame,2
        PL_PSS  $019fc,do_swap_screen,2
        PL_ENDIF

        PL_IFC4X        4 ; "Impatient mode"
        PL_BRAW $4385c,$4391c           ; @fast_quit
        PL_L    $2631e,$70017001        ; Choose to load old save
        PL_L    $261f8,$70007000        ; Choose save slot 0
        PL_PS   $47d48,find_click_box_020 ; Straight to arcade mode
        PL_R    $4d2be                  ; _VSync
        PL_ENDIF

        ; Not supported as it's too slow anyway
        ;PL_IFC4X        5 ; Uncapped frame rate
        ;PL_W    $,$0000 ; Disable frame rate limit
        ;PL_ENDIF

        PL_GA   $3f99e,@ThreeScreenSwap_ptr
        PL_GA   $4ce00,_screen1_ptr
        PL_GA   $4d884,_vblank_clock_ptr
        PL_GA   $14fbe,@Control_ptr
        PL_GA   $0082a,@HandleEjection_ptr
        PL_GA   $271ee,@RemoveDeadMissiles_ptr
        PL_GA   $4c44a,_SetPage_ptr
        PL_GA   $4cc70,_SetLogbase_ptr
        PL_GA   $6a4b8,PlotColour_ptr
        PL_GA   $4c486,_PalNtsc_ptr
        PL_GA   $71600,_current_page_ptr
        PL_GA   $715fc,_logbase_ptr
        PL_GA   $6f4a2,_sprogtab_ptr

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
outofmemory
    dc.b    "could not allocate fast buffer"
mem_patched
    dc.b    0
needs_fpu_patches
    dc.b    0
    cnop    0,4
;============================================================================

