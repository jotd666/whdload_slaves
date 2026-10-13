; Development phase solver: continue an existing road contact when rendering
; omits its polygon. Never acquire new road support from airborne/off-road state.
; Original road/object priority and zero/eight/forced-native paths are retained.
; Only finite convex car-space footprints on non-gap records are eligible.
; Course-list boundaries and uncertain geometry retain the native fallback.
_terrain_select:
 tst.b -$16b6(a4)
 bne .road
 IFD VERIFY_DISPATCH_NATIVE
 bra.s .native
 ELSE
 move.w _time_scalar_fields(pc),d0
 beq .native
 cmpi.w #8,d0
 beq .native
 tst.b -$16b5(a4)
 bne .native
 move.w _terrain_continuing(pc),d0
 beq .native
 tst.b -$66f0(a4)
 beq .native
 movem.l d1-d7/a1-a3,-(a7)
 ; C022 writes its plane workspace even when the footprint is rejected.
 ; Restore it before either native continuation so a failed probe is inert.
 lea -116(a7),a7
 lea -$6bba(a4),a0
 movea.l a7,a1
 moveq #28,d7
.save_workspace:
 move.l (a0)+,(a1)+
 dbf d7,.save_workspace
 lea _terrain_selected(pc),a0
 clr.w (a0)
 move.b #1,-$6bb9(a4)
 movea.l _phase_steering_body(pc),a0
 adda.l #$c022-$b398,a0
 jsr (a0)
 bsr _terrain_mask
 lea -$6bac(a4),a1
 bsr _terrain_bounds
 movea.l a7,a0
 lea -$6bba(a4),a1
 moveq #28,d7
.restore_workspace:
 move.l (a0)+,(a1)+
 dbf d7,.restore_workspace
 lea 116(a7),a7
 movem.l (a7)+,d1-d7/a1-a3
 tst.w d0
 beq .native
 ENDC
.road:
 lea _terrain_continuing(pc),a0
 move.w #1,(a0)
 ; Reuse the installed B398 address to reach the two native continuations.
 movea.l _phase_steering_body(pc),a0
 adda.l #$cdc4-$b398,a0
 jmp (a0)
.native:
 lea _terrain_continuing(pc),a0
 clr.w (a0)
 movea.l _phase_steering_body(pc),a0
 adda.l #$cdca-$b398,a0
 jmp (a0)


; Preserve the displaced native writes and final MOVE.W condition codes.
_terrain_selected_hook:
 move.l a0,-(a7)
 lea _terrain_selected(pc),a0
 move.w d4,(a0)
 movea.l (a7)+,a0
 move.l a2,-70(a5)
 move.w d5,-62(a5)
 rts
_terrain_selected: dc.w 0

; Only straight indexing within one course list is proven here. Crossing a
; list boundary retains native fallback until the native links are mirrored.
; D2 permits the first/second quad with bits1/0 respectively.
_terrain_mask:
 moveq #0,d2
 move.w _terrain_selected(pc),d0
 cmpi.w #1,d0
 blo.s .done
 cmpi.w #2,d0
 bhi.s .done
 movea.l -$6720(a4),a0
 movea.l -$50da(a4),a2
 tst.b -$66b0(a4)
 beq.s .list
 movea.l -$66ae(a4),a0
 movea.l -$50d6(a4),a2
.list:
 movea.l -$671c(a4),a3
 suba.w #40,a3
 cmpa.l a0,a3
 blo.s .done
 adda.w #100,a3
 cmpa.l a2,a3
 bhi.s .done
 movea.l -$671c(a4),a3
 subq.w #3,d0
 muls.w #20,d0
 adda.l d0,a3
 btst #2,18(a3)
 bne.s .second
 bset #1,d2
.second:
 btst #2,38(a3)
 bne.s .done
 bset #0,d2
.done:
 rts
; A1 points at three native car-space road cross-sections (six XYZ vertices).
; D2 mask: bit1 permits first quad, bit0 permits second quad.
; Return D0=1 only when origin is in a nondegenerate convex projected quad.
; Bound coordinates before signed products; uncertain/far geometry is rejected.
_terrain_bounds:
 moveq #5,d7
 movea.l a1,a2
.check_range:
 move.w (a2),d0
 addi.w #8191,d0
 cmpi.w #16382,d0
 bhi .outside
 move.w 4(a2),d0
 addi.w #8191,d0
 cmpi.w #16382,d0
 bhi .outside
 addq.w #6,a2
 dbf d7,.check_range
 lea _terrain_indices(pc),a0
 moveq #1,d7
.quad:
 btst d7,d2
 bne.s .enabled
 addq.w #5,a0
 dbf d7,.quad
 bra .outside
.enabled:
 moveq #0,d5
 moveq #3,d6
.edge:
 moveq #0,d1
 move.b (a0)+,d1
 lea (a1,d1.w),a2
 moveq #0,d1
 move.b (a0),d1
 lea (a1,d1.w),a3
 move.w (a2),d3
 muls.w 4(a3),d3
 move.w 4(a2),d4
 muls.w (a3),d4
 sub.l d4,d3
 beq.s .next_edge
 moveq #1,d4
 tst.l d3
 bpl.s .sign
 moveq #-1,d4
.sign:
 tst.w d5
 beq.s .first_sign
 cmp.w d4,d5
 bne.s .next_quad
.first_sign:
 move.w d4,d5
.next_edge:
 dbf d6,.edge
 tst.w d5
 bne.s .inside
 moveq #0,d6
 bra.s .next_quad
.inside:
 moveq #1,d0
 rts
.next_quad:
 ; The next list starts five bytes after this quad's start.
 adda.w d6,a0
 addq.w #1,a0
 dbf d7,.quad
.outside:
 moveq #0,d0
 rts
_terrain_indices: dc.b 0,6,18,12,0,12,18,30,24,12
 even

_terrain_continuing: dc.w 0
