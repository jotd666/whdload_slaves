;*---------------------------------------------------------------------------
;  :Program.	Swos.asm
;  :Contents.	Slave for "SWOS 95-96/96-97" from Sensible Software
;  :Author.	Galahad of Fairlight
;  :History.	12.05.01
;  :Requires.	-
;  :Copyright.	Public Domain
;  :Language.	68000 Assembler
;  :Translator.	PhxAs
;  :To Do.
;---------------------------------------------------------------------------*

	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

    IFD    BARFLY
	OUTPUT	wdh1:SWOS2/SWOS.Slave
	;OPT	O+ OG+			;enable optimizing
    ENDC
  
; chiponly triggers an access fault when trying to play
; let's hope we're not going to need that
CHIP_ONLY

BUFFER_SIZE = $800

; probably more than enough!
TEAM_BUFFER_SIZE = $40000

PROGRAM_LOCATION_OFFSET = $80000

    IFD CHIP_ONLY
CHIPMEMSIZE = $180000+PROGRAM_LOCATION_OFFSET
FASTMEMSIZE = TEAM_BUFFER_SIZE
PROGRAM_FASTMEMSIZE = 0
    ELSE
CHIPMEMSIZE = $100000
PROGRAM_FASTMEMSIZE = $80000+PROGRAM_LOCATION_OFFSET
FASTMEMSIZE = PROGRAM_FASTMEMSIZE+TEAM_BUFFER_SIZE
    ENDC

; 1MB chip + 1,5MB slow mem prog @ $D00000
; D5 07000000: fastmem: 07 = 0111 = 1.5MB
; D6 07000003: chipmem: 03 = 0011 = 1MB
; D7 00280000 : total memory

; chip 2MB: prog @ $180000
; D5 00000000: no fastmem
; D6 0000000F: chipmem: 1111 = 2MB         
; D7 00200000: total memory

; autocompute bit masks (not very useful, as the memory routine
; is so obscure and buggy that it is completely skipped)
CHIPBITS = (1<<(CHIPMEMSIZE/$80000))-1
FASTBITS = ((1<<(PROGRAM_FASTMEMSIZE/$80000))-1)<<24
    
;======================================================================

base
		SLAVE_HEADER		;ws_Security + ws_ID
		dc.w	10		;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap|WHDLF_ClearMem	;ws_flags
		dc.l	CHIPMEMSIZE		;ws_BaseMemSize
		dc.l	0		;ws_ExecInstall
		dc.w	Start-base	;ws_GameLoader
		dc.w	_data-base		;ws_CurrentDir
		dc.w	0		;ws_DontCache
_keydebug	dc.b	0		;ws_keydebug = none
_keyexit	dc.b	$46		;ws_keyexit = Del
_expmem:
		dc.l	FASTMEMSIZE		;ws_ExpMem
		dc.w	_name-base	;ws_name
		dc.w	_copy-base	;ws_copy
		dc.w	_info-base	;ws_info


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
    
_name	dc.b	'-+ Sensible World Of Soccer +-'
        IFD CHIP_ONLY
        dc.b    " (DEBUG/CHIP mode)"
        ENDC
        dc.b    0
_copy	dc.b	'1994-97 Sensible Software',0
_info	dc.b	'-------------------------',10
	dc.b	'SWOS v0.9.......94-95',10
	dc.b	'SWOS v1.0.......94-95',10
	dc.b	'SWOS v1.1.......94-95',10
	dc.b	'SWOS............95-96',10
	dc.b	'SWOS UPDATE.....95-96',10
	dc.b	'SWOS EURO96.....95-96',10
	dc.b	'SWOS v1.52 (v1).96-97',10
	dc.b	'SWOS v1.52 (v2).96-97',10
	dc.b	'-------------------------',10
	dc.b	'Version '
    DECL_VERSION
	dc.b	0
	dc.b	-1
	CNOP 0,2

_data:
	dc.b	"data",0
	; slave loads "SWOS2" program, which is designed for A1200...
	; (original SSBOOT program loads SWOS for < kick3.1+68020)
Swos.rel:
	dc.b	'SWOS2.REL',0
Swos.prg:
	dc.b	'SWOS2',0
_savedir:
	dc.b	'SAVE',0
_save_filepath:
	dc.b	'SAVE/'
_save_filename:	ds.b	14
	dc.b	"$","VER: slave "
    DECL_VERSION
	dc.b	10,0	
	even



;======================================================================
Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
        IFD CHIP_ONLY
		; put team buffer in expmem
		lea	data_buffer(pc),a0
		move.l	_expmem(pc),(a0)
        lea _expmem(pc),a0
        move.l  #$100000,(a0)   ; simulate expmem
        ENDC

        ; configure other expmem buffer
        lea program_location(pc),a1
        move.l  _expmem(pc),a0       
        add.l   #PROGRAM_LOCATION_OFFSET,a0
        move.l  a0,(a1)
        IFND	CHIP_ONLY
		add.l	#$80000,a0
		lea		data_buffer(pc),a1
		move.l	a0,(a1)
		
		ENDC

		patch	$100,avoid_big_value
		
		lea	Swos.rel(pc),a0		
        move.l  _expmem(pc),a1
		bsr	_LoadFileDEC
		lea	reloc_size(pc),a0
		move.l	d0,(a0)
		lea	Swos.prg(pc),a0
	
        move.l  program_location(pc),a1

		bsr	_LoadFileDEC
		;bsr	remove_hogs
		lea	swos_version(pc),a0
		move.l	d0,(a0)
		move.l	program_location(pc),a0
		move.l	_expmem(pc),a1
;a0 = Program
;a1 = relocation table
;relocate:
;		movem.l	d0-d1/a0-a2,-(a7)
;		moveq	#8,d1				;Header of load location!
;		move.l	reloc_size(pc),d0		;Size of relocation table!
;		move.l	a0,a2
;continue_relocation:
;		add.l	(a1)+,a0			;Add and move
;		add.b	d1,(a0)				;Force relocation!
;		move.l	a2,a0				;Restore
;		subq.l	#4,d0				;Because its longword!
;		bne.s	continue_relocation
relocate:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	program_location(pc),d1				; load location!
        sub.l   #$100000,d1             ; base address
		move.l	reloc_size(pc),d0		;Size of relocation table!
		move.l	a0,a2

        ; non-relocated addresses are like $001x???? with 0<=x<8
        ; a0 is always odd and points on the "1x" part
        ;
        ; this is basic reloc which allows to reloc on second part of
        ; chipmem or just slow mem, but not any mem, well it can be done
        ; of course
        ;
continue_relocation:
		add.l	(a1)+,a0			;Add and move
        ; some reloc offsets are bogus (ex: C2 C3 at start)
        ; filter them out with those heuristics
        tst.b   -(a0)
        bne.b   .skip
        cmp.b   #$18,(1,a0)
        bcc.b   .skip
        cmp.b   #$10,(1,a0)
        bcs.b   .skip
        
		add.l	d1,(a0)				;Force relocation!
.skip
		move.l	a2,a0				;Restore
		subq.l	#4,d0				;Because its longword!
		bne.s	continue_relocation
		movem.l	(a7)+,d0-d1/a0-a2
		move.w	#$2000,sr
		lea	swos_version(pc),a2
		move.l	(a2),d2
		move.l	#$4ef96002,d0
		move.l	#$70004e75,d1

;		cmp.l	#363958,d2
;		beq	swos_xxx       ; SPS841, unsupported
		cmp.l	#341138,d2
		beq	swos_9596       ; SPS201
		cmp.l	#357260,d2		;TEST FIRST
		beq	swos_9697
		cmp.l	#337114,d2
		beq.s	swos_9495   ; ??? jotd: I don't have this version
		cmp.l	#335006,d2
		beq	swos_9495_2     ; SPS840
		cmp.l	#357298,d2
		beq	swos_euro       ; SPS1825
		cmp.l	#357226,d2
		beq	swos_152
		cmp.l	#356964,d2
		beq	swos_0842		; SPS842
		cmp.l	#334640,d2
		beq	swos_german
        
        pea	TDREASON_WRONGVER
        move.l	_resload(pc),-(a7)
        addq.l	#resload_Abort,(a7)
        rts

remove_hogs:
		movem.l	d0/a0,-(a7)
		move.l	reloc_size(pc),d0	;Size of file!
		move.l	program_location(pc),a0		;$180000
loopblit:
		cmp.w	#$33fc,(a0)
		bne.s	_notblit
		cmp.w	#$8400,2(a0)
		beq.s	nextcheck
		cmp.w	#$0400,2(a0)
		bne.s	_notblit
nextcheck:
		cmp.l	#$dff096,4(a0)
		bne.s	_notblit
		move.w	#$6006,(a0)		;Store BRA		
_notblit:	addq.l	#2,a0
		subq.l	#2,d0
		bne.s	loopblit
		movem.l	(a7)+,d0/a0
		rts
;---------------------------------------

swos_9495:
        lea pl_9495(pc),a0
        bra patch_with_patchlist

pl_9495
    PL_START
    PL_W    $6a,$6002       ; fix zero div
    PL_W    $c6,$6002       ; cacr
    ; copylock
    PL_P    $19e6,copylock
	
    ; Fake send to loader, but we still need to update current disk or whatnot
	; else it crashes when loading tactics because disk changes and state is
	; not updated in the game
	PL_S	$3d2+6,$4b6-$456

	
    PL_P    $22da,fix_memory_routine_9495     ; 101676
    PL_R    $37c		;Format Disk name removed  
    
    ; jotd
    ; fix snoop bugs
    ;PL_PSS  $2398,fix_snoop_bug,4
    ;PL_ORW  $20be,$200  ; colorbit bplcon0
    ;PL_L  $20c8,$01FE0000  ; remove bplcon3 write
    ;PL_L  $20cc,$01FE0000  ; remove bplcon4 write
    ;PL_R    $fe0   ; floppy shit
    ;PL_R    $156a   ; floppy shit
	
	PL_P	$5d8,rob_northen_loader   ; not sure!
    
    PL_END
    
swos_9495_2:

        lea pl_9495_2(pc),a0
        bra patch_with_patchlist

pl_9495_2
    PL_START
	; aka SPS 840
	PL_PA	$17dc+2,data_buffer
	; removes size check
	; which is stupid as at this point the file
	; may be RNC packed. We have no idea of the actual
	; file size!
	PL_NOP	$1814,2		; no size check
	PL_PA	$1816+2,data_buffer

    PL_W    $d4,$6002       ; fix zero div
    PL_W    $130,$6002       ; cacr
    ; copylock
    PL_P    $1bea,copylock
    ; Fake send to loader, but we still need to update current disk or whatnot
	; else it crashes when loading tactics because disk changes and state is
	; not updated in the game
	PL_S	$456,$4b6-$456
	
    PL_P    $24ec,fix_memory_routine_9495_2     ; 10171A
    PL_R    $3e6		;Format Disk name removed
    PL_PS   $756a,access	
    ;PL_W	$552c,$6002,	;TESTTESTTEST    
    
    ; jotd
    ; fix snoop bugs
    ;PL_PSS  $2398,fix_snoop_bug,4
    ;PL_ORW  $20be,$200  ; colorbit bplcon0
    ;PL_L  $20c8,$01FE0000  ; remove bplcon3 write
    ;PL_L  $20cc,$01FE0000  ; remove bplcon4 write
    ;PL_R    $fe0   ; floppy shit
    ;PL_R    $156a   ; floppy shit

	PL_P	$5d8,rob_northen_loader
    
    PL_END 

swos_9596:

        lea pl_9596(pc),a0
        bra patch_with_patchlist
		
pl_9596
    PL_START
	; allows to read team files of any size
	PL_PA	$17e2+2,data_buffer
	PL_NOP	$181a,2		; no size check
	PL_PA	$181c+2,data_buffer	; no buffer re-set

    PL_W    $CC,$6002       ; fix zero div
    PL_W    $128,$6002       ; cacr
    ; copylock
    PL_P    $1bfa,copylock
    ; Fake send to loader, but we still need to update current disk or whatnot
	; else it crashes when loading tactics because disk changes and state is
	; not updated in the game
	PL_S	$44e,$4ae-$44e

    PL_P    $24fc,fix_memory_routine_9596
    PL_R    $3de		;Format Disk name removed
    PL_PS   $7518,access	
    PL_R    $3db44          ;Removes disk requesters!
    ;PL_W	$552c,$6002,	;TESTTESTTEST    
    
    ; jotd
    PL_PS   $2F70,kb_hook
    ; fix snoop bugs
    ;PL_PSS  $2398,fix_snoop_bug,4
    ;PL_ORW  $20be,$200  ; colorbit bplcon0
    ;PL_L  $20c8,$01FE0000  ; remove bplcon3 write
    ;PL_L  $20cc,$01FE0000  ; remove bplcon4 write
    PL_R    $fe0   ; floppy shit
    PL_R    $156a   ; floppy shit

	PL_P	$5D0,rob_northen_loader
    
	PL_L	$4a832,$4EB80100
	
    PL_END 
;-----------------------------
swos_euro:

        lea pl_euro(pc),a0
        bra patch_with_patchlist

pl_euro
    PL_START
	; jotd: proper sized buffer for big team files
	PL_PA	$5944+2,data_buffer
	PL_NOP	$597e,4			; no size check
	PL_PA	$5982+2,data_buffer
	
    PL_W    $CC,$6002       ; fix zero div
    ; copylock
    PL_P    $5d78,copylock

    ; Fake send to loader, but we still need to update current disk or whatnot
	; else it crashes when loading tactics because disk changes and state is
	; not updated in the game
	PL_S	$43e,$49e-$43e

    PL_P    $667a,fix_memory_routine_9697
    PL_R    $3ce		;Format Disk name removed
    PL_PS   $7614,access	
    
    ; jotd
    PL_PS   $1B44,kb_hook
    ; fix snoop bugs
    PL_PSS  $2398,fix_snoop_bug,4
    PL_ORW  $20be,$200  ; colorbit bplcon0
    PL_L  $20c8,$01FE0000  ; remove bplcon3 write
    PL_L  $20cc,$01FE0000  ; remove bplcon4 write
    PL_R    $fd0   ; floppy shit
    PL_R    $155a   ; floppy shit
    
	PL_P	$5C0,rob_northen_loader
	PL_L	$4dff6,$4EB80100
	
    PL_END
    
;-----------------------------
swos_152:
        lea pl_9697_1(pc),a0
        bra patch_with_patchlist

pl_9697_1
    PL_START
	; proper sized buffer for big team files
	PL_PA	$5968+2,data_buffer
	PL_NOP	$59a2,4			; no size check
	PL_PA	$59a6+2,data_buffer
	
    PL_W    $CC,$6002       ; fix zero div
    ; copylock
    PL_W    $5d80,$26bc
    PL_W    $5de4,$26bc
    PL_L    $5de6,$cfd1efe7
    PL_L    $5d82,$71583efc
	
	
    PL_P    $670a,fix_memory_routine_9697_1
    PL_PS   $76a4,access
    ;PL_W	$552c,$6002,	;TESTTESTTEST    
    
    ; jotd
    PL_PS   $1B58,kb_hook

    ; Fake send to loader, but we still need to update current disk or whatnot
	; else it crashes when loading tactics because disk changes and state is
	; not updated in the game
	PL_S	$43e,$49e-$43e

    ; fix snoop bugs
    PL_PSS  $23ac,fix_snoop_bug,4
    PL_ORW  $20d2,$200  ; colorbit bplcon0
    PL_L  $20dc,$01FE0000  ; remove bplcon3 write
    PL_L  $20e0,$01FE0000  ; remove bplcon4 write
    PL_R    $fd0   ; floppy shit
    PL_R    $155a   ; floppy shit
   

   
	PL_R	$e7e
	PL_P	$5C0,rob_northen_loader

	PL_L	$4df98,$4EB80100

    PL_END
;--------------------------------------
swos_german:
        lea pl_german(pc),a0
        bra patch_with_patchlist
        

pl_german
    PL_START
	; jotd: proper sized buffer for big team files
	PL_PA	$17dc+2,data_buffer
	PL_NOP	$1814,2			; no size check
	PL_PA	$1816+2,data_buffer

    PL_W    $d4,$6002       ; fix zero div
    PL_W    $130,$6002       ; cacr
    ; copylock
    PL_P    $1bea,copylock

    PL_P    $24ec,fix_memory_routine_9495_2
    PL_R    $3e6		;Format Disk name removed
    PL_PS   $75a2,access	
   
    ; jotd
    ; Fake send to loader, but we still need to update current disk or whatnot
	; else it crashes when loading tactics because disk changes and state is
	; not updated in the game
	PL_S	$456,$4b6-$456
	
    PL_PS   $2F4C,kb_hook
    ; fix snoop bugs
    PL_PSS  $37a0,fix_snoop_bug,4
    PL_ORW  $34c6,$200  ; colorbit bplcon0
    PL_L  $34d0,$01FE0000  ; remove bplcon3 write
    PL_L  $34d4,$01FE0000  ; remove bplcon4 write
    PL_R    $fd8   ; floppy shit
    PL_R    $156a   ; floppy shit    ; jotd

 	PL_P	$5D8,rob_northen_loader
   
    PL_END


swos_0842:  ; SPS 0842 96/76
        lea pl_0842(pc),a0
        bra patch_with_patchlist
        
; offsets similar to "euro" version
pl_0842
    PL_START
	; jotd: proper sized buffer for big team files
	PL_PA	$5944+2,data_buffer
	PL_NOP	$597e,4			; no size check
	PL_PA	$5982+2,data_buffer

    PL_W    $CC,$6002       ; fix zero div
    ; copylock
    PL_W    $5d54,$26bc
    PL_L    $5d56,$cfd1efe7
    ; Fake send to loader, but we still need to update current disk or whatnot
	; else it crashes when loading tactics because disk changes and state is
	; not updated in the game
	PL_S	$442,$49e-$442
    PL_P    $6664,fix_memory_routine_9697   ; same address as 9697
    PL_R    $3ce		;Format Disk name removed
    PL_PS   $75fe,access	
  
    PL_R    $407e0          ;Removes disk requesters!
    
    ; jotd
    PL_PS   $1B44,kb_hook
    ; fix snoop bugs
    PL_PSS  $2398,fix_snoop_bug,4
    PL_ORW  $20be,$200  ; colorbit bplcon0
    PL_L  $20c8,$01FE0000  ; remove bplcon3 write
    PL_L  $20cc,$01FE0000  ; remove bplcon4 write
    PL_R    $fd0   ; floppy shit
    PL_R    $155a   ; floppy shit
   
	PL_P	$5C0,rob_northen_loader
	; 4a120 can become corrupt
	PL_L	$4de92,$4EB80100
   
    PL_END
    
;-----------------------------
swos_9697:
		        
        lea pl_9697(pc),a0
patch_with_patchlist:
        move.l	program_location(pc),a1
		        move.l  _resload(pc),a2
        jsr (resload_Patch,a2)
     
        ; set registers D5-D7 to expected values
        move.l  #CHIPMEMSIZE+PROGRAM_FASTMEMSIZE,D7
        move.l  #FASTBITS,d5
        move.l  #CHIPBITS|FASTBITS,d6       

        move.l	program_location(pc),a0
		jmp	(a0)			;Execute program!		

pl_9697
    PL_START
	; jotd: proper sized buffer for big team files
	PL_PA	$5944+2,data_buffer
	PL_NOP	$597e,4		; no size check
	PL_PA	$5982+2,data_buffer

	
	
    PL_W    $CC,$6002       ; fix zero div
    ; copylock (checked at +$1fe70: EORI.L	#$715829de,D0)
    PL_P    $5D78,copylock

    PL_P    $667A,fix_memory_routine_9697
    PL_R    $3ce		;Format Disk name removed
    PL_PS   $7614,access
    PL_W    $4144a,$6008	;Removes last bug!		  
    
    ; jotd
    PL_PS   $1B44,kb_hook

    ; Fake send to loader, but we still need to update current disk or whatnot
	; else it crashes when loading tactics because disk changes and state is
	; not updated in the game
	PL_S	$43e,$49e-$43e

    ; fix snoop bugs
    PL_PSS  $2398,fix_snoop_bug,4
    PL_ORW  $20be,$200  ; colorbit bplcon0
    PL_L  $20c8,$01FE0000  ; remove bplcon3 write
    PL_L  $20cc,$01FE0000  ; remove bplcon4 write
    PL_R    $fd0   ; floppy shit
    PL_R    $155a   ; floppy shit

	PL_P	$5C0,rob_northen_loader
	PL_L	$4dfec,$4EB80100

    PL_END
    
fix_snoop_bug
	MOVEA.L	#_custom,A6		;102398: 2c7c00dff000
	move.W	#$200,bplcon0(A6)	; colorbit
    rts

avoid_big_value:
	tst.w	d0
	beq.b	.fail
	cmp.w	#$50,d0
	bcs.b	.ok
.fail
	; value in D0 is bogus, this will trigger an access fault
	; clear it, the called routine will run in degraded mode, it doesn't
	; seem to change anything.
	;
	; but fix this value in memory to avoid more issues
	; this will degrade gameplay but won't crash

	move.w	#1,(-2,a0)
	addq.w	#4,a7
	MOVEM.L	(A7)+,D0-D7/A0-A6
	rts
.ok
	SUBQ.W	#1,D0			;14dfec: 5340
	rts
	

; replaces memory detection routine that pokes into every location
; from $80000 to $20*$80000 ...
; in the end we just store the amount of chipmem, and use fastmem
; for the executable. Game doesn't handle/use more fastmem apparently
;
; if we set the proper value game tries to read outside memory bounds
; damn this memory management is a nightmare
;
; previous version of the slave wrote the value $200000 in a wrong
; location, leaving the actual location at 0, and the game worked
; so maybe it should be left as is.
FIX_MEM_ROUTINE:MACRO
fix_memory_routine_\1
    rts
;    move.l  a0,-(a7)
;    move.l  _expmem(pc),a0
;    add.l   #\2+PROGRAM_LOCATION_OFFSET,a0
;    MOVE.L #CHIPMEMSIZE,(a0)
;    move.l  (a7)+,a0
;    rts
    ENDM

    
    FIX_MEM_ROUTINE 9697_1,$589c
    FIX_MEM_ROUTINE 9495,$1676
    FIX_MEM_ROUTINE 9495_2,$1712
    FIX_MEM_ROUTINE 9596,$1718
    FIX_MEM_ROUTINE 9697,$5878

    
rob_northen_loader:
	move.l	a3,-(a7)
	add.w	d0,d0
	lea		rob_commands_table(pc),a3
	add.w	(a3,d0.w),a3
	jsr		(a3)
	move.l	(a7)+,a3
	rts

; < A0: name
; > A0: name prepended with "SAVE/" if .TAC,.PRE,.DIY,.SEA,.CAR, .HIL file,
; and DF0: prefix removed
; else unchanged

fix_filename:
	move.l	a0,a2
	cmp.b	#':',(3,a0)
	bne.b	.loop
	addq.w	#4,a0		; skip DF0:
.loop
	tst.b	(a2)+
	bne.b	.loop
	subq.w	#1,a2	; back
	; try to match one of the save extensions
	move.b	-(a2),d0
	ror.l	#8,d0
	move.b	-(a2),d0
	ror.l	#8,d0
	move.b	-(a2),d0
	ror.l	#8,d0
	move.b	-(a2),d0
	ror.l	#8,d0
	lea		_ext_table(pc),a3
.comp
	move.l	(a3)+,d2
	beq.b	.no_userdata
	cmp.l	d0,d2
	bne.b	.comp
	
	; user data file: copy to buffer with "SAVE/"
	lea		_save_filename(pc),a3
	move.l	a0,a2
.copy
	move.b	(a2)+,(a3)+
	bne.b	.copy
	lea	_save_filepath(pc),a0
.no_userdata
	rts
	
_ext_table:
	dc.l	".DIY"
	dc.l	".PRE"
	dc.l	".SEA"
	dc.l	".CAR"
	dc.l	".TAC"
	dc.l	".HIL"
	dc.l	0
	
rob_commands_table:
	dc.w	rob_load-rob_commands_table
	dc.w	rob_save-rob_commands_table
	dc.w	rob_delete-rob_commands_table
	dc.w	rob_list_directory-rob_commands_table
	dc.w	rob_format_disk-rob_commands_table
	dc.w	rob_get_file_size-rob_commands_table
	dc.w	nothing-rob_commands_table
	dc.w	nothing-rob_commands_table
	
rob_load:
	movem.l	d0-d7/a0-a6,-(a7)
	bsr		fix_filename
	bsr	_LoadFile
	movem.l	(a7)+,d0-d7/a0-a6
	move.l	size(pc),d1
	moveq	#0,d0
	rts
	
rob_save:
	movem.l	d0-d7/a0-a6,-(a7)
	bsr		fix_filename
	move.l	d1,d0		; size
	bsr	_SaveFile
	movem.l	(a7)+,d0-d7/a0-a6
	move.l	size(pc),d1
	moveq	#0,d0
	rts
	
rob_delete:
	movem.l	d0-d7/a0-a6,-(a7)
	bsr		fix_filename
	bsr	_Deletefile
	movem.l	(a7)+,d0-d7/a0-a6
	moveq	#0,d0
	rts
	
rob_format_disk:
	moveq	#0,d0
	rts

rob_get_file_size:
	movem.l	d2-d7/a0-a6,-(a7)	
	bsr		fix_filename
	bsr		_GetFileSize
	move.l	d0,d1
	movem.l	(a7)+,d2-d7/a0-a6
	moveq	#0,d0
	rts
	
rob_list_directory:
	movem.l	d0-d7/a0-a6,-(a7)
	move.l	_resload(pc),a2
	; skip colon
	moveq	#0,d1
.sk
	move.b	(a0,d1.w),d0
	beq.b	.out
	cmp.b	#':',d0
	beq.b	.colon
	addq	#1,d1
	bra.b	.sk
.colon
	; colon found: skip it
	addq.w	#1,a0
	add.w	d1,a0
.out
	lea		_savedir(pc),a0
	; a0: directory path, stripped from drive prefix
	; a1: buffer, save it
	move.l	a1,a3
	lea		listdir_buffer(pc),a1
	move.l	#BUFFER_SIZE,D0
	jsr		resload_ListFiles(a2)
	lea		size(pc),a0
	move.w	d0,(a0)				; number of files
	beq.b	.empty
	subq	#1,d0			; minus one for dbf
	
	lea		listdir_buffer(pc),a1
.copy_loop:
	moveq	#0,d1
.copy_file:
	move.b	(a1)+,(2,a3,d1.w)
	beq.b	.copyout
	addq	#1,d1
	bra.b	.copy_file
	; set name length
.copyout:
	move.b	d1,(1,a3)
	; try to mimic rob output...
	move.b	#$FD,(a3)
	add.w	#$20,a3		; next entry
	dbf		d0,.copy_loop
	
.empty:	
	movem.l	(a7)+,d0-d7/a0-a6
	move.w	size(pc),d1
	moveq	#0,d0
	rts
	
nothing:

	nop
	rts
	
_flushcache:
	move.l	a2,-(a7)
	move.l	_resload(pc),a2
	jsr	resload_FlushCache(a2)
	move.l	(a7)+,a2
	rts

request:
		
; Fixes bug with Highlights play! JOTD: potential issue if A1 is in fast!!!
access:
	adda.l	$18(a5),a1			;Game
	move.l	a1,d1
	and.l	#$00ffffff,d1			;Clear high bytes!
	move.l	d1,a1
	moveq	#0,d1				;Game
	rts




kb_hook
    move.b  $bfec01,d0
    move.w  d0,-(a7)
    not.b   d0
    ror.b   #1,d0
    cmp.b   _keyexit(pc),d0
    beq.b   quit
	move.w  (a7)+,d0
    rts
    
quit
	pea	TDREASON_OK
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
    
copylock:
    MOVE.L #$71583efc,(A3)
    rts
    
;---------------

_resload	dc.l	0		;address of resident loader
size:
		dc.l	0
reloc_size:
		dc.l	0
swos_version:
		dc.l	0
program_location
    dc.l    0
data_buffer:
	dc.l	0
listdir_buffer:
	ds.b	BUFFER_SIZE
	dc.l	0		; safety
;--------------------------------
; IN:	d0=offset d1=size d2=disk a0=dest
; OUT:	d0=success

		cnop	0,4

_GetFileSize:
		movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_GetFileSize(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
_LoadFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFile(a2)
		lea	size(pc),a0
		move.l	d0,(a0)
		movem.l	(a7)+,d0-d1/a0-a2
		rts

_LoadFileDEC:
		movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
_Deletefile:
		movem.l	d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_DeleteFile(a2)
		movem.l	(a7)+,d1/a0-a2
		rts
_SaveFile:
		movem.l	d0-d1/a0-a2,-(a7)
		move.l	_resload(pc),a2
		jsr	resload_SaveFile(a2)
au:		movem.l	(a7)+,d0-d1/a0-a2
		rts
;==========================================