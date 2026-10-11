; VERIFY-only coverage builder for audited front-overlay commands.
; a0=program, a1=h3, a2=8000-byte CPU mask. d0=1 supported, 0 fallback.
; Every other register is preserved. No game state or hardware is written.
; Unsupported commands/geometry fail closed; caller must discard partial mask.
overlay_mask_build:
	link a6,#-32
	movem.l d1-d7/a0-a5,-(sp)
	move.l a0,a3
	move.l a1,a4
	adda.l #$8000,a4
	move.l a2,a5
	clr.l -4(a6) ; image table
	clr.l -8(a6) ; image descriptor
	move.w #255,-12(a6) ; bounded command stream
	move.l a3,d0
	addi.l #512,d0
	move.l d0,-16(a6)
	cmpi.l #8000,$1d34(a4)
	bne .fail
	cmpi.w #5,$1d3c(a4)
	bne .fail
	cmpi.w #40,$1d42(a4)
	bne .fail
	move.l a5,a0
	move.w #1999,d0
.clear
	clr.l (a0)+
	dbf d0,.clear
.next
	cmpa.l -16(a6),a3
	bhs .fail
	move.w (a3)+,d0
	cmpi.w #$0ff0,d0
	beq .success
	subq.w #1,-12(a6)
	bmi .fail
	; Largest operand is eight bytes. Never read beyond the bounded stream.
	move.l a3,d1
	addq.l #8,d1
	cmp.l -16(a6),d1
	bhi .fail
	cmpi.w #$2002,d0
	beq .colour
	cmpi.w #$1051,d0
	beq .set
	cmpi.w #$1031,d0
	beq .image
	cmpi.w #$a104,d0
	beq .rectangle
	cmpi.w #$a0a4,d0
	beq .line
	cmpi.w #$a502,d0
	beq .bitmap
.fail
	moveq #0,d0
	bra .done
.success
	moveq #1,d0
.done
	movem.l (sp)+,d1-d7/a0-a5
	unlk a6
	rts
.colour
	addq.l #4,a3 ; coverage is independent of colour
	bra .next
.set
	moveq #0,d0
	move.w (a3)+,d0
	bmi .fail
	lsl.l #2,d0
	lea -$44fe(a4),a0
	move.l 0(a0,d0.l),-4(a6)
	beq .fail
	bra .next
.image
	move.l -4(a6),d0
	beq .fail
	move.l d0,a0
	moveq #0,d0
	move.w (a3)+,d0
	bmi .fail
	lsl.l #2,d0
	move.l 0(a0,d0.l),-8(a6)
	beq .fail
	bra .next
.rectangle
	move.w (a3)+,d2
	move.w (a3)+,d3
	move.w (a3)+,d4
	move.w (a3)+,d5
	cmpi.w #320,d2
	bhs .fail
	cmpi.w #200,d3
	bhs .fail
	tst.w d4
	ble .fail
	tst.w d5
	ble .fail
	add.w d2,d4
	bcs .fail
	cmpi.w #320,d4
	bhi .fail
	add.w d3,d5
	bcs .fail
	cmpi.w #200,d5
	bhi .fail
	move.w d2,d6
.rect_row
	move.w d6,d2
.rect_pixel
	move.w d2,d0
	move.w d3,d1
	bsr overlay_mask_point
	tst.w d0
	beq .fail
	addq.w #1,d2
	cmp.w d4,d2
	blo .rect_pixel
	addq.w #1,d3
	cmp.w d5,d3
	blo .rect_row
	bra .next
.line
	move.w (a3)+,d2
	move.w (a3)+,d3
	move.w (a3)+,d4
	move.w (a3)+,d5
	cmpi.w #320,d2
	bhs .fail
	cmpi.w #320,d4
	bhs .fail
	cmpi.w #200,d3
	bhs .fail
	cmpi.w #200,d5
	bhs .fail
	moveq #1,d0
	move.w d0,-20(a6)
	move.w d4,d6
	sub.w d2,d6
	bpl .line_dx
	neg.w d6
	neg.w -20(a6)
.line_dx
	move.w d0,-22(a6)
	move.w d5,d7
	sub.w d3,d7
	bpl .line_dy
	neg.w d7
	neg.w -22(a6)
.line_dy
	neg.w d7
	move.w d6,d0
	add.w d7,d0
	move.w d0,-24(a6)
.line_pixel
	move.w d2,d0
	move.w d3,d1
	bsr overlay_mask_point
	tst.w d0
	beq .fail
	cmp.w d4,d2
	bne .line_step
	cmp.w d5,d3
	beq .next
.line_step
	move.w -24(a6),d0
	add.w d0,d0
	move.w d0,-26(a6)
	cmp.w d7,d0
	blt .line_y
	add.w d7,-24(a6)
	add.w -20(a6),d2
.line_y
	move.w -26(a6),d0
	cmp.w d6,d0
	bgt .line_pixel
	add.w d6,-24(a6)
	add.w -22(a6),d3
	bra .line_pixel
.bitmap
	move.w (a3)+,d2
	move.w (a3)+,d3
	cmpi.w #320,d2
	bhs .fail
	cmpi.w #200,d3
	bhs .fail
	move.l -8(a6),d0
	beq .fail
	move.l d0,a0
	tst.w 16(a0)
	bne .fail
	moveq #0,d4
	move.w 8(a0),d4
	beq .fail
	cmpi.w #320,d4
	bhi .fail
	addi.w #15,d4
	lsr.w #4,d4
	add.w d4,d4 ; source pitch bytes
	move.w 10(a0),d5
	beq .fail
	cmpi.w #200,d5
	bhi .fail
	move.w d4,d0
	mulu.w d5,d0
	cmp.l 12(a0),d0
	bne .fail
	move.w d4,-28(a6)
	addq.w #2,-28(a6) ; native mask row includes a pad word
	lsl.w #3,d4 ; padded source width in pixels
	move.w d2,d0
	add.w d4,d0
	cmpi.w #320,d0
	bhi .fail
	move.w d3,d0
	add.w d5,d0
	cmpi.w #200,d0
	bhi .fail
	move.l 4(a0),a1
	move.l a1,d0
	beq .fail
.bitmap_row
	moveq #0,d6
.bitmap_pixel
	move.w d6,d0
	lsr.w #3,d0
	moveq #7,d7
	move.w d6,d1
	andi.w #7,d1
	sub.w d1,d7
	btst d7,0(a1,d0.w)
	beq .bitmap_next
	move.w d2,d0
	add.w d6,d0
	move.w d3,d1
	bsr overlay_mask_point
	tst.w d0
	beq .fail
.bitmap_next
	addq.w #1,d6
	cmp.w d4,d6
	blo .bitmap_pixel
	adda.w -28(a6),a1
	addq.w #1,d3
	subq.w #1,d5
	bne .bitmap_row
	bra .next

; Set one coverage bit; preserve all except d0 and CCR.
overlay_mask_point:
	movem.l d1-d3/a0,-(sp)
	cmpi.w #320,d0
	bhs .fail
	cmpi.w #200,d1
	bhs .fail
	tst.w $1d46(a4)
	beq .unclipped
	cmp.w $1d48(a4),d0
	blt .fail
	cmp.w $1d4a(a4),d0
	bgt .fail
	cmp.w $1d4c(a4),d1
	blt .fail
	cmp.w $1d4e(a4),d1
	bgt .fail
.unclipped
	moveq #7,d2
	move.w d0,d3
	andi.w #7,d3
	sub.w d3,d2
	lsr.w #3,d0
	mulu.w #40,d1
	add.w d0,d1
	move.l a5,a0
	bset d2,0(a0,d1.w)
	moveq #1,d0
	bra .done
.fail
	moveq #0,d0
.done
	movem.l (sp)+,d1-d3/a0
	rts

; First four front-program calls: allocate private CPU storage, build and expose
; the mask, then free it. All native inputs are restored before interpretation.
overlay_mask_verify:
	movem.l d0-a6,-(sp)
	; The pixel probe can be selected without W6: its h3 pointer is then unset.
	lea .mask_base(pc),a0
.mask_base
	adda.l #perf_mask-.mask_base,a0
	btst #5,2(a0)
	beq overlay_mask_verify_done
	lea overlay_mask_result(pc),a5
	cmpi.l #4,12(a5)
	bhs overlay_mask_verify_done
	moveq #0,d7
	move.w overlay_probe_header(pc),d7
	cmpi.w #3,d7
	blo overlay_mask_verify_done
	cmpi.w #4,d7
	bhi overlay_mask_verify_done
	lea .h3_base(pc),a0
.h3_base
	adda.l #time_loop_h3-.h3_base,a0
	move.l (a0),a4
	move.l 4.w,a6
	move.l #8032,d0
	moveq #0,d1
	jsr _LVOAllocMem(a6)
	move.l d0,(a5)
	beq overlay_blit_bad
	move.l d0,a0
	move.l #$a55ac33c,d1
	move.l d1,(a0)+
	move.l d1,(a0)+
	move.l d1,(a0)+
	move.l d1,(a0)+
	move.l d1,8000(a0)
	move.l d1,8004(a0)
	move.l d1,8008(a0)
	move.l d1,8012(a0)
	move.l a0,a2
	move.l a4,a1
	moveq #0,d0
	move.w d7,d0
	lsl.l #2,d0
	lea $7b52(a4),a0
	move.l 0(a0,d0.l),a0
	bsr overlay_mask_build
	move.l d0,4(a5)
	move.l d7,8(a5)
	addq.l #1,12(a5)
overlay_mask_observed:
	nop
	move.l 4.w,a6
	move.l (a5),a1
	move.l #8032,d0
	jsr _LVOFreeMem(a6)
	clr.l (a5)
overlay_mask_verify_done
	movem.l (sp)+,d0-a6
	rts
overlay_mask_result: dc.l 0,0,0,0 ; allocation, supported, program, count
