; VERIFY-only persistent CPU cache twin. Original game drawing always runs.
; Retain one packed allocation per front program across the four diagnostic
; calls, replay onto private pre-draw pixels, and compare the full native output.
overlay_shadow_before:
	movem.l d0-a6,-(sp)
	lea overlay_mask_result(pc),a0
	tst.l (a0)
	beq .done
	cmpi.l #1,4(a0)
	bne .done
	lea overlay_shadow_result(pc),a5
	move.l 4.w,a6
	move.l #40032,d0
	moveq #0,d1
	jsr _LVOAllocMem(a6)
	move.l d0,8(a5)
	beq overlay_blit_bad
	move.l d0,a1
	move.l #$a55ac33c,d1
	move.l d1,(a1)+
	move.l d1,(a1)+
	move.l d1,(a1)+
	move.l d1,(a1)+
	move.l a1,a0
	adda.l #40000,a0
	move.l d1,(a0)+
	move.l d1,(a0)+
	move.l d1,(a0)+
	move.l d1,(a0)+
	lea .h3_base(pc),a0
.h3_base
	adda.l #time_loop_h3-.h3_base,a0
	move.l (a0),a0
	adda.l #$9d72,a0
	move.l (a0),a0
	move.l a0,32(a5)
	move.w #9999,d0
.copy
	move.l (a0)+,(a1)+
	dbf d0,.copy
.done
	movem.l (sp)+,d0-a6
	rts

overlay_shadow_after:
	movem.l d0-a6,-(sp)
	lea overlay_shadow_result(pc),a5
	tst.l 8(a5)
	beq overlay_shadow_done
	addq.l #1,20(a5)
	clr.l 24(a5)
	clr.l 28(a5)
	clr.l 64(a5)
	lea overlay_pack_result(pc),a3
	cmpi.l #1,4(a3)
	bne .unsupported
	move.l 8(a3),d0
	move.l d0,36(a5)
	subq.l #3,d0
	cmpi.l #1,d0
	bhi .unsupported
	lsl.w #2,d0
	move.l a5,a4
	adda.w d0,a4 ; selected persistent pointer
	mulu.w #3,d0
	lea 40(a5),a2
	adda.w d0,a2 ; selected saved descriptor
	lea 16(a3),a3
	tst.l (a4)
	bne .hit
	move.l 4.w,a6
	move.l #5240,d0
	moveq #0,d1
	jsr _LVOAllocMem(a6)
	move.l d0,(a4)
	beq overlay_blit_bad
	move.l d0,a1
	move.l overlay_pack_result(pc),a0
	move.w #1309,d0
.seed
	move.l (a0)+,(a1)+
	dbf d0,.seed
	move.l (a3),(a2)
	move.l 4(a3),4(a2)
	move.l 8(a3),8(a2)
	addq.l #1,16(a5)
	bra .replay
.hit
	moveq #2,d0
	move.l a2,a0
	move.l a3,a1
.geometry
	cmpm.l (a0)+,(a1)+
	bne .unsupported
	dbf d0,.geometry
	addq.l #1,12(a5)
.replay
	move.l (a4),d0
	move.l d0,64(a5)
	move.l d0,a0
	lea 16(a0),a0
	moveq #0,d0
	move.w 8(a3),d0
	mulu.w #5,d0
	move.l a0,a1
	adda.l d0,a1
	move.l 8(a5),a2
	lea 16(a2),a2
	bsr overlay_replay_cpu
	move.l 8(a5),a0
	lea 16(a0),a0
	move.l 32(a5),a1
	moveq #0,d1
	move.w #39999,d0
.compare
	addq.l #1,d1
	cmpm.b (a0)+,(a1)+
	beq .next
	addq.l #1,24(a5)
	tst.l 28(a5)
	bne .next
	move.l d1,28(a5) ; first differing byte + 1
.next
	dbf d0,.compare
	bra overlay_shadow_observed
.unsupported
	addq.l #1,68(a5)
overlay_shadow_observed:
	nop
	move.l 4.w,a6
	move.l 8(a5),a1
	move.l #40032,d0
	jsr _LVOFreeMem(a6)
	clr.l 8(a5)
overlay_shadow_done:
	movem.l (sp)+,d0-a6
	rts

; End of each mask attempt, including unsupported pack/mask cases. The mask
; attempt count owns the bounded lifetime, so a rejected fourth attempt cannot
; leave an earlier successful cache allocated.
overlay_shadow_cleanup:
	movem.l d0/a0-a1/a5-a6,-(sp)
	lea overlay_mask_result(pc),a0
	cmpi.l #4,12(a0)
	blo .done
	lea overlay_shadow_result(pc),a5
	move.l 4.w,a6
	move.l (a5),d0
	beq .second
	move.l d0,a1
	move.l #5240,d0
	jsr _LVOFreeMem(a6)
	clr.l (a5)
.second
	move.l 4(a5),d0
	beq .cleared
	move.l d0,a1
	move.l #5240,d0
	jsr _LVOFreeMem(a6)
	clr.l 4(a5)
.cleared
	clr.l 64(a5)
.done
	movem.l (sp)+,d0/a0-a1/a5-a6
	rts

; a0=packed image, a1=packed mask, a2=full private framebuffer, a3=descriptor.
; Independent native expression old XOR ((old XOR image) AND mask).
; Descriptor came from the bounded packer and matches the retained cache.
; Preserve every register; CCR volatile. No hardware or game-memory writes.
overlay_replay_cpu:
	movem.l d0-a6,-(sp)
	moveq #0,d0
	move.w 2(a3),d0
	mulu.w #40,d0
	add.w (a3),d0
	adda.l d0,a2
	move.w 4(a3),d3
	moveq #40,d4
	sub.w d3,d4
	move.w 6(a3),d2
	mulu.w #40,d2
	neg.l d2
	addi.l #8000,d2
	moveq #4,d7
.plane
	move.l a1,a4
	move.w 6(a3),d6
	subq.w #1,d6
.row
	move.w d3,d5
	subq.w #1,d5
.byte
	move.b (a2),d0
	move.b (a0)+,d1
	eor.b d0,d1
	and.b (a4)+,d1
	eor.b d0,d1
	move.b d1,(a2)+
	dbf d5,.byte
	adda.w d4,a2
	dbf d6,.row
	adda.l d2,a2
	dbf d7,.plane
	movem.l (sp)+,d0-a6
	rts

overlay_shadow_result:
	dc.l 0,0,0,0,0,0,0,0 ; caches, target, hits, misses, calls, mismatch, first
	dc.l 0,0 ; original destination, current program
	dcb.w 12,0 ; two saved descriptors
	dc.l 0,0 ; selected persistent cache, unsupported cases
