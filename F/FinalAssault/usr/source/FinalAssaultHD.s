;*---------------------------------------------------------------------------
;  :Program.	BoppinHD.asm
;  :Contents.	Slave for "Boppin"
;  :Author.	JOTD, from Wepl sources
;  :Original	v1 
;  :Version.	$Id: BoppinHD.asm 1.2 2002/02/08 01:18:39 wepl Exp wepl $
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
	OUTPUT	"FinalAssault.slave"
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
CHIPMEMSIZE	= $C0000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $40000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000

;DISKSONBOOT
DOSASSIGN
;INITAGA
HDINIT
IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
;SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHECHIPDATA
SEGTRACKER


slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
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

assign1:
	dc.b	"Final Assault",0

slv_name		dc.b	"Final Assault / Bivouac / Chamonix Challenge"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
slv_copy		dc.b	"1987-1988 Inforgrames / Epyx",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

program:
	dc.b	"biv",0
args		dc.b	10
args_end
	dc.b	0
slv_config
	dc.b    "BW;"
	dc.b    "C5:B:disable fast cpu fixes;"
	dc.b	0

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

_bootdos
		clr.l	$0.W

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

	
	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase
	;assigns
		lea	assign1(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

    IFD CHIP_ONLY
    move.l  a6,-(a7)
    move.l  4,a6
    move.l  #$20000-$0001BBA8-$138,d0
    move.l  #MEMF_CHIP,d1
    jsr     _LVOAllocMem(a6)
    move.l  (a7)+,a6
    ENDC
    
	;load exe
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_main(pc),a5
		bsr	load_exe
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)


    

; < D1: number of ticks
vbl_reg:    
    movem.l d0/a0-a1,-(a7)
    lea vbl_counter(pc),a0
    move.l  (a0),d0
    cmp.l   #10,d0
    bcc.b   .nowait     ; first time called/lost sync/pause/whatever
    ; wait till at least x vblanks passed after last zeroing
.wait
    cmp.l   (a0),d1
    bcc.b   .wait
.nowait
    clr.l   (a0)
    movem.l (a7)+,d0/a0-a1
    rts
    
    
new_level3_interrupt
    movem.l d0/a0,-(a7)
    move.w  _custom+intreqr,d0
    btst    #5,d0
    beq.b   .novbl
    ; vblank interrupt, read joystick/mouse
    ;;bsr _joystick
    ; add to counter
    lea vbl_counter(pc),a0
    addq.l  #1,(a0)
.novbl
    movem.l (a7)+,d0/a0
    move.l  old_level3_interrupt(pc),-(a7)
    rts
    

; < d7: seglist (BPTR)
; 3 versions are supported
; - french cracked
; - english cracked
; - english protected (same version as cracked once decrypted)
patch_main
	bsr	get_version
	lea	patch_table(pc),a1
    cmp.l   #3,d0
    beq.b   english_encrypted
    cmp.l   #4,d0
    beq   english_encrypted_2
	add.w   d0,d0
    lea patch_table(pc),a0
    add.w  (a1,d0.w),a0
        
    move.l  d7,a1
    move.l  _resload(pc),a2
    jsr resload_PatchSeg(a2)

    bsr save_first_segment


    rts
    

; how to intercept decrpytion on winuae: it's pretty simple
; first boot the original IPF/RAW game and right away use
; f $1D000 $70000
; so first time program is called (not ROM or libs or runback) it stops
; if mem is too low you stumble on "runback" program
; on english_encrypted_2 version, it stops (most of the time) at 1DBA8 
; and jumps to TVD at 2D1B8
; to fix addresses, better make a snapshot when game is loading, as it's kind
; of random
;
; use a memory watchpoint to see when the JSR location is changed
; (w 0 $1DBAC 2 W)
; The location has changed to reflect the new TVD decryption routine, which is not
; decrypted yet. Put a memwatch there and you'll intercept the first decryption
;
;0002d40c b150                     eor.w d0,(a0) [48e7]
;0002d40e 51cb fff4                dbf.w d3,#$fff4 == $0002d404 (F)
;0002d412 60dc                     bra.b #$dc == $0002d3f0 (T)
;
; a few bytes earlier you stumble on the tables init
;
;0002d5a0 246d 001a                movea.l ($001a,a5) == $0002d6ea [000185b8],a2
;0002d5a4 3400                     move.w d0,d2
; the key in D0 has already changed hence the snapshot feature. Now you know
; where to add a breakpoint to get the value of the key as load address doesn't change
; (can be done with a calculation but it's not very convenient)
; 0002d5b6 43fa fbe0                lea.l (-$0420,pc) == $0002d198,a1 => this is the key list
; length of key data is $540 (starts by assign + Ben Herdnon copyright text)

; do "f $1D000 $1E000" again to catch the second decryption start
; you end up at the same address (but the data is different)
; in the end the program start is at 1DB48
;
; DECRYPT_PASS  arg1,arg2,arg3
; arg1: pass number (for different routines)
; arg2: offset of the JSR for startup once decrypted (decrypted jsr - start jsr)	

    
DECRYPT_PASS:MACRO
us_encrypted_start_\1:
	MOVEA.L	first_segment(pc),A0		;2fa86: 206d0024    ; start ($20000)
    move.l  a0,d0
    add.l   #\2,d0
    move.l  d0,(2,a0)       ; adjust jump/jsr of the decrypted startup
    ; now decrypt the rest of the executable
	lea decrypt_offset_len_table_\1(pc),A2		;2fa78: this table isn't in clear at start, we ripped it
	MOVE.W	#\3,D2			;2fa7c: this key was ripped too
	MOVEQ	#0,D0			;2fa7e: 7000
	MOVEQ	#0,D3			; changes nothing...
    
    ; final decryption of the code (A500 std config code at $1FBF8, start $10178)
    ; D2 = $66CB
.LAB_000B:
	MOVE.W	(A2)+,D0		;2fa80: 301a
	MOVE.W	(A2)+,D3		;2fa82: 361a
	BEQ.S	.LAB_000D		;2fa84: 671e
	MOVEA.L	first_segment(pc),A0		;2fa86: 206d0024    ; start ($20000)
	ADDA.L	D0,A0			;2fa8a: d1c0
	ADDA.L	D0,A0			;2fa8c: d1c0
	lea decrypt_keys_\1(pc),A1		;2fa86: 206d0024
	SUBQ.W	#2,D3			;2fa92: 5543
.LAB_000C:
	MOVE.W	(A0)+,D0		;2fa94: 3018
	MOVE.B	(A1)+,D1		;2fa96: 1219
	EOR.W	D2,D0			;2fa98: b540
	EOR.B	D1,D0			;2fa9a: b300
	EOR.W	D0,(A0)			;2fa9c: b150
	DBF	D3,.LAB_000C		;2fa9e: 51cbfff4
	BRA.S	.LAB_000B		;2faa2: 60dc
.LAB_000D
    ENDM

; executable is encrypted, and the encrypted executable is
; encrypted a second time (same tool), so it needs 2 almost identical
; passes to decrypt
english_encrypted
    move.l  d7,-(a7)
    ; save segment (encrypted version will need it)
    bsr save_first_segment

    DECRYPT_PASS    1,$F130,$66CB
    DECRYPT_PASS    2,$E99C,$5D7C
    move.l  (a7)+,a1
    lea pl_english(pc),a0
    move.l  _resload(pc),a2
    jsr resload_PatchSeg(a2)
    rts
    
english_encrypted_2
    move.l  d7,-(a7)
    ; save segment (encrypted version will need it)
    bsr save_first_segment
    
    DECRYPT_PASS    3,$1cc58-$DB48,$31D6
    DECRYPT_PASS    4,$1c4d2-$DB48,$D77B
    move.l  (a7)+,a1
	lea pl_english_2(pc),a0
    move.l  _resload(pc),a2
    jsr resload_PatchSeg(a2)
    rts
    
   
patch_table:
    dc.w    pl_english-patch_table
    dc.w    pl_french-patch_table
    dc.w    pl_chamonix_2281-patch_table

pl_english
    PL_START
    PL_PSS  $0e51e,dma_sound_wait_1,2
    PL_PSS  $0e530,dma_sound_wait_2,2
    PL_IFC5
    PL_ELSE
    PL_PSS  $016D6,speed_regulation_game_english,2
    PL_PS   $0c386,speed_regulation_preparation_english
    PL_PS   $0c462,speed_regulation_preparation_english
    PL_ENDIF
    PL_IFBW
    PL_PSS   $0c01c,after_title_english,4
    PL_ENDIF
    PL_END
    
pl_english_2:
    PL_START
    PL_PSS  $e50c,dma_sound_wait_1,2
    PL_PSS  $e51e,dma_sound_wait_2,2
    PL_IFC5
    PL_ELSE
    PL_PSS  $016D6,speed_regulation_game_english,2
    PL_PS   $0c36e,speed_regulation_preparation_english
    PL_PS   $0c44a,speed_regulation_preparation_english
    PL_ENDIF
    PL_IFBW
    PL_PSS   $0c004,after_title_english,4
    PL_ENDIF
    PL_END
    
pl_french
    PL_START
    PL_PSS  $0e2f2,dma_sound_wait_1,2
    PL_PSS  $0e304,dma_sound_wait_2,2
    PL_IFC5
    PL_ELSE
    PL_PSS  $01730,speed_regulation_game_french,2
    PL_PS   $0c0fa,speed_regulation_preparation_french
    PL_PS   $0c1d6,speed_regulation_preparation_french
    PL_ENDIF
    PL_IFBW
    PL_PSS   $0bd90,after_title_french,4
    PL_ENDIF
    PL_END
    
pl_chamonix_2281
    PL_START
    PL_PSS  $0e3ba,dma_sound_wait_1,2
    PL_PSS  $0e3cc,dma_sound_wait_2,2
    PL_IFC5
    PL_ELSE
    PL_PSS  $016b8,speed_regulation_game_chamonix,2
    PL_PS   $0c1c2,speed_regulation_preparation_chamonix
    PL_PS   $0c29e,speed_regulation_preparation_chamonix
    PL_ENDIF
    PL_IFBW
    PL_PSS   $0be58,after_title_chamonix,4
    PL_ENDIF
    PL_END

save_first_segment:
    lea first_segment(pc),a2
    add.l   d7,d7
    add.l   d7,d7
    addq.l  #4,d7
    move.l  d7,(a2)
    IFD CHIP_ONLY
    move.l  d7,$100.W
    ENDC
    rts

after_title_english
	PEA	voies_string(PC)		;0bd90: 487a05e4
	JSR	-32110(A4)		;0bd94: 4eac8282
	ADDQ.W	#4,A7			;0bd98: 584f
    bra.b   wait_both_fire
    
after_title_chamonix
	PEA	voies_string(PC)		;0bd90: 487a05e4
	JSR	-32118(A4)		;0bd94: 4eac8282
	ADDQ.W	#4,A7			;0bd98: 584f
    bra.b   wait_both_fire
   
after_title_french
	PEA	voies_string(PC)		;0bd90: 487a05e4
	JSR	-32126(A4)		;0bd94: 4eac8282
	ADDQ.W	#4,A7			;0bd98: 584f
wait_both_fire:
.loop1
	btst	#7,$BFE001
	beq.b	.loop1
	btst	#6,$BFE001
	beq.b	.loop1
.loop2
	btst	#6,$BFE001
	beq.b	.out
	btst	#7,$BFE001
	bne.b	.loop2
.out
	rts
    
speed_regulation_preparation_french
    movem.l d1,-(a7)    
    moveq.l #2,d1
    bsr vbl_reg
    movem.l (a7)+,d1
	MOVE.B	-11124(A4),D3		;0c386: 162cd4c0
	EXT.W	D3			;0c38a: 4883
    rts
    
speed_regulation_game_french
    movem.l d1,-(a7)    
    moveq.l #1,d1
    bsr vbl_reg
    movem.l (a7)+,d1
    
    ; original game code
	TST.W	-11374(A4)		;016d6: 4a6cd3c6
    BEQ.W	.out		;016da: 660001aa
    add.l   #$886-$6DC,(a7) ; emulate BNE
.out
    rts
 
speed_regulation_preparation_chamonix
    movem.l d1,-(a7)    
    moveq.l #2,d1
    bsr vbl_reg
    movem.l (a7)+,d1
	MOVE.B	-11080(A4),D3		;0c386: 162cd4c0
	EXT.W	D3			;0c38a: 4883
    rts
   
speed_regulation_game_chamonix
    movem.l d1,-(a7)    
    moveq.l #1,d1
    bsr vbl_reg
    movem.l (a7)+,d1
    
    ; original game code
	TST.W	-11330(A4)		;016d6: 4a6cd3c6
    BEQ.W	.out		;016da: 660001aa
    add.l   #$886-$6DC,(a7) ; emulate BNE
.out
    rts
   
speed_regulation_preparation_english
    movem.l d1,-(a7)    
    moveq.l #2,d1
    bsr vbl_reg
    movem.l (a7)+,d1
	MOVE.B	-11072(A4),D3		;0c386: 162cd4c0
	EXT.W	D3			;0c38a: 4883
    rts
    
speed_regulation_game_english
    movem.l d1,-(a7)    
    moveq.l #1,d1
    bsr vbl_reg
    movem.l (a7)+,d1
    
    ; original game code
	TST.W	-11322(A4)		;016d6: 4a6cd3c6
    BEQ.W	.out		;016da: 660001aa
    add.l   #$886-$6DC,(a7) ; emulate BNE
.out
    rts
    
dma_sound_wait_1:
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
dma_sound_wait_2:
	move.w  d0,-(a7)
	move.w	#2,d0
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
	
get_version:
	movem.l	d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	cmp.l	#85804,D0
	beq.b	.english_noprotection

	cmp.l	#85156,d0
	beq.b	.french_noprotection

	cmp.l	#83488,d0
	beq.b	.us_encrypted_chris

	cmp.l	#88524,d0
	beq.b	.us_encrypted

	cmp.l	#85428,d0
	beq.b	.chamonix_noprotection

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.english_noprotection
	moveq	#0,d0
	bra.b	.out
.french_noprotection
	moveq	#1,d0
	bra.b	.out
.chamonix_noprotection
	moveq	#2,d0
	bra.b	.out
.us_encrypted
	moveq	#3,d0
	bra	.out
.us_encrypted_chris
	moveq	#4,d0
	bra	.out
.out
	movem.l	(a7)+,d1/a1
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

first_segment
    dc.l    0
    
old_level3_interrupt
    dc.l    0
vbl_counter
    dc.l    0
        
decrypt_offset_len_table_1:
     dc.w   $0003,$0536,$0539,$0536,$0A6F,$0536,$0FA5,$0536
     dc.w   $14DB,$0536,$1A11,$0536,$1F47,$0536,$247D,$0536
     dc.w   $29B3,$0536,$2EE9,$0536,$341F,$0536,$3955,$0536
     dc.w   $3E8B,$0536,$43C1,$0536,$48F7,$0536,$4E2D,$0536
     dc.w   $5363,$0536,$5899,$0536,$5DCF,$0536,$6305,$0428
     dc.w   $6735,$000D,$674B,$0058,$67A5,$012C,$68D7,$000A
     dc.w   $68E6,$0011,$68F9,$0006,$6907,$001E,$6927,$0014
     dc.w   $6940,$013A,$6A80,$0005,$6A8D,$0046,$6AD5,$0006
     dc.w   $6ADD,$0008,$6AED,$0011,$6B00,$0007,$6B09,$0049
     dc.w   $6B54,$000F,$6B69,$0029,$6B94,$0019,$6BAF,$008C
     dc.w   $6C3D,$0005,$6C44,$001A,$6C64,$000B,$6C71,$0006
     dc.w   $6C79,$0008,$6C8C,$0009,$6CA0,$0015,$6CBE,$0006
     dc.w   $6CCE,$0010,$6CE0,$000F,$6CF1,$001B,$6D26,$000F
     dc.w   $6D37,$0025,$6D5E,$0007,$6D6A,$0010,$6D7C,$0012
     dc.w   $6D99,$005F,$6E18,$0056,$6E73,$0021,$6E9B,$0119
     dc.w   $6FC7,$0101,$70CA,$0008,$70D4,$0097,$716D,$001D
     dc.w   $718C,$0006,$7194,$0006,$719C,$0006,$71A4,$000B
     dc.w   $71B1,$001D,$71D3,$000C,$71E1,$0058,$723B,$000F
     dc.w   $724C,$0033,$7281,$00FF,$7382,$0040,$73C4,$0031
     dc.w   $73F7,$0536,$792D,$01FA,$7B29,$000F,$0000,$0000

decrypt_offset_len_table_2:
     dc.w   $0003,$0536,$0539,$0536,$0A6F,$0536,$0FA5,$0536
     dc.w   $14DB,$0536,$1A11,$0536,$1F47,$0536,$247D,$0536
     dc.w   $29B3,$0536,$2EE9,$0536,$341F,$0536,$3955,$0536
     dc.w   $3E8B,$0536,$43C1,$0536,$48F7,$0536,$4E2D,$0536
     dc.w   $5363,$0536,$5899,$0536,$5DCF,$0536,$6305,$0428
     dc.w   $6735,$000D,$674B,$0058,$67A5,$012C,$68D7,$000A
     dc.w   $68E6,$0011,$68F9,$0006,$6907,$001E,$6927,$0014
     dc.w   $6940,$013A,$6A80,$0005,$6A8D,$0046,$6AD5,$0006
     dc.w   $6ADD,$0008,$6AED,$0011,$6B00,$0007,$6B09,$0049
     dc.w   $6B54,$000F,$6B69,$0029,$6B94,$0019,$6BAF,$008C
     dc.w   $6C3D,$0005,$6C44,$001A,$6C64,$000B,$6C71,$0006
     dc.w   $6C79,$0008,$6C8C,$0009,$6CA0,$0015,$6CBE,$0006
     dc.w   $6CCE,$0010,$6CE0,$000F,$6CF1,$001B,$6D26,$000F
     dc.w   $6D37,$0025,$6D5E,$0007,$6D6A,$0010,$6D7C,$0012
     dc.w   $6D99,$005F,$6E18,$0056,$6E73,$0021,$6E9B,$0119
     dc.w   $6FC7,$0101,$70CA,$0008,$70D4,$0097,$716D,$001D
     dc.w   $718C,$0006,$7194,$0006,$719C,$0006,$71A4,$000B
     dc.w   $71B1,$001D,$71D3,$000C,$71E1,$0058,$723B,$000F
     dc.w   $724C,$0033,$7281,$00FF,$7382,$0040,$73C4,$0031
     dc.w   $73F7,$0491,$0000,$0000
    
decrypt_offset_len_table_3:
	dc.w	$0003,$0536,$0539,$0536,$0A6F,$0536,$0FA5,$0536
	dc.w	$14DB,$0536,$1A11,$0536,$1F47,$0536,$247D,$0536
	dc.w	$29B3,$0536,$2EE9,$0536,$341F,$0536,$3955,$0536
	dc.w	$3E8B,$0536,$43C1,$0536,$48F7,$0536,$4E2D,$0536
	dc.w	$5363,$0536,$5899,$0536,$5DCF,$0536,$6305,$041C
	dc.w	$6729,$000D,$673F,$005C,$679D,$012C,$68D2,$000A
	dc.w	$68E1,$0011,$68F4,$0006,$6902,$001E,$6922,$0014
	dc.w	$693B,$013A,$6A7B,$0005,$6A88,$0044,$6ACE,$0006
	dc.w	$6AD6,$0008,$6AE6,$0011,$6AF9,$0007,$6B02,$0049
	dc.w	$6B4D,$000F,$6B62,$0029,$6B8D,$0017,$6BA6,$008C
	dc.w	$6C34,$0005,$6C3B,$001A,$6C5B,$000B,$6C68,$0006
	dc.w	$6C70,$0008,$6C83,$0009,$6C97,$0015,$6CB5,$0006
	dc.w	$6CC5,$0010,$6CD7,$000F,$6CE8,$001B,$6D1D,$000F
	dc.w	$6D2E,$0025,$6D55,$0007,$6D61,$0010,$6D73,$0012
	dc.w	$6D90,$005F,$6E0F,$0056,$6E6A,$0021,$6E92,$0119
	dc.w	$6FBE,$0101,$70C1,$0008,$70CB,$0097,$7164,$001D
	dc.w	$7183,$0006,$718B,$0006,$7193,$0006,$719B,$000B
	dc.w	$71A8,$001D,$71CA,$000C,$71D8,$0058,$7232,$000F
	dc.w	$7243,$0033,$7278,$00FF,$7379,$0040,$73BB,$0031
	dc.w	$73EE,$0536,$7924,$01F3,$7B19,$000F,$0000,$0000

decrypt_offset_len_table_4:
	dc.w	$0003,$0536,$0539,$0536,$0A6F,$0536,$0FA5,$0536
	dc.w	$14DB,$0536,$1A11,$0536,$1F47,$0536,$247D,$0536
	dc.w	$29B3,$0536,$2EE9,$0536,$341F,$0536,$3955,$0536
	dc.w	$3E8B,$0536,$43C1,$0536,$48F7,$0536,$4E2D,$0536
	dc.w	$5363,$0536,$5899,$0536,$5DCF,$0536,$6305,$041C
	dc.w	$6729,$000D,$673F,$005C,$679D,$012C,$68D2,$000A
	dc.w	$68E1,$0011,$68F4,$0006,$6902,$001E,$6922,$0014
	dc.w	$693B,$013A,$6A7B,$0005,$6A88,$0044,$6ACE,$0006
	dc.w	$6AD6,$0008,$6AE6,$0011,$6AF9,$0007,$6B02,$0049
	dc.w	$6B4D,$000F,$6B62,$0029,$6B8D,$0017,$6BA6,$008C
	dc.w	$6C34,$0005,$6C3B,$001A,$6C5B,$000B,$6C68,$0006
	dc.w	$6C70,$0008,$6C83,$0009,$6C97,$0015,$6CB5,$0006
	dc.w	$6CC5,$0010,$6CD7,$000F,$6CE8,$001B,$6D1D,$000F
	dc.w	$6D2E,$0025,$6D55,$0007,$6D61,$0010,$6D73,$0012
	dc.w	$6D90,$005F,$6E0F,$0056,$6E6A,$0021,$6E92,$0119
	dc.w	$6FBE,$0101,$70C1,$0008,$70CB,$0097,$7164,$001D
	dc.w	$7183,$0006,$718B,$0006,$7193,$0006,$719B,$000B
	dc.w	$71A8,$001D,$71CA,$000C,$71D8,$0058,$7232,$000F
	dc.w	$7243,$0033,$7278,$00FF,$7379,$0040,$73BB,$0031
	dc.w	$73EE,$048A,$0000,$0000,$0000,$0000,$0000,$0000

; this is the data+code that the program starts to decrypt (2 passes)
; when it starts. those bytes are used as a key for the final decryption    
; we could have let the code run but that involved a lot of system calls
; including trackdisk shit and all so under whdload not sure how it would
; have reacted. Better rip it from a running emulated session with real
; IPF file with protection on a A500 emulated system.
; big kudos to the people who cracked that with real amigas. Not impossible
; but damn tricky.

decrypt_keys_1:
    incbin  "decrypt_keys_1.bin"
decrypt_keys_2:
    incbin  "decrypt_keys_2.bin"
decrypt_keys_3:
    incbin  "decrypt_keys_3.bin"
decrypt_keys_4:
    incbin  "decrypt_keys_4.bin"
voies_string
    dc.b    "voies",0
    