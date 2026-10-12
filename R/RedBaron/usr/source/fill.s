; W4 D1: omit C DMA only when BOTH computed edge masks are all ones.
; PERF_RANGE sim:2fd2c 10 bit=7
; The original plane loop, minterms, waits, modulos and pointers remain intact.
fill_install:
	movem.l d0-a6,-(sp)
	move.l #$2fd2c,d0
	moveq #10,d1
	lea fill_expected(pc),a0
	bsr perf_check_bytes
	lea fill_patch(pc),a0
	jsr resload_Patch(a2)
	IFD VERIFY
	btst #0,perf_custom5+1(pc) ; CUSTOM5 bit 16: hardware pixel twin
	beq.b .done
	move.l 36(sp),a1
	; This twin can run in menus, before the flight observer knows h3.
	move.l a1,a0
	adda.l #$301b2,a0
	move.l (a0),d0
	subi.l #$9a2c,d0
	lea fill_twin_h3(pc),a0
	move.l d0,(a0)
	move.l #$2fd8a,d0
	moveq #8,d1
	lea fill_twin_expected(pc),a0
	bsr perf_check_bytes
	lea fill_twin_patch(pc),a0
	jsr resload_Patch(a2)
.done
	ENDC
	jsr resload_FlushCache(a2)
	movem.l (sp)+,d0-a6
	rts
fill_expected: dc.w $383c,$03fa,$41f9,$00df,$f000
fill_patch:
	PL_START
	PL_PSS $2fd2c,fill_setup,4
	PL_END
fill_base:
fill_setup:
	move.w #$03fa,d4
	cmp.l #-1,d7
	bne.b .masked
	move.w #$01fa,d4
.masked
	lea $dff000,a0
	rts

	IFD VERIFY
; Deliberately incompatible with CUSTOM5 bit 3's paint hook at the same site.
; Original hardware -> save pixels -> restore input -> candidate -> compare.
; Includes every affected word, hence the untouched bits of masked edges too.
; Bounds are explicit: at most 20 words x 256 lines, positive signed modulo.
; No VERIFY register/CCR survives: the replaced BLTSIZE MOVE supplies NZVC;
; following original ADD overwrites X before it can be consumed.
fill_twin_expected: dc.w $2141,$0054,$3143,$0058
; VERIFY_RANGE sim:2fd8a 8: destination pointer and BLTSIZE writes.
fill_twin_patch:
	PL_START
	PL_PSS $2fd8a,fill_twin,2
	PL_END
fill_twin:
	movem.l d0-a6,-(sp)
	lea fill_twin_header(pc),a6
	move.w d3,d6
	andi.w #63,d6
	beq fill_twin_fail
	cmpi.w #20,d6
	bhi fill_twin_fail
	move.w d3,d5
	lsr.w #6,d5
	beq fill_twin_fail
	cmpi.w #256,d5
	bhi fill_twin_fail
	; The game's pitch at sim:2fd0c is checked by the pixel traversal below:
	; BLTDMOD is write-only; derive saved original modulo from h3 instead.
	move.l fill_twin_h3(pc),a1
	adda.l #$9d42,a1
	move.w (a1),d2
	move.w d6,d0
	add.w d0,d0
	sub.w d0,d2
	bmi fill_twin_fail
	move.l d1,a1
	lea fill_base(pc),a2
	adda.l #fill_twin_before-fill_base,a2
	bsr fill_twin_copy
	; Replay original C+D blit on exactly the original input.
	move.w d4,d0
	ori.w #$0200,d0
	move.w d0,$40(a0)
	move.l d1,$48(a0)
	move.l d1,$54(a0)
	move.w d3,$58(a0)
	bsr fill_twin_wait
	move.l d1,a1
	lea fill_base(pc),a2
	adda.l #fill_twin_after-fill_base,a2
	bsr fill_twin_copy
	move.l d1,a1
	lea fill_base(pc),a2
	adda.l #fill_twin_before-fill_base,a2
	move.w d5,d7
	subq.w #1,d7
.restore_row
	move.w d6,d0
	subq.w #1,d0
.restore_word
	move.w (a2)+,(a1)+
	dbf d0,.restore_word
	adda.w d2,a1
	dbf d7,.restore_row
	move.w d4,$40(a0)
	move.l d1,$48(a0)
	move.l d1,$54(a0)
	move.w d3,$58(a0)
	bsr fill_twin_wait
	move.l d1,a1
	lea fill_base(pc),a2
	adda.l #fill_twin_after-fill_base,a2
	move.w d5,d7
	subq.w #1,d7
.compare_row
	move.w d6,d0
	subq.w #1,d0
.compare_word
	move.w (a2)+,d4
	cmp.w (a1)+,d4
	bne fill_twin_fail
	addq.l #1,24(a6)
	dbf d0,.compare_word
	adda.w d2,a1
	dbf d7,.compare_row
	addq.l #1,12(a6)
	; Count using original saved d4 explicitly, independent of host endianness.
	move.l 16(sp),d0
	andi.w #$0200,d0
	bne.b .masked
	addq.l #1,16(a6)
	bra.b .done
.masked
	addq.l #1,20(a6)
.done
	movem.l (sp)+,d0-a6
	move.w d3,d3
	rts
fill_twin_copy:
	move.w d5,d7
	subq.w #1,d7
.row
	move.w d6,d0
	subq.w #1,d0
.word
	move.w (a1)+,(a2)+
	dbf d0,.word
	adda.w d2,a1
	dbf d7,.row
	rts
fill_twin_wait:
	btst #6,2(a0)
.wait
	btst #6,2(a0)
	bne.b .wait
	rts
fill_twin_fail:
	pea fill_twin_message(pc)
	pea TDREASON_FAILMSG
	move.l _resload(pc),a2
	jmp resload_Abort(a2)
fill_twin_message: dc.b "Red Baron: solid-fill pixel twin mismatch or bounds",0
	even
fill_twin_h3: dc.l 0
fill_twin_header: dc.b "RBFILL01"
	dc.l 1,0,0,0,0 ; version, twins, D-only, masked, compared words
	ENDC
