	INCDIR	"Include:"
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	IFD	BARFLY
	OUTPUT	Wonderdog.cdslave
	BOPT	O+				;enable optimizing
	BOPT	OG+				;enable optimizing
	BOPT	ODd-				;disable mul optimizing
	BOPT	ODe-				;disable mul optimizing
	BOPT	w4-				;disable 64k warnings
	BOPT	wo-			;disable optimizer warnings
	SUPER
	ENDC
CD_SLAVE_HEADER	MACRO
		moveq	#-1,d0
		rts
		dc.b	"CD32LOAD"
		ENDM

_base		CD_SLAVE_HEADER			;ws_Security + ws_ID
	; we don't need/can't really use expmem info, because depending on
	; slave build options, we can have expmem at 0 and chipmem at $100000
	; or expmem at $80000 and chipmem at $0 but in the end CD32load sets
	; expmem to $80000 most of the time so why bother?? (or we can get that
	; from a game address register, e.g. no issue to "repatch" a patchlist since
	; we are called with the original arguments
	;
	; and the other data from slave header aren't very useful either
	;
	; what we need:
	; init routine (optional)
	; hook for each hookable call (optional)
_resload
	dc.l	0	; cd32load writes (unhooked!) resident loader address here
_cdplay
	dc.l	0	; cd32load writes the address of the play routine here
_cdstop
	dc.l	0	; cd32load writes the address of the stop routine here
_cdstatus
	dc.l	0	; cd32load writes the address of the stop routine here
	; now the hooks
	dc.w	0   ;init-_base	; init: called just BEFORE the main slave init
	dc.w	0	; Decrunch: called after a call to resload_Decrunch
	dc.w	0	; DiskLoad: same thing for all below calls
	dc.w	0	; LoadFile
	dc.w	0	; LoadFileDecrunch
	dc.w	0	; LoadFileOffset
	dc.w	Patch-_base	; Patch
	dc.w	0	; PatchSeg
	dc.w	0	; Relocate
	
init:
.wb
	btst	#6,$bfe001
	beq.b	.wb
.loop
	move.w	#$0F0,$DFF180
	btst	#6,$bfe001
	bne.b	.loop
	rts
	
Patch:

	lea	patch_counter(pc),a2
	tst.l	(a2)
	beq.b	.skip	; intro patch: forget it
	; second time, the main patchlist is called
	lea	_expmem(pc),a2
	; store expansion memory from the game point of view
	; (depending on the DEBUG flags, there could be NO expmem
	; and big chipmem). The value is probably $80000 in a1
	move.l	a1,(a2)
	; we're going to force SFX and add cd player calls
	lea	pl_main(pc),a0
	move.l	_resload(pc),a2
	jsr	(resload_Patch,a2)
.skip
	move.l	#1,(a2)
	rts

patch_counter
	dc.l	0
	
pl_main
	PL_START
	PL_B	$840C,$60	; no more MUSIC/SFX switch
	PL_W	$8D7E,1		; SFX by default
	PL_PS	$14050,before_load_music	; store sector for music file
	PL_END	
before_load_music
	movem.l	D0/D1/D2/A0/A1,-(a7)
	move.w	(a4),d0
	lea	current_music_track(pc),a1
	clr.w	(a1)
	
	lea	music_table(pc),a0
	moveq	#1,d2
.loop
	move.w	(a0)+,d1
	beq.b	.end
	addq	#1,d2
	cmp.w	d0,d1
	bne.b	.loop
	; found the track index
	move.w	d2,(a1)
.wb
	btst	#6,$bfe001
	beq.b	.wb

	moveq.l	#2,d0
	moveq.l	#0,d1
	move.l	_cdplay(pc),a1
	jsr	(a1)
.end
	; this is annoying: we have to fix expmem to $80000
	; or the slave won't work with DEBUG set in master slave
	; but we can store that from the master patchlist hook
	; that's what we did
	move.l	_expmem(pc),a0
	add.l	#$8D7E,(a0)		; sfx/music flag
	tst.w	(a0)		; stolen
	movem.l	(a7)+,D0/D1/D2/A0/A1
	rts
	



_expmem	dc.l	0


current_music_track
	dc.w	0
music_table:
	dc.w	$1DB  ; 1. bunny_hop_meadow.np3
	dc.w	$3A5  ; 2. dogville.np3 c78e: 3A5
	dc.w	$99	   ; 3. scrap_yard.np3 a0de: 99
	dc.w	$180	; 4. loony_moon.np3 d0b8: 180
	dc.w	$24F	; 5. planet_weird.np3 dc7a: 24F
	dc.w	$31E	; 6. planet_k_9.np3 def6: sector 31E
	dc.w	$44A	; boss.np3 b038: 44A
	dc.w	0
	



	