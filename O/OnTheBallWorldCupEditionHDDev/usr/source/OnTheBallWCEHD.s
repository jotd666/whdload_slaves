;*---------------------------------------------------------------------------
;  :Program.	OnTheBallWCEHD.asm
;  :Contents.	Slave for "On The Ball/Anstoss World Championship Edition"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
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

	IFD BARFLY
    IFD AGA
	OUTPUT	"OnTheBallWCEAGA.slave"
    ELSE
	OUTPUT	"OnTheBallWCEECS.slave"    
    ENDC
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

    IFD AGA
    IFD CHIP_ONLY
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
    ELSE
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $100000
    ENDC
    ELSE
    IFD CHIP_ONLY
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
    ELSE
CHIPMEMSIZE	= $A0000
FASTMEMSIZE	= $A0000
    ENDC    
    ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
HD_Cyls = 10000		; game believes it runs from HD
BOOTDOS
;;STACKSIZE = 8000
CACHE


;============================================================================


slv_Version	= 17
    IFD AGA
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_ReqAGA
    ELSE
slv_Flags	= WHDLF_NoError|WHDLF_Examine
    ENDC
    
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

_assign_boot:
	dc.b	"boot",0
	
    
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

slv_name		dc.b	"On The ball/Anstoss World Cup Edition"
            IFD AGA
                dc.b    " AGA"
             ENDC
                dc.b    0
slv_copy		dc.b	"1994 Ascon",0
slv_info		dc.b	"adapted by JOTD",10,10
			dc.b	"Version "
			DECL_VERSION
		dc.b	0
	EVEN

;============================================================================



CHECK_AND_ASSIGN:MACRO

	;assigns
		lea	\1_assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign4(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign5(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	\1_assign6(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	ENDM


    
_bootdos
	move.l	(_resload,pc),a2		;A2 = resload

	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

    ;;bsr install_kbint
    
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase


	; assigns

		lea	_assign_boot(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	; perform the necessary assigns

		CHECK_AND_ASSIGN	gb
		CHECK_AND_ASSIGN	d

        IFD CHIP_ONLY
        movem.l a6,-(a7)
        move.l  $4,a6
        move.l  #$3150,d0
        move.l  #MEMF_CHIP,D1
        jsr (_LVOAllocMem,a6)
        movem.l (a7)+,a6
        ENDC
        
        lea	score(pc),a0
        lea	savedir(pc),a1
        bsr	_dos_assign

        lea program(pc),a0
        lea	args(pc),a1
        move.l	#args_end-args,d0
        lea patch_alloc(pc),a5
        bsr	_load_exe


        pea	TDREASON_OK
        move.l	_resload(pc),-(a7)
        addq.l	#resload_Abort,(a7)
        rts

patch_alloc
    move.l  d7,a1
    addq.l  #4,a1
    lea pl_alloc(pc),a0
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    rts

scrmodule_loaded
    ; vector to a lot of utility routines, shared by proggies
	MOVE.L	D0,$8.W
	MOVEA.L	D0,A0			;0590: 2040
    
    movem.l a0-a2/d0-d1,-(a7)
    move.l  _resload(pc),a2
    move.l  a0,a1
    lea pl_scrmodule_aga(pc),a0       ; also works on another version
    cmp.l   #$4e7a1801,($2F26,a1)
    beq.b   .patch
    bra.b   .skip
    ; just in case...
    bra wrongver
.patch

    jsr (resload_Patch,a2)
.skip
    movem.l (a7)+,a0-a2/d0-d1    
.noscpatch
    rts
    
run_intro
    bsr _flushcache
    movem.l a0,-(a7)
    jsr (a0)
    movem.l (a7)+,a0
    rts
 

run_main
    ; patch, there are 2 offsets depending on the version
    movem.l a0-a2/d0-d1,-(a7)
    move.l  _resload(pc),a2
    move.l  a0,a1
    lea pl_main_uk_ecs(pc),a0       ; also works on another version
    cmp.l   #$2F0E2C79,($490,a1)
    beq.b   .patch
    lea pl_main_ger_aga(pc),a0       ; also works on another version
    cmp.l   #$2F0E2C79,($48c,a1)
    beq.b   .patch
    ; just in case...
    bra wrongver
.patch

    jsr (resload_Patch,a2)    
    movem.l (a7)+,a0-a2/d0-d1
    ; call
    movem.l a0,-(a7)
    jsr (a0)
    movem.l (a7)+,a0
    ; quit game with "end" button (probably crashes in the real game)
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
    
wrongver:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
; < A0: executable name
load_executable:
	MOVE.L	A6,-(A7)		;105e18: 2f0e
	MOVEA.L	$3C.W,A6		;105e1a: scrmodul/other function vector
	JSR	44(A6)			;105e20: 4eae002c
    ; returns start in D0
	MOVEA.L	(A7)+,A6		;105e24: 2c5f
    bsr _flushcache
	RTS				;105e26: 4e75

load_hwm_executable
    bsr load_executable
    move.l  d0,d7
    movem.l a0-a2/d0-d1,-(a7)
    move.l  _resload(pc),a2
    move.l  d0,a1
    ;lea pl_hwm(pc),a0
    ;jsr (resload_Patch,a2)    
    movem.l (a7)+,a0-a2/d0-d1
    rts
 
load_init_executable
    bsr load_executable
    move.l  d0,d7
    movem.l a0-a2/d0-d1,-(a7)
    move.l  _resload(pc),a2
    move.l  d0,a1
    ; simple sanity check just in case
    cmp.l   #$43ef0032,($370,a1)
    bne   wrongver
    
    lea pl_init(pc),a0
    jsr (resload_Patch,a2)    
    movem.l (a7)+,a0-a2/d0-d1
    rts

pl_scrmodule_aga
    PL_START
    ; no VBR read, leave at 0
    PL_NOP    $2f26,10
    PL_END
    
pl_init
    PL_START
    PL_W    $35E,$1011  ; move.b  (a1),d0 is simpler, seen in a crack
    ; crack manual protection $00055CEA-$00055988
    ;;PL_S     $362,$1E ; this works too
    PL_END
   
pl_main_uk_ecs
    PL_START
    ; load and patch init.exe (protection)
    PL_PS   $2C6,load_init_executable   ; $105c4e-$105988
    ; flush caches when loading any executable
    PL_P   $490,load_executable        ; $105e18-$105988
    ; load hwm
    ;PL_PS   $2FE,load_hwm_executable
    PL_END

pl_main_ger_aga
    PL_START
    ; load and patch init.exe (protection)
    PL_PS   $2C2,load_init_executable   ; $a9c92-$a99d0
    ; flush caches when loading any executable
    PL_P   $48c,load_executable        ; $a9e5c-$a99d0
    PL_END

pl_alloc
    PL_START
    PL_IFC1
    PL_NOP  $05a6,6
    PL_ELSE
    PL_PS   $05a6,run_intro    
    PL_ENDIF
    

    PL_P   $05c0,run_main    
    PL_PS   $058C,scrmodule_loaded
    
    PL_R    $09e8       ; remove cacr/vbr tampering
    PL_NOP  $0658,4     ; cacr change
    PL_END
            
;============================================================================
    
        IFEQ    1
    
new_Open
	cmp.l	#MODE_NEWFILE,d2
	bne	.out
    
	; what is the assign
	cmp.b	#'s',(a0)+
	bne.b	.out
	cmp.b	#'a',(a0)+
	bne.b	.out
	cmp.b	#'v',(a0)+
	bne.b	.out
	cmp.b	#'e',(a0)+
	bne.b	.out
	cmp.b	#'d',(a0)+
	bne.b	.out
	cmp.b	#'i',(a0)+
	bne.b	.out
	cmp.b	#'s',(a0)+
	bne.b	.out
	cmp.b	#'k',(a0)+
	bne.b	.out
	cmp.b	#':',(a0)+
	bne.b	.out


	; A1: savename.ans
	; create the file in advance so write to file
	; will be much faster and without os swaps

	movem.l	d0-d1/a0-a2,-(a7)

	lea	savebuf+5(pc),a1
.copy
	move.b	(a0)+,(a1)+
	bne.b	.copy

	lea	savebuf(pc),a0	; name

	move.l  #1,d0                 ;size
	move.l  #20000,d1               ;offset (max save size)
	lea     savebuf(pc),a1          ;source
	move.l  (_resload,pc),a2
	jsr     (resload_SaveFileOffset,a2)

	movem.l	(a7)+,d0-d1/a0-a2

.out
	move.l	old_Open(pc),-(a7)
	rts

savebuf:
	dc.b	"save/"

	ds.b	30,0
	even
    ENDC
    
    

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
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
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_skip_intro	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_original_keyboard	dc.l	0
		dc.l	0

slv_config
	dc.b    "C1:B:skip introduction;"
	dc.b	0


slv_CurrentDir:
	dc.b	"data",0
	EVEN
    
d_assign1
	dc.b	"anstosswm1",0
d_assign2
	dc.b	"anstosswm2",0
d_assign3
	dc.b	"anstosswm3",0
d_assign4
	dc.b	"anstosswm4",0
d_assign5
	dc.b	"anstosswm5",0
d_assign6:
	dc.b	"anstosswm6",0


gb_assign1
	dc.b	"OTB-WORLDCUP1",0
gb_assign2
	dc.b	"OTB-WORLDCUP2",0
gb_assign3
	dc.b	"OTB-WORLDCUP3",0
gb_assign4
	dc.b	"OTB-WORLDCUP4",0
gb_assign5
	dc.b	"OTB-WORLDCUP5",0
gb_assign6:
	dc.b	"OTB-WORLDCUP6",0

score:
    dc.b    "savedisk",0
    
savedir
	dc.b	"save",0
program
	dc.b	"alloc",0


args		dc.b	10
args_end
	dc.b	0
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION

		dc.b	0
    even
    
active_keymap
	dc.l	0
active_program
	dc.l	0
_keyboard_type
    dc.l    0
;============================================================================
