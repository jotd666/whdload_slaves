; Shared bit-14 lifetime hooks; runtime bit 18 implies this ownership guard.
; This never skips native drawing and never overlaps W1's shared free tail.
; PERF_RANGE sim:28516 6 bit=14
; PERF_RANGE sim:28556 8 bit=14
; PERF_RANGE sim:286fc 8 bit=14
; PERF_RANGE sim:28df4 6 bit=14
; PERF_RANGE sim:301d8 8 bit=14
; PERF_RANGE sim:303ac 6 bit=14
; PERF_RANGE sim:3038e 6 bit=14
ovlife_install:
	movem.l d0-a6,-(sp)
	move.l a1,a3
	; Derive h3 independently from the original registry operand.
	move.l a3,a0
	adda.l #$301b2,a0
	move.l (a0),d2
	subi.l #$9a2c,d2
	move.l d2,d0
	addi.l #$9a2c,d0
	lea ovlife_registry(pc),a0
	move.l d0,(a0)
	addi.l #512,d0
	lea ovlife_bitmap_all_bytes+2(pc),a0
	move.l d0,(a0)
	lea ovlife_registry_end(pc),a0
	move.l d0,(a0)
	lea .check_base(pc),a6
.check_base
	adda.l #perf_check_bytes-.check_base,a6
	move.l #$28516,d0
	moveq #6,d1
	lea ovlife_reset_bytes(pc),a0
	jsr (a6)
	move.l a3,d0
	addi.l #$2851c,d0
	lea ovlife_reset_tail+2(pc),a0
	move.l d0,(a0)
	move.l #$28556,d0
	moveq #8,d1
	lea ovlife_load_bytes(pc),a0
	jsr (a6)
	move.l a3,d0
	addi.l #$2855e,d0
	lea ovlife_load_tail+2(pc),a0
	move.l d0,(a0)
	move.l #$286fc,d0
	moveq #8,d1
	lea ovlife_rebuild_bytes(pc),a0
	jsr (a6)
	move.l a3,d0
	addi.l #$28704,d0
	lea ovlife_rebuild_tail+2(pc),a0
	move.l d0,(a0)
	move.l #$28df4,d0
	moveq #6,d1
	lea ovlife_release_bytes(pc),a0
	jsr (a6)
	move.l a3,d0
	addi.l #$28dfa,d0
	lea ovlife_release_tail+2(pc),a0
	move.l d0,(a0)
	move.l #$301d8,d0
	moveq #8,d1
	lea ovlife_bitmap_load_bytes(pc),a0
	jsr (a6)
	move.l a3,d0
	addi.l #$301e0,d0
	lea ovlife_bitmap_load_tail+2(pc),a0
	move.l d0,(a0)
	move.l #$303ac,d0
	moveq #6,d1
	lea ovlife_bitmap_release_bytes(pc),a0
	jsr (a6)
	move.l a3,d0
	addi.l #$303b2,d0
	lea ovlife_bitmap_release_tail+2(pc),a0
	move.l d0,(a0)
	move.l #$3038e,d0
	moveq #6,d1
	lea ovlife_bitmap_all_bytes(pc),a0
	jsr (a6)
	move.l a3,d0
	addi.l #$30394,d0
	lea ovlife_bitmap_all_tail+2(pc),a0
	move.l d0,(a0)
	move.l a3,d0
	addi.l #$303ee,d0
	lea ovlife_zero_tail+2(pc),a0
	move.l d0,(a0)
	lea .attn_base(pc),a0
.attn_base
	adda.l #perf_attnflags+3-.attn_base,a0
	btst #0,(a0)
	beq .cpu_ready
	lea ovlife_save_ccr(pc),a0
	move.w #$42e7,(a0)
	IFD VERIFY
	lea ovlife_test_ccr(pc),a0
	move.w #$42c0,(a0)
	ENDC
.cpu_ready
	IFD VERIFY
	bsr ovlife_selftest
	IFD VERIFY_OVERLAY_KEY_EXPERIMENT
	bsr overlay_key_selftest
	ENDC
	ENDC
	lea .patch(pc),a0
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
.patch
	PL_START
	PL_P $28516,ovlife_reset
	PL_P $28556,ovlife_load
	PL_NOP $2855c,2
	PL_P $286fc,ovlife_rebuild
	PL_NOP $28702,2
	PL_P $28df4,ovlife_release
	PL_P $301d8,ovlife_bitmap_load
	PL_NOP $301de,2
	PL_P $303ac,ovlife_bitmap_release
	PL_P $3038e,ovlife_bitmap_all
	PL_END
ovlife_reset_bytes: dc.w $48e7,$0120,$7e00
ovlife_load_bytes: dc.w $4e55,$ffe8,$48e7,$0f30
ovlife_rebuild_bytes: dc.w $48e7,$0f30,$3e2f,$001c
ovlife_release_bytes: dc.w $2f07,$3e2f,$0008
ovlife_bitmap_load_bytes: dc.w $2208,$243c,$0000,$03ed
ovlife_bitmap_release_bytes: dc.w $2008,$673e,$5188
ovlife_bitmap_all_bytes: dc.w $227c,$0000,$9c2c

ovlife_invalidate:
ovlife_save_ccr: dc.w $40e7
	move.l a0,-(sp)
	bsr instrument_cache_invalidate
	IFD VERIFY
	lea overlay_shadow_valid(pc),a0
	clr.l (a0)+
	clr.l (a0)
	lea ovlife_count(pc),a0
	addq.l #1,(a0)
	ENDC
	move.l (sp)+,a0
	move.w (sp)+,ccr
	rts

	IFD VERIFY
; Exercise all CCR combinations in private state before installing the hooks.
ovlife_selftest:
	movem.l d0-d2/a0,-(sp)
	moveq #31,d2
ovlife_case:
	lea overlay_shadow_valid(pc),a0
	move.l #1,(a0)
	move.l #1,4(a0)
	move.w d2,ccr
	bsr ovlife_invalidate
ovlife_test_ccr: dc.w $40c0 ; move.w SR,D0; CCR on 010+
	andi.w #31,d0
	cmp.w d2,d0
	bne overlay_blit_bad
	lea overlay_shadow_valid(pc),a0
	tst.l (a0)
	bne overlay_blit_bad
	tst.l 4(a0)
	bne overlay_blit_bad
	dbf d2,ovlife_case
	lea ovlife_count(pc),a0
	cmpi.l #32,(a0)
	bne overlay_blit_bad
	clr.l (a0)
	move.l #32,4(a0)
	movem.l (sp)+,d0-d2/a0
	rts
	ENDC

ovlife_reset:
	bsr ovlife_invalidate
	movem.l d7/a2,-(sp)
	moveq #0,d7
ovlife_reset_tail:
	jmp $0.l

ovlife_load:
	bsr ovlife_invalidate
	link a5,#-24
	movem.l d4-d7/a2-a3,-(sp)
ovlife_load_tail:
	jmp $0.l

ovlife_rebuild:
	bsr ovlife_invalidate
	movem.l d4-d7/a2-a3,-(sp)
	move.w 28(sp),d7
ovlife_rebuild_tail:
	jmp $0.l

ovlife_release:
	bsr ovlife_invalidate
	move.l d7,-(sp)
	move.w 8(sp),d7
ovlife_release_tail:
	jmp $0.l

ovlife_bitmap_load:
	bsr ovlife_invalidate
	move.l a0,d1
	move.l #1005,d2
ovlife_bitmap_load_tail:
	jmp $0.l

ovlife_bitmap_release:
	bsr ovlife_invalidate
	move.l a0,d0
	beq ovlife_zero_tail
	subq.l #8,a0
ovlife_bitmap_release_tail:
	jmp $0.l

ovlife_bitmap_all:
	bsr ovlife_invalidate
	move.l ovlife_registry_end(pc),a1
ovlife_bitmap_all_tail:
	jmp $0.l
ovlife_zero_tail:
	jmp $0.l
ovlife_registry: dc.l 0
ovlife_registry_end: dc.l 0
	IFD VERIFY
ovlife_count: dc.l 0,0 ; operations, private CCR cases

; Optional private failure fixture: poison the first image byte of both owned
; caches, then invalidate before the third diagnostic call. No game data writes.
ovlife_refill_probe:
	movem.l d0/a0-a1,-(sp)
	lea .options(pc),a0
.options
	adda.l #perf_custom4-.options,a0
	cmpi.l #$80000,(a0)
	bne .done
	lea ovlife_refill_result(pc),a0
	tst.l (a0)
	bne .done
	lea overlay_mask_result(pc),a1
	cmpi.l #3,12(a1)
	bne .done
	lea overlay_shadow_valid(pc),a1
	cmpi.l #1,(a1)
	bne overlay_blit_bad
	cmpi.l #1,4(a1)
	bne overlay_blit_bad
	lea overlay_shadow_result(pc),a1
	move.l (a1),d0
	beq overlay_blit_bad
	move.l d0,4(a0)
	move.l 4(a1),d0
	beq overlay_blit_bad
	move.l d0,8(a0)
	move.l #1,(a0)
	move.l 4(a0),a1
	eori.b #$ff,16(a1)
	move.l 8(a0),a1
	eori.b #$ff,16(a1)
	bsr ovlife_invalidate
.done
	movem.l (sp)+,d0/a0-a1
	rts
ovlife_refill_result: dc.l 0,0,0 ; injections, retained program-three/four pointers

	ENDC
