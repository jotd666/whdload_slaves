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
	OUTPUT	"BombX.slave"
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

	IFD BARFLY
	DOSCMD	"WDate  >T:date"
	ENDC

MEMBASE = $1000

    IFD CHIP_ONLY
CHIPMEM = $100000
EXPMEM = 0
    ELSE
CHIPMEM = $80000
EXPMEM = $40000
    ENDC
    
;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem 		;ws_flags
		dc.l	CHIPMEM			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	_current_dir-_base		;ws_CurrentDir
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
		

DECL_VERSION:MACRO
	dc.b	"1.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM

    
_name		dc.b	"Bomb'X"
	IFD	CHIP_ONLY
	dc.b	" (DEBUG/CHIP MODE)"
	ENDC
			dc.b	0
_copy		dc.b	"1993 Mediagogo",0
_info		dc.b	"adapted by JOTD",10,10
		dc.b	"Version "
		DECL_VERSION
		dc.b	0
_current_dir:
	dc.b	"data",0

program:
	dc.b	"game",0
args		dc.b	10
args_end
	dc.b	0
_config
	dc.b    "C1:X:Trainer infinite lives:0;"
	dc.b    "C1:X:Trainer infinite energy:1;"
	dc.b    "C1:X:Trainer maximum power:2;"
	dc.b    "C2:B:Trivial passwords 00000 ...;"
	dc.b	0


; version xx.slave works

	dc.b	"$","VER: slave "
	DECL_VERSION
	dc.b	0
	EVEN

_start
		clr.l	$0.W
        
        lea _resload(pc),a2
        move.l  a0,(a2)

        patch   $100,dos_read
        move.w  #$FFFFFFFE,$106
        move.l  #$106,$DFF080
        ;move.w  #$A3F0,_custom+dmacon  ; same as kick value
        ;move.w  #$9100,_custom+adkcon
		move.l	_resload(pc),a2		;A2 = resload
        lea tag(pc),a0
        jsr (resload_Control,a2)
	
		lea	program(pc),a0
        IFD CHIP_ONLY
        move.l  #MEMBASE,a1
        move.l  a1,d7
        jsr (resload_LoadFile,a2)
        move.l  #MEMBASE,a0
        bsr _relocate
        lea video_memory(pc),a0
        ; empiric location of bitplane memory
        ; memory management of this game is just horrible
        add.l   #MEMBASE+$20000,d0
        move.l  d0,(a0)        
        ELSE
        move.l  _expmem(pc),a1
        move.l  a1,d7
        jsr (resload_LoadFile,a2)
        move.l  _expmem(pc),a0
        bsr _relocate
        lea video_memory(pc),a0
        move.l  #MEMBASE,(a0)        
        ENDC
        bsr patch_main
        move.l  d7,a1
        jsr (a1)
	;quit
_quit		pea	TDREASON_OK
		move.l	(_resload,pc),a2
		jmp	(resload_Abort,a2)

; < d7: seglist (APTR)

patch_main
    
    move.l  d7,a1
	lea	pl_main(pc),a0
	jsr	resload_Patch(a2)
    
    move.l  trivial_passwords(pc),d0
    beq   .sk
    move.l  d7,a1
    add.l  #$4b82,a1 ; passwords
    move.l  #49,d1
.loop  
    addq.l  #1,a1
    lea .code(pc),a0
    move.b  (a0)+,(a1)+
    move.b  (a0)+,(a1)+
    move.b  (a0)+,(a1)+
    move.b  (a0)+,(a1)+
    move.b  (a0)+,(a1)+
    addq.l  #2,a1

    
    lea .code(pc),a0
    move.b  (4,a0),d0
    add.b   #1,d0
    cmp.b   #':',d0
    bne.b   .ok
    move.b  #'0',d0
    add.b   #1,(3,a0)
.ok
    move.b  d0,(4,a0)
    dbf d1,.loop
.sk    
	rts

.code:
    dc.b    "00000"
    even

; < A0: address
; > D0: size
_relocate	movem.l	d1/a0-a2,-(sp)
        clr.l   -(a7)                   ;TAG_DONE
        move.l  a7,a1                   ;tags		
        move.l	_resload(pc),a2
		jsr	resload_Relocate(a2)
        add.w   #4,a7
        movem.l	(sp)+,d1/a0-a2
		rts
        
dos_read:
    movem.l d1/a2,-(a7)
    move.l _resload(pc),a2
    move.l  $392.W,a0
    jsr (resload_GetFileSize,a2)
    cmp.l   d0,d3
    bcs.b   .ok
    move.l  d0,d3 
.ok
    move.l  d2,a1
    moveq.l #0,d1   ; offset=0
    move.l  d3,d0   ; size

    move.l  $392.W,a0
    jsr (resload_LoadFileOffset,a2)
    movem.l (a7)+,d1/a2
    move.l  d3,d0
    rts
    
pl_main
	PL_START
    ; needs cache flush after smc (no more smc anyway)
    ; we set dma here
    PL_PSS  $0804,set_dma,2
	; crack protection code
    PL_L  $5226,$60000156
    ; dodgy memory detection needs patching for 512k chip
    ; but works because program resides in fastmem 
    ;PL_R    $071a   ; no need to detect memory or do anything
    
    PL_PSS  $174C,dma_write,2
    PL_PS   $0eda,dma_wait_1
    PL_PS   $0f16,dma_wait_2
    PL_PS   $0f52,dma_wait_4
    PL_PS   $0f8e,dma_wait_8
    
    PL_IFC1X    0
    PL_NOP  $76ee,4     ; infinite lives
    PL_ENDIF
    PL_IFC1X    1
    PL_NOP  $6c94,4
    PL_NOP  $a048,4
    PL_ENDIF
    PL_IFC1X    2
    PL_NOP  $6c5a,2     ; max power
    PL_ENDIF
    
    PL_R       $1e5e        ; CIA-B shit
    PL_NOP     $0828,6      ; read copjmp1
    PL_ORW      $082e+2,$3CF    ; enable dma like kickstart does
    ; kill os stuff
    PL_R    $0a34
    PL_NOP  $0d4c,4 ; no unlock
    PL_NOP  $1da6,4 ; no close
    PL_L  $1d8e,$70014E71 ; open 
    PL_I    $1dfe   ; write
    PL_L    $1dda,$4EB80100
    PL_R    $1d50   ; no openlib
    PL_R    $1d5e   ; no closelib
    PL_PS   $077c,get_video_memory
    PL_S    $0782,$0798-$782
    
    PL_P    $0c4a,end_int3
    PL_P    $0ea8,end_int2
    PL_NOP   $0cf0,10   ; skip lock
    PL_PS  $d08,examine
	PL_END

examine
    move.l  $392,a0
    move.l  _resload(pc),a6
    jsr resload_GetFileSize(a6)
    move.l  $386,a0
    move.l  d0,124(a0)
    tst.l   d0      ; CR tested on return
    rts
    
dma_wait_1
    move.w  #1,dmacon(a0)
    bra.b   dma_delay
dma_wait_2
    move.w  #2,dmacon(a0)
    bra.b   dma_delay
dma_wait_4
    move.w  #4,dmacon(a0)
    bra.b   dma_delay
dma_wait_8
    move.w  #8,dmacon(a0)
    bra.b   dma_delay
dma_write
    MOVE.W	20(A6),_custom+dmacon
dma_delay
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
end_int3
    MOVEM.L	(A7)+,D0-D7/A0-A6
    move.w  #$70,_custom+intreq
    rte
    
end_int2
	movem.l	D0/A5,-(a7)
	LEA	$00BFD000,A5
	MOVEQ	#$08,D0
	AND.B	$1D01(A5),D0
	BEQ	.nokey
	MOVE.B	$1C01(A5),D0
	NOT.B	D0
	ROR.B	#1,D0		; raw key code here

    cmp.b   _keyexit(pc),d0
    beq   _quit


	BSET	#$06,$1E01(A5)
	move.l	#2,d0
	bsr	beamdelay
	BCLR	#$06,$1E01(A5)	; acknowledge key

.nokey
	movem.l	(a7)+,d0/a5
	move.w	#8,$dff09c
	rte

; < D0: numbers of vertical positions to wait
beamdelay
.bd_loop1
	move.w  d0,-(a7)
    move.b	$dff006,d0	; VPOS
.bd_loop2
	cmp.b	$dff006,d0
	beq.s	.bd_loop2
	move.w	(a7)+,d0
	dbf	d0,.bd_loop1
	rts
    
get_video_memory
    move.l  video_memory(pc),d0
    rts
    


set_dma:
    ;move.w  #$83F0,_custom+dmacon
    MOVE.W	#$c038,_custom+intena
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

tag		dc.l	WHDLTAG_CUSTOM2_GET
trivial_passwords	dc.l	0
		dc.l	0
video_memory
    dc.l    0
_resload
    dc.l    0
;============================================================================

	END
