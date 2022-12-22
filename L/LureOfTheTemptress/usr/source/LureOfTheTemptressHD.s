
VER_ITALIAN = 0
VER_GERMAN = 1
VER_FRENCH = 2
VER_ENGLISH_2030 = 3
VER_ENGLISH_2031 = 4        ; AKA "english version 2"

SAVE_LEN = $11600


	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	LureOfTheTemptress.slave
	ENDC

    IFD CHIP_ONLY
CHIPMEMSIZE = $100000
FASTMEMSIZE = $0
    ELSE
CHIPMEMSIZE = $80000
FASTMEMSIZE = $80000
    ENDC
    
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_whddata-_base	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem_whd
		dc.l	FASTMEMSIZE			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w    0     ; kickstart name
		dc.l    $0         ; kicksize
		dc.w    $0         ; kickcrc
		dc.w	slv_config-_base

slv_config:
		dc.b    "BW;"
		dc.b	0
	even
; set manually depending on the compilation flags
_expmem
	dc.l	0
	
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

;DEBUG

DECL_VERSION:MACRO
	dc.b	"2.2"
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
    dc.b    10
	dc.b	0

_whddata:
		dc.b	"data",0
_name		dc.b	"Lure of the Temptress"
		IFD	DEBUG
		dc.b	" (DEBUG MODE)"
		ENDC
		dc.b	0
_copy		dc.b	"1992 Revolution Software",0
_info		dc.b	"installed & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

		even



_start	
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	lea	(_tags,pc),A0
	jsr	(resload_Control,A2)

	lea	_expmem(pc),a0
	IFD	CHIP_ONLY
	move.l	#CHIPMEMSIZE,(a0)
	ELSE
	move.l	_expmem_whd(pc),(a0)
	ENDC
	
	move.l	_expmem(pc),$0.W
	
	lea	boot(pc),A0
	lea	$70000,A1
	move.l	_resload(pc),a2
	jsr	resload_Decrunch(a2)

    
	lea	pl_boot(pc),a0
	lea	$70000,A1
	jsr	(resload_Patch,a2)
	JMP	$70058
	
pl_boot
	PL_START
	PL_P	$3D4,ReadSectors
	; *** after load
	PL_P	$29C,loader

	; *** remove a cacr remove routine

	PL_NOP	$DCC,4
	
	; *** remove sort of speed/pal/ntsc test

	PL_NOP	$12E,2
    
    PL_IFBW
    PL_PS   $12c8,wait_intro_screen
    PL_ENDIF
	PL_END

wait_intro_screen
    movem.l  d0/a2,-(a7)
    move.l  _resload(pc),a2
    move.l  #50,d0
    jsr (resload_Delay,a2)
    movem.l  (a7)+,d0/a2
	LEA	$71144,A1
    rts
    

loader:
	move.l	D0,-(sp)
	move.l	buttonwait(pc),D0
	beq	.skip
.bw
	btst	#7,$BFE001
	beq	.skip
	btst	#6,$BFE001
	beq	.skip
	bra	.bw
.skip
	move.l	(sp)+,D0

	lea	version(pc),A0

	cmp.l	#'Date',$59F0.W
	beq	PatchGerman1


; french
	cmp.l	#'ichi',$59F0.W
	bne	PatchEnglish1

	move.l	#VER_FRENCH,(A0)
	
	lea	pl_french(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
	
	bra	PatchStart1

pl_french:
	PL_START
	; *** load routine - french

	PL_P	$3CBB4,ReadSectors2

	; *** copy protection

	PL_P	$19734,skip_protection

	; *** kb interrupt - french

	PL_PS	$1FDC4,KbInt

	; *** HD saves - french

	; *** removes insert disk requester for load/save - french

	PL_NOP	$1FFCE,4 ; SAVE
	PL_NOP	$20104,4	; LOAD

	; *** load and save - french

	PL_P	$19C54,SaveGameHD
	PL_P	$19C7E,LoadGameHD
	PL_P	$3CC38,SaveGameDir

	; *** $BFD100 routine - french

	PL_L	$3CD70,$70004E75

	; *** memory patch - french

	PL_P	$1FA3C,RelocateFrench

	; *** prevents floppy formatting - french

	PL_L	$3CCCA,$7E004E75

	PL_P	$1F404,FastDecrunch2
	PL_P	$1F770,FastDecrunch1
    
    ; audio dma wait
    PL_PS   $26150,dma_write
    PL_PS   $26214,dma_write
    PL_PS   $262be,dma_write
    PL_PS   $264d8,dma_write

    ; menu text wait
    PL_PS   $260e8,wait_to_read_text

	; access fault avoidance
	PL_PS	$18288,_avoid_af2
	
	; fix unmasked D1 MSW
	PL_P	$21524,fix_unmasked_d1_msw

	PL_END
	
PatchStart1:

	jmp	$4000.W


PatchEnglish1:
	cmp.l	#'Info',$59F0.W
	bne	PatchEnglish_SPS2031

	move.l	#VER_ENGLISH_2030,(A0)

    
	lea	pl_english_2030(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)

	bra	PatchStart1
    
    
pl_english_2030
	PL_START
	; *** load routine - english

	PL_P	$3B278,ReadSectors2

	; *** copy protection

	PL_P	$19776,skip_protection

	; *** kb interrupt - english

	PL_PS	$1FDB6,KbInt

	; *** memory patch - english

	PL_P	$1FA2E,RelocateEnglish

	; *** HD saves - english

	; *** removes insert disk requester for load/save - english

	PL_NOP	$1FFC6,4	; SAVE
	PL_NOP	$200FC,4	; LOAD

	; *** load and save - english

	PL_P	$19C96,SaveGameHD
	PL_P	$19CC0,LoadGameHD
	PL_P	$3B2FC,SaveGameDir

	; *** prevents floppy formatting

	PL_L	$3B38E,$7E004E75

	; *** removes a $BFD100 access routine

	PL_L	$3B434,$70FF4E75

	; *** relocates the decrunch1 routine in fast memory - english
	PL_P	$1F762,FastDecrunch1
	PL_P	$1F3F6,FastDecrunch2

    ; proper dma stop sound delay
    PL_PS   $25ff8,dma_write
    PL_PS   $260bc,dma_write
    PL_PS   $26166,dma_write
    PL_PS   $26380,dma_write
    
    ; *** wait a few seconds more to be able to read the intro text
    ; (on fast machines where decompression is super fast thanks
    ; to the relocation...)
    
    PL_PS   $25f90,wait_to_read_text

	; access fault avoidance
	PL_PS	$18286,_avoid_af2
	
	; fix unmasked D1 MSW
	PL_P	$214ea,fix_unmasked_d1_msw

	PL_END
	
PatchEnglish_SPS2031:
	cmp.l	#$696C65FF,$59F0.W	; "ile"+$FF
	bne	PatchItalian

	move.l	#VER_ENGLISH_2031,(A0)
    
	lea	pl_english_2031(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)
    
	bra	PatchStart1

pl_english_2031
	PL_START
	; *** load routine - english 2

	PL_P	$3B1A8,ReadSectors2

	; *** copy protection - english 2

	PL_P	$1971C,skip_protection

	; *** kb interrupt - english 2

	PL_PS	$1FD5C,KbInt

	; *** memory patch - english 2

	PL_P	$1F9D4,RelocateEnglish2

	; *** HD saves - english 2

	; *** removes insert disk requester for load/save - english 2

	PL_NOP	$1FF6C,4	; SAVE
	PL_NOP	$200A2,4	; LOAD

	; *** load and save - english 2

	PL_P	$19C3C,SaveGameHD
	PL_P	$19C66,LoadGameHD
	PL_P	$3B22C,SaveGameDir

	; *** prevents floppy formatting

	PL_L	$3B2BE,$7E004E75

	; *** removes a $BFD100 access routine

	PL_L	$3B364,$70004E75
	
    ; decrunch routines
	PL_P	$1F708,FastDecrunch1
	PL_P	$1F39C,FastDecrunch2
      
    ; audio dma wait
    PL_PS   $25f98,dma_write
    PL_PS   $2605c,dma_write
    PL_PS   $26106,dma_write
    PL_PS   $26320,dma_write
   
    PL_PS   $25f30,wait_to_read_text

	; access fault avoidance
	PL_PS	$18270,_avoid_af2
	
	; fix unmasked D1 MSW
	PL_P	$21492,fix_unmasked_d1_msw

	PL_END
	
PatchItalian:
	cmp.l	#'File',$59F2.W	; "File"
	bne	PatchUnknown

	move.l	#VER_ITALIAN,(A0)

	
	lea	pl_italian(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)


	bra	PatchStart1
pl_italian
	PL_START
	; *** load routine - italian

	PL_P	$3BB86,ReadSectors2

	; *** copy protection - italian

	PL_P	$1970C,skip_protection

	; *** kb interrupt - italian

	PL_PS	$1FD4C,KbInt

	; *** memory patch - italian

	PL_P	$1F9C4,RelocateItalian

	; *** HD saves - italian

	; *** removes insert disk requester for load/save - italian

	PL_NOP	$1FF5A,4	; SAVE
	PL_NOP	$20090,4	; LOAD

	; *** load and save - italian

	PL_P	$19C2C,SaveGameHD
	PL_P	$19C56,LoadGameHD
	PL_P	$3BC0A,SaveGameDir

	; *** prevents floppy formatting

	PL_L	$3BC9C,$7E004E75

	; *** removes a $BFD100 access routine

	PL_L	$3BD42,$70004E75
	
	PL_P	$1F6F8,FastDecrunch1
	PL_P	$1F38C,FastDecrunch2


    ; audio dma wait
    PL_PS   $25fe0,dma_write
    PL_PS   $260a4,dma_write
    PL_PS   $2614e,dma_write
    PL_PS   $26368,dma_write


    PL_PS   $25f78,wait_to_read_text
	
	; access fault avoidance
	PL_PS	$18260,_avoid_af2
	
	; fix unmasked D1 MSW
	PL_P	$2148c,fix_unmasked_d1_msw
	
	PL_END
	
PatchUnknown:
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

_avoid_af2:
	move.l	(2,a5),a2
	cmp.l	#$4000,a2
	bcs.b	.avoid
	cmp.l	#$80000,a2
	bcc.b	.avoid
	move.w	(a2)+,d0
	cmp.w	#40,d0
	; > 40: bogus address too as index is too high (issue #0005576)
	bcc.b	.avoid
	rts

.avoid
	; figured out that setting to 0 makes game jump to first address
	; of the table, which seems harmless
	moveq	#0,d0
	rts

skip_protection
	lea	enable_wait(pc),a0
	clr.w	(a0)		; no more wait now
	
	clr.w	d0
	rts
	
fix_unmasked_d1_msw
	move.l	d1,-(a7)
	; add D1 to A3, but sometimes D1 msw is not zero
	; naive fix is to do ADD.L => ADD.W but this is a
	; problem when D1 > $7FFF because add becomes signed
	; so we have to keep adding a long
	swap	d1
	clr.w	d1
	swap	d1
	ADDA.L	D1,A3			;2148c: d7c1
	move.l	(a7)+,d1
	ADDA.W	D0,A3			;2148e: d6c0
	RTS				;21490: 4e75

wait_to_read_text
    movem.l d0-d1/a0/a2,-(a7)
    ; not needed first time
	move.w	enable_wait(pc),d0
	beq.b	.nowait
    lea first_time(pc),a0
    tst.b   (a0)
    beq.b   .wait
    clr.b   (a0)
    bra.b   .waitrel
.wait
	; also should not be activated after the intro has played
    move.l  _resload(pc),a2
    move.l  #60,d0      ; add 6 seconds, user can click on a button
    jsr (resload_Delay,a2)
    ; wait lmb not pressed to avoid that user skips the intro
    ; during this waiting time
.waitrel
    btst    #6,$bfe001
    beq.b   .waitrel
.nowait
    movem.l (a7)+,d0-d1/a0/a2

    ; original code
	LEA	0(A0,D0.W),A0		;25f90: 41f00000
	MOVEQ	#3,D2			;25f94: 7403
    
    rts
    
    
; **** GERMAN version
	
PatchGerman1:
	move.l	#VER_GERMAN,(A0)

 
;	move.w	#$4EF9,$19E00
;	move.l	#CopyDisk,$19E02	
	lea	pl_german(pc),a0
	sub.l	a1,a1
	move.l	_resload(pc),a2
	jsr		resload_Patch(a2)	

.nocopydisk
	bra	PatchStart1

pl_german
	PL_START
	; *** load routine

	PL_P	$3DA1E,ReadSectors2

	; *** copy protection

	PL_P	$198E0,skip_protection

	; *** kb interrupt

	PL_PS	$1FF28,KbInt

	; *** $BFD100 routine - german

	PL_L	$3DBDA,$70FF4E75

	; *** memory patch - german

	PL_P	$1FBA0,RelocateGerman

	; *** HD saves

	PL_P	$19E00,SaveGameHD
	PL_P	$19E2A,LoadGameHD
	PL_P	$3DAA2,SaveGameDir

	; *** removes insert disk requester for load/save - german

	PL_NOP	$20136,4
	PL_NOP	$2026C,4

	; *** prevents floppy formatting

	PL_L	$3DB34,$7E004E75

	PL_P	$1F8D4,FastDecrunch1
	PL_P	$1F568,FastDecrunch2


    ; audio dma wait
    PL_PS   $26256,dma_write
    PL_PS   $2631a,dma_write
    PL_PS   $263c4,dma_write
    PL_PS   $265de,dma_write


    ; wait for intro text (loading is so fast now)
    PL_PS   $261ee,wait_to_read_text

	; access fault avoidance
	PL_PS	$18434,_avoid_af2
	
	; fix unmasked D1 MSW
	PL_P	$2168c,fix_unmasked_d1_msw
    
	PL_END


KbInt:
	lea	$4414.W,A1
	move.b	D0,D1
	cmp.b	_keyexit(pc),D0
	bne	.noquit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.noquit
	rts

ReadSectors2:
	tst.w	D1
	bne	.noboot
	cmp.w	#1,D2
	bne	.noboot

	bra	LoadGameDir
.noboot

	; ** try to figure out if this is a game load

;	cmp.w	#$8C,D2		; length
;	beq	.test2
;	cmp.w	#$8B,D2		; length (for french version)
;	bne	.hdload
;.test2
;	cmp.l	#$4000,A0	; buffer
;	bne	.hdload

	; this is when the game loads a "restart" game save
	; so the tests above are useless because load & save
	; are already intercepted at a higher level
	
.hdload
	move.l	D0,-(sp)
	moveq.l	#0,D0
	move.w	$44DA.W,D0		; required disk
	subq	#1,D0			; 1,2,3,4
	bsr	ReadSectors
	move.l	(sp)+,D0
.out
	rts

ReadSectors:
	move.l	D3,D7
	moveq	#0,D3
	bsr	_robread
	move.l	D7,D3
	moveq.l	#0,D7
	rts

; Rob Northen track loading routine
; < A0: buffer
; < D0: disk number
; < D1: sector offset (*$200)
; < D2: sector length (*$200)
; < D3: command (ignored)
; > D0: 0 if ok (which is all the time :))

_robread:
	movem.l	d1-d3/a0-a2,-(A7)
	and.b	#$FF,D3
	bne.b	.exit

	move.l	d0,d3		; disk number stored
	
	swap	D1
	clr.w	D1
	swap	D1
	swap	D2
	clr.w	D2
	swap	D2
	tst.w	D2
	beq.b	.exit		; length=0: out

	move.l	D1,D0
	ext.l	d0
	lsl.l	#7,d0			;diskoffset
	lsl.l	#2,d0

	move.l	D2,D1			;len to read
	ext.l	d1
	lsl.l	#7,d1
	lsl.l	#2,d1

	move.l	D3,D2
	addq.l	#1,D2
	MOVE.L	_resload(PC),A2
	jsr	(resload_DiskLoad,a2)
.exit
	movem.l	(A7)+,d1-d3/a0-a2
	moveq.l	#0,D0
	rts
    
LoadGameHD:
	movem.l	D1-D7/A0-A6,-(sp)
	
	add.b	#'1',D0
	lea	savenum(pc),A0
	move.b	D0,(A0)
	lea	savename(pc),A0
	lea	$4000.W,A1	; buffer
	move.l	#SAVE_LEN,D0	; size
	moveq.l	#0,D1	; offset
	move.l	_resload(pc),a2
	jsr	(resload_LoadFileOffset,a2)

	movem.l	(sp)+,D1-D7/A0-A6
    moveq.l #0,d0
	rts
		 
		 

SaveGameHD:
	movem.l	D1/A0-A2,-(sp)
	
	add.b	#'1',D0
	lea	savenum(pc),A0
	move.b	D0,(A0)
	lea	savename(pc),A0
	lea	$4000.W,A1	; buffer
	move.l	#SAVE_LEN,D0
	move.l	_resload(pc),a2
	jsr	(resload_SaveFile,a2)

	movem.l	(sp)+,D1/A0-A2
    moveq.l #0,d0   ; no error
	rts


LoadGameDir:
	; *** load the game directory from HD
    
	movem.l	D0-D1/A0-A3,-(sp)
    move.l  a0,a3       ; save buffer
	lea	dirname(pc),A0
	move.l	_resload(pc),a2
	jsr	(resload_GetFileSize,a2)
	cmp.l	#$200,d0    ; test existence and correct size!
	bne.b	.error
	
	move.l	A3,A1			; buffer
	lea	dirname(pc),A0
	jsr	(resload_LoadFile,a2)
	moveq.l	#0,D7
.exit
	movem.l	(sp)+,D0-D1/A0-A3
	rts
.error
	moveq	#-1,D7
	bra	.exit

BypassLoad:
	illegal

BypassLoadGerman:
	JSR	$3DC2E			; resumes floppy access
	JMP	$3DA26

BypassLoadFrench:
	JSR	$3CDC4			; resumes floppy access
	JMP	$3CC40

BypassLoadEnglish:
	illegal
	JSR	$3CDC4			; resumes floppy access
	JMP	$3CC4A


SaveGameDir:
	moveq.l	#0,D7

	tst.w	D1
	bne	.exit
	cmp.w	#1,D2
	bne	.exit

	; *** save the game directory to HD

	movem.l	D0-D1/A0-A2,-(sp)

	move.l	A0,A1   ; buffer
	lea	dirname(pc),A0
	move.l	#$200,D0
	move.l	_resload(pc),a2
	jsr	(resload_SaveFile,a2)
	moveq	#0,d7

	movem.l	(sp)+,D0-D1/A0-A2
.exit
	rts


RelocateItalian:
	lea	$17406,a0
	bra	RelocateCommon

RelocateFrench:
	LEA	$1740E,A0
	bra	RelocateCommon

RelocateGerman:
	LEA	$1747C,A0
	bra	RelocateCommon

RelocateEnglish:
	LEA	$17430,A0
	bra	RelocateCommon

RelocateEnglish2:
	LEA	$173F6,A0
	bra	RelocateCommon
	
RelocateCommon:
	move.l	_expmem(pc),D0
	sub.l	#$C00000,D0		; game designed for $C00000 addresses
	MOVE	#$0014,D7
LAB_0000:
	ADD.L	D0,(A0)+
	DBF	D7,LAB_0000

	move.l	_expmem(pc),D0
	RTS


    
_resload:
	dc.l	0

dma_write
    MOVE.W	2(A4),150(A5)		;25f98: 3b6c00020096
    
	move.w  d0,-(a7)
	move.w	#4,d0   ; make it 7 if still issues
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	;;;addq.l	#2,(a7)  harmful if not used with PSS!!
	move.w	(a7)+,d0
	rts    

kb_interrupt
	move.b	$bfec01,d1
	move.l	d1,-(a7)
	not.b	d1
	ror.b	#1,d1
	cmp.b	_keyexit(pc),d1
	bne.b	.sk

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

.sk
	move.l	(a7)+,d1
	rts

_flushcache:
	move.l	A2,-(A7)
	move.l	(_resload,pc),a2
	jsr	(resload_FlushCache,a2)
	move.l	(A7)+,A2
	rts

_tags
		dc.l	WHDLTAG_BUTTONWAIT_GET
buttonwait
		dc.l	0
		dc.l	0
enable_wait
	dc.w	$FFFF
first_time
    dc.w    $FFFF
version
	dc.l	0
savename:
	dc.b	"luresave."
savenum:
	dc.b	"0",0
dirname
	dc.b	"luresave.dir",0
    even
boot:
	incbin	"lureboot.rnc"
    even
    
decrunch_buffer:
    ds.b    $100,0
    
FastDecrunch1:
	MOVE.W	(A1)+,D0		;1f708: 3019
	MOVE.L	(A1)+,D7		;1f70a: 2e19
	BTST	#0,D0			;1f70c: 08000000
	BEQ.W	LAB_07D0		;1f710: 67000006
	LEA	96(A1),A1		;1f714: 43e90060
LAB_07D0:
	MOVE.L	(A1)+,D6		;1f718: 2c19
	MOVE.W	#$0020,D5		;1f71a: 3a3c0020
	LEA	decrunch_buffer(PC),A2		;1f71e: 45fafee8
	CLR.W	D0			;1f722: 4240
	MOVE.W	#$001f,D1		;1f724: 323c001f
LAB_07D1:
	BSR.W	LAB_07F3		;1f728: 6100021a
	ANDI.W	#$001f,D4		;1f72c: 0244001f
	MOVE.B	D4,(A2)			;1f730: 1484
	BSR.W	LAB_07F3		;1f732: 61000210
	ANDI.W	#$001f,D4		;1f736: 0244001f
	MOVE.B	D4,32(A2)		;1f73a: 15440020
	BSR.W	LAB_07F3		;1f73e: 61000204
	ANDI.W	#$001f,D4		;1f742: 0244001f
	MOVE.B	D4,64(A2)		;1f746: 15440040
	BSR.W	LAB_07F3		;1f74a: 610001f8
	ANDI.W	#$001f,D4		;1f74e: 0244001f
	MOVE.B	D4,96(A2)		;1f752: 15440060
	LEA	1(A2),A2		;1f756: 45ea0001
	DBF	D1,LAB_07D1		;1f75a: 51c9ffcc
	LEA	decrunch_buffer(PC),A2		;1f75e: 45fafea8
	BSR.W	LAB_07F3		;1f762: 610001e0
	ANDI.W	#$001f,D4		;1f766: 0244001f
	MOVE.W	#$000f,D2		;1f76a: 343c000f
	MOVE.W	#$0013,D1		;1f76e: 323c0013
LAB_07D2:
	MOVE.W	D4,D3			;1f772: 3604
	ROXR.W	#1,D4			;1f774: e254
	ROXL	(A0)			;1f776: e5d0

    ; asm fixed (IRA is buggy on ROXL)
    ROXR.W #$01,D4
    ROXL.W (A0,$0028)
    ROXR.W #$01,D4
    ROXL.W (A0,$0050)
    ROXR.W #$01,D4
    ROXL.W (A0,$0078)
    ROXR.W #$01,D4
    ROXL.W (A0,$00a0)
    DBF D2,LAB_07D3
    LEA.L (A0,$0002),a0
    MOVE.W #$000f,D2
    dbf d1,LAB_07D3
	LEA	160(A0),A0		;1f7a0: 41e800a0
	MOVE.W	#$0013,D1		;1f7a4: 323c0013
LAB_07D3:
	CLR.W	D4			;1f7a8: 4244
	DBF	D7,LAB_07D4		;1f7aa: 51cf0004
	RTS				;1f7ae: 4e75
LAB_07D4:
	DBF	D5,LAB_07D5		;1f7b0: 51cd0008
	MOVE.L	(A1)+,D6		;1f7b4: 2c19
	MOVE.W	#$001f,D5		;1f7b6: 3a3c001f
LAB_07D5:
	ROXL.L	#1,D6			;1f7ba: e396
	BCS.W	LAB_07D6		;1f7bc: 65000008
	MOVE.B	0(A2,D3.W),D4		;1f7c0: 18323000
	BRA.S	LAB_07D2		;1f7c4: 60ac
LAB_07D6:
	DBF	D5,LAB_07D7		;1f7c6: 51cd0008
	MOVE.L	(A1)+,D6		;1f7ca: 2c19
	MOVE.W	#$001f,D5		;1f7cc: 3a3c001f
LAB_07D7:
	ROXL.L	#1,D6			;1f7d0: e396
	BCS.W	LAB_07DA		;1f7d2: 6500001e
	DBF	D5,LAB_07D8		;1f7d6: 51cd0008
	MOVE.L	(A1)+,D6		;1f7da: 2c19
	MOVE.W	#$001f,D5		;1f7dc: 3a3c001f
LAB_07D8:
	ROXL.L	#1,D6			;1f7e0: e396
	BCS.W	LAB_07D9		;1f7e2: 65000008
	MOVE.B	32(A2,D3.W),D4		;1f7e6: 18323020
	BRA.S	LAB_07D2		;1f7ea: 6086
LAB_07D9:
	MOVE.B	64(A2,D3.W),D4		;1f7ec: 18323040
	BRA.S	LAB_07D2		;1f7f0: 6080
LAB_07DA:
	DBF	D5,LAB_07DB		;1f7f2: 51cd0008
	MOVE.L	(A1)+,D6		;1f7f6: 2c19
	MOVE.W	#$001f,D5		;1f7f8: 3a3c001f
LAB_07DB:
	ROXL.L	#1,D6			;1f7fc: e396
	BCS.W	LAB_07DC		;1f7fe: 6500000a
	MOVE.B	96(A2,D3.W),D4		;1f802: 18323060
	BRA.W	LAB_07D2		;1f806: 6000ff6a
LAB_07DC:
	BSR.W	LAB_07F3		;1f80a: 61000138
	ANDI.W	#$001f,D4		;1f80e: 0244001f
	CMP.B	0(A2,D3.W),D4		;1f812: b8323000
	BEQ.W	LAB_07DD		;1f816: 6700001e
	CMP.B	32(A2,D3.W),D4		;1f81a: b8323020
	BEQ.W	LAB_07DE		;1f81e: 67000020
	CMP.B	64(A2,D3.W),D4		;1f822: b8323040
	BEQ.W	LAB_07DF		;1f826: 67000022
	CMP.B	96(A2,D3.W),D4		;1f82a: b8323060
	BEQ.W	LAB_07E0		;1f82e: 67000024
	BRA.W	LAB_07D2		;1f832: 6000ff3e
LAB_07DD:
	CLR.W	D4			;1f836: 4244
	BSR.W	LAB_07E5		;1f838: 61000070
	BRA.W	LAB_07E1		;1f83c: 6000001c
LAB_07DE:
	CLR.W	D4			;1f840: 4244
	BSR.W	LAB_07EE		;1f842: 610000d6
	BRA.W	LAB_07E1		;1f846: 60000012
LAB_07DF:
	CLR.W	D4			;1f84a: 4244
	BSR.W	LAB_07F1		;1f84c: 610000e8
	BRA.W	LAB_07E1		;1f850: 60000008
LAB_07E0:
	CLR.W	D4			;1f854: 4244
	BSR.W	LAB_07F3		;1f856: 610000ec
LAB_07E1:
	MOVE.W	D3,D0			;1f85a: 3003
	MOVE.W	D4,D3			;1f85c: 3604
	SUBI.W	#$0001,D3		;1f85e: 04430001
LAB_07E2:
	MOVE.B	D0,D4			;1f862: 1800
	ROXR.W	#1,D4			;1f864: e254
	ROXL	(A0)			;1f866: e5d0
    ROXR.W #$01,D4
    ROXL.W (A0,$0028)
    ROXR.W #$01,D4
    ROXL.W (A0,$0050)
    ROXR.W #$01,D4
    ROXL.W (A0,$0078)
    ROXR.W #$01,D4
    ROXL.W (A0,$00a0)
    DBF D2,LAB_07E3
	LEA	2(A0),A0		;1f884: 41e80002
	MOVE.W	#$000f,D2		;1f888: 343c000f
	DBF	D1,LAB_07E3		;1f88c: 51c9000a
	LEA	160(A0),A0		;1f890: 41e800a0
	MOVE.W	#$0013,D1		;1f894: 323c0013
LAB_07E3:
	CLR.W	D4			;1f898: 4244
	DBF	D7,LAB_07E4		;1f89a: 51cf0004
	RTS				;1f89e: 4e75
LAB_07E4:
	DBF	D3,LAB_07E2		;1f8a0: 51cbffc0
	MOVE.W	D0,D3			;1f8a4: 3600
	BRA.W	LAB_07D4		;1f8a6: 6000ff08
LAB_07E5:
	DBF	D5,LAB_07E6		;1f8aa: 51cd0008
	MOVE.L	(A1)+,D6		;1f8ae: 2c19
	MOVE.W	#$001f,D5		;1f8b0: 3a3c001f
LAB_07E6:
	ROXL.L	#1,D6			;1f8b4: e396
	ROXL.W	#1,D4			;1f8b6: e354
	DBF	D5,LAB_07E7		;1f8b8: 51cd0008
	MOVE.L	(A1)+,D6		;1f8bc: 2c19
	MOVE.W	#$001f,D5		;1f8be: 3a3c001f
LAB_07E7:
	ROXL.L	#1,D6			;1f8c2: e396
	ROXL.W	#1,D4			;1f8c4: e354
	DBF	D5,LAB_07E8		;1f8c6: 51cd0008
	MOVE.L	(A1)+,D6		;1f8ca: 2c19
	MOVE.W	#$001f,D5		;1f8cc: 3a3c001f
LAB_07E8:
	ROXL.L	#1,D6			;1f8d0: e396
	ROXL.W	#1,D4			;1f8d2: e354
	DBF	D5,LAB_07E9		;1f8d4: 51cd0008
	MOVE.L	(A1)+,D6		;1f8d8: 2c19
	MOVE.W	#$001f,D5		;1f8da: 3a3c001f
LAB_07E9:
	ROXL.L	#1,D6			;1f8de: e396
	ROXL.W	#1,D4			;1f8e0: e354
	DBF	D5,LAB_07EA		;1f8e2: 51cd0008
	MOVE.L	(A1)+,D6		;1f8e6: 2c19
	MOVE.W	#$001f,D5		;1f8e8: 3a3c001f
LAB_07EA:
	ROXL.L	#1,D6			;1f8ec: e396
	ROXL.W	#1,D4			;1f8ee: e354
	DBF	D5,LAB_07EB		;1f8f0: 51cd0008
	MOVE.L	(A1)+,D6		;1f8f4: 2c19
	MOVE.W	#$001f,D5		;1f8f6: 3a3c001f
LAB_07EB:
	ROXL.L	#1,D6			;1f8fa: e396
	ROXL.W	#1,D4			;1f8fc: e354
	DBF	D5,LAB_07EC		;1f8fe: 51cd0008
	MOVE.L	(A1)+,D6		;1f902: 2c19
	MOVE.W	#$001f,D5		;1f904: 3a3c001f
LAB_07EC:
	ROXL.L	#1,D6			;1f908: e396
	ROXL.W	#1,D4			;1f90a: e354
	DBF	D5,LAB_07ED		;1f90c: 51cd0008
	MOVE.L	(A1)+,D6		;1f910: 2c19
	MOVE.W	#$001f,D5		;1f912: 3a3c001f
LAB_07ED:
	ROXL.L	#1,D6			;1f916: e396
	ROXL.W	#1,D4			;1f918: e354
LAB_07EE:
	DBF	D5,LAB_07EF		;1f91a: 51cd0008
	MOVE.L	(A1)+,D6		;1f91e: 2c19
	MOVE.W	#$001f,D5		;1f920: 3a3c001f
LAB_07EF:
	ROXL.L	#1,D6			;1f924: e396
	ROXL.W	#1,D4			;1f926: e354
	DBF	D5,LAB_07F0		;1f928: 51cd0008
	MOVE.L	(A1)+,D6		;1f92c: 2c19
	MOVE.W	#$001f,D5		;1f92e: 3a3c001f
LAB_07F0:
	ROXL.L	#1,D6			;1f932: e396
	ROXL.W	#1,D4			;1f934: e354
LAB_07F1:
	DBF	D5,LAB_07F2		;1f936: 51cd0008
	MOVE.L	(A1)+,D6		;1f93a: 2c19
	MOVE.W	#$001f,D5		;1f93c: 3a3c001f
LAB_07F2:
	ROXL.L	#1,D6			;1f940: e396
	ROXL.W	#1,D4			;1f942: e354
LAB_07F3:
	DBF	D5,LAB_07F4		;1f944: 51cd0008
	MOVE.L	(A1)+,D6		;1f948: 2c19
	MOVE.W	#$001f,D5		;1f94a: 3a3c001f
LAB_07F4:
	ROXL.L	#1,D6			;1f94e: e396
	ROXL.W	#1,D4			;1f950: e354
	DBF	D5,LAB_07F5		;1f952: 51cd0008
	MOVE.L	(A1)+,D6		;1f956: 2c19
	MOVE.W	#$001f,D5		;1f958: 3a3c001f
LAB_07F5:
	ROXL.L	#1,D6			;1f95c: e396
	ROXL.W	#1,D4			;1f95e: e354
	DBF	D5,LAB_07F6		;1f960: 51cd0008
	MOVE.L	(A1)+,D6		;1f964: 2c19
	MOVE.W	#$001f,D5		;1f966: 3a3c001f
LAB_07F6:
	ROXL.L	#1,D6			;1f96a: e396
	ROXL.W	#1,D4			;1f96c: e354
	DBF	D5,LAB_07F7		;1f96e: 51cd0008
	MOVE.L	(A1)+,D6		;1f972: 2c19
	MOVE.W	#$001f,D5		;1f974: 3a3c001f
LAB_07F7:
	ROXL.L	#1,D6			;1f978: e396
	ROXL.W	#1,D4			;1f97a: e354
	DBF	D5,LAB_07F8		;1f97c: 51cd0008
	MOVE.L	(A1)+,D6		;1f980: 2c19
	MOVE.W	#$001f,D5		;1f982: 3a3c001f
LAB_07F8:
	ROXL.L	#1,D6			;1f986: e396
	ROXL.W	#1,D4			;1f988: e354
	RTS	    ;1f98a: 4e75
    
FastDecrunch2:
	LEA	decrunch_buffer(PC),A3		;1f39c: 47fa026a
	ADDQ.W	#2,A1			;1f3a0: 5449
	MOVE.L	(A1)+,D7		;1f3a2: 2e19
	LSR.L	#4,D7			;1f3a4: e88f
	SUBQ.L	#1,D7			;1f3a6: 5387
	BSR.W	LAB_07CD		;1f3a8: 6100025a
	MOVEA.L	A3,A2			;1f3ac: 244b
	MOVE.W	#$003f,D6		;1f3ae: 3c3c003f
LAB_07A1:
	CLR.W	D1			;1f3b2: 4241
	DBF	D5,LAB_07A2		;1f3b4: 51cd0008
	MOVE.W	(A1)+,D4		;1f3b8: 3819
	MOVE.W	#$000f,D5		;1f3ba: 3a3c000f
LAB_07A2:
	ROXL.W	#1,D4			;1f3be: e354
	ROXL.W	#1,D1			;1f3c0: e351
	DBF	D5,LAB_07A3		;1f3c2: 51cd0008
	MOVE.W	(A1)+,D4		;1f3c6: 3819
	MOVE.W	#$000f,D5		;1f3c8: 3a3c000f
LAB_07A3:
	ROXL.W	#1,D4			;1f3cc: e354
	ROXL.W	#1,D1			;1f3ce: e351
	DBF	D5,LAB_07A4		;1f3d0: 51cd0008
	MOVE.W	(A1)+,D4		;1f3d4: 3819
	MOVE.W	#$000f,D5		;1f3d6: 3a3c000f
LAB_07A4:
	ROXL.W	#1,D4			;1f3da: e354
	ROXL.W	#1,D1			;1f3dc: e351
	DBF	D5,LAB_07A5		;1f3de: 51cd0008
	MOVE.W	(A1)+,D4		;1f3e2: 3819
	MOVE.W	#$000f,D5		;1f3e4: 3a3c000f
LAB_07A5:
	ROXL.W	#1,D4			;1f3e8: e354
	ROXL.W	#1,D1			;1f3ea: e351
	MOVE.W	D1,(A2)+		;1f3ec: 34c1
	DBF	D6,LAB_07A1		;1f3ee: 51ceffc2
	CLR.W	D6			;1f3f2: 4246
	CLR.W	D1			;1f3f4: 4241
	DBF	D5,LAB_07A6		;1f3f6: 51cd0008
	MOVE.W	(A1)+,D4		;1f3fa: 3819
	MOVE.W	#$000f,D5		;1f3fc: 3a3c000f
LAB_07A6:
	ROXL.W	#1,D4			;1f400: e354
	ROXL.W	#1,D1			;1f402: e351
	DBF	D5,LAB_07A7		;1f404: 51cd0008
	MOVE.W	(A1)+,D4		;1f408: 3819
	MOVE.W	#$000f,D5		;1f40a: 3a3c000f
LAB_07A7:
	ROXL.W	#1,D4			;1f40e: e354
	ROXL.W	#1,D1			;1f410: e351
	DBF	D5,LAB_07A8		;1f412: 51cd0008
	MOVE.W	(A1)+,D4		;1f416: 3819
	MOVE.W	#$000f,D5		;1f418: 3a3c000f
LAB_07A8:
	ROXL.W	#1,D4			;1f41c: e354
	ROXL.W	#1,D1			;1f41e: e351
	DBF	D5,LAB_07A9		;1f420: 51cd0008
	MOVE.W	(A1)+,D4		;1f424: 3819
	MOVE.W	#$000f,D5		;1f426: 3a3c000f
LAB_07A9:
	ROXL.W	#1,D4			;1f42a: e354
	ROXL.W	#1,D1			;1f42c: e351
	MOVE.W	D1,D0			;1f42e: 3001
	MOVE.W	#$000f,D2		;1f430: 343c000f
	BRA.W	LAB_07B8		;1f434: 600000ba
LAB_07AA:
	MOVE.W	D1,D0			;1f438: 3001
	TST.W	D6			;1f43a: 4a46
	BEQ.S	LAB_07AB		;1f43c: 6706
	SUBQ.W	#1,D6			;1f43e: 5346
	BRA.W	LAB_07B8		;1f440: 600000ae
LAB_07AB:
	ASL.W	#3,D1			;1f444: e741
	MOVEA.L	A3,A2			;1f446: 244b
	ADDA.W	D1,A2			;1f448: d4c1
	DBF	D5,LAB_07AC		;1f44a: 51cd0008
	MOVE.W	(A1)+,D4		;1f44e: 3819
	MOVE.W	#$000f,D5		;1f450: 3a3c000f
LAB_07AC:
	ROXL.W	#1,D4			;1f454: e354
	BCS.S	LAB_07AD		;1f456: 6506
	MOVE.W	(A2),D1			;1f458: 3212
	BRA.W	LAB_07B8		;1f45a: 60000094
LAB_07AD:
	DBF	D5,LAB_07AE		;1f45e: 51cd0008
	MOVE.W	(A1)+,D4		;1f462: 3819
	MOVE.W	#$000f,D5		;1f464: 3a3c000f
LAB_07AE:
	ROXL.W	#1,D4			;1f468: e354
	BCS.S	LAB_07B0		;1f46a: 6514
	DBF	D5,LAB_07AF		;1f46c: 51cd0008
	MOVE.W	(A1)+,D4		;1f470: 3819
	MOVE.W	#$000f,D5		;1f472: 3a3c000f
LAB_07AF:
	ROXL.W	#1,D4			;1f476: e354
	BCS.S	LAB_07B7		;1f478: 6572
	MOVE.W	2(A2),D1		;1f47a: 322a0002
	BRA.S	LAB_07B8		;1f47e: 6070
LAB_07B0:
	DBF	D5,LAB_07B1		;1f480: 51cd0008
	MOVE.W	(A1)+,D4		;1f484: 3819
	MOVE.W	#$000f,D5		;1f486: 3a3c000f
LAB_07B1:
	ROXL.W	#1,D4			;1f48a: e354
	BCS.S	LAB_07B2		;1f48c: 6506
	MOVE.W	6(A2),D1		;1f48e: 322a0006
	BRA.S	LAB_07B8		;1f492: 605c
LAB_07B2:
	CLR.W	D1			;1f494: 4241
	DBF	D5,LAB_07B3		;1f496: 51cd0008
	MOVE.W	(A1)+,D4		;1f49a: 3819
	MOVE.W	#$000f,D5		;1f49c: 3a3c000f
LAB_07B3:
	ROXL.W	#1,D4			;1f4a0: e354
	ROXL.W	#1,D1			;1f4a2: e351
	DBF	D5,LAB_07B4		;1f4a4: 51cd0008
	MOVE.W	(A1)+,D4		;1f4a8: 3819
	MOVE.W	#$000f,D5		;1f4aa: 3a3c000f
LAB_07B4:
	ROXL.W	#1,D4			;1f4ae: e354
	ROXL.W	#1,D1			;1f4b0: e351
	DBF	D5,LAB_07B5		;1f4b2: 51cd0008
	MOVE.W	(A1)+,D4		;1f4b6: 3819
	MOVE.W	#$000f,D5		;1f4b8: 3a3c000f
LAB_07B5:
	ROXL.W	#1,D4			;1f4bc: e354
	ROXL.W	#1,D1			;1f4be: e351
	DBF	D5,LAB_07B6		;1f4c0: 51cd0008
	MOVE.W	(A1)+,D4		;1f4c4: 3819
	MOVE.W	#$000f,D5		;1f4c6: 3a3c000f
LAB_07B6:
	ROXL.W	#1,D4			;1f4ca: e354
	ROXL.W	#1,D1			;1f4cc: e351
	CMP.W	(A2),D1			;1f4ce: b252
	BEQ.S	LAB_07B9		;1f4d0: 674c
	CMP.W	2(A2),D1		;1f4d2: b26a0002
	BEQ.W	LAB_07C2		;1f4d6: 670000b6
	CMP.W	4(A2),D1		;1f4da: b26a0004
	BEQ.W	LAB_07C5		;1f4de: 670000ca
	CMP.W	6(A2),D1		;1f4e2: b26a0006
	BEQ.W	LAB_07C7		;1f4e6: 670000d0
	BRA.S	LAB_07B8		;1f4ea: 6004
LAB_07B7:
	MOVE.W	4(A2),D1		;1f4ec: 322a0004
LAB_07B8:
	MOVE.W	D1,D0			;1f4f0: 3001
	LSR.W	#1,D0			;1f4f2: e248
	ROXL	(A0)			;1f4f4: e5d0
	LSR.W	#1,D0			;1f4f6: e248
    ROXL.W (A0,$0002)
    LSR.W #$01,D0
    ROXL.W #$01,D3
    LSR.W #$01,D0
    ROXL.W (A0,$0006)
	DBF	D2,LAB_07AA		;1f506: 51caff30
	MOVE.W	D3,4(A0)		;1f50a: 31430004
	ADDA.W	#$0008,A0		;1f50e: d0fc0008
	MOVE.W	#$000f,D2		;1f512: 343c000f
	SUBQ.L	#1,D7			;1f516: 5387
	BGE.W	LAB_07AA		;1f518: 6c00ff1e
	RTS				;1f51c: 4e75
LAB_07B9:
	DBF	D5,LAB_07BA		;1f51e: 51cd0008
	MOVE.W	(A1)+,D4		;1f522: 3819
	MOVE.W	#$000f,D5		;1f524: 3a3c000f
LAB_07BA:
	ROXL.W	#1,D4			;1f528: e354
	ROXL.W	#1,D6			;1f52a: e356
	DBF	D5,LAB_07BB		;1f52c: 51cd0008
	MOVE.W	(A1)+,D4		;1f530: 3819
	MOVE.W	#$000f,D5		;1f532: 3a3c000f
LAB_07BB:
	ROXL.W	#1,D4			;1f536: e354
	ROXL.W	#1,D6			;1f538: e356
	DBF	D5,LAB_07BC		;1f53a: 51cd0008
	MOVE.W	(A1)+,D4		;1f53e: 3819
	MOVE.W	#$000f,D5		;1f540: 3a3c000f
LAB_07BC:
	ROXL.W	#1,D4			;1f544: e354
	ROXL.W	#1,D6			;1f546: e356
	DBF	D5,LAB_07BD		;1f548: 51cd0008
	MOVE.W	(A1)+,D4		;1f54c: 3819
	MOVE.W	#$000f,D5		;1f54e: 3a3c000f
LAB_07BD:
	ROXL.W	#1,D4			;1f552: e354
	ROXL.W	#1,D6			;1f554: e356
	DBF	D5,LAB_07BE		;1f556: 51cd0008
	MOVE.W	(A1)+,D4		;1f55a: 3819
	MOVE.W	#$000f,D5		;1f55c: 3a3c000f
LAB_07BE:
	ROXL.W	#1,D4			;1f560: e354
	ROXL.W	#1,D6			;1f562: e356
	DBF	D5,LAB_07BF		;1f564: 51cd0008
	MOVE.W	(A1)+,D4		;1f568: 3819
	MOVE.W	#$000f,D5		;1f56a: 3a3c000f
LAB_07BF:
	ROXL.W	#1,D4			;1f56e: e354
	ROXL.W	#1,D6			;1f570: e356
	DBF	D5,LAB_07C0		;1f572: 51cd0008
	MOVE.W	(A1)+,D4		;1f576: 3819
	MOVE.W	#$000f,D5		;1f578: 3a3c000f
LAB_07C0:
	ROXL.W	#1,D4			;1f57c: e354
	ROXL.W	#1,D6			;1f57e: e356
	DBF	D5,LAB_07C1		;1f580: 51cd0008
	MOVE.W	(A1)+,D4		;1f584: 3819
	MOVE.W	#$000f,D5		;1f586: 3a3c000f
LAB_07C1:
	ROXL.W	#1,D4			;1f58a: e354
	ROXL.W	#1,D6			;1f58c: e356
LAB_07C2:
	DBF	D5,LAB_07C3		;1f58e: 51cd0008
	MOVE.W	(A1)+,D4		;1f592: 3819
	MOVE.W	#$000f,D5		;1f594: 3a3c000f
LAB_07C3:
	ROXL.W	#1,D4			;1f598: e354
	ROXL.W	#1,D6			;1f59a: e356
	DBF	D5,LAB_07C4		;1f59c: 51cd0008
	MOVE.W	(A1)+,D4		;1f5a0: 3819
	MOVE.W	#$000f,D5		;1f5a2: 3a3c000f
LAB_07C4:
	ROXL.W	#1,D4			;1f5a6: e354
	ROXL.W	#1,D6			;1f5a8: e356
LAB_07C5:
	DBF	D5,LAB_07C6		;1f5aa: 51cd0008
	MOVE.W	(A1)+,D4		;1f5ae: 3819
	MOVE.W	#$000f,D5		;1f5b0: 3a3c000f
LAB_07C6:
	ROXL.W	#1,D4			;1f5b4: e354
	ROXL.W	#1,D6			;1f5b6: e356
LAB_07C7:
	DBF	D5,LAB_07C8		;1f5b8: 51cd0008
	MOVE.W	(A1)+,D4		;1f5bc: 3819
	MOVE.W	#$000f,D5		;1f5be: 3a3c000f
LAB_07C8:
	ROXL.W	#1,D4			;1f5c2: e354
	ROXL.W	#1,D6			;1f5c4: e356
	DBF	D5,LAB_07C9		;1f5c6: 51cd0008
	MOVE.W	(A1)+,D4		;1f5ca: 3819
	MOVE.W	#$000f,D5		;1f5cc: 3a3c000f
LAB_07C9:
	ROXL.W	#1,D4			;1f5d0: e354
	ROXL.W	#1,D6			;1f5d2: e356
	DBF	D5,LAB_07CA		;1f5d4: 51cd0008
	MOVE.W	(A1)+,D4		;1f5d8: 3819
	MOVE.W	#$000f,D5		;1f5da: 3a3c000f
LAB_07CA:
	ROXL.W	#1,D4			;1f5de: e354
	ROXL.W	#1,D6			;1f5e0: e356
	DBF	D5,LAB_07CB		;1f5e2: 51cd0008
	MOVE.W	(A1)+,D4		;1f5e6: 3819
	MOVE.W	#$000f,D5		;1f5e8: 3a3c000f
LAB_07CB:
	ROXL.W	#1,D4			;1f5ec: e354
	ROXL.W	#1,D6			;1f5ee: e356
	DBF	D5,LAB_07CC		;1f5f0: 51cd0008
	MOVE.W	(A1)+,D4		;1f5f4: 3819
	MOVE.W	#$000f,D5		;1f5f6: 3a3c000f
LAB_07CC:
	ROXL.W	#1,D4			;1f5fa: e354
	ROXL.W	#1,D6			;1f5fc: e356
	MOVE.W	D0,D1			;1f5fe: 3200
	BRA.W	LAB_07AA		;1f600: 6000fe36
LAB_07CD:
	CLR.W	D5			;1f604: 4245
	RTS				;1f606: 4e75
    
    