;*---------------------------------------------------------------------------
;  :Program.	DefenderOfTheCrown.asm
;  :Contents.	Slave for "Defender of the Crown" from Cinemaware
;  :Author.	Wepl
;  :Original	v1 
;  :Version.	
;  :History.	
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
	OUTPUT	"DefenderOfTheCrown.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIP_ONLY

	IFD	CHIP_ONLY
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= 0
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
	ENDC
NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
HDINIT
IOCACHE		= 5000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
BOOTDOS

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s


;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

DECL_VERSION:MACRO
	incbin	"slave_version"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	ENDM

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	$A,$D,0

_defender1
	dc.b	"defender1",0
_defender2
	dc.b	"defender2",0

slv_CurrentDir		dc.b	"data",0
slv_name		dc.b	"Defender Of The Crown"
			IFD	CHIP_ONLY
			dc.b	" (DEBUG/CHIP MODE)"
			ENDC
			dc.b	0
slv_copy		dc.b	"1986 Cinemaware/Master Designer Software",0
slv_info		dc.b	"Adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
	EVEN
_program:
	dc.b	"defender",0
_args		dc.b	10
_args_end
	dc.b	0
slv_config:
    dc.b    "C1:B:Infinite money;"
    dc.b    "C2:B:1024 knights at start;"
    dc.b    "C3:B:no simulated loading wait;"
	dc.b	0
	EVEN

;============================================================================

PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
    cmp.w	#$4EF9,(A1)
    beq.b   end_patch_\1    ; already done
	moveq	#0,D0
	move.w	4(A1),D0
	addq.l	#4,D0
	add.l	D0,A1

	lea	old_\1(pc),a0
	move.l	A1,(A0)+

	move.l	A6,A1
	add.l	#_LVO\1,A1
	move.b	1(A1),D0
	ext.w	D0
	ext.l	D0
	move.l	D0,(A0)		; moves to d0_value_xxx

	move.w	#$4EF9,(A1)+	
	pea	new_\1_init(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
new_\1_init
	move.l	d0_value_\1(pc),d0
	bra	new_\1
old_\1:
	dc.l	0
d0_value_\1
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1
	ENDM

	;initialize kickstart and environment

_bootdos	move.l	(_resload,pc),a2		;A2 = resload

	;get tags
		lea	(tag,pc),a0
		jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;assigns
		lea	_defender1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_defender2(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;load exe
		lea	_program(pc),a0
		move.l	a0,d1
		jsr	(_LVOLoadSeg,a6)
		move.l	d0,d7			;D7 = segment
		beq	end

        move.l  dont_wait(pc),d0
        bne.b   no_wait
		PATCH_DOSLIB_OFFSET	Open
no_wait
	;patch
;		lea	_pl1,a0
;		move.l	d7,a1
;		jsr	(resload_PatchSeg,a2)

	IFD DEBUG
	;set debug
		clr.l	-(a7)
		move.l	d7,-(a7)
		pea	WHDLTAG_DBGSEG_SET
		move.l	a7,a0
		jsr	(resload_Control,a2)
		add.w	#12,a7
	ENDC

	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1
	addq.l	#4,a1

	movem.l	a1,-(a7)
	lea	pl_main(pc),a0	
	jsr	resload_Patch(a2)
	move.l	(a7)+,a1

	lea	(_args,pc),a0
	move.l	(4,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	moveq	#_args_end-_args,d0

	jsr	(a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	pea	TDREASON_OK
	jmp	(resload_Abort,a2)


end
	jsr	(_LVOIoErr,a6)
	move.l	a3,-(a7)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts


pl_main
	PL_START
	PL_PS	$75AE,avoid_exec_poke
    ; avoid money decrease : everything can be bought
    PL_IFC1
	PL_PS	$2CB4,fix_money
    PL_ENDIF
    PL_IFC2
    PL_PSS   $0045E,set_knights,2
    PL_ENDIF

    ; forces blitter waits (not useful)
    IFEQ    1
    PL_NOP  $2976,2
    PL_NOP  $2A00,2
    PL_NOP  $4ED0,2
    PL_NOP  $518E,2
    PL_PSS  $029BC,wait_blit_1,2
    PL_PSS  $02A2E,wait_blit_1,2
    PL_PSS  $04F34,wait_blit_2,2
    PL_PSS  $0520E,wait_blit_3,2
    ENDC
    
    IFD CHIP_ONLY
    PL_PS   $0FE58,set_a4   ; able to debug data with A4 basereg
    ENDC
	PL_END

    IFEQ    1
wait_blit_1
	MOVE	#$3214,$DFF058
    bsr wait_blit
    rts
wait_blit_2
	MOVE	-40(A5),$DFF058
    bsr wait_blit
    rts
wait_blit_3    
	MOVE	-8(A5),$DFF058
    bsr wait_blit
    rts
    
wait_blit
	BTST	#6,dmaconr+$DFF000
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
    ENDC
    
    IFD CHIP_ONLY
set_a4:
    ADDA.L	#$00008002,A4		
    move.l  a4,$100.W
    rts
    ENDC
    
set_knights

	LEA	-24854(A4),A6		;0045E: 4DEC9EEA
    ; initialize number of knights
	move.w  #1024,0(A6,D3.L)
    rts
    
fix_money
	move.w	#$100,(-$60E6,a4)
	move.l	#$100,d3
	rts

avoid_exec_poke:
	cmp.l	#0,a6
	beq.b	.avoid
	move.l	(4,a6),(-4,a5)
	rts
.avoid
	addq.l	#4,A7
	unlk	A5
	rts

new_Open
	move.l	d1,a0
	add.l	#10,a0

	bsr	wait_if_required

.nogmap
	move.l	old_Open(pc),-(a7)
	rts

MUSTWAIT_FILE_ENTRY:MACRO
	dc.w	\1-filenames_must_wait
	; counter
	dc.w	0
	; open index where must wait (-1: all the time)
	dc.w	\2
	; delay we must wait (divided by 10 i.e. 1/5th of second)
	dc.w	\3*5
	ENDM

; < A0: filename

wait_if_required
	movem.l	d0-a6,-(a7)
	lea	filenames_must_wait(pc),a2
	move.l	a2,a3
.loop
	moveq.l	#0,d0
	move.w	(a2),d0
	beq.b	.out
	add.l	a3,d0	; absolute address
	move.l	d0,a1
	bsr	strcmp
	tst.l	d0
	bne.b	.next

	addq.w	#1,2(a2)	; add 1 to open file counter

	move.w	4(a2),d0	; counter value where must wait
	bmi.b	.wait		; wait if < 0

	cmp.w	2(a2),d0
	bne.b	.next		; we don't wait this time

	; wait if file encountered
.wait
	moveq	#0,d2
	move.w	6(a2),d2
	subq.l	#1,d2
.waitloop
	; wait mouse but not active wait or else other tasks such as
	; music, animations, ... are blocked: not very nice

	moveq	#0,d3
	btst	#6,$bfe001
	bne.b	.nomouse
	st	d3	; we'll exit after the next wait
.nomouse
;;	move.w	#$f00,$dff180
	move.l	#10,d1
	jsr	(_LVODelay,a6)

	tst	d3
	bne.b	.out

	dbf	d2,.waitloop

	bra.b	.out

.next
	addq.l	#filenames_must_wait_end-filenames_must_wait,a2	; next entry
	bra.b	.loop
.out
	movem.l	(a7)+,d0-a6
	rts

filenames_must_wait
	MUSTWAIT_FILE_ENTRY	gmap_name,1,16		; robin 2 message
filenames_must_wait_end
	MUSTWAIT_FILE_ENTRY	char_name,-1,8		; just before character selection
	MUSTWAIT_FILE_ENTRY	sherwood_name,2,16	; robin 1 message
	MUSTWAIT_FILE_ENTRY	sword_name,-1,6
	MUSTWAIT_FILE_ENTRY	joust_name,-1,6
	MUSTWAIT_FILE_ENTRY	gallery_name,-1,8
	MUSTWAIT_FILE_ENTRY	siege_name,-1,6
	dc.w	0

gmap_name
	dc.b	"gmap.scene",0
char_name
	dc.b	"char.scene",0
sword_name
	dc.b	"sword.scene",0
sherwood_name
	dc.b	"sherwood.scene",0
joust_name
	dc.b	"joust.scene",0
gallery_name
	dc.b	"gallery.scene",0
siege_name
	dc.b	"siege.scene",0
	even

; < a0: str1
; < a1: str2
; > d0: -1: fail, 0: ok

strcmp:
	movem.l	d1/a0-a2,-(A7)
.contstrcmpasm
	move.b	(A0)+,d0
	beq.s	.termstrcmpasm
	move.b	(A1)+,d1
	beq.s	.failstrcmpasm
	bsr.s	.letterstrcmpasm
	exg	d0,d1
	bsr.s	.letterstrcmpasm
	cmp.b	d0,d1
	bne.s	.failstrcmpasm
	bra.s	.contstrcmpasm

.termstrcmpasm
	tst.b	(A1)+
	bne.s	.failstrcmpasm
	moveq.l	#0,d0
	bra.s	.endstrcmpasm

.letterstrcmpasm
	cmp.b	#$60,d0
	bls.s	.letter1strcmpasm
	cmp.b	#$7a,d0
	bhi.s	.letter1strcmpasm
	sub.b	#$20,d0
.letter1strcmpasm
	rts

.failstrcmpasm
	moveq.l	#-1,d0
.endstrcmpasm
	movem.l	(A7)+,d1/a0-a2
	rts

tag		dc.l	WHDLTAG_CUSTOM3_GET
dont_wait		dc.l	0
		dc.l	0

;============================================================================


;============================================================================

	END
