; The native route builder indexes its 16-byte "sped" table with a track
; piece byte (0..255). A4000 races use a private, initialized 256-byte table:
; preserve all 16 defined costs and give undefined entries cost 0 (+1 in the
; native accumulator). This retains the native traversal/tie-breaking rule
; without depending on resource-adjacent heap contents. Format-2 replays
; continue to install their recorded route after native resource loading.
; Normal/A2500 keep the original pointer and every original table read.
;
; $16346 replaces MOVE.L D0,-$F26(A5); CLR.W -2(A5).
; D0 is the freshly loaded speed resource. Preserve registers and the flags
; of the final CLR, including X. Never write outside the private table.
sim_opponent_route_prepare:
 move.l d0,-$f26(a5)
 cmp.w #50,-$15fa(a4)
 bne .native
 movem.l d0-d1/a0-a1,-(sp)
 movea.l d0,a1
 lea sim_opponent_route_costs(pc),a0
 moveq #63,d1
.clear:
 clr.l (a0)+
 dbra d1,.clear
 lea sim_opponent_route_costs(pc),a0
 moveq #15,d1
.copy:
 move.b (a1)+,(a0)+
 dbra d1,.copy
 lea sim_opponent_route_costs(pc),a0
 move.l a0,-$f26(a5)
 lea sim_opponent_route_prepared(pc),a0
 movea.l (a0),a1
 addq.l #1,a1             ; address arithmetic preserves the caller's X flag
 move.l a1,(a0)
 movem.l (sp)+,d0-d1/a0-a1
.native:
 clr.w -2(a5)
 rts
 even
sim_opponent_route_prepared: dc.l 0
sim_opponent_route_costs: dcb.b 256,0
