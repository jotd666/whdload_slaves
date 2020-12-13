;*---------------------------------------------------------------------------
;  :Program.	
;  :Contents.	Slave for "Bundesliga Manager Hattick AGA"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BMHHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"BundesligaManagerHatt.slave"
	IFND	CHIP_ONLY
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	ENDC

	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

	IFD	CHIP_ONLY
    ; with this setting it's easier to debug
    ; but the title music is trashed
    ; except in version 1
CHIPMEMSIZE	= $200000
FASTMEMSIZE	= $0000
	ELSE
    ; there's enough memory for the music to play properly
CHIPMEMSIZE	= $180000
FASTMEMSIZE	= $100000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
INITAGA
HDINIT
;HRTMON
IOCACHE		= 1000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
STACKSIZE = 20000
BOOTDOS
CACHE
;HD_Cyls = 1000

slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Req68020|WHDLF_ReqAGA|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

;============================================================================

	include	kick31.s

;============================================================================



_assign_env
	dc.b	"ENV",0
_assign_1
	dc.b	"BMH_1",0
_assign_2
	dc.b	"BMH_2",0
_assign_3
	dc.b	"BMH_3",0
_assign_4
	dc.b	"JFF",0
savedir
	dc.b	"save",0

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
	dc.b	"$VER: slave "
	DECL_VERSION
    dc.b    0
    
slv_name	dc.b	"Bundesliga Manager Hattrick AGA"
		IFD	CHIP_ONLY
		dc.b	" (DEBUG/CHIP MODE)"
		ENDC
		dc.b	0
slv_copy	dc.b	"1994 Software 2000 / Kron software",0
slv_info	dc.b	"adapted & fixed by JOTD",10
		dc.b	"Thanks to Hubert Maier Jr for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

_program:
	dc.b	"m3",0
_args		dc.b	"KRON-SOFTWARE",10
_args_end
	dc.b	0
envpath
	dc.b	"ram:",0


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
	move.l	_resload(pc),a2		;A2 = resload


	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	savedir(pc),a0
		bsr	must_exist

	; patch doslib

	PATCH_XXXLIB_OFFSET	Open
	PATCH_XXXLIB_OFFSET	Lock

	;assigns
		lea	_assign_env(pc),a0
		lea	envpath(pc),a1
		bsr	_dos_assign
		lea	_assign_1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_3(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign_4(pc),a0
		lea	savedir(pc),a1
		bsr	_dos_assign

        IFD CHIP_ONLY
        movem.l a6,-(a7)
        move.l  4,A6
        move.l  #$20000-$1F920,d0
        move.l  #MEMF_CHIP,d1
        jsr _LVOAllocMem(a6)
        movem.l (a7)+,a6
        ENDC
	;load exe
		lea	_program(pc),a0
		lea	_args(pc),a1
		moveq	#_args_end-_args,d0
		lea	patch_main(pc),a5
		bsr	_load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < A0 filename
; < A6 dosbase

must_exist
	movem.l	d0-d1/a0-a1/a3,-(a7)
	move.l	a0,d1
	move.l	a0,a3
	move.l	#ACCESS_READ,d2
	jsr	_LVOLock(a6)
	move.l	d0,d1
	beq.b	.error
	jsr	_LVOUnLock(a6)
	movem.l	(a7)+,d0-d1/a0-a1/a3
	rts

.error
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

new_Open
    bsr hack_df0
	move.l	old_Open(pc),-(a7)
	rts

new_Lock
	bsr hack_df0
	move.l	old_Lock(pc),-(a7)
	rts

get_long
	move.l	(a0)+,d0
	rts
    
hack_df0
    
	move.l	d1,a0
	bsr	get_long
    
	cmp.l	#'DF0:',d0
	bne.b	.orig
	move.l	#'JFF:',-4(a0)
.orig	
    rts
    
; < d7: seglist (APTR)

patch_main
	movem.l	d0-d1/a0-a2,-(a7)
	lea	_program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

    move.l  d7,a1
    
	cmp.l	#418428,D0
	beq.b	v1

	cmp.l	#431692,d0
	beq.b	v1_12

	cmp.l	#432308,d0
 	beq.b	v1_20
   
	cmp.l	#432896,d0
	beq.b	v1_21		; StingRay's v1.21
    
	cmp.l	#434320,d0
	beq.b	v1_31

	cmp.l	#434468,d0
	beq.b	v1_35

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts


out
	movem.l	(a7)+,d0-d1/a0-a2
	rts

v1
	lea	pl_v1(pc),a0
pmain:
	move.l	_resload(pc),a2
	jsr	resload_PatchSeg(a2)
	bra	out


v1_20
	lea	pl_v1_20(pc),a0
    bra pmain
v1_21
	lea	pl_v1_21(pc),a0
    bra pmain
v1_31
	lea	pl_v1_31(pc),a0
    bra pmain
v1_35
	lea	pl_v1_35(pc),a0
    bra pmain
v1_12
	lea	pl_v1_12(pc),a0
    bra pmain

pl_v1
	PL_START
	; remove DF0: check (based on intuition disk change routines)
	; -> it is possible to reload a game
	PL_B	$35D0E,$60

    ; no trace of any protection code like newer versions...
    
	PL_I	$5b5d4	; CACR shit
	PL_PS	$5b998,emulate_dbf
	PL_PS	$5ba54,emulate_dbf

    PL_PSS  $024ec,patch_aux,2

	PL_END


pl_v1_12
	PL_START
	; remove DF0: check (based on intuition disk change routines)
	; -> it is possible to reload a game
    PL_B	$35582,$60

	;; crack (thx StingRay!)
	PL_NOP	$10686,4
	PL_B	$548c4,$60

	PL_I	$5d504 ; CACR shit
	PL_PS	$5d806,emulate_dbf
	PL_PS	$5d8be,emulate_dbf
    
    PL_PSS  $0250c,patch_aux,2
	PL_END

pl_v1_20
	PL_START
	; remove DF0: check (based on intuition disk change routines)
	; -> it is possible to reload a game
    PL_B	$3575a,$60

	;; crack (thx StingRay!)
	PL_NOP	$10796,4
	PL_B	$54ae4,$60

	PL_I	$5d734	; CACR shit
	PL_PS	$5da56,emulate_dbf
	PL_PS	$5db0e,emulate_dbf
    
   
	PL_END

pl_v1_21
	PL_START
	; remove DF0: check (based on intuition disk change routines)
	; -> it is possible to reload a game
    PL_B	$358fe,$60

	;; crack (thx StingRay!)
	PL_NOP	$10862,4
	PL_B	$54d2c,$60

	PL_I	$5d940	; CACR shit
	PL_PS	$5dc62,emulate_dbf
	PL_PS	$5dd1a,emulate_dbf
	PL_END

pl_v1_31
	PL_START
	; remove DF0: check (based on intuition disk change routines)
	; -> it is possible to reload a game
    PL_B	$35d0e,$60

	;; crack (thx StingRay!)
	PL_NOP	$108aa,4
	PL_B	$55194,$60

	PL_I	$5de7c	; CACR shit
	PL_PS	$5e19e,emulate_dbf
	PL_PS	$5e256,emulate_dbf
    
	PL_END
pl_v1_35
	PL_START
	; remove DF0: check (based on intuition disk change routines)
	; -> it is possible to reload a game
    PL_B	$35daa,$60

	;; crack (thx StingRay!)
	PL_NOP	$108a2,4
	PL_B	$551d0,$60

	PL_I	$5df08	; CACR shit
	PL_PS	$5e22a,emulate_dbf
	PL_PS	$5e2e2,emulate_dbf
	PL_END
pl_aux
	PL_START
    PL_PS   $76,dma_audio_write
    PL_PSS   $00fa,dma_audio_write_2,2
    PL_END
    
patch_aux:
	MOVEA.L	$4,A6	;0250c: 2c780004
	JSR	(_LVOCopyMem,A6)	;02510: 4eaefd90 exec.library (off=-624)
    ; A2: destination
    cmp.l   #$DFF096,($78+$20,a2)
    bne.b   .no_aux
    movem.l d0-d1/a0-a2,-(a7)
    lea ($20,a2),a1
    move.l  _resload(pc),a2
    lea pl_aux(pc),a0
    ;;jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
.no_aux
    rts
    
dma_audio_write
    MOVE.W	d0,_custom+dmacon
    bra dma_wait

dma_audio_write_2
    bsr dma_wait
    MOVE.W	52(A6),_custom+dmacon
    rts
 
dma_wait
    move.l  d0,-(a7)
	move.l  #4,d0
	bsr	beamdelay
    move.l  (a7)+,d0
    rts
    
emulate_dbf
	;; soundtracker delay shit
	move.l  #7,d0
	bsr	beamdelay
	add.l	#2,(a7)
	rts


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
	jsr	(_LVOIoErr,a6)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
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



;============================================================================

	END
