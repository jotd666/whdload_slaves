; Copy AI dispatch and hot acceleration helpers after the movement/code copy.
; Called only after CUSTOM2 and CPU/Fast selection, before entering the game.
; Native data/table addresses stay unchanged. Cross-copy relative calls resolve
; directly; the remaining external calls use native JMP stubs. Each span keeps
; an explicit native fallthrough target.
step_physics_aux_init:
 lea $8d2c0,a0
public_ref_200 equ *-4
 lea aux_8d2c0(pc),a1
 move.w #775,d0
.copy_8d2c0:
 move.w (a0)+,(a1)+
 dbf d0,.copy_8d2c0
 lea $8dd66,a0
public_ref_201 equ *-4
 lea aux_8dd66(pc),a1
 move.w #130,d0
.copy_8dd66:
 move.w (a0)+,(a1)+
 dbf d0,.copy_8dd66
 lea $8e166,a0
public_ref_202 equ *-4
 lea aux_8e166(pc),a1
 move.w #183,d0
.copy_8e166:
 move.w (a0)+,(a1)+
 dbf d0,.copy_8e166
 lea $8da5c,a0
public_ref_203 equ *-4
 lea aux_8da5c(pc),a1
 move.w #86,d0
.copy_8da5c:
 move.w (a0)+,(a1)+
 dbf d0,.copy_8da5c
 lea aux_8d2c0(pc),a0
 move.w #aux_8dd66+$0-(aux_8d2c0+$36),$36(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_90b8e-(aux_8d2c0+$94),$94(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_90b7c-(aux_8d2c0+$a8),$a8(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_8dd66+$0-(aux_8d2c0+$13c),$13c(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d940-(aux_8d2c0+$15e),$15e(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8dfc8-(aux_8d2c0+$170),$170(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8db40-(aux_8d2c0+$188),$188(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_8e166+$ec-(aux_8d2c0+$194),$194(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_8dd66+$0-(aux_8d2c0+$1aa),$1aa(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d940-(aux_8d2c0+$1c2),$1c2(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8dfc8-(aux_8d2c0+$1ce),$1ce(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8db40-(aux_8d2c0+$1da),$1da(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_8e166+$ec-(aux_8d2c0+$368),$368(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_8dd66+$0-(aux_8d2c0+$37e),$37e(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_8e166+$ec-(aux_8d2c0+$404),$404(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_8dd66+$0-(aux_8d2c0+$41a),$41a(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d9e2-(aux_8d2c0+$468),$468(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d940-(aux_8d2c0+$52c),$52c(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d91c-(aux_8d2c0+$54c),$54c(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d940-(aux_8d2c0+$568),$568(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d91c-(aux_8d2c0+$588),$588(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d940-(aux_8d2c0+$5a2),$5a2(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d91c-(aux_8d2c0+$5c2),$5c2(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d940-(aux_8d2c0+$5d8),$5d8(a0)
 lea aux_8d2c0(pc),a0
 move.w #aux_to_8d91c-(aux_8d2c0+$5f8),$5f8(a0)
 lea aux_8dd66(pc),a0
 move.w #aux_to_8de6c-(aux_8dd66+$26),$26(a0)
 lea aux_8da5c(pc),a0
 move.w #aux_to_8db0a-(aux_8da5c+$24),$24(a0)
 lea aux_8da5c(pc),a0
 move.w #aux_to_8db0a-(aux_8da5c+$58),$58(a0)
 lea aux_8da5c(pc),a0
 move.w #aux_to_8db0a-(aux_8da5c+$7a),$7a(a0)
 lea aux_8da5c(pc),a0
 move.w #aux_to_8db0a-(aux_8da5c+$9e),$9e(a0)
 nop
 nop
 lea aux_8d2c0+$0(pc),a0
 move.w #$4ef9,$8d2c0
public_ref_204 equ *-4
 move.l a0,$8d2c2
public_ref_205 equ *-4
 lea aux_8d2c0+$14a(pc),a0
 move.w #$4ef9,$8d40a
public_ref_206 equ *-4
 move.l a0,$8d40c
public_ref_207 equ *-4
 lea aux_8d2c0+$1ae(pc),a0
 move.w #$4ef9,$8d46e
public_ref_208 equ *-4
 move.l a0,$8d470
public_ref_209 equ *-4
 lea aux_8d2c0+$226(pc),a0
 move.w #$4ef9,$8d4e6
public_ref_210 equ *-4
 move.l a0,$8d4e8
public_ref_211 equ *-4
 lea aux_8dd66+$0(pc),a0
 move.w #$4ef9,$8dd66
public_ref_212 equ *-4
 move.l a0,$8dd68
public_ref_213 equ *-4
 lea aux_8e166+$0(pc),a0
 move.w #$4ef9,$8e166
public_ref_214 equ *-4
 move.l a0,$8e168
public_ref_215 equ *-4
 lea aux_8e166+$ec(pc),a0
 move.w #$4ef9,$8e252
public_ref_216 equ *-4
 move.l a0,$8e254
public_ref_217 equ *-4
 lea aux_8da5c+$0(pc),a0
 move.w #$4ef9,$8da5c
public_ref_218 equ *-4
 move.l a0,$8da5e
public_ref_219 equ *-4
.done:
 lea step_physics_aux_init(pc),a2
 suba.l #step_physics_aux_init-_resload,a2
 move.l (a2),a2
 jmp aux_lane_width_init(pc)
 nop
 cnop 0,2
aux_8d2c0:
 ds.b 1552
 jmp $8d8d0
public_ref_220 equ *-4
 cnop 0,2
aux_8dd66:
 ds.b 262
 jmp $8de6c
public_ref_221 equ *-4
 cnop 0,2
aux_8e166:
 ds.b 368
 jmp $8e2d6
public_ref_222 equ *-4
 cnop 0,2
aux_8da5c:
 ds.b 174
 jmp $8db0a
public_ref_223 equ *-4
aux_to_8d91c:
 jmp $8d91c
public_ref_224 equ *-4
aux_to_8d940:
 jmp $8d940
public_ref_225 equ *-4
aux_to_8d9e2:
 jmp $8d9e2
public_ref_226 equ *-4
aux_to_8db0a:
 jmp $8db0a
public_ref_227 equ *-4
aux_to_8db40:
 jmp $8db40
public_ref_228 equ *-4
aux_to_8de6c:
 jmp $8de6c
public_ref_229 equ *-4
aux_to_8dfc8:
 jmp $8dfc8
public_ref_230 equ *-4
aux_to_90b7c:
 jmp $90b7c
public_ref_231 equ *-4
aux_to_90b8e:
 jmp $90b8e
public_ref_232 equ *-4

; Padding keeps the hot copied routines aligned.
 ds.b 42
aux_lane_width_init:
; Reuse reserved initialization space without moving any hot copied routines.
; The native table supplies D2 half-width; D4 is leftover render state.
 lea aux_8da5c(pc),a0
 move.w #$d042,$8da96-$8da5c(a0)
 move.w #$9042,$8dab8-$8da5c(a0)
aux_lane_scan_init:
; Only the measured uncached 68020 benefits. The outer gate already excludes 000.
 lea step_physics_aux_init(pc),a0
 suba.l #step_physics_aux_init-cpu_attention,a0
 move.l (a0),d0
 andi.l #$8c,d0 ; AFF_68030 | AFF_68040 | AFF_68060
 bne.s .done
 dc.w $4e7a,$0002 ; MOVEC CACR,D0, executed only on a selected 68020
 btst #0,d0
 bne.s .done
 lea $8d970,a0
public_ref_233 equ *-4
 lea aux_lane_scan_body(pc),a1
 moveq #56,d0
.copy:
 move.w (a0)+,(a1)+
 dbf d0,.copy
 nop
 lea aux_lane_scan(pc),a0
 move.w #$4ef9,$8d966
public_ref_234 equ *-4
 move.l a0,$8d968
public_ref_235 equ *-4
.done:
 jsr (resload_FlushCache,a2)
 rts
aux_lane_scan:
 move.b $71(a1),d7
 subq.w #1,d1
 lea $8d012,a6
public_ref_236 equ *-4
aux_lane_scan_body:
 ds.b $72
