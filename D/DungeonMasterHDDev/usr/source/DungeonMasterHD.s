;*---------------------------------------------------------------------------
;  :Modul.	kick13.asm
;  :Contents.	kickstart 1.3 booter
;  :Author.	Wepl
;  :Original.
;  :Version.	$Id: kick13.asm 1.2 2001/09/20 19:46:12 wepl Exp wepl $
;  :History.	19.10.99 started
;		20.09.01 ready for JOTD ;)
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	lvo/dos.i
	INCLUDE	lvo/exec.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

;CHIP_ONLY

	IFD BARFLY
	OUTPUT	"DungeonMaster.Slave"
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
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $00000
	ELSE
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 2
WPDRIVES	= %1111

DISKSONBOOT
CBDOSLOADSEG
SETPATCH
;HDINIT

;MEMFREE	= $100
;NEEDFPU

;============================================================================

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_EmulPriv|WHDLF_EmulTrap
slv_keyexit	= $5D	;num '*'

;============================================================================

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
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
slv_config:
        dc.b    "C1:X:trainer no damage:0;"
		dc.b	0

slv_name		dc.b	"Dungeon Master (V3.6)"
		IFD	CHIP_ONLY
		dc.b	" (DEBUG MODE)"
		ENDC
		dc.b	0
slv_copy		dc.b	"1986-1992 FTL/Software Heaven",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"from Wepl excellent KickStarter 34.005",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	0
	EVEN

; < D0: BSTR filename
; < D1: seglist
_cb_dosLoadSeg
		add.l	D1,D1		
		add.l	D1,D1	
		addq.l	#4,d1	

		; now D1 is start address

		lsl.l	#2,d0
		move.l	d0,a0

		addq.l	#1,a0
		bsr	get_long
		cmp.l	#'BJEL',D0	; BJELoad_R BSTR
		bne.b	.nomain_v3


		move.l	d1,a1		; bjeload program
        lea loader_routine(pc),a0
        move.l  ($82A,a1),(a0)
        
		lea	pl_bjeload(pc),a0	; patchlist
		move.l	_resload(pc),a2
		jsr	resload_Patch(a2)
		rts
.nomain_v3
		cmp.l	#'Vers',D0
		beq.b	.skip

		cmp.w	#'dm',D0	; dm BSTR
		bne.b	.nomain_v1
		bra	wrong_version	; unsupported old version!
.nomain_v1
		cmp.l	#'exec',D0
		bne.b	.skipexec
		rts			; exec
.skipexec
		cmp.w	#'by',D0
		beq.b	.skip
		rts			; bye

.skip
		; skip program

		move.l	D1,A0
		move.l	#$70004E75,(A0)
		rts

_quit
		PEA	TDREASON_OK
		MOVE.L	_resload(PC),-(A7)
		add.l	#resload_Abort,(a7)
		rts

wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

loader_routine_wrap
	MOVE.L	-18(A5),-(A7)		;0820: 2f2dffee: file id or such
	MOVE.L	-26(A5),-(A7)		;0824: 2f2dffe6: source address
	move.l  loader_routine(pc),a0
    jsr (a0)
    movem.l a1,-(a7)
    move.l  8(a7),a1
    add.l   #$fbd6-$3154,a1
    ; A0 is the start address
    ; check if main engine is loaded
    cmp.l   #$39460034,(a1)
    bne.b   .nomain
    move.l  8(a7),a1
    movem.l d0-d1/A0/A2,-(a7)
    move.l  _resload(pc),a2
    lea pl_main(pc),a0
    jsr resload_Patch(a2)
    movem.l (a7)+,d0-d1/A0/A2
.nomain
    movem.l (a7)+,a1
    
	ADDQ.W	#8,A7			;082e: 504f
    rts
    
loader_routine
    dc.l    0
    
pl_main
	PL_START
    PL_IFC1X    0
    PL_NOP      $fbd6-$3154,4   ; no damage when hitting walls
    PL_ENDIF
    PL_END
    
pl_bjeload
	PL_START
	PL_PS	$6C,end_bje_patch
	PL_PS	$E8C,main_jump
	PL_P	$19BA,c_open
    PL_PSS  $0820,loader_routine_wrap,10
    PL_B    $084c,$60 ; remove checksum check so we can modify the main proggy...
    PL_B    $0752,$60 ; remove checksum check so we can modify the main proggy...
    PL_R    $0be0   ; remove checksum routine to save time!
	PL_END

; don't know if it's any use...
end_bje_patch
	MOVE.L	#$4afc4e73,12(A2)	;006c: 257c4afc4e73000c
	MOVE.L	D4,24(A2)		;0074: 25440018
	add.l	#6,(A7)
	bsr	_flushcache
	rts
	
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

; for V3.6

main_jump:
	movem.l	D0-D1/A0-A2,-(A7)

	MOVEA.L	24(A6),A5		;original

	move.l	last_opened_file(pc),d0
	cmp.l	#'KAOS',D0
	bne.b	.nomain

	bsr	_replace_df0
.nomain
	bsr	_flushcache
	movem.l	(A7)+,D0-D1/A0-A2

	jmp	(A0)

; replace DF0: by DF1: for savegame disk unit

_replace_df0:
	movem.l	D0-A6,-(A7)

    
	move.l	a0,a1		; end
    IFD CHIP_ONLY
    move.l  a0,$100
    ENDC
    
	sub.l	#$20000,a0
	lea	.df0_1(pc),a2
	moveq.l	#4,d0
.df0_1_loop:
	bsr	_rev_hexsearch

	cmp.l	#0,A1
	beq.b	.exit_1

	move.l	#'DF1:',(a1)
	cmp.l	#$00004475,4(a1)
	bne.b	.df0_1_loop
.exit_1
	movem.l	(A7)+,D0-A6
	rts

.df0_1:
	dc.b	"DF0:"
	even

; < A0: address
; > D0: longword
get_long
	move.l	a0,-(a7)
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	lsl.l	#8,d0
	move.b	(a0)+,d0
	move.l	(a7)+,a0
	rts

;< A0: start
;< A1: end
;< A2: bytes
;< D0: length
;> A1: address or 0 if not found


_rev_hexsearch:
	movem.l	D1/D3/A0/A2,-(A7)
.addrloop:
	moveq.l	#0,D3
.strloop:
	move.b	(A1,D3.L),D1	; gets byte
	cmp.b	(A2,D3.L),D1	; compares it to the user string
	bne.b	.notok		; nope
	addq.l	#1,D3
	cmp.l	D0,D3
	bcs.b	.strloop

	; pattern was entirely found!

	bra.b	.exit
.notok:
	subq.l	#1,A1	; next byte please
	cmp.l	A0,A1
	bcc.b	.addrloop	; end?
	sub.l	A1,A1
.exit:
	movem.l	(A7)+,D1/D3/A0/A2
	rts

	END

