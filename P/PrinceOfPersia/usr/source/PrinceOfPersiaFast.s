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

