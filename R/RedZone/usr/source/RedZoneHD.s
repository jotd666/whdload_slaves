; Red Zone loader by JOTD
;
; Assembled with Barfly
;
; smc @ $A1B6, $A220, ...

; controls???


;;    ; SMC for 3D writes
;;LAB_00AD:
;;	OR.W	D3,(A2)+		;091cc: 875a  essayer de couper ces writes
;;LAB_00AE:
;;	OR.W	D3,8190(A2)		;091ce: 876a1ffe
;;LAB_00AF:
;;	OR.W	D3,16382(A2)		;091d2: 876a3ffe
;;LAB_00B0:
;;	OR.W	D3,24574(A2)		;091d6: 876a5ffe
;;	MOVE.W	(A7)+,D4		;091da: 381f
;;	CMPI.W	#$0010,D4		;091dc: 0c440010
;;	BEQ.W	LAB_00B2		;091e0: 6700013a
;;	LEA	LAB_00B7+2(PC),A6	;091e4: 4dfa0160
;;    ; SMC jump table, highly fishy!
;;    ; done to avoid/unroll loops (Duff's device)  : essayer de NOPs toute la zone
; du duff device
;;	MOVE.W	0(A6,D4.W),LAB_00B1+2	;091e8: 33f6400000009202
;;	MOVE.W	EXT_0148.W,D3		;091f0: 36385f50
;;	MOVE.W	EXT_0149.W,D4		;091f4: 38385f52
;;	MOVEA	EXT_014a.W,A6		;091f8: 3c785f54
;;	MOVE.W	EXT_014b.W,D0		;091fc: 30385f56



;CHIP_ONLY

	IFD	CHIP_ONLY
FASTSIZE = $1000
CHIPMEMSIZE = $180000
	ELSE
FASTSIZE = $81000
CHIPMEMSIZE = $80000
	
	ENDC
CHIP_BASE = $8000
	
	INCDIR	Include:
	INCLUDE	exec/execbase.i
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

	IFD	BARFLY
	BOPT	w4-			;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER				;disable supervisor warnings
	OUTPUT	RedZone.slave
	ENDC


_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_EmulTrap   ;|WHDLF_ClearMem
		dc.l	CHIPMEMSIZE			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_whddata-_base	;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5D			;ws_keyexit = num '*'
_expmem
		dc.l	FASTSIZE			;ws_ExpMem

		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w    0     ; kickstart name
		dc.l    $0         ; kicksize
		dc.w    $0         ; kickcrc
		dc.w	slv_config-_base

slv_config:
 		dc.b    "C1:X:no damage:0;"
 		dc.b    "C1:X:cheat keys:1;"
        dc.b    "C2:B:use original exe;"
        dc.b    "C3:B:enable high detail by default;"
		dc.b    "C4:X:Skip intro movie:0;"
        dc.b    "C4:X:Skip intro screens:1;"
        dc.b    "C4:X:Fast intro screens:2;"
		dc.b	0
	even

	
	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

;DEBUG

DECL_VERSION:MACRO
	dc.b	"3.1"
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

_whddata:
		dc.b	"data",0
_name		dc.b	"Red Zone"
		IFD	CHIP_ONLY
		dc.b	" (chip/debug MODE)"
		ENDC
		dc.b	0
_copy		dc.b	"1992 Psygnosis",0
_info		dc.b	"installed & fixed by JOTD",10
		dc.b	10,"Thanks to Bored Seal, Angus",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0

		even

; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
object_name
	dc.b	"fast_object",0
	even
	
_start	
	lea	_resload(pc),a1
	move.l	a0,(a1)			;save for later use
	move.l	a0,a2			;A2 = resload

	lea	(_tag,pc),a0
	jsr	(resload_Control,a2)

	move.l	use_original_exe(pc),d0
	beq.b	.out
	
	move.l	#WCPUF_Base_NC|WCPUF_Exp_CB|WCPUF_Slave_CB|WCPUF_IC|WCPUF_DC|WCPUF_BC|WCPUF_SS|WCPUF_SB,d0
	move.l	#WCPUF_All,d1
	jsr	(resload_SetCPU,a2)

.out
	IFND	CHIP_ONLY
	lea	progstart(pc),a0
	move.l	_expmem(pc),(a0)
	ENDC
	
	; init: freezes all interrupts

	MOVEA.L	#$7FF00,A7
	MOVEA.L	#$00DFF000,A6
	MOVE	#$7FFF,154(A6)
	MOVE	#$7FFF,150(A6)
	MOVE	#$7FFF,158(A6)

	; configure memory: useless to set some fastmem, the game does not use it

	clr.l	$4.W	; expmem start
	clr.l	$8.W	; size

	; load 'main' file at address $400.W

	lea	mainname(pc),A0
	lea	$400.W,a1
	jsr	(resload_LoadFile,a2)		

	; patch it

	lea	_pmain(pc),a0
	sub.l	a1,a1
	jsr	(resload_Patch,a2)
	
	; and start

	move.w	#$2700,SR
	moveq.l	#0,D2

	lea	$4E8.W,a0	; sets copperlist in advance
	move.l	a0,$dff080	; avoids snoop problem


	jmp	$410.W

mainname:
	dc.b	"main",0
	even

DiskRoutine:
	MOVEM.L	D2-D7/A0-A6,-(A7)

	cmp.b	#5,D1
	beq	.dr_DirRead
	cmp.b	#0,D1
	beq	.dr_FileRead

	cmp.b	#1,D1
	beq	.dr_FileWrite

	moveq.l	#0,D0
	dc.w	$FF01


.dr_FileRead:
	move.l	use_original_exe(pc),d0
	bne.b	.orig
	; reworked version: change load address from $8000 to required
	cmp.l	#$8000,a1
	bne.b	.orig

	; main "object" code, relocated version
	; load it directly at the proper location
	lea		object_name(pc),a0
	move.l	progstart(pc),a1
	

.orig

	move.l	_resload(pc),a2
	jsr	(resload_LoadFile,a2)		

	move.l	D0,D1
	moveq.l	#0,D0
	bra	.dr_End

; *** read directory

.dr_DirRead:
	moveq.l	#0,D1
	moveq.l	#0,D0	

.dr_End:
	MOVEM.L	(A7)+,D2-D7/A0-A6
	RTS

; *** other commands, not supported, and unlikely to be called

.dr_Other:
	cmp.w	#1,D1
	beq	.dr_FileWrite

	dc.w	$FF02

; *** write file (only score)
; D0 holds the length to write but we ignore it
; because we write only the scores

.dr_FileWrite:
	dc.w	$FF03

	; *** if something else than the scorefile is written, ignore it

;	move.l	A0,D1
;	GETUSRADDR	scorename
;	JSRGEN	StrcmpAsm
;	tst.l	D0
;	bne	.notscore

;;	bsr	WSOnExit	; write scores
.nowrite
	moveq.l	#0,D0
	move.l	#$C8,D1
	bra	.dr_End

.notscore
	dc.w	$FF04
	moveq.l	#-1,D0
	moveq.l	#0,D1
	bra	.dr_End

Jump7000:
	movem.l	D0/D1/A0-A2,-(A7)
	movem.l	_resload(pc),A2
	sub.l	a1,a1
	lea	_pintro(pc),A0
	jsr	(resload_Patch,A2)
	movem.l	(A7)+,D0/D1/A0-A2

    or.w #$0700,sr
    lea.l $00007000,a0
    adda.l #$0005644c,a0
    lea.l $0005d44c,a1
.copy
    move.l -(a0),-(a1)
    cmpa.l #$00007000,a1
    bge.b .copy
	bsr	_flushcache
	; jump to intro
	jmp	$8000
	
Jump8000:
	
	movem.l	D0/D1/A0-A2,-(A7)

	clr.w	$9B4.W
	move.l	enable_high_details(pc),d0
	beq.b	.low
	move.w	#$4,$9B4.W	; 020 cpu 
.low

	move.l	use_original_exe(pc),d0
	bne	.official
 
	cmp.w	#$4,$9B4.W	; 020 cpu 
	bne.b	.no020
	move.w	#$8,$9B4.W	; 020+ cpu exclusive setting
	
.no020
	
	IFD	CHIP_ONLY
	; put crap in the original zone
	; just in case the game jumps here
	; (if winuae memory protection isn't active
	; or a custom chip accesses there)
	lea		$8000,a0
	lea		$520ca,a1
	move.w	#$CCCC,d0
.copy
	move.w	d0,(a0)+
	cmp.l	a0,a1
	bne.b	.copy
	
	move.l	#$520ca-$8000,d0                   ;one longword
	lea     $8000,a0                ;address
	move.l  (_resload,pc),a2
	jsr     (resload_ProtectRead,a2)
	move.l	#$520ca-$8000,d0                   ;one longword
	lea     $8000,a0                ;address
	move.l  (_resload,pc),a2
	jsr     (resload_ProtectWrite,a2)
	ENDC
	
	lea		progbase(pc),a0
	move.l	progstart(pc),(a0)
	
	move.l	_expmem(pc),a7
	add.l	#FASTSIZE,a7
	
	move.l  progstart(pc),a0
    bsr   _Relocate	

	move.l	_resload(pc),a0
	move.b	_keyexit(pc),d0
	move.l	progstart(pc),-(a7)
	rts
	
.official

	pea	_emu_bra(pc)
	move.l	(a7)+,$B4.W
	pea	_emu_jsr(pc)
	move.l	(a7)+,$B8.W
	pea	_emu_jmp(pc)
	move.l	(a7)+,$BC.W

	movem.l	_resload(pc),A2
	move.l	progbase(pc),a1
	sub.l	#$8000,a1
	lea	pl_main(pc),A0
	jsr	(resload_Patch,A2)

	movem.l	(A7)+,D0/D1/A0-A2
	lea	CHIP_BASE,A7
	move.l	a7,usp		; game puts USP to A7 at some moment
	
	move.l	progbase(pc),a0
	sub.l	#$8000,a0
	add.l	#$229D8,a0


	jmp	(a0)


smctable_1
	dc.l	$B91C,$A32A,$A264,$A28A,$A22C,0 ; + $A1E4
smctable_2
	dc.l	$91A8,$91CC,$932C,0
smctable_3
	dc.l	$B20C,0
smctable_4
	dc.l	$B24E,0


_Relocate	movem.l	d0-d1/a0-a2,-(sp)
        clr.l   -(a7)                   ;TAG_DONE
;        pea     -1                      ;true
;        pea     WHDLTAG_LOADSEG
		IFND		CHIP_ONLY
        move.l  chipstart(pc),-(a7)       ;chip area
        pea     WHDLTAG_CHIPPTR        
        pea     8                       ;8 byte alignment
        pea     WHDLTAG_ALIGN
		ENDC
        move.l  a7,a1                   ;tags		
		move.l	_resload(pc),a2
		jsr	resload_Relocate(a2)
		IFND		CHIP_ONLY
        add.w   #5*4,a7
		ELSE
		addq.w	#4,a7
		ENDC
		
        movem.l	(sp)+,d0-d1/a0-a2
		rts    

FixIntroAF:
	cmp.l	#$80000,A1
	beq.b	.skip		; avoid access fault
.copy
	move.b	(A0)+,(A1)+
	dbf	D0,.copy
.skip
	rts
	; ATM 80000 and C00000 are poked in object.s:@3d076
progstart
    dc.l    $100000
progbase
	dc.l	$8000
chipstart
	IFD		CHIP_ONLY
	dc.l	$C0000		; 750kb
	ELSE
	dc.l	$8000
	ENDC
_resload:
	dc.l	0

_pmain:
    PL_START
    PL_P	$4DA,Jump7000		; jumper
    PL_P	$736,DiskRoutine
    PL_END

_pintro:	PL_START
		PL_P	$5805A,DiskRoutine
		PL_P	$5804C,Jump8000
		PL_PS	$86FE,FixIntroAF
		PL_IFC4X    0
		PL_NOP	$8054,4
		PL_ENDIF
        
		PL_END

PL_P_RELOC:MACRO
    PL_P    $\1,jump_\1
    ENDM

PATCH_DBF:MACRO
    PL_W    $\2,\1+$4E40
    ENDM
    

_tag		
		dc.l	WHDLTAG_CUSTOM2_GET
use_original_exe	dc.l	0
	dc.l	WHDLTAG_CUSTOM3_GET
enable_high_details	dc.l	0
		dc.l	0
    
pl_main:	PL_START
	; vbl count 5 => 1???
		;;PL_W	$22d32,1
		; skip loop
		; PL_S	$22d28,$3A-$28
		
		; trainer
		PL_IFC1X	0
		PL_NOP	$41696,8
		PL_NOP	$45034,6
		PL_NOP	$4509a,6
		PL_NOP	$452ae,8
		PL_NOP	$45b4e,6
		PL_NOP	$49aa0,6
		PL_ENDIF
		
		; skip expansion memory test that is broken anyway
		PL_S	$3D076,$12a-$76
		
		PL_I	$229b4	; just in case someone jumps in the ORI zone just before
		
		PL_PS	$22C2E,kb_interrupt	; quit key with NOVBRMOVE
		PL_L	$23468,$31C7099C	; skip country check (NTSC version)
		PL_S	$229BC,$229CC-$229BC	; skip CACR stuff
		PL_S	$22A8E,$22AAE-$22A8E	; skip floppy stuff
		PL_P	$514D2,DiskRoutine	; disk load

        ; skip dummy trap handlers
        PL_S    $22aae,$c2-$ae
		; SMC

		;;PL_W	$09200,$4E4D		; BRA, Duff's device to draw stuff
		;;PL_W	$094FA,$4E4D		; BRA
		;;PL_W	$09766,$4E4D		; BRA

		PL_W	$0BB22,$4E4E		; JSR
		PL_W	$3D2B2,$4E4E		; JSR
		PL_W	$3D2DC,$4E4E		; JSR
		PL_W	$3D306,$4E4E		; JSR
		PL_W	$3D330,$4E4E		; JSR

		PL_W	$0ED3E,$4E4F		; JMP
		PL_W	$3D342,$4E4F		; JMP
		PL_W	$3D348,$4E4F		; JMP
		PL_W	$3D34E,$4E4F		; JMP
		PL_W	$3D354,$4E4F		; JMP

		; intercept indirect jumps
		;PL_P	$D452,jmp_a0_1
		;PL_P	$DA06,jmp_a6_1
		;PL_P	$DA42,jmp_a6_1
		;PL_P	$D1F0,jsr_loop_1
		;PL_PS	$3D384,jsr_2

		PL_PS	$4FB0E,FixJsrBug

		IFD	FIX_was_SMC
		;PL_PS	$B28A,set_dynamic_code_1    ; TODO cache flush!!!
		;PL_PS	$B486,set_dynamic_code_2    ; TODO cache flush!!!
		;PL_PS	$B6BC,set_dynamic_code_3    ; TODO cache flush!!!
		;PL_P	$B6BC+6,set_dynamic_code_4    ; TODO cache flush!!!
		ENDC

;;		IFD	DEBUG
		; move sr -> move ccr (protectSMC likes that better)
	;	PL_W	$CE9E,$42E7
	;	PL_W	$CEA2,$44DF
;;		ENDC
		PL_IFC4X    1
		PL_W	$238ce,$6014
        PL_L    $238D6,1
		PL_ENDIF

        PL_IFC4X    2
        PL_L    $238D6,1
        PL_ENDIF
        
        ;;PL_I    $22ed6      ; blitter interrupt... game doesn't use it!
        ; fastmem relocs

		PL_END


    
jsr_2:
	MOVEA.L	0(A0,D0),A0		;3D384: 20700000
	JMP	(A0)			;3D388: 4E90

jsr_loop_1
.loop
	MOVEA.L	(A6)+,A0		;0D1F0: 205E
	CMPA.L	#$FFFFFFFF,A0		;0D1F2: B1FCFFFFFFFF
	BEQ.S	.out

    
	JSR	(A0)			;0D1FA: 4E90
	bra	.loop
.out
	rts

jmp_a6_1
	ADDA	D5,A6			;0DA06: DCC5
	JMP	(A6)			;0DA08: 4ED6
	RTS				;0DA0A: 4E75

jmp_a0_1:

	MOVE.L	(A6)+,D7		;0D452: 2E1E
	MOVEA.L	D7,A0			;0D454: 2047
	; correct address else it bounces back to chip code

	JMP	(A0)			;0D456: 4ED0

    


    
; corrects SMC $4EF9(address changing all the time)
; emulate JMP from trap. rather easy

_emu_jmp:

	move.l	A0,-(A7)
	move.l	6(A7),A0	; return address

	move.l	(a0),a0

	move.l	A0,6(A7)	; RTE -> JMP address
	move.l	(A7)+,A0
	rte

; corrects SMC BRA (relative address changing all the time)
; emulate BRA from trap. rather easy

_emu_bra:
	movem.l	D0/A0,-(A7)
	move.l	10(A7),A0	; return address
	move.w	(a0),d0
	ext.l	d0
	add.l	d0,10(A7)	; RTE -> BRA address
	movem.l	(A7)+,D0/A0
	rte

; corrects SMC $4BF9(address changing all the time)
; emulate JSR from trap. Tricky!

_emu_jsr:

	move.l	a0,-(a7)
	lea	.jsr_address(pc),a0
	move.l	6(a7),(a0)
	move.l	(a7)+,a0

	pea	.afterrte(pc)
	move.l	(A7),6(A7)	; modify RTE return address
	addq.l	#4,a7
	rte
.afterrte:
	move.l	.jsr_address(pc),-(a7)
	addq.l	#4,(a7)

	subq.l	#4,a7
	move.l	a0,-(a7)
	move.l	.jsr_address(pc),a0
    
    IFND    RELOCATE_TO_XXX
    ; sanity
    cmp.l   #CHIPMEMSIZE,a0
    bcs.b   .ok
   
    nop
    nop
    illegal
.ok
    ENDC
	; self-modifying code wrote the address in the unrelocated code
	; (we chose to relocate only JSR/JMP except for move #imm, where imm
	; is an interrupt vector
	; if we choose the other way (relocate all, more problems occur, likes
	; bad memory type and worse)
	
	move.l	(a0),a0     ; get contents of this jsr address
	
	move.l	a0,4(a7)
	move.l	(a7)+,a0
	rts

.jsr_address:
	dc.l	0

FixJsrBug:
	cmp.w	#$40,D0
	beq.b	.nojsr		; avoid access fault
	move.l	(A0,D0.W),A0
    IFND    RELOCATE_TO_XXX
    ; sanity
    cmp.l   #CHIPMEMSIZE,a0
    bcs.b   .ok

    nop
    nop
    illegal
    illegal
    illegal
.ok
    ENDC
	jmp	(A0)
.nojsr

    nop
    nop
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

