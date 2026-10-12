; Full-composition gauge layers, populated only during an active bit-19 stage.
; Reuse the existing exact raw-input/context key. A background bitmap's native
; mask owns coverage; colour zero is opaque when its mask bit is set.
; Accept a layer only when the native needle/result rectangle is wholly inside
; that coverage. Other layouts remain unavailable to the full compositor.
; Capturing layers does not suppress native drawing or change the normal mask.
CG_KEY = 4
CG_AREA = 292
CG_PIXELS = 320
CG_PLANE = 640 ; bounded packed plane; pitch is CG_AREA+4, not a fixed width
CG_MASK = CG_PIXELS+CG_PLANE*5
CG_STRIDE = CG_MASK+CG_PLANE
CG_POOL_BYTES = CG_STRIDE*14

cockpit_gauges_before:
 movem.l d0-a6,-(sp)
 lea cockpit_gauge_pending(pc),a0
 clr.l (a0)
 move.l cockpit_stage_active(pc),d0
 beq cg_before_done
 cmpi.w #6,d4
 bhi cg_before_done
 moveq #0,d0
 move.b -$ee3(a4),d0
 cmpi.w #1,d0
 bhi cg_before_done
 add.w d4,d4
 add.w d4,d0
 lsr.w #1,d4
 mulu.w #CG_STRIDE,d0
 move.l d0,-(sp)
 bsr cockpit_gauges_allocate
 move.l (sp)+,d0
 move.l cockpit_gauge_pool(pc),a6
 cmpa.l #0,a6
 beq cg_before_done
 adda.l d0,a6
 move.l a2,a3 ; original native background descriptor
 lea .key(pc),a0
.key
 adda.l #instrument_cache_key-.key,a0
 jsr (a0)
 tst.l d0
 beq cg_before_reject
 lea .temp(pc),a0
.temp
 adda.l #instrument_cache_key_temp-.temp,a0
 tst.l (a6)
 beq .changed
 move.l a0,a1
 lea CG_KEY(a6),a2
 moveq #IC_KEY_BYTES/4-1,d0
.match
 cmpm.l (a1)+,(a2)+
 bne .changed
 dbf d0,.match
 IFD VERIFY
 lea cockpit_gauge_counts(pc),a0
 addq.l #1,(a0)
 ENDC
 bsr cockpit_gauge_seen
 bra cg_before_done
.changed
 clr.l (a6)
 move.l a0,a1
 lea CG_KEY(a6),a2
 moveq #IC_KEY_BYTES/4-1,d0
.key_copy
 move.l (a1)+,(a2)+
 dbf d0,.key_copy
 lea CG_PIXELS(a6),a0
 move.w #CG_PLANE*6/4-1,d0
.clear
 clr.l (a0)+
 dbf d0,.clear
 move.l a3,a0
 bsr cockpit_gauge_mask
 tst.l d0
 beq cg_before_reject
 lea cockpit_gauge_pending(pc),a0
 move.l a6,(a0)
 bra cg_before_done
cg_before_reject:
 clr.l (a6)
cg_before_done:
 movem.l (sp)+,d0-a6
 rts

; a0=background descriptor, a6=record, d6.w=x, d5.w=y.
; Require an unmirrored native bitmap with zero pad words; reject before reads
; beyond its declared pitch/height or the 640-byte packed plane. d0=1 accepted, 0 fallback. Preserve others.
cockpit_gauge_mask:
 link a5,#-16
 movem.l d1-d7/a0-a4,-(sp)
 tst.w 16(a0)
 bne cg_mask_bad
 move.l (a0),d0
 beq cg_mask_bad
 btst #0,d0
 bne cg_mask_bad
 move.w d6,d2
 bmi cg_mask_bad
 move.w d5,d3
 bmi cg_mask_bad
 moveq #0,d4
 move.w 8(a0),d4
 beq cg_mask_bad
 cmpi.w #96,d4
 bhi cg_mask_bad
 addi.w #15,d4
 lsr.w #4,d4
 add.w d4,d4 ; colour pitch
 move.w 10(a0),d5
 beq cg_mask_bad
 cmpi.w #64,d5
 bhi cg_mask_bad
 move.w d4,d0
 mulu.w d5,d0
 cmp.l 12(a0),d0
 bne cg_mask_bad
 move.w d4,-2(a5)
 addq.w #2,-2(a5) ; source mask pitch includes one zero pad word
 lsl.w #3,d4
 move.w d2,d0
 add.w d4,d0
 bcs cg_mask_bad
 cmpi.w #320,d0
 bhi cg_mask_bad
 move.w d3,d1
 add.w d5,d1
 bcs cg_mask_bad
 cmpi.w #200,d1
 bhi cg_mask_bad
 move.l 4(a0),a1
 move.l a1,d0
 beq cg_mask_bad
 btst #0,d0
 bne cg_mask_bad
 move.w d2,d0
 lsr.w #4,d0
 add.w d0,d0
 move.w d0,CG_AREA(a6)
 move.w d3,CG_AREA+2(a6)
 move.w d2,d1
 add.w d4,d1
 addi.w #15,d1
 lsr.w #4,d1
 add.w d1,d1
 sub.w d0,d1
 move.w d1,CG_AREA+4(a6)
 move.w d5,CG_AREA+6(a6)
 move.w d1,d0
 mulu.w d5,d0
 cmpi.l #CG_PLANE,d0
 bhi cg_mask_bad
 move.l a6,a4
 adda.l #CG_MASK,a4
cg_mask_row:
 move.w -2(a5),d0
 subq.w #2,d0
 tst.w 0(a1,d0.w)
 bne cg_mask_bad
 moveq #0,d6
cg_mask_pixel:
 move.w d6,d0
 lsr.w #3,d0
 move.w d6,d1
 andi.w #7,d1
 moveq #7,d7
 sub.w d1,d7
 btst d7,0(a1,d0.w)
 beq cg_mask_next
 move.w d2,d0
 add.w d6,d0
 move.w d0,d1
 andi.w #7,d1
 moveq #7,d7
 sub.w d1,d7
 lsr.w #3,d0
 sub.w CG_AREA(a6),d0
 move.w d3,d1
 sub.w CG_AREA+2(a6),d1
 mulu.w CG_AREA+4(a6),d1
 add.w d0,d1
 bset d7,0(a4,d1.w)
 ; Seed colour from the resource, never from the old rendered frame. Native
 ; background redraws can be clipped to the previous needle rectangle.
 movem.l d2/d4/a2-a3,-(sp)
 moveq #0,d0
 move.w d6,d0
 lsr.w #3,d0
 move.l (a0),a2
 ; a1 advances by mask pitch; colour rows omit the trailing mask pad word.
 move.l a1,d2
 sub.l 4(a0),d2
 divu.w -2(a5),d2
 andi.l #$ffff,d2
 move.w -2(a5),d4
 subq.w #2,d4
 mulu.w d4,d2
 add.l d2,d0
 adda.l d0,a2
 lea CG_PIXELS(a6),a3
 adda.w d1,a3
 move.w d6,d2
 andi.w #7,d2
 neg.w d2
 addq.w #7,d2
 moveq #4,d4
.colour
 btst d2,(a2)
 beq .colour_next
 bset d7,(a3)
.colour_next
 adda.l 12(a0),a2
 adda.l #CG_PLANE,a3
 dbf d4,.colour
 movem.l (sp)+,d2/d4/a2-a3
cg_mask_next:
 addq.w #1,d6
 cmp.w d4,d6
 blo cg_mask_pixel
 adda.w -2(a5),a1
 addq.w #1,d3
 subq.w #1,d5
 bne cg_mask_row
 moveq #1,d0
 bra cg_mask_done
cg_mask_bad:
 moveq #0,d0
cg_mask_done:
 movem.l (sp)+,d1-d7/a0-a4
 unlk a5
 rts

cockpit_gauges_after:
 movem.l d0-a6,-(sp)
 lea cockpit_gauge_pending(pc),a0
 move.l (a0),a6
 clr.l (a0)
 cmpa.l #0,a6
 beq cg_after_done
 ; Native dispatcher has updated this page's exact result rectangle.
 move.w d4,d0
 lsl.w #4,d0
 moveq #0,d1
 move.b -$ee3(a4),d1
 lsl.w #3,d1
 add.w d1,d0
 lea -$ecc(a4),a0
 adda.w d0,a0
 move.l a6,a1
 adda.l #CG_MASK,a1
 bsr cockpit_gauge_contains
 tst.l d0
 beq cg_after_done
 ; Capture only the new needle's exact rectangle. Pixels outside it are
 ; the resource background, not remnants of the scene or another layer.
 move.l a0,a2
 bsr cockpit_stage_wait
 move.l $1d72(a4),a0
 lea CG_PIXELS(a6),a1
 bsr cockpit_gauge_capture
 move.l #1,(a6)
 bsr cockpit_gauge_seen
 IFD VERIFY
 lea cockpit_gauge_counts(pc),a0
 addq.l #1,4(a0)
 ENDC
cg_after_done:
 movem.l (sp)+,d0-a6
 rts

; a0=current native frame, a1=seeded layer, a2=validated result rectangle.
; Copy exact pixel bounds, retaining resource pixels in the edge bytes.
cockpit_gauge_capture:
 movem.l d0-d7/a0-a4,-(sp)
 move.w 2(a2),d3
 move.w 6(a2),d5
 subq.w #1,d5
.row
 move.w (a2),d2
 move.w 4(a2),d4
 subq.w #1,d4
.pixel
 move.w d3,d0
 mulu.w #40,d0
 move.w d2,d1
 lsr.w #3,d1
 add.w d1,d0
 move.l a0,a3
 adda.l d0,a3
 move.w d3,d0
 sub.w CG_AREA+2(a6),d0
 mulu.w CG_AREA+4(a6),d0
 sub.w CG_AREA(a6),d1
 add.w d1,d0
 move.l a1,a4
 adda.l d0,a4
 move.w d2,d1
 andi.w #7,d1
 moveq #7,d6
 sub.w d1,d6
 moveq #4,d7
.plane
 btst d6,(a3)
 beq .zero
 bset d6,(a4)
 bra .next_plane
.zero
 bclr d6,(a4)
.next_plane
 adda.l #8000,a3
 adda.l #CG_PLANE,a4
 dbf d7,.plane
 addq.w #1,d2
 dbf d4,.pixel
 addq.w #1,d3
 dbf d5,.row
 movem.l (sp)+,d0-d7/a0-a4
 rts

; a0=native x/y/width/height, a1=packed coverage, a6=gauge record. d0=fully covered.
; Conservative for line/bitmap bounds: holes reject, never invent opacity.
cockpit_gauge_contains:
 movem.l d1-d7/a0-a2,-(sp)
 move.w (a0),d2
 bmi .bad
 move.w 2(a0),d3
 bmi .bad
 move.w 4(a0),d4
 ble .bad
 move.w 6(a0),d5
 ble .bad
 add.w d2,d4
 bcs .bad
 cmpi.w #320,d4
 bhi .bad
 add.w d3,d5
 bcs .bad
 cmpi.w #200,d5
 bhi .bad
 move.w CG_AREA(a6),d0
 lsl.w #3,d0
 cmp.w d0,d2
 blo .bad
 move.w CG_AREA+4(a6),d1
 lsl.w #3,d1
 add.w d1,d0
 cmp.w d0,d4
 bhi .bad
 cmp.w CG_AREA+2(a6),d3
 blo .bad
 move.w CG_AREA+2(a6),d0
 add.w CG_AREA+6(a6),d0
 cmp.w d0,d5
 bhi .bad
 move.w d2,d6
.row
 move.w d6,d2
.pixel
 move.w d2,d0
 lsr.w #3,d0
 sub.w CG_AREA(a6),d0
 move.w d3,d1
 sub.w CG_AREA+2(a6),d1
 mulu.w CG_AREA+4(a6),d1
 add.w d0,d1
 move.w d2,d0
 andi.w #7,d0
 moveq #7,d7
 sub.w d0,d7
 btst d7,0(a1,d1.w)
 beq .bad
 addq.w #1,d2
 cmp.w d4,d2
 blo .pixel
 addq.w #1,d3
 cmp.w d5,d3
 blo .row
 moveq #1,d0
 bra .done
.bad
 moveq #0,d0
.done
 movem.l (sp)+,d1-d7/a0-a2
 rts

cockpit_gauges_invalidate:
 movem.l d0/a0,-(sp)
 lea cockpit_gauge_pending(pc),a0
 clr.l (a0)
 move.l cockpit_gauge_pool(pc),a0
 cmpa.l #0,a0
 beq .done
 moveq #13,d0
.loop
 clr.l (a0)
 adda.l #CG_STRIDE,a0
 dbf d0,.loop
.done
 movem.l (sp)+,d0/a0
 rts

cockpit_gauges_allocate:
 movem.l d0-d1/a0-a1/a6,-(sp)
 lea cockpit_gauge_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 move.l #CG_POOL_BYTES,d0
 move.l #$10004,d1
 jsr _LVOAllocMem(a6)
 lea cockpit_gauge_pool(pc),a0
 move.l d0,(a0)
.done
 movem.l (sp)+,d0-d1/a0-a1/a6
 rts
cockpit_gauge_pool: dc.l 0
cockpit_gauge_pending: dc.l 0
cockpit_gauge_attempted: dc.w 0
 IFD VERIFY
cockpit_gauge_counts: dc.l 0,0 ; stable-key reuse, newly captured layers
 ENDC

; Only gauges accepted during this invocation may enter the composition.
cockpit_gauge_seen:
 movem.l d0/a0,-(sp)
 lea cockpit_gauge_seen_bits(pc),a0
 move.w (a0),d0
 bset d4,d0
 move.w d0,(a0)
 movem.l (sp)+,d0/a0
 rts
cockpit_gauge_seen_bits: dc.w 0

; Expand one bounded gauge into a shared full-size composition scratch layer.
; a0=record, a1=48000-byte scratch, all registers preserved.
cockpit_gauge_expand:
 movem.l d0-d7/a0-a5,-(sp)
 move.l a1,a2
 move.w #11999,d0
.clear
 clr.l (a2)+
 dbf d0,.clear
 moveq #0,d0
 move.w CG_AREA+2(a0),d0
 mulu.w #40,d0
 add.w CG_AREA(a0),d0
 adda.l d0,a1
 lea CG_PIXELS(a0),a2
 moveq #5,d7
.plane
 move.l a1,a3
 move.l a2,a4
 move.w CG_AREA+6(a0),d6
 subq.w #1,d6
.row
 move.l a3,a5
 move.l a4,d1
 move.w CG_AREA+4(a0),d5
 lsr.w #1,d5
 subq.w #1,d5
.word
 move.w (a4)+,(a5)+
 dbf d5,.word
 move.l d1,a4
 adda.w CG_AREA+4(a0),a4
 adda.w #40,a3
 dbf d6,.row
 adda.l #CG_PLANE,a2
 adda.l #8000,a1
 dbf d7,.plane
 movem.l (sp)+,d0-d7/a0-a5
 rts
