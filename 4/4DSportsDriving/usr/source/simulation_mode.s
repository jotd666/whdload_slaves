; Extended graphics/simulation dialog, using the original modal frame and
; menu renderer. Native entry already ran LINK A5,#-$21E and modal entry.
; Buffer: A5-$21E..-$1F (512 bytes). Nine word flags: A5-$1E..-$D.
; Selected mode changes here; active/race mode changes only at native setup.
sim_mode_dialog:
 movem.l d2-d7/a2-a3,-(sp)
 lea sim_mode_opens(pc),a0
 addq.l #1,(a0)
 move.w -$bc(a4),d6
 moveq #0,d7
.loop:
 lea -$1e(a5),a0
 moveq #8,d0
.clear:
 clr.w (a0)+
 dbra d0,.clear
 moveq #0,d0
 move.b -$7708(a4),d0
 cmp.w #4,d0
 bhi .mode
 add.w d0,d0
 lea -$1e(a5),a0
 move.w #2,(a0,d0.w)
.mode:
 moveq #5,d0
 cmp.w #10,-$bc(a4)
 beq .mark
 moveq #6,d0
 cmp.w #20,-$bc(a4)
 beq .mark
 moveq #7,d0
.mark:
 add.w d0,d0
 lea -$1e(a5),a0
 move.w #2,(a0,d0.w)
 lea sim_mode_text(pc),a0
 lea -$21e(a5),a1
.copy:
 move.b (a0)+,(a1)+
 bne .copy
 lea -$21e(a5),a0
 lea -$1e(a5),a1
.stars:
 move.b (a0)+,d0
 beq .show
 cmp.b #'[',d0
 bne .stars
 tst.w (a1)+
 beq .stars
 move.b #'*',(a0)
 bra .stars
.show:
 move.w d7,-(sp)
 pea -$1e(a5)
 move.w -$45ce(a4),-(sp)
 move.w #-1,-(sp)
 move.w #-1,-(sp)
 pea -$21e(a5)
 move.w #1,-(sp)
 move.w #2,-(sp)
 lea sim_mode_dialog(pc),a0
 adda.l #sim_game-sim_mode_dialog,a0
 move.l (a0),a0
 adda.l #$17034,a0
 jsr (a0)
 lea 20(sp),sp
 move.b d0,d7
 ext.w d7
 bmi .done
 cmp.w #8,d7
 bhs .done
 cmp.w #5,d7
 blo .graphics
 moveq #10,d0
 cmp.w #5,d7
 beq .select
 moveq #20,d0
 cmp.w #6,d7
 bne .a4000
 tst.w -$4628(a4)          ; retain the original A2500 benchmark gate
 bne .loop
 bra .select
.a4000:
 lea sim_mode_dialog(pc),a0
 adda.l #sim_time_field_hz-sim_mode_dialog,a0
 cmp.w #50,(a0)
 bne .loop                ; experimental A4000 remains PAL-only
 moveq #50,d0             ; manual selection; PAL 040/060 also default to this rate
.select:
 lea sim_mode_changes(pc),a0
 addq.l #1,(a0)
 move.w -$bc(a4),4(a0)
 move.w d0,6(a0)
 move.w -$15fa(a4),8(a0)
 moveq #0,d1
 move.b -$173a(a4),d1
 move.w d1,10(a0)
 move.w d0,-$bc(a4)
 bra .loop
.graphics:
 move.b d7,-$7708(a4)
 bra .loop
.done:
 cmp.w -$bc(a4),d6
 beq .close
 bsr sim_preferences_save
 ; Preserve the game's localized next-race notice and original dialog ABI.
 clr.w -(sp)
 clr.l -(sp)
 move.w -$45ce(a4),-(sp)
 move.w #-1,-(sp)
 move.w #-1,-(sp)
 lea sim_mode_dialog(pc),a0
 adda.l #sim_game-sim_mode_dialog,a0
 move.l (a0),a0
 adda.l #$1ad52,a0
 pea (a0)
 move.l -$77fc(a4),-(sp)
 lea sim_mode_dialog(pc),a0
 adda.l #sim_game-sim_mode_dialog,a0
 move.l (a0),a0
 adda.l #$18f94,a0
 jsr (a0)
 addq.l #8,sp
 move.l d0,-(sp)
 move.w #1,-(sp)
 move.w #1,-(sp)
 lea sim_mode_dialog(pc),a0
 adda.l #sim_game-sim_mode_dialog,a0
 move.l (a0),a0
 adda.l #$17034,a0
 jsr (a0)
 lea 20(sp),sp
.close:
 lea sim_mode_dialog(pc),a0
 adda.l #sim_game-sim_mode_dialog,a0
 move.l (a0),a0
 adda.l #$1a7b0,a0
 jsr (a0)
 movem.l (sp)+,d2-d7/a2-a3
 unlk a5
 rts
 even
 dc.b "4DMODEUI"
 dc.w 1,0
sim_mode_opens: dc.l 0
sim_mode_changes: dc.l 0
 dc.w 0,0,0,0             ; previous, selected, active and recorded at choice
sim_mode_text:
 dc.b "Graphic levels]}[  FULL][  FULL, no clds/scnry.]"
 dc.b "[  MEDIUM, no clds/scnry.][  FAST, no clds/scnry.]"
 dc.b "[  FAST, no clds/scnry/horiz.]}[  Normal Simulation Speed]"
 dc.b "[  A2500 Simulation Speed][  A4000 Simulation Speed]}[  Done]",0
 even
