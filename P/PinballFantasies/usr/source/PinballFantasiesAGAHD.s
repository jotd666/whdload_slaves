;*---------------------------------------------------------------------------
;  :Program.	PinballFantasiesHD.asm
;  :Contents.	Slave for "PinballFantasies"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: PinballFantasiesHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"PinballFantasies.slave"
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

;============================================================================

    IFD FAST_SLAVE
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $100000
    ELSE
CHIPMEMSIZE	= $1FF000
FASTMEMSIZE	= $0000	; just for OS memory
    ENDC
    
NUMDRIVES	= 1
WPDRIVES	= %0000

;BLACKSCREEN
;DISKSONBOOT
;DOSASSIGN
;DEBUG	: with it nonvolatile.lib fails
HDINIT
;HRTMON
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
BOOTDOS
CACHE
;CBDOSLOADSEG
FONTHEIGHT = 8

;============================================================================


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_ReqAGA|WHDLF_Req68020|WHDLF_Examine|WHDLF_ClearMem
slv_keyexit	= $5D	; num '*'

;============================================================================

	INCLUDE	kick31cd32.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

DECL_VERSION:MACRO
	dc.b	"3.2"
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

slv_name		dc.b	"Pinball Fantasies CD³²/AGA"
    IFND    FAST_SLAVE
    dc.b    " (no fast)"
    ENDC
    dc.b    0
slv_copy		dc.b	"1994 21st Century Entertainment",0
slv_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0


	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
slv_config		
	dc.b	"C1:B:skip introduction (CD32);"
	dc.b	0	
	even

_program:
	dc.b	"Pinball",0
_args		dc.b	10
_args_end
	dc.b	0

	IFD	FAST_SLAVE
mem_message:
	dc.b	"Sorry you have expansion mem at $7Fxxxxxx,",10
	dc.b	"Please replace by the AGACHIP slave.",10
	dc.b	"Or use allocate tool for aminet to allocate block",10
	dc.b	0
	ENDC
	EVEN

;============================================================================

	;initialize kickstart and environment

_bootdos
	clr.l	$0.W
	bsr	_patch_cd32_libs

	IFD	FAST_SLAVE
	move.b	_expmem(pc),d0
	btst	#7,d0
	beq.b	.skip
	; expmem has 31-bit set: no way, can't do
	pea	mem_message(pc)
	pea	TDREASON_FAILMSG
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
.skip

	; lookup for a zeroed bit on expmem MSB to replace
	; the $1E (30) value that the game uses and which is
	; for instance incompatible with my expmem location ($79xxxxxx)

	move.l	#6,d1
.loop
	btst	d1,d0
	dbeq.b	d1,.loop

	tst.b	d1
	bmi	msb_7f	; MSB is $7F: it exists!!

	add.b	#24,d1
	lea	_freebit(pc),a0
	move.b	d1,(a0)

	lea	_mask(pc),a0
	move.b	d0,(a0)		; store MSB of fastmem in mask

	; patch ROM!! this is ugly but can't be avoided
    ; or we would have to re-implement LoadSeg relocation ourselves
    ; (done in OSEmu code but I'd rather not dig that one out)
    ; we have to detect A1200 / A4000 ROM
	move.l	_expmem(pc),a1
	add.l	#$26F9C,a1
    cmp.l   #$d7b21800,(a1) ; long expected for A1200 3.1 rom
    beq.b   .patchrom
    ; it has to be A4000 3.1 rom
	move.l	_expmem(pc),a1
	add.l	#$1d3c4,a1
    cmp.l   #$d7b21800,(a1) ; long expected for A1200 3.1 rom
    beq.b   .patchrom
    illegal     ; can't happen since only 2 ROMS are supported by kickemu
.patchrom
	move.l	#$4EB80124,(A1)
	patch	$124,_preloc

	bsr	_flushcache
	ENDC
	
	move.l	(_resload,pc),a2		;A2 = resload

	;open doslib
	lea	(_dosname,pc),a1
	move.l	(4),a6
	jsr	(_LVOOldOpenLibrary,a6)
	move.l	d0,a6			;A6 = dosbase
    lea _the_dosbase(pc),a0
    move.l  d0,(a0)

	;load exe
    lea	_program(pc),a0
    movem.l a0,-(a7)
    jsr (resload_GetFileSize,a2)
    lea _version(pc),a0
    cmp.l   #6724,d0
    bne.b   .noaga_47
; aga SPS0047
    move.l  #0,(a0)
    bra.b   .cont
.noaga_47    
    cmp.l   #6732,d0
    bne.b   .noaga_2025
; aga SPS2025
    move.l  #1,(a0)
    bra.b   .cont
.noaga_2025
    cmp.l   #4348,d0
    bne.b   .nocd32
    move.l  #2,(a0)
    bra.b   .cont
.nocd32    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.cont
    movem.l (a7)+,a0
    move.l	a0,d1
    jsr	(_LVOLoadSeg,a6)
    move.l	d0,d7			;D7 = segment
    beq	_end			;file not found

	;patch here
    
    
    move.l  _version(pc),d0
	lea	patch_table(pc),a1
	add.w   d0,d0
    lea patch_table(pc),a0
    add.w  (a1,d0.w),a0
    move.l	d7,a1
    jsr (resload_PatchSeg,a2)
    
	;call
    move.l	d7,a1
    add.l	a1,a1
    add.l	a1,a1
    lea	(_args,pc),a0
    move.l	(4,a7),d0		;stacksize
    sub.l	#5*4,d0			;required for MANX stack check
    movem.l	d0/d7/a2/a6,-(a7)
    moveq	#_args_end-_args,d0
    jsr	(4,a1)
    movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
    move.l	d7,d1
    jsr	(_LVOUnLoadSeg,a6)

	;quit
_quit	
    pea	TDREASON_OK
	move.l	(_resload,pc),a2
	jmp	(resload_Abort,a2)

_end
	jsr	(_LVOIoErr,a6)
	pea	_program(pc)
	move.l	d0,-(a7)
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

	IFD	FAST_SLAVE

msb_7f
	pea	mem_message(pc)
	pea	TDREASON_FAILMSG
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts
	ENDC
	
patch_table:
    dc.w    _pl_aga-patch_table
    dc.w    _pl_aga-patch_table
    dc.w    _pl_cd32-patch_table
		


_pl_aga
	PL_START
	PL_R    $220	; skip protection on AGA version

    PL_NOP  $06cc,4  ; remove cache turn off
    PL_NOP  $06dc,4  ; remove delay of 1 second or such
    PL_NOP  $06fe,4  ; remove delay of 1 second or such

    PL_PSS  $684,_which_table_is_it,2
    ;;PL_PSS  $6a8,_which_table_is_it,2

    PL_PS   $06e8,_patch_table

	PL_END

_pl_cd32:
	PL_START
    PL_L    $3ae,$4E717000      ; VBR => 0
    PL_IFC1
    PL_NOP  $5B8,4
    PL_ELSE
    PL_PS   $5a8,_patch_intro
    PL_ENDIF
    
    PL_PSS  $6FA,_which_table_is_it,2
    
    PL_PS   $470,_patch_music
    PL_PS   $5E4,_patch_menu
    
    PL_NOP  $71c,4  ; remove cache turn off
    PL_NOP  $72c,4  ; remove delay of 1 second or such
    PL_NOP  $75a,4  ; remove delay of 1 second or such
    PL_PS   $738,_patch_table
	PL_END

_which_table_is_it
    ; d1 holds table name
    ; depending on the table name, a different value must be put
    ; in the sprite color register ... I don't remember how I found that out either...
    ; and why it doesn't work right out of the box
    move.l  d1,a0
    cmp.b   #'B',(7,a0)
    bne.b   .not_speed_devils
	move.w	#$00BB,$DFF10C		; fixes gfx bugs on sprite (ball, level 2)    
    bra.b   .loadseg
.not_speed_devils
	move.w	#$0044,$DFF10C		; fixes gfx bugs on sprite (ball, all other tables)
.loadseg
	MOVEA.L	_the_dosbase(pc),A6		;6fa: 2c6d000c
	jmp	(_LVOLoadSeg,A6)	; we'll patch it later
    
_patch_table
	move.w	#$0000,$DFF1FC		; fixes gfx bugs on tables (fmode = ECS)
	move.w	#$0000,$DFF106		; fixes gfx bugs on tables


	ADDA.L	A0,A0			;5e4: d1c8

    
    movem.l d0-d1/a0-a2,-(a7)
    ; now try to find which table it is
    addq.l  #4,a0
    bsr _get_table_id
    move.l  a0,a1
    move.l  _resload(pc),a2
    movem.l a1,-(a7)
    lea _pl_table_common(pc),a0
    jsr (resload_Patch,a2)
    movem.l (a7)+,a1
    
    ; a1: first segment + offset (ntsc)
    add.l   _patch_offset(pc),a1
    
    IFD FAST_SLAVE

	patch	$100,_p100
	patch	$106,_p106
	patch	$10C,_p10C
	patch	$112,_p112
	patch	$118,_p118
	patch	$11E,_p11E
    
    ENDC
    
    lea _pl_table_123(pc),a0
    move.l  _is_table_4(pc),d0
    beq.b   .p1
    lea _pl_table_4(pc),a0
	IFD	FAST_SLAVE
	move.b	_freebit(pc),$42F3(a1)
	move.b	_freebit(pc),$43BF(a1)
    ENDC
    bra.b   .p    
.p1
	IFD	FAST_SLAVE
	; change position of the #30 bit
	move.b	_freebit(pc),$42ED(a1)
	move.b	_freebit(pc),$43B9(a1)
    ELSE
    nop
    ENDC

.p
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
    jsr (4,a0)
    rts

_get_table_id
    lea _patch_offset(pc),a1
    clr.l   (a1)
    lea _is_table_4(pc),a1
    clr.l   (a1)
    move.l  #$0881001e,d0
	cmp.l	$42EA(a0),d0
	beq.b	.table_pal
	cmp.l	$42EA+6(a0),d0
	beq.b	.table_ntsc
    move.l  #1,(a1) ; probably table 4
	cmp.l	$42F0(a0),d0
	beq.b	.table_pal
	cmp.l	$42F0+6(a0),d0
	beq.b	.table_ntsc
    
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
    
.table_pal
    rts
.table_ntsc
    lea _patch_offset(pc),a1
    move.l  #6,(a1)
    rts
    
    
_patch_menu
	ADDA.L	A0,A0			;5e4: d1c8
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    move.l  a0,a1
    addq.l  #4,a1
    ; a1: first segment
    lea _pl_cd32_menu(pc),a0
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
    jmp (4,a0)
    

    
_patch_music:
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    move.l  a0,a1
    ; a1: first segment
    lea _pl_cd32_music(pc),a0
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
	MOVE.L	A0,(A5)			;470: 2a88
	MOVEQ	#40,D0			;472: 7028
	JMP	(A0)			;474: 4e90    
    
_patch_intro  
	CMPA.L	#$0,A0		;: b0fc0000
	BNE.S	.ok		;5ac: 6728
    add.l   #$D6-$AE,(a7)
    rts
.ok
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    move.l  a0,a1
    add.l   a1,a1
    add.l   a1,a1
    addq.l  #4,a1
    ; a1: first segment
    lea _pl_cd32_intro(pc),a0
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
    rts

; nothing to do, just empty patch for intro
_pl_cd32_intro:
	PL_START
    PL_END
    
_pl_cd32_music:
	PL_START
    PL_PSS  $3E6,_fix_dma_sound,2
    PL_PSS  $b2e,_fix_dma_sound,2
    ;PL_PS   $00442,_fix_dma_sound_2
    ;PL_PS   $00196,_fix_dma_sound_2
    ;PL_P   $00098,_fix_dma_sound_3
    PL_END
    
_pl_cd32_menu:
	PL_START
    ; leave VBR to 0
    PL_B    $012,$60
    ; remove LMB => call exec.Debug (and locks up)!!
    PL_S    $0e18a,$20
    PL_END
    
_fix_dma_sound_2
    MOVE.W	d0,_custom+dmacon
    bra.b   _dma_sound_wait
_fix_dma_sound_3
    MOVE.W	#$F,_custom+dmacon
    bra.b   _dma_sound_wait
    
_fix_dma_sound:
    MOVE.W	(30,A6),_custom+dmacon
_dma_sound_wait:
	move.w  d0,-(a7)
	move.w	#4,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	move.w	(a7)+,d0
    rts

_pl_table_common
    PL_START
    PL_B    $00c6,$60       ; skip VBR read, leave to 0    
    PL_END
    
    
	IFND	FAST_SLAVE
_pl_table_123:
_pl_table_4:
	PL_START
	PL_END
   
    ELSE
_pl_table_123:
	PL_START
	PL_L	$4348,$4EB80100
	PL_L	$4404,$4EB80100
	PL_L	$433A,$4EB80106
	PL_L	$43F6,$4EB80106
	PL_L	$43E8,$4EB8010C
	PL_L	$4334,$4EB80112
	PL_L	$43EE,$4EB80112
	PL_L	$4340,$4EB80118
	PL_L	$43FC,$4EB80118
	PL_L	$431C,$4EB8011E
	PL_L	$43E0,$4EB8011E
	PL_END

_pl_table_4:
	PL_START
	PL_L	$434E,$4EB80100
	PL_L	$440A,$4EB80100
	PL_L	$4340,$4EB80106
	PL_L	$43FC,$4EB80106
	PL_L	$43EE,$4EB8010C
	PL_L	$433A,$4EB80112
	PL_L	$43F4,$4EB80112
	PL_L	$4346,$4EB80118
	PL_L	$4402,$4EB80118
	PL_L	$4322,$4EB8011E
	PL_L	$43E6,$4EB8011E
	PL_END


MASKIT:MACRO
	move.l	d0,-(a7)
	move.l	a3,d0
	and.l	_mask(pc),d0
	move.l	d0,a3
	move.l	(a7)+,d0
	ENDM


    
; patch dos.library relocation
; I don't remember what it does, but it probably
; only changes a special kind of reloc, else it would
; trash all other addresses and also menu, intro...
; since LoadSeg code is changed globally...
; anyway it works great... damn I wish i had commented that
; back in the day...
_preloc
	movem.l	D0/D2,-(A7)
	move.l	(0,A2,D1.L),d2
    ; replace bit 30 when set by the free bit
	bclr	#30,d2
	beq.b	.skip
	moveq	#0,d0
	move.b	_freebit(pc),d0
	bset	D0,D2
	move.l	D2,(0,A2,D1.L)
.skip
	add.l	D3,(0,A2,D1.L)
	movem.l	(a7)+,d0/d2
	rts

_p100
	MASKIT
        BCLR    D6,48(A3)               ;04348: 0DAB0030        ; FIX1
	RTS

_p106
	MASKIT
        BTST    D6,48(A3)               ;043F6: 0D2B0030        ; FIX1
	RTS

_p10C
	MASKIT
        CMPI.B  #$1E,(A3)               ;043E8: 0C13001E        ; FIX1
	RTS

_p112
	MASKIT
        CMPI.B  #$1F,(A3)               ;04334: 0C13001F        ; FIX1
	RTS

_p118:
	MASKIT
        CMPI.B  #$FE,1(A3)              ;04340: 0C2B00FE0001    ; FIX1
	RTS

_p11E:
	MASKIT
        OR.B    D7,48(A3)               ;0431C: 8F2B0030        ; FIX1
	RTS

	


; MSB mask

_mask:
	dc.l	$FFFFFFFF

; position of a zero bit for expmem MSB

_freebit:
	dc.w	0
    ENDC
_patch_offset
    dc.l    0
_is_table_4
    dc.l    0
_version
    dc.l    0
_the_dosbase
    dc.l    0
    