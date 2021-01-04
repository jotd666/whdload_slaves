
	INCDIR	Include:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	lvo/dos.i

;CHIPONLY
	IFD BARFLY
	OUTPUT	"WhoFramedRogerRabbit.slave"
	IFND	CHIPONLY
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



	IFD	CHIPONLY
HRTMON
CHIPMEMSIZE	= $100000
FASTMEMSIZE	= $0000
	ELSE
BLACKSCREEN
CHIPMEMSIZE	= $80000
FASTMEMSIZE	= $80000
	ENDC

NUMDRIVES	= 1
WPDRIVES	= %0000


DOSASSIGN

;DISKSONBOOT
;INITAGA
HDINIT
;IOCACHE		= 10000
;MEMFREE	= $200
;NEEDFPU
SETPATCH
;STACKSIZE = 10000
BOOTDOS
CACHE

slv_Version	= 17
slv_Flags	= WHDLF_NoError|WHDLF_Examine|WHDLF_NoKbd
slv_keyexit	= $5D	; num '*'

	include	whdload/kick13.s

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

	
slv_name	dc.b	"Who Framed Roger Rabbit"
	IFD	CHIPONLY
	dc.b	" (CHIPONLY MODE)"
	ENDC
			dc.b	0
slv_copy	dc.b	"1988 Silent/Buena Vista",0
slv_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Thanks to Radertified@EAB for trainer offsets",10,10
		dc.b	"Thanks to Tony Aksnes for disk images",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
slv_CurrentDir:
	dc.b	"data",0

slv_config
        dc.b    "C1:X:skip level 1 and 3:0;"
        dc.b    "C1:X:infinite lives:1;"
        dc.b    "C1:X:invincibility:2;"
        dc.b    "C1:X:full speed levels 1 and 3:3;"
        dc.b    "C1:X:skip level 2:4;"
        dc.b    "C1:X:penguins can't replace napkins level 2:5;"
        dc.b    "C1:X:infinite time level 4:6;"
        dc.b    "C3:B:skip introduction;"
		dc.b	0

program:
	dc.b	"rogerrabbit",0
args		dc.b	10
args_end
	dc.b	0
d1_assign
	dc.b	"Disk1",0
d2_assign
	dc.b	"Disk2",0
gfxname
	dc.b	"graphics.library",0	
; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	EVEN


    
PATCH_XXXLIB_OFFSET:MACRO
	movem.l	d0-d1/a0-a1,-(a7)
	move.l	A6,A1
	add.l	#_LVO\1,A1
	lea	old_\1(pc),a0
	move.l	2(A1),(A0)
	move.w	#$4EF9,(A1)+	
	pea	new_\1(pc)
	move.l	(A7)+,(A1)+
	bra.b	end_patch_\1
old_\1:
	dc.l	0
end_patch_\1:
	movem.l	(a7)+,d0-d1/a0-a1

	ENDM

    
    
_bootdos
		clr.l	$0.W

	; saves registers (needed for BCPL stuff, global vector, ...)

    lea	(_saveregs,pc),a0
    movem.l	d1-d7/a1-a2/a4-a6,(a0)
    lea	_stacksize(pc),a2
    move.l	4(a7),(a2)

        
		move.l	(_resload,pc),a2		;A2 = resload

	;get tags
        lea	(tag,pc),a0
        jsr	(resload_Control,a2)
            
        lea	gfxname(pc),a1
        moveq	#0,d0
        move.l	$4.W,a6
        jsr	_LVOOpenLibrary(a6)

        move.l	d0,a6
        PATCH_XXXLIB_OFFSET	RectFill
        PATCH_XXXLIB_OFFSET	BltBitMap
        PATCH_XXXLIB_OFFSET	Text
        PATCH_XXXLIB_OFFSET	Move

	;open doslib
		lea	(_dosname,pc),a1
		move.l	(4),a6
		jsr	(_LVOOldOpenLibrary,a6)
		move.l	d0,a6			;A6 = dosbase

		lea	d1_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign
		lea	d2_assign(pc),a0
		sub.l	a1,a1
		bsr	_dos_assign

		bsr	check_version 
	;load exe
        move.l  _version(pc),d1
		lea	program(pc),a0
		lea	args(pc),a1
		moveq	#args_end-args,d0
		lea	patch_exe_c160(pc),a5
        cmp.l   #1,d1
        beq.b   .go
		lea	patch_exe_prerelease(pc),a5
        ;cmp.l   #2,d0
        ;beq.b   .go
.go
		bsr	load_exe_special
_quit		
        pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)
		
check_version:
	movem.l	d0-d1/a1,-(a7)
	lea	program(pc),A0
	move.l	_resload(pc),a2
	jsr	resload_GetFileSize(a2)

	moveq.l	#1,d1
	cmp.l	#107472,D0
	beq.b	.ok
	moveq.l	#2,d1
	cmp.l	#100708,D0
	beq.b	.ok

	pea	TDREASON_WRONGVER
	move.l	_resload(pc),-(a7)
	addq.l	#resload_Abort,(a7)
	rts
.ok
	lea	_version(pc),a1
	move.l	d1,(a1)

	movem.l	(a7)+,d0-d1/a1
	rts

; call graphics.library function then wait
DECL_GFX_WITH_WAIT:MACRO
new_\1
    pea .next(pc)
	move.l	old_\1(pc),-(a7)
	rts
.next:
    bra wait_blit
    ENDM    
    
    DECL_GFX_WITH_WAIT  BltBitMap
    DECL_GFX_WITH_WAIT  RectFill
    DECL_GFX_WITH_WAIT  Text    ; not waiting on Text is probably the issue
    DECL_GFX_WITH_WAIT  Move

wait_blit
    movem.l D0,-(a7)
 ;   movem.l _blitter_fixes(pc),d0
 ;   btst    #1,d0
 ;   bne.b   .nowait
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
.nowait
    movem.l (a7)+,d0
	rts    
; < d7: seglist (APTR)

patch_exe_c160
	move.l	(_resload,pc),a2
	lea	pl_main_c160(pc),a0
.do
	move.l	d7,a1
	jsr	(resload_PatchSeg,a2)

	rts
    
patch_exe_prerelease
	move.l	(_resload,pc),a2
	lea	pl_main_prerelease(pc),a0
.do
	move.l	d7,a1
	jsr	(resload_PatchSeg,a2)

	rts
pl_main_c160
    PL_START
    PL_P    $FA,overlay_jump_c160
    PL_P    $11A,overlay_jump_c160_2
    
    PL_PS   $35d2,fix_dma_write_d0
    
    PL_END
    
    ; this is the version that I originally supported. No wonder why I was lazy
    ; and did a diskfile install: the startup code is difficult to fool with bootdos
pl_main_prerelease
    PL_START
    ; when performing a CreateProc from bootdos, program thinks it's been started from
    ; workbench and does the GetMsg shit which locks up the game: let's just disable that
    PL_NOP  $5222,2
    ; no longer needed now. Program reached that point (dead end) when just using LoadSeg
    ; like the other version and a lot of other programs... But the seglist was the whdload bootdos one
    ; so it kind of looped...
    ;; PL_P    $68A4,create_process 
    ; hook after LoadSeg called with NULL seglist (overlay load)
    PL_PS   $005e2a,overlay_jump_prerelease
    
    PL_IFC3
    PL_NOP  $00029a,4
    PL_ENDIF
    
    PL_PS   $2676,fix_dma_write_d0
    
    PL_END
    
fix_dma_write_d0
    MOVE.W  D0,$00DFF096
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

; <D1: loaded segment (BCPL), 0 then code
overlay_jump_prerelease
    movem.l d0-d1/a0-a2,-(a7)
    move.l  _resload(pc),a2
    add.l   d1,d1
    add.l   d1,d1
    addq.l  #4,d1
    move.l  d1,a1
    cmp.l   #$0c6c010e,($4416c-$43898,a1)
    bne.b   .no_part_1

    lea pl_part_1_prerelease(pc),a0
    jsr resload_Patch(a2)
    bra   .out
.no_part_1
    cmp.l   #$4eac816a,($44C2C-$43898,a1)
    bne.b   .no_prot

    lea pl_protect_part_prerelease(pc),a0
    jsr resload_Patch(a2)
    bra   .out
    
.no_prot
    cmp.l   #$522c839e,($013300-$123b4,a1)
    bne.b   .no_level2
    lea pl_part_2_prerelease(pc),a0
    jsr resload_Patch(a2)
    bra   .out
     
.no_level2
    cmp.l   #$19704000,($014894-$014886,a1)
    bne.b   .no_level4
    lea pl_part_4_prerelease(pc),a0
    jsr resload_Patch(a2)
    bra   .out
    
.no_level4
    ;move.l  a1,$100
.out   
    movem.l (a7)+,d0-d1/a0-a2
    ; original
	ADDA.L  A0,A0                ;005e2a: d1c8
	ADDA.L  A0,A0                ;005e2c: d1c8
	TST.L   (A0)                 ;005e2e: 4a90    
    rts



    
; prot part: $3D0DA NOP $3CC7C start
pl_protect_part_prerelease
    PL_START
    ;PL_L  $44C2C-$43898,$70004E71 ; disable password check JOTD version
    PL_B    $123A,$60   ; return forced
    PL_NOP  $13AE,2     ; password check (Radertified@eab)
    PL_END
    
pl_part_1_prerelease
    PL_START
    
    PL_IFC1X    1     ; level 1 & 3: infinite fails on oil slicks
    PL_NOP      $3eb22,2
    PL_ENDIF    
    PL_IFC1X    2     ; invincibility
    PL_NOP      $3c906,2    
    PL_ENDIF
    PL_IFC1X    3       ; full speed
    PL_W    $3c8f8+2,$10    ; full speed (game)
    PL_W    $3d9a4+2,$10    ; full speed (game init)
    PL_ENDIF
    ; ends race immediately
    PL_IFC1X    0       ; skip level 1-3
    PL_W   $4416e-$43898,$8    ; tests against low x value => ends
    PL_ENDIF
    PL_END
    
pl_part_2_prerelease
    PL_START
    ; trainer level 2
    PL_IFC1X    1    ; infinite lives
    PL_NOP  $013300-$123b4,4
    PL_ENDIF
    PL_IFC1X    5  ; level 2 Prevent Penguins From Replacing Napkins
    PL_NOP  $0127ea-$123b4,2     
    PL_ENDIF
    PL_IFC1X    4   ; skip level 2
	PL_B    $01290e-$123b4,$42
	PL_NOP  $012912-$123b4,4
    PL_ENDIF
    PL_END
    
pl_part_4_prerelease
    PL_START
    ; trainer level 4
    PL_IFC1X    1   ; infinite lives
    PL_NOP  $014a20-$014886,4    
    PL_ENDIF   
    PL_IFC1X    2    ; invincibility: 
    PL_B      $018bfe-$014886,$60    ; Weasels Can't Kill You
    PL_B      $019dc4-$014886,$60    ; invincibility: Dip Can't Kill You
    PL_ENDIF
    PL_IFC1X    6    ; infinite time
    PL_NOP  $016b34-$014886,4    
    PL_ENDIF
    PL_END


create_process
        ; D1 name, D2 pri D3 seglist D4 stacksize
  ;      	JSR	(_LVOCreateProc,A6)	;0068a4: 4eaeff76 dos.library (off=-138)
    illegal

; called just before jumping to some
; overlayed code that just got loaded
; loaded code doesn't correspond to exact
; segments start
overlay_jump_c160:
    move.l  _resload(pc),a2
    movem.l d0-d1/a0-a1,-(a7)
    cmp.l   #$487800fa,($E22-$DF6,a1)
    bne.b   .no_part_1
    lea pl_part_1_c160(pc),a0
    jsr resload_Patch(a2)
    bra .launch
.no_part_1   
    cmp.l   #$426dffe0,($34-$2c,a1)
    bne.b   .no_protect_part
    lea pl_protect_part_c160(pc),a0
    jsr resload_Patch(a2)
    bra .launch
.no_protect_part
    cmp.l   #$520013C0,($D60,a1)
    bne.b   .no_part2_c160
    lea pl_part_2_c160(pc),a0
    jsr resload_Patch(a2)    
    bra .launch    
.no_part2_c160
    cmp.l   #$41FAFC5A,($0005A2-$00059A,a1)
    bne.b   .no_intro
    lea pl_intro_c160(pc),a0
    jsr resload_Patch(a2)
    bra   .launch
.no_intro
    cmp.l   #$3e2f003e,(8,a1)
    bne.b   .no_part4_c160
    lea pl_part_4_c160(pc),a0
    jsr resload_Patch(a2)
    bra   .launch
.no_part4_c160

.launch    
    movem.l (a7)+,d0-d1/a0-a1
	MOVEM.L	(A7)+,D2-D7/A2-A7
    move.l  a1,$100
	JMP	(A1)

pl_intro_c160
    PL_START
    PL_IFC3
    PL_B    $0005E8-$00059A,$60
    PL_ENDIF
    PL_END    

; train part 2
;00035F20 0001 ed66                OR.B #$66,D1
;00035F24 5200                     ADDQ.B #$01,D0
;00035F26 13c0 0001 ed66           MOVE.B D0,$0001ed66 [04] <=== nop
;00035F2C 6100 fdb4                BSR.W #$fdb4 == $00035ce2

pl_protect_part_c160
    PL_START
    PL_NOP  $3d08a-$3cc2c,2 ; remove password check ($45E)
    PL_B  $328,$60 ; remove password screen completely
    PL_END
    
pl_part_1_c160
    PL_START
    ; ends race immediately
    PL_IFC1X    0
    PL_PS   $3CA52-$3bdf6,end_race_pos
    PL_ENDIF
    ; infinite lives
    PL_IFC1X    1
    PL_NOP      $3eb24-$3bdf6,6
    PL_ENDIF
    PL_END

pl_part_2_c160
    PL_START
    ; trainer level 2
    PL_IFC1X    1    ; infinite lives
    PL_NOP  $13D4C-$012fec,2
    PL_ENDIF
    PL_IFC1X    5  ; level 2 Prevent Penguins From Replacing Napkins
    PL_NOP  $13298-$012fec,2     
    PL_ENDIF
    PL_IFC1X    4   ; skip level 2
    PL_W  $013270-$012fec,$4279    
    PL_NOP  $013276-$012fec,2    
    PL_ENDIF
    PL_END
    
pl_part_4_c160
    PL_START
    ; trainer level 4
    PL_IFC1X    1   ; infinite lives
    PL_NOP  $016b88-$016526,2    
    PL_ENDIF   
    PL_IFC1X    2    ; invincibility: 
    PL_B      $01a666-$016526,$60    ; Weasels Can't Kill You
    PL_B      $01b6ca-$016526,$60    ; invincibility: Dip Can't Kill You
    PL_ENDIF
    PL_IFC1X    6    ; infinite time
    PL_NOP  $18350-$016526,2    
    PL_ENDIF
    PL_END
    
    
end_race_pos
    move.w  #$120,d0
    RTS
    
overlay_jump_c160_2:
    MOVEA.L	D7,A3
    movem.l d0-d1/a0-a2,-(a7)
    lea pl_intro(pc),a0
    move.l  d7,a1
    add.l   #4,a1
    move.l  _resload(pc),a2
    ;jsr (resload_Patch,a2)
    movem.l (a7)+,d0-d1/a0-a2
    
    move.l  A3,$104
    JMP	$0004(A3)
    rts

pl_intro
    PL_START
    PL_PSS   $44f2,wait_blit,2
    PL_PSS   $4548,wait_blit,2
    PL_PSS   $4656,wait_blit,2
    PL_PSS   $46e8,wait_blit,2
    PL_PSS   $4abe,wait_blit,2
    PL_PSS   $4b50,wait_blit,2
    PL_PSS   $4e2a,wait_blit,2
    PL_PSS   $4e74,wait_blit,2
    PL_PSS   $505c,wait_blit,2
    PL_PSS   $50ee,wait_blit,2
    
    ;PL_P    $54f0,string_compare
        
    PL_END

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)


load_exe_special:
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
	movem.l	d2/a4,-(a7)
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/a4
.skip
    move.l  _version(pc),d0
    cmp.l   #2,d0
    beq.b   .alternate
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
.alternate
    ; call createproc and wait forever
    lea program(pc),a0    
    ; D1 points to "final:rr" but I guess any valid string is ok
    move.l  a0,d1
    ; D2 = 0
    moveq.l #0,d2
    ; D3 is the BCPL seglist
    move.l	d7,d3
    ; D4 stacksize = 2000
    move.l  #2000,d4
	jsr	(_LVOCreateProc,a6)
    ; wait forever
    move.l  $4,A6
    moveq   #0,d0
    jsr (_LVOWait,a6)
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
_version
	dc.l	0
tag		dc.l	WHDLTAG_CUSTOM1_GET
custom1	dc.l	0
		dc.l	0
		
	
;============================================================================

	END
