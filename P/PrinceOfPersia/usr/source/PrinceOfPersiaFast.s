;*---------------------------------------------------------------------------
;  :Contents.	A500 speed-ups for Prince of Persia, version 1 (UK and 1b).
;		See PERFORMANCE_PLAN.md (part C) and INTERNALS.md.
;		CUSTOM5 bit OPT_ORIGINAL turns them all off, for A/B comparisons.
;---------------------------------------------------------------------------*

OPT_ORIGINAL = 4

pl_fast_v1
	PL_START
	PL_IFC5X	OPT_ORIGINAL
	PL_ELSE
	; C3: tile lookup (INTERNALS.md B3)
	PL_P	$107d0,fast_get_tile_to_draw
	PL_P	$108c6,fast_load_curr_and_left_tile
	PL_P	$11b96,fast_get_room_address
	; C2(b): restore only what changed instead of the full-screen copy (INTERNALS.md B1)
	PL_P	$05686,fast_shape
	PL_P	$199e0,fast_rect_fill
	PL_P	$19894,fast_rect_copy
	PL_P	$19802,fast_clear
	PL_P	$1975c,fast_copy
	PL_P	$1bf76,fast_picture
	PL_ENDIF
	IFD	VERIFY
	PL_NEXT	pl_verify_v1
	ELSE
	PL_END
	ENDC

;---------------------------------------------------------------------------
; C3 tile lookup. Same memory writes and results as the compiled C code
; (SDLPoP names: seg008.c and seg006.c).

; get_tile_to_draw(room, column, row, *tiletype, *modifier, tile_room0), g:$107d0
fast_get_tile_to_draw
	movem.l	d2-d3,-(sp)
	movem.l	12(sp),d0-d2		; room, column, row
	move.l	32(sp),d3		; tile_room0
	bsr.b	tile_to_draw
	move.l	24(sp),a0
	move.b	d0,(a0)
	move.l	28(sp),a0
	move.b	d1,(a0)
	and.l	#$ff,d0
	movem.l	(sp)+,d2-d3
	rts

; d0 room, d1 column, d2 row, d3 tile_room0 (longs)
; > d0.b tile, d1.b modifier (upper bytes undefined); d2-d3 kept, a0 trashed
tile_to_draw
	cmp.l	#-1,d1
	bne.b	.room
	; column -1: the left room's cached column, leftroom_[row] (g:$10942)
	move.l	d2,d1
	add.l	d1,d1
	lea	$499fc,a0
	add.l	d1,a0
	move.b	(a0)+,d0
	move.b	(a0),d1
	bra.b	.plates
.room
	tst.l	d0
	beq.b	.room0
	; tilepos = g:$0718a[row] + column, into the arrays g:$11b96 chose
	move.l	d2,d0
	add.l	d0,d0
	add.l	d0,d0
	add.l	_reloc_base(pc),d0
	move.l	d0,a0
	move.l	($718a-$1000,a0),a0
	add.l	d1,a0
	move.l	$49a94,d0		; curr_room_tiles
	move.b	(a0,d0.l),d0
	and.b	#$1f,d0
	move.l	$49a98,d1		; curr_room_modif
	move.b	(a0,d1.l),d1
	bra.b	.plates
.room0
	moveq	#0,d1
	move.b	d3,d0
.plates
	cmp.b	#6,d0
	beq.b	.closer
	cmp.b	#15,d0
	bne.b	.done
	bsr.b	.timer
	ble.b	.done
	moveq	#0,d1			; a held-down opener draws as floor
	moveq	#1,d0
	rts
.closer
	bsr.b	.timer
	ble.b	.done
	moveq	#5,d0			; a held-down closer draws as stuck
.done
	rts

; > flags gt if the door-link timer of modifier d1 is above 1 (get_doorlink_timer, g:$0e514)
.timer
	move.l	d2,-(sp)
	moveq	#0,d2
	move.b	d1,d2
	move.l	$49aa0,a0
	move.b	(a0,d2.l),d2
	and.b	#$1f,d2
	cmp.b	#1,d2
	movem.l	(sp)+,d2		; keeps the flags
	rts

; load_curr_and_left_tile(), g:$108c6
fast_load_curr_and_left_tile
	movem.l	d2-d3,-(sp)
	move.l	$49a16,d2		; drawn_row
	moveq	#20,d3			; tile_room0: wall, or floor on the bottom row
	moveq	#2,d0
	cmp.l	d2,d0
	bne.b	.wall
	moveq	#1,d3
.wall
	move.l	$47b18,d0		; drawn_room
	move.l	$49a1a,d1		; drawn_col
	bsr.w	tile_to_draw
	move.b	d0,$47b60		; curr_tile
	move.b	d1,$47b62		; curr_modifier
	move.l	$47b18,d0
	move.l	$49a1a,d1
	subq.l	#1,d1
	bsr.w	tile_to_draw
	move.b	d0,$47b64		; tile_left
	move.b	d1,$47b66		; modifier_left
	move.l	$49a1a,d0
	add.l	d0,d0
	add.l	d0,d0
	add.l	_reloc_base(pc),d0
	move.l	d0,a0
	move.l	($740a-$1000,a0),$49a1e	; draw_xh = g:$0740a[drawn_col]
	movem.l	(sp)+,d2-d3
	rts

; get_room_address(room), g:$11b96
fast_get_room_address
	move.l	4(sp),d1
	move.l	d1,$47d54		; loaded_room
	beq.b	.done
	move.l	d1,d0
	subq.l	#1,d0
	add.l	d0,d0
	move.l	d0,a0
	lsl.l	#4,d0
	sub.l	a0,d0			; (room-1)*30
	lea	$470de,a0
	add.l	d0,a0
	move.l	a0,$49a94		; curr_room_tiles
	lea	$473ae,a0
	add.l	d0,a0
	move.l	a0,$49a98		; curr_room_modif
.done
	rts

;---------------------------------------------------------------------------
; C2(b) partial screen restore. Each frame g:$094e4 copies the room background, buffer 0,
; onto the hidden display buffer (40,000 bytes). This keeps, for each display buffer, the
; parts that may differ from buffer 0 and copies only those: what was drawn into the display
; buffer since its last restore, and what changed in buffer 0. Every write to the three
; buffers goes through the routines hooked here (INTERNALS.md B1, B2).
;
; A part is an 8-line band (25 per buffer) with a span of word columns: two bytes, first and
; last column, $ff00 when clean.

BUF0 = $49fee				; room background
BUF1 = $53c2e				; display buffers
BUF2 = $5d86e
BUF_SIZE = 40000
PLANE_SIZE = $1f40
BANDS = 25

fast_dirty
	dcb.w	BANDS,$0013		; buffer 1: all dirty until the first full copy
	dcb.w	BANDS,$0013		; buffer 2

; Mark lines d1-d2 and word columns d3-d4 (longs, inclusive, unclipped) as changed in the
; buffer that address d0 is in. Changes to buffer 0 dirty both display buffers.
; Trashes d0-d4, a0-a1.
fast_mark
	cmp.l	#19,d4			; past the right edge: the blit wraps onto the next line
	bgt.b	.wrap
	tst.l	d3
	bpl.b	.cols
.wrap
	moveq	#0,d3
	moveq	#19,d4
	subq.l	#1,d1
	addq.l	#1,d2
.cols
	tst.l	d1
	bpl.b	.top
	moveq	#0,d1
.top
	cmp.l	#199,d2
	ble.b	.bottom
	move.l	#199,d2
.bottom
	cmp.l	d2,d1
	bgt.b	.out
	cmp.l	d4,d3
	bgt.b	.out
	lsr.w	#3,d1			; bands
	lsr.w	#3,d2
	lea	fast_dirty(pc),a0
	sub.l	#BUF0,d0
	bcs.b	.out
	cmp.l	#BUF_SIZE,d0
	bcs.b	.both
	sub.l	#BUF_SIZE,d0
	cmp.l	#BUF_SIZE,d0
	bcs.b	.bands
	lea	BANDS*2(a0),a0
	sub.l	#BUF_SIZE,d0
	cmp.l	#BUF_SIZE,d0
	bcs.b	.bands
.out
	rts
.both
	bsr.b	.bands
	lea	BANDS*2(a0),a0
	; a0 the buffer's table; widens bands d1-d2 to columns d3-d4
.bands
	move.w	d1,d0
	add.w	d0,d0
	lea	(a0,d0.w),a1
	move.w	d2,d0
	sub.w	d1,d0
.band
	cmp.b	(a1),d3
	bcc.b	.right
	move.b	d3,(a1)
.right
	cmp.b	1(a1),d4
	bls.b	.next
	move.b	d4,1(a1)
.next
	addq.l	#2,a1
	dbf	d0,.band
	rts

; Mark the whole buffer that address d0 is in. Trashes d0-d4, a0-a1.
fast_mark_all
	moveq	#0,d1
	move.l	#199,d2
	moveq	#0,d3
	moveq	#19,d4
	bra.w	fast_mark

; g:$05686: one shape into the draw target *$674ba, as 5 or 10 plane blits. Its D area:
; lines from $67522, $6750e of them; word columns from $67524, $67520 of them, or one more
; when the shift moves left ($67526 < $67516) and the source is narrower ($67510 != $67520).
fast_shape
	movem.l	d2-d4,-(sp)
	moveq	#0,d1
	move.w	$67522,d1
	moveq	#0,d2
	move.w	$6750e,d2
	add.l	d1,d2
	subq.l	#1,d2
	moveq	#0,d3
	move.w	$67524,d3
	moveq	#0,d4
	move.w	$67520,d4
	move.w	$67526,d0
	cmp.w	$67516,d0
	bge.b	.right
	move.w	$67510,d0
	cmp.w	d0,d4
	beq.b	.right
	addq.l	#1,d4
.right
	add.l	d3,d4
	subq.l	#1,d4
	move.l	$674ba,d0
	bsr.w	fast_mark
	movem.l	(sp)+,d2-d4
	link	a6,#0
	movem.l	d2-d7/a2-a4,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$0568e-$1000,a0
	jmp	(a0)

; g:$199e0(plane, x, y, width, height, ...): rectangle fill (draw_rect)
fast_rect_fill
	movem.l	d2-d4,-(sp)
	lea	16(sp),a0
	bsr.b	fast_mark_rect
	movem.l	(sp)+,d2-d4
	link	a6,#-4
	movem.l	d2-d7,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$199e8-$1000,a0
	jmp	(a0)

; g:$19894(source, destination, x, y, width, height, ...): rectangle copy
fast_rect_copy
	movem.l	d2-d4,-(sp)
	lea	20(sp),a0
	bsr.b	fast_mark_rect
	movem.l	(sp)+,d2-d4
	link	a6,#-4
	movem.l	d2-d7,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$1989c-$1000,a0
	jmp	(a0)

; a0 the arguments plane, x, y, width, height (pixels, longs)
fast_mark_rect
	move.l	(a0)+,d0
	move.l	(a0)+,d3
	move.l	(a0)+,d1
	move.l	(a0)+,d4
	move.l	(a0),d2
	add.l	d1,d2
	subq.l	#1,d2
	add.l	d3,d4
	subq.l	#1,d4
	asr.l	#4,d3
	asr.l	#4,d4
	bpl.w	fast_mark
	moveq	#0,d4			; g:$199e0 rounds toward 0
	bra.w	fast_mark

; g:$19802(words, colour, address): clear or fill
fast_clear
	movem.l	d2-d4,-(sp)
	move.l	24(sp),d0
	bsr.w	fast_mark_all
	movem.l	(sp)+,d2-d4
	link	a6,#0
	movem.l	d2-d4,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$1980a-$1000,a0
	jmp	(a0)

; g:$1bf76: a picture into a buffer, partly by the CPU
fast_picture
	lea	fast_dirty(pc),a0
	moveq	#BANDS*2-1,d0
.all
	move.w	#$0013,(a0)+
	dbf	d0,.all
	link	a6,#-4
	movem.l	d2-d6/a2-a4,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$1bf7e-$1000,a0
	jmp	(a0)

; g:$1975c(words, source, destination): copy. The full copy of buffer 0 onto a display
; buffer copies only the dirty parts. Outside the gameplay frame (g:$094e4) the whole of it
; is dirtied first, and so is the other display buffer.
fast_copy
	cmp.l	#BUF_SIZE/2,4(sp)
	bne.b	.other
	cmp.l	#BUF0,8(sp)
	bne.b	.other
	lea	fast_dirty(pc),a0
	lea	BANDS*2(a0),a1
	move.l	12(sp),d0
	cmp.l	#BUF1,d0
	beq.b	.display
	exg	a0,a1
	cmp.l	#BUF2,d0
	beq.b	.display
.other
	movem.l	d2-d4,-(sp)
	move.l	24(sp),d0
	bsr.w	fast_mark_all
	movem.l	(sp)+,d2-d4
	link	a6,#0
	movem.l	d2-d5,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$19764-$1000,a0
	jmp	(a0)
.display				; a0 this buffer's table, a1 the other's
	move.l	_reloc_base(pc),d0
	add.l	#$094f4-$1000,d0	; return address of g:$094e4's call of g:$1bd5e
	cmp.l	4(a6),d0		; a6 is g:$1bd5e's frame
	beq.b	.restore
	moveq	#BANDS-1,d0
.all
	move.w	#$0013,(a0)+
	move.w	#$0013,(a1)+
	dbf	d0,.all
	lea	-BANDS*2(a0),a0
.restore
	movem.l	d2-d7/a2-a3,-(sp)
	move.l	12+32(sp),a3		; destination
	move.l	a0,a1
	move.w	#INTF_BLIT,_custom+intena	; no blitter interrupts: the waits poll
	moveq	#0,d2			; band
.scan
	cmp.w	#BANDS,d2
	beq.w	.done
	move.b	(a1),d3			; first column
	cmp.b	1(a1),d3
	bls.b	.group
	addq.l	#2,a1
	addq.w	#1,d2
	bra.b	.scan
.group					; dirty bands d5 to d2-1, columns d3 to d4
	move.b	1(a1),d4
	move.w	d2,d5
.more
	move.w	#$ff00,(a1)+
	addq.w	#1,d2
	cmp.w	#BANDS,d2
	beq.b	.blit
	move.b	(a1),d6
	cmp.b	1(a1),d6
	bhi.b	.blit
	cmp.b	d6,d3
	bls.b	.left
	move.b	d6,d3
.left
	move.b	1(a1),d6
	cmp.b	d6,d4
	bcc.b	.more
	move.b	d6,d4
	bra.b	.more
.blit
	and.w	#$ff,d3
	and.w	#$ff,d4
	move.w	d5,d6
	mulu	#8*40,d6
	add.w	d3,d6
	add.w	d3,d6			; offset in the plane
	move.w	d2,d7
	sub.w	d5,d7
	lsl.w	#3,d7			; lines
	lsl.w	#6,d7
	move.w	d4,d0
	sub.w	d3,d0
	addq.w	#1,d0			; words
	or.w	d0,d7			; BLTSIZE
	moveq	#20,d1
	sub.w	d0,d1
	add.w	d1,d1			; modulo
	lea	BUF0,a0
	add.l	d6,a0
	lea	(a3,d6.l),a2
	bsr.b	.waitblit
	move.l	#$09f00000,_custom+bltcon0
	move.l	#-1,_custom+bltafwm
	move.w	d1,_custom+bltamod
	move.w	d1,_custom+bltdmod
	moveq	#5-1,d0
.plane
	bsr.b	.waitblit
	move.l	a0,_custom+bltapt
	move.l	a2,_custom+bltdpt
	move.w	d7,_custom+bltsize
	lea	PLANE_SIZE(a0),a0
	lea	PLANE_SIZE(a2),a2
	dbf	d0,.plane
	bra.w	.scan
.done
	bsr.b	.waitblit
	move.w	#INTF_BLIT,_custom+intreq
	move.w	#INTF_SETCLR|INTF_BLIT,_custom+intena
	movem.l	(sp)+,d2-d7/a2-a3
	rts
.waitblit
	btst	#DMAB_BLTDONE-8,_custom+dmaconr
.busy
	btst	#DMAB_BLTDONE-8,_custom+dmaconr
	bne.b	.busy
	rts
