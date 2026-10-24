; Move the complete patched rr.ice HUNK_CODE image into optional public RAM.
; Called after the simulation copy initializers; independently gates CUSTOM2/Fast.
; Native 68000 keeps its original simulation and gains code/data/stack placement.
; Keep the original Chip heap endpoint and all external DMA buffers unchanged.
; Validate the surviving native HUNK_RELOC32 block before changing anything.
; Never guess pointers from arbitrary words: use native relocation offsets
; and explicitly annotated slave operands.
public_main_init:
 movem.l d0-d7/a0-a6,-(a7)
 move.l _enhanced_framerate(pc),d0
 beq .done
 move.l _expmem(pc),a5
 cmpa.l #$200000,a5
 bcs .done
 cmpa.l #$a00000,a5
 bcs .placement_ok
 cmpa.l #$1000000,a5
 bcs .done
.placement_ok:
 cmpi.l #$3ec,$bc40c
 bne .done
 cmpi.l #5173,$bc410
 bne .done
 ; Validate every original HUNK record before copying or patching anything.
 tst.l $bc414
 bne .done
 tst.l $c14ec
 bne .done
 cmpi.l #$3f2,$c14f0
 bne .done
 lea $bc418,a0
 move.w #5173-1,d0
.validate:
 move.l (a0)+,d1
 btst #0,d1
 bne .done
 cmpi.l #$3c3ec-4,d1
 bhi .done
 dbf d0,.validate
 lea $5000(a5),a5
 lea $80000,a0
 move.l a5,a1
 move.w #$3c3ec/4-1,d0
.copy:
 move.l (a0)+,(a1)+
 dbf d0,.copy
 move.l a5,d7
 sub.l #$80000,d7
 moveq #0,d2
 move.l #$3c3ec,d3
 move.l a5,a4
 bsr public_main_remap_span
 ; Simulation copies were never initialized on the native CPU path.
 move.l enhanced_selected(pc),d0
 cmpi.l #3,d0
 bne .helpers
 lea public_main_spans(pc),a6
.spans:
 move.l (a6)+,d2
 bmi .helpers
 move.l (a6)+,d3
 add.l d2,d3
 move.l (a6)+,d0
 lea _base(pc),a4
 adda.l d0,a4
 bsr public_main_remap_span
 bra .spans
.helpers:
 lea _base(pc),a6
 adda.l #public_main_helper_refs-_base,a6
.next_helper:
 move.l (a6)+,d0
 bmi .publish
 lea _base(pc),a1
 adda.l d0,a1
 bsr public_main_adjust
 bra .next_helper
.publish:
 ; Menu pictures reuse actor storage, but only their front-end operands must
 ; remain Chip for blitter DMA. Race actor references still point to Fast RAM.
 lea public_main_menu_dma(pc),a0
.menu_dma:
 move.w (a0)+,d0
 bmi .menu_dma_done
 move.l a5,a1
 adda.w d0,a1
 sub.l d7,(a1)
 bra .menu_dma
.menu_dma_done:
 bsr f_cpu_init
 bsr e_blitter_init
 bsr public_iff_init
 bsr public_menu_init
 bsr public_recolor_init
 move.l a5,a1
 adda.l #$35236,a1
 cmpi.l #$08f90001,(a1)
 bne .audio_done
 move.l a5,d0
 addi.l #$35ad0,d0
 cmp.l 4(a1),d0
 bne .audio_done
 lea public_audio_main(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 move.w #$4e71,6(a1)
.audio_done:
 move.l a5,a1
 adda.l #$36050,a1
 cmpi.w #$23c8,(a1)
 bne .fx_done
 move.l a5,d0
 addi.l #$36106,d0
 cmp.l 2(a1),d0
 bne .fx_done
 lea public_audio_fx(pc),a0
 move.w #$4eb9,(a1)
 move.l a0,2(a1)
.fx_done:
 lea public_asset_pool(pc),a0
 move.l a5,d0
 addi.l #$4b000,d0
 move.l d0,(a0)
 bsr public_asset_init
 move.l a5,a1
 adda.l #$2fd9c,a1
 lea public_asset_relocate(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 ; Also install the guarded stack for a relocated native main image.
 move.l a5,a1
 adda.l #$2876c,a1
 lea _base(pc),a0
 adda.l #step_stack_start-_base,a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 move.l a5,a1
 adda.l #$d000,a1
 lea public_main_lane_lookup(pc),a0
 move.w #$4eb9,$b42(a1)
 move.l a0,$b44(a1)
 move.w #$4e71,$b48(a1)
 move.w #$4eb9,$b7e(a1)
 move.l a0,$b80(a1)
 move.w #$4e71,$b84(a1)
 move.l a5,d0
 add.l #$d128,d0
 move.l d0,2(a0)
 lea expansion_memory(pc),a0
 move.l a5,(a0)
 move.w #$4ef9,$80000
 move.l a5,$80002
 move.l _resload(pc),a2
 jsr (resload_FlushCache,a2)
.done:
 movem.l (a7)+,d0-d7/a0-a6
 rts
; d2/d3: source span offsets, a4: copied span base, d7: relocation delta.
public_main_remap_span:
 lea $bc418,a3
 move.w #5173-1,d6
.fix:
 move.l (a3)+,d0
 cmp.l d2,d0
 bcs .next
 cmp.l d3,d0
 bcc .next
 sub.l d2,d0
 move.l a4,a1
 adda.l d0,a1
 bsr public_main_adjust
.next:
 dbf d6,.fix
 rts
public_main_adjust:
 move.l (a1),d1
 cmpi.l #$80000,d1
 bcs .done
 cmpi.l #$bc3ec,d1
 bcc .done
 add.l d7,(a1)
.done:
 rts
public_main_spans:
 dc.l $b486,$1b80,step_physics_fast_code-_base
 dc.l $b02e,$350,step_object_fast_code-_base
 dc.l $970e,$140,step_collision_geometry_code-_base
 dc.l $989e,$44,step_collision_geometry_code+$140-_base
 dc.l $d2c0,$610,aux_8d2c0-_base
 dc.l $dd66,$106,aux_8dd66-_base
 dc.l $e166,$170,aux_8e166-_base
 dc.l $da5c,$ae,aux_8da5c-_base
 dc.l $d970,$72,aux_lane_scan_body-_base
 dc.l -1

; Preserve the seventh lane coordinate: native reads the high word of the
; adjacent dispatch pointer, whose original value is $0008.
public_main_lane_lookup:
 lea $8d128,a6
 cmpi.w #12,d0
 bne .normal
 move.w #8,d0
 rts
.normal:
 move.w (a6,d0.w),d0
 rts

; Audited HUNK operand offsets: paired menu copy/depack destinations and SET
; descriptor relocation inputs. No race actor operands belong in this list.
public_main_menu_dma:
 dc.w $172e,$1742,$3ba6,$3bb2,$3fa2,$3fba,$4174,$418c
 dc.w $54c2,$54ce,$5768,$5774,$57b0,$57bc
 ; Descriptor readers point two bytes past the same count word.
 dc.w $1fb4,$3bc0,$3fc8,$419a,$54dc,$5790,$57ca,-1
