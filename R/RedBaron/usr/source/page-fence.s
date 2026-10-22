; page fence: deferred reuse of the former display page, sim v1 / 030+ / bit 21.
; The native copper stores remain at sim:3154a for external beam observation.

fence_install:
 movem.l d0-a6,-(sp)
 lea fence_sim(pc),a0
 move.l a1,(a0)
 move.l #$574,d0
 moveq #8,d1
 lea .render_bytes(pc),a0
 bsr .check
 move.l #$31522,d0
 moveq #6,d1
 lea .beam_bytes(pc),a0
 bsr .check
 ; The bounded pickup guard below is valid only for this native copper layout.
 move.l a1,a0
 adda.l #$3151a,a0
 move.l (a0),a0
 cmpi.l #$2a01fffe,-4(a0)
 bne fence_bad
 cmpi.l #$2c01fffe,48(a0)
 bne fence_bad
 lea .pace_base(pc),a0
.pace_base
 adda.l #pace_swap-.pace_base,a0
 lea fence_swap_original+2(pc),a3
 move.l (a0),(a3)
 lea fence_swap(pc),a3
 move.l a3,(a0)
 move.l a1,d0
 addi.l #$31528,d0
 lea fence_native_beam_tail+2(pc),a0
 move.l d0,(a0)
 move.l a1,d0
 addi.l #$3154a,d0
 lea fence_publish_tail+2(pc),a0
 move.l d0,(a0)
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 bsr fence_install_boundaries
 jsr resload_FlushCache(a2)
 movem.l (sp)+,d0-a6
 rts
.check
 lea .check_base(pc),a3
.check_base
 adda.l #perf_check_bytes-.check_base,a3
 jmp (a3)
.render_bytes: dc.w $3e2f,$0020,$3c2f,$0022
.beam_bytes: dc.w $2039,$00df,$f004
.patch
 PL_START
 PL_PSS $574,fence_render,2
 PL_P $31522,fence_beam
 PL_END

; Called only through pace_flight's original swap target. Other native swaps
; retain their beam wait. The deadline is sampled AFTER all copper stores, so
; a VBlank interrupt during publication can delay reuse, never release it early.
fence_swap:
 dc.w $42e7
 movem.l d0/a0,-(sp)
 lea fence_in_swap(pc),a0
 move.w #1,(a0)
 clr.w 2(a0)
 movem.l (sp)+,d0/a0
 move.w (sp)+,ccr
 bsr fence_swap_original
 dc.w $42e7
 movem.l d0/a0-a1,-(sp)
 lea fence_in_swap(pc),a0
 clr.w (a0)
 tst.w 2(a0)
 beq .done
 lea .clock(pc),a1
.clock
 adda.l #pace_state-.clock,a1
 move.l (a1),d0
 addq.l #1,d0
 move.l d0,fence_deadline-fence_in_swap(a0)
 move.w #1,fence_pending-fence_in_swap(a0)
.done
 movem.l (sp)+,d0/a0-a1
 move.w (sp)+,ccr
 rts
fence_swap_original:
 jsr $0.l
 rts

; Entered after native TST d1 selected the safe flight path. Skip only the
; beam spin; the original MOVEM publishes the complete unchanged pointer set.
fence_beam:
 dc.w $42e7
 movem.l d0/a0,-(sp)
 lea fence_in_swap(pc),a0
 tst.w (a0)
 beq fence_beam_native
 tst.w fence_scene_owned-fence_in_swap(a0)
 beq fence_beam_native
 ; Native copper waits at line 42, executes twelve pointer moves, then waits
 ; at line 44 before enabling bitplanes. Never modify the pointer block while
 ; that pickup can be in progress. Reserve line 40 for the wrapper tail: a
 ; sample at the end of line 40 otherwise reaches the native MOVEM at 41.
 ; >=44 is after the complete pickup. No full-frame beam spin remains.
.pickup
 move.l $dff004,d0
 andi.l #$1ff00,d0
 cmpi.l #$2700,d0
 ble .safe
 cmpi.l #$2c00,d0
 blt .pickup
.safe
 move.w #1,2(a0)
 movem.l (sp)+,d0/a0
 move.w (sp)+,ccr
fence_publish_tail:
 jmp $0.l
fence_beam_native:
 movem.l (sp)+,d0/a0
 move.w (sp)+,ccr
 move.l $dff004,d0
fence_native_beam_tail:
 jmp $0.l

; Only the unchanged forward prelude is allowed to overlap display scanning.
; Redraw flags, view transitions, full-screen flashes and other views fence at
; entry. The private scene validates its own geometry; rejection fences there.
fence_render:
 move.w 36(sp),d7
 move.w 38(sp),d6
 bsr cockpit_fast_begin
 dc.w $42e7
 movem.l d0/a0,-(sp)
 lea fence_scene_owned(pc),a0
 clr.w (a0)
 tst.w d7
 bne .fallback
 move.l scene_frame_h3(pc),a0
 adda.l #$4000,a0
 tst.l $922(a0) ; h3:4922/4924 full-screen replacement
 bne .fallback
 tst.w $588(a0) ; h3:4588 forced redraw count
 bne .fallback
 tst.l $2712(a0) ; h3:6712 current view / 6714 previous view
 bne .fallback
 tst.w $2716(a0) ; h3:6716 background restore count
 beq .done
.fallback
 bsr fence_wait
.done
 movem.l (sp)+,d0/a0
 move.w (sp)+,ccr
 rts

; Called after a custom-register base is selected. The native path is fenced;
; a private software drawing operation can continue while the page is scanned.
fence_wait_native:
 dc.w $42e7
 move.l d0,-(sp)
 move.w scene_frame_active(pc),d0
 bne .done
 bsr fence_wait
.done
 move.l (sp)+,d0
 move.w (sp)+,ccr
 rts

; Preserve all inputs and flags, including X. Deadline subtraction is wrap-safe
; for this one-field obligation. IRQs remain enabled throughout the wait.
fence_wait:
 dc.w $42e7
 movem.l d0/a0-a1,-(sp)
 lea fence_pending(pc),a0
 tst.w (a0)
 beq .done
 lea .clock(pc),a1
.clock
 adda.l #pace_state-.clock,a1
 move.l (a1),d0
 sub.l fence_deadline-fence_pending(a0),d0
 bpl .ready
.wait
 move.l (a1),d0
 sub.l fence_deadline-fence_pending(a0),d0
 bmi .wait
.ready
 clr.w (a0)
.done
 movem.l (sp)+,d0/a0-a1
 move.w (sp)+,ccr
 rts

fence_sim: dc.l 0
fence_in_swap: dc.w 0
fence_skipped: dc.w 0
fence_scene_owned: dc.w 0
fence_pending: dc.w 0
fence_deadline: dc.l 0

; Implemented with checked whole-instruction boundary veneers below.
fence_install_boundaries:
 ; Validate relocated operands against this sim's data hunk, not an address
 ; from a particular boot. All other displaced instructions are literal checks.
 move.l scene_frame_h3(pc),d0
 addi.l #$32fe,d0
 lea .pause_expected+2(pc),a0
 move.l d0,(a0)
 move.l scene_frame_h3(pc),d0
 addi.l #$3254,d0
 lea .exit_expected+2(pc),a0
 move.l d0,(a0)+
 move.l scene_frame_h3(pc),d0
 addi.l #$7778,d0
 move.l d0,(a0)
 lea .checks(pc),a3
 lea fence_boundary_code(pc),a6
 moveq #6,d5
.next
 move.l fence_sim(pc),a4
 adda.l (a3)+,a4
 move.w (a3)+,d6
 move.w (a3)+,d7
 move.l a4,a0
 move.l a3,a1
 move.w d6,d0
 subq.w #1,d0
.compare
 cmpm.b (a0)+,(a1)+
 bne fence_bad
 dbf d0,.compare
 adda.w d6,a3
 move.l a6,a1
 move.w #$4eb9,(a1)+
 lea cockpit_fast_boundary(pc),a0
 move.l a0,(a1)+
 tst.w d7
 bne .map
 move.l a4,a0
 move.w d6,d0
 lsr.w #1,d0
 subq.w #1,d0
.copy
 move.w (a0)+,(a1)+
 dbf d0,.copy
 bra .tail
.map
 ; The map entry contains a short BSR: emit its absolute equivalent after
 ; the native MOVEM instead of copying a PC-relative displacement.
 move.l (a4),(a1)+
 move.w #$4eb9,(a1)+
 move.l fence_sim(pc),d0
 addi.l #$275a6,d0
 move.l d0,(a1)+
.tail
 move.w #$4ef9,(a1)+
 move.l a4,a0
 adda.w d6,a0
 move.l a0,(a1)+
 move.w #$4ef9,(a4)
 move.l a6,2(a4)
 adda.w #32,a6
 dbf d5,.next
 rts
.checks
 dc.l $1f0d2
 dc.w 8,0,$4e55,$fff0,$48e7,$0f10
 dc.l $1fa8a
 dc.w 6,0,$4e55,$ffe4,$7019
 dc.l $1fb40
 dc.w 6,0,$2040,$3e10,$554f
 dc.l $21ac8
 dc.w 6,0
.pause_expected
 dc.w $4879
 dc.l 0
 dc.l $21f4a
 dc.w 10,0
.exit_expected
 dc.w $23f9
 dc.l 0,0
 dc.l $275e2
 dc.w 6,1,$48e7,$3000,$61be
 ; The forward object-list overflow can invoke the native error dialog
 ; before scene entry. Fence this exceptional path before any OS display work.
 dc.l $29652
 dc.w 8,0,$48e7,$0130,$266f,$0010
fence_boundary_code: dcb.b 7*32,0
fence_bad:
 pea .message(pc)
 pea TDREASON_FAILMSG
 lea .resload(pc),a2
.resload
 adda.l #_resload-.resload,a2
 move.l (a2),a2
 jmp resload_Abort(a2)
.message: dc.b "Red Baron: unexpected deferred-fence hook",0
 even
