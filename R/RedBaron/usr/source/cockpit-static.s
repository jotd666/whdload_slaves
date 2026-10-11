; E2 base-layer capture from the native sim:2c144 cookie-cut descriptor.
; Called only within the bit-19/020+ private cockpit stage, after WaitBlit.
; a4=h3+$8000, d7.w=native forced-redraw flag. Preserve all registers.
; Output: cockpit_static_layer={40000-byte FAST image,8000-byte FAST mask}.
; Capture follows the original packed source stride and its bottom-clip rule;
; no screen/background pixels enter the cache. A null layer means fallback.
; The bit-14 lifetime hooks invalidate before source resources can be reused.
; The layer is captured here; suppressing the original draw awaits all layers.
CS_STATIC_BYTES = 48000
cockpit_static_prepare:
 movem.l d0-a6,-(sp)
 move.l cockpit_stage_sim(pc),a3
 adda.l #$2c2b2,a3
 lea cockpit_static_temp(pc),a2
 move.l (a3),d0
 beq cs_static_reject
 move.l $1d62(a4),d1
 beq cs_static_reject
 move.l d0,(a2)
 move.l d1,4(a2)
 or.l d1,d0
 btst #0,d0
 bne cs_static_reject
 moveq #0,d2
 move.w 4(a3),d2 ; destination byte offset
 bmi cs_static_reject
 move.l d2,d0
 divu.w #40,d0
 swap d0
 tst.w d0 ; native full-width copy must start at a row boundary
 bne cs_static_reject
 move.w d2,8(a2)
 moveq #0,d3
 move.w 6(a3),d3 ; native BLTSIZE
 move.w d3,d0
 andi.w #63,d0
 cmpi.w #20,d0
 bne cs_static_reject
 lsr.w #6,d3
 beq cs_static_reject
 move.w d3,d0
 mulu.w #40,d0
 cmp.w 8(a3),d0 ; full source plane stride, including clipped-off rows
 bne cs_static_reject
 move.w d0,12(a2)
 move.w $1d4e(a4),d4
 cmpi.w #75,d4
 blt .height_ready
 cmpi.w #159,d4
 bge .height_ready
 move.w #159,d0
 sub.w d4,d0
 sub.w d0,d3
 ble cs_static_reject
.height_ready
 move.w d3,10(a2)
 clr.w 14(a2)
 mulu.w #40,d3
 add.l d2,d3
 cmpi.l #8000,d3
 bhi cs_static_reject
 lea cockpit_static_valid(pc),a0
 tst.w (a0)
 beq .fill
 tst.w d7
 bne .fill
 tst.b -$ee4(a4) ; native redraw count
 bne .fill
 lea cockpit_static_key(pc),a0
 move.l a2,a1
 moveq #3,d0
.match
 cmpm.l (a0)+,(a1)+
 bne .fill
 dbf d0,.match
 IFD VERIFY
 lea cockpit_static_counts(pc),a0
 addq.l #1,(a0)
 ENDC
 bra cs_static_done
.fill
 bsr cockpit_static_invalidate
 bsr cockpit_static_allocate
 move.l cockpit_static_pool(pc),d0
 beq cs_static_done
 move.l d0,a5
 move.l a5,a0
 move.w #CS_STATIC_BYTES/4-1,d0
.clear
 clr.l (a0)+
 dbf d0,.clear
 moveq #0,d2
 move.w 10(a2),d2
 mulu.w #40,d2 ; accepted bytes per plane
 moveq #0,d3
 move.w 12(a2),d3
 sub.l d2,d3 ; skip clipped source rows
 move.l #8000,d4
 sub.l d2,d4 ; output gap to next full-size plane
 move.l (a2),a0
 move.l a5,a1
 moveq #0,d0
 move.w 8(a2),d0
 adda.l d0,a1
 moveq #4,d5
.plane
 move.w d2,d6
 lsr.w #1,d6
 subq.w #1,d6
.pixels
 move.w (a0)+,(a1)+
 dbf d6,.pixels
 adda.l d3,a0
 adda.l d4,a1
 dbf d5,.plane
 move.l 4(a2),a0
 move.l a5,a1
 adda.l #40000,a1
 moveq #0,d0
 move.w 8(a2),d0
 adda.l d0,a1
 lsr.w #1,d2
 subq.w #1,d2
.mask
 move.w (a0)+,(a1)+
 dbf d2,.mask
 lea cockpit_static_key(pc),a1
 move.l a2,a0
 moveq #3,d0
.key
 move.l (a0)+,(a1)+
 dbf d0,.key
 lea cockpit_static_layer(pc),a0
 move.l a5,(a0)
 adda.l #40000,a5
 move.l a5,4(a0)
 lea cockpit_static_valid(pc),a0
 move.w #1,(a0)
 IFD VERIFY
 lea cockpit_static_counts(pc),a0
 addq.l #1,4(a0)
 ENDC
 bra cs_static_done
cs_static_reject:
 bsr cockpit_static_invalidate
cs_static_done:
 movem.l (sp)+,d0-a6
 rts

cockpit_static_invalidate:
 move.l a0,-(sp)
 lea cockpit_static_valid(pc),a0
 clr.w (a0)
 lea cockpit_static_layer(pc),a0
 clr.l (a0)+
 clr.l (a0)
 move.l (sp)+,a0
 rts

cockpit_static_allocate:
 movem.l d0-d1/a0-a1/a6,-(sp)
 lea cockpit_static_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 move.l #CS_STATIC_BYTES,d0
 move.l #$10004,d1 ; cleared FAST memory, no chip fallback for CPU cache
 jsr _LVOAllocMem(a6)
 lea cockpit_static_pool(pc),a0
 move.l d0,(a0)
.done
 movem.l (sp)+,d0-d1/a0-a1/a6
 rts
cockpit_static_valid: dc.w 0
cockpit_static_attempted: dc.w 0
cockpit_static_pool: dc.l 0
cockpit_static_layer: dc.l 0,0
cockpit_static_key: dcb.b 16,0
cockpit_static_temp: dcb.b 16,0
 IFD VERIFY
cockpit_static_counts: dc.l 0,0 ; hits, fills
 ENDC
