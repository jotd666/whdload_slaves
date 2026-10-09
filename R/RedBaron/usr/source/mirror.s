; W1a: exact horizontal mirror. Main-thread only, like the original bitmap code.
; d0-a6 preserved; CCR dead at sim:30424. Scratch never aliases game/blitter data.
; 44 bytes saved, versus the original's 44 + 2*rounded-width words.
; PERF_RANGE sim:304d0 6 bit=0
mirror_prepare:
	movem.l d0-a6,-(sp)
	lea mirror_depth_ptr(pc),a0
	move.l a1,a3
	adda.l #$304fe,a3
	move.l (a3),(a0)
	lea mirror_original_tail+2(pc),a0
	move.l a1,d0
	add.l #$304d6,d0
	move.l d0,(a0)
	movem.l (sp)+,d0-a6
	rts
mirror_install:
	movem.l d0-a6,-(sp)
	bsr mirror_prepare
	move.l #$304d0,d0
	moveq #6,d1
	lea mirror_expected(pc),a0
	bsr perf_check_bytes
	IFD VERIFY
	btst #1,perf_custom5+2(pc)
	bne.b .no_synthetic
	bsr mirror_word_selftest
	btst #5,perf_custom5+3(pc)
	beq.b .no_synthetic
	bsr mirror_synthetic_tests
.no_synthetic
	ENDC
	lea mirror_patch(pc),a0
	jsr resload_Patch(a2)
	; Include the runtime continuation stubs in the cache synchronization.
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
mirror_patch:
	PL_START
	PL_P $304d0,mirror_entry
	PL_END
mirror_expected:
	dc.w $48e7,$ffe0,$2258

mirror_entry:
	IFD VERIFY
	btst #5,perf_custom5+3(pc)
	bne mirror_live_twin
	ENDC
mirror_fast:
	movem.l d0-a2,-(sp)
	; Unsupported inputs retain the original semantics and unbounded row stack.
	move.w 8(a0),d3
	beq mirror_fallback
	cmp.w #320,d3
	bhi mirror_fallback
	move.w 10(a0),d4
	beq mirror_fallback
	cmp.w #200,d4
	bhi mirror_fallback
	move.l mirror_depth_ptr(pc),a1
	move.w (a1),d7
	cmp.w #4,d7
	beq.b .depth_ok
	cmp.w #5,d7
	bne mirror_fallback
.depth_ok
	; The previous cookie-cut blit may still read the mask being regenerated.
	btst #6,$dff002
.wait
	btst #6,$dff002
	bne.b .wait
	move.l (a0),a1
	move.l 4(a0),a2
	add.w #15,d3
	lsr.w #4,d3
	subq.w #1,d4
	moveq #0,d0
	move.w d4,d6
.clear_row
	move.w d3,d5
.clear_word
	move.w d0,(a2)+
	dbf d5,.clear_word
	dbf d6,.clear_row
	move.l 4(a0),a2
	subq.w #1,d3
	subq.w #1,d7
.plane
	move.w d4,d6
.row
	move.l a1,d2
	lea mirror_scratch_end(pc),a0
	moveq #0,d0
	move.w d3,d5
.reverse
	move.b (a1)+,d0
	move.b mirror_table(pc,d0.w),-(a0)
	move.b (a1)+,d0
	move.b mirror_table(pc,d0.w),-(a0)
	dbf d5,.reverse
	move.l d2,a1
	move.w d3,d5
.copy
	move.w (a0)+,d0
	move.w d0,(a1)+
	or.w d0,(a2)+
	dbf d5,.copy
	addq.l #2,a2
	dbf d6,.row
	; Rewind the mask for the next plane; leave source planes contiguous.
	move.w d3,d0
	addq.w #2,d0
	move.w d4,d1
	addq.w #1,d1
	mulu.w d1,d0
	add.l d0,d0
	suba.l d0,a2
	dbf d7,.plane
	movem.l (sp)+,d0-a2
mirror_fast_return:
	rts
mirror_fallback
	movem.l (sp)+,d0-a2
	movem.l d0-a2,-(sp)
	move.l (a0)+,a1
mirror_original_tail:
	jmp $0.l
mirror_depth_ptr: dc.l 0
mirror_scratch: dcb.b 40,0
mirror_scratch_end:
mirror_table:
	dc.b $00,$80,$40,$c0,$20,$a0,$60,$e0,$10,$90,$50,$d0,$30,$b0,$70,$f0
	dc.b $08,$88,$48,$c8,$28,$a8,$68,$e8,$18,$98,$58,$d8,$38,$b8,$78,$f8
	dc.b $04,$84,$44,$c4,$24,$a4,$64,$e4,$14,$94,$54,$d4,$34,$b4,$74,$f4
	dc.b $0c,$8c,$4c,$cc,$2c,$ac,$6c,$ec,$1c,$9c,$5c,$dc,$3c,$bc,$7c,$fc
	dc.b $02,$82,$42,$c2,$22,$a2,$62,$e2,$12,$92,$52,$d2,$32,$b2,$72,$f2
	dc.b $0a,$8a,$4a,$ca,$2a,$aa,$6a,$ea,$1a,$9a,$5a,$da,$3a,$ba,$7a,$fa
	dc.b $06,$86,$46,$c6,$26,$a6,$66,$e6,$16,$96,$56,$d6,$36,$b6,$76,$f6
	dc.b $0e,$8e,$4e,$ce,$2e,$ae,$6e,$ee,$1e,$9e,$5e,$de,$3e,$be,$7e,$fe
	dc.b $01,$81,$41,$c1,$21,$a1,$61,$e1,$11,$91,$51,$d1,$31,$b1,$71,$f1
	dc.b $09,$89,$49,$c9,$29,$a9,$69,$e9,$19,$99,$59,$d9,$39,$b9,$79,$f9
	dc.b $05,$85,$45,$c5,$25,$a5,$65,$e5,$15,$95,$55,$d5,$35,$b5,$75,$f5
	dc.b $0d,$8d,$4d,$cd,$2d,$ad,$6d,$ed,$1d,$9d,$5d,$dd,$3d,$bd,$7d,$fd
	dc.b $03,$83,$43,$c3,$23,$a3,$63,$e3,$13,$93,$53,$d3,$33,$b3,$73,$f3
	dc.b $0b,$8b,$4b,$cb,$2b,$ab,$6b,$eb,$1b,$9b,$5b,$db,$3b,$bb,$7b,$fb
	dc.b $07,$87,$47,$c7,$27,$a7,$67,$e7,$17,$97,$57,$d7,$37,$b7,$77,$f7
	dc.b $0f,$8f,$4f,$cf,$2f,$af,$6f,$ef,$1f,$9f,$5f,$df,$3f,$bf,$7f,$ff
