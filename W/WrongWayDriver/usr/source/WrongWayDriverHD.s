
		INCDIR	include:
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i
        INCLUDE	exec/memory.i
        INCLUDE	lvo/exec.i

		IFD BARFLY
		OUTPUT	"WrongWayDriver.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

;CHIP_ONLY
STACKSIZE = $1000

    IFD CHIP_ONLY
CHIPMEM = $80000
EXPMEM = STACKSIZE*2
    ELSE
CHIPMEM = $80000
EXPMEM = $80000
    ENDC
    
CHIP_START = $FF8-$1D0
PROGRAM_SIZE = $23300

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem 		;ws_flags
		dc.l	CHIPMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
		
;============================================================================
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
	
	
_name		dc.b	"Wrong Way Driver"
    IFD CHIP_ONLY
    dc.b    " (DEBUG/CHIP MODE)"
    ENDC
    dc.b    0
_copy		dc.b	"2021 pink^abyss",0
_info		dc.b	"adapted by JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

_data		dc.b	"data",0
program:
	dc.b	"WrongWayDriver",0

_config
 		dc.b	0

		dc.b	"$VER: WrongWayDriver slave "
		DECL_VERSION
		dc.b	$A,0
		EVEN

;======================================================================
_start						;a0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use

       ; install fake exec for AllocMem & AvailMem
        lea CHIP_START,A6
        move.l  A6,4.W
        move.l  #$FF,d0
        move.l  #$4AFC4AFC,d1   ; trash other vectors just in case...
.loop
        move.l  d1,-(a6)
        dbf d0,.loop
        move.l  4.W,a6
        lea (_LVOAllocMem,a6),a0
        move.w  #$4EF9,(a0)+
        pea fake_allocmem(pc)
        move.l  (a7)+,(a0)
        lea (_LVOAvailMem,a6),a0
        move.w  #$4EF9,(a0)+
        pea fake_availmem(pc)
        move.l  (a7)+,(a0)
        lea (_LVOCopyMem,a6),a0
        move.w  #$4EF9,(a0)+
        pea fake_copymem(pc)
        move.l  (a7)+,(a0)
    
    
        ;;bsr _SetupKeyboard


        ; chip already configured
        ; set fastmem. Note: in chip_only mode
        ; the fastmem size will be 0
		IFND	CHIP_ONLY
        move.l  _expmem(pc),a3
		add.l	#PROGRAM_SIZE,a3
        lea free_fastmem(pc),a0
        move.l  a3,(a0)+    ; start

        add.l   #EXPMEM-STACKSIZE*2,a3   ; minus stack
        move.l  a3,(a0) ; top

        move.l  _expmem(pc),A7
        add.l   #EXPMEM-STACKSIZE*2,A7 ; ssp stack on top of fastmem
		ELSE
		lea		CHIPMEM,A7
		ENDC

        move.l  A7,A0        
        sub.l   #STACKSIZE,A0   ; usb stack just below
        move.l  A0,USP
        move.w  #0,SR
		
        lea game_address(pc),a0
        IFD CHIP_ONLY
        move.l   #CHIP_START,d0
        ELSE        
        move.l  _expmem(pc),d0
        ENDC
        add.l   #8,d0
        move.l  d0,(a0)
        
        lea	_Tags(pc),a0
		move.l	_resload(pc),a2
		jsr	resload_Control(a2)
		
		lea	program(pc),a0	;Load main file
		move.l	game_address(pc),a1
        sub.l   #8,a1   ; for segments + align
		move.l	a1,a5
		bsr	_LoadFile
        bsr	_Relocate
        ; patch decrunch

        move.l  game_address(pc),d0
		
        subq.l  #4,d0
        lsr.l   #2,d0
        move.l  d0,a1
        lea pl_boot(pc),a0
        jsr resload_PatchSeg(a2)      
 		move.l	game_address(pc),-(a7)
        rts

pl_boot
	PL_START
    PL_P    $bc,end_unpack
	PL_W	$104,$4A43		; tst d3
	PL_NOP	$106,4			; skip color write
    PL_S    $8,$40-$8       ; skip intro text
	PL_END

pl_main
	PL_START
	; force 68000
    PL_NOP	$0035e,6
	PL_B	$00364,$60
	; skip open libs
    PL_S	$aa,$dc-$aa
	; skip debug code
	PL_NOP	$02988,6
	PL_NOP	$02996,2
	PL_B	$0299c,$60
	PL_NOP	$02a4e,6
	PL_NOP	$02a58,2
	PL_B	$02a5e,$60
	PL_B	$02cb6,$60   
	; skip graphics lib call
	PL_S	$001fa,$00220-$1FA
	PL_S	$002b8,$002d8-$002b8
	; bplcon3 write
	PL_NOP	$0033e,8
	PL_NOP	$0bb36,8
	; copperlist fix
	PL_PS	$0e7da,fix_copperlist_1
	PL_PS	$02a2c,fix_copperlist_2
	; bltdmod write
	PL_W	$06220,$4268	; word clear not long clear
	; extra wait blits
	; a combination of those extra wait blits fix the
	; trashed opponent & bonuses issue on fast machines
	; not sure which ones are really needed and which are
	; not, this isn't going to slow down the game since
	; those blits are only done when preparing data
	PL_PS	$12946,wait_blit_1
	PL_PS	$12950,wait_blit_2
	PL_PSS	$12cb6,wait_blit_3,2
	PL_PSS	$0e748,wait_blit_4,2
	PL_PSS	$0e764,wait_blit_4,2
	PL_PS	$0d1ee,wait_blit_5
	PL_PSS	$0dd82,wait_blit_6,2
	PL_PSS	$07afe,wait_blit_11,2
	;PL_PS	$08780,wait_blit_7
	PL_PSS	$08764,wait_blit_8,2
	;PL_PS	$08820,wait_blit_9
	PL_PSS	$863E,wait_blit_10,2
	PL_END
  
    
CIAA_PRA = $bfe001
CIAA_SDR = $BFEC01

wait_blit
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
	
wait_blit_11
	bsr		wait_blit
	move.l a1,(16,a3)	;07afe: 11ae27490010
	MOVE.L	A5,12(A3)		;07b02: 274d000c
	rts
	
wait_blit_1
	bsr		wait_blit
	ADDQ.W	#1,A1			;12946: 5249
	MOVE.W	A1,D0			;12948: 3009
	CMP.W	A5,D0			;1294a: b04d
	rts
	
wait_blit_2
	; after blit loop, force wait
	bsr		wait_blit
	MOVEA.L	96+4(A7),A3		;12950: 266f0060
	MOVE.W	A6,D6			;13950: 3c0e
	rts
	
wait_blit_3
	MOVE.W	D1,(88,A0)		;12cb6: 31410058
	ADDQ.W	#1,(92+4,A7)		;12cba: 526f005c
	bra		wait_blit

wait_blit_4
	MOVE.W	D4,(24,A2)		;0e764: 35440018
	ADD.W	(112+4,A7),D5		;0e768: da6f0070
	bra		wait_blit
wait_blit_5
	bsr		wait_blit
	ADDQ.W	#1,D6			;0d1ee: 5246
	CMP.W	(124+4,A7),D6		;0d1f0: bc6f007c
	rts
wait_blit_6
	bsr		wait_blit
	ADD.W	(72+4,A7),D7		;0dd82: de6f0048
	MOVE.W	(72+4,A7),D6		;0dd86: 3c2f0048
	rts
	
wait_blit_7
	move.w a0,($0018,a3)
	move.l	#$8222,(a7)
	;add.l	#$EA9C,(a7)
	bra		wait_blit
	
wait_blit_8	
	MOVE.W	D6,(24,A3)		;08764: 37460018
	ADDQ.W	#1,(66+4,A7)		;08768: 526f0042
	bra		wait_blit

wait_blit_9
	MOVE.W	A3,(88,A2)		;08820: 354b0058
	move.l	#$848E,(a7)
	;add.w	#$ec68,(a7)
	bra		wait_blit
	

wait_blit_10
	MOVE.W	D5,(24,A3)		;0863e: 37450018
	LEA	(14278,A4),A4		;08642: 49ec37c6
	bra		wait_blit
	
fix_copperlist_1
	MOVE.W	#$0040,(150,A0)
	move.l	a0,-(a7)
	move.l	d0,a0	; copperlist start
	move.w	#$5600,$6178A-$616EC(a0)	; fix bplcon0 issue
	move.w	#$0200,$61822-$616EC(a0)	; fix bplcon0 issue
	move.w	#$4200,$61892-$616EC(a0)	; fix bplcon0 issue
	move.l	(a7)+,a0
	rts
	
fix_copperlist_2
	MOVE.W	#$0040,(150,A0)
	move.l	a0,-(a7)
	move.l	d0,a0	; copperlist start
	move.w	#$5600,$6338e-$632F0(a0)	; fix bplcon0 issue
	move.w	#$0200,$63426-$632F0(a0)	; fix bplcon0 issue
	move.w	#$4200,$63496-$632F0(a0)	; fix bplcon0 issue
	move.l	(a7)+,a0
	rts
	
    
end_unpack
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    lea  (4,a3),a3
	move.l	a3,a1
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)

    movem.l (a7)+,d0-d1/a0-a2
    jmp (a3)
    
	
    ; AllocMem/AvailMem emulation. No need to go full kickemu
    ; since the game never frees the memory it allocates,
    ; making implementation of AllocMem & AvailMem (almost)
    ; trivial. Well, I have added fastmem support to OSEmu so
    ; I can assure you that is trivial in comparison!
	; 
	; MEMF_CLEAR is not emulated, not needed here because slave
	; is configured with WHDLF_ClearMem (else it fails)
    
fake_allocmem
    move.l  d2,-(a7)
    move.l  d1,d2
    and.l   #MEMF_CHIP+MEMF_FAST,d2 ; keep only those
    btst    #MEMB_CHIP,d2
    beq.b   .fast
.chip
    lea free_chipmem(pc),a0
    bra.b .alloc
.fast
    lea free_fastmem(pc),a0
.alloc
    ; round size on 4 bytes
    move.l  d0,d1
    and.b   #$FC,d1
    cmp.b   d0,d1
    beq.b   .aligned
    addq.l  #4,d1
    move.l  d1,d0       ; new size rounded on 4 bytes
.aligned
    ; get available memory
    move.l  (4,a0),d1
    sub.l   (a0),d1
    cmp.l   d0,d1
    bcs.b   .not_enough
    ; enough memory available, allocate
    move.l  d0,d1   ; size
    move.l  (a0),d0 ; address
    add.l   d1,(a0) ; update memory start

    IFEQ    1
    ; temp compute free memory
    lea free_chipmem(pc),a0
    move.l  (4,a0),$100
    move.l  (a0),d2
    sub.l   d2,$100
    lea free_fastmem(pc),a0
    move.l  (4,a0),$104
    move.l  (a0),d2
    sub.l  d2,$104
    ENDC
    
    move.l  (a7)+,d2
    tst.l   d0
    rts
    
.not_enough
    tst.l   d2
    bne.b   .out
    ; no particular memory required: perform a second pass
    ; with chipmem
    move.l  #MEMF_CHIP,d2
    bra   .chip
.out
    moveq.l #0,d0
    move.l  (a7)+,d2
    rts

; A0: source
; A1: dest
; D0: len
fake_copymem
    movem.l d2-d3,-(a7)
    ; borrowed from JST code :)
	cmp.l	A0,A1
	beq.b	.exit		; same regions: out
	bcs.b	.copyfwd	; A1 < A0: copy from start

	tst.l	D0
	beq.b	.exit		; length 0: out

	; here A0 > A1, copy from end

	add.l	D0,A0		; adds length to A0
	cmp.l	A0,A1
	bcc.b	.cancopyfwd	; A0+D0<=A1: can copy forward (optimized)
	add.l	D0,A1		; adds length to A1 too

.copybwd:
	move.b	-(A0),-(A1)
	subq.l	#1,D0
	bne.b	.copybwd

.exit
    movem.l (a7)+,d2-d3
    rts
.cancopyfwd:
	sub.l	D0,A0		; restores A0 from A0+D0 operation
.copyfwd:
	move.l	A0,D1
	btst	#0,D1
	bne.b	.fwdbytecopy	; src odd: byte copy
	move.l	A1,D1
	btst	#0,D1
	bne.b	.fwdbytecopy	; dest odd: byte copy

	move.l	D0,D2
	lsr.l	#4,D2		; divides by 16
	move.l	D2,D3
	beq.b	.fwdbytecopy	; < 16: byte copy

.fwd4longcopy
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	move.l	(A0)+,(A1)+
	subq.l	#1,D2
	bne.b	.fwd4longcopy

	lsl.l	#4,D3		; #of bytes*16 again
	sub.l	D3,D0		; remainder of 16 division

.fwdbytecopy:
	tst.l	D0
	beq.b	.exit
.fwdbytecopy_loop:
	move.b	(A0)+,(A1)+
	subq.l	#1,D0
	bne.b	.fwdbytecopy_loop
	bra.b	.exit
    
    ; we're ignoring MEMF_LARGEST, assuming free memory is all contiguous
fake_availmem
    btst    #MEMB_CHIP,d1
    beq.b   .fast
    lea free_chipmem(pc),a0
    bra.b .calc
.fast
    lea free_fastmem(pc),a0
.calc
    move.l  (4,a0),d0
    sub.l   (a0),d0
    rts

free_chipmem:
    IFD CHIP_ONLY
    dc.l    CHIP_START+PROGRAM_SIZE   ; start
    ELSE
	; fastmem
    dc.l    CHIP_START  ; chip hunk comes first
    ENDC
    dc.l    CHIPMEM

    
    ; initialized dynamically at startup
free_fastmem
    dc.l    0   ; start
    dc.l    0   ; top
    
	
    include whdload/keyboard.s

;======================================================================
_LoadFile	movem.l	d0-d1/a0-a2,-(sp)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		movem.l	(sp)+,d0-d1/a0-a2
		rts

;======================================================================

_Relocate	movem.l	d0-d1/a0-a2,-(sp)
		move.l	a5,a0
        clr.l   -(a7)                   ;TAG_DONE
        pea     -1                      ;true
        pea     WHDLTAG_LOADSEG
        pea     8                       ;8 byte alignment
        pea     WHDLTAG_ALIGN
        move.l  a7,a1                   ;tags		move.l	_resload(pc),a2
		jsr	resload_Relocate(a2)
        add.w   #5*4,a7
        movem.l	(sp)+,d0-d1/a0-a2
		rts


		
		
;======================================================================
_resload	dc.l	0			;Resident loader
game_address
    dc.l    0
    
_Tags		dc.l	WHDLTAG_BUTTONWAIT_GET
_ButtonWait	dc.l	0
		dc.l	WHDLTAG_CUSTOM1_GET
_Custom1	dc.l	0
		dc.l	TAG_DONE
;======================================================================

_quit		pea	TDREASON_OK
		bra	_end
_wrongver	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

		END
