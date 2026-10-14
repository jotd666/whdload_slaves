; Native compositor for word-aligned five-plane overlays.
; a0=image, a1=shared mask, a2=destination; d0=words/row, d1=rows.
; Image planes/mask are packed, destination pitch=40 and plane stride=8000.
; All registers preserved; CCR volatile. Caller supplies validated chip buffers.
overlay_blit:
	movem.l d0-a6,-(sp)
	cmpi.w #1,d0
	blo overlay_blit_bad
	cmpi.w #20,d0
	bhi overlay_blit_bad
	cmpi.w #1,d1
	blo overlay_blit_bad
	cmpi.w #200,d1
	bhi overlay_blit_bad
	move.w d0,d3
	add.w d3,d3
	moveq #40,d2
	sub.w d3,d2
	mulu.w d1,d3 ; image plane bytes
	move.w d1,d4
	lsl.w #6,d4
	or.w d0,d4
	lea $dff000,a3
	bsr overlay_blit_wait
	move.l #$0fca0000,$40(a3) ; A mask, B image, C destination: cookie cut
	move.l #-1,$44(a3)
	clr.w $64(a3) ; A modulo
	clr.w $62(a3) ; B modulo
	move.w d2,$60(a3) ; C modulo
	move.w d2,$66(a3) ; D modulo
	moveq #4,d5
.plane
	bsr overlay_blit_wait
	move.l a1,$50(a3)
	move.l a0,$4c(a3)
	move.l a2,$48(a3)
	move.l a2,$54(a3)
	move.w d4,$58(a3)
	adda.l d3,a0
	adda.l #8000,a2
	dbf d5,.plane
	bsr overlay_blit_wait
	movem.l (sp)+,d0-a6
	rts

overlay_blit_wait:
	tst.w $dff002
.wait
	btst #6,$dff002
	bne.b .wait
	rts

overlay_blit_bad:
	pea overlay_blit_error(pc)
	pea TDREASON_FAILMSG
	lea .resload_base(pc),a2
.resload_base
	adda.l #_resload-.resload_base,a2
	move.l (a2),a2
	jmp resload_Abort(a2)
overlay_blit_error: dc.b "Red Baron: invalid overlay compositor state",0
	even

	IFD VERIFY
OVERLAY_TEST_CHIP = 45240 ; guards + destination + largest image + mask
; Private-buffer hardware check. Never writes a game framebuffer.
overlay_blit_selftest:
	movem.l d0-a6,-(sp)
	lea overlay_blit_result(pc),a5
	tst.l 8(a5)
	bne overlay_blit_test_done
	move.l 4.w,a6
	move.l #40000,d0
	moveq #0,d1
	jsr _LVOAllocMem(a6)
	move.l d0,4(a5)
	beq overlay_blit_bad
	move.l #OVERLAY_TEST_CHIP,d0
	moveq #2,d1
	jsr _LVOAllocMem(a6)
	move.l d0,(a5)
	beq overlay_blit_bad
	lea overlay_blit_cases(pc),a4
	moveq #1,d7
overlay_blit_test_case:
	bsr overlay_blit_wait
	move.l (a5),a0
	move.w #OVERLAY_TEST_CHIP-1,d0
	moveq #$5a,d1
.fill
	move.b d1,(a0)+
	add.b d1,d1
	bcc.b .filled_seed
	eori.b #$1d,d1
.filled_seed
	dbf d0,.fill
	move.l (a5),a0
	lea 16(a0),a0
	move.l 4(a5),a1
	move.w #9999,d0
.copy
	move.l (a0)+,(a1)+
	dbf d0,.copy
	bsr overlay_blit_expected
	move.l (a5),a0
	adda.l #40016,a0
	move.l (a5),a1
	adda.l #44356,a1
	move.l (a5),a2
	move.w 6(a4),d0
	mulu.w #40,d0
	move.w 4(a4),d1
	lsr.w #3,d1
	add.w d1,d0
	addi.l #16,d0
	adda.l d0,a2
	move.w (a4),d0
	move.w 2(a4),d1
	bsr overlay_blit
	; Compare the full allocation, including untouched destination, source,
	; mask, unused source space and both guards. Expected is CPU-composed.
	move.l (a5),a0
	move.l 4(a5),a1
	move.w #OVERLAY_TEST_CHIP-1,d0
	moveq #$5a,d1
	moveq #0,d2
.check
	move.b d1,d3
	cmpi.l #16,d2
	blo.b .outside
	cmpi.l #40016,d2
	bhs.b .outside
	move.b (a1)+,d3
.outside
	cmp.b (a0)+,d3
	bne overlay_blit_bad
	add.b d1,d1
	bcc.b .checked_seed
	eori.b #$1d,d1
.checked_seed
	addq.l #1,d2
	dbf d0,.check
	addq.l #1,8(a5)
	addi.l #OVERLAY_TEST_CHIP,12(a5)
overlay_blit_test_observed:
	nop
	addq.l #8,a4
	dbf d7,overlay_blit_test_case
	move.l 4.w,a6
	move.l (a5),a1
	move.l #OVERLAY_TEST_CHIP,d0
	jsr _LVOFreeMem(a6)
	move.l 4(a5),a1
	move.l #40000,d0
	jsr _LVOFreeMem(a6)
	clr.l (a5)
	clr.l 4(a5)
overlay_blit_test_done:
	movem.l (sp)+,d0-a6
	rts

; Independent byte expression: old XOR ((old XOR image) AND mask).
overlay_blit_expected:
	movem.l d0-a6,-(sp)
	move.l (a5),a0
	adda.l #40016,a0
	move.l (a5),a3
	adda.l #44356,a3
	move.l 4(a5),a2
	move.w 6(a4),d0
	mulu.w #40,d0
	move.w 4(a4),d1
	lsr.w #3,d1
	add.w d1,d0
	adda.l d0,a2
	move.w (a4),d2
	add.w d2,d2
	move.w 2(a4),d6
	mulu.w #40,d6
	neg.l d6
	addi.l #8000,d6
	moveq #4,d4
.plane
	move.l a3,a1
	move.w 2(a4),d3
	subq.w #1,d3
.row
	move.w d2,d0
	subq.w #1,d0
.byte
	move.b (a0)+,d1
	move.b (a2),d5
	eor.b d5,d1
	and.b (a1)+,d1
	eor.b d5,d1
	move.b d1,(a2)+
	dbf d0,.byte
	adda.w #40,a2
	suba.w d2,a2
	dbf d3,.row
	adda.l d6,a2
	dbf d4,.plane
	movem.l (sp)+,d0-a6
	rts

overlay_blit_cases: dc.w 12,30,64,71,14,31,64,72
overlay_blit_result: dc.l 0,0,0,0 ; chip, expected, cases, checked bytes

	ENDC
