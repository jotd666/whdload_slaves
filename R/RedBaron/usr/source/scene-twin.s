; VERIFY only: one native pixel twin for each direct primitive. No world replay.
; Private snapshots reuse reserved workspace; never enter normal/developer builds.
scene_twin_before:
 movem.l d0-a6,-(sp)
 lea scene_twin_result(pc),a5
 clr.l 4(a5)
 move.l scene_packet(pc),d0
 move.l (a5),d1
 btst d0,d1
 bne .done
 move.l #1,4(a5)
 bsr scene_frame_wait
 move.l scene_frame_storage(pc),a1
 adda.l #PERF_SCENE_TWIN_SCREEN,a1
 move.l scene_frame_original(pc),a0
 move.w #1250-1,d7
 bsr scene_frame_copy32
 move.l scene_frame_storage(pc),a1
 adda.l #PERF_SCENE_TWIN_SCRATCH,a1
 move.l scene_frame_original+4(pc),a0
 move.w #250-1,d7
 bsr scene_frame_copy32
 ; Give the native renderer exactly the candidate's pre-operation pixels.
 move.l scene_frame_buffer(pc),a0
 move.l scene_frame_original(pc),a1
 move.w #1250-1,d7
 bsr scene_frame_copy32
 move.l scene_frame_original+4(pc),a1
 move.w #250-1,d7
 bsr scene_frame_copy32
.done
 movem.l (sp)+,d0-a6
 rts

scene_twin_after:
 movem.l d0-a6,-(sp)
 lea scene_twin_result(pc),a5
 tst.l 4(a5)
 beq .done
 move.l scene_frame_h3(pc),a6
 adda.l #$8000,a6
 lea scene_frame_active(pc),a0
 clr.w (a0)
 move.l scene_frame_original(pc),$1d72(a6)
 move.l scene_frame_original+4(pc),$1d76(a6)
 lea scene_packet(pc),a4
 cmpi.l #2,(a4)
 beq .polygon
 move.l 12(a4),d0
 move.l 16(a4),d1
 move.l 20(a4),d2
 move.l 24(a4),d3
 move.l scene_primitive_sim(pc),a0
 tst.l (a4)
 bne .line
 adda.l #$2fc68,a0
 bra .draw
.line
 adda.l #$2ea28,a0
.draw
 jsr (a0)
 bra .compare
.polygon
 lea $dff000,a0
 move.l #$ffffffff,$44(a0)
 move.w #2,$42(a0)
 move.l 16(a4),d0
 add.w d0,d0
 neg.w d0
 addi.w #40,d0
 move.w d0,$64(a0)
 move.w d0,$60(a0)
 move.w d0,$66(a0)
 move.l 20(a4),d2
 lsl.w #6,d2
 or.w 18(a4),d2
 move.l scene_frame_original+4(pc),d0
 add.l 12(a4),d0
 move.l scene_frame_original(pc),d1
 add.l 12(a4),d1
 move.l 28(a4),d5
 moveq #4,d6
.plane
 bsr scene_frame_wait
 move.w #$0b0a,d3
 lsr.w #1,d5
 bcc .black
 move.w #$0bfa,d3
.black
 move.w d3,$40(a0)
 move.l d0,$50(a0)
 move.l d1,$48(a0)
 move.l d1,$54(a0)
 move.w d2,$58(a0)
 addi.l #8000,d1
 dbf d6,.plane
.compare
 bsr scene_frame_wait
 move.l scene_frame_buffer(pc),a0
 move.l scene_frame_original(pc),a1
 move.w #9999,d7
.words
 cmpm.l (a0)+,(a1)+
 bne .bad
 dbf d7,.words
 move.l scene_frame_storage(pc),a0
 adda.l #PERF_SCENE_TWIN_SCREEN,a0
 move.l scene_frame_original(pc),a1
 move.w #1250-1,d7
 bsr scene_frame_copy32
 move.l scene_frame_storage(pc),a0
 adda.l #PERF_SCENE_TWIN_SCRATCH,a0
 move.l scene_frame_original+4(pc),a1
 move.w #250-1,d7
 bsr scene_frame_copy32
 move.l scene_frame_h3(pc),a6
 adda.l #$8000,a6
 move.l scene_frame_buffer(pc),d0
 move.l d0,$1d72(a6)
 addi.l #40000,d0
 move.l d0,$1d76(a6)
 lea scene_frame_active(pc),a0
 move.w #1,(a0)
 lea scene_twin_result(pc),a5
 move.l scene_packet(pc),d0
 move.l (a5),d1
 bset d0,d1
 move.l d1,(a5)
 clr.l 4(a5)
 addq.l #1,8(a5)
.done
 movem.l (sp)+,d0-a6
 rts
.bad
 move.l a0,12(a5)
 move.l a1,16(a5)
 bra scene_frame_bad
scene_twin_result: dc.l 0,0,0,0,0 ; passed bits, armed, count, mismatch pointers
