; CUSTOM5 bit 6: original-path shadow-framebuffer twin for every cached draw.
; CUSTOM5 bit 7: pretend the cache allocation failed, exercising the fallback.
cache_verify_install:
	movem.l d0-a6,-(sp)
	move.l a1,a0
	adda.l #$3073e,a0
	lea cache_verify_target(pc),a2
	move.l (a0),(a2)
	move.l a1,a0
	adda.l #$307be,a0
	lea cache_verify_plane_size(pc),a2
	move.l (a0),(a2)
	move.l a1,d0
	add.l #$30418,d0
	lea cache_reference_tail+2(pc),a0
	move.l d0,(a0)
	movem.l (sp)+,d0-a6
	rts

cache_pixel_twin:
	movem.l d0-a6,-(sp)
	lea cache_verify_context(pc),a5
	move.l a0,(a5)
	move.l d0,4(a5)
	move.l d1,8(a5)
	; Above our 60-byte save + BSR return + 18-byte temporary descriptor are
	; the cache hook's original register inputs. Keep the original x/request.
	move.l 82(sp),12(a5)
	move.l 86(sp),16(a5)
	move.l 90(sp),20(a5)
	move.l cache_state(pc),a0
	move.l a0,24(a5)
	move.w 16(a0),74(a5)
	move.l cache_verify_plane_size(pc),a1
	move.l (a1),d0
	move.l mirror_depth_ptr(pc),a1
	mulu.w (a1),d0
	move.l d0,44(a5)
	add.l cache_state+28(pc),d0
	add.l #32,d0
	move.l d0,32(a5)
	moveq #2,d1
	move.l 4.w,a6
	jsr _LVOAllocMem(a6)
	tst.l d0
	beq mirror_verify_fail
	move.l d0,28(a5)
	add.l #16,d0
	move.l 24(a5),a0
	lea 56(a5),a1
	moveq #8,d1
.descriptor
	move.w (a0)+,(a1)+
	dbf d1,.descriptor
	move.l d0,56(a5)
	move.l 68(a5),d1
	mulu.w cache_state+20(pc),d1
	add.l d1,d0
	move.l d0,60(a5)
	move.l 28(a5),d0
	add.l #16,d0
	add.l cache_state+28(pc),d0
	move.l d0,36(a5)
	; A previous blit may still be modifying the framebuffer we are copying.
	bsr cache_verify_wait
	move.l 24(a5),a0
	move.l (a0),a0
	move.l 56(a5),a1
	move.l d1,d0
	bsr mirror_twin_copy
	move.l 24(a5),a0
	move.l 4(a0),a0
	move.l 60(a5),a1
	move.l cache_state+28(pc),d0
	sub.l d1,d0
	bsr mirror_twin_copy
	move.l cache_verify_target(pc),a0
	move.l (a0),40(a5)
	move.l (a0),a0
	move.l 36(a5),a1
	move.l 44(a5),d0
	bsr mirror_twin_copy
	move.l 28(a5),a1
	moveq #3,d0
.start_guard
	move.l #$6374776e,(a1)+
	dbf d0,.start_guard
	move.l 28(a5),a1
	adda.l 32(a5),a1
	suba.w #16,a1
	moveq #3,d0
.end_guard
	move.l #$6374776e,(a1)+
	dbf d0,.end_guard
	move.l cache_verify_target(pc),a0
	move.l 36(a5),(a0)
	move.l 12(a5),d0
	move.l 16(a5),d1
	move.l 20(a5),d2
	lea 56(a5),a0
	bsr cache_reference_draw
	move.l d0,48(a5)
	move.l d1,52(a5)
	bsr cache_verify_wait
	move.l cache_verify_target(pc),a0
	move.l 40(a5),(a0)
	move.l (a5),a0
	move.l 4(a5),d0
	move.l 8(a5),d1
	bsr cache_call_blit
	move.l d0,(sp)
	move.l d1,4(sp)
	cmp.l 48(a5),d0
	beq.b .d0_output
	; sim:30792 replaces only d0.w with depth; after the last SUBQ.W its
	; high word still belongs to the framebuffer base loaded at sim:3073c.
	move.l 40(a5),d2
	and.l #$ffff0000,d2
	cmp.l d2,d0
	bne mirror_verify_fail
	move.l 36(a5),d2
	and.l #$ffff0000,d2
	cmp.l 48(a5),d2
	bne mirror_verify_fail
.d0_output
	cmp.l 52(a5),d1
	beq.b .outputs
	; A completed blit leaves a framebuffer-relative address in d1; a
	; rejected blit leaves the unchanged y argument. Accept only these cases.
	sub.l 40(a5),d1
	move.l 52(a5),d0
	sub.l 36(a5),d0
	cmp.l d0,d1
	bne mirror_verify_fail
.outputs
	bsr cache_verify_wait
	move.l 40(a5),a0
	move.l 36(a5),a1
	move.l 44(a5),d0
	bsr mirror_twin_compare
	move.l 24(a5),a0
	; Compare descriptor fields against the cache key and saved orientation.
	move.w 74(a5),d0
	cmp.w 16(a0),d0
	bne mirror_verify_fail
	lea cache_state+4(pc),a1
	moveq #16,d0
	bsr mirror_twin_compare
	move.l 28(a5),a1
	moveq #3,d0
.start_check
	cmp.l #$6374776e,(a1)+
	bne mirror_verify_fail
	dbf d0,.start_check
	move.l 28(a5),a1
	adda.l 32(a5),a1
	suba.w #16,a1
	moveq #3,d0
.end_check
	cmp.l #$6374776e,(a1)+
	bne mirror_verify_fail
	dbf d0,.end_check
	move.l 28(a5),a1
	move.l 32(a5),d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
	lea cache_verify_header(pc),a0
	addq.l #1,16(a0)
	movem.l (sp)+,d0-a6
	rts
cache_verify_wait:
	btst #6,$dff002
.wait
	btst #6,$dff002
	bne.b .wait
	rts
cache_reference_draw:
	move.w d2,-(sp)
	swap d0
	move.w 16(a0),d0
cache_reference_tail:
	jmp $0.l
cache_verify_target: dc.l 0
cache_verify_plane_size: dc.l 0
cache_verify_context: dcb.b 76,0
cache_verify_header:
	dc.b "RBMCAC01"
	dc.l 1,0,0
