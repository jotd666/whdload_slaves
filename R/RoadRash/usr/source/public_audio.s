; Separate ProTracker CPU headers/patterns from Paula sample storage.
; Native initialization has already constructed the original Chip sample
; pointers. Publish only the module-base cell after copying the full prefix.
public_audio_main:
 move.w sr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 move.l _expmem(pc),a4
 move.l a4,a1
 adda.l #$5c000,a1
 adda.l #$5000,a4
 move.l a4,a3
 adda.l #$35958,a3
 move.l (a3),a0
 move.l #$5000,d2
 bsr public_audio_copy
 adda.l #$35ad0,a4
 move.w 60(a7),ccr
 bset #1,(a4)
 movem.l (a7)+,d0-d7/a0-a6
 addq.l #2,a7
 rts

public_audio_boot:
 move.w sr,-(a7)
 movem.l d0-d7/a0-a6,-(a7)
 move.l _expmem(pc),a4
 move.l a4,a1
 adda.l #$30000,a1
 adda.l #$42000,a4
 move.l a4,a3
 adda.l #$6774,a3
 move.l (a3),a0
 move.l #$10000,d2
 bsr public_audio_copy
 move.w 60(a7),ccr
 bset #1,$68ec(a4)
 movem.l (a7)+,d0-d7/a0-a6
 addq.l #2,a7
 rts

; A0 native module, A1 destination, A3 module-base owner, D2 capacity.
; The order table includes all 128 slots, matching native sample placement.
public_audio_copy:
 cmpi.l #$4d2e4b2e,1080(a0)
 bne .done
 moveq #0,d0
 moveq #127,d1
 lea 952(a0),a2
.orders:
 cmp.b (a2),d0
 bcc .next
 move.b (a2),d0
.next:
 addq.l #1,a2
 dbf d1,.orders
 addq.l #1,d0
 lsl.l #8,d0
 lsl.l #2,d0
 addi.l #1084,d0
 cmp.l d2,d0
 bhi .done
 move.l a1,d2
 lsr.l #2,d0
 subq.w #1,d0
.copy:
 move.l (a0)+,(a1)+
 dbf d0,.copy
 move.l d2,(a3)
.done:
 rts

; FX/FX2 have 8-byte descriptions followed by Paula sample bytes. Rebase
; each relative sample offset against the public table so the original
; ADD.L module-base consumer still produces the original Chip address.
public_audio_fx:
 move.w sr,-(a7)
 movem.l d0-d3/a0-a3,-(a7)
 move.l _expmem(pc),a3
 move.l a3,a1
 adda.l #$4e000,a1
 adda.l #$3b106,a3
 move.l (a0),d0
 cmpi.l #$40,d0
 beq .valid
 cmpi.l #$58,d0
 bne .native
.valid:
 move.l a0,d1
 sub.l a1,d1
 move.l a1,a2
 lsr.w #3,d0
 subq.w #1,d0
.copy:
 move.l (a0)+,d2
 add.l d1,d2
 move.l d2,(a1)+
 move.l (a0)+,(a1)+
 dbf d0,.copy
 move.l a2,a0
.native:
 move.l a0,(a3)
 move.w 32(a7),ccr
 ; MOVE originally set N/Z from the Chip pointer, even on high Fast maps.
 move.l 16(a7),d0
 movem.l (a7)+,d0-d3/a0-a3
 addq.l #2,a7
 rts
