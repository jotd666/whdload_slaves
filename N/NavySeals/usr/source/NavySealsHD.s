	INCDIR	"Include:"
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i

DECL_VERSION:MACRO
	dc.b	"2.1"
	IFD BARFLY
		dc.b	" "
		INCBIN	"T:date"
	ENDC
	IFD	DATETIME
		dc.b	" "
		incbin	datetime
	ENDC
	ENDM    
    
_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
_config

    dc.b    "C1:X:infinite credits:0;"
    dc.b    "C1:X:infinite lives:1;"
    dc.b    "C1:X:infinite Energy:2;"
    dc.b    "C1:X:infinite time:3;"
    dc.b    "C1:X:help levelskips:4;"
	dc.b	0
        even
_name		dc.b	"Navy Seals",0
_copy		dc.b	"1990 Ocean",0
_info		dc.b	"adapted by Bored Seal & JOTD",10
        DECL_VERSION
		dc.b    0
		even

_Start		lea	(_resload,pc),a1
		move.l	a0,(a1)			;save for later using
		move.l	a0,a2
                lea     (_tags,pc),a0
                jsr     (resload_Control,a2)

		move.l	#$54c,d1		;load executable
		moveq	#$6c,d2
		lea	$800,a0
		bsr	LoadRNCTracks

		move.l	a0,a5
		mulu.w	#$200,d2
		move.l	d2,d0
		jsr     (resload_CRC16,a2)
		cmp.w	#$a796,d0
		bne	Unsupported

		suba.l	a0,a0			;snoop mode bug
		move.l	#$fffffffe,(a0)
		move.l	a0,$dff080
        
        sub.l   a1,a1
        lea pl_main(pc),a0
        jsr (resload_Patch,a2)
        bsr	LoadHi
		jmp	(a5)

pl_main
        PL_START
		PL_P	$c16,LoadRNCTracks

		PL_W	$822,$6008		;skip fault blitter operation
					
		;blit fix
		PL_P    $100,BlitWait
		PL_L	$344a,$4eb80100

		PL_R  $ae8a		;remove RNC protection
		PL_R  $88a		;cacr operation

        PL_PSS  $4954,FixFault,2  ;fix 24bit access fault
        PL_PS   $515A,BeamDelay


		PL_W	$08ca,$6f
		PL_W	$6670,$6f
		PL_W	$6818,$6f

        PL_IFC1
        PL_ELSE
        ; only save scores if no cheat
        PL_PSS  $6a72,SaveHi,2
        PL_ENDIF
        
        ; delay loop is just too fast
        PL_PSS    $00006E86,credits_delay,2
        
		PL_IFC1X    0
		PL_W	$6ece,$4a79		;unlimited credits
        PL_ENDIF
        PL_IFC1X    1
		PL_CW	$281e			;unlimited lives
        PL_ENDIF
        PL_IFC1X    2
		PL_CW	$1de2			;energy
		PL_W	$21f4,$4a79
		PL_W	$1bd6,$603e
        PL_ENDIF
        PL_IFC1X    3
        PL_PS  $23C4,sub_time        ; time
        PL_ENDIF
        PL_END
 
sub_time
    cmp.l   #$17B0,(4,a7) ; skip sub only from normal game, not from level end
    beq.b   .skip
    dc.l    $023c0fef   ; AND #$0fef,CCR
    SBCD.B D1,D0
.skip
    rts
    
; $ACCC minutes:seconds in BCD
credits_delay:
    ; add a delay because loop is too fast
    ; (meets the same beam value when looping so the
    ; continue timer is too fast)
.wait:
	MOVE.W	$DFF006,D0		;6942: 302e0006
	ANDI.W	#$ff00,D0		;6946: 0240ff00
	CMPI.W	#$fc00,D0		;694a: 0c40fb00
	BNE.S	.wait
        
    ; original
     jsr $00006942.W
     jmp $00006e96.W
     
BlitWait	btst	#6,$dff002
		bne	BlitWait
		move.w	d5,$58(a6)
		rts

FixFault	move.l	a1,-(sp)
		add.l	a1,d1
		and.l	#$0000FFFF,d1
		move.l	d1,a1
		move.b	(a1),d1
		move.l	(sp)+,a1
		andi.b	#2,d1
		rts

LoadRNCTracks	movem.l a0-a2/d0-d3,-(sp)
		mulu.w	#$200,d1
		mulu.w	#$200,d2
		move.l	d1,d0
		move.l	d2,d1
		moveq	#1,d2
		move.l	(_resload,pc),a2
		jsr	(resload_DiskLoad,a2)
		movem.l (sp)+,a0-a2/d0-d3
		clr.l	d0
		rts


        
BeamDelay
        movem.l d0,-(a7)
        move.l  trainer(pc),d0
        btst    #4,d0
        movem.l (a7)+,d0
        beq.b   .noskip
        cmp.b   #$5F,d0
        bne.b   .noskip
        clr.w   $ACD8   ; no more bombs to defuse: level skip!
.noskip
        cmp.b   _keyexit(pc),d0
        bne.b   .noquit
        
        pea	TDREASON_OK
        move.l	_resload(pc),-(a7)
        addq.l	#resload_Abort,(a7)
        rts
.noquit        
        moveq	#1,d0
BM_1	move.w  d0,-(sp)
		move.b	$dff006,d0	; VPOS
BM_2		cmp.b	$dff006,d0
		beq	BM_2
		move.w	(sp)+,d0
		dbf	d0,BM_1
		rts

LoadHi		movem.l	d0-d7/a0-a6,-(sp)
		bsr	Params
                jsr     (resload_GetFileSize,a2)
                tst.l   d0
                beq     NoHisc
		bsr	Params
		jsr	(resload_LoadFile,a2)
NoHisc		movem.l	(sp)+,d0-d7/a0-a6
		rts

Params		lea	hiscore(pc),a0
		lea	$6d36,a1
		move.l	(_resload,pc),a2
		rts

SaveHi		jsr	$6ada
		move.w	#$77,d7

		movem.l	d0-d7/a0-a6,-(sp)
		bsr	Params
		moveq	#$2e,d0
		jsr	(resload_SaveFile,a2)

		movem.l	(sp)+,d0-d7/a0-a6
		rts

Unsupported	pea	TDREASON_WRONGVER
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

_resload	dc.l	0
_tags		dc.l	WHDLTAG_CUSTOM1_GET
trainer		dc.l    0,0
hiscore		dc.b	"NavySeals.High",0