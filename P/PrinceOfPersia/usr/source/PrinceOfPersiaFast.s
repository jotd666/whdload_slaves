;*---------------------------------------------------------------------------
;  :Contents.	A500 speed-ups for all supported Prince of Persia versions.
;		Performance analysis and development notes are kept locally.
;		CUSTOM5 bit OPT_ORIGINAL turns them all off, for A/B comparisons.
;---------------------------------------------------------------------------*

OPT_ORIGINAL = 4

pl_fast_v1
	PL_START
	PL_IFC5X	OPT_ORIGINAL
	PL_ELSE
	; C1: synchronous polling replaces STOP and the per-blit interrupt
	PL_P	$053a2,fast_blit_c
	PL_P	$053d6,fast_blit
	PL_P	$053dc,fast_blit_saved	; continuation used by VERIFY's sabotage probe
	VERSION_REF	1,4,VR_GAME_CODE
	PL_W	$19ecc,$a028		; enable VERTB/PORTS/EXTER, without BLIT
	; C3: tile lookup
	VERSION_REF	2,4,VR_GAME_CODE
	PL_P	$107d0,fast_get_tile_to_draw
	VERSION_REF	3,4,VR_GAME_CODE
	PL_P	$108c6,fast_load_curr_and_left_tile
	VERSION_REF	4,4,VR_GAME_CODE
	PL_P	$11b96,fast_get_room_address
	; C4: logic hot spots
	VERSION_REF	5,4,VR_GAME_CODE
	PL_P	$131f0,fast_record_131f0
	VERSION_REF	6,4,VR_GAME_CODE
	PL_P	$1320e,fast_record_1320e
	VERSION_REF	7,4,VR_GAME_CODE
	PL_P	$1322c,fast_record_1322c
	VERSION_REF	8,4,VR_GAME_CODE
	PL_P	$1324a,fast_record_1324a
	VERSION_REF	9,4,VR_GAME_CODE
	PL_P	$13268,fast_record_13268
	VERSION_REF	10,4,VR_GAME_CODE
	PL_P	$1328a,fast_record_1328a
	VERSION_REF	11,4,VR_GAME_CODE
	PL_P	$132ac,fast_record_132ac
	VERSION_REF	12,4,VR_GAME_CODE
	PL_P	$132ce,fast_record_132ce

	VERSION_REF	13,4,VR_GAME_CODE
	PL_P	$10942,fast_load_leftroom
	VERSION_REF	14,4,VR_GAME_CODE
	PL_P	$1099a,fast_load_rowbelow
	VERSION_REF	15,4,VR_GAME_CODE
	PL_P	$14fe6,fast_get_right_wall_xpos
	VERSION_REF	16,2,VR_EARLY_CODE
	PL_P	$0ba56,fast_draw_frame
	VERSION_REF	17,4,VR_GAME_CODE
	PL_P	$116a2,fast_draw_table
	PL_P	$05908,fast_shape_expand
	PL_P	$055ca,fast_flip_horizontal
	VERSION_REF	18,4,VR_GAME_CODE
	PL_P	$12bea,fast_get_tile
	VERSION_REF	19,4,VR_GAME_CODE
	PL_P	$12c7c,fast_find_room
	VERSION_REF	20,4,VR_GAME_CODE
	PL_P	$14e8c,fast_check_collisions
	VERSION_REF	21,4,VR_GAME_CODE
	PL_P	$131b0,fast_y_to_row
	VERSION_REF	22,4,VR_GAME_CODE
	PL_P	$13596,fast_collision_dimensions
	; C2(b): restore only what changed instead of the full-screen copy
	PL_P	$05686,fast_shape
	VERSION_REF	23,4,VR_GAME_CODE
	PL_P	$199e0,fast_rect_fill
	VERSION_REF	24,4,VR_GAME_CODE
	PL_P	$19894,fast_rect_copy
	VERSION_REF	25,4,VR_GAME_CODE
	PL_P	$19802,fast_clear
	VERSION_REF	26,4,VR_GAME_CODE
	PL_P	$1975c,fast_copy
	VERSION_REF	27,4,VR_GAME_CODE
	PL_P	$1bf76,fast_picture
	; C5: shape draw path
	VERSION_REF	28,2,VR_EARLY_CODE
	PL_P	$0be6c,fast_image_remap
	VERSION_REF	29,4,VR_IMAGE_LOOKUP
	PL_P	$1dd9a,fast_get_image
	VERSION_REF	30,4,VR_IMAGE_LOOKUP
	PL_P	$1dd14,fast_get_image_checked
	VERSION_REF	31,4,VR_GAME_CODE
	PL_P	$1c802,fast_load_image
	VERSION_REF	32,4,VR_GAME_CODE
	PL_P	$1c694,fast_get_frame
	VERSION_REF	33,4,VR_GAME_CODE
	PL_P	$11904,fast_draw_table_image
	VERSION_REF	34,4,VR_GAME_CODE
	PL_P	$1c29c,fast_draw_shape
	VERSION_REF	35,4,VR_GAME_CODE
	PL_P	$1c8d6,fast_clip
	VERSION_REF	36,4,VR_GAME_CODE
	PL_P	$1cb94,fast_draw
	; C6: the full-room draw invalidates both display buffers once
	VERSION_REF	37,4,VR_GAME_CODE
	PL_P	$1173e,fast_draw_table_entry
	VERSION_REF	38,4,VR_GAME_CODE
	PL_P	$1bec8,fast_draw_rect
	VERSION_REF	39,2,VR_EARLY_CODE
	PL_PS	$0abfe,fast_draw_room_tables
	VERSION_REF	40,4,VR_GAME_CODE
	PL_P	$10c9a,fast_add_back
	VERSION_REF	41,4,VR_GAME_CODE
	PL_P	$10d52,fast_add_fore
	VERSION_REF	42,4,VR_GAME_CODE
	PL_P	$1b948,fast_random
	PL_ENDIF
	IFD	VERIFY
	PL_NEXT	pl_verify_v1
	ELSE
	PL_END
	ENDC

;---------------------------------------------------------------------------
; C6: room-decoration RNG and back/foreground table construction. Preserve the
; generator, its seed writes, table bytes (including untouched padding), and the
; original error paths. Small ranges avoid the compiled C division scaffolding.
fast_random
	move.l	4(sp),d0
	cmp.l	#$ffff,d0
	beq.b	.valid
	cmp.l	#32766,d0
	bhi.b	.original
.valid
	movem.l	d2-d3,-(sp)
	move.l	d0,d3
	move.l	_reloc_base(pc),a0
	VERSION_REF	43,2,VR_EARLY_DATA
	lea	($7cb6-$1000,a0),a0
	move.l	(a0),d0
	move.l	d0,d2
	move.w	d0,d1
	add.w	d1,d1
	add.w	d0,d1			; low(seed)*3, only its low word contributes
	mulu.w	#$43fd,d0
	swap	d2
	mulu.w	#$43fd,d2
	add.w	d1,d2
	swap	d2
	clr.w	d2
	add.l	d2,d0
	add.l	#$269ec3,d0
	move.l	d0,(a0)
	swap	d0
	and.l	#$ffff,d0
	cmp.l	#$ffff,d3
	beq.b	.out
	move.w	d3,d1
	addq.w	#1,d3
	move.w	d3,d2
	and.w	d1,d2
	bne.b	.divide
	and.w	d1,d0
	bra.b	.out
.divide
	divu.w	d3,d0
	clr.w	d0
	swap	d0
.out
	movem.l	(sp)+,d2-d3
	rts
.original
	link	a6,#0
	movem.l	d2-d3,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	44,4,VR_GAME_CODE
	add.l	#$1b950-$1000,a0
	jmp	(a0)

fast_add_back
	movem.l	d2/a2-a3,-(sp)
	VERSION_REF	45,4,VR_GLOBALS
	lea	$47d64,a2
	VERSION_REF	46,4,VR_GLOBALS
	lea	$47d78,a3
	bra.b	fast_add_layer
fast_add_fore
	movem.l	d2/a2-a3,-(sp)
	VERSION_REF	47,4,VR_GLOBALS
	lea	$47d68,a2
	VERSION_REF	48,4,VR_GLOBALS
	lea	$483b8,a3
fast_add_layer
	move.l	20(sp),d0		; image (1-based)
	beq.b	.none
	cmp.l	#256,d0
	beq.b	.none
	move.l	(a2),d1
	cmp.l	#200,d1
	bge.b	.original
	lsl.l	#3,d1
	add.l	d1,a3
	move.l	16(sp),d2		; table number
	move.l	d2,d1
	lsl.l	#2,d1
	VERSION_REF	49,4,VR_GLOBALS
	lea	$49aa8,a0
	subq.l	#1,d0
	move.l	(a0,d1.l),a0
	move.l	d0,d1
	move.l	a0,d0
	bsr.w	fast_image_lookup
	tst.l	d0
	beq.b	.none
	move.l	d0,a0
	moveq	#0,d1
	move.w	6(a0),d1
	and.w	#$3ff,d1
	move.b	27(sp),(a3)		; x in byte columns
	move.b	31(sp),1(a3)		; x pixel offset
	move.b	d2,4(a3)
	move.l	20(sp),d0
	subq.l	#1,d0
	move.b	d0,5(a3)
	move.l	32(sp),d0		; y minus height plus one
	sub.l	d1,d0
	addq.l	#1,d0
	move.w	d0,2(a3)
	move.b	39(sp),6(a3)
	addq.l	#1,(a2)
	moveq	#1,d0
	bra.b	.out
.none
	moveq	#0,d0
.out
	movem.l	(sp)+,d2/a2-a3
	rts
.original
	VERSION_REF	50,4,VR_GAME_CODE
	move.l	#$10ca2-$1000,d0
	VERSION_REF	51,4,VR_GLOBALS
	cmp.l	#$47d64,a2
	beq.b	.back
	VERSION_REF	52,4,VR_GAME_CODE
	move.l	#$10d5a-$1000,d0
.back
	movem.l	(sp)+,d2/a2-a3
	link	a6,#0
	movem.l	d2-d6/a2,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	d0,a0
	jmp	(a0)

;---------------------------------------------------------------------------
; C1 blitter waits. Every blit is complete on return, so existing register writes,
; in-place flips, scratch copies and display swaps keep their synchronous ordering.
; Poll twice for the old Agnus busy-bit latency; clear BLIT without disturbing VERTB.
; The original assembler entry preserves all registers and SR.
fast_blit_c
	move.l	4(sp),d0
fast_blit
	move.w	sr,-(sp)
fast_blit_start
	move.w	d0,_custom+bltsize
	bsr.b	fast_blit_wait
	move.w	(sp)+,sr
	rts

; VERIFY's optional sabotage entry saves SR at g:$053d4 and resumes at g:$053dc.
; Keep that continuation valid with its original saved-SR contract.
fast_blit_saved
	move.w	sr,-(sp)
	move.l	a0,-(sp)
	move.l	_reloc_base(pc),a0
	move.w	($053d4-$1000,a0),4(sp)
	move.l	(sp)+,a0
	bra.b	fast_blit_start

fast_blit_wait
	btst	#DMAB_BLTDONE-8,_custom+dmaconr
.busy
	btst	#DMAB_BLTDONE-8,_custom+dmaconr
	bne.b	.busy
	move.w	#INTF_BLIT,_custom+intreq
	move.w	#INTF_BLIT,_custom+intreq
	rts

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
	VERSION_REF	53,4,VR_GLOBALS
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
	VERSION_REF	54,4,VR_GLOBALS
	move.l	$49a94,d0		; curr_room_tiles
	move.b	(a0,d0.l),d0
	and.b	#$1f,d0
	VERSION_REF	55,4,VR_GLOBALS
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
	VERSION_REF	56,4,VR_GLOBALS
	move.l	$49aa0,a0
	move.b	(a0,d2.l),d2
	and.b	#$1f,d2
	cmp.b	#1,d2
	movem.l	(sp)+,d2		; keeps the flags
	rts

; load_curr_and_left_tile(), g:$108c6
fast_load_curr_and_left_tile
	; draw_room's ordinary row: a tile with no pending draw counters has no
	; draw_tile side effects. Keep column 9 so the final lookup globals match.
	move.l	_reloc_base(pc),d0
	VERSION_REF	57,4,VR_GAME_CODE
	add.l	#$115ea-$1000,d0
	cmp.l	(sp),d0
	bne.b	.above
	VERSION_REF	58,4,VR_GLOBALS
	move.l	$49a1a,d1
	cmp.l	#9,d1
	beq.w	.load
	VERSION_REF	59,4,VR_GLOBALS
	move.l	$49a16,d0
	lsl.l	#2,d0
	move.l	_reloc_base(pc),a0
	lea	($718a-$1000,a0),a0
	add.l	(a0,d0.l),d1
	VERSION_REF	60,4,VR_GLOBALS
	lea	$47c40,a0
	move.b	(a0,d1.l),d0
	or.b	$1e(a0,d1.l),d0
	or.b	$5a(a0,d1.l),d0
	or.b	$78(a0,d1.l),d0
	lea	$96(a0),a0
	or.b	(a0,d1.l),d0
	or.b	$1e(a0,d1.l),d0
	or.b	$3c(a0,d1.l),d0
	bne.w	.load
	move.l	(sp),d0
	add.l	#$115fa-$115ea,d0
	move.l	d0,-(sp)		; leave one dummy argument for 115fc's stack cleanup
	rts
.above
	add.l	#$11648-$115ea,d0
	cmp.l	(sp),d0
	bne.w	.load
	VERSION_REF	61,4,VR_GLOBALS
	move.l	$49a1a,d1
	cmp.l	#9,d1
	beq.w	.load
	VERSION_REF	62,4,VR_GLOBALS
	lea	$47d30,a0
	tst.b	(a0,d1.l)
	bne.w	.load
	add.l	#$11656-$11648,d0
	move.l	d0,-(sp)		; dummy argument for 11658's cleanup
	rts

.load
	movem.l	d2-d3,-(sp)
	VERSION_REF	63,4,VR_GLOBALS
	move.l	$49a16,d2		; drawn_row
	moveq	#20,d3			; tile_room0: wall, or floor on the bottom row
	moveq	#2,d0
	cmp.l	d2,d0
	bne.b	.wall
	moveq	#1,d3
.wall
	VERSION_REF	64,4,VR_GLOBALS
	move.l	$47b18,d0		; drawn_room
	VERSION_REF	65,4,VR_GLOBALS
	move.l	$49a1a,d1		; drawn_col
	bsr.w	tile_to_draw
	VERSION_REF	66,4,VR_GLOBALS
	move.b	d0,$47b60		; curr_tile
	VERSION_REF	67,4,VR_GLOBALS
	move.b	d1,$47b62		; curr_modifier
	VERSION_REF	68,4,VR_GLOBALS
	move.l	$47b18,d0
	VERSION_REF	69,4,VR_GLOBALS
	move.l	$49a1a,d1
	subq.l	#1,d1
	bsr.w	tile_to_draw
	VERSION_REF	70,4,VR_GLOBALS
	move.b	d0,$47b64		; tile_left
	VERSION_REF	71,4,VR_GLOBALS
	move.b	d1,$47b66		; modifier_left
	VERSION_REF	72,4,VR_GLOBALS
	move.l	$49a1a,d0
	add.l	d0,d0
	add.l	d0,d0
	add.l	_reloc_base(pc),d0
	move.l	d0,a0
	VERSION_REF	73,6,VR_GLOBALS
	move.l	($740a-$1000,a0),$49a1e	; draw_xh = g:$0740a[drawn_col]
	movem.l	(sp)+,d2-d3
	rts

; get_room_address(room), g:$11b96
fast_get_room_address
	move.l	4(sp),d1
fast_get_room_address_reg
	VERSION_REF	74,4,VR_GLOBALS
	cmp.l	$47d54,d1
	beq.b	.done
	VERSION_REF	75,4,VR_GLOBALS
	move.l	d1,$47d54		; loaded_room
	beq.b	.done
	move.l	d1,d0
	subq.l	#1,d0
	add.l	d0,d0
	move.l	d0,a0
	lsl.l	#4,d0
	sub.l	a0,d0			; (room-1)*30
	VERSION_REF	76,4,VR_GLOBALS
	lea	$470de,a0
	add.l	d0,a0
	VERSION_REF	77,4,VR_GLOBALS
	move.l	a0,$49a94		; curr_room_tiles
	VERSION_REF	78,4,VR_GLOBALS
	lea	$473ae,a0
	add.l	d0,a0
	VERSION_REF	79,4,VR_GLOBALS
	move.l	a0,$49a98		; curr_room_modif
.done
	rts


; The second foreground pass follows a restore of the background, which
; already contains those same foreground shapes. Only redraw shapes touched
; by intervening display writes. Keep all setup, flips and scratch side effects.
fast_fore_pass
	dc.w	0
fast_frame_active
	dc.w	0
fast_cache_stale
	dc.w	1
fast_draw_table
	move.l	d2,-(sp)
	move.w	fast_fore_pass(pc),d2
	lea	fast_fore_pass(pc),a0
	clr.w	(a0)
	move.l	_reloc_base(pc),d0
	VERSION_REF	80,4,VR_EARLY_CODE
	add.l	#$0bae6-$1000,d0
	cmp.l	4(sp),d0
	beq.b	.second
	sub.l	#$0bae6-$0bab8,d0
	cmp.l	4(sp),d0
	bne.b	.call
	move.w	#2,(a0)
	bra.b	.call
.second
	move.w	#1,(a0)
.call
	move.l	8(sp),-(sp)
	bsr.b	.original
	addq.l	#4,sp
	lea	fast_fore_pass(pc),a0
	move.w	d2,(a0)
	move.l	(sp)+,d2
	rts
.original
	link	a6,#0
	movem.l	d2-d5,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	81,4,VR_GAME_CODE
	add.l	#$116aa-$1000,a0
	jmp	(a0)

; d0 destination, d1..d2 lines, d3..d4 words. Return Z when its dirty
; words cannot overlap the shape. Inputs d1-d4 are preserved for fast_mark.
fast_fore_touched
	lea	fast_background_dirty(pc),a0
	VERSION_REF	82,4,VR_GLOBALS
	cmp.l	#BUF0,d0
	beq.b	.buffer
	lea	fast_dirty(pc),a0
	VERSION_REF	83,4,VR_GLOBALS
	cmp.l	#BUF1,d0
	beq.b	.buffer
	lea	BANDS*4(a0),a0
	VERSION_REF	84,4,VR_GLOBALS
	cmp.l	#BUF2,d0
	bne.b	.yes
.buffer
	cmp.l	#19,d4
	bhi.b	.yes
	cmp.l	#199,d2
	bhi.b	.yes
	movem.l	d1-d4,-(sp)
	lsl.w	#2,d3
	addq.w	#1,d4
	lsl.w	#2,d4
	lea	fast_dirty_prefix(pc),a1
	move.l	(a1,d3.w),d3
	move.l	(a1,d4.w),d4
	eor.l	d4,d3
	lsr.w	#4,d1
	lsr.w	#4,d2
	sub.w	d1,d2
	lsl.w	#2,d1
	add.w	d1,a0
.band
	move.l	(a0)+,d0
	and.l	d3,d0
	bne.b	.out
	dbf	d2,.band
.out
	movem.l	(sp)+,d1-d4
	rts
.yes
	moveq	#1,d0
	rts

; Give synchronous frame blits priority, preserving the incoming DMA setting.
fast_draw_frame
	move.l	d2,-(sp)
	lea	fast_cache_stale(pc),a0
	tst.w	(a0)
	beq.b	.cache_ready
	clr.w	(a0)
	lea	fast_fore_cache_data(pc),a0
	moveq	#FC_COUNT-1,d0
.invalidate
	clr.l	(a0)
	lea	FC_SIZE(a0),a0
	dbf	d0,.invalidate
.cache_ready
	lea	fast_frame_active(pc),a0
	move.w	#1,(a0)
	lea	fast_background_dirty(pc),a0
	moveq	#BANDS-1,d0
.clear_dirty
	clr.l	(a0)+
	dbf	d0,.clear_dirty
	move.w	_custom+dmaconr,d2
	and.w	#DMAF_BLITHOG,d2
	move.w	#DMAF_SETCLR!DMAF_BLITHOG,_custom+dmacon
	bsr.b	.original
	tst.w	d2
	bne.b	.keep
	move.w	#DMAF_BLITHOG,_custom+dmacon
.keep
	lea	fast_frame_active(pc),a0
	clr.w	(a0)
	move.l	(sp)+,d2
	rts
.original
	link	a6,#-8
	movem.l	d2/a2,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	85,4,VR_EARLY_CODE
	add.l	#$0ba5e-$1000,a0
	jmp	(a0)

; Common row-coordinate range: identical signed divide/remainder result.
fast_y_to_row
	move.l	4(sp),d0
	add.l	#60,d0
	cmp.l	#315,d0
	bcc.b	.original
	lea	.rows(pc),a0
	move.b	(a0,d0.w),d0
	ext.w	d0
	ext.l	d0
	rts
.original
	link	a6,#0
	movem.l	d2-d3,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	86,4,VR_GAME_CODE
	add.l	#$131b8-$1000,a0
	jmp	(a0)
.rows
	dcb.b	63,-1
	dcb.b	63,0
	dcb.b	63,1
	dcb.b	63,2
	dcb.b	63,-1
	even

; Decode collision image dimensions without the compiled signed-divide scaffold.
fast_collision_dimensions
	link	a6,#0
	movem.l	d2/a2,-(sp)
	VERSION_REF	87,4,VR_GLOBALS
	lea	$49b3e,a2
	moveq	#0,d1
	VERSION_REF	88,4,VR_GLOBALS
	move.b	$49b5c,d1
	cmp.b	#255,d1
	beq.b	.none
	moveq	#0,d0
	VERSION_REF	89,4,VR_GLOBALS
	move.b	$49b5e,d0
	lsl.w	#2,d0
	VERSION_REF	90,4,VR_GLOBALS
	lea	$49aa8,a0
	move.l	(a0,d0.w),d0
	bsr.w	fast_image_lookup
	tst.l	d0
	beq.b	.none
	move.l	d0,a0
	moveq	#0,d2
	move.w	4(a0),d2
	and.w	#$3ff,d2
	moveq	#0,d1
	move.w	6(a0),d1
	and.w	#$3ff,d1
	bra.b	.dimensions
.none
	moveq	#0,d2
	moveq	#0,d1
.dimensions
	move.l	d2,d0
	addq.l	#1,d0
	lsr.l	#1,d0
	VERSION_REF	91,4,VR_GLOBALS
	move.l	d0,$49b32
	VERSION_REF	92,4,VR_GLOBALS
	move.l	d1,$49b2e
	move.l	_reloc_base(pc),a0
	VERSION_REF	93,4,VR_GAME_CODE
	add.l	#$13620-$1000,a0
	jmp	(a0)

; Fixed, disjoint 18-byte character records; preserve memcpy's return value.
fast_record_131f0
	VERSION_REF	94,4,VR_GLOBALS
	lea	$479b0,a1
	VERSION_REF	95,4,VR_GLOBALS
	lea	$4798c,a0
	move.l	a0,d0
	REPT	4
	move.l	(a1)+,(a0)+
	ENDR
	move.w	(a1)+,(a0)+
	rts
fast_record_1320e
	VERSION_REF	96,4,VR_GLOBALS
	lea	$4798c,a1
	VERSION_REF	97,4,VR_GLOBALS
	lea	$479b0,a0
	move.l	a0,d0
	REPT	4
	move.l	(a1)+,(a0)+
	ENDR
	move.w	(a1)+,(a0)+
	rts
fast_record_1322c
	VERSION_REF	98,4,VR_GLOBALS
	lea	$479c2,a1
	VERSION_REF	99,4,VR_GLOBALS
	lea	$4798c,a0
	move.l	a0,d0
	REPT	4
	move.l	(a1)+,(a0)+
	ENDR
	move.w	(a1)+,(a0)+
	rts
fast_record_1324a
	VERSION_REF	100,4,VR_GLOBALS
	lea	$4798c,a1
	VERSION_REF	101,4,VR_GLOBALS
	lea	$479c2,a0
	move.l	a0,d0
	REPT	4
	move.l	(a1)+,(a0)+
	ENDR
	move.w	(a1)+,(a0)+
	rts
fast_record_13268
	bsr.w	fast_record_131f0
	VERSION_REF	102,4,VR_GLOBALS
	lea	$479c2,a1
	VERSION_REF	103,4,VR_GLOBALS
	lea	$4799e,a0
	move.l	a0,d0
	REPT	4
	move.l	(a1)+,(a0)+
	ENDR
	move.w	(a1)+,(a0)+
	rts
fast_record_1328a
	bsr.w	fast_record_1320e
	VERSION_REF	104,4,VR_GLOBALS
	lea	$4799e,a1
	VERSION_REF	105,4,VR_GLOBALS
	lea	$479c2,a0
	move.l	a0,d0
	REPT	4
	move.l	(a1)+,(a0)+
	ENDR
	move.w	(a1)+,(a0)+
	rts
fast_record_132ac
	bsr.w	fast_record_1322c
	VERSION_REF	106,4,VR_GLOBALS
	lea	$479b0,a1
	VERSION_REF	107,4,VR_GLOBALS
	lea	$4799e,a0
	move.l	a0,d0
	REPT	4
	move.l	(a1)+,(a0)+
	ENDR
	move.w	(a1)+,(a0)+
	rts
fast_record_132ce
	bsr.w	fast_record_1324a
	VERSION_REF	108,4,VR_GLOBALS
	lea	$4799e,a1
	VERSION_REF	109,4,VR_GLOBALS
	lea	$479b0,a0
	move.l	a0,d0
	REPT	4
	move.l	(a1)+,(a0)+
	ENDR
	move.w	(a1)+,(a0)+
	rts

; Collision tile lookup. Keep all original globals, including tilepos when room=0.
fast_get_tile
	movem.l	d2/a2,-(sp)
	VERSION_REF	110,4,VR_GLOBALS
	lea	$49b74,a2
	move.l	12(sp),(a2)
	move.l	16(sp),4(a2)
	move.l	20(sp),8(a2)
fast_get_tile_body
	bsr.w	fast_find_room
	tst.l	d0
	beq.b	.wall
	move.l	d0,d1
	bsr.w	fast_get_room_address_reg
	move.l	8(a2),d0
	lsl.l	#2,d0
	move.l	_reloc_base(pc),a0
	lea	($718a-$1000,a0),a0
	move.l	(a0,d0.l),d0
	add.l	4(a2),d0
	move.b	d0,-2(a2)
	and.l	#$ff,d0
	VERSION_REF	111,4,VR_GLOBALS
	move.l	$49a94,a0
	move.b	(a0,d0.l),d0
	and.l	#31,d0
	bra.b	.store
.wall
	moveq	#20,d0
.store
	move.b	d0,-4(a2)
	movem.l	(sp)+,d2/a2
	rts

fast_get_tile_regs
	movem.l	d2/a2,-(sp)
	VERSION_REF	112,4,VR_GLOBALS
	lea	$49b74,a2
	movem.l	d0-d2,(a2)
	bra.w	fast_get_tile_body

; check_collisions(row, room-array, flags-array), g:$14e8c. Look up the
; tile once, derive both wall edges, and retain every original global write.
fast_check_collisions
	movem.l	d2-d7/a2-a3,-(sp)
	movem.l	36(sp),d4-d6
	VERSION_REF	113,4,VR_GLOBALS
	move.b	$47995,d7
	ext.w	d7
	ext.l	d7
	VERSION_REF	114,4,VR_GLOBALS
	move.b	$49b88,d3
	ext.w	d3
	ext.l	d3
	move.l	_reloc_base(pc),a2
	move.l	d3,d0
	addq.l	#5,d0
	lea	($73ea-$1000,a2),a0
	moveq	#0,d1
	move.b	(a0,d0.l),d1
	addq.l	#7,d1
	VERSION_REF	115,4,VR_GLOBALS
	move.l	d1,$49b0e
	VERSION_REF	116,4,VR_GLOBALS
	lea	$49b74,a3
	bra.w	.test
.column
	move.l	d7,d0
	move.l	d3,d1
	move.l	d4,d2
	bsr.w	fast_get_tile_regs
	moveq	#0,d2
	move.b	.types(pc,d0.w),d2
	move.l	#255,d0
	moveq	#0,d1
	tst.w	d2
	beq.b	.edges
	lea	($73fe-$1000,a2),a0
	move.b	(a0,d2.w),d0
	ext.w	d0
	ext.l	d0
	VERSION_REF	117,4,VR_GLOBALS
	add.l	$49b0e,d0
	move.b	6(a0,d2.w),d1
	ext.w	d1
	ext.l	d1
	neg.l	d1
	VERSION_REF	118,4,VR_GLOBALS
	add.l	$49b0e,d1
	add.l	#13,d1
.edges
	moveq	#0,d2
	VERSION_REF	119,4,VR_GLOBALS
	cmp.l	$49b3a,d0
	bge.b	.right
	moveq	#15,d2
.right
	VERSION_REF	120,4,VR_GLOBALS
	cmp.l	$49b36,d1
	ble.b	.store
	or.b	#$f0,d2
.store
	move.l	4(a3),a0
	move.b	d2,(a0,d6.l)
	move.b	3(a3),(a0,d5.l)
	VERSION_REF	121,8,VR_GLOBALS
	add.l	#14,$49b0e
	addq.l	#1,d3
.test
	VERSION_REF	122,4,VR_GLOBALS
	move.b	$49b8a,d0
	ext.w	d0
	ext.l	d0
	cmp.l	d3,d0
	bge.w	.column
	movem.l	(sp)+,d2-d7/a2-a3
	rts
.types
	dc.b	0,0,0,0,1,0,0,1,0,0,0,0,1,2,0,0
	dc.b	0,0,3,0,4,0,0,0,0,0,0,0,0,0,0,0

; Follow horizontal links first, then vertical, as the recursive original does.
fast_find_room
	VERSION_REF	123,4,VR_GLOBALS
	lea	$49b74,a0
.loop
	move.l	4(a0),d0
	cmp.l	#10,d0
	bcs.b	.row
	tst.l	d0
	bpl.b	.right
	bra.b	.left
.row
	move.l	8(a0),d0
	cmp.l	#3,d0
	bcs.b	.done
	tst.l	d0
	bmi.b	.up
	bra.b	.down
.done
	move.l	(a0),d0
	rts
.left
	add.l	#10,4(a0)
	moveq	#0,d1
	bra.b	.link
.right
	sub.l	#10,4(a0)
	moveq	#1,d1
	bra.b	.link
.up
	addq.l	#3,8(a0)
	moveq	#2,d1
	bra.b	.link
.down
	subq.l	#3,8(a0)
	moveq	#3,d1
.link
	move.l	(a0),d0
	beq.b	.loop
	subq.l	#1,d0
	lsl.l	#2,d0
	add.l	d1,d0
	VERSION_REF	124,4,VR_GLOBALS
	lea	$4787e,a1
	move.b	(a1,d0.l),d0
	and.l	#$ff,d0
	move.l	d0,(a0)
	bra.b	.loop

;---------------------------------------------------------------------------
; C4 logic hot spots (draw_room's row loads, check_collisions).

; load_leftroom(), g:$10942: leftroom_[row] = the left room's column 9
fast_load_leftroom
	movem.l	d2-d3/a2,-(sp)
	VERSION_REF	125,4,VR_GLOBALS
	move.l	$47b1c,-(sp)		; room_L
	bsr.w	fast_get_room_address
	addq.l	#4,sp
	VERSION_REF	126,4,VR_GLOBALS
	lea	$499fc,a2		; leftroom_
	moveq	#0,d2
.row
	VERSION_REF	127,4,VR_GLOBALS
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
	VERSION_REF	128,4,VR_GLOBALS
	cmp.l	$49a16,d0		; drawn_row
	bne.b	.same
	VERSION_REF	129,4,VR_GLOBALS
	move.l	$47b28,d4		; room_B
	VERSION_REF	130,4,VR_GLOBALS
	move.l	$47b34,d5		; room_BL
	moveq	#0,d2
	bra.b	.rooms
.same
	VERSION_REF	131,4,VR_GLOBALS
	move.l	$47b18,d4		; drawn_room
	VERSION_REF	132,4,VR_GLOBALS
	move.l	$47b1c,d5		; room_L
	VERSION_REF	133,4,VR_GLOBALS
	move.l	$49a16,d2
	addq.l	#1,d2
.rooms
	move.l	d4,-(sp)
	bsr.w	fast_get_room_address
	addq.l	#4,sp
	VERSION_REF	134,4,VR_GLOBALS
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
	VERSION_REF	135,4,VR_GLOBALS
	move.b	d0,$49a02
	VERSION_REF	136,4,VR_GLOBALS
	move.b	d1,$49a02+1
	VERSION_REF	137,4,VR_GLOBALS
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
	VERSION_REF	138,4,VR_GAME_CODE
	add.l	#$14f28-$1000,d0
	cmp.l	(sp),d0
	bne.b	.get_tile
	moveq	#0,d0
	VERSION_REF	139,4,VR_GLOBALS
	move.b	$49b70,d0
	bra.b	.wall
.get_tile
	move.l	12(sp),-(sp)
	move.l	12(sp),-(sp)
	move.l	12(sp),-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	140,4,VR_GAME_CODE
	add.l	#$12bea-$1000,a0
	jsr	(a0)
	lea	12(sp),sp
.wall
	move.l	d0,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	141,4,VR_GAME_CODE
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
	VERSION_REF	142,4,VR_GLOBALS
	add.l	$49b0e,d0
	sub.l	d1,d0
.done
	rts

;---------------------------------------------------------------------------
; C2(b) partial screen restore. Each frame g:$094e4 copies the room background, buffer 0,
; onto the hidden display buffer (40,000 bytes). This keeps, for each display buffer, the
; parts that may differ from buffer 0 and copies only those: what was drawn into the display
; buffer since its last restore, and what changed in buffer 0. Every write to the three
; buffers goes through the routines hooked here.
;
; Each of 13 bands covers 16 lines (the last covers 8). A long holds one bit
; per 16-pixel word column. Zero is clean. Copies retain gaps between dirty runs.
; A third table tracks changes to the background during the current frame.

BUF0 = $49fee				; room background
BUF1 = $53c2e				; display buffers
BUF2 = $5d86e
BUF_SIZE = 40000
PLANE_SIZE = $1f40
BANDS = 13

fast_dirty
	dcb.l	BANDS,$000fffff		; buffer 1: all dirty until the first full copy
	dcb.l	BANDS,$000fffff		; buffer 2
fast_background_dirty
	dcb.l	BANDS,$000fffff

fast_full_room
	dc.w	0

; g:$0aba0's full-room draw_tables call. Buffer 0 is rebuilt in full; no
; per-shape dirty marks are needed until the ordinary frame drawing resumes.
fast_draw_room_tables
	movem.l	d0-d4/a0-a1,-(sp)
	lea	fast_fore_cache_data(pc),a0
	moveq	#FC_COUNT-1,d0
.clear_cache
	clr.l	(a0)
	lea	FC_SIZE(a0),a0
	dbf	d0,.clear_cache
	VERSION_REF	143,4,VR_GLOBALS
	move.l	#BUF0,d0
	bsr.w	fast_mark_all
	lea	fast_full_room(pc),a0
	move.w	#1,(a0)
	; All draws wait synchronously: give their blits priority over the polling
	; CPU, and restore the incoming priority bit before ordinary drawing.
	move.w	_custom+dmaconr,d2
	and.w	#DMAF_BLITHOG,d2
	move.w	#DMAF_SETCLR!DMAF_BLITHOG,_custom+dmacon
	move.l	_reloc_base(pc),a0
	VERSION_REF	144,4,VR_EARLY_CODE
	add.l	#$0bafa-$1000,a0
	jsr	(a0)
	tst.w	d2
	bne.b	.keep_hog
	move.w	#DMAF_BLITHOG,_custom+dmacon
.keep_hog
	lea	fast_full_room(pc),a0
	clr.w	(a0)
	movem.l	(sp)+,d0-d4/a0-a1
	rts

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
	lsr.w	#4,d1			; bands
	lsr.w	#4,d2
	lea	fast_dirty(pc),a0
	VERSION_REF	145,4,VR_GLOBALS
	sub.l	#BUF0,d0
	bcs.b	.out
	cmp.l	#BUF_SIZE,d0
	bcs.b	.both
	sub.l	#BUF_SIZE,d0
	cmp.l	#BUF_SIZE,d0
	bcs.b	.bands
	lea	BANDS*4(a0),a0
	sub.l	#BUF_SIZE,d0
	cmp.l	#BUF_SIZE,d0
	bcs.b	.bands
.out
	rts
.both
	move.w	fast_frame_active(pc),d0
	bne.b	.in_frame
	lea	fast_cache_stale(pc),a1
	move.w	#1,(a1)
.in_frame
	bsr.b	.range
.all_band
	or.l	d3,(a1)
	or.l	d3,BANDS*4(a1)
	or.l	d3,BANDS*8(a1)
	addq.l	#4,a1
	dbf	d0,.all_band
	rts
.bands
	bsr.b	.range
.band
	or.l	d3,(a1)+
	dbf	d0,.band
	rts
.range
	lsl.w	#2,d3
	addq.w	#1,d4
	lsl.w	#2,d4
	lea	fast_dirty_prefix(pc),a1
	move.l	(a1,d3.w),d3
	move.l	(a1,d4.w),d4
	eor.l	d4,d3
	move.w	d1,d0
	lsl.w	#2,d0
	lea	(a0,d0.w),a1
	move.w	d2,d0
	sub.w	d1,d0
	rts

; Inclusive columns d3-d4 -> d3 bitmask. d4 and a1 are scratch.
fast_dirty_prefix
	dc.l	$0,$1,$3,$7,$f,$1f,$3f,$7f,$ff,$1ff,$3ff,$7ff,$fff,$1fff,$3fff,$7fff,$ffff,$1ffff,$3ffff,$7ffff,$fffff

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
	move.w	fast_full_room(pc),d0
	bne.w	.draw
	movem.l	d2-d4,-(sp)
	moveq	#0,d1
	VERSION_REF	146,4,VR_GLOBALS
	move.w	$67522,d1
	moveq	#0,d2
	VERSION_REF	147,4,VR_GLOBALS
	move.w	$6750e,d2
	add.l	d1,d2
	subq.l	#1,d2
	moveq	#0,d3
	VERSION_REF	148,4,VR_GLOBALS
	move.w	$67524,d3
	moveq	#0,d4
	VERSION_REF	149,4,VR_GLOBALS
	move.w	$67520,d4
	VERSION_REF	150,4,VR_GLOBALS
	move.w	$67526,d0
	VERSION_REF	151,4,VR_GLOBALS
	cmp.w	$67516,d0
	bge.b	.right
	VERSION_REF	152,4,VR_GLOBALS
	move.w	$67510,d0
	cmp.w	d0,d4
	beq.b	.right
	addq.l	#1,d4
.right
	add.l	d3,d4
	subq.l	#1,d4
	move.w	fast_fore_pass(pc),d0
	beq.b	.mark
	cmp.w	#2,d0
	beq.b	.mark
	VERSION_REF	153,4,VR_GLOBALS
	move.l	$674ba,d0
	bsr.w	fast_fore_touched
	bne.b	.mark
	movem.l	(sp)+,d2-d4
	rts
.mark
	VERSION_REF	154,4,VR_GLOBALS
	move.l	$674ba,d0
	bsr.w	fast_mark
	movem.l	(sp)+,d2-d4
.draw
	link	a6,#0
	movem.l	d2-d7/a2-a4,-(sp)
	move.l	_reloc_base(pc),a0
	add.l	#$0568e-$1000,a0
	jmp	(a0)

; Narrow horizontal flips: flatten the plane/row loop and unroll byte pairs.
; The original lookup table reverses each byte; all image planes include the mask.
fast_flip_horizontal
	move.l	8(sp),d0
	subq.l	#1,d0
	cmp.l	#1,d0
	bhi.w	.original
	movem.l	d2-d4/a2-a3,-(sp)
	move.l	24(sp),a0
	move.l	28(sp),d4
	move.l	32(sp),d2
	move.l	36(sp),d3
	lea	$52f8,a2
	moveq	#0,d0
	move.b	(a2,d3.w),d0
	addq.w	#1,d0
	mulu.w	d0,d2
	subq.l	#1,d2
	lea	$51b8,a3
	moveq	#0,d0
	moveq	#0,d1
	cmp.w	#1,d4
	bne.b	.two
.one
	move.b	(a0),d0
	move.b	1(a0),d1
	move.b	(a3,d1.w),(a0)+
	move.b	(a3,d0.w),(a0)+
	dbf	d2,.one
	bra.b	.out
.two
	lea	4(a0),a1
.row
	tst.l	(a0)
	beq.b	.zero
	move.b	(a0),d0
	move.b	-(a1),d1
	move.b	(a3,d1.w),(a0)+
	move.b	(a3,d0.w),(a1)
	move.b	(a0),d0
	move.b	-(a1),d1
	move.b	(a3,d1.w),(a0)+
	move.b	(a3,d0.w),(a1)
	addq.l	#2,a0
	addq.l	#6,a1
	dbf	d2,.row
	bra.b	.out
.zero
	addq.l	#4,a0
	addq.l	#4,a1
	dbf	d2,.row
.out
	movem.l	(sp)+,d2-d4/a2-a3
	rts
.original
	link	a6,#0
	movem.l	d2-d7/a2-a4,-(sp)
	move.l	_reloc_base(pc),a0
	jmp	($055d2-$1000,a0)

; Expanded right-shift: one masked copy instead of clear then OR.
fast_shape_expand
	VERSION_REF	155,4,VR_GLOBALS
	tst.l	$6750a
	bne.b	.original
	VERSION_REF	156,4,VR_GLOBALS
	tst.l	$674f6
	bne.b	.original
	moveq	#0,d5
	moveq	#40,d0
	VERSION_REF	157,4,VR_GLOBALS
	sub.w	$67520,d0
	VERSION_REF	158,4,VR_GLOBALS
	sub.w	$67520,d0
	move.l	#$fffe0000,d1
	move.w	d0,d1
	swap	d0
	move.w	#-2,d0
	move.l	d0,d2
	move.l	#$ffff0000,d3
	move.w	d7,d4
	or.w	#$0fca,d4
	swap	d4
	move.w	d7,d4
	VERSION_REF	159,4,VR_GLOBALS
	move.w	$6750e,d0
	lsl.w	#6,d0
	VERSION_REF	160,4,VR_GLOBALS
	or.w	$67520,d0
	move.l	_reloc_base(pc),a0
	jmp	($0581a-$1000,a0)
.original
	moveq	#0,d5
	; The six-byte entry patch also overwrites move.w #-1,d0's opcode.
	move.w	#-1,d0
	move.l	_reloc_base(pc),a0
	jmp	($05910-$1000,a0)

; Reuse single-part foreground setup across passes. Across frames, only
; immutable terrain images qualify; full-room drawing and background writes
; outside a frame invalidate it. Keys include entry, clip and image header.
; Clipped, scratch-backed and custom-mask shapes retain normal setup.
FC_SIZE = 172
FC_COUNT = 64
fast_fore_cache_active
	dc.l	0
fast_fore_cache_parts
	dc.w	0
fast_fore_cache_next
	dc.w	0
fast_fore_cache_data
	dcb.b	FC_SIZE*FC_COUNT,0

; Called with the entry wrapper's saved registers still on the stack.
fast_fore_cache_enter
	lea	fast_fore_cache_active(pc),a0
	clr.l	(a0)
	move.w	fast_fore_pass(pc),d0
	beq.w	.miss
	cmp.l	#1,44(sp)
	bne.w	.miss
	move.l	48(sp),d1
	cmp.l	#200,d1
	bcc.w	.miss
	move.l	d1,d7
	lsl.l	#3,d1
	VERSION_REF	161,4,VR_GLOBALS
	lea	$483b8,a1
	add.l	d1,a1
	move.l	(a1),d1
	move.l	4(a1),d0
	eor.l	d0,d1
	move.l	d1,d0
	swap	d0
	eor.w	d0,d1
	move.w	d1,d0
	lsr.w	#8,d0
	eor.w	d0,d1
	and.w	#FC_COUNT/4-1,d1
	mulu.w	#FC_SIZE*4,d1
	lea	fast_fore_cache_data(pc),a3
	add.l	d1,a3
	move.l	a3,a4
	move.l	(a1),d2
	move.l	4(a1),d3
	moveq	#3,d1
.find
	tst.l	(a3)
	beq.w	.miss_entry
	cmp.l	4(a3),d2
	bne.b	.next
	cmp.l	8(a3),d3
	beq.b	.reuse
.next
	lea	FC_SIZE(a3),a3
	dbf	d1,.find
	move.l	a4,a3
	lea	fast_fore_cache_next(pc),a0
	addq.w	#1,(a0)
	move.w	(a0),d1
	and.w	#3,d1
	mulu.w	#FC_SIZE,d1
	add.l	d1,a3
	bra.w	.miss_entry
.reuse
	move.l	_reloc_base(pc),a0
	VERSION_REF	162,2,VR_EARLY_DATA
	lea	($7e42-$1000,a0),a0
	lea	12(a3),a1
	REPT	5
	cmpm.l	(a0)+,(a1)+
	bne.w	.miss_entry
	ENDR
	move.l	40(a3),a0
	move.w	fast_fore_pass(pc),d0
	cmp.w	#2,d0
	bne.b	.header
	VERSION_REF	163,4,VR_GLOBALS
	cmp.l	#$674be,a0
	bcs.w	.miss_entry
	cmp.l	#$80000,a0
	bcc.w	.miss_entry
.header
	move.l	(a0),d0
	cmp.l	32(a3),d0
	bne.w	.miss_entry
	move.l	4(a0),d0
	cmp.l	36(a3),d0
	bne.w	.miss_entry
	moveq	#0,d7
	move.b	10(a3),d7
	and.b	#$7f,d7
	cmp.b	#3,d7
	bne.b	.colour_ok
	move.l	_reloc_base(pc),a0
	move.w	($64c2-$1000,a0),d0
	and.w	#31,d0
	cmp.w	40+$67502-SHAPE(a3),d0
	bne.w	.miss_entry
.colour_ok
	; Restore assigned fields, preserving whichever tag colours were unused.
	VERSION_REF	164,4,VR_GLOBALS
	move.w	$67502,d6
	swap	d6
	VERSION_REF	165,4,VR_GLOBALS
	move.w	$67508,d6
	lea	40(a3),a0
	VERSION_REF	166,4,VR_GLOBALS
	lea	SHAPE,a2
	REPT	4
	movem.l	(a0)+,d0-d5/a1/a4
	movem.l	d0-d5/a1/a4,(a2)
	lea	32(a2),a2
	ENDR
	move.w	(a0),(a2)
	cmp.b	#9,d7
	beq.b	.colour8
	cmp.b	#64,d7
	bcc.b	.colour8
	VERSION_REF	167,4,VR_GLOBALS
	move.w	d6,$67508
.colour8
	swap	d6
	cmp.b	#3,d7
	beq.b	.colour7
	VERSION_REF	168,4,VR_GLOBALS
	move.w	d6,$67502
.colour7
	move.w	fast_fore_pass(pc),-(sp)
	lea	fast_fore_pass(pc),a0
	move.w	#3,(a0)
	bsr.w	fast_shape
	lea	fast_fore_pass(pc),a0
	move.w	(sp)+,(a0)
	moveq	#1,d0
	rts
.miss_entry
	move.w	fast_fore_pass(pc),d0
	cmp.w	#2,d0
	bne.b	.miss
	clr.l	(a3)
	lea	fast_fore_cache_active(pc),a0
	move.l	a3,(a0)
	clr.w	4(a0)
.miss
	moveq	#0,d0
	rts

fast_fore_cache_save
	move.l	fast_fore_cache_active(pc),d1
	beq.w	.out
	move.l	d1,a3
	tst.l	d0
	beq.w	.out
	move.w	fast_fore_cache_parts(pc),d1
	cmp.w	#1,d1
	bne.w	.out
	VERSION_REF	169,4,VR_GLOBALS
	lea	SHAPE,a0
	tst.l	$674da-SHAPE(a0)
	bne.w	.out
	tst.l	$674e2-SHAPE(a0)
	bne.w	.out
	tst.l	$674e6-SHAPE(a0)
	bne.w	.out
	tst.l	$674f6-SHAPE(a0)
	bne.w	.out
	move.l	48(sp),d1
	lsl.l	#3,d1
	VERSION_REF	170,4,VR_GLOBALS
	lea	$483b8,a0
	add.l	d1,a0
	moveq	#0,d1
	move.b	6(a0),d1
	and.b	#$7f,d1
	beq.b	.mode
	cmp.b	#2,d1
	beq.b	.mode
	cmp.b	#16,d1
	beq.b	.mode
	cmp.b	#3,d1
	beq.b	.mode
	cmp.b	#9,d1
	beq.b	.mode
	cmp.b	#64,d1
	bcs.w	.out
	cmp.b	#95,d1
	bhi.w	.out
.mode
	move.l	(a0)+,4(a3)
	move.l	(a0),8(a3)
	move.l	_reloc_base(pc),a0
	VERSION_REF	171,2,VR_EARLY_DATA
	lea	($7e42-$1000,a0),a0
	lea	12(a3),a1
	moveq	#4,d1
.clip
	move.l	(a0)+,(a1)+
	dbf	d1,.clip
	VERSION_REF	172,4,VR_GLOBALS
	move.l	SHAPE,a0
	move.l	(a0)+,(a1)+
	move.l	(a0),(a1)+
	VERSION_REF	173,4,VR_GLOBALS
	lea	SHAPE,a0
	REPT	4
	movem.l	(a0)+,d1-d7/a4
	movem.l	d1-d7/a4,(a1)
	lea	32(a1),a1
	ENDR
	move.w	(a0),(a1)
	move.l	#1,(a3)
.out
	rts

; g:$1bec8(buffer, rect, colour): validate once, mark once, set the common
; geometry once for all five planes. Rectangles use exclusive right/bottom.
; With A DMA disabled, BLTADAT=$ffff and the first/last masks supply A.
; $0a clears (C & ~A); $fa sets (C | A). A true full-width fill needs only D.
fast_draw_rect
	movem.l	d2-d7/a2-a4,-(sp)
	move.l	44(sp),a4
	move.l	40(sp),d0
	cmp.l	#4,d0
	bhi.w	.original
	move.w	(a4),d0
	bmi.w	.original
	move.w	2(a4),d1
	bmi.w	.original
	cmp.w	4(a4),d0
	bge.w	.original
	cmp.w	6(a4),d1
	bge.w	.original
	cmp.w	#320,4(a4)
	bgt.w	.original
	cmp.w	#200,6(a4)
	bgt.w	.original
	move.l	40(sp),d0
	cmp.w	#3,d0
	beq.b	.shown
	cmp.w	#4,d0
	beq.b	.target
	lsl.w	#2,d0
	move.l	_reloc_base(pc),a0
	VERSION_REF	174,4,VR_EARLY_DATA
	add.l	#$7d0a-$1000,a0
	move.l	(a0,d0.w),d0
	bra.b	.buffer
.shown
	VERSION_REF	175,4,VR_GLOBALS
	move.l	$674b2,d0
	bra.b	.buffer
.target
	VERSION_REF	176,4,VR_GLOBALS
	move.l	$674ba,d0
.buffer
	move.l	d0,a3
	move.w	fast_full_room(pc),d1
	beq.b	.mark
	VERSION_REF	177,4,VR_GLOBALS
	cmp.l	#BUF0,a3
	beq.b	.setup
.mark
	moveq	#0,d1
	move.w	2(a4),d1
	moveq	#0,d2
	move.w	6(a4),d2
	subq.w	#1,d2
	moveq	#0,d3
	move.w	(a4),d3
	lsr.w	#4,d3
	moveq	#0,d4
	move.w	4(a4),d4
	subq.w	#1,d4
	lsr.w	#4,d4
	bsr.w	fast_mark
.setup
	lea	_custom,a2
	moveq	#0,d0
	move.w	2(a4),d0
	mulu.w	#40,d0
	add.l	d0,a3
	move.w	(a4),d0
	move.w	d0,d2
	lsr.w	#4,d2
	add.w	d2,d2
	add.w	d2,a3
	lsr.w	#1,d2
	moveq	#15,d1
	and.w	d0,d1
	moveq	#-1,d3
	lsr.w	d1,d3
	move.w	4(a4),d0
	subq.w	#1,d0
	move.w	d0,d4
	lsr.w	#4,d4
	sub.w	d2,d4
	addq.w	#1,d4
	moveq	#15,d1
	and.w	d0,d1
	moveq	#15,d0
	sub.w	d1,d0
	moveq	#-1,d2
	lsl.w	d0,d2
	move.w	d3,bltafwm(a2)
	move.w	d2,bltalwm(a2)
	moveq	#40,d0
	sub.w	d4,d0
	sub.w	d4,d0
	move.w	d0,bltcmod(a2)
	move.w	d0,bltdmod(a2)
	clr.w	bltcon1(a2)
	move.w	6(a4),d5
	sub.w	2(a4),d5
	lsl.w	#6,d5
	or.w	d4,d5
	move.w	#$030a,d2
	move.w	#$03fa,d3
	move.w	4(a4),d0
	sub.w	(a4),d0
	cmp.w	#320,d0
	bne.b	.masked
	move.w	#$0100,d2
	move.w	#$01ff,d3
.masked
	move.l	48(sp),d7
	moveq	#4,d6
.plane
	move.w	d2,d0
	asr.l	#1,d7
	bcc.b	.colour
	move.w	d3,d0
.colour
	move.w	d0,bltcon0(a2)
	move.w	#-1,bltadat(a2)
	move.l	a3,bltcpt(a2)
	move.l	a3,bltdpt(a2)
	move.w	d5,d0
	bsr.w	fast_blit
	add.l	#PLANE_SIZE,a3
	dbf	d6,.plane
	move.l	d7,d0
	movem.l	(sp)+,d2-d7/a2-a4
	rts
.original
	movem.l	(sp)+,d2-d7/a2-a4
	link	a6,#-8
	movem.l	d2-d7/a2-a4,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	178,4,VR_GAME_CODE
	add.l	#$1bed0-$1000,a0
	jmp	(a0)

; g:$199e0(plane, x, y, width, height, ...): rectangle fill (draw_rect)
fast_rect_fill
	; A word-aligned full-width fill needs only D DMA. The original reads
	; the old plane through A and B even when neither edge needs masking.
	tst.l	8(sp)
	bne.b	.original
	cmp.l	#320,16(sp)
	bne.b	.original
	cmp.l	#20,24(sp)
	bne.b	.original
	move.l	20(sp),d0
	beq.b	.original
	cmp.l	#1024,d0
	bhi.b	.original
	movem.l	d2-d4,-(sp)
	lea	16(sp),a0
	bsr.w	fast_mark_rect
	move.l	24(sp),d0		; y
	move.l	d0,d1
	lsl.l	#3,d0
	lsl.l	#5,d1
	add.l	d1,d0
	add.l	16(sp),d0		; plane
	move.l	d0,_custom+bltdpt
	clr.w	_custom+bltdmod
	move.l	#$01000000,d0
	tst.l	40(sp)			; colour
	beq.b	.clear
	or.l	#$00ff0000,d0
.clear
	move.l	d0,_custom+bltcon0
	move.l	32(sp),d0		; height
	lsl.w	#6,d0
	or.w	#20,d0
	bsr.w	fast_blit
	movem.l	(sp)+,d2-d4
	rts
.original
	movem.l	d2-d4,-(sp)
	lea	16(sp),a0
	bsr.b	fast_mark_rect
	movem.l	(sp)+,d2-d4
	link	a6,#-4
	movem.l	d2-d7,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	179,4,VR_GAME_CODE
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
	VERSION_REF	180,4,VR_GAME_CODE
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
	VERSION_REF	181,4,VR_GAME_CODE
	add.l	#$1980a-$1000,a0
	jmp	(a0)

; g:$1bf76: a picture into a buffer, partly by the CPU
fast_picture
	lea	fast_cache_stale(pc),a0
	move.w	#1,(a0)
	lea	fast_dirty(pc),a0
	moveq	#BANDS*3-1,d0
.all
	move.l	#$000fffff,(a0)+
	dbf	d0,.all
	link	a6,#-4
	movem.l	d2-d6/a2-a4,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	182,4,VR_GAME_CODE
	add.l	#$1bf7e-$1000,a0
	jmp	(a0)

; g:$1975c(words, source, destination): copy. The full copy of buffer 0 onto a display
; buffer copies only the dirty parts. Outside the gameplay frame (g:$094e4) the whole of it
; is dirtied first, and so is the other display buffer.
fast_copy
	cmp.l	#BUF_SIZE/2,4(sp)
	bne.b	.other
	VERSION_REF	183,4,VR_GLOBALS
	cmp.l	#BUF0,8(sp)
	bne.b	.other
	lea	fast_dirty(pc),a0
	lea	BANDS*4(a0),a1
	move.l	12(sp),d0
	VERSION_REF	184,4,VR_GLOBALS
	cmp.l	#BUF1,d0
	beq.b	.display
	exg	a0,a1
	VERSION_REF	185,4,VR_GLOBALS
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
	VERSION_REF	186,4,VR_GAME_CODE
	add.l	#$19764-$1000,a0
	jmp	(a0)
.display				; a0 this buffer's table, a1 the other's
	move.l	_reloc_base(pc),d0
	VERSION_REF	187,4,VR_EARLY_CODE
	add.l	#$094f4-$1000,d0	; return address of g:$094e4's call of g:$1bd5e
	cmp.l	4(a6),d0		; a6 is g:$1bd5e's frame
	beq.b	.restore
	moveq	#BANDS-1,d0
.all
	move.l	#$000fffff,(a0)+
	move.l	#$000fffff,(a1)+
	dbf	d0,.all
	lea	-BANDS*4(a0),a0
.restore
	movem.l	d2-d7/a2-a4,-(sp)
	move.l	12+36(sp),a3		; destination
	move.l	a0,a1
	move.w	#INTF_BLIT,_custom+intena	; no blitter interrupts: the waits poll
	moveq	#0,d2			; band
.scan
	cmp.w	#BANDS,d2
	beq.w	.done
	move.l	(a1),d6
	bne.b	.group
	addq.l	#4,a1
	addq.w	#1,d2
	bra.b	.scan
.group
	move.w	d2,d5
.more
	clr.l	(a1)+
	addq.w	#1,d2
	cmp.w	#BANDS,d2
	beq.b	.bounds
	cmp.l	(a1),d6
	beq.b	.more
.bounds
	moveq	#0,d3
	move.l	d6,d0
.left
	lsr.l	#1,d0
	bcs.b	.left_found
	addq.w	#1,d3
	bra.b	.left
.left_found
	move.w	d3,d4
.right
	btst	#0,d0
	beq.b	.run_end
	lsr.l	#1,d0
	addq.w	#1,d4
	bra.b	.right
.run_end
	move.l	d0,a4
.blit
	move.w	d5,d6
	mulu	#16*40,d6
	add.w	d3,d6
	add.w	d3,d6			; offset in the plane
	move.w	d2,d7
	lsl.w	#4,d7
	cmp.w	#200,d7
	bls.b	.height
	move.w	#200,d7
.height
	move.w	d5,d0
	lsl.w	#4,d0
	sub.w	d0,d7			; lines
	lsl.w	#6,d7
	move.w	d4,d0
	sub.w	d3,d0
	addq.w	#1,d0			; words
	or.w	d0,d7			; BLTSIZE
	moveq	#20,d1
	sub.w	d0,d1
	add.w	d1,d1			; modulo
	VERSION_REF	188,4,VR_GLOBALS
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
	move.l	a4,d0
	beq.w	.scan
	move.w	d4,d3
	addq.w	#1,d3
	bra.w	.left
.done
	bsr.b	.waitblit
	move.w	#INTF_BLIT,_custom+intreq
	move.w	#INTF_BLIT,_custom+intreq	; also acknowledge on machines with delayed IRQ clear
	movem.l	(sp)+,d2-d7/a2-a4
	rts
.waitblit
	btst	#DMAB_BLTDONE-8,_custom+dmaconr
.busy
	btst	#DMAB_BLTDONE-8,_custom+dmaconr
	bne.b	.busy
	rts

;---------------------------------------------------------------------------
; C5 shape draw path. The image draw g:$11904 goes through a tag-list
; graphics library: g:$1c29c parses the tags, g:$1c694 picks the image, g:$1c8d6 clips and
; g:$1cb94 sets up the blits. These are the same routines with register code in place of
; the compiled C; their memory writes and results are the same.

; image_remap(&chtab, &id), g:$0be6c: the kid's two tables ($7f928, $7fa90) are split into
; eight per image range (g:$06310, two tables per range); other tables are left alone
fast_image_remap
	move.l	4(sp),a1
	moveq	#0,d0
	VERSION_REF	189,4,VR_BOOT_TABLES
	cmp.l	#$7f928,(a1)
	beq.b	.kid
	VERSION_REF	190,4,VR_BOOT_TABLES
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
	move.l	8(sp),d1
; d0 table, d1 image. The common path uses no argument copies or remap calls.
fast_image_lookup
	tst.l	d0
	beq.b	.done
	move.l	d0,a0
	moveq	#0,d0
	move.w	8(a0),d0
	cmp.l	d1,d0
	bls.b	.none
	cmp.l	#142,d1
	bhi.b	.lookup
	VERSION_REF	191,4,VR_BOOT_TABLES
	cmp.l	#$7f928,a0
	beq.b	.remap
	VERSION_REF	192,4,VR_BOOT_TABLES
	cmp.l	#$7fa90,a0
	beq.b	.remap
.lookup
	move.l	(a0),a1
	move.l	8(a1),d0
	add.l	10(a0),d0
	move.l	d0,a0
	lsl.l	#2,d1
	move.l	(a0,d1.l),d1
	add.l	d1,d1
	add.l	d1,d0
	rts
.remap
	move.l	d1,-(sp)
	move.l	a0,-(sp)
	bsr.w	fast_get_image_checked
	addq.l	#8,sp
	rts
.none
	moveq	#0,d0
.done
	rts

; get_image_checked(chtab, id), g:$1dd14: the same without the checks (the original asserts)
fast_get_image_checked
	cmp.l	#142,8(sp)
	bhi.b	.remapped
	VERSION_REF	193,4,VR_BOOT_TABLES
	cmp.l	#$7f928,4(sp)
	beq.b	.remap
	VERSION_REF	194,4,VR_BOOT_TABLES
	cmp.l	#$7fa90,4(sp)
	bne.b	.remapped
.remap
	pea	8(sp)
	pea	8(sp)
	bsr.w	fast_image_remap
	addq.l	#8,sp
.remapped
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
; C6: the table renderer already looked up the first image for its dimensions.
; d0 is that image; decode it without repeating the remap and table lookup.
fast_load_image_header
	move.l	d0,a0
	VERSION_REF	195,4,VR_GLOBALS
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
	VERSION_REF	196,4,VR_GLOBALS
	mulu.w	$674c8,d0
	move.w	d0,(a1)+		; $674d8 plane size
	moveq	#0,d0
	VERSION_REF	197,8,VR_GLOBALS
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
	VERSION_REF	198,4,VR_GAME_CODE
	add.l	#$1c69c-$1000,a0
	jmp	(a0)

; g:$1173e: decode a back/foreground record into the table renderer's
; registers. Signed byte coordinates and the unsigned image/mode are unchanged.
fast_draw_table_entry
	move.l	4(sp),d0
	cmp.l	#1,d0
	bhi.b	.original
	movem.l	d2-d7/a2-a4,-(sp)
	bsr.w	fast_fore_cache_enter
	tst.l	d0
	bne.w	.cached
	move.l	40(sp),d0
	VERSION_REF	199,4,VR_GLOBALS
	lea	$47d78,a1
	tst.l	d0
	beq.b	.table
	VERSION_REF	200,4,VR_GLOBALS
	lea	$483b8,a1
.table
	move.l	44(sp),d0
	lsl.l	#3,d0
	add.l	d0,a1
	moveq	#0,d0
	move.b	4(a1),d0
	lsl.w	#2,d0
	VERSION_REF	201,4,VR_GLOBALS
	lea	$49aa8,a0
	move.l	(a0,d0.w),d2
	moveq	#0,d3
	move.b	5(a1),d3
	move.b	(a1),d4
	ext.w	d4
	lsl.w	#3,d4
	move.b	1(a1),d0
	ext.w	d0
	add.w	d0,d4
	ext.l	d4
	move.w	2(a1),d5
	ext.l	d5
	moveq	#0,d6
	move.b	6(a1),d6
	move.l	d6,-(sp)			; mode argument cleared by flipped draws
	move.l	sp,a4
	bsr.w	fast_table_image_core
	addq.l	#4,sp
	bsr.w	fast_fore_cache_save
.cached
	movem.l	(sp)+,d2-d7/a2-a4
	rts
.original
	link	a6,#0
	movem.l	d2-d4,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	202,4,VR_GAME_CODE
	add.l	#$11746-$1000,a0
	jmp	(a0)

; draw_table_image(table, image, x, y, mode), g:$11904. Decode its modes
; directly into the tag state, then enter the shared draw core with registers.
; Unusual/asserting modes retain the original diagnostics and library fallback.
fast_draw_table_image
	movem.l	d2-d7/a2-a4,-(sp)
	movem.l	40(sp),d2-d6
	lea	56(sp),a4
	bsr.w	fast_table_image_core
	movem.l	(sp)+,d2-d7/a2-a4
	rts

; Retain a kid-table remap for the subsequent shape setup and part selection.
; The original table's bounds check still precedes remapping.
fast_table_image_lookup
	move.l	d2,a0
	moveq	#0,d0
	move.w	8(a0),d0
	cmp.l	d3,d0
	bls.b	.none
	cmp.l	#142,d3
	bhi.b	.lookup
	VERSION_REF	203,4,VR_BOOT_TABLES
	cmp.l	#$7f928,d2
	beq.b	.kid
	VERSION_REF	204,4,VR_BOOT_TABLES
	cmp.l	#$7fa90,d2
	bne.b	.lookup
.kid
	move.l	d3,-(sp)
	move.l	d2,-(sp)
	pea	4(sp)
	pea	4(sp)
	bsr.w	fast_image_remap
	addq.l	#8,sp
	movem.l	(sp)+,d2-d3
.lookup
	move.l	d2,a1
	move.l	(a1),a0
	move.l	8(a0),d0
	add.l	10(a1),d0
	move.l	d0,a0
	move.l	d3,d1
	lsl.l	#2,d1
	move.l	(a0,d1.l),d1
	add.l	d1,d1
	add.l	d1,d0
	rts
.none
	moveq	#0,d0
	rts

; d2-d6: table, image, x, y, mode; a4 points to the writable mode argument.
fast_table_image_core
	move.l	d6,d0
	and.l	#~$80,d0
	beq.b	.mode_ok
	cmp.l	#2,d0
	beq.b	.mode_ok
	cmp.l	#3,d0
	beq.b	.mode_ok
	cmp.l	#9,d0
	beq.b	.mode_ok
	cmp.l	#16,d0
	beq.b	.mode_ok
	cmp.l	#64,d0
	blo.w	.orig
	cmp.l	#95,d0
	bhi.w	.orig
.mode_ok
	tst.l	d2
	beq.w	.orig
	move.l	d2,a0
	cmp.b	#2,4(a0)
	bcc.w	.orig
	bsr.w	fast_table_image_lookup
	tst.l	d0
	beq.w	.out
	move.l	d0,a1
	move.l	d0,a3
	bsr.w	fast_reset_tags
	moveq	#0,d0
	move.w	4(a1),d0
	and.w	#$3ff,d0
	btst	#7,d6
	beq.b	.unflipped
	sub.l	d0,d4
	VERSION_REF	205,8,VR_GLOBALS
	move.l	#1,$674ee
	and.l	#~$80,d6
	move.l	d6,(a4)			; original clears bit 7 in its caller's argument
.unflipped
	; (dimension-1)/2, with signed division rounding toward zero for zero
	move.l	d0,d1
	beq.b	.xhalf
	subq.l	#1,d1
	lsr.l	#1,d1
.xhalf
	add.l	d1,d4
	moveq	#0,d0
	move.w	6(a1),d0
	and.w	#$3ff,d0
	move.l	d0,d1
	beq.b	.yhalf
	subq.l	#1,d1
	lsr.l	#1,d1
.yhalf
	sub.l	d5,d1
	sub.l	d0,d1
	add.l	#200,d1
	move.l	d1,d5
	cmp.l	#2,d6
	beq.b	.nomask
	cmp.l	#3,d6
	beq.b	.mask
	cmp.l	#9,d6
	beq.b	.silhouette
	cmp.l	#64,d6
	blo.b	.draw
	move.w	d6,d0
	and.w	#31,d0
	VERSION_REF	206,4,VR_GLOBALS
	move.w	d0,$67508
	bra.b	.silhouette
.nomask
	VERSION_REF	207,8,VR_GLOBALS
	move.l	#1,$6750a
	bra.b	.draw
.mask
	VERSION_REF	208,8,VR_GLOBALS
	move.l	#1,$674fe
	move.l	_reloc_base(pc),a0
	move.w	($64c0-$1000+2,a0),d0
	and.w	#31,d0
	VERSION_REF	209,4,VR_GLOBALS
	move.w	d0,$67502
	bra.b	.draw
.silhouette
	; mode 9 explicitly supplies zero; the unused colour word otherwise survives
	cmp.l	#9,d6
	bne.b	.colour
	VERSION_REF	210,4,VR_GLOBALS
	clr.w	$67508
.colour
	VERSION_REF	211,8,VR_GLOBALS
	move.l	#1,$67504
.draw
	bra.w	fast_draw_shape_core
.out
	rts
.orig
	move.l	d6,-(sp)
	move.l	d5,-(sp)
	move.l	d4,-(sp)
	move.l	d3,-(sp)
	move.l	d2,-(sp)
	bsr.b	.original
	move.l	16(sp),(a4)
	lea	20(sp),sp
	rts
.original
	link	a6,#0
	movem.l	d2-d7/a2-a3,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	212,4,VR_GAME_CODE
	add.l	#$1190c-$1000,a0
	jmp	(a0)

fast_reset_tags
	; clear the tags' state as g:$1c578 does
	VERSION_REF	213,4,VR_GLOBALS
	lea	$674de,a0
	moveq	#0,d0
	move.l	d0,4(a0)
	move.l	d0,8(a0)
	move.l	d0,12(a0)
	move.l	d0,16(a0)
	move.l	d0,20(a0)
	move.l	d0,24(a0)
	move.l	d0,32(a0)
	move.l	d0,38(a0)
	move.l	d0,44(a0)
	rts

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
	bsr.w	fast_reset_tags
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
	VERSION_REF	214,6,VR_GLOBALS
	move.w	2(a4),$674ea
	VERSION_REF	215,6,VR_GLOBALS
	move.w	6(a4),$674ec
	addq.l	#8,a4
	bra.w	.tag
.t1
	VERSION_REF	216,6,VR_GLOBALS
	move.w	2(a4),$674ea
	addq.l	#4,a4
	bra.w	.tag
.t2
	VERSION_REF	217,6,VR_GLOBALS
	move.w	2(a4),$674ec
	addq.l	#4,a4
	bra.w	.tag
.t3
	VERSION_REF	218,4,VR_GLOBALS
	move.l	(a4)+,$674ee
	VERSION_REF	219,4,VR_GLOBALS
	move.l	(a4)+,$674f2
	bra.w	.tag
.t4
	VERSION_REF	220,4,VR_GLOBALS
	move.l	(a4)+,$674ee
	bra.w	.tag
.t5
	VERSION_REF	221,4,VR_GLOBALS
	move.l	(a4)+,$674f2
	bra.w	.tag
.t6
	VERSION_REF	222,4,VR_GLOBALS
	move.l	(a4)+,$674f6
	VERSION_REF	223,4,VR_GLOBALS
	move.l	(a4)+,$674fa
	bra.w	.tag
.t7
	VERSION_REF	224,4,VR_GLOBALS
	move.l	(a4)+,$674fe
	moveq	#31,d0
	and.w	2(a4),d0
	VERSION_REF	225,4,VR_GLOBALS
	move.w	d0,$67502
	addq.l	#4,a4
	bra.w	.tag
.t8
	VERSION_REF	226,4,VR_GLOBALS
	move.l	(a4)+,$67504
	moveq	#31,d0
	and.w	2(a4),d0
	VERSION_REF	227,4,VR_GLOBALS
	move.w	d0,$67508
	addq.l	#4,a4
	bra.w	.tag
.t9
	VERSION_REF	228,4,VR_GLOBALS
	move.l	(a4)+,$6750a
	bra.w	.tag
.tags_done
	sub.l	a3,a3			; no preloaded first image from the tag-list entry
	bsr.w	fast_draw_shape_core
	movem.l	(sp)+,d2-d5/a2-a4
	rts
.orig
	movem.l	(sp)+,d2-d5/a2-a4
	link	a6,#-8
	movem.l	d2-d5/a2-a4,-(sp)
	move.l	_reloc_base(pc),a0
	VERSION_REF	229,4,VR_GAME_CODE
	add.l	#$1c2a4-$1000,a0
	jmp	(a0)

; d2 table, d3 image, d4 x, d5 y; a3 optional first image; tags already set.
; Preserved by callers. Chained parts always use their own image lookup.
fast_draw_shape_core
	cmp.l	#142,d3
	bhi.b	.remapped
	VERSION_REF	230,4,VR_BOOT_TABLES
	cmp.l	#$7f928,d2
	beq.b	.remap
	VERSION_REF	231,4,VR_BOOT_TABLES
	cmp.l	#$7fa90,d2
	bne.b	.remapped
.remap
	move.l	d3,-(sp)
	move.l	d2,-(sp)
	pea	4(sp)
	pea	4(sp)
	bsr.w	fast_image_remap
	addq.l	#8,sp
	movem.l	(sp)+,d2-d3
.remapped
	move.l	d2,a0
	moveq	#0,d0
	move.b	5(a0),d0
	cmp.l	d0,d3
	bcs.b	.first_valid
	sub.l	a3,a3			; retain get_frame's out-of-range diagnostics
.first_valid
	sub.l	a2,a2			; drawn
	sub.l	a4,a4			; first part
.part
	lea	fast_fore_cache_parts(pc),a0
	addq.w	#1,(a0)
	move.l	a3,d0
	beq.b	.lookup
	sub.l	a3,a3
	bsr.w	fast_load_image_header
	move.l	d5,-(sp)
	move.l	d4,-(sp)
	bsr.w	fast_clip
	addq.l	#8,sp
	bra.b	.clipped
.lookup
	move.l	d3,-(sp)
	move.l	d2,-(sp)
	bsr.w	fast_get_frame
	move.l	d5,(sp)
	move.l	d4,-(sp)
	bsr.w	fast_clip
	lea	12(sp),sp
.clipped
	tst.l	d0
	beq.b	.next
	bsr.w	fast_draw
	move.w	#1,a2
.next
	; Eight first-part tables continue 14 bytes later; $7fc1a continues
	; only when reached as the second part of $7fc0c.
	VERSION_REF	232,4,VR_BOOT_TABLES
	cmp.l	#$7f706,d2
	bcs.w	.done
	VERSION_REF	233,4,VR_BOOT_TABLES
	cmp.l	#$7fc1a,d2
	bhi.w	.done
	VERSION_REF	234,4,VR_BOOT_TABLES
	cmp.l	#$7f706,d2
	beq.b	.found
	VERSION_REF	235,4,VR_BOOT_TABLES
	cmp.l	#$7f738,d2
	beq.b	.found
	VERSION_REF	236,4,VR_BOOT_TABLES
	cmp.l	#$7f76a,d2
	beq.b	.found
	VERSION_REF	237,4,VR_BOOT_TABLES
	cmp.l	#$7fb44,d2
	beq.b	.found
	VERSION_REF	238,4,VR_BOOT_TABLES
	cmp.l	#$7fb76,d2
	beq.b	.found
	VERSION_REF	239,4,VR_BOOT_TABLES
	cmp.l	#$7fba8,d2
	beq.b	.found
	VERSION_REF	240,4,VR_BOOT_TABLES
	cmp.l	#$7fbda,d2
	beq.b	.found
	VERSION_REF	241,4,VR_BOOT_TABLES
	cmp.l	#$7fc0c,d2
	beq.b	.found
	VERSION_REF	242,4,VR_BOOT_TABLES
	cmp.l	#$7fc1a,d2
	bne.b	.done
	move.l	a4,d0
	bne.b	.found
.done
	move.l	a2,d0
	rts
.found
	add.l	#14,d2
	move.w	#1,a4
	bra.w	.part

; The loaded image and its blit state, from load_image's header to the plane pointers
SHAPE = $674be

; clip_image(x, y), g:$1c8d6: places the loaded image at x, y in the clip rectangle
; (g:$07e42: origin x, -, origin y, -, left, right, bottom, top; words) and sets its target
; position $674de-$674e1 and the lines and columns clipped off each edge $674e2-$674e9
; > d0 0 if nothing is left
fast_clip
	movem.l	d2-d3,-(sp)
	VERSION_REF	243,4,VR_GLOBALS
	lea	SHAPE,a0
	move.l	$674ee-SHAPE(a0),d0
	or.l	$674f2-SHAPE(a0),d0
	bne.w	.general
	move.l	_reloc_base(pc),a1
	VERSION_REF	244,2,VR_EARLY_DATA
	lea	($7e42-$1000,a1),a1
	move.w	$674c6-SHAPE(a0),d0
	beq.w	.general
	subq.w	#1,d0
	move.w	d0,d1
	lsr.w	#1,d0
	move.w	14(sp),d2
	add.w	$674ea-SHAPE(a0),d2
	sub.w	$674ca-SHAPE(a0),d2
	sub.w	d0,d2
	cmp.w	12(a1),d2
	blt.w	.general
	add.w	d2,d1
	cmp.w	14(a1),d1
	bgt.w	.general
	move.w	$674c8-SHAPE(a0),d0
	beq.b	.general
	subq.w	#1,d0
	move.w	d0,d1
	lsr.w	#1,d0
	move.w	18(sp),d3
	add.w	$674ec-SHAPE(a0),d3
	sub.w	$674cc-SHAPE(a0),d3
	sub.w	d0,d3
	cmp.w	18(a1),d3
	blt.b	.general
	add.w	d3,d1
	cmp.w	16(a1),d1
	bgt.b	.general
	sub.w	12(a1),d2
	add.w	(a1),d2
	move.w	d2,$674de-SHAPE(a0)
	move.w	6(a1),d0
	subq.w	#1,d0
	sub.w	d1,d0
	add.w	18(a1),d0
	move.w	d0,$674e0-SHAPE(a0)
	clr.l	$674e2-SHAPE(a0)
	clr.l	$674e6-SHAPE(a0)
	moveq	#1,d0
	movem.l	(sp)+,d2-d3
	rts
.general
	movem.l	(sp)+,d2-d3
	movem.l	d2-d6/a2,-(sp)
	move.w	4+24+2(sp),d1		; x
	move.w	8+24+2(sp),d3		; y
	move.l	_reloc_base(pc),a2
	VERSION_REF	245,4,VR_EARLY_DATA
	add.l	#$7e42-$1000,a2
	VERSION_REF	246,4,VR_GLOBALS
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
	VERSION_REF	247,4,VR_GLOBALS
	lea	SHAPE,a0
	bsr.w	.setup
	bsr.w	.flip
	VERSION_REF	248,4,VR_GLOBALS
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
	VERSION_REF	249,4,VR_GLOBALS
	lea	SHAPE,a0
	tst.l	$674f6-SHAPE(a0)
	beq.b	.ptrs
	move.l	$674fa-SHAPE(a0),-(sp)
	move.l	_reloc_base(pc),a0
	jsr	($055a6-$1000,a0)
	addq.l	#4,sp
.ptrs
	VERSION_REF	250,4,VR_GLOBALS
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
	VERSION_REF	251,4,VR_GLOBALS
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
	VERSION_REF	252,4,VR_GLOBALS
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
	VERSION_REF	253,4,VR_GLOBALS
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
	VERSION_REF	254,4,VR_GLOBALS
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
	VERSION_REF	255,4,VR_GLOBALS
	move.l	a1,$6753c
.planes_done
	rts
