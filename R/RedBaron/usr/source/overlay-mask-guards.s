; VERIFY-only private eligibility cases. Never modify a live resource.
; Result: allocation (zero after free), passed count. Fatal VERIFY on mismatch.
overlay_mask_guard_verify:
	lea overlay_mask_guard_result(pc),a0
	tst.l 4(a0)
	bne .done
	movem.l d0-a6,-(sp)
	move.l 4.w,a6
	move.l #48992,d0 ; private h3, guard, 8000-byte mask, guard
	moveq #0,d1
	jsr _LVOAllocMem(a6)
	lea overlay_mask_guard_result(pc),a0
	move.l d0,(a0)
	beq overlay_blit_bad
	move.l d0,a4
	move.l a4,a3
	adda.l #$8000,a3
	lea .cases(pc),a5
	moveq #13,d7
.case
	move.l a4,a0
	move.w #12247,d0
.clear
	clr.l (a0)+
	dbf d0,.clear
	move.l #8000,$1d34(a3)
	move.w #5,$1d3c(a3)
	move.w #320,$1d40(a3)
	move.w #40,$1d42(a3)
	move.w #200,$1d44(a3)
	move.w #1,$1d46(a3)
	move.w #319,$1d4a(a3)
	move.w #199,$1d4e(a3)
	lea $100(a4),a0
	move.l a0,$3b06(a4)
	lea $200(a4),a0
	move.l a0,$100(a4)
	lea $300(a4),a0
	move.l a0,$204(a4)
	move.w #16,$208(a4)
	move.w #2,$20a(a4)
	move.l #4,$20c(a4)
	move.w #$8000,$300(a4)
	move.w #$4000,$304(a4)
	lea .program(pc),a0
	lea $400(a4),a1
	moveq #3,d0
.copy
	move.l (a0)+,(a1)+
	dbf d0,.copy
	lea $2000(a3),a0
	moveq #3,d0
.guard
	move.l #$a55ac33c,(a0)+
	move.l #$a55ac33c,8012(a0)
	dbf d0,.guard
	moveq #0,d0
	move.w (a5)+,d0
	move.w (a5)+,0(a4,d0.l)
	lea $400(a4),a0
	move.l a4,a1
	lea $2010(a3),a2
	bsr overlay_mask_build
	cmp.w (a5)+,d0
	bne overlay_blit_bad
	lea $2000(a3),a0
	moveq #3,d0
.check_guard
	cmpi.l #$a55ac33c,(a0)+
	bne overlay_blit_bad
	cmpi.l #$a55ac33c,8012(a0)
	bne overlay_blit_bad
	dbf d0,.check_guard
	lea overlay_mask_guard_result(pc),a0
	addq.l #1,4(a0)
	dbf d7,.case
	move.l a4,a1
	move.l #48992,d0
	move.l 4.w,a6
	jsr _LVOFreeMem(a6)
	lea overlay_mask_guard_result(pc),a0
	clr.l (a0)
	movem.l (sp)+,d0-a6
.done
	rts
.program
	dc.w $1051,1,$1031,0,$a502,10,10,$0ff0
.cases
	; private offset, replacement word, expected supported result
	dc.w $9d40,320,1 ; baseline
	dc.w $9d40,304,0
	dc.w $9d44,199,0
	dc.w $302,1,0 ; first mask pad
	dc.w $306,1,0 ; second mask pad
	dc.w $40a,288,1 ; padded right edge 319
	dc.w $40a,289,0 ; padded right edge 320
	dc.w $40c,198,1 ; bottom edge 199
	dc.w $40c,199,0 ; bottom edge 200
	dc.w $9d4a,41,1 ; padded edge exactly on clip
	dc.w $9d4a,40,0
	dc.w $9d48,11,0 ; left clip
	dc.w $9d4c,11,0 ; top clip
	dc.w $9d4e,10,0 ; bottom clip
overlay_mask_guard_result: dc.l 0,0
