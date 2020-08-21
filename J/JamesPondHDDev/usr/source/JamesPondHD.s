;*---------------------------------------------------------------------------
;  :Program.	JamesPondHD.asm
;  :Contents.	Slave for "James Pond" from Millenium
;  :Author.	JOTD
;  :History.	28.01.05
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	Devpac 3.14
;  :To Do.
;---------------------------------------------------------------------------*

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	JamesPond.slave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC

; this source code allows to generate 512k chip and 1Meg slave version
; one version requires 1Meg, other don't

    IFD USE_FASTMEM
USE_EXPMEM
CHIPMEMSIZE = $80000
EXPMEMSIZE = $80000
    ENDC
    IFD USE_CHIPMEM
USE_EXPMEM
CHIPMEMSIZE = $100000
EXPMEMSIZE = $0
    ENDC
    
    IFND    USE_EXPMEM
    ; 3 versions don't require an expansion
CHIPMEMSIZE = $80000
EXPMEMSIZE = $0    
    ENDC
    
;======================================================================

_base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	17		;ws_Version
		dc.w	WHDLF_Disk|WHDLF_NoError|WHDLF_ClearMem	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	start-_base	;ws_GameLoader
		dc.w	0		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	$0		;ws_keydebug
_keyexit	dc.b	$5D		;ws_keyexit = '*'
_expmem
        dc.l	EXPMEMSIZE			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0			;ws_kickname
		dc.l	0			;ws_kicksize
		dc.w	0			;ws_kickcrc
		dc.w	_config-_base		;ws_config

_config		
        dc.b	"C1:X:infinite lives:0;"
        dc.b	"C1:X:invincibility:1;"
        dc.b	"C1:X:infinite time:2;"
        dc.b	"C3:L:start level:"
        dc.b    "Licence to bubble,From sellafield with love,"        
        dc.b    "View to a spill!,The fish with the golden bar,"        
        dc.b    "For your fins only,Fishfingers,They only live once,"        
        dc.b    "Leak and let die,Orchids are forever,Moneyraker,"        
        dc.b    "The mermaid who loved me,Dr maybe;"                
        dc.b	"C5:B:disable fast CPUs fixes;"
        dc.b    0
		even

;============================================================================

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC


DECL_VERSION:MACRO
	dc.b	"2.3"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

_name		dc.b	"James Pond: Underwater Agent"
		dc.b	0
_copy		dc.b	"1990 Millenium",0
_info		dc.b	"adapted & fixed by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0

START_TRACK	equ	66
WHICH_SIDE	equ	1
NUM_TRACKS	equ	14
LOAD_AREA	equ	$2CD4
cside = 602
ctrack = 604
ccount = 608
cdma = 610
cbase = cside


    
MFMALT_OFFSET = $51400
MFMALT_START = $2EE4
MFMALT_JUMP = $13030
MFMALT_LENGTH = $12BC4

;======================================================================
start	;	A0 = resident loader
;======================================================================

	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use

	move.l	a0,a2
	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	lea	CHIPMEMSIZE-$100,a7

    IFD USE_EXPMEM
	; load & version check
    ; the latest version submitted doesn't follow the same boot sequence
    ; check if this is that version (which requires 1MB)
    lea $400.W,a0
	move.l	#$4,d1
    moveq.l  #1,d2
	move.l	#MFMALT_OFFSET,d0		; current offset
	jsr	resload_DiskLoad(a2)
    move.l  $400.W,d0
    cmp.l   #$601A0001,d0
    bne   .not_alternate
    ; MFM non SPS has a slightly different structure
    lea MFMALT_START,a0
	move.l	#MFMALT_LENGTH,d1
	move.l	#MFMALT_OFFSET,d0		; current offset
	jsr	resload_DiskLoad(a2)

    ; change variable addresses
    lea side_flag(pc),a4
    move.l #$284A,(a4)
    lea start_track(pc),a4
    move.l  #$284C,(a4)
    lea start_sector(pc),a4
    move.l  #$284E,(a4)
    lea nb_sectors_to_read(pc),a4
    move.l  #$2850,(a4)
    lea disk_buffer(pc),a4
    move.l  #$2852,(a4)


    IFD USE_CHIPMEM
    lea _expmem(pc),a0
    move.l  #$80000,(a0)       ; expmem
    ENDC
    move.l  _expmem(pc),$7FFFC
    
	bsr	patch_blits
    
    lea load_routine(pc),a0
    move.l #$12ec8,(a0)
    lea scores_address(pc),a0
    move.l  #$1184c,(a0)

	bsr	read_scores
	
	lea	pl_main_mfmalt(pc),a0
	sub.l	A1,A1
	jsr	resload_Patch(a2)
		
    
	move.w	#$2700,sr
	move.w	#$7FFF,$dff09a
	move.w	#$7FFF,$dff09c
   
    jmp $13042
    
.not_alternate
    ENDC
    
    
    ; SPS & re-release (DOStrack)
	move.l	a7,a5
	sub.l	#cbase,a5

	move.w	#WHICH_SIDE,cside(a5)
	move.w	#START_TRACK,ctrack(a5)
	move.w	#NUM_TRACKS,ccount(a5)
	move.l	#LOAD_AREA,cdma(a5)

	bsr	read_sectors_boot

	lea	LOAD_AREA,A0
	move.l	#$1400,d0	
	jsr	resload_CRC16(a2)
	cmp.w	#$83F9,d0
	beq.b	.sps_3015
    cmp.w   #$BA51,d0
	beq.b	.sps_3016
	cmp.w	#$E456,d0
	beq.b	.rerel
    cmp.w   #$9821,d0
	bne	wrong_version

    ; special message for the 512k slave
	pea	.needs_other_slave(pc)
	pea	(TDREASON_FAILMSG).w
	move.l	_resload(pc),a0
	jmp	resload_Abort(a0)
	    
    
    
	bra	wrong_version
    
.rerel
	lea	version(pc),a0
	move.l	#1,(a0)

	bsr	load_boot_rerel
.sps_3015
	bsr	patch_blits

    lea load_routine(pc),a0
    move.l #$124c8,(a0)
    lea scores_address(pc),a0
    move.l  #$114a8,(a0)

	bsr	read_scores
	
	lea	pl_main_3015(pc),a0
	sub.l	A1,A1
	jsr	resload_Patch(a2)
		
    
	move.w	#$2700,sr
	move.w	#$7FFF,$dff09a
	move.w	#$7FFF,$dff09c

	jmp	$12632
.sps_3016
	bsr	patch_blits

    lea load_routine(pc),a0
    move.l #$125f8,(a0)
    lea scores_address(pc),a0
    move.l  #$115d8,(a0)


	bsr	read_scores
	
	lea	pl_main_3016(pc),a0
	sub.l	A1,A1
	jsr	resload_Patch(a2)

    
	move.w	#$2700,sr
	move.w	#$7FFF,$dff09a
	move.w	#$7FFF,$dff09c

	jmp	$12768
    
.needs_other_slave
    dc.b    "This game version requires the other slave: JamesPond1MB.slave",0
    even

load_boot_rerel
	lea	LOAD_AREA,a3
	move.l	#$B6E00,d3	; offset
	move	#$D,d4		; nb of tracks to read - 1
	move.l	_resload(pc),a2
	moveq	#1,d2
	move.l	#$1400,d5
.loop
	move.l	d5,d1
	move.l	a3,a0		; current buffer
	move.l	d3,d0		; current offset
	jsr	resload_DiskLoad(a2)
	add.l	d5,a3
	add.l	#$2C00,d3
	dbf	d4,.loop
	rts

wrong_version
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts

; A5: base for disk load

read_sectors_boot
	movem.l	d0-a6,-(a7)
	move.l	cdma(a5),a0	; destination
	moveq	#0,d1
	move.w	ccount(a5),d1

	mulu	#$1400,d1	; length
	
	add.l	d1,cdma(a5)	; update buffer start
	clr.w	ccount(a5)	; clear track count

	moveq	#0,d0
	move.w	ctrack(a5),d0	; start track
	subq.w	#1,d0		; minus 1 (image starts at track 2 head 0)

	tst.w	cside(a5)
	beq.b	.do
	add.w	#79,d0	; side 1
.do
	mulu	#$1400,d0	; offset
	moveq	#1,d2
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)	
	movem.l	(a7)+,d0-a6
	rts

read_sectors_game
	movem.l	d0,-(a7)
	move.l	version(pc),d0
	beq.b	.orig
	bsr	read_sectors_rerel
	bra.b	.out
.orig
	bsr	read_sectors_orig
.out
	movem.l	(a7)+,d0
	rts




; this is a tricky routine, because the version is either a re-release
; or a crack (sold to Chris as a re-release, maybe :))
;
; rerelease: disk map different from original since DIC has been used
; to read the disk, and thus data is not contiguous (on original disk
; data is stored on each side, without alterning sides)

read_sectors_rerel
	movem.l	d1-a6,-(a7)
	moveq	#0,D0
	moveq	#0,D1
	moveq	#0,D2
	moveq	#0,D3
	moveq	#0,D5
	
    move.l  side_flag(pc),a4
	move.w	(a4),D0	; disk side
	mulu.w	#$B,D0
	lsl.l	#8,D0
	add.l	D0,D0		; 0 or $1600 offset depending on side
	

	move.l	start_track(pc),a4	; start track (track = both sides ($2C00))
	move.w	(a4),D1
	mulu.w	#$B,D1
	lsl.l	#8,D1
	add.l	D1,D1
	add.l	D1,D1
	add.l	D0,D1

	move.l	disk_buffer(pc),a4	; destination buffer
	move.l	(a4),A0	; destination buffer

	move.l	start_sector(pc),a4	; sector offset
	move.w	(a4),D5	; sector offset
	subq	#1,D5
	lsl.l	#7,D5

	add.l	D5,D5
	add.l	D5,D5		; *4

	move.l	D5,D2
	add.l	D1,D2		; total disk offset in D2: OK


	move.l	#$1400,D1	; real track length
	sub.l	D5,D1		; substracts offset
	bmi	.error		; try to read boot?

	move.l	nb_sectors_to_read(pc),a4
	move.w	(a4),D3
	lsl.l	#7,D3
	add.l	D3,D3
	add.l	D3,D3	; total length to read

	move.l	_resload(pc),a2
.loop
	movem.l	a0/d1-d2,-(a7)
	move.l	d2,d0
	moveq	#1,d2
	jsr	(resload_DiskLoad,a2)	
	movem.l	(a7)+,a0/d1-d2

	add.l	D1,A0		; updates buffer start
	add.l	D1,D2		; adds length to offset
	add.l	#$1800,D2	; change of side
	sub.l	D1,D3
	bcs	.quit
	beq	.quit

	move.l	#$1400,D1	; reload real track length
	cmp.l	D3,D1
	bcs.b	.loop
	move.l	D3,D1		; less than $1400 because D3 is lower than that
	bra.b	.loop
.quit
    move.l disk_buffer(pc),a4
	move.l	A0,(a4)
    move.l nb_sectors_to_read(pc),a4
	clr.w	(a4)

	movem.l	(a7)+,d1-a6
	RTS
.error
	illegal

read_sectors_orig
	movem.l	d1-a6,-(a7)
	move.l	disk_buffer(pc),a4
	move.l	(a4),a0	; destination
	moveq	#0,d1
	move.l	nb_sectors_to_read(pc),a4
	move.w	(a4),d1
	mulu	#$200,d1	; length	

	moveq	#0,d0
    move.l  start_track(pc),a4
	move.w	(a4),d0	; start track
;;	add.w	d1,start_track	; update start track
	subq.w	#1,d0		; start track minus 1 (image starts at track 1 head 0)


    move.l  side_flag(pc),a4
	tst.w	(a4)
	beq.b	.do
	add.w	#79,d0	; side 1
.do
	mulu	#$1400,d0	; offset

	moveq.l	#0,d5
    move.l  start_sector(pc),a4
	move.w	(a4),D5
	subq	#1,D5
	lsl.l	#7,D5
	add.l	D5,D5
	add.l	D5,D5		; *512

	add.l	d5,d0		; offset += sector offset

	moveq	#1,d2
	movem.l	a0/d1,-(a7)
	move.l	_resload(pc),a2
	jsr	(resload_DiskLoad,a2)	
	movem.l	(a7)+,a0/d1

	move.l	disk_buffer(pc),a4
	add.l	d1,(a4)	; update buffer start
	move.l	nb_sectors_to_read(pc),a4
	clr.w	(a4)		; clear sector count

	movem.l	(a7)+,d1-a6
	rts

;-------


patch_blits
    move.l  _slow_68000(pc),d0
    bne.b   .skip
	lea	blitwait_d1(pc),a0
	move.l	a0,d0

	move.l	#$23C900DF,d1
	move.w	#$F054,d2

	lea	$A000,A0
	lea	$B000,A1

.loop
	cmp.l	(A0),D1
	beq.b	.found
.next
	addq.l	#2,A0
	cmp.l	A0,A1
	bne.b	.loop
.skip
	rts

.found
	cmp.w	4(A0),D2
	bne.b	.next
	
	; *** sequence found, let's patch

	move.w	#$4EB9,(A0)+
	move.l	D0,(A0)

	bra.b	.next


pl_blitter
	PL_START
	; blitter stuff
    PL_IFC5
    PL_ELSE
	PL_P	$AA,blitwait_a1_a6
	PL_P	$B0,blitwait_a4_a5
	PL_P	$B6,blitwait_a5_a6

	PL_PS	$048EC,blitter_force_dma
	PL_PS	$04926,move_a0_dff050
	PL_PS	$04946,blitter_dma_end
	PL_PS	$0A602,blitter_dma_end
	PL_PS	$0A68A,move_imml_4b89a_dff054
	PL_PS	$0A6A4,move_imml_4bf2a_dff054
	PL_PS	$0A6BE,move_imml_4c5ba_dff054
	PL_PS	$0A81A,blitter_force_dma
	PL_PS	$0a938,move_a0_dff054
	PL_PS	$0a948,move_a2_dff050
;;;	PL_PS	$0a952,move_a0_dff054
	PL_PS	$0a962,move_a2_dff050
;;;	PL_PS	$0a96c,move_a0_dff054
	PL_PS	$0A978,blitter_dma_end
	PL_PS	$0aa50,clr_dff064
	PL_PS	$0aa98,move_d7_dff046
	PL_PS	$0ab14,move_a3_dff04c
	PL_PS	$0ab3a,move_a3_dff04c
	PL_PS	$0ab60,move_a3_dff04c
	PL_PS	$0abc8,move_d7_dff046
	PL_PS	$0ac2a,move_a3_dff054
	PL_PS	$0ac40,move_a1_dff050
;;;	PL_PS	$0ac4c,move_a2_dff054
	PL_PS	$0AD2E,blitter_dma_end
	PL_PS	$0ADCE,blitter_force_dma
	PL_P	$0add6,clr_dff042	; followed by RTS
	PL_PSS	$0aea2,blitwait_9f0_dff040,2
	PL_PS	$0AED4,blitter_force_dma_3
	PL_PS	$0aeec,move_a1_dff054
	PL_PS	$0AF00,blitter_dma_end
	PL_PS	$0AF34,blitter_force_dma_3
	PL_PS	$0af52,move_a1_dff054
	PL_PS	$0AF6A,blitter_dma_end
	PL_PS	$0AFD8,blitter_force_dma
	PL_PSS	$0afe0,move_ffff_dff044,2
	PL_PS	$0b020,move_a0_dff050
	PL_PS	$0B036,blitter_dma_end
	PL_PS	$0BDB6,blitter_force_dma
	PL_PS	$0bdde,move_addrs_275c_dff054
	PL_PS	$0bdee,move_addrs_2760_dff054
	PL_PS	$0BDFE,blitter_dma_end
	PL_PS	$0BE08,blitter_force_dma
	PL_PS	$0be38,move_d0_dff054
	PL_PS	$0be4c,move_d0_dff054
	PL_PS	$0BE5A,blitter_dma_end
    PL_ENDIF
	PL_END
    
pl_blitter_3015:
    PL_START
    PL_IFC5
    PL_ELSE
	PL_PSS	$0c6e8,blitwait_0_dff066,2
	PL_PS	$0C6FE,blitter_force_dma_3
	PL_PS	$0C718,blitter_dma_end
	PL_PS	$0CCE6,blitter_dma_end
	PL_PSS	$0ecc8,move_d5_64_clr_66,2
	PL_L	$0ECFE,$4EB800B6
	PL_L	$0ED10,$4EB800B6
	PL_L	$0ED1C,$4EB800B6
	PL_L	$0ED28,$4EB800B6
	PL_PS	$0ED42,move_d5_a6_swap

	PL_L	$0ED8C,$4EB800AA
	PL_L	$0EDA4,$4EB800AA
	PL_L	$0EDB8,$4EB800AA

	PL_PS	$0EDF4,blitter_force_dma
	PL_PS	$0EE5A,blitter_dma_end
	PL_PS	$0ee98,move_ffff_dff044
	PL_PS	$0EEBC,blitter_force_dma_2
	PL_L	$0EED4,$4EB800B0
	PL_L	$0EEE0,$4EB800B0
	PL_P	$0eeec,patch_eeec
	PL_PS	$0EEF4,blitter_dma_end_2
	PL_PS	$117EC,blitter_force_dma
	PL_PS	$11820,move_d0_dff054
	PL_PS	$11832,move_d1_dff054
	PL_PS	$11840,blitter_dma_end
	PL_PS	$11A3E,blitter_dma_end
	PL_PS	$11A74,blitter_dma_end

    PL_ENDIF
	PL_NEXT pl_blitter
    
pl_blitter_3016:
    PL_START
    PL_IFC5
    PL_ELSE
	PL_PSS	$0c6c0,blitwait_0_dff066,2
    
	PL_PS	$0c6d6,blitter_force_dma_3
	PL_PS	$0c6f0,blitter_dma_end
	PL_PS	$0ccbe,blitter_dma_end

	PL_PSS	$0eca0,move_d5_64_clr_66,2
	PL_L	$0ecd6,$4EB800B6
	PL_L	$0ece8,$4EB800B6
	PL_L	$0ecf4,$4EB800B6
	PL_L	$0ed00,$4EB800B6
	PL_PS	$0ed1a,move_d5_a6_swap

	PL_L	$0ed64,$4EB800AA
	PL_L	$0ed7c,$4EB800AA
	PL_L	$0ed90,$4EB800AA
	PL_L	$0eda4,$4EB800AA

	PL_PS	$0edcc,blitter_force_dma
	PL_PS	$0ee32,blitter_dma_end
	PL_PS	$0ee70,move_ffff_dff044
	PL_PS	$0ee94,blitter_force_dma_2
	PL_L	$0eeac,$4EB800B0
	PL_L	$0eeb8,$4EB800B0
	PL_P	$0eec4,patch_eeec
	PL_PS	$0eecc,blitter_dma_end_2
	PL_PS	$1190c,blitter_force_dma
	PL_PS	$11940,move_d0_dff054
	PL_PS	$11952,move_d1_dff054
	PL_PS	$11960,blitter_dma_end
	PL_PS	$11b5e,blitter_dma_end
	PL_PS	$11b94,blitter_dma_end
    PL_ENDIF
    
	PL_NEXT pl_blitter

pl_blitter_mfmalt
	PL_START
	; blitter stuff
    PL_IFC5
    PL_ELSE
	PL_P	$AA,blitwait_a1_a6
	PL_P	$B0,blitwait_a4_a5
	PL_P	$B6,blitwait_a5_a6

	PL_PS	$04afc,blitter_force_dma
    
	PL_PS	$04b36,move_a0_dff050
	PL_PS	$04946,blitter_dma_end
	PL_PS	$04b56,blitter_dma_end
	PL_PS	$0a89a,move_imml_4b89a_dff054
	PL_PS	$0a8b4,move_imml_4bf2a_dff054
	PL_PS	$0a8ce,move_imml_4c5ba_dff054
	PL_PS	$0aa2a,blitter_force_dma
	PL_PS	$0ab48,move_a0_dff054
	PL_PS	$0ab58,move_a2_dff050
;;;	PL_PS	$0a952,move_a0_dff054
	PL_PS	$0ab72,move_a2_dff050
;;;	PL_PS	$0a96c,move_a0_dff054
	PL_PS	$0ab88,blitter_dma_end
	PL_PS	$0ac60,clr_dff064
	PL_PS	$0aca8,move_d7_dff046
	PL_PS	$0ad24,move_a3_dff04c
	PL_PS	$0ad4a,move_a3_dff04c
	PL_PS	$0ad70,move_a3_dff04c
	PL_PS	$0add8,move_d7_dff046
	PL_PS	$0ae3a,move_a3_dff054
	PL_PS	$0ae50,move_a1_dff050
;;;	PL_PS	$0ac4c,move_a2_dff054
	PL_PS	$0af3e,blitter_dma_end
	PL_PS	$0afde,blitter_force_dma
	PL_P	$0afe6,clr_dff042	; followed by RTS
	PL_PSS	$0b0b2,blitwait_9f0_dff040,2
	PL_PS	$0b0e4,blitter_force_dma_3
	PL_PS	$0b0fc,move_a1_dff054
	PL_PS	$0b110,blitter_dma_end
    
	PL_PS	$0b144,blitter_force_dma_3
	PL_PS	$0b162,move_a1_dff054
	PL_PS	$0b17a,blitter_dma_end
	PL_PS	$0b1e8,blitter_force_dma
	PL_PSS	$0b1f0,move_ffff_dff044,2
	PL_PS	$0b230,move_a0_dff050
	PL_PS	$0b246,blitter_dma_end
	PL_PS	$0bfdc,blitter_force_dma
	PL_PS	$0c004,move_addrs_275c_dff054
	PL_PS	$0c014,move_addrs_2760_dff054
	PL_PS	$0c024,blitter_dma_end
	PL_PS	$0c02e,blitter_force_dma
	PL_PS	$0c05e,move_d0_dff054
	PL_PS	$0c072,move_d0_dff054
	PL_PS	$0c080,blitter_dma_end
    
	PL_PSS	$0c908,blitwait_0_dff066,2
	PL_PS	$0c91e,blitter_force_dma_3
	PL_PS	$0c938,blitter_dma_end
	PL_PS	$0cf0e,blitter_dma_end
	PL_PSS	$0eefe,move_d5_64_clr_66,2
	PL_L	$0ef34,$4EB800B6
	PL_L	$0ef46,$4EB800B6
	PL_L	$0ef52,$4EB800B6
	PL_L	$0ef5e,$4EB800B6
	PL_PS	$0ef78,move_d5_a6_swap

	PL_L	$0efc2,$4EB800AA
	PL_L	$0efda,$4EB800AA
	PL_L	$0efee,$4EB800AA

	PL_PS	$0f02a,blitter_force_dma
	PL_PS	$0f090,blitter_dma_end
	PL_PS	$0f0ce,move_ffff_dff044
	PL_PS	$0f0f2,blitter_force_dma_2
	PL_L	$0f10a,$4EB800B0
	PL_L	$0f116,$4EB800B0
	PL_P	$0f122,patch_eeec
	PL_PS	$0f12a,blitter_dma_end_2
	PL_PS	$11b80,blitter_force_dma
	PL_PS	$11bb4,move_d0_dff054
	PL_PS	$11bc6,move_d1_dff054
	PL_PS	$11bd4,blitter_dma_end
	PL_PS	$11dd2,blitter_dma_end
	PL_PS	$11e08,blitter_dma_end
    PL_ENDIF
	PL_END
    


pl_main_mfmalt
	PL_START

    PL_IFC1X    0
    PL_NOP  $09cf8,6
    PL_ENDIF
    
    PL_IFC1X    1
    PL_NOP	$0b448,2
    PL_ENDIF
    
    PL_IFC1X    2
    PL_S    $0aa84,$96-$84
    PL_ENDIF
    
    PL_S    $13068,$10      ; skip mem clear, already done at whdload startup
    
    IFD    USE_FASTMEM
    PL_PS   $11fd2,set_expmem
    PL_S    $11fd8,$12018-$11fd8
    ENDC
    
    PL_PS  $0b30e,set_start_level
    
    ; load & fix module player routine
    PL_PSS  $0b2d8,load_music_code_game,6
    PL_PS  $1009a,load_music_code_title
    
	; keyboard interrupt & timer fix

	PL_PS	$0c56c,kb_int
	PL_PS	$0c516,kb_delay

	; copperlist

	;;PL_PS	$C1A2xx,set_copperlist_3015

	; protection (ripped by comparing original -> rerelease)

	PL_NOP	$0b2b0,$2
	PL_NOP	$132ec,$4
	PL_L	$132f0,$4e712a3c
	PL_L	$132f4,$00000002

	; extra stuff (protection + speedup)

;	PL_I	$1054Axx
;	PL_I	$128A0xx
;	PL_I	$C1B2xx

	PL_S	$1306e,$90-$6E	; skip disk & clr mem stuff
	PL_S	$13240,$BC-$5C


	; remove disk accesses

	PL_R	$10a94
	PL_R	$10a42
	PL_R	$10a82
	PL_R	$10b22
	PL_R	$10ad6
	PL_R	$10b38
	PL_R	$10a08
	PL_W	$130a0,$6006
	PL_L	$1323c,$600000B2

	; load

	PL_P	$10702,read_sectors_game

	; remove a delay

	PL_NOP	$126b0,$4

	; decrunch
	
	PL_P	$0caf4,decrunch

	; hiscore save

	PL_PSS	$11ee2,write_scores,2

	PL_NEXT pl_blitter_mfmalt
    
    
pl_main_3015
	PL_START

    PL_IFC1X    0
    PL_NOP  $09ae8,6
    PL_ENDIF
    
    PL_IFC1X    1
    PL_NOP	$B238,2
    PL_ENDIF
    

    PL_IFC1X    2
    PL_S    $0a874,$96-$84
    PL_ENDIF

    
    PL_PS  $0b0fe,set_start_level
    
    ; load & fix module player routine
    PL_PSS  $0b0c8,load_music_code_game,6
    PL_PS  $0fe64,load_music_code_title
    
	; keyboard interrupt & timer fix

	PL_PS	$C346,kb_int
	PL_PS	$C2F0,kb_delay

	; copperli-st

	PL_PS	$C1A2,set_copperlist_3015

	; protection (ripped by comparing original -> rerelease)

	PL_NOP	$0000b0a0,$2
	PL_NOP	$00012908,$4
	PL_L	$0001290c,$4e712a3c
	PL_L	$00012910,$00000002

	; extra stuff (protection + speedup)

	PL_I	$1054A
	PL_I	$128A0
	PL_I	$C1B2

	PL_S	$1265E,$74-$5E	; skip disk & clr mem stuff
	PL_S	$1285C,$BC-$5C


	; remove disk accesses

	PL_R	$10858
	PL_R	$10806
	PL_R	$10846
	PL_R	$108E6
	PL_R	$1089A
	PL_R	$108FC
	PL_R	$107CC
	PL_W	$126C4,$6006
	PL_L	$12858,$600000B2

	; load

	PL_P	$104CC,read_sectors_game

	; remove a delay

	PL_NOP	$126B0,$4

	; decrunch
	
	PL_P	$C8D4,decrunch

	; hiscore save

	PL_PSS	$11B4E,write_scores,2

	PL_NEXT pl_blitter_3015

pl_main_3016
	PL_START

    PL_IFC1X    0
    PL_NOP  $09ae8,6
    PL_ENDIF
    
    PL_IFC1X    1
    PL_NOP	$B238,2
    PL_ENDIF

    PL_IFC1X    2
    PL_S    $0a874,$96-$84
    PL_ENDIF
    
    PL_PS  $0b0fe,set_start_level
    
    ; load & fix module player routine
    PL_PSS  $0b0c8,load_music_code_game,6
    PL_PS   $0fe3c,load_music_code_title

	; keyboard interrupt & timer fix

	PL_PS	$C346,kb_int
	PL_PS	$C2F0,kb_delay

	; copperlist

	PL_PS	$C1A2,set_copperlist_3016

	; protection (ripped by comparing original -> rerelease)

	PL_NOP	$0000b0a0,$2
;	PL_NOP	$00012908,$4
;	PL_L	$0001290c,$4e712a3c
;	PL_L	$00012910,$00000002

	; extra stuff (protection + speedup)

	;;PL_I	$10522
	;;PL_I	$128A0xxxx
	;;PL_I	$C1B2

	PL_S	$12794,$b2-$94	; skip disk & clr mem stuff
	;;PL_S	$1285C,$BC-$5C


	; remove disk accesses

	PL_R	$10836
	PL_R	$107e4
	PL_R	$10824
	PL_R	$108c4
	PL_R	$10878
	PL_R	$108e6
	PL_R	$107aa
	PL_W	$12802,$6006
	;;PL_L	$12858xxxx,$600000B2

	; load

	PL_P	$104a4,read_sectors_game

	; remove a delay

	PL_NOP	$127ee,$4

	; decrunch
	
	PL_P	$0c8ac,decrunch

	; hiscore save

	PL_PSS	$11c6e,write_scores,2

	PL_NEXT pl_blitter_3016
    
set_start_level:
	MOVE.W	#$0003,$1b0  ; nb lives
    move.b  _start_level+3(pc),$2BB
    rts
    
set_expmem
    move.l  _expmem(pc),$27A6.W
    rts
    
MODULE_CODE_3015 = $000448ca

pl_module_player:
    PL_START
    PL_IFC5
    PL_ELSE
    PL_PS   $584,dma_wait_1  ; $44e4e-MODULE_CODE_3015
    PL_PS   $62E,dma_wait_1 ; $44ef8-MODULE_CODE_3015,
;    PL_PSS  $44e76-MODULE_CODE_3015,dma_wait_2,4
;    PL_PSS  $44a5a-MODULE_CODE_3015,dma_wait_3,4
    PL_PS   $fa,dma_wait_4  ; $449c4-MODULE_CODE_3015
    PL_ENDIF
    PL_END
    
dma_wait_1:
    MOVE.W	2(A4),150(A5)		;44e4e: 3b6c00020096
    bra.b soundtracker_loop
dma_wait_2:
	MOVE.W	#$0001,6(A0)		;44e76: 317c00010006
	MOVE.W	(A4),150(A5)		;44e7c: 3b540096
    bra.b soundtracker_loop
dma_wait_3
	MOVE.W	#$0002,14(A4)		;44a5a: 397c0002000e
	MOVE.W	(A4),150(A5)		;44a60: 3b540096
    bra.b soundtracker_loop
dma_wait_4
	MOVE.W	2(A1),150(A0)		;449c4: 316900020096
    bra.b soundtracker_loop
    nop
soundtracker_loop
	move.w  d0,-(a7)
	move.w	#7,d0
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
    
TITLE_MUSIC_CODE = $0006c800

load_music_code_title:
    movem.l d0-d1/a0-a2,-(a7)
    lea pl_module_player(pc),a0
    lea  TITLE_MUSIC_CODE,a1
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
    
    MOVE.W	#$0001,$279e.W

    RTS
    
load_music_code_game:
    movem.l a0,-(a7)
    move.l disk_buffer(pc),a0
	MOVE.L	#MODULE_CODE_3015,(a0)
    movem.l (a7)+,a0
    pea .next(pc)
    move.l  load_routine(pc),-(a7)
    rts
.next
    movem.l d0-d1/a0-a2,-(a7)
    lea pl_module_player(pc),a0
    lea  MODULE_CODE_3015,a1
    move.l  _resload(pc),a2
    jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
    RTS
    
; 10EC0 00010A8C 00012DDC 3016
set_copperlist_3015
    cmp.l   #$12cb0,a0
    bne.b   .nogame
    nop
.nogame
	cmp.l	#$1095C,a0
	bne.b	.sk
	move.l	#-2,$1099C
.sk
	move.l	a0,$dff080
	rts
set_copperlist_3016
    cmp.l   #$12ddc,a0
    bne.b   .nogame
    nop
.nogame
;	cmp.l	#$1095C,a0
;	bne.b	.sk
;	move.l	#-2,$1099C
;.sk
	move.l	a0,$dff080
	rts

move_d5_64_clr_66
	bsr	waitblit
	move.w	d5,($64,a6)                    ;$00dff064
	move.w	#0,($66,a6)                       ;$00dff066
	rts


move_d5_a6_swap
	bsr	waitblit
	move.w	d5,($46,a6)                    ;$00dff046
	swap	d5
	rts

patch_ee98
	bsr	waitblit
	move.w	#$ffff,($44,a5)                ;$00dff044
	rts

move_ffff_dff044
	bsr	waitblit
	move.w	#$ffff,($dff044)
	rts

patch_eeec:
	bsr	waitblit
	move.l	a4,($54,a5)                    ;$00dff054
	move.w	d1,($58,a5)                    ;$00dff058
	bra	blitter_dma_end_2

BLTHOG=$400
;BLTHOG=0

blitter_force_dma_3
	add.l	#2,(a7)		; skip next 2 bytes
	move.w	#$8240+BLTHOG,$dff096
	rts

blitter_force_dma
	add.l	#2,(a7)		; skip next 2 bytes
blitter_force_dma_2
	move.w	#$8040+BLTHOG,$dff096
	rts

blitter_dma_end
	add.l	#2,(a7)		; skip next 2 bytes
blitter_dma_end_2
	bsr	waitblit
	move.w	#BLTHOG,$dff096	; orig
	rts

BUILD_BLITWAIT_x_xx_dffxxx:MACRO
move_\1_\2:
	bsr	waitblit
	move.\3	\1,$\2
	rts
	ENDM

BUILD_BLITWAIT_x_imml_dffxxx:MACRO
move_imml_\1_\2:
	bsr	waitblit
	MOVE.L	#$\1,$\2
	add.l	#4,(a7)
	rts
	ENDM

BUILD_BLITWAIT_x_addrs_dffxxx:MACRO
move_addrs_\1_\2:
	bsr	waitblit
	MOVE.L	$\1.W,$\2
	add.l	#2,(a7)
	rts
	ENDM


	BUILD_BLITWAIT_x_xx_dffxxx	d0,dff054,L
	BUILD_BLITWAIT_x_xx_dffxxx	d1,dff054,L
	BUILD_BLITWAIT_x_xx_dffxxx	a0,dff054,L
	BUILD_BLITWAIT_x_xx_dffxxx	a1,dff054,L
	BUILD_BLITWAIT_x_xx_dffxxx	a2,dff054,L
	BUILD_BLITWAIT_x_xx_dffxxx	a3,dff054,L

	BUILD_BLITWAIT_x_xx_dffxxx	d0,dff050,L
	BUILD_BLITWAIT_x_xx_dffxxx	d1,dff050,L
	BUILD_BLITWAIT_x_xx_dffxxx	a0,dff050,L
	BUILD_BLITWAIT_x_xx_dffxxx	a1,dff050,L
	BUILD_BLITWAIT_x_xx_dffxxx	a2,dff050,L

	BUILD_BLITWAIT_x_xx_dffxxx	d7,dff046,W
	BUILD_BLITWAIT_x_xx_dffxxx	a3,dff04c,l

	BUILD_BLITWAIT_x_imml_dffxxx	4b89a,dff054,l
	BUILD_BLITWAIT_x_imml_dffxxx	4bf2a,dff054,l
	BUILD_BLITWAIT_x_imml_dffxxx	4c5ba,dff054,l

	BUILD_BLITWAIT_x_addrs_dffxxx	275c,dff054,l
	BUILD_BLITWAIT_x_addrs_dffxxx	2760,dff054,l

blitwait_d1:
	bsr	waitblit
	move.l	a1,($dff054)
	rts


clr_dff064:
	bsr	waitblit
	move.w	#0,$dff064
	rts

clr_dff042
	bsr	waitblit
	move.w	#0,($dff042)
	rts

blitwait_0_dff066
	bsr	waitblit
	move.w       #0,($dff066)
	rts

blitwait_9f0_dff040
	bsr	waitblit
	move.w	#$9f0,($dff040)
	rts

blitwait_a4_a5:
	bsr	waitblit
	move.l	a4,84(A5)
	rts

blitwait_a5_a6:
	bsr	waitblit
	move.l	a5,80(a6)
	rts

blitwait_a1_a6:
	bsr	waitblit
	move.l	a1,80(A6)
	rts

read_scores
	movem.l	d0-a6,-(a7)
	lea	hiscname(pc),A0
	move.l  scores_address(pc),A1
	move.l	_resload(pc),a2
	jsr	resload_LoadFile(a2)
	movem.l	(a7)+,d0-a6
	rts

write_scores
	movem.l	d0-a6,-(a7)
	move.l	_trainer(pc),d0
	bne.b	.skip
    move.l  _start_level(pc),d0
	bne.b	.skip
    
	lea	hiscname(pc),A0
	move.l  scores_address(pc),A1
	moveq.l	#66,D0
	move.l	_resload(pc),a2
	jsr	resload_SaveFile(a2)
.skip
	movem.l	(a7)+,d0-a6
	rts

decrunch

	LEA	4(A0),A1		;00: 43E80004
	MOVE.L	(A0),D0			;04: 2010
	ADD.L	A0,D0			;06: D088
	ADDQ.L	#4,D0			;08: 5880
	MOVEA.L	D0,A0			;0A: 2040
	MOVEA.L	-(A0),A2		;0C: 2460
	ADDA.L	A1,A2			;0E: D5C9
	MOVE.L	-(A0),D5		;10: 2A20
	MOVE.L	-(A0),D0		;12: 2020
	EOR.L	D0,D5			;14: B185
.lab_0000:
	LSR.L	#1,D0			;16: E288
	BNE.S	.lab_0001		;18: 6604
	BSR	.lab_000E		;1A: 61000080
.lab_0001:
	BCS.S	.lab_0008		;1E: 6536
	MOVEQ	#8,D1			;20: 7208
	MOVEQ	#1,D3			;22: 7601
	LSR.L	#1,D0			;24: E288
	BNE.S	.lab_0002		;26: 6604
	BSR	.lab_000E		;28: 61000072
.lab_0002:
	BCS.S	.lab_000A		;2C: 654A
	MOVEQ	#3,D1			;2E: 7203
	MOVEQ	#0,D4			;30: 7800
.lab_0003:
	BSR	.lab_000F		;32: 61000074
	MOVE	D2,D3			;36: 3602
	ADD	D4,D3			;38: D644
.lab_0004:
	MOVEQ	#7,D1			;3A: 7207
.lab_0005:
	LSR.L	#1,D0			;3C: E288
	BNE.S	.lab_0006		;3E: 6602
	BSR.S	.lab_000E		;40: 615A
.lab_0006:
	ROXL.L	#1,D2			;42: E392
	DBF	D1,.lab_0005		;44: 51C9FFF6
	MOVE.B	D2,-(A2)		;48: 1502
	DBF	D3,.lab_0004		;4A: 51CBFFEE
	BRA.S	.lab_000C		;4E: 6034
.lab_0007:
	MOVEQ	#8,D1			;50: 7208
	MOVEQ	#8,D4			;52: 7808
	BRA.S	.lab_0003		;54: 60DC
.lab_0008:
	MOVEQ	#2,D1			;56: 7202
	BSR.S	.lab_000F		;58: 614E
	CMP.B	#$02,D2			;5A: B43C0002
	BLT.S	.lab_0009		;5E: 6D10
	CMP.B	#$03,D2			;60: B43C0003
	BEQ.S	.lab_0007		;64: 67EA
	MOVEQ	#8,D1			;66: 7208
	BSR.S	.lab_000F		;68: 613E
	MOVE	D2,D3			;6A: 3602
	MOVEQ	#12,D1			;6C: 720C
	BRA.S	.lab_000A		;6E: 6008
.lab_0009:
	MOVEQ	#9,D1			;70: 7209
	ADD	D2,D1			;72: D242
	ADDQ	#2,D2			;74: 5442
	MOVE	D2,D3			;76: 3602
.lab_000A:
	BSR.S	.lab_000F		;78: 612E
.lab_000B:
	SUBQ.L	#1,A2			;7A: 538A
	MOVE.B	0(A2,D2),(A2)		;7C: 14B22000
	DBF	D3,.lab_000B		;80: 51CBFFF8
.lab_000C:
	CMPA.L	A2,A1			;84: B3CA
	BLT.S	.lab_0000		;86: 6D8E

	tst.l	D5
	bne	wrong_version
	rts
.lab_000E:
	MOVE.L	-(A0),D0		;9C: 2020
	EOR.L	D0,D5			;9E: B185
	MOVE	#$0010,CCR		;A0: 44FC0010
	ROXR.L	#1,D0			;A4: E290
	RTS				;A6: 4E75
.lab_000F:
	SUBQ	#1,D1			;A8: 5341
	MOVEQ	#0,D2			;AA: 7400
.lab_0010:
	LSR.L	#1,D0			;AC: E288
	BNE.S	.lab_0011		;AE: 660A
	MOVE.L	-(A0),D0		;B0: 2020
	EOR.L	D0,D5			;B2: B185
	MOVE	#$0010,CCR		;B4: 44FC0010
	ROXR.L	#1,D0			;B8: E290
.lab_0011:
	ROXL.L	#1,D2			;BA: E392
	DBF	D1,.lab_0010		;BC: 51C9FFEE
	RTS				;C0: 4E75

kb_delay
	moveq	#3,d0
	bra	_beamdelay
	
kb_int
	ror.b	#1,D0
	move.b	D0,($159).W

	cmp.b	_keyexit(pc),D0
	bne	.noquit

	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.noquit
	tst.b	d0
	rts


_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts


_tag		dc.l	WHDLTAG_CUSTOM1_GET
_trainer	dc.l	0
		dc.l	WHDLTAG_CUSTOM3_GET
_start_level	dc.l	0
		dc.l	WHDLTAG_CUSTOM5_GET
_slow_68000:
        dc.l	0
		dc.l	0

version
	dc.l	0

;--------------------------------

_resload	dc.l	0		;address of resident loader

waitblit
.wait
	BTST	#6,dmaconr+$DFF000
	bne.b	.wait
wb
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	bra.s	.end
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
.end
	rts

; < D0: numbers of vertical positions to wait
_beamdelay
.bd_loop1
	move.l  d0,-(a7)
        move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.l	(a7)+,d0
	dbf	d0,.bd_loop1
	rts

load_routine:
    dc.l    0
scores_address:
    dc.l    0
    
side_flag:
    dc.l    $27A6
start_track:
    dc.l    $27A8
start_sector
    dc.l    $27AA
nb_sectors_to_read
    dc.l	$27AC
disk_buffer
    dc.l    $27AE
 
    
hiscname
	dc.b	"Highs",0
