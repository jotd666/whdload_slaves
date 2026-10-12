; Foreground layer provider for the complete cockpit compositor, bit 19/020+.
; Reuses the audited 2/3/4 scripts and their exact input/state keys. The former
; standalone cache was dropped for <2% gains: this provider feeds the full
; ordered composition and has no independent performance acceptance.
; Unsupported front states keep native dispatch and expose no layer.
; PERF_RANGE sim:15f12 6 bit=19
OS_PIXELS = 48000
OS_SCRIPT = OC_ENTRY*3
OS_TEMP_MASK = OS_SCRIPT+512
OS_FAST = OS_TEMP_MASK+8000

overlay_solid_install:
 movem.l d0-a6,-(sp)
 lea .attn(pc),a0
.attn
 adda.l #perf_attnflags+3-.attn,a0
 btst #1,(a0)
 beq .done
 move.l a1,a3
 move.l a3,a0
 adda.l #$301b2,a0
 move.l (a0),d0
 subi.l #$9a2c,d0
 addi.l #$195c,d0
 lea overlay_solid_bytes+2(pc),a0
 move.l d0,(a0)
 lea overlay_solid_original_load+2(pc),a0
 move.l d0,(a0)
 move.l a3,d0
 addi.l #$15f18,d0
 lea overlay_solid_original_tail+2(pc),a0
 move.l d0,(a0)
 move.l #$15f12,d0
 moveq #6,d1
 lea overlay_solid_bytes(pc),a0
 lea .check(pc),a6
.check
 adda.l #perf_check_bytes-.check,a6
 jsr (a6)
 move.l a3,a0
 adda.l #$301b2,a0
 move.l (a0),d0
 subi.l #$9a2c,d0
 lea overlay_cache_h3(pc),a0
 move.l d0,(a0)
 move.l a3,d0
 addi.l #$168c8,d0
 lea overlay_cache_native+2(pc),a0
 move.l d0,(a0)
 move.l a3,d0
 addi.l #$16226,d0
 lea overlay_solid_tail+2(pc),a0
 move.l d0,(a0)
 bsr overlay_cache_invalidate
 move.l a3,a1
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 jsr resload_FlushCache(a2)
.done
 movem.l (sp)+,d0-a6
 rts
.patch
 PL_START
 PL_P $15f12,overlay_solid_front
 PL_END
overlay_solid_bytes: dc.w $2079
 dc.l 0

overlay_solid_front:
 movem.l d0-a6,-(sp)
 lea cockpit_foreground_layer(pc),a0
 clr.l (a0)+
 clr.l (a0)
 move.l cockpit_stage_active(pc),d0
 beq overlay_solid_original_dispatch
 move.l overlay_cache_h3(pc),a4
 adda.l #$8000,a4
 move.l -$66a4(a4),a0 ; h3:195c native cockpit-height selector
 cmpi.w #40,(a0)
 ble overlay_solid_original_dispatch
 tst.w -10(a5) ; native damage-enabled local
 beq .damage_ready
 tst.b -$1b0a(a4) ; h3:64f6 / 64f7 damage scripts 28/29
 bne overlay_solid_original_dispatch
 tst.b -$1b09(a4)
 bne overlay_solid_original_dispatch
.damage_ready
 tst.w -$27d0(a4) ; h3:5830 gun animation; native sim:1216a
 bne overlay_solid_original_dispatch
 bsr overlay_solid_allocate
 moveq #2,d7
 move.l overlay_solid_entry(pc),d0
 beq .native
 move.l d0,a5
 move.l overlay_cache_h3(pc),a4
 adda.l #$8000,a4
 move.l a5,a0
 move.w d7,d0
 bsr cf_overlay_key_matches
 tst.l d0
 beq .miss
 lea OC_ENTRY(a5),a0
 moveq #3,d0
 bsr cf_overlay_key_matches
 tst.l d0
 beq .miss
 lea OC_ENTRY*2(a5),a0
 moveq #4,d0
 bsr cf_overlay_key_matches
 tst.l d0
 bne .hit
.miss
 clr.w (a5)
 ; Native mask rendering requires the original screen and a bounded clip.
 cmpi.l #8000,$1d34(a4)
 bne .native
 cmpi.w #5,$1d3c(a4)
 bne .native
 cmpi.w #320,$1d40(a4)
 bne .native
 cmpi.w #40,$1d42(a4)
 bne .native
 cmpi.w #200,$1d44(a4)
 bne .native
 tst.w $1d46(a4)
 beq .native
 move.w $1d48(a4),d0
 bmi .native
 cmp.w $1d4a(a4),d0
 bgt .native
 cmpi.w #320,$1d4a(a4)
 bhs .native
 move.w $1d4c(a4),d0
 bmi .native
 cmp.w $1d4e(a4),d0
 bgt .native
 cmpi.w #200,$1d4e(a4)
 bhs .native
 tst.b -$4b0(a4)
 bne .native
 move.l -$4a6(a4),a0 ; program 2 pointer at h3:7b5a
 lea OS_SCRIPT(a5),a1
 bsr cf_overlay_mask_script_prepare
 tst.l d0
 beq .native
 move.l d0,d6
 bsr overlay_solid_key
 tst.l d0
 beq .native
 lea OC_ENTRY(a5),a0
 lea -$8000(a4),a1
 moveq #3,d0
 bsr cf_overlay_cache_key_build
 tst.l d0
 beq .native
 lea OC_ENTRY*2(a5),a0
 moveq #4,d0
 bsr cf_overlay_cache_key_build
 tst.l d0
 beq .native
 lea OS_SCRIPT(a5),a0
 move.l overlay_solid_mask(pc),a1
 lea overlay_cache_native(pc),a2 ; its JSR/RTS wrapper is not the interpreter
 move.l 2(a2),a2 ; relocated native entry
 bsr cf_overlay_native_mask
 tst.l d0
 beq .native
 ; Extend exact native solid coverage with audited gun-script coverage.
 moveq #3,d6
.mask_loop
 move.w d6,d0
 lsl.w #2,d0
 lea -$4ae(a4),a0
 move.l 0(a0,d0.w),a0
 lea -$8000(a4),a1
 lea OS_TEMP_MASK(a5),a2
 bsr cf_overlay_mask_build
 tst.l d0
 beq .native
 move.l overlay_solid_mask(pc),a0
 lea OS_TEMP_MASK(a5),a1
 move.w #1999,d0
.union
 move.l (a1)+,d1
 or.l d1,(a0)+
 dbf d0,.union
 addq.w #1,d6
 cmpi.w #5,d6
 blo .mask_loop
 bsr overlay_cache_original_program
 bsr cockpit_stage_wait
 bsr cockpit_foreground_capture
 bsr overlay_cache_save_state
 move.w OC_ENTRY+OVERLAY_KEY_EFFECTS(a5),d0
 or.w OC_ENTRY*2+OVERLAY_KEY_EFFECTS(a5),d0
 or.w d0,OVERLAY_KEY_EFFECTS(a5)
 move.w #1,(a5)
 IFD VERIFY
 lea overlay_cache_stats(pc),a0
 addq.l #1,4(a0)
 ENDC
 bra .done
.hit
 move.l OC_PIXELS(a5),a0
 move.l a0,a1
 adda.l #40000,a1
 move.l $1d72(a4),a2
 moveq #20,d0
 move.w #200,d1
 bsr cf_overlay_fast
 bsr overlay_cache_restore_state
 IFD VERIFY
 lea overlay_cache_stats(pc),a0
 addq.l #1,(a0)
 ENDC
 bra .done
.native
 IFD VERIFY
 lea overlay_cache_stats(pc),a0
 addq.l #1,8(a0)
 ENDC
 bsr overlay_cache_original_program
 movem.l (sp)+,d0-a6
 bra overlay_solid_tail
.done
 ; Expose only this invocation's accepted front layer. Fallbacks must not
 ; publish an old record left valid by a previous compatible frame.
 tst.w (a5)
 beq .no_layer
 lea cockpit_foreground_layer(pc),a0
 move.l OC_PIXELS(a5),d0
 move.l d0,(a0)
 addi.l #40000,d0
 move.l d0,4(a0)
.no_layer
 movem.l (sp)+,d0-a6
overlay_solid_tail:
 jmp $0.l
overlay_solid_original_dispatch:
 movem.l (sp)+,d0-a6
overlay_solid_original_load:
 move.l $0.l,a0
overlay_solid_original_tail:
 jmp $0.l

; Seven ordered input ranges, with no per-frame bitmap-content scan.
; d6=accepted script byte count. Key remains invalid until pixel fill succeeds.
overlay_solid_key:
 clr.l (a5)
 clr.l 4(a5)
 move.w #2,2(a5)
 move.w #17,OVERLAY_KEY_EFFECTS(a5) ; colours and filled mode only
 lea -$4a6(a4),a1
 moveq #4,d0
 bsr .append
 tst.l d0
 beq .done
 move.l (a1),a1
 move.l d6,d0
 bsr .append
 tst.l d0
 beq .done
 lea $1d34(a4),a1
 moveq #28,d0
 bsr .append
 tst.l d0
 beq .done
 lea -$4b0(a4),a1
 moveq #1,d0
 bsr .append
 tst.l d0
 beq .done
 lea -$4549(a4),a1
 moveq #10,d0
 bsr .append
 tst.l d0
 beq .done
 moveq #1,d5
.palette
 lea -$4541(a4),a1
 move.b 0(a1,d5.w),d0
 ext.w d0
 lsl.w #2,d0
 lea -$6fe3(a4),a1
 adda.w d0,a1
 moveq #4,d0
 bsr .append
 tst.l d0
 beq .done
 dbf d5,.palette
.done
 rts
.append
 move.l a5,a0
 bra cf_overlay_key_append

overlay_solid_allocate:
 lea overlay_solid_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 ; Reserve the mandatory fast pixel payload before flexible metadata.
 ; Otherwise MEMF_ANY metadata may consume the last usable fast block.
 move.l #OS_PIXELS,d0
 moveq #4,d1
 jsr _LVOAllocMem(a6)
 move.l d0,a5
 tst.l d0
 beq .done
 move.l #OS_FAST,d0
 move.l #$10000,d1
 jsr _LVOAllocMem(a6)
 tst.l d0
 beq .free_unattached_pixels
 move.l d0,a0
 move.l a5,OC_PIXELS(a0)
 move.l a0,a5
 move.l #8000,d0
 moveq #2,d1
 jsr _LVOAllocMem(a6)
 tst.l d0
 beq .free_pixels
 lea overlay_solid_mask(pc),a0
 move.l d0,(a0)
 lea overlay_solid_entry(pc),a0
 move.l a5,(a0)
 bra .done
.free_pixels
 move.l OC_PIXELS(a5),a1
 move.l #OS_PIXELS,d0
 jsr _LVOFreeMem(a6)
.free_meta
 move.l a5,a1
 move.l #OS_FAST,d0
 jsr _LVOFreeMem(a6)
 bra .done
.free_unattached_pixels
 move.l a5,a1
 move.l #OS_PIXELS,d0
 jsr _LVOFreeMem(a6)
.done
 rts

overlay_solid_entry: dc.l 0
overlay_solid_mask: dc.l 0
overlay_solid_attempted: dc.w 0

cockpit_foreground_capture:
 movem.l d0-d3/a0-a3,-(sp)
 lea cockpit_final_valid(pc),a0
 clr.w (a0) ; rebuilt foreground can change coverage anywhere
 move.l $1d72(a4),a0
 move.l OC_PIXELS(a5),a1
 move.l overlay_solid_mask(pc),a2
 move.l a1,a3
 adda.l #40000,a3
 move.w #1999,d0
.mask
 move.l (a2)+,(a3)+
 dbf d0,.mask
 moveq #4,d3
.plane
 move.l overlay_solid_mask(pc),a2
 move.w #1999,d0
.pixels
 move.l (a0)+,d1
 and.l (a2)+,d1
 move.l d1,(a1)+
 dbf d0,.pixels
 dbf d3,.plane
 movem.l (sp)+,d0-d3/a0-a3
 rts
cockpit_foreground_layer: dc.l 0,0

cf_overlay_key_matches:
 move.l a6,-(sp)
 lea .target(pc),a6
.target
 adda.l #overlay_key_matches-.target,a6
 jsr (a6)
 move.l (sp)+,a6
 rts

cf_overlay_mask_script_prepare:
 move.l a6,-(sp)
 lea .target(pc),a6
.target
 adda.l #overlay_mask_script_prepare-.target,a6
 jsr (a6)
 move.l (sp)+,a6
 rts

cf_overlay_native_mask:
 move.l a6,-(sp)
 lea .target(pc),a6
.target
 adda.l #overlay_native_mask-.target,a6
 jsr (a6)
 move.l (sp)+,a6
 rts

cf_overlay_mask_build:
 move.l a6,-(sp)
 lea .target(pc),a6
.target
 adda.l #overlay_mask_build-.target,a6
 jsr (a6)
 move.l (sp)+,a6
 rts

cf_overlay_fast:
 move.l a6,-(sp)
 lea .target(pc),a6
.target
 adda.l #overlay_fast-.target,a6
 jsr (a6)
 move.l (sp)+,a6
 rts

cf_overlay_key_append:
 move.l a6,-(sp)
 lea .target(pc),a6
.target
 adda.l #overlay_key_append-.target,a6
 jsr (a6)
 move.l (sp)+,a6
 rts

cf_overlay_cache_key_build:
 move.l a6,-(sp)
 lea .target(pc),a6
.target
 adda.l #overlay_cache_key_build-.target,a6
 jsr (a6)
 move.l (sp)+,a6
 rts
