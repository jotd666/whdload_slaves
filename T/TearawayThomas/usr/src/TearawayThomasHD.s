
		INCDIR	sc:include/
		INCLUDE	whdload.i
		INCLUDE	whdmacros.i

		IFD BARFLY
		OUTPUT	"TearawayThomas.slave"
		BOPT	O+			;enable optimizing
		BOPT	OG+			;enable optimizing
		BOPT	ODd-			;disable mul optimizing
		BOPT	ODe-			;disable mul optimizing
		BOPT	w4-			;disable 64k warnings
		BOPT	wo-			;disable warnings
		SUPER				;disable supervisor warnings
		ENDC

; hiscores at 750
;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	17			;ws_Version
		dc.w	WHDLF_NoError|WHDLF_ClearMem		;ws_flags
		dc.l	$80000			;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_Start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$5d			;ws_keyexit = F10
_expmem		dc.l	0			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info
		dc.w	0                       ;ws_kickname
		dc.l	0                       ;ws_kicksize
		dc.w	0                       ;ws_kickcrc
		dc.w	_config-_base		;ws_config
_config
   dc.b    "C1:X:Trainer Infinite Time:0;"
   dc.b    "C1:X:Trainer Infinite Lives:1;"
   dc.b    "C1:X:Trainer Invincibility:2;"
   dc.b    "C1:X:Up and down to change level:3;"
 
   ; dc.b    "C3:L:Start with lives:2,3,4,5,6,7;"			
    dc.b	0
;============================================================================
	IFD BARFLY
	IFND	.passchk
	DOSCMD	"WDate  >T:date"
.passchk
	ENDC
	ENDC

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

_name		dc.b	"Tearaway Thomas",0
_copy		dc.b	"1992 Head-On Technology Ltd",0
_info		dc.b	"Installed by Codetapper/Action! & JOTD",10
		dc.b	"Version "
		DECL_VERSION
		dc.b	-1,"Thanks to Galahad/Fairlight for bypassing the",10
		dc.b	"encryption and cracking the game! Great work!",10
		dc.b	"Thanks also to Carlo Pirri for the original!",0
_Diskname	dc.b	"Disk.1",0
_Hex400		dc.b	"TTBIN0",0
_Hex75d00	dc.b	"TTBIN1",0
		EVEN

;======================================================================
_Start	;	A0 = resident loader
;======================================================================

		lea	_resload(pc),a1
		move.l	a0,(a1)			;save for later use
		
		lea	_Hex400(pc),a0
		lea	$400.w,a1
		move.l	_resload(pc),a2
		jsr	resload_LoadFileDecrunch(a2)

		lea	_Hex75d00(pc),a0
		lea	$75d00,a1
		jsr	resload_LoadFileDecrunch(a2)

		lea	_Diskname(pc),a0
		jsr	resload_GetFileSize(a2)

		cmp.l	#609092,d0
		beq	_FastVersion

		lea	$7e85a,a0		;$200 bytes/sector image
		pea	_Loader200(pc)
		bra	_StartGame

_FastVersion	lea	$7e84c,a0		;$1fc bytes/sector image
		pea	_Loader1fc(pc)

_StartGame	
		move.w	#$4ef9,(a0)+
		move.l	(sp)+,(a0)+

		lea		pl_main(pc),a0
		sub.l	a1,a1
		move.l	_resload(pc),a2
		jsr		resload_Patch(a2)
	
		jmp	$440.W			;Start game

pl_main:
	PL_START
	PL_PS	$476,_keybd		;Add quit key
	
	PL_PS	$7da8,blit_wait_1
	PL_PS	$7fD0,blit_wait_1
	PL_PSS	$8042,blit_wait_2,2
	
	PL_IFC1X	0
	PL_W	$7302,$4a39
	PL_ENDIF
	PL_IFC1X	1
	PL_B	$c726,$60
	PL_ENDIF
	PL_IFC1X	2
	PL_PS	$a9a8,ironman_thomas
	PL_ENDIF
	PL_IFC1X	3
	PL_NOP	$c830,4
	PL_ENDIF
	PL_END
	
blit_wait_1:
	LSL.W	#7,D0			;7fd0: ef48
	LEA	0(A3,D0.L),A4		;7fd2: 49f30800
	bra.b	wait_blit
	
blit_wait_2:
	LEA	0(A3,D0.L),A4		;8042: 49f30800
	LEA	512(A0),A0		;8046: 41e80200
	bra.b	wait_blit
	
ironman_thomas:
	st	d1		| Invincibility
	rts
wait_blit:
	TST.B	$BFE001
.wait
	BTST	#6,dmaconr+$DFF000
	BNE.S	.wait
	rts
	
;7c4ac = keymap replacement (add later if there is any need) so all
;keymaps will work with the game. Lowercase letters only required.

;======================================================================
;This loader is only for the disk image which has been ripped as $1fc
;bytes per sector. It means you can load the entire file in one hit!
;Much better for machines with very little memory.

_Loader1fc	movem.l	d0-d3/a0-a2,-(sp)	;d0 = size
		move.l	a0,d1			;d1 = offset
		lea	_Diskname(pc),a0	;a0 = name
		move.l  _resload(pc),a2		;a1 = address
		jsr	resload_LoadFileOffset(a2)
		movem.l	(sp)+,d0-d3/a0-a2
		rts

;======================================================================
;This is the loader for a normal disk image, if someone is too lazy to
;depack the game to disk it will still run. This should eliminate email
;from lamers saying it doesn't work with their version of the game :)
;The first chunk of code remains in the game.

_Loader200	;move.l	d0,d6			;d0 = File length
		;move.l	a0,d0			;a0 = Offset (sectors $1fc bytes not $200!)
		;divu.w	#508,d0
		;move.w	d0,d1			;d1 = Sector to load
		;swap	d0
		;move.w	d0,d3			;d3 = Bytes to skip in sector

LoadNextBlock	move.l	#$1fc,d7
		sub.w	d3,d7
		sub.l	d7,d6
		bcc.b	MoreSectorsToLoad
		add.l	d6,d7
		clr.l	d6
MoreSectorsToLoad	
		movem.l	d0-d3/a0-a2,-(sp)
		move.l  _resload(pc),a2
		movea.l	a1,a0			;a0 = dest address
		move.w	d1,d0
		mulu	#$200,d0		;d0 = offset (bytes)
		and.l	#$ffff,d3
		add.l	d3,d0
		move.l	d7,d1			;d1 = length (bytes)
		moveq	#1,d2			;d2 = disk
		jsr	resload_DiskLoad(a2)
		movem.l	(sp)+,d0-d3/a0-a2

		adda.w	d7,a1
		clr.w	d3

		addq.w	#1,d1
		tst.l	d6
		bne.b	LoadNextBlock
		rts

;======================================================================

_keybd		move.b	($bfec01).l,d0		;Stolen code

		move.l	d0,-(sp)
		not.b	d0
		ror.b	#1,d0
		cmp.b	_keyexit(pc),d0
		beq	_exit
		move.l	(sp)+,d0
		rts

;======================================================================
_resload	dc.l	0		;address of resident loader
;======================================================================

_exit		pea	TDREASON_OK
_end		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

;======================================================================

		END
