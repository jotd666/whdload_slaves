; W1b: one chip-resident inverse image. Small UI bitmaps remain on the normal path.
; Key: descriptor, both storage pointers, width/height, plane size and plane count.
; PERF_RANGE sim:30412 6 bit=1
; PERF_RANGE sim:303c6 8 bit=1
CACHE_DESC = 32
CACHE_MIN_BYTES = 4096
cache_install:
	movem.l d0-a6,-(sp)
	bsr mirror_prepare
	lea cache_sim(pc),a0
	move.l a1,(a0)
	move.l a1,d0
	add.l #$30572,d0
	lea cache_call_blit+2(pc),a0
	move.l d0,(a0)
	move.l a1,d0
	add.l #$303ce,d0
	lea cache_free_tail+2(pc),a0
	move.l d0,(a0)
	move.l #$30412,d0
	moveq #6,d1
	lea cache_draw_expected(pc),a0
	bsr perf_check_bytes
	move.l #$303c6,d0
	moveq #8,d1
	lea cache_free_expected(pc),a0
	bsr perf_check_bytes
	IFD VERIFY
	bsr cache_verify_install
	ENDC
	lea cache_patch(pc),a0
	jsr resload_Patch(a2)
	movem.l (sp)+,d0-a6
	rts
cache_patch:
	PL_START
	PL_PS $30412,cache_draw
	PL_P $303c6,cache_free_set
	PL_NOP $303cc,2
	PL_END
cache_draw_expected: dc.w $4840,$3028,$0010
cache_free_expected: dc.w $2f0e,$233c,$0000,$0000

cache_draw:
	movem.l d0-a6,-(sp)
	move.w d2,d3
	or.w 16(a0),d3
	btst #0,d3
	bne .vertical
	and.w #$fffc,d3
	bne .fallback
	move.w d2,d3
	move.w 16(a0),d4
	eor.w d4,d3
	btst #1,d3
	beq .fallback
	bsr cache_get
	tst.l d0
	beq .fallback
	; The game owns the descriptor; give the blitter routine a temporary copy.
	lea -18(sp),sp
	move.l sp,a0
	move.l sp,a2
	lea cache_state+CACHE_DESC(pc),a1
	moveq #8,d0
.descriptor
	move.w (a1)+,(a2)+
	dbf d0,.descriptor
	move.l 18(sp),d0
	swap d0
	move.w 28(sp),d0
	and.w #3,d0
	swap d0
	btst #17,d0
	beq.b .position
	move.w 8(a0),d3
	neg.w d3
	and.w #15,d3
	sub.w d3,d0
.position
	move.l 22(sp),d1
	IFD VERIFY
	btst #6,perf_custom5+3(pc)
	beq.b .plain_draw
	bsr cache_pixel_twin
	bra.b .drawn
.plain_draw
	ENDC
	bsr cache_call_blit
.drawn
	; Keep the original blitter routine's d0/d1 outputs, not its inputs.
	move.l d0,18(sp)
	move.l d1,22(sp)
	lea 18(sp),sp
	move.l cache_sim(pc),d0
	add.l #$3045a,d0
	move.l d0,60(sp)
	movem.l (sp)+,d0-a6
	rts
.vertical
	; Conservative single-entry policy: drop on any vertical draw request.
	bsr cache_drop
.fallback
	movem.l (sp)+,d0-a6
	swap d0
	move.w 16(a0),d0
	rts
cache_call_blit:
	jmp $0.l

; a0 = real descriptor. d0 = success flag; every other register preserved.
cache_get:
	movem.l d1-a6,-(sp)
	move.l a0,a4
	lea cache_state(pc),a5
	moveq #0,d0
	move.w 8(a4),d0
	beq .no
	cmp.w #320,d0
	bhi .no
	moveq #0,d1
	move.w 10(a4),d1
	beq .no
	cmp.w #200,d1
	bhi .no
	add.w #15,d0
	lsr.w #4,d0
	add.w d0,d0
	mulu.w d1,d0
	cmp.l 12(a4),d0
	bne .no
	move.l mirror_depth_ptr(pc),a0
	move.w (a0),d2
	cmp.w #4,d2
	beq.b .depth
	cmp.w #5,d2
	bne .no
.depth
	move.l d0,d5
	add.w d1,d1
	add.l d1,d5
	mulu.w d2,d0
	move.l d0,d4
	cmp.l #CACHE_MIN_BYTES,d4
	blo .no
	move.l d4,d6
	add.l d5,d6
	tst.l 24(a5)
	beq.b .build
	cmp.l (a5),a4
	bne.b .build
	cmp.w 20(a5),d2
	bne.b .build
	move.l a4,a0
	lea 4(a5),a1
	moveq #3,d1
.key
	move.l (a0)+,d0
	cmp.l (a1)+,d0
	bne.b .build
	dbf d1,.key
	bra .yes
.build
	bsr cache_drop
	IFD VERIFY
	btst #7,perf_custom5+3(pc)
	bne .no
	ENDC
	move.l d6,d0
	moveq #2,d1
	move.l 4.w,a6
	jsr _LVOAllocMem(a6)
	tst.l d0
	beq .no
	move.l d0,24(a5)
	move.l d6,28(a5)
	move.l a4,(a5)
	move.w d2,20(a5)
	move.l a4,a0
	lea 4(a5),a1
	moveq #3,d1
.save_key
	move.l (a0)+,(a1)+
	dbf d1,.save_key
	move.l a4,a0
	lea CACHE_DESC(a5),a1
	moveq #8,d1
.save_descriptor
	move.w (a0)+,(a1)+
	dbf d1,.save_descriptor
	move.l 24(a5),d0
	move.l d0,CACHE_DESC(a5)
	add.l d4,d0
	move.l d0,CACHE_DESC+4(a5)
	move.l (a4),a0
	move.l 24(a5),a1
	move.l d4,d0
	lsr.l #1,d0
	subq.w #1,d0
.copy_planes
	move.w (a0)+,(a1)+
	dbf d0,.copy_planes
	lea CACHE_DESC(a5),a0
	IFD VERIFY
	btst #6,perf_custom5+3(pc)
	beq.b .plain_mirror
	bsr mirror_live_twin
	lea cache_verify_header(pc),a0
	addq.l #1,12(a0)
	bra.b .mirrored
.plain_mirror
	ENDC
	bsr mirror_fast
.mirrored
	; The original normalizes this mask after its first horizontal flip.
	; Preserve that side effect without ever rewriting the game's planes.
	bsr cache_normalize_mask
.yes
	moveq #1,d0
	movem.l (sp)+,d1-a6
	rts
.no
	moveq #0,d0
	movem.l (sp)+,d1-a6
	rts

; a4 = real descriptor, a5 = entry; d5 = mask byte length. Called only at build.
cache_normalize_mask:
	movem.l d0-a2,-(sp)
	move.l 4(a4),a2
	move.l d5,d0
	lsr.l #1,d0
	subq.w #1,d0
.clear
	clr.w (a2)+
	dbf d0,.clear
	move.l (a4),a1
	move.w 8(a4),d3
	add.w #15,d3
	lsr.w #4,d3
	subq.w #1,d3
	move.w 10(a4),d4
	subq.w #1,d4
	move.w 20(a5),d7
	subq.w #1,d7
.plane
	move.l 4(a4),a2
	move.w d4,d6
.row
	move.w d3,d5
.word
	move.w (a1)+,d0
	or.w d0,(a2)+
	dbf d5,.word
	addq.l #2,a2
	dbf d6,.row
	dbf d7,.plane
	movem.l (sp)+,d0-a2
	rts

; Free only after the blitter has stopped reading either cached source.
cache_drop:
	movem.l d0-a6,-(sp)
	lea cache_state(pc),a5
	tst.l 24(a5)
	beq.b .done
	btst #6,$dff002
.wait
	btst #6,$dff002
	bne.b .wait
	move.l 24(a5),a1
	move.l 28(a5),d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
	clr.l 24(a5)
	clr.l (a5)
.done
	movem.l (sp)+,d0-a6
	rts
cache_free_set:
	; Any set free invalidates our single entry, also covering descriptor reuse.
	bsr cache_drop
	move.l a6,-(sp)
	move.l #0,-(a1)
cache_free_tail:
	jmp $0.l
cache_sim: dc.l 0
cache_state: dcb.b 50,0
	even
