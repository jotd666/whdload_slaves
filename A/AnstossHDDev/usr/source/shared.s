; this is a part of the loading code, leave in first position!!

		move.l	active_program(pc),a0
		lea	args(pc),a1
		move.l	#args_end-args,d0
		sub.l	a5,a5
		bsr	_load_exe

		lea	editor_called(pc),a0
		tst.b	(a0)
		beq.b	.quit

		; we just quit the editor: reboot

		clr.b	(a0)
		move.l	$4.W,a6
		lea	.svmode(pc),a5
		jsr	_LVOSupervisor(a6)
		ILLEGAL
.svmode
		ori	#$700,SR
		bra	kick_reboot

.quit
		pea	TDREASON_OK
		move.l	_resload(pc),-(a7)
		addq.l	#resload_Abort,(a7)
		rts
        
;============================================================================

; < D0: BSTR filename
; < D1: seglist

_cb_dosLoadSeg
	add.l	D1,D1		
	add.l	D1,D1	

	lsl.l	#2,d0		;-> APTR
	move.l	d0,a0
	moveq	#0,d0
	move.b	(a0)+,d0	;D0 = name length
	;remove leading path
	move.l	a0,a1
	move.l	d0,d2
.2	move.b	(a1)+,d3
	subq.l	#1,d2
	cmp.b	#":",d3
	beq	.1
	cmp.b	#"/",d3
	beq	.1
	tst.l	d2
	bne	.2
	bra	.3
.1	move.l	a1,a0		;A0 = name
	move.l	d2,d0		;D0 = name length
	bra	.2
.3

	move.l	d1,a1
	addq.l	#4,a1	; first segment

	bsr	get_string_word

	cmp.l	#'atar',d2
	bne.b	.4
	cmp.b	#$D,d0
	bne.b	.4

	; atari.library: remove the protection

    cmp.w   #$204d,($702,a1)
    bne.b   .v2
	add.l	#$702,a1
    bra.b   .crk
.v2
    cmp.w   #$204d,($6fe,a1)
    bne.b   .4
	add.l	#$6fe,a1
 
.crk

	move.w	#$4EB9,(a1)+
	pea	crack_it(pc)
	move.l	(a7)+,(a1)
	bra.b	.out
.4
	cmp.l	#'lade',d2
	bne.b	.5
	cmp.b	#$10,d0
	bne.b	.5

	; ladenlib.library

	bra.b	.out
.5
	cmp.l	#'edit',d2
	bne.b	.6
	lea	editor_called(pc),a0
	st.b	(a0)
.6
.out
	rts

; < A0
; > D2
get_string_word
	movem.l	a0/d3,-(a7)
	moveq.l	#3,d3
.gwloop
	lsl.l	#8,d2
	move.b	(a0)+,d2
	cmp.b	#'Z'+1,d2
	bcc.b	.nouc
	cmp.b	#'A',d2
	bcs.b	.nouc
	add.b	#'a'-'A',d2
.nouc
	dbf	d3,.gwloop
	movem.l	(a7)+,a0/d3
	rts

crack_it	
	movem.l	D0/A1,-(a7)
	move.b	-1(a5),d0
	cmp.b	#'A',d0
	bcs.b	.out
	cmp.b	#'z'+1,d0
	bcc.b	.out

	; likely to be a letter

	cmp.b	29(a5),d0
	bne.b	.out

	move.l	a5,a0
	lea	30(A5),a1

	; copy the answer into the question buffer!

.cp
	move.b	(a1)+,(a0)+
	bne.b	.cp

.out
	movem.l	(a7)+,d0/A1

	; stolen

	move.l	a5,a0
.loop
	tst.b	(a0)+
	bne.B	.loop
	
	rts
    

editor_called
		dc.w	0

new_Open
	cmp.l	#MODE_NEWFILE,d2
	bne.b	.out

	; what is the assign
	move.l	d1,a0	; filename
	cmp.b	#'n',(a0)+
	bne.b	.nonil
	cmp.b	#'i',(a0)+
	bne.b	.nonil
	cmp.b	#'l',(a0)+
	bne.b	.nonil
	cmp.b	#':',(a0)+
	bne.b	.nonil

	bra.b	.out	; open "nil" device
.nonil

	move.l	d1,a0	; filename
	move.l	D0,-(a7)
.raloop
	move.b	(a0)+,d0
	beq.b	.ex
	cmp.b	#':',d0
	bne.b	.nocolon
	move.l	a0,a1	; store simplified name in A1
.nocolon
	bra.b	.raloop
.ex
	move.l	(a7)+,d0

	; A0 points to the end of the name
	subq.l	#5,a0

	cmp.b	#'.',(a0)+
	bne.b	.noans
	cmp.b	#'a',(a0)+
	bne.b	.noans
	cmp.b	#'n',(a0)+
	bne.b	.noans
	cmp.b	#'s',(a0)+
	bne.b	.noans

	; A1: savename.ans
	; create the file in advance so write to file
	; will be much faster and without os swaps

	movem.l	d0-d1/a0-a2,-(a7)

	lea	savebuf+5(pc),a0
.copy
	move.b	(a1)+,(a0)+
	bne.b	.copy

	lea	savebuf(pc),a0	; name

	move.l  #1,d0                 ;size
	move.l  #180000,d1               ;offset (max save size)
	lea     savebuf(pc),a1          ;source
	move.l  (_resload,pc),a2
	jsr     (resload_SaveFileOffset,a2)

	movem.l	(a7)+,d0-d1/a0-a2

.noans
.out
	move.l	old_Open(pc),-(a7)
	rts

savebuf:
	dc.b	"save/"

	ds.b	30,0
	even


check_vonplatte:
		lea	savedir(pc),a0
		move.l	a0,d1
		move.l	#ACCESS_READ,d2
		jsr	_LVOLock(a6)
		move.l	d0,d1
		bne	.okdir

		pea	savedir(pc)
		pea	205			; directory not found
		pea	TDREASON_DOSREAD
		move.l	(_resload,pc),-(a7)
		add.l	#resload_Abort,(a7)
		rts

.okdir
		jsr	_LVOUnLock(a6)

		; check if file "vonplatte" exists (HD flag)

		lea	.vonplatte_name(pc),a0
		move.l	a0,d1
		move.l	#ACCESS_READ,d2
		jsr	_LVOLock(a6)
		move.l	d0,d1
		bne	.ok

		; create the file if not exists

		lea	.vonplatte_name(pc),a0
		move.l	a0,d1
		move.l	#MODE_NEWFILE,d2
		jsr	_LVOOpen(a6)		
		move.l	d0,d1
		bne.b	.close
		ILLEGAL			; problem!!!
.close
		jsr	_LVOClose(a6)
		bra.b	.cont
.ok
		jsr	_LVOUnLock(a6)
.cont
		rts

.vonplatte_name
	dc.b	"vonplatte",0
	even

; < a0: program name
; < a1: arguments
; < d0: argument string length
; < a5: patch routine (0 if no patch routine)

_load_exe:
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
	add.l	d7,d7
	add.l	d7,d7
	jsr	(a5)
	bsr	_flushcache
	movem.l	(a7)+,d2/d7/a4
.skip
	;call
	move.l	d7,a1
	add.l	a1,a1
	add.l	a1,a1

	move.l	a4,a0
	move.l	($44,a7),d0		;stacksize
	sub.l	#5*4,d0			;required for MANX stack check
	movem.l	d0/d7/a2/a6,-(a7)
	move.l	d2,d0			; argument string length
	jsr	(4,a1)
	movem.l	(a7)+,d1/d7/a2/a6

	;remove exe
	move.l	d7,d1
	jsr	(_LVOUnLoadSeg,a6)

	movem.l	(a7)+,d0-a6
	rts

.end
	move.l	a3,-(a7)
	pea	205			; file not found
	pea	TDREASON_DOSREAD
	move.l	(_resload,pc),-(a7)
	add.l	#resload_Abort,(a7)
	rts

_tag		dc.l	WHDLTAG_CUSTOM1_GET
_skip_intro	dc.l	0
		dc.l	WHDLTAG_CUSTOM2_GET
_original_keyboard	dc.l	0
		dc.l	0

install_kbint:
    move.l	_original_keyboard(pc),d0
    bne.b   .done
    lea    old_kbint(pc),a1
    lea kbint_hook(pc),a0
    cmp.l   (a1),a0
    beq.b   .done
    move.l  $68.W,(a1)
    move.l  a0,$68.W
.done
    rts
    
kbint_hook:
    movem.l  a0-a1/d0-d3,-(a7)
    move.b  $BFEC01,d0
    ror.b   #1,d0
    not.b   d0
    moveq.l #0,d1
    bclr    #7,d0
    sne     d1
    lea kb_table(pc),a0
    move.l  _keyboard_type(pc),d2
    add.l   d2,d2
    move.w  (a0,d2.w),a1
    add.w   a1,a0
    
.loop
    move.b  (a0)+,d2
    bmi.b   .noswap
    move.b  (a0)+,d3
    cmp.b   d0,d2
    bne.b   .loop
    move.b  d3,d0

.pack
    tst.b   d1
    beq.b   .norel
    bset    #7,d0   ; key released
.norel
    not.b   d0
    rol.b   #1,d0
    move.b  d0,$BFEC01    
.noswap
    movem.l  (a7)+,a0-a1/d0-d3
    
    move.l  old_kbint(pc),-(a7)
    rts

    
old_kbint:
    dc.l    0

kb_table:
    dc.w    us-kb_table,french-kb_table,deutsch-kb_table

us:
    dc.b    -1
french:
    dc.b    $10,$20   ; a <-> q
    dc.b    $20,$10   ; a <-> q
    dc.b    $11,$31   ; w <-> z
    dc.b    $31,$11   ; w <-> z
    dc.b    $29,$37   ; m <-> ,
    dc.b    $37,$38   ; m <-> ,
    dc.b    -1    
deutsch:
    dc.b    $15,$31   ; y -> z
    dc.b    $31,$15   ; z -> y
    dc.b    -1    

gb_program:
    dc.b    "otb",0
d_program:
	dc.b	"ANSTOSS",0
f_program:
	dc.b	"c-r",0
    
    even
    
active_keymap
	dc.l	0
active_program
	dc.l	0
_keyboard_type
    dc.l    0
;============================================================================
