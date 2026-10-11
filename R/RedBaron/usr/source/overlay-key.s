; Ordered exact-byte guard and bounded key storage for the E2 cache.
; Private key: valid.w, program.w, count.w, used.w, 32 range descriptors
; {source.l, expected.l, length.w, reserved.w}, then 8192 snapshot bytes.
; Invalidate valid before freeing/reusing any referenced resource.
OVERLAY_KEY_HEADER = 8+32*12
OVERLAY_KEY_EFFECTS = OVERLAY_KEY_HEADER+8192
OVERLAY_KEY_BYTES = OVERLAY_KEY_EFFECTS+2
; a0=key, d0.w=program; d0.l=match, other registers preserved, CCR volatile.
overlay_key_matches:
 movem.l d1-d3/a0-a3,-(sp)
 IFD VERIFY_OVERLAY_KEY_EXPERIMENT
 lea overlay_key_reads(pc),a3
 clr.l (a3)
 ENDC
 cmpi.w #1,(a0)
 bne .no
 cmp.w 2(a0),d0
 bne .no
 move.w 4(a0),d1
 beq .no
 cmpi.w #32,d1
 bhi .no
 subq.w #1,d1
 addq.l #8,a0
.range
 move.w 8(a0),d2
 beq .no
 cmpi.w #4096,d2
 bhi .no
 move.l (a0),a1
 move.l 4(a0),a2
 IFND VERIFY_OVERLAY_KEY_EXPERIMENT
 ; Keep the diagnostic first-different-byte read counter unchanged. Runtime
 ; ranges use longwords where both addresses are even, without crossing a
 ; descriptor boundary or following a changed selecting pointer.
 move.l a1,d3
 move.l a2,-(sp)
 or.l (sp)+,d3
 btst #0,d3
 bne .bytes
.longs
 cmpi.w #4,d2
 blo .bytes
 cmpm.l (a1)+,(a2)+
 bne .no
 subq.w #4,d2
 bra .longs
.bytes
 tst.w d2
 beq .next_range
 ENDC
 subq.w #1,d2
.byte
 IFD VERIFY_OVERLAY_KEY_EXPERIMENT
 addq.l #1,(a3)
 ENDC
 cmpm.b (a1)+,(a2)+
 bne .no
 dbf d2,.byte
.next_range
 adda.w #12,a0
 dbf d1,.range
 moveq #1,d0
 bra .done
.no
 moveq #0,d0
.done
 movem.l (sp)+,d1-d3/a0-a3
 rts

; Append one dependency in pointer-before-pointee order. Caller owns validity.
; a0=key, a1=source, d0.l=length. d0.l=success; all others preserved.
; A failed append invalidates the whole key and never reads the source.
overlay_key_append:
 movem.l d1-d3/a0-a3,-(sp)
 tst.l d0
 beq .fail
 cmpi.l #4096,d0
 bhi .fail
 moveq #0,d1
 move.w 4(a0),d1
 cmpi.w #32,d1
 bhs .fail
 moveq #0,d2
 move.w 6(a0),d2
 add.l d0,d2
 cmpi.l #8192,d2
 bhi .fail
 move.l a0,a2
 adda.l #OVERLAY_KEY_HEADER,a2
 moveq #0,d3
 move.w 6(a0),d3
 adda.l d3,a2
 mulu.w #12,d1
 lea 8(a0),a3
 adda.l d1,a3
 move.l a1,(a3)
 move.l a2,4(a3)
 move.w d0,8(a3)
 clr.w 10(a3)
 move.w d2,6(a0)
 addq.w #1,4(a0)
 subq.w #1,d0
.copy
 move.b (a1)+,(a2)+
 dbf d0,.copy
 moveq #1,d0
 bra .done
.fail
 clr.w (a0)
 moveq #0,d0
.done
 movem.l (sp)+,d1-d3/a0-a3
 rts
