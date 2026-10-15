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
	; C4: logic hot spots
	PL_P	$10942,fast_load_leftroom
	PL_P	$1099a,fast_load_rowbelow
	PL_P	$14fe6,fast_get_right_wall_xpos
	; C2(b): restore only what changed instead of the full-screen copy (INTERNALS.md B1)
	PL_P	$05686,fast_shape
	PL_P	$199e0,fast_rect_fill
	PL_P	$19894,fast_rect_copy
	PL_P	$19802,fast_clear
	PL_P	$1975c,fast_copy
	PL_P	$1bf76,fast_picture
	; C5: shape draw path
	PL_P	$0be6c,fast_image_remap
	PL_P	$1dd9a,fast_get_image
	PL_P	$1dd14,fast_get_image_checked
	PL_P	$1c802,fast_load_image
	PL_P	$1c694,fast_get_frame
	PL_P	$1c29c,fast_draw_shape
	PL_P	$1c8d6,fast_clip
	PL_P	$1cb94,fast_draw
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
; C4 logic hot spots (draw_room's row loads, check_collisions).

; load_leftroom(), g:$10942: leftroom_[row] = the left room's column 9
fast_load_leftroom
	movem.l	d2-d3/a2,-(sp)
	move.l	$47b1c,-(sp)		; room_L
	bsr.w	fast_get_room_address
	addq.l	#4,sp
	lea	$499fc,a2		; leftroom_
	moveq	#0,d2
.row
	move.l	$47b1c,d0
	moveq	#9,d1
	moveq	#20,d3
	bsr.w	tile_to_draw
	move.b	d0,(a2)+
	move.b	d1,(a2)+
	addq.l	#1,d2
	moveq	#3,d0
	cmp.l	d2,d0
	bgt.b	.row
	movem.l	(sp)+,d2-d3/a2
	rts

; load_rowbelow(), g:$1099a: row_below_left_[1..9] = columns 0-8 of the row below,
; row_below_left_[0] = column 9 of the room to its left
fast_load_rowbelow
	movem.l	d2-d5/a2,-(sp)
	moveq	#2,d0
	cmp.l	$49a16,d0		; drawn_row
	bne.b	.same
	move.l	$47b28,d4		; room_B
	move.l	$47b34,d5		; room_BL
	moveq	#0,d2
	bra.b	.rooms
.same
	move.l	$47b18,d4		; drawn_room
	move.l	$47b1c,d5		; room_L
	move.l	$49a16,d2
	addq.l	#1,d2
.rooms
	move.l	d4,-(sp)
	bsr.w	fast_get_room_address
	addq.l	#4,sp
	lea	$49a02+2,a2		; row_below_left_[1]
	moveq	#0,d3			; tile_room0
	moveq	#0,d1
.column
	move.l	d1,-(sp)
	move.l	d4,d0
	bsr.w	tile_to_draw
	move.b	d0,(a2)+
	move.b	d1,(a2)+
	move.l	(sp)+,d1
	addq.l	#1,d1
	moveq	#9,d0
	cmp.l	d1,d0
	bgt.b	.column
	move.l	d5,-(sp)
	bsr.w	fast_get_room_address
	addq.l	#4,sp
	move.l	d5,d0
	moveq	#9,d1
	moveq	#20,d3
	bsr.w	tile_to_draw
	move.b	d0,$49a02
	move.b	d1,$49a02+1
	move.l	$47b18,-(sp)
	bsr.w	fast_get_room_address
	addq.l	#4,sp
	movem.l	(sp)+,d2-d5/a2
	rts

; get_right_wall_xpos(room, column, row), g:$14fe6. check_collisions (g:$14e8c) calls it
; at g:$14f24 right after get_left_wall_xpos (g:$14f8e) with the same arguments, and only
; register code between: get_tile (g:$12bea) would redo the same writes and return the same
; curr_tile2 ($49b70), so that call reuses it.
fast_get_right_wall_xpos
	move.l	_reloc_base(pc),d0
	add.l	#$14f28-$1000,d0
	cmp.l	(sp),d0
	bne.b	.get_tile
	moveq	#0,d0
	move.b	$49b70,d0
	bra.b	.wall
.get_tile
	move.l	12(sp),-(sp)
	move.l	12(sp),-(sp)
	move.l	12(sp),-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$12bea-$1000,a0
	jsr	(a0)
	lea	12(sp),sp
.wall
	move.l	d0,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$13fc8-$1000,a0	; wall_type
	jsr	(a0)
	addq.l	#4,sp
	tst.l	d0
	beq.b	.done
	move.l	_reloc_base(pc),a0
	add.l	d0,a0
	move.b	($7404-$1000,a0),d1
	ext.w	d1
	ext.l	d1
	moveq	#13,d0
	add.l	$49b0e,d0
	sub.l	d1,d0
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

;---------------------------------------------------------------------------
; C5 shape draw path (INTERNALS.md B4, B5). The image draw g:$11904 goes through a tag-list
; graphics library: g:$1c29c parses the tags, g:$1c694 picks the image, g:$1c8d6 clips and
; g:$1cb94 sets up the blits. These are the same routines with register code in place of
; the compiled C; their memory writes and results are the same.

; image_remap(&chtab, &id), g:$0be6c: the kid's two tables ($7f928, $7fa90) are split into
; eight per image range (g:$06310, two tables per range); other tables are left alone
fast_image_remap
	move.l	4(sp),a1
	moveq	#0,d0
	cmp.l	#$7f928,(a1)
	beq.b	.kid
	cmp.l	#$7fa90,(a1)
	bne.b	.done
	moveq	#4,d0
.kid
	move.l	8(sp),a0
	move.l	(a0),d1
	cmp.l	#142,d1
	bhi.b	.done
	move.l	d2,-(sp)
	moveq	#0,d2
	move.b	.group(pc,d1.w),d2
	bmi.b	.none
	sub.b	.base(pc,d2.w),d1
	move.l	d1,(a0)
	lsl.w	#3,d2
	add.w	d2,d0
	move.l	_reloc_base(pc),a0
	add.w	d0,a0
	move.l	($6310-$1000,a0),(a1)
.none
	move.l	(sp)+,d2
.done
	rts
.base
	dc.b	0,29,74,77,85,100,126,9
	; range of each id 0-142, -1 for none
.group
	dc.b	0,0,0,0,0,0,0,0,0,7,7,7,7,-1,-1,-1
	dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,1,1,-1
	dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1
	dc.b	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,2,2,2,3,3,3
	dc.b	3,3,3,-1,-1,4,4,4,4,4,4,-1,-1,-1,-1,-1
	dc.b	-1,-1,-1,-1,5,5,5,5,5,5,5,5,5,5,5,5
	dc.b	5,5,5,5,5,5,5,5,5,5,5,-1,-1,-1,6,6
	dc.b	6,6,6,6,6,6,6,6,6,6,6,6,6,6,6
	even

; get_image(chtab, id), g:$1dd9a: the image's address, 0 for no table or an id out of range
fast_get_image
	move.l	4(sp),d0
	beq.b	.done
	move.l	d0,a0
	moveq	#0,d0
	move.w	8(a0),d0		; image count
	cmp.l	8(sp),d0
	bhi.b	fast_get_image_checked
	moveq	#0,d0
.done
	rts

; get_image_checked(chtab, id), g:$1dd14: the same without the checks (the original asserts)
fast_get_image_checked
	pea	8(sp)
	pea	8(sp)
	bsr.w	fast_image_remap
	addq.l	#8,sp
	move.l	4(sp),a1
	move.l	(a1),a0
	move.l	8(a0),d0
	add.l	10(a1),d0		; the offset table
	move.l	d0,a0
	move.l	8(sp),d1
	add.l	d1,d1
	add.l	d1,d1
	move.l	(a0,d1.l),d1
	add.l	d1,d1
	add.l	d1,d0
	rts

; load_image(chtab, id), g:$1c802: decodes the image's header into $674be-$674dd
; > d0 1 when its data is outside chip memory
fast_load_image
	move.l	8(sp),-(sp)
	move.l	8(sp),-(sp)
	bsr.b	fast_get_image_checked
	addq.l	#8,sp
	move.l	d0,a0
	lea	$674be,a1
	move.l	a0,(a1)+		; $674be image
	addq.l	#8,d0
	move.l	d0,(a1)+		; $674c2 data
	moveq	#$7f,d0
	and.b	(a0),d0
	move.w	d0,(a1)+		; $674c6 width
	moveq	#$7f,d1
	and.b	1(a0),d1
	move.w	d1,(a1)+		; $674c8 height
	move.b	2(a0),d1
	ext.w	d1
	move.w	d1,(a1)+		; $674ca x offset
	move.b	3(a0),d1
	ext.w	d1
	move.w	d1,(a1)+		; $674cc y offset
	moveq	#0,d1
	tst.b	(a0)
	bpl.b	.x
	moveq	#1,d1
.x
	move.w	d1,(a1)+		; $674ce
	moveq	#0,d1
	tst.b	1(a0)
	bpl.b	.y
	moveq	#1,d1
.y
	move.w	d1,(a1)+		; $674d0
	moveq	#0,d1
	move.b	4(a0),d1
	lsr.b	#3,d1
	move.w	d1,(a1)+		; $674d2
	moveq	#0,d1
	move.b	6(a0),d1
	lsr.b	#3,d1
	move.w	d1,(a1)+		; $674d4
	subq.l	#1,d0			; words: (width - 1) / 16 + 1, 0 for no width
	asr.l	#4,d0
	addq.l	#1,d0
	move.w	d0,(a1)+		; $674d6
	mulu.w	$674c8,d0
	move.w	d0,(a1)+		; $674d8 plane size
	moveq	#0,d0
	cmp.l	#$80000,$674c2
	bcs.b	.chip
	moveq	#1,d0
.chip
	move.l	d0,(a1)			; $674da
	rts

; get_frame(chtab, x [, y [, z]]), g:$1c694: loads image x (+ y x columns (+ z x rows)) of
; a table with 1-3 dimensions; -2 picks the last
fast_get_frame
	move.l	4(sp),a0
	moveq	#0,d0
	move.b	4(a0),d0		; dimensions
	cmp.w	#3,d0
	bhi.w	.orig
	moveq	#0,d1
	move.b	5(a0),d1		; columns
	move.l	8(sp),d0
	cmp.l	#-2,d0
	bne.b	.x
	move.l	d1,d0
	subq.l	#1,d0
.x
	cmp.l	d1,d0			; out of range: the original's assert
	bcc.w	.orig
	cmp.b	#2,4(a0)
	bcs.b	.load
	movem.l	d2-d4,-(sp)
	move.l	d0,d2			; index so far
	moveq	#0,d3
	move.b	6(a0),d3		; rows
	move.l	12+12(sp),d0
	cmp.l	#-2,d0
	bne.b	.y
	move.l	d3,d0
	subq.l	#1,d0
.y
	cmp.l	d3,d0
	bcc.b	.orig_saved
	cmp.b	#3,4(a0)
	bne.b	.rows
	moveq	#0,d4
	move.b	7(a0),d4		; layers
	move.l	16+12(sp),d1
	cmp.l	#-2,d1
	bne.b	.z
	move.l	d4,d1
	subq.l	#1,d1
.z
	cmp.l	d4,d1
	bcc.b	.orig_saved
	mulu.w	d3,d1			; z x rows + y
	add.l	d1,d0
	moveq	#0,d1
	move.b	5(a0),d1
.rows
	mulu.w	d1,d0			; x columns + x
	add.l	d2,d0
	movem.l	(sp)+,d2-d4
.load
	move.l	d0,-(sp)
	move.l	a0,-(sp)
	bsr.w	fast_load_image
	addq.l	#8,sp
	rts
.orig_saved
	movem.l	(sp)+,d2-d4
.orig
	link	a6,#0
	movem.l	d2-d5/a2-a3,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$1c69c-$1000,a0
	jmp	(a0)

; draw_shape(chtab, id, x, y, tag, args..., -1), g:$1c29c: sets the tags' state in
; $674de-$6750d, clips (g:$1c8d6) and draws (g:$1cb94) the image, then the further parts of
; the images some tables split
; > d0 1 if any part was drawn
fast_draw_shape
	movem.l	d2-d5/a2-a4,-(sp)
	lea	4+28(sp),a4
	movem.l	(a4)+,d2-d5		; chtab, id, x, y
	tst.l	d2
	beq.w	.orig			; the original asserts
	move.l	d2,a0
	cmp.b	#2,4(a0)		; it passes one index whatever the table
	bcc.w	.orig
	; clear the tags' state as g:$1c578 does
	lea	$674de,a0
	clr.l	4(a0)
	clr.l	8(a0)
	clr.l	12(a0)
	clr.l	16(a0)
	clr.l	20(a0)
	clr.l	24(a0)
	clr.l	32(a0)
	clr.l	38(a0)
	clr.l	44(a0)
.tag
	move.l	(a4)+,d0
	moveq	#-1,d1
	cmp.l	d1,d0
	beq.w	.tags_done
	cmp.l	#9,d0
	bhi.w	.orig			; the original asserts
	add.w	d0,d0
	move.w	.tags(pc,d0.w),d0
	jmp	.tags(pc,d0.w)
.tags
	dc.w	.t0-.tags,.t1-.tags,.t2-.tags,.t3-.tags,.t4-.tags
	dc.w	.t5-.tags,.t6-.tags,.t7-.tags,.t8-.tags,.t9-.tags
.t0
	move.w	2(a4),$674ea
	move.w	6(a4),$674ec
	addq.l	#8,a4
	bra.w	.tag
.t1
	move.w	2(a4),$674ea
	addq.l	#4,a4
	bra.w	.tag
.t2
	move.w	2(a4),$674ec
	addq.l	#4,a4
	bra.w	.tag
.t3
	move.l	(a4)+,$674ee
	move.l	(a4)+,$674f2
	bra.w	.tag
.t4
	move.l	(a4)+,$674ee
	bra.w	.tag
.t5
	move.l	(a4)+,$674f2
	bra.w	.tag
.t6
	move.l	(a4)+,$674f6
	move.l	(a4)+,$674fa
	bra.w	.tag
.t7
	move.l	(a4)+,$674fe
	moveq	#31,d0
	and.w	2(a4),d0
	move.w	d0,$67502
	addq.l	#4,a4
	bra.w	.tag
.t8
	move.l	(a4)+,$67504
	moveq	#31,d0
	and.w	2(a4),d0
	move.w	d0,$67508
	addq.l	#4,a4
	bra.w	.tag
.t9
	move.l	(a4)+,$6750a
	bra.w	.tag
.tags_done
	move.l	d3,-(sp)
	move.l	d2,-(sp)
	pea	4(sp)
	pea	4(sp)
	bsr.w	fast_image_remap
	addq.l	#8,sp
	movem.l	(sp)+,d2-d3
	move.l	_reloc_base(pc),a3
	add.l	#$1c000-$1000,a3
	sub.l	a2,a2			; drawn
	lea	.chain(pc),a4
.part
	move.l	d3,-(sp)
	move.l	d2,-(sp)
	bsr.w	fast_get_frame
	move.l	d5,(sp)
	move.l	d4,-(sp)
	jsr	($8d6,a3)		; g:$1c8d6, clip
	lea	12(sp),sp
	tst.l	d0
	beq.b	.next
	jsr	($b94,a3)		; g:$1cb94, draw
	move.w	#1,a2
.next
	; the tables whose images go on in another (g:$1c35a-$1c476)
	move.l	(a4)+,d0
	beq.b	.done
	cmp.l	d0,d2
	beq.b	.found
	addq.l	#4,a4
	bra.b	.next
.found
	move.l	(a4),d2
	lea	.chain2(pc),a4		; only that one goes on to a third
	bra.b	.part
.done
	move.l	a2,d0
	movem.l	(sp)+,d2-d5/a2-a4
	rts
.orig
	movem.l	(sp)+,d2-d5/a2-a4
	link	a6,#-8
	movem.l	d2-d5/a2-a4,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$1c2a4-$1000,a0
	jmp	(a0)
.chain
	dc.l	$7f706,$7f714
	dc.l	$7fb44,$7fb52
	dc.l	$7fb76,$7fb84
	dc.l	$7fba8,$7fbb6
	dc.l	$7fbda,$7fbe8
	dc.l	$7fc0c,$7fc1a
	dc.l	$7f738,$7f746
	dc.l	$7f76a,$7f778
	dc.l	0
.chain2
	dc.l	$7fc1a,$7fc28
	dc.l	0

; The loaded image and its blit state, from load_image's header to the plane pointers
SHAPE = $674be

; clip_image(x, y), g:$1c8d6: places the loaded image at x, y in the clip rectangle
; (g:$07e42: origin x, -, origin y, -, left, right, bottom, top; words) and sets its target
; position $674de-$674e1 and the lines and columns clipped off each edge $674e2-$674e9
; > d0 0 if nothing is left
fast_clip
	movem.l	d2-d6/a2,-(sp)
	move.w	4+24+2(sp),d1		; x
	move.w	8+24+2(sp),d3		; y
	move.l	_reloc_base(pc),a2
	add.l	#$7e42-$1000,a2
	lea	SHAPE,a0
	move.w	14(a2),d0
	cmp.w	12(a2),d0
	blt.w	.none
	move.w	16(a2),d0
	cmp.w	18(a2),d0
	blt.w	.none
	add.w	$674ea-SHAPE(a0),d1	; tag offsets
	add.w	$674ec-SHAPE(a0),d3
	moveq	#0,d5
	moveq	#0,d6
	; left edge: x less the image's x offset and half its width
	tst.l	$674ee-SHAPE(a0)
	bne.b	.hflip
	move.w	d1,d4
	sub.w	$674ca-SHAPE(a0),d4
	moveq	#0,d0
	move.w	$674c6-SHAPE(a0),d0
	subq.l	#1,d0
	bpl.b	.hhalf
	moveq	#0,d0
.hhalf
	lsr.l	#1,d0
	sub.w	d0,d4
	bra.b	.hclip
.hflip
	moveq	#0,d0
	tst.w	$674ce-SHAPE(a0)
	bne.b	.hodd
	moveq	#1,d0
.hodd
	move.w	$674ca-SHAPE(a0),d4
	add.w	d1,d4
	add.w	d0,d4
	move.w	$674c6-SHAPE(a0),d0
	lsr.w	#1,d0
	sub.w	d0,d4
.hclip
	cmp.w	12(a2),d4
	bge.b	.left_in
	move.w	12(a2),d5
	sub.w	d4,d5
	cmp.w	$674c6-SHAPE(a0),d5
	bcc.w	.none
	move.w	12(a2),d4
.left_in
	move.w	$674c6-SHAPE(a0),d0
	sub.w	d5,d0
	add.w	d4,d0
	subq.w	#1,d0
	cmp.w	14(a2),d0
	ble.b	.right_in
	move.w	d0,d6
	sub.w	14(a2),d6
	moveq	#0,d2
	move.w	$674c6-SHAPE(a0),d2
	moveq	#0,d0
	move.w	d6,d0
	moveq	#0,d1
	move.w	d5,d1
	add.l	d1,d0
	cmp.l	d0,d2
	bls.w	.none
.right_in
	move.w	d4,d0
	sub.w	12(a2),d0
	add.w	(a2),d0
	move.w	d0,$674de-SHAPE(a0)
	tst.l	$674ee-SHAPE(a0)
	beq.b	.hstore
	exg	d5,d6
.hstore
	move.w	d5,$674e2-SHAPE(a0)
	move.w	d6,$674e4-SHAPE(a0)
	; top edge, the same way; the target y is that of the bottom line
	moveq	#0,d5
	moveq	#0,d6
	tst.l	$674f2-SHAPE(a0)
	bne.b	.vflip
	move.w	d3,d4
	sub.w	$674cc-SHAPE(a0),d4
	moveq	#0,d0
	move.w	$674c8-SHAPE(a0),d0
	subq.l	#1,d0
	bpl.b	.vhalf
	moveq	#0,d0
.vhalf
	lsr.l	#1,d0
	sub.w	d0,d4
	bra.b	.vclip
.vflip
	moveq	#0,d0
	tst.w	$674d0-SHAPE(a0)
	bne.b	.vodd
	moveq	#1,d0
.vodd
	move.w	$674cc-SHAPE(a0),d4
	add.w	d3,d4
	add.w	d0,d4
	move.w	$674c8-SHAPE(a0),d0
	lsr.w	#1,d0
	sub.w	d0,d4
.vclip
	cmp.w	18(a2),d4
	bge.b	.top_in
	move.w	18(a2),d6
	sub.w	d4,d6
	cmp.w	$674c8-SHAPE(a0),d6
	bcc.b	.none
	move.w	18(a2),d4
.top_in
	move.w	$674c8-SHAPE(a0),d1
	sub.w	d6,d1
	add.w	d4,d1
	subq.w	#1,d1
	cmp.w	16(a2),d1
	ble.b	.bottom_in
	move.w	d1,d5
	sub.w	16(a2),d5
	moveq	#0,d2
	move.w	$674c8-SHAPE(a0),d2
	moveq	#0,d0
	move.w	d6,d0
	moveq	#0,d1
	move.w	d5,d1
	add.l	d1,d0
	cmp.l	d0,d2
	bls.b	.none
	move.w	16(a2),d1
.bottom_in
	move.w	6(a2),d0
	subq.w	#1,d0
	sub.w	d1,d0
	add.w	18(a2),d0
	move.w	d0,$674e0-SHAPE(a0)
	tst.l	$674f2-SHAPE(a0)
	beq.b	.vstore
	exg	d5,d6
.vstore
	move.w	d5,$674e6-SHAPE(a0)
	move.w	d6,$674e8-SHAPE(a0)
	moveq	#1,d0
	bra.b	.out
.none
	moveq	#0,d0
.out
	movem.l	(sp)+,d2-d6/a2
	rts

; draw_image(), g:$1cb94: blits the clipped image, through the scratch planes at
; $1a28-$49c7 (g:$05432) when it is clipped, masked (tag 6) or outside chip memory
fast_draw
	movem.l	d2-d5/a2,-(sp)
	lea	SHAPE,a0
	bsr.w	.setup
	bsr.w	.flip
	lea	SHAPE,a0
	tst.l	$674f6-SHAPE(a0)
	bne.b	.scratch
	tst.l	$674e2-SHAPE(a0)	; clipped left or right
	bne.b	.scratch
	tst.l	$674e6-SHAPE(a0)	; top or bottom
	bne.b	.scratch
	tst.l	$674da-SHAPE(a0)
	bne.b	.scratch
	move.w	$674d8-SHAPE(a0),$6751c-SHAPE(a0)
	moveq	#0,d0
	bsr.w	.planes
	bra.b	.blit
.scratch
	move.w	$67510-SHAPE(a0),d0
	mulu.w	$6750e-SHAPE(a0),d0
	move.w	d0,$6751c-SHAPE(a0)
	move.w	$67512-SHAPE(a0),d0	; first source line and word
	mulu.w	$674d6-SHAPE(a0),d0
	moveq	#0,d1
	move.w	$67514-SHAPE(a0),d1
	add.l	d1,d0
	bsr.w	.planes
	move.l	_reloc_base(pc),a0
	jsr	($05432-$1000,a0)
	lea	SHAPE,a0
	tst.l	$674f6-SHAPE(a0)
	beq.b	.ptrs
	move.l	$674fa-SHAPE(a0),-(sp)
	move.l	_reloc_base(pc),a0
	jsr	($055a6-$1000,a0)
	addq.l	#4,sp
.ptrs
	lea	$67528,a0
	move.l	#$1a28,(a0)+
	move.l	#$2218,(a0)+
	move.l	#$2a08,(a0)+
	move.l	#$31f8,(a0)+
	move.l	#$39e8,(a0)+
	move.l	#$41d8,(a0)
.blit
	move.l	_reloc_base(pc),a0
	jsr	($05686-$1000,a0)
	movem.l	(sp)+,d2-d5/a2
	rts

	; g:$1cc8c: the blit geometry in $6750e-$67527. a0 SHAPE, kept
.setup
	move.w	$674c6-SHAPE(a0),d0	; clipped width and height
	sub.w	$674e2-SHAPE(a0),d0
	sub.w	$674e4-SHAPE(a0),d0
	move.w	d0,$6751a-SHAPE(a0)
	move.w	$674c8-SHAPE(a0),d0
	sub.w	$674e6-SHAPE(a0),d0
	sub.w	$674e8-SHAPE(a0),d0
	move.w	d0,$6750e-SHAPE(a0)
	move.w	d0,$6751e-SHAPE(a0)
	move.w	$674de-SHAPE(a0),d0	; target word, shift and words
	move.w	d0,d1
	lsr.w	#4,d1
	move.w	d1,$67524-SHAPE(a0)
	moveq	#15,d2
	and.w	d0,d2
	move.w	d2,$67526-SHAPE(a0)
	add.w	$6751a-SHAPE(a0),d0
	subq.w	#1,d0
	lsr.w	#4,d0
	sub.w	d1,d0
	addq.w	#1,d0
	move.w	d0,$67520-SHAPE(a0)
	move.w	$674e0-SHAPE(a0),$67522-SHAPE(a0)
	tst.l	$674ee-SHAPE(a0)	; source column: the flipped image is word aligned on the right
	beq.b	.noflip
	move.w	$674c6-SHAPE(a0),d0
	subq.w	#1,d0
	and.w	#15,d0
	moveq	#15,d3
	sub.w	d0,d3
	add.w	$674e4-SHAPE(a0),d3
	bra.b	.source
.noflip
	move.w	$674e2-SHAPE(a0),d3
.source
	move.w	d3,d0
	lsr.w	#4,d0
	move.w	d0,$67514-SHAPE(a0)
	moveq	#15,d1
	and.w	d3,d1
	move.w	d1,$67516-SHAPE(a0)
	add.w	$6751a-SHAPE(a0),d3
	subq.w	#1,d3
	moveq	#15,d1
	and.w	d3,d1
	move.w	d1,$67518-SHAPE(a0)
	lsr.w	#4,d3
	sub.w	d0,d3
	addq.w	#1,d3
	move.w	d3,$67510-SHAPE(a0)
	move.w	$674e6-SHAPE(a0),d0	; first source line
	tst.l	$674f2-SHAPE(a0)
	beq.b	.line
	move.w	$674e8-SHAPE(a0),d0
.line
	move.w	d0,$67512-SHAPE(a0)
	rts

	; g:$1cdba: flips the image data in place when the wanted direction differs from the
	; one recorded in its header (bit 2 of byte 4, and of byte 6 for vertical). Both
	; record into byte 4, as the original does. a0 SHAPE
.flip
	move.l	(a0),a1
	moveq	#0,d1
	btst	#2,4(a1)
	beq.b	.h
	moveq	#1,d1
.h
	cmp.l	$674ee-SHAPE(a0),d1
	beq.b	.v
	move.l	#$055ca-$1000,d2
	bsr.b	.flip_call
.v
	moveq	#0,d1
	btst	#2,6(a1)
	beq.b	.v1
	moveq	#1,d1
.v1
	cmp.l	$674f2-SHAPE(a0),d1
	beq.b	.flipped
	move.l	#$0562c-$1000,d2
.flip_call
	moveq	#0,d0
	move.w	$674d2-SHAPE(a0),d0
	move.l	d0,-(sp)
	move.w	$674c8-SHAPE(a0),d0
	move.l	d0,-(sp)
	move.w	$674d6-SHAPE(a0),d0
	move.l	d0,-(sp)
	move.l	$674c2-SHAPE(a0),-(sp)
	add.l	_reloc_base(pc),d2
	move.l	d2,a0
	jsr	(a0)
	lea	16(sp),sp
	lea	SHAPE,a0
	move.l	(a0),a1
	moveq	#1,d0
	and.b	$674f1-SHAPE(a0),d0
	lsl.b	#2,d0
	and.b	#~4,4(a1)
	or.b	d0,4(a1)
.flipped
	rts

	; g:$1ce74: plane pointers $67528-$6753b and the mask $6753c from the image data
	; $674c2 + 2 × d0, the planes present ($674d2) and the planes to fill from the mask
	; ($674d4, tags 7 and 8), or blank ($49c8). a0 SHAPE, kept
.planes
	move.l	$674c2-SHAPE(a0),d1
	add.l	d0,d1
	add.l	d0,d1
	lea	$49c8,a1
	lea	$67528,a2
	moveq	#0,d5
	move.w	$674d8-SHAPE(a0),d5
	add.l	d5,d5			; plane size in bytes
	move.w	$674d2-SHAPE(a0),d2
	moveq	#5-1,d4
	tst.l	$67504-SHAPE(a0)
	beq.b	.present
	; tag 8: past the image's planes; the planes in $67509 are the mask, the others blank
.past
	lsr.w	#1,d2
	bcc.b	.past_next
	add.l	d5,d1
.past_next
	dbf	d4,.past
	move.b	$67509-SHAPE(a0),d2
	moveq	#5-1,d4
.select
	move.l	a1,(a2)
	lsr.b	#1,d2
	bcc.b	.select_next
	move.l	d1,(a2)
.select_next
	addq.l	#4,a2
	dbf	d4,.select
	move.l	d1,(a2)
	bra.b	.tag7
.present
	move.l	a1,(a2)
	lsr.w	#1,d2
	bcc.b	.present_next
	move.l	d1,(a2)
	add.l	d5,d1
.present_next
	addq.l	#4,a2
	dbf	d4,.present
	move.l	d1,(a2)			; the mask follows the planes
	lea	$67528,a2
	move.w	$674d4-SHAPE(a0),d3
	moveq	#5-1,d4
.fill
	lsr.w	#1,d3
	bcc.b	.fill_next
	cmp.l	(a2),a1
	bne.b	.fill_next
	move.l	d1,(a2)
.fill_next
	addq.l	#4,a2
	dbf	d4,.fill
.tag7
	tst.l	$674fe-SHAPE(a0)
	beq.b	.tag9
	lea	$67528,a2
	move.b	$67503-SHAPE(a0),d2
	moveq	#5-1,d4
.mask
	lsr.b	#1,d2
	bcc.b	.mask_next
	move.l	d1,(a2)
.mask_next
	addq.l	#4,a2
	dbf	d4,.mask
.tag9
	tst.l	$6750a-SHAPE(a0)
	beq.b	.planes_done
	move.l	a1,$6753c
.planes_done
	rts
