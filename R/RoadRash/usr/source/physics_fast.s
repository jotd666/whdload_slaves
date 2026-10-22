; Movement/collision code copy for the selected enhanced Fast RAM path.
; Initialize after the simulation patch list and before entering the loaded game.
; Most absolute data references stay native; two shared scratch words move
; with all their native users before copying. External branches need stubs.
; Embedded tables retain their native aliases. Steering wrappers return
; to their original code addresses.
step_physics_fast_init:
 bsr step_scratch_init
 lea $8b486,a0
public_ref_160 equ *-4
 lea step_physics_fast_code(pc),a1
 move.w #7040/4-1,d0
.copy:
 move.l (a0)+,(a1)+
 dbf d0,.copy
 lea step_physics_fast_code(pc),a0
 lea step_physics_fast_fixups(pc),a1
.fix:
 move.w (a1)+,d0
 bmi .patched
 move.w (a1)+,d1
 move.w d1,(a0,d0.w)
 bra .fix
.patched:
 bsr step_pair_clear_init
 nop
 nop
 lea step_physics_fast_code+$0(pc),a0
 move.w #$4ef9,$8b486
public_ref_161 equ *-4
 move.l a0,$8b488
public_ref_162 equ *-4
 lea step_physics_fast_code+$1122(pc),a0
 move.w #$4ef9,$8c5a8
public_ref_163 equ *-4
 move.l a0,$8c5aa
public_ref_164 equ *-4
 lea step_physics_fast_code+$1428(pc),a0
 move.w #$4ef9,$8c8ae
public_ref_165 equ *-4
 move.l a0,$8c8b0
public_ref_166 equ *-4
 lea step_physics_fast_code+$760(pc),a0
 move.w #$4ef9,$8bbe6
public_ref_167 equ *-4
 move.l a0,$8bbe8
public_ref_168 equ *-4
 lea step_physics_fast_code+$666(pc),a0
 move.w #$4ef9,$8baec
public_ref_169 equ *-4
 move.l a0,$8baee
public_ref_170 equ *-4
 lea step_physics_fast_code+$caa(pc),a0
 move.w #$4ef9,$8c130
public_ref_171 equ *-4
 move.l a0,$8c132
public_ref_172 equ *-4
 lea step_physics_fast_code+$1008(pc),a0
 move.w #$4ef9,$8c48e
public_ref_173 equ *-4
 move.l a0,$8c490
public_ref_174 equ *-4
 lea step_physics_fast_code+$1a6a(pc),a0
 move.w #$4ef9,$8cef0
public_ref_175 equ *-4
 move.l a0,$8cef2
public_ref_176 equ *-4
.done:
 lea step_physics_fast_init(pc),a2
 suba.l #step_physics_fast_init-_resload,a2
 move.l (a2),a2
 jsr (resload_FlushCache,a2)
 rts
; Called inside the master-toggle/CPU/Fast gate, before copying physics.
; Patch all native absolute users, including the pose renderer; the copy then
; inherits those pointers. Each pair/pose traversal clears scratch before use.
; Data remains in the selected public Fast slave hunk; no DMA consumes it.
step_scratch_init:
 move.w step_scratch_enabled(pc),d0
 beq .done
 lea step_scratch_words(pc),a2
 move.w $8b480,(a2)
public_ref_177 equ *-4
 move.w $a59ca,2(a2)
public_ref_178 equ *-6
 move.l a2,d1
 lea .first(pc),a0
 bsr .patch
 addq.l #2,d1
 lea .second(pc),a0
 bsr .patch
.done:
 rts
.patch:
 move.l (a0)+,d0
 beq .return
 move.l d0,a1
 move.l d1,(a1)
 bra .patch
.return:
 rts
.first:
 dc.l $8c8b0,$8ce6c,0
public_ref_179 equ *-12
public_ref_180 equ *-8
.second:
 dc.l $89d60,$89e1a,$89f04,$89f92,$89fc4
public_ref_181 equ *-20
public_ref_182 equ *-16
public_ref_183 equ *-12
public_ref_184 equ *-8
public_ref_185 equ *-4
 dc.l $8c8b6,$8c9de,$8ca0a,$8ca22,$8cb08,$8cb34,$8cb4c,0
public_ref_186 equ *-32
public_ref_187 equ *-28
public_ref_188 equ *-24
public_ref_189 equ *-20
public_ref_190 equ *-16
public_ref_191 equ *-12
public_ref_192 equ *-8
step_scratch_words: dc.w 0,0
step_scratch_enabled:
 dc.w 1
 cnop 0,4
; The copied pair tail originally performs three unconditional Chip writes.
; Test before clearing: BTST and BCLR both alter only Z, using the old bit.
; The final test/clear therefore preserves the native CCR result, even if
; A1 and A2 alias. No data/address registers are changed by the tail.
step_pair_clear_init:
 move.w step_pair_clear_enabled(pc),d0
 beq .done
 lea step_physics_fast_code+$8cb70-$8b486(pc),a0
 lea step_pair_clear(pc),a1
 move.w #$4ef9,(a0)
 move.l a1,2(a0)
.done:
 rts
step_pair_clear:
 btst #4,$68(a1)
 beq .second
 bclr #4,$68(a1)
.second:
 btst #7,$69(a1)
 beq .third
 bclr #7,$69(a1)
.third:
 btst #7,$69(a2)
 beq .done
 bclr #7,$69(a2)
.done:
 rts
step_pair_clear_enabled:
 dc.w 1
 cnop 0,4
step_physics_fast_fixups:
 dc.w $88,step_physics_to_8e166-(step_physics_fast_code+$88)
 dc.w $de,step_physics_to_8e166-(step_physics_fast_code+$de)
 dc.w $14e,step_physics_to_8da5c-(step_physics_fast_code+$14e)
 dc.w $4a8,step_physics_to_8e2d6-(step_physics_fast_code+$4a8)
 dc.w $502,step_physics_to_8e2d6-(step_physics_fast_code+$502)
 dc.w $74c,step_physics_to_8e91c-(step_physics_fast_code+$74c)
 dc.w $88e,step_physics_to_8de84-(step_physics_fast_code+$88e)
 dc.w $d88,step_physics_to_8e614-(step_physics_fast_code+$d88)
 dc.w $d9e,step_physics_to_8e614-(step_physics_fast_code+$d9e)
 dc.w $dc6,step_physics_to_8eaf0-(step_physics_fast_code+$dc6)
 dc.w $e80,step_physics_to_8e70c-(step_physics_fast_code+$e80)
 dc.w $eda,step_physics_to_8e70c-(step_physics_fast_code+$eda)
 dc.w $11ec,step_physics_to_8e614-(step_physics_fast_code+$11ec)
 dc.w $11f4,step_physics_to_8eaf0-(step_physics_fast_code+$11f4)
 dc.w $1256,step_physics_to_8e70c-(step_physics_fast_code+$1256)
 dc.w $12c4,step_physics_to_8e70c-(step_physics_fast_code+$12c4)
 dc.w $17a6,step_physics_to_8dade-(step_physics_fast_code+$17a6)
 dc.w -1
 cnop 0,4
step_physics_fast_code:
 ds.b 7040
step_physics_to_8da5c:
 jmp aux_8da5c+$0(pc)
 nop
step_physics_to_8dade:
 jmp $8dade
public_ref_193 equ *-4
step_physics_to_8de84:
 jmp $8de84
public_ref_194 equ *-4
step_physics_to_8e166:
 jmp aux_8e166+$0(pc)
 nop
step_physics_to_8e2d6:
 jmp $8e2d6
public_ref_195 equ *-4
step_physics_to_8e614:
 jmp $8e614
public_ref_196 equ *-4
step_physics_to_8e70c:
 jmp $8e70c
public_ref_197 equ *-4
step_physics_to_8e91c:
 jmp $8e91c
public_ref_198 equ *-4
step_physics_to_8eaf0:
 jmp $8eaf0
public_ref_199 equ *-4
