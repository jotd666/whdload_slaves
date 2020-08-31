;*---------------------------------------------------------------------------
;  :Program.	CartonRougeHD.asm
;  :Contents.	Slave for "CartonRouge"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: CartonRougeHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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

	IFD BARFLY
	OUTPUT	"Anstoss.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

CHIPMEMSIZE	= $A0000
FASTMEMSIZE	= $D0000
NUMDRIVES	= 1
WPDRIVES	= %0000

BLACKSCREEN
;DISKSONBOOT
DOSASSIGN
;DEBUG
HDINIT
;HRTMON
IOCACHE		= 10000	; german saves are big
;MEMFREE	= $200
;NEEDFPU
SETPATCH
HD_Cyls = 10000		; game believes it runs from HD
BOOTDOS
STACKSIZE = 8000
CACHE
CBDOSLOADSEG

;============================================================================


slv_Version	= 16
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	INCLUDE	kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


d_assign1
	dc.b	"ANSTOSS1",0
d_assign2
	dc.b	"ANSTOSS2",0
d_assign3
	dc.b	"ANSTOSS3",0
d_assign4
	dc.b	"ANSTOSS4",0
d_assign5
	dc.b	"ANSTOSS5",0
d_assign6:
	dc.b	"spielstandanstoss",0
d_assign7:
	dc.b	"spielstandanstoss",0


f_assign1
	dc.b	"c-r1",0
f_assign2
	dc.b	"c-r2",0
f_assign3
	dc.b	"c-r3",0
f_assign4
	dc.b	"c-r4",0
f_assign5
	dc.b	"c-r5",0
f_assign6:
	dc.b	"scorediskotb",0
f_assign7
	dc.b	"df0",0

savedir
	dc.b	"save",0

_assign7:
	dc.b	"FONTS",0
_assign8:
	dc.b	"LIBS",0


DECL_VERSION:MACRO
	dc.b	"1.2"
	ENDM

slv_name		dc.b	"Anstoss/Carton Rouge",0
slv_copy		dc.b	"1992 Ascon",0
slv_info		dc.b	"adapted by JOTD",10
			dc.b	"from Wepl excellent KickStarter 34.005",10,10
			dc.b	"Set CUSTOM1=1 to skip introduction",10,10
			dc.b	"Version "
			DECL_VERSION
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0
	EVEN

intro
	dc.b	"intro",0
d_program:
	dc.b	"ANSTOSS",0
f_program:
	dc.b	"c-r",0
setmap
	dc.b	"setmap",0
args		dc.b	10
args_end
	dc.b	0
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
		dc.b	$A,$D,0

	EVEN

;============================================================================

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	lsl.l	#2,d0		;-> APTR
	move.l	d0,a0
	moveq	#0,d0
	move.b	(a0)+,d0	;D0 = name length
	;remove leading path
	move.l	a0,a1
	move.l	d0,d2
.2	move.b	(a1)+,d3
	subq.l	#1,d2
	cmp.b	#":",d3
	beq	.1
	cmp.b	#"/",d3
	beq	.1
	tst.l	d2
	bne	.2
	bra	.3
.1	move.l	a1,a0		;A0 = name
	move.l	d2,d0		;D0 = name length
	bra	.2
.3

	move.l	d1,a1
	addq.l	#4,a1	; first segment

	bsr	get_string_word

	cmp.l	#'atar',d2
	bne.b	.4
	cmp.b	#$D,d0
	bne.b	.4

	; atari.library: remove the protection

	add.l	#$702,a1

	move.w	#$4EB9,(a1)+
	pea	crack_it(pc)
	move.l	(a7)+,(a1)
	bra.b	.out
.4
	cmp.l	#'lade',d2
	bne.b	.5
	cmp.b	#$10,d0
	bne.b	.5

	; ladenlib.library

	bra.b	.out
.5
	cmp.l	#'edit',d2
	bne.b	.6
	lea	editor_called(pc),a0
	st.b	(a0)
.6
.out
	rts

; < A0
; > D2
get_string_word
	movem.l	a0/d3,-(a7)
	moveq.l	#3,d3
.gwloop
	lsl.l	#8,d2
	move.b	(a0)+,d2
	cmp.b	#'Z'+1,d2
	bcc.b	.nouc
	cmp.b	#'A',d2
	bcs.b	.nouc
	add.b	#'a'-'A',d2
.nouc
	dbf	d3,.gwloop
	movem.l	(a7)+,a0/d3
	rts

crack_it	
	movem.l	D0/A1,-(a7)
	move.b	-1(a5),d0
	cmp.b	#'A',d0
	bcs.b	.out
	cmp.b	#'z'+1,d0
	bcc.b	.out

	; likely to be a letter

	cmp.b	29(a5),d0
	bne.b	.out

	move.l	a5,a0
	lea	30(A5),a1

	; copy the answer into the question buffer!

.cp
	move.b	(a1)+,(a0)+
	bne.b	.cp

.out
	movem.l	(a7)+,d0/A1

	; stolen

	move.l	a5,a0
.loop
	tst.b	(a0)+
	bne.B	.loop
	;initialize kickstart and environment
	
	rts

CHECK_AND_ASSIGN:MACRO
		lea	.keymap_\1(pc),a0
		move.l	a0,d1
		move.l	#ACCESS_READ,d2
		jsr	_LVOLock(a6)
		move.l	d0,d1
		beq.b	.out_\1
		jsr	_LVOUnLock(a6)

		lea	.keymaparg_\1(pc),a0
		lea	active_keymap(pc),a1
		move.l	a0,(a1)		
		lea	\1_program(pc),a0
		lea	active_program(pc),a1
		move.l	a0,(a1)		
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
		lea	savedir(pc),a1
		bsr	_dos_assign
		lea	\1_assign7(pc),a0
		lea	savedir(pc),a1
		bsr	_dos_assign
		bra.b	.out_\1
.keymap_\1
	dc.b	"DEVS:Keymaps/\1",0,0
.keymaparg_\1
	dc.b	"\1",10,0
		even
.out_\1
	ENDM

PATCH_DOSLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
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

_bootdos
	move.l	(_resload),a2		;A2 = resload

	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

	;patch dos lib: Open
		PATCH_DOSLIB_OFFSET	Open

	;test (and create) hd file flag

		bsr	check_vonplatte

	; assigns

		lea	_assign7(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	_assign8(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

	;check which version we have and perform the necessary assigns

		CHECK_AND_ASSIGN	f
		CHECK_AND_ASSIGN	d

		move.l	active_keymap(pc),d0
		bne.b	.ok

		pea	TDREASON_WRONGVER
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
.ok

		move.l	_custom1(pc),d0
		bne.b	.skip
		lea	intro(pc),a0
		lea	args(pc),a1
		move.l	#args_end-args,d0
		sub.l	a5,a5
		bsr	_load_exe

.skip
	IFEQ	1
		move.l	active_keymap(pc),a1
		lea	setmap(pc),a0
		moveq.l	#2,d0
		sub.l	a5,a5
		bsr	_load_exe
	ENDC

		move.l	active_program(pc),a0
		lea	args(pc),a1
		move.l	#args_end-args,d0
		sub.l	a5,a5
		bsr	_load_exe

		lea	editor_called(pc),a0
		tst.b	(a0)
		beq.b	.quit

		; we just quit the editor: reboot

		clr.b	(a0)
		move.l	$4.W,a6
		lea	.svmode(pc),a5
		jsr	_LVOSupervisor(a6)
		ILLEGAL
.svmode
		ori	#$700,SR
		bra	kick_reboot

.quit
		pea	TDREASON_OK
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts

editor_called
		dc.w	0

new_Open
	cmp.l	#MODE_NEWFILE,d2
	bne.b	.out

	; what is the assign
	move.l	d1,a0	; filename
	cmp.b	#'n',(a0)+
	bne.b	.nonil
	cmp.b	#'i',(a0)+
	bne.b	.nonil
	cmp.b	#'l',(a0)+
	bne.b	.nonil
	cmp.b	#':',(a0)+
	bne.b	.nonil

	bra.b	.out	; open "nil" device
.nonil

	move.l	d1,a0	; filename
	move.l	D0,-(a7)
.raloop
	move.b	(a0)+,d0
	beq.b	.ex
	cmp.b	#':',d0
	bne.b	.nocolon
	move.l	a0,a1	; store simplified name in A1
.nocolon
	bra.b	.raloop
.ex
	move.l	(a7)+,d0

	; A0 points to the end of the name
	subq.l	#5,a0

	cmp.b	#'.',(a0)+
	bne.b	.noans
	cmp.b	#'a',(a0)+
	bne.b	.noans
	cmp.b	#'n',(a0)+
	bne.b	.noans
	cmp.b	#'s',(a0)+
	bne.b	.noans

	; A1: savename.ans
	; create the file in advance so write to file
	; will be much faster and without os swaps

	movem.l	d0-d1/a0-a2,-(a7)

	lea	savebuf+5(pc),a0
.copy
	move.b	(a1)+,(a0)+
	bne.b	.copy

	lea	savebuf(pc),a0	; name

	move.l  #1,d0                 ;size
	move.l  #180000,d1               ;offset (max save size)
	lea     savebuf(pc),a1          ;source
	move.l  (_resload,pc),a2
	jsr     (resload_SaveFileOffset,a2)

	movem.l	(a7)+,d0-d1/a0-a2

.noans
.out
	move.l	old_Open(pc),-(a7)
	rts

savebuf:
	dc.b	"save/"

	blk.b	30,0
	even


check_vonplatte:
		lea	savedir(pc),a0
		move.l	a0,d1
		move.l	#ACCESS_READ,d2
		jsr	_LVOLock(a6)
		move.l	d0,d1
		bne	.okdir

		pea	savedir(pc)
		pea	205			; directory not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

.okdir
		jsr	_LVOUnLock(a6)

		; check if file "vonplatte" exists (HD flag)

		lea	.vonplatte_name(pc),a0
		move.l	a0,d1
		move.l	#ACCESS_READ,d2
		jsr	_LVOLock(a6)
		move.l	d0,d1
		bne	.ok

		; create the file if not exists

		lea	.vonplatte_name(pc),a0
		move.l	a0,d1
		move.l	#MODE_NEWFILE,d2
		jsr	_LVOOpen(a6)		
		move.l	d0,d1
		bne.b	.close
		ILLEGAL			; problem!!!
.close
		jsr	_LVOClose(a6)
		bra.b	.cont
.ok
		jsr	_LVOUnLock(a6)
.cont
		rts

.vonplatte_name
	dc.b	"vonplatte",0
	even

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
_custom1	dc.l	0
		dc.l	0

active_keymap
	dc.l	0
active_program
	dc.l	0
;============================================================================

	END
