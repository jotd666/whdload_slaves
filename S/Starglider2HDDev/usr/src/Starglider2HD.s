;*---------------------------------------------------------------------------
;  :Program.	starglider2.slave.asm
;  :Contents.	Slave for "Star Glider 2"
;  :Author.	Graham, Wepl
;  :Original.	v1 1.05 EUR Graham
;		v2 1.03 USA Garry Cardinal <garryc@telusplanet.net>
;  :Version.	$Id: Starglider2.slave.asm 1.6 2005/07/12 20:16:06 wepl Exp wepl $
;  :History.	previous versions by Graham
;		12.06.05 support for v2 added
;		11.07.05 update 1.2 finished
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.16
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE whdmacros.i

	IFD	BARFLY
	OUTPUT	"wart:st/starglider2/Starglider2.Slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-				;disable optimizer warnings
	SUPER
	ENDC

RELOC_ENABLED = 1
CHIP_ONLY
;UNRELOC_ENABLED

	IFD	RELOC_ENABLED
RELOC_MEM = $67000
	ELSE
	; not relocated: slave is a debug slave
	; (I don't want to distribute a non-relocated slave)
CHIP_ONLY = 1
RELOC_MEM = 0
	ENDC
	
SOUNDMEMSIZE = $6e000

BASE_CHIP_SIZE = $80000

	IFD	CHIP_ONLY
CHIPMEMSIZE = BASE_CHIP_SIZE+SOUNDMEMSIZE+RELOC_MEM
FASTMEMSIZE = 0
	ELSE
CHIPMEMSIZE = BASE_CHIP_SIZE		;ws_BaseMemSize
FASTMEMSIZE = SOUNDMEMSIZE+RELOC_MEM
	IFND	UNRELOC_ENABLED
UNRELOC_ENABLED
	ENDC
	ENDC

; buffer used to load reloc & delta tables
; it's in chipmem but it doesn't matter much
AUX_BUFFER = $68000
V1_FILE_SIZE = 419308

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError		;ws_flags
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_data-_base			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$58			;ws_keyexit = F9
_expmem		dc.l	FASTMEMSIZE			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
_data
	dc.b	"data",0
_config
	dc.b	"C4:B:disable speed regulation;"
		dc.b	0

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

_name		dc.b	'Starglider 2'
		IFD	CHIP_ONLY
		dc.b	" (chip only)"
		ENDC
			dc.b	0
_copy		dc.b	'1988 Argonaut Software',0
_info		dc.b	'fixed and installed by Graham/Wepl/JOTD',10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_filename	dc.b	'Starglider2',0
_sound		dc.b	'Starglider2.sound',0
_delta	dc.b	"starglider2.delta",0
_reloc_v1	dc.b	"starglider2_v1.reloc",0
_unreloc_v1	dc.b	"starglider2_v1.unreloc",0
; not necessary, we're using wdelta
;_reloc_v2	dc.b	"starglider2_v2.reloc",0
_disk		dc.b	'Disk.'
_disknum	dc.b	0,0,0,0

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

	EVEN

;======================================================================
_start	;	A0 = resident loader
;======================================================================

	lea	(_resload,pc),a1
	move.l	a0,(a1)
	movea.l	a0,a2

	lea	(_tags,pc),a0
	jsr	(resload_Control,a2)
	bsr.w	_setdisknum

	IFD	CHIP_ONLY
	lea		_expmem(pc),a0
	move.l	#BASE_CHIP_SIZE,(a0)
	ENDC
	
	IFD	RELOC_ENABLED
	move.l	_expmem(pc),d0
	lea		_reloc_base(pc),a0
	add.l	d0,(a0)
	add.l	#RELOC_MEM,d0
	lea		_sound_base(pc),a0
	move.l	d0,(a0)
	ELSE
	lea		_sound_base(pc),a0
	move.l	_expmem(pc),(a0)
	ENDC
	
	; set CPU and cache options
	move.l	#WCPUF_Base_WT|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	resload_SetCPU(a2)

	
	lea	(_sound,pc),a0
	move.l	_sound_base(pc),a1
	jsr	(resload_LoadFileDecrunch,a2)
	
	; load the file again at the original location
	; so parts that need chip are there
	; in fastmem mode it's not possible to know if the chip
	; zone is accessed wrongly since there are exceptions
	lea	(_filename,pc),a0
	lea		$1000.W,a1
	jsr	(resload_LoadFileDecrunch,a2)
	;;move.l	d0,d5		; size of decrunched file
	move.l	#V1_FILE_SIZE/4,d5	; size of v1 decrunched file
	
	lea		$1000.W,a0
	move.l	#$1000,d0
	jsr	(resload_CRC16,a2)
	lea	pl_address(pc),a3
	lea	_pl1(pc),a0
	lea	$12602-$1000,a1		; minus base
	cmp.w	#$abeb,d0
	beq	.v1
	cmp.w	#$2a15,d0
	beq	.v1
	cmp.w	#$836f,d0		; v2 (older)
	beq	.v2
	pea	TDREASON_WRONGVER
	jmp	(resload_Abort,a2)
.v2
	IFD	RELOC_ENABLED
; convert to version 1 using wdelta, relocs are too time-consuming
; to redo
	movem.l	a0-a1,-(a7)
	lea		AUX_BUFFER,a1
	lea		_delta(pc),a0
	jsr		resload_LoadFileDecrunch(a2)
	; apply delta
	lea		$1000.W,a0
	move.l	_reloc_base(pc),a1
	lea		AUX_BUFFER,a2             ;wdelta	
	move.l	_resload(pc),a4		; using a2 isn't a good idea here :)
	jsr		resload_Delta(a4)
	move.l	a4,a2
	
	; delta was applied, now copy back to original location
	lea		$1000,a1
	move.l	_reloc_base(pc),a0
.copychip
	move.l	(a0)+,(a1)+
	subq.l	#1,d5
	bne.b	.copychip
	
	movem.l	(a7)+,a0-a1
	ELSE
	; no reloc, no delta no nothing
	lea	_pl2(pc),a0
	lea	$1119a,a1	
	ENDC
	
	bra.b	.cont
.v1
; just copy chip code into reloc
	IFD	RELOC_ENABLED
	movem.l	a0-a1,-(a7)
	lea		$1000,a0
	move.l		_reloc_base(pc),a1
.copy
	move.l	(a0)+,(a1)+
	subq.l	#1,d5
	bne.b	.copy
	movem.l	(a7)+,a0-a1
	ENDC
	
.cont
	add.l	_reloc_base(pc),a1
	lea	_cylinder(pc),a6
	move.l	a1,(a6)
	move.l	a0,(a3)
	

	IFD		RELOC_ENABLED
	
	lea		$1000.W,a1		; use $1000 for reloc table
	lea		_reloc_v1(pc),a0
	jsr		resload_LoadFileDecrunch(a2)

	; relocate
	move.l	_reloc_base(pc),a0
	lea		(-$1000,a0),a1	; reloc base -$1000
	move.l	a1,d1
	lea		$1000.W,a1
.reloc
	move.l	(a1)+,d0
	beq.b	.end
	add.l	d1,(a0,d0.l)
	bra.b	.reloc
.end

	IFD	UNRELOC_ENABLED
	; fastmem mode
	;
	; that's why the unreloc table is only applied in the case
	; of fastmem. In the case of CHIP_ONLY, all is relocated 
	; including audio, copper, sprites, and
	; it works since memory is chip.
	;
	; CHIP_ONLY still allows debug to check missed relocs:
	; add MMU protect on old program
	; winuae: w 0 $1000 $665ea

	
	; unrelocate
	; use $68000 (out of program memory) for unreloc table
	lea		AUX_BUFFER,a1
	lea		_unreloc_v1(pc),a0
	jsr		resload_LoadFileDecrunch(a2)
	
	; relocate
	move.l	_reloc_base(pc),a0
	lea		(-$1000,a0),a1	; reloc base -$1000
	move.l	a1,d1
	lea		AUX_BUFFER,a1
.unreloc
	move.l	(a1)+,d0
	beq.b	.endu
	; correct offsets
	sub.l	d1,(a0,d0.l)
	bra.b	.unreloc
.endu
	
	ENDC
	
	ENDC
	move.l	_reloc_base(pc),a1
	move.l	pl_address(pc),a0
	jsr	(resload_Patch,a2)

	move.l	_reloc_base(pc),-(a7)
	rts

_pl1	PL_START
	PL_W	2,$8001			;flags from loader set, mode without os
	
	PL_P	$2c10,_3c12		;protection
	PL_S	$be32,$4a-$32		;expmem check
	PL_S	$bed4,8			;illegal write icm
	PL_PSS	$d49e,_e49e,4		;protection
	PL_P	$ee10,_loaddata
	PL_P	$ee16,_savedata
	PL_PS	$efae,_loadgame
	PL_PS	$f124,_savegame1
	PL_S	$f2de,8			;dont skip sound prior first protection check
	PL_PS	$f34c,_setsoundptr
	PL_B	$f613,$ff		;sound already loaded
	PL_R	$f83e			;cia access
	PL_R	$f85e			;cia access
	PL_R	$f876			;cia access
	PL_B	$fad8,$60		;bsr -> bra, no disk read retry
	PL_L	$fc70,$70004E75		;insert disk
	PL_R	$fc96			;cia access
	PL_S	$fcca,$fce4-$fcca	;cia access
	PL_R	$fcfa			;cia access
	PL_P	$fde4,_format
	PL_L	$100f4,$70004E75	;disk access
	PL_S	$3bd00,$1a		;expmem check
	PL_IFC4
	PL_ELSE
	PL_PS	$0b6fe,_vbl_hook
	PL_PS	$002a0,_vbl_reg
	PL_ENDIF
	PL_END

_pl2	PL_START
	PL_W	2,$8001			;flags from loader set, mode without os
	PL_R	$249a			;setting color00
	PL_P	$2c04,_3c06		;protection
	PL_R	$b566			;regional check
	PL_S	$be00,$4a-$32		;expmem check
	PL_S	$bea2,8			;illegal write icm
	PL_R	$beb8			;setting color00
	PL_C	$c120,$50		;clear colors on startup
	PL_PSS	$d452,_e452,4		;protection
	PL_P	$edc4,_loaddata
	PL_P	$edca,_savedata
	PL_PS	$ef66,_loadgame
	PL_PS	$f0a6,_savegame2
	PL_S	$f260,8			;dont skip sound prior first protection check
	PL_PS	$f2ce,_setsoundptr
	PL_B	$f59b,$ff		;sound already loaded
	PL_R	$f79a			;cia access
	PL_R	$f7ba			;cia access
	PL_R	$f7d2			;cia access
	PL_B	$f9aa,$60		;bsr -> bra, no disk read retry
	PL_L	$fb26,$70004E75		;insert disk
	PL_R	$fb4c			;cia access
	PL_S	$fb80,$fce4-$fcca	;cia access
	PL_R	$fbb0			;cia access
	PL_P	$fc96,_format
;	PL_L	$100f4,$70004E75	;disk access
;	PL_S	$3bd00,$1a		;expmem check
	PL_END

_vbl_reg:    
    movem.l d0-d1/a0,-(a7)
    move.l #1,d1       ; the bigger the longer the wait
    lea _vbl_counter(pc),a0
    move.w  (a0),d0
    cmp.w   #10,d0
    bcc.b   .nowait     ; first time called/lost sync/pause/whatever
    ; wait till at least x vblanks passed after last zeroing
.wait
    cmp.w   (a0),d1
    bcc.b   .wait
.nowait
    clr.w   (a0)
    movem.l (a7)+,d0-d1/a0
	move.l	_reloc_base(pc),a6
	add.w	#$17be,a6
	move.l	(a6),a6	; original: move.l $27BE,a6
    rts
_vbl_hook
    lea _vbl_counter(pc),a0
    addq.w  #1,(a0)
	lea		_custom,a5		; original
	rts
_3c12
	move.l	a0,-(a7)
	move.l	_reloc_base(pc),a0
	add.l	#$14000,a0
	move.w	#$7000,($3C4,a0)	; 153C4...
	move.w	#$4213,($3D0,a0)
	move.w	#$7000,($488,a0)
	move.w	#$4213,($496,a0)
	move.w	#$7000,($54E,a0)
	move.w	#$4213,($55A,a0)
	move.l	_resload(pc),a0
	jsr		resload_FlushCache(a0)
	move.l	(a7)+,a0
	move.l	_reloc_base(pc),-(a7)
	add.l	#$142F2,(a7)
	rts

_e49e
	bsr	_3c12
	move.l	a0,-(a7)
	move.l	_reloc_base(pc),a0
	add.l	#$54DC8-$1000,a0
	clr.w	(a0)			;original
	move.l	(a7)+,a0
	rts

_3c06
	move.l	a0,-(a7)
	move.l	_reloc_base(pc),a0
	add.l	#$13000-$1000,a0
	move.w	#$7000,($c9a,a0)
	move.w	#$4213,($ca8,a0)
	move.l	_resload(pc),a0
	jsr		resload_FlushCache(a0)
	move.l	(a7)+,a0
	move.l	_reloc_base(pc),-(a7)
	add.l	#$12BFC,(a7)
	rts
	;jmp	($13bfc).l

_e452	bsr.b	_3c06
	move.l	a0,-(a7)
	move.l	_reloc_base(pc),a0
	add.l	#$5341c-$1000,a0
	clr.w	(a0)			;original
	move.l	(a7)+,a0
	rts

_setsoundptr	move.l	(a7)+,a0
		move.l	(a0)+,a1
		move.l	_sound_base(pc),(a1)
		jmp	(a0)

_getcyl		move.l	a0,-(a7)
		move.l	(_cylinder,pc),a0
		moveq	#0,d1
		move.w	(a0),d1
		move.l	(a7)+,a0
		rts

_loadgame	move.l	#$17ba*4,d0
		bsr	_getcyl
		addq.l	#1,d1
		mulu.w	#$1400,d1
		move.l	a0,a1				;destination
		lea	(_disk,pc),a0
		movea.l	(_resload,pc),a2
		jsr	(resload_LoadFileOffset,a2)
		moveq	#0,d0
		add.l	#$efd2-$efae-6,(a7)
		rts

_savegame1	sub.l	#$17ba*4,a1
		bra	_savegame

_savegame2	move.l	a0,a1

_savegame	move.l	#$17ba*4,d0
		bsr	_getcyl
		addq.l	#1,d1
		mulu.w	#$1400,d1
		lea	(_disk,pc),a0
		movea.l	(_resload,pc),a2
		jsr	(resload_SaveFileOffset,a2)
		add.l	#$f158-$f124-6,(a7)
		rts

_loaddata	lea	(_disk,pc),a0
		movea.l	(_resload,pc),a2
		jsr	(resload_GetFileSize,a2)
		tst.l	d0
		bne	.ok
		moveq	#-1,d0
		rts
		
.ok		move.l	#$1400,d0
		bsr	_getcyl
		mulu.w	d0,d1
		lea	(_disk,pc),a0
		lea	($7E000).l,a1
		jsr	(resload_LoadFileOffset,a2)
		moveq	#0,d0
		rts

_savedata	move.l	#$1400,d0
		bsr	_getcyl
		mulu.w	d0,d1
		lea	(_disk,pc),a0
		lea	($7E000).l,a1
		movea.l	(_resload,pc),a2
		jsr	(resload_SaveFileOffset,a2)
		moveq	#0,d0
		rts

_format		move.l	#$1400,d0
		lea	(_disk,pc),a0
		lea	($7e000),a1
		movea.l	(_resload,pc),a2
		jsr	(resload_SaveFile,a2)
		moveq	#0,d0
		rts

_setdisknum	movem.l	d0/a0,-(sp)
	move.l	(_custom1,pc),d0
	cmp.l	#999,d0
	bls.b	lbC000334
	moveq	#1,d0
lbC000334	lea	(_disknum,pc),a0
	divu.w	#100,d0
	tst.w	d0
	beq.b	lbC000346
	ori.b	#$30,d0
	move.b	d0,(a0)+
lbC000346	sub.w	d0,d0
	swap	d0
	divu.w	#10,d0
	tst.w	d0
	beq.b	lbC000358
	ori.b	#$30,d0
	move.b	d0,(a0)+
lbC000358	sub.w	d0,d0
	swap	d0
	ori.b	#$30,d0
	move.b	d0,(a0)+
	clr.b	(a0)
	movem.l	(sp)+,d0/a0
	rts

_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	0
_cylinder	dc.l	0
_reloc_base
	dc.l	$1000
_sound_base
	dc.l	0
_vbl_counter
	dc.w	0
pl_address
	dc.l	0
	end
