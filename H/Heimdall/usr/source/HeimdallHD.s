; Resourced by whdslave_resourcer
; a program written by JOTD in 2016
;
; (and completely rewritten just after that :))
;
; TODO:
; - make it support fast memory to have 512k chip
; - swap save/load icons for spanish version

	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD BARFLY
	OUTPUT	"Heimdall.slave"
	;BOPT	O+				;enable optimizing
	;BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	SUPER
	ENDC

; english version seems to require 1MB chip
;USE_FASTMEM
	IFD	USE_FASTMEM
EXPMEM = $80000
CHIPMEM = $80000
	ELSE
EXPMEM = $0
CHIPMEM = $100000
	ENDC

ENGLISH_VERSION = 0
GERMAN_VERSION = 1
FRENCH_VERSION = 2
SPANISH_VERSION = 2

_base	SLAVE_HEADER					; ws_security + ws_id
	dc.w	17					; ws_version (was 5)
	dc.w	WHDLF_NoError
	dc.l	CHIPMEM					; ws_basememsize
	dc.l	0					; ws_execinstall
	dc.w	start-_base		; ws_gameloader
	dc.w	_data-_base				; ws_currentdir
	dc.w	0					; ws_dontcache
_keydebug
	dc.b	$58					; ws_keydebug
_keyexit
	dc.b	$59					; ws_keyexit
_expmem
	dc.l	EXPMEM					; ws_expmem
	dc.w	_name-_base				; ws_name
	dc.w	_copy-_base				; ws_copy
	dc.w	_info-_base				; ws_info
    dc.w    0     ; kickstart name
    dc.l    $0         ; kicksize
    dc.w    $0         ; kickcrc
	dc.w	_config-_base		;ws_config
;---

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

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
_data   dc.b    "data",0
_name	dc.b	'Heimdall',0
_copy	dc.b	'1991 Core Design',0
_info
    dc.b   'adapted by John Selck & JOTD',10
    dc.b    "Version "
    DECL_VERSION
    dc.b    0
_kickname   dc.b    0
;--- version id

_config
	dc.b    "C1:L:Custom save disk:5,6,7,8,9,10;"			
	dc.b	0

    dc.b	"$","VER: slave "
	DECL_VERSION

	dc.b	0

    even

start:
	LEA	_resload(PC),A1		;052: 43fa01fe
	move.L	A0,(A1)			;056: 2288
	MOVEA.L	A0,A2			;058: 2248
	LEA	tags(PC),A0		;05a: 41fa01fa
	JSR	resload_Control(A2)	;5e (offset=34)
	lea	virtual_savedisk(pc),a0
	add.l	#5,(a0)			; so it's valid even if 0
	; we have to detect the version from the boot sector
	LEA	$6000.W,A0		;062: 41f86000
	MOVEQ	#0,D0			;066: 7000
	move.W	#$0,D1		;068: 323c06d5
	MOVEQ	#1,D2			;06c: 7407
	MOVEQ	#0,D3			;06e: 7600
	BSR.W	rn_diskload		;070: 6100003c

	move.l	#$200,d0
	jsr	(resload_CRC16,a2)

	cmp.w	#$E8BE,d0
	beq.b	.sector_6d5	; english
	cmp.w	#$45DB,d0
	beq.b	.sector_6d5	; english
	cmp.w	#$7E4E,d0
	beq.b	.sector_6d7	; german or french
	cmp.w	#$4130,d0
	beq.b	.sector_6d5	; spanish

.wrongver
	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts	
.sector_6d5:
	move.W	#$06d5,D1		;068: 323c06d5
	bra.b	.loadboot
.sector_6d7:
	move.W	#$06d7,D1		;068: 323c06d5

.loadboot
	LEA	$6000.W,A0		;062: 41f86000
	MOVEQ	#0,D0			;066: 7000
	MOVEQ	#7,D2			;06c: 7407
	MOVEQ	#0,D3			;06e: 7600
	BSR.W	rn_diskload		;070: 6100003c
	move.l	#$E00,d0
	jsr	(resload_CRC16,a2)
	lea	game_version(pc),a3
	lea		pl_boot(pc),a0
	cmp.w	#$FF8,d0
	beq.b	.english
	cmp.w	#$8DBE,d0
	beq.b	.english
	cmp.w	#$D95D,d0
	beq.b	.german
	cmp.w	#$4EAA,d0
	beq.b	.french
	cmp.w	#$6B37,d0
	beq.b	.spanish
	    

	bra.b	.wrongver
.french
	move.l	#FRENCH_VERSION,(a3)
	bra.b	.patch
.german
	move.l	#GERMAN_VERSION,(a3)
	bra.b	.patch
.english
	move.l	#ENGLISH_VERSION,(a3)
	bra.b	.patch
.spanish
    move.l  #SPANISH_VERSION,(a3)
    lea pl_boot_spanish(pc),a0
.patch	
	sub.l	a1,a1
	MOVEA.L	_resload(PC),A2		;0de: 247a0172
	jsr	resload_Patch(a2)
	
	JMP	$6000.W

    
jump_75000
    movem.l a0-a2,-(a7)
    lea $75000,a1
	lea pl_spanish_75000(pc),a0
	MOVEA.L	_resload(PC),A2		;0de: 247a0172
	jsr	resload_Patch(a2)
    movem.l (a7)+,a0-a2
    jmp $75000
    
    

; spanish boot is different
pl_boot_spanish:
	PL_START
	PL_B	$6006,$60
    PL_P    $61D0,jump_75000
	PL_PS   $63d0,detect_expansion  ; this is ran when located at 75000
    PL_S    $63d6,$6400-$63d6
	PL_P	$640e,rn_diskload
	PL_END
    
pl_boot:
	PL_START
	PL_B	$6006,$60
	PL_NOP	$6236,2
	PL_P	$6454,rn_diskload
	PL_P	$62bc,patch_loader
	PL_END
    
detect_expansion
    bsr  get_ext_mem
    move.l  a0,d0
    rts
    
rn_diskload:
	MOVEM.L	D0-D7/A0-A6,-(A7)	;0ae: 48e7fffe
	MULU	#$0200,D1		;0b2: c2fc0200
	MULU	#$0200,D2		;0b6: c4fc0200
	BTST	#0,D3			;0ba: 08030000
	BNE.S	.save		;0be: 6616
	move.L	D1,D0			;0c0: 2001
	move.L	D2,D1			;0c2: 2202
	move.L	current_disk(PC),D2		;0c4: 243a0188
	MOVEA.L	_resload(PC),A2		;0c8: 247a0188
	JSR	resload_DiskLoad(A2)
    cmp.l   #4,d2
    bne.b   .no_fix
    move.l  game_version(pc),d2
    cmp.l   #SPANISH_VERSION,d2
    bne.b   .no_fix
    ; post-correction for spanish version
    ; one file is corrupt on disk 4 but it works
    ; from floppy... crashes badly with whdload
    ; (one $200-long sector seems to have complete bogus
    ; data,the rest is 100% identical)
	MOVEM.L	(A7),D0-D7/A0-A6	;0d0: 4cdf7fff
    move.l  (8,a0),d0
    cmp.l   #$6E4A,d0
    bne.b   .no_fix
    ; fix the damaged sector on spanish version
    lea ($1000,a0),a0
    lea correct_data(pc),a1
    move.w  #$7F,d0
.copy
    move.l  (a1)+,(a0)+
    dbf d0,.copy
    
.no_fix
	MOVEM.L	(A7)+,D0-D7/A0-A6	;0d0: 4cdf7fff
	RTS				;0d4: 4e75

.save:
	move.L	D2,D0			;0d6: 2002
	MOVEA.L	A0,A1			;0d8: 2248
	LEA	savedisk_name(PC),A0		;0da: 41fa0186
	MOVEA.L	_resload(PC),A2		;0de: 247a0172
	
	movem.l	D0-D1/A0-A1,-(A7)
	; disk doesn't exist, but we'll create a blank one right away
	; let's save some junk on the disk to avoid flashing
	jsr	(resload_GetFileSize,a2)
	tst.l	d0
	bne.b	.nozap
	LEA	savedisk_name(PC),A0
	sub.l	a1,a1
	move.l	#150000,d0	; should do
	jsr	(resload_SaveFile,a2)
.nozap
	movem.l	(A7)+,D0-D1/A0-A1
	
	JSR	resload_SaveFileOffset(A2)	;e2 (offset=38)
	BRA.S	.no_fix		;0e6: 60e8
	
patch_loader:
	JSR	(A1)			;  original
	move.l	game_version(pc),d0
	cmp.l	#ENGLISH_VERSION,d0
	beq.b	.english
	cmp.l	#GERMAN_VERSION,d0
	beq.b	.german
	cmp.l	#FRENCH_VERSION,d0
	beq.b	.french
	ILLEGAL
.french
	lea		pl_loader_fr(pc),a0
	bra.b	.patch_loader
.english
	lea		pl_loader_en(pc),a0
	bra.b	.patch_loader
.german
	lea		pl_loader_de(pc),a0
.patch_loader
	sub.l	a1,a1
	MOVEA.L	_resload(PC),A2		;0de: 247a0172
	jsr	resload_Patch(a2)
	JMP	$1000.W
	

pl_loader_en:
	PL_START
	PL_P	$AC18,set_ext_mem_en
	PL_P	$AC7A,patch_main_en
	PL_P	$A30C,emulate_copylock_en
	PL_P	$1F118,set_current_disk
	PL_END
pl_loader_fr:
	PL_START
	PL_P	$A0F6,set_ext_mem_fr
	PL_P	$a158,patch_main_fr
	PL_P	$a15e,emulate_copylock_fr
	PL_P	$1eef2,set_current_disk
	PL_END
pl_loader_de:
	PL_START
	PL_P	$A214,set_ext_mem_de
	PL_P	$a276,patch_main_de
	PL_P	$a27c,emulate_copylock_de
	PL_P	$1f00c,set_current_disk
	PL_END

get_ext_mem:
	IFD	USE_FASTMEM
	move.l	_expmem(pc),a0
	ELSE
	lea	$80000,a0
	ENDC
	rts
	

set_ext_mem_sp:
	bsr	get_ext_mem
	move.L	a0,$1000.W
	rts
    
set_ext_mem_en:
	bsr	get_ext_mem
	move.L	A0,$101a.W
	JMP	$ac56

set_ext_mem_fr:
	bsr	get_ext_mem
	move.L	A0,$101a.W
	JMP	$a134
	
set_ext_mem_de:
	bsr	get_ext_mem
	move.L	A0,$101a.W
	JMP	$a252
; well, not really the copylock id, but a signature
; that protection sets in expansion memory
; (except in spanish version, grrr)
COPYLOCK_ID = $f82e0688
; sets copylock key
emulate_copylock_en:
	bsr	get_ext_mem
	add.l	#$136e0,a0
	move.L	#COPYLOCK_ID,(a0)
	RTS
emulate_copylock_de:
	bsr	get_ext_mem
	add.l	#$136cc,a0
	move.L	#COPYLOCK_ID,(a0)
	RTS
emulate_copylock_fr:
	bsr	get_ext_mem
	add.l	#$136d0,a0
	move.L	#COPYLOCK_ID,(a0)
	RTS
emulate_copylock_sp:
	move.L	#COPYLOCK_ID,$1888.W
	RTS

set_current_disk:
	MOVEQ	#0,D0			;150: 7000
	move.W	$41da.W,D0
	LEA	current_disk(PC),A0		;156: 41fa00f6
	move.L	D0,(A0)			;15a: 2080
	MOVEQ	#0,D1			;15c: 7200
	RTS				;15e: 4e75
    
set_current_disk_sp:
	MOVEQ	#0,D0			;150: 7000
	move.W	$40de.W,D0
	LEA	current_disk(PC),A0		;156: 41fa00f6
	move.L	D0,(A0)			;15a: 2080
	MOVEQ	#0,D1			;15c: 7200
	RTS				;15e: 4e75

pl_spanish_75000:
    PL_START
    PL_P    $74,patch_main_sp
    PL_END
    
patch_main_sp:    
    MOVEA.L D0,A0
	movem.l	a0-a2/d0-d1,-(a7)
	move.l	a0,a1
	lea	pl_main_sp(pc),a0
	MOVEA.L	_resload(PC),A2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2/d0-d1
    JMP (A0)
    
patch_main_de:
	movem.l	a0-a2/d0-d1,-(a7)
	move.l	a0,a1
	lea	pl_main_de(pc),a0
	MOVEA.L	_resload(PC),A2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2/d0-d1
	jmp	(2,a0)
	
patch_main_en:
	movem.l	a0-a2/d0-d1,-(a7)
	move.l	a0,a1
	lea	pl_main_en(pc),a0
	MOVEA.L	_resload(PC),A2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2/d0-d1
	jmp	(2,a0)
    
patch_main_fr:
	movem.l	a0-a2/d0-d1,-(a7)
	move.l	a0,a1
	lea	pl_main_fr(pc),a0
	MOVEA.L	_resload(PC),A2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2/d0-d1
	jmp	(2,a0)
	
pl_main_fr:
	PL_START
	PL_P	$13720,rn_diskload
	PL_P	$dc58,set_current_savedisk_name
	PL_P	$dc58+6,get_current_savedisk_size
	PL_W	$dd04,$FF5A
    PL_NOP  $67A,6      ; remove call to password check program
	PL_PSS	$8E6,active_dbf_loop_1,6
	PL_PSS	$d332,active_dbf_loop_2,6
	PL_PSS	$12ca,keyboard,4
    PL_PSS  $14842,soundtracker_loop,2
    PL_PSS  $14858,soundtracker_loop,2
    PL_PSS  $14f38,soundtracker_loop,2
    PL_PSS  $14f4e,soundtracker_loop,2
    PL_PSS  $364,patch_ingame_fr,2
    PL_PS   $5e8,patch_intro_fr
    ; rn decruncher from whdload isn't working here
    PL_P    $141F6,decrunch
    PL_PS   $3b2,jump_c000_en
	PL_END

pl_main_en:
	PL_START
	PL_P	$13730,rn_diskload
	PL_P	$DC66,set_current_savedisk_name
	PL_P	$DC6C,get_current_savedisk_size
	PL_W	$DD12,$FF5A
    PL_NOP  $67A,6      ; remove call to password check program
	PL_PSS	$8e6,active_dbf_loop_1,6	;MOVE.W	#$1388,D6
	PL_PSS	$d340,active_dbf_loop_2,6	;MOVE.W	#$03e8,D0
    PL_PSS  $14852,soundtracker_loop,2
    PL_PSS  $14868,soundtracker_loop,2
    PL_PSS  $14f48,soundtracker_loop,2
    PL_PSS  $14f5e,soundtracker_loop,2
	PL_PSS	$12ca,keyboard,4
    PL_PSS  $364,patch_ingame_en,2
    PL_PS   $5e8,patch_intro_en
    PL_P    $14206,decrunch
    PL_PS   $3B2,jump_c000_en
	PL_END

pl_main_sp:
	PL_START
	PL_P	$153fc,rn_diskload
	PL_P	$f806,set_current_savedisk_name
	PL_P	$f80c,get_current_savedisk_size
	PL_W	$f8bc,$FF50 ; branch a little after
    PL_NOP  $958,6      ; remove call to password check program
    PL_PS   $90C,emulate_copylock_sp
	PL_PSS	$c02,active_dbf_loop_1,6	;MOVE.W	#$1388,D6
	PL_PSS	$ee30,active_dbf_loop_2,6	;MOVE.W	#$03e8,D0
	PL_PSS	$c74e,keyboard,4
    PL_PSS  $16638,soundtracker_loop,4
    PL_PSS  $16652,soundtracker_loop,4
    PL_PSS  $16da4,soundtracker_loop,4
    PL_PSS  $16dbc,soundtracker_loop,4
    PL_PSS  $5d8,patch_ingame_sp,2
    PL_PS   $8b2,patch_intro_sp
    ; boot patch is apparently magically transferred in main program
    ; except for this version where there is no boot
    PL_P    $1622a,set_current_disk_sp
    PL_S    $15f44,$60-$44      ; skip strange memory correction stuff
    PL_PS   $30,set_ext_mem_sp  ; program expects expmem in D0, but can be fixed here too
    PL_P    $15f60,decrunch
    PL_PS   $63c,jump_c000_en
	PL_END
	
pl_main_de:
	PL_START
	PL_P	$1371c,rn_diskload
	PL_P	$dc54,set_current_savedisk_name
	PL_P	$dc5a,get_current_savedisk_size
	PL_W	$dcfe,$FF5A
	PL_NOP	$676,6      ; remove call to password check program
	PL_PSS	$8e2,active_dbf_loop_1,6
	PL_PSS	$d32e,active_dbf_loop_2,6
	PL_PSS	$12c6,keyboard,4
    PL_PSS  $1483e,soundtracker_loop,2
    PL_PSS  $14854,soundtracker_loop,2
    PL_PSS  $14f34,soundtracker_loop,2
    PL_PSS  $14f4a,soundtracker_loop,2
    PL_PSS  $364,patch_ingame_de,2
    PL_PS   $5e4,patch_intro_de
    PL_P    $1ed7a,decrunch
    PL_PS   $3b2,jump_c000_en
	PL_END

jump_c000_en:
    ; keep keyboard interrupt enabled
    ; allows quit in bonus sections from 68000
    move.b  #$18,$C15F
    bsr _flushcache
    jmp $C000
    
;;decrunch2:
;;    movem.l d1/a0-a2,-(a7)
;;	MOVEA.L	A0,A1   ; forces in-place !!!!
;;    move.l  _resload(pc),a2
;;    jsr (resload_Decrunch,a2)
;;    movem.l (a7)+,d1/a0-a2
;;    ; returns size in D0
;;    rts

; whdload built-in RNC decrunch chokes on that one
; for some reason on a particular file (unable to decrunch data)
decrunch
; this decrunch code is copied from french version
	MOVEM.L	D1-D7/A0-A6,-(A7)	;941f6: 48e77ffe
	MOVEA.L	A0,A1			;941fa: 2248
	BSR.W	.lab_0B2C		;941fc: 6100015a
	CMP.L	#$524e4301,D0		;94200: b0bc524e4301
	BNE.S	.lab_0B14		;94206: 6654
	BSR.W	.lab_0B2C		;94208: 6100014e
	LEA	4(A0),A4		;9420c: 49e80004
	LEA	0(A4,D0.L),A2		;94210: 45f40800
	ADDA.L	#$00000100,A2		;94214: d5fc00000100
	MOVEA.L	A2,A3			;9421a: 264a
	BSR.W	.lab_0B2C		;9421c: 6100013a
	LEA	0(A4,D0.L),A6		;94220: 4df40800
	MOVE.B	-(A6),D3		;94224: 1626
.lab_0B11:
	BSR.W	.lab_0B17		;94226: 61000044
	ADDQ.W	#1,D5			;9422a: 5245
	CMPA.L	A4,A6			;9422c: bdcc
	BLE.S	.lab_0B13		;9422e: 6f22
	BSR.W	.lab_0B1F		;94230: 61000090
	BSR.W	.lab_0B25		;94234: 610000c8
	SUBQ.W	#1,D6			;94238: 5346
	LEA	0(A3,D7.W),A0		;9423a: 41f37000
	EXT.L	D6			;9423e: 48c6
	ADDA.L	D6,A0			;94240: d1c6
	TST.W	D7			;94242: 4a47
	BNE.S	.lab_0B12		;94244: 6604
	LEA	1(A3),A0		;94246: 41eb0001
.lab_0B12:
	MOVE.B	-(A0),-(A3)		;9424a: 1720
	DBF	D6,.lab_0B12		;9424c: 51cefffc
	BRA.S	.lab_0B11		;94250: 60d4
.lab_0B13:
	MOVE.L	A2,D0			;94252: 200a
	SUB.L	A3,D0			;94254: 908b
	MOVEA.L	A3,A0			;94256: 204b
	BRA.W	.lab_0B2E		;94258: 6000010a
.lab_0B14:
	MOVEQ	#0,D0			;9425c: 7000
	BRA.W	.lab_0B2E		;9425e: 60000104
.lab_0B15:
	LSL.B	#1,D3			;94262: e30b
	BNE.S	.lab_0B16		;94264: 6604
	MOVE.B	-(A6),D3		;94266: 1626
	ROXL.B	#1,D3			;94268: e313
.lab_0B16:
	RTS				;9426a: 4e75
.lab_0B17:
	MOVEQ	#-1,D5			;9426c: 7aff
	BSR.W	.lab_0B15		;9426e: 6100fff2
	BCC.S	.lab_0B1D		;94272: 6444
	MOVEQ	#0,D5			;94274: 7a00
	BSR.W	.lab_0B15		;94276: 6100ffea
	BCC.S	.lab_0B1B		;9427a: 6432
	LEA	.lab_0B1E(PC),A0		;9427c: 41fa003c
	MOVEQ	#3,D1			;94280: 7203
.lab_0B18:
	CLR.W	D5			;94282: 4245
	MOVE.B	0(A0,D1.W),D0		;94284: 10301000
	EXT.W	D0			;94288: 4880
	MOVEQ	#-1,D2			;9428a: 74ff
	LSL.W	D0,D2			;9428c: e16a
	NOT.W	D2			;9428e: 4642
	SUBQ.W	#1,D0			;94290: 5340
.lab_0B19:
	BSR.W	.lab_0B15		;94292: 6100ffce
	ROXL.W	#1,D5			;94296: e355
	DBF	D0,.lab_0B19		;94298: 51c8fff8
	TST.W	D1			;9429c: 4a41
	BEQ.S	.lab_0B1A		;9429e: 6706
	CMP.W	D5,D2			;942a0: b445
	DBNE	D1,.lab_0B18		;942a2: 56c9ffde
.lab_0B1A:
	MOVE.B	4(A0,D1.W),D0		;942a6: 10301004
	EXT.W	D0			;942aa: 4880
	ADD.W	D0,D5			;942ac: da40
.lab_0B1B:
	MOVE.W	D5,-(A7)		;942ae: 3f05
.lab_0B1C:
	MOVE.B	-(A6),-(A3)		;942b0: 1726
	DBF	D5,.lab_0B1C		;942b2: 51cdfffc
	MOVE.W	(A7)+,D5		;942b6: 3a1f
.lab_0B1D:
	RTS				;942b8: 4e75
.lab_0B1E:
	DC.W	$0a03			;942ba
	DC.W	$0202			;942bc
	DC.W	$0e07			;942be
	DC.W	$0401			;942c0
.lab_0B1F:
	LEA	.lab_0B24(PC),A0		;942c2: 41fa0030
	MOVEQ	#3,D0			;942c6: 7003
.lab_0B20:
	BSR.W	.lab_0B15		;942c8: 6100ff98
	BCC.S	.lab_0B21		;942cc: 6404
	DBF	D0,.lab_0B20		;942ce: 51c8fff8
.lab_0B21:
	CLR.W	D6			;942d2: 4246
	ADDQ.W	#1,D0			;942d4: 5240
	MOVE.B	0(A0,D0.W),D1		;942d6: 12300000
	BEQ.S	.lab_0B23		;942da: 670e
	EXT.W	D1			;942dc: 4881
	SUBQ.W	#1,D1			;942de: 5341
.lab_0B22:
	BSR.W	.lab_0B15		;942e0: 6100ff80
	ROXL.W	#1,D6			;942e4: e356
	DBF	D1,.lab_0B22		;942e6: 51c9fff8
.lab_0B23:
	MOVE.B	5(A0,D0.W),D1		;942ea: 12300005
	EXT.W	D1			;942ee: 4881
	ADD.W	D1,D6			;942f0: dc41
	RTS				;942f2: 4e75
.lab_0B24:
	DC.W	$0a02			;942f4
	dc.w $0100
	DC.W	$000a			;942f8
	DC.W	$0604			;942fa
	dc.w $0302
.lab_0B25:
	MOVEQ	#0,D7			;942fe: 7e00
	CMP.W	#$0002,D6		;94300: bc7c0002
	BEQ.S	.lab_0B29		;94304: 672a
	MOVEQ	#1,D0			;94306: 7001
.lab_0B26:
	BSR.W	.lab_0B15		;94308: 6100ff58
	BCC.S	.lab_0B27		;9430c: 6404
	DBF	D0,.lab_0B26		;9430e: 51c8fff8
.lab_0B27:
	ADDQ.W	#1,D0			;94312: 5240
	LEA	.lab_0B2B(PC),A0		;94314: 41fa0036
	MOVE.B	0(A0,D0.W),D1		;94318: 12300000
	EXT.W	D1			;9431c: 4881
.lab_0B28:
	BSR.W	.lab_0B15		;9431e: 6100ff42
	ROXL.W	#1,D7			;94322: e357
	DBF	D1,.lab_0B28		;94324: 51c9fff8
	LSL.W	#1,D0			;94328: e348
	ADD.W	4(A0,D0.W),D7		;9432a: de700004
	RTS				;9432e: 4e75
.lab_0B29:
	MOVEQ	#5,D0			;94330: 7005
	CLR.W	D1			;94332: 4241
	BSR.W	.lab_0B15		;94334: 6100ff2c
	BCC.S	.lab_0B2A		;94338: 6404
	MOVEQ	#8,D0			;9433a: 7008
	MOVEQ	#64,D1			;9433c: 7240
.lab_0B2A:
	BSR.W	.lab_0B15		;9433e: 6100ff22
	ROXL.W	#1,D7			;94342: e357
	DBF	D0,.lab_0B2A		;94344: 51c8fff8
	ADD.W	D1,D7			;94348: de41
	RTS				;9434a: 4e75
.lab_0B2B:
	dc.w $0b04
	dc.w $0700
	dc.w $0120
	dc.l $00000020
	DC.W	$0000			;94356
.lab_0B2C:
	MOVEQ	#3,D1			;94358: 7203
.lab_0B2D:
	LSL.L	#8,D0			;9435a: e188
	MOVE.B	(A0)+,D0		;9435c: 1018
	DBF	D1,.lab_0B2D		;9435e: 51c9fffa
	RTS				;94362: 4e75
.lab_0B2E:
	MOVE.L	A0,D2			;94364: 2408
	SUB.L	A1,D2			;94366: 9489
	MOVE.L	D0,D1			;94368: 2200
	BEQ.S	.lab_0B31		;9436a: 670c
.lab_0B2F:
	MOVE.B	(A0)+,(A1)+		;9436c: 12d8
	SUBQ.L	#1,D1			;9436e: 5381
	BNE.S	.lab_0B2F		;94370: 66fa
.lab_0B30:
	CLR.B	(A1)+			;94372: 4219
	SUBQ.L	#1,D2			;94374: 5382
	BNE.S	.lab_0B30		;94376: 66fa
.lab_0B31:
	MOVEM.L	(A7)+,D1-D7/A0-A6	;94378: 4cdf7ffe
	RTS				;9437c: 4e75

keyboard
	MOVE.B	$bfec01,D0		;812c6: 103900
	ROR.B	#1,D0			;812cc: e218
	NOT.B	D0			;812ce: 4600
	cmp.b	_keyexit(pc),d0
	bne.b	.noquit
	; quit the game on quitkey (68000/NOVBRMOVE)
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	;;rts	
.noquit
	rts

PATCHINTRO:MACRO
patch_intro_\1:
    pea .ret(pc)
    pea $\2
	movem.l	a0/d0,-(a7)
    bsr get_ext_mem
    move.l  a0,d0
    add.l   d0,8(a7)
	movem.l	(a7)+,a0/d0
    rts
.ret
    ; intro has been loaded
 	movem.l	a0-a2/d0-d1,-(a7)
	sub.l   a1,a1
	lea	pl_intro_\1(pc),a0
	MOVEA.L	_resload(PC),A2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2/d0-d1
    rts
    ENDM
    
    PATCHINTRO  fr,140E6
    PATCHINTRO  de,140E2
    PATCHINTRO  en,140f6
    PATCHINTRO  sp,15e1e
    
pl_intro_fr:
    PL_START
    PL_PSS  $42C38,soundtracker_loop,2
    PL_PS   $42BEA,dma_wait
    PL_END
pl_intro_en:
pl_intro_sp:
    PL_START
    PL_PSS  $40C26,soundtracker_loop,2
    PL_PS   $40BD8,dma_wait
    PL_END
pl_intro_de:
    PL_START
    PL_PSS  $42C3C,soundtracker_loop,2
    PL_PSS  $42C8A,soundtracker_loop,2
    PL_END

    
patch_ingame_de:
	movem.l	a0-a2/d0-d1,-(a7)
	sub.l   a1,a1
	lea	pl_ingame(pc),a0
	MOVEA.L	_resload(PC),A2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2/d0-d1
    RTS
patch_ingame_fr:
	movem.l	a0-a2/d0-d1,-(a7)
	sub.l   a1,a1
	lea	pl_ingame(pc),a0
	MOVEA.L	_resload(PC),A2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2/d0-d1
    RTS
    
patch_ingame_en:
	movem.l	a0-a2/d0-d1,-(a7)
	sub.l   a1,a1
	lea	pl_ingame(pc),a0
	MOVEA.L	_resload(PC),A2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2/d0-d1
    RTS
patch_ingame_sp:
	movem.l	a0-a2/d0-d1,-(a7)
	sub.l   a1,a1
	lea	pl_ingame(pc),a0
	MOVEA.L	_resload(PC),A2
	jsr	resload_Patch(a2)	
	movem.l	(a7)+,a0-a2/d0-d1
    RTS
    

pl_ingame:
    PL_START
	PL_NOP  $c16c,2 ; patch found in original game !
    PL_PSS  $00045AD8,soundtracker_loop,2
    PL_END

dma_wait:
    movem.l d0,-(a7)
    bsr soundtracker_loop
    movem.l (a7)+,d0
    BTST.B #$0002,($001e,a6)
    rts
 
soundtracker_loop
	move.w	#8,d0
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
	
	; 80CEC (english) loop to select characters slightly too fast
	; on accelerated amigas. Well...
	
active_dbf_loop_1:
	rts
	
	movem.l	d0,-(a7)
	move.l	#$1388,d0
	bsr	beamdelay
	movem.l	(a7)+,d0
	rts
active_dbf_loop_2:
	rts

	move.l	#$3e8,d0
	bsr	beamdelay
	rts
	
; < D0: numbers of vertical positions to wait
beamdelay
	lsr.w	#1,d0
.bd_loop1
	move.w  d0,-(a7)
	move.w	#$F00,$DFF180
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
	
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts
    
set_current_savedisk_name:
	move.L	virtual_savedisk(PC),D0
	CMP.L	#$5,D0
	BCS.S	.lab_000B
	CMP.L	#$100,D0
	BCS.S	.ok
	MOVEQ	#-1,D0
.ok:
	LEA	current_disk(PC),A0
	move.L	D0,(A0)
	BSR.S	write_savedisk_number
	MOVEQ	#0,D0
	RTS

.lab_000B:
	MOVEQ	#1,D0
	RTS

get_current_savedisk_size:
	move.L	virtual_savedisk(PC),D0
	CMP.L	#$00000005,D0
	BCS.S	.error_game_disk	; this cannot happen
	CMP.L	#$00000100,D0
	BCS.S	.ok
	MOVEQ	#-1,D0
.ok:
	LEA	current_disk(PC),A0
	move.L	D0,(A0)
	BSR.S	write_savedisk_number
	LEA	savedisk_name(PC),A0
	MOVEA.L	_resload(PC),A2
	JSR	resload_GetFileSize(A2)
	TST.L	D0
	BEQ.S	.error
	MOVEQ	#0,D0
	RTS

.error_game_disk:
	MOVEQ	#1,D0
	RTS

.error:	
	MOVEQ	#-1,D0
	RTS

write_savedisk_number:
	LEA	disk_index(PC),A0
	move.L	current_disk(PC),D0
	DIVU	#$0064,D0
	TST.B	D0
	BEQ.S	.lab_0011
	ORI.B	#'0',D0
	move.B	D0,(A0)+
.lab_0011:
	SUB.W	D0,D0
	SWAP	D0
	DIVU	#$000a,D0
	TST.B	D0
	BEQ.S	.lab_0012
	ORI.B	#'0',D0
	move.B	D0,(A0)+
.lab_0012:
	SWAP	D0
	ORI.B	#'0',D0
	move.B	D0,(A0)+
	CLR.B	(A0)
	RTS

current_disk:
	dc.l	0
_resload:
	dc.l	0
tags:
	dc.l	WHDLTAG_CUSTOM1_GET
virtual_savedisk:
	dc.l	0		; defaults to 5
	dc.l	0
game_version
	dc.l	0
savedisk_name:
	dc.b	"disk."
disk_index:
	dc.b	0,0,0,0,0
    cnop    0,4
correct_data:
    incbin  "d4_28a00.bin"
    
