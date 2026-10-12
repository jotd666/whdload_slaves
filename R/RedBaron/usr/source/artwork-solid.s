; Sparse static artwork candidate: sim v1, all CPU classes for measurement.
; Developer/VERIFY bit 19; not release-enabled until measured.
; PERF_RANGE sim:15f1e 12 bit=19
OS_PIXELS = 14338 ; count + at most 1024 occupied words, 14 bytes each
OS_FAST = OC_ENTRY+512

artwork_solid_install:
 movem.l d0-a6,-(sp)
 move.l a1,a3
 move.l #$15f1e,d0
 moveq #12,d1
 lea artwork_solid_bytes(pc),a0
 lea .check(pc),a6
.check
 adda.l #perf_check_bytes-.check,a6
 jsr (a6)
 move.l a3,a0
 adda.l #$301b2,a0
 move.l (a0),d0
 subi.l #$9a2c,d0
 lea artwork_cache_h3(pc),a0
 move.l d0,(a0)
 move.l a3,d0
 addi.l #$168c8,d0
 lea artwork_cache_native+2(pc),a0
 move.l d0,(a0)
 move.l a3,d0
 addi.l #$15f2a,d0
 lea artwork_solid_tail+2(pc),a0
 move.l d0,(a0)
 ; Shared lifetime installer is selected once by perf_apply_v1.
 move.l a3,a1
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 jsr resload_FlushCache(a2)
.done
 movem.l (sp)+,d0-a6
 rts
.patch
 PL_START
 PL_P $15f1e,artwork_solid_front
 PL_NOP $15f24,6
 PL_END
artwork_solid_bytes: dc.w $554f,$7002,$3f00,$4eba,$09a2,$584f

artwork_solid_front:
 movem.l d0-a6,-(sp)
 bsr artwork_solid_allocate
 moveq #2,d7
 move.l artwork_solid_entry(pc),d0
 beq .native
 move.l d0,a5
 move.l artwork_cache_h3(pc),a4
 adda.l #$8000,a4
 move.l a5,a0
 move.w d7,d0
 bsr overlay_key_matches
 tst.l d0
 bne .hit
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
 lea OC_ENTRY(a5),a1
 bsr overlay_mask_script_prepare
 tst.l d0
 beq .native
 move.l d0,d6
 bsr artwork_solid_key
 tst.l d0
 beq .native
 lea OC_ENTRY(a5),a0
 move.l artwork_solid_mask(pc),a1
 lea artwork_cache_native(pc),a2 ; its JSR/RTS wrapper is not the interpreter
 move.l 2(a2),a2 ; relocated native entry
 bsr overlay_native_mask
 tst.l d0
 beq .native
 bsr artwork_cache_original_program
 bsr artwork_wait
 move.l $1d72(a4),a0
 move.l artwork_solid_mask(pc),a1
 move.l OC_PIXELS(a5),a2
 bsr artwork_sparse_pack
 tst.l d0
 beq .done
 bsr artwork_cache_save_state
 move.w #1,(a5)
 IFD VERIFY
 lea artwork_cache_stats(pc),a0
 addq.l #1,4(a0)
 ENDC
 bra .done
.hit
 IFD VERIFY
 bsr artwork_cache_twin_before
 ENDC
 move.l OC_PIXELS(a5),a0
 move.l $1d72(a4),a1
 bsr artwork_sparse_update
 bsr artwork_cache_restore_state
 IFD VERIFY
 bsr artwork_cache_twin_after
 lea artwork_cache_stats(pc),a0
 addq.l #1,(a0)
 ENDC
 bra .done
.native
 IFD VERIFY
 lea artwork_cache_stats(pc),a0
 addq.l #1,8(a0)
 ENDC
 bsr artwork_cache_original_program
.done
 movem.l (sp)+,d0-a6
artwork_solid_tail:
 jmp $0.l

; Seven ordered input ranges, with no per-frame bitmap-content scan.
; d6=accepted script byte count. Key remains invalid until pixel fill succeeds.
artwork_solid_key:
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
 bra overlay_key_append

artwork_solid_allocate:
 lea artwork_solid_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 ; Use the already reserved renderer workspace; never compete with the
 ; game's runtime fast-memory pool. This feature owns its first OS_FAST+OS_PIXELS bytes.
 lea .workspace(pc),a0
.workspace
 adda.l #memory_workspace_reserved-.workspace,a0
 move.l (a0),d0
 beq .done
 move.l d0,a5
 move.l d0,a0
 move.w #(OS_FAST+OS_PIXELS)/2-1,d0
.clear
 clr.w (a0)+
 dbf d0,.clear
 move.l #8000,d0
 moveq #2,d1
 jsr _LVOAllocMem(a6)
 tst.l d0
 beq .done
 lea artwork_solid_mask(pc),a0
 move.l d0,(a0)
 move.l a5,d0
 addi.l #OS_FAST,d0
 move.l d0,OC_PIXELS(a5)
 lea artwork_solid_entry(pc),a0
 move.l a5,(a0)
 bra .done
.done
 rts

artwork_solid_entry: dc.l 0
artwork_solid_mask: dc.l 0
artwork_solid_attempted: dc.w 0

