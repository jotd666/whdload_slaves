; CPU-neutral selective repair of static cockpit words. No bounding-box scan.
; The list contains only covered 16-pixel words, including opaque black.
; A matching pixel incurs no write; uncovered bits always retain current scene.
; a0=40000-byte native image, a1=8000-byte exact mask, a2=14338-byte list.
; Format: count.w, then {offset.w,mask.w,colour[5].w}. Maximum 1024 records; larger coverage falls back.
artwork_sparse_pack:
 movem.l d1-d7/a0-a4,-(sp)
 move.l a2,a4
 clr.w (a2)+
 moveq #0,d1
 move.w #3999,d7
.word
 move.w (a1)+,d2
 beq .next
 cmpi.w #1024,(a4)
 bhs .overflow
 addq.w #1,(a4)
 move.w d1,(a2)+
 move.w d2,(a2)+
 move.l a0,a3
 moveq #4,d6
.plane
 move.w (a3),d3
 and.w d2,d3
 move.w d3,(a2)+
 adda.l #8000,a3
 dbf d6,.plane
.next
 addq.l #2,a0
 addq.w #2,d1
 dbf d7,.word
 moveq #1,d0
 bra .done
.overflow
 clr.w (a4)
 moveq #0,d0
.done
 movem.l (sp)+,d1-d7/a0-a4
 rts

; a0=list, a1=current draw page. All registers preserved; CCR volatile.
; Actual destination pixels are the validity guard, independently on each page.
; This remains correct after scene writes, messages or a full page clear.
artwork_sparse_update:
 movem.l d0-d4/a0-a2,-(sp)
 bsr artwork_wait
 move.w (a0)+,d4
 beq .done
 subq.w #1,d4
.word
 moveq #0,d0
 move.w (a0)+,d0
 move.l a1,a2
 adda.w d0,a2
 move.w (a0)+,d1
 move.w (a2),d2
 move.w (a0)+,d3
 eor.w d2,d3
 and.w d1,d3
 beq .plane0_same
 eor.w d3,d2
 move.w d2,(a2)
.plane0_same
 move.w 8000(a2),d2
 move.w (a0)+,d3
 eor.w d2,d3
 and.w d1,d3
 beq .plane1_same
 eor.w d3,d2
 move.w d2,8000(a2)
.plane1_same
 move.w 16000(a2),d2
 move.w (a0)+,d3
 eor.w d2,d3
 and.w d1,d3
 beq .plane2_same
 eor.w d3,d2
 move.w d2,16000(a2)
.plane2_same
 move.w 24000(a2),d2
 move.w (a0)+,d3
 eor.w d2,d3
 and.w d1,d3
 beq .plane3_same
 eor.w d3,d2
 move.w d2,24000(a2)
.plane3_same
 move.w 32000(a2),d2
 move.w (a0)+,d3
 eor.w d2,d3
 and.w d1,d3
 beq .plane4_same
 eor.w d3,d2
 move.w d2,32000(a2)
.plane4_same
 dbf d4,.word
.done
 movem.l (sp)+,d0-d4/a0-a2
 rts

artwork_wait:
 tst.w $dff002
.wait
 btst #6,$dff002
 bne .wait
 rts

 IFD VERIFY
artwork_bad:
 pea artwork_mismatch_message(pc)
artwork_abort:
 pea TDREASON_FAILMSG
 lea .base(pc),a2
.base
 adda.l #_resload-.base,a2
 move.l (a2),a2
 jmp resload_Abort(a2)
artwork_mismatch_message: dc.b "Red Baron: sparse artwork pixel/state mismatch",0
 even
 ENDC
