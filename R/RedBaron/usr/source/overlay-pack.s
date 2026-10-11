; Pack completed pixels plus independent coverage into a bounded CPU cache.
; a0=40000-byte framebuffer, a1=8000-byte mask, a2=5208-byte output,
; a3=12-byte descriptor: left byte, top, row bytes, rows, plane bytes, total.
; d0=1 success, 0 empty/too large. Other registers preserved; CCR volatile.
; Pixels outside coverage are zeroed, so cached data never retains background.
overlay_pack:
	movem.l d1-d7/a0-a6,-(sp)
	move.l a1,a4
	moveq #40,d2
	moveq #0,d3
	move.w #200,d4
	moveq #0,d5
	moveq #0,d1
.scan_row
	moveq #0,d0
.scan_byte
	tst.b (a4)+
	beq .scan_next
	move.w d0,d6
	andi.w #$fffe,d6
	cmp.w d2,d6
	bhs .left_ready
	move.w d6,d2
.left_ready
	addq.w #2,d6
	cmp.w d3,d6
	bls .right_ready
	move.w d6,d3
.right_ready
	cmp.w d4,d1
	bhs .top_ready
	move.w d1,d4
.top_ready
	move.w d1,d5
	addq.w #1,d5
.scan_next
	addq.w #1,d0
	cmpi.w #40,d0
	blo .scan_byte
	addq.w #1,d1
	cmpi.w #200,d1
	blo .scan_row
	tst.w d3
	beq .fail
	sub.w d2,d3
	sub.w d4,d5
	move.w d3,d6
	mulu.w d5,d6
	move.l d6,d7
	mulu.w #6,d7
	cmpi.l #5208,d7
	bhi .fail
	move.w d2,(a3)
	move.w d4,2(a3)
	move.w d3,4(a3)
	move.w d5,6(a3)
	move.w d6,8(a3)
	move.w d7,10(a3)
	mulu.w #40,d4
	add.w d2,d4
	adda.w d4,a0
	adda.w d4,a1
	moveq #40,d4
	sub.w d3,d4 ; source row gap
	moveq #4,d7
.plane
	move.l a1,a4
	move.l a0,a5
	move.w 6(a3),d6
	subq.w #1,d6
.row
	move.w d3,d5
	subq.w #1,d5
.byte
	move.b (a5)+,d0
	and.b (a4)+,d0
	move.b d0,(a2)+
	dbf d5,.byte
	adda.w d4,a4
	adda.w d4,a5
	dbf d6,.row
	adda.l #8000,a0
	dbf d7,.plane
	move.l a1,a4
	move.w 6(a3),d6
	subq.w #1,d6
.mask_row
	move.w d3,d5
	subq.w #1,d5
.mask_byte
	move.b (a4)+,(a2)+
	dbf d5,.mask_byte
	adda.w d4,a4
	dbf d6,.mask_row
	moveq #1,d0
	bra .done
.fail
	moveq #0,d0
.done
	movem.l (sp)+,d1-d7/a0-a6
	rts

; Capture-only private pack after the original draw. Never runs the blitter or
; writes the game framebuffer; free both private allocations before returning.
overlay_pack_verify:
overlay_pack_save_ccr: dc.w $40e7 ; installer changes to MOVE CCR on 010+
	movem.l d0-a6,-(sp)
	lea overlay_mask_result(pc),a4
	tst.l (a4)
	beq overlay_pack_verify_done
	cmpi.l #1,4(a4)
	bne overlay_pack_free_mask
	lea overlay_pack_result(pc),a5
	move.l 8(a4),8(a5)
	move.l 12(a4),12(a5)
	move.l 4.w,a6
	move.l #5240,d0
	moveq #0,d1
	jsr _LVOAllocMem(a6)
	move.l d0,(a5)
	beq overlay_blit_bad
	move.l d0,a0
	move.w #1309,d0
.fill
	move.l #$a55ac33c,(a0)+
	dbf d0,.fill
	lea .h3_base(pc),a0
.h3_base
	adda.l #time_loop_h3-.h3_base,a0
	move.l (a0),a0
	adda.l #$9d72,a0
	move.l (a0),a0
	move.l (a4),a1
	lea 16(a1),a1
	move.l (a5),a2
	lea 16(a2),a2
	lea 16(a5),a3
	bsr overlay_pack
	move.l d0,4(a5)
overlay_pack_observed:
	nop
	move.l 4.w,a6
	move.l (a5),a1
	move.l #5240,d0
	jsr _LVOFreeMem(a6)
	clr.l (a5)
overlay_pack_free_mask:
	move.l 4.w,a6
	move.l (a4),a1
	move.l #8032,d0
	jsr _LVOFreeMem(a6)
	clr.l (a4)
overlay_pack_verify_done:
	movem.l (sp)+,d0-a6
	move.w (sp)+,ccr
	rts
overlay_pack_result: dc.l 0,0,0,0 ; allocation, supported, program, count
	dc.w 0,0,0,0,0,0 ; descriptor
