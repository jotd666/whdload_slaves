; Static gun artwork on the non-firing forward path; native draw order retained.
artwork_front_install:
 movem.l d0-a6,-(sp)
 move.l a1,a3
 move.l #$15f8a,d0
 moveq #24,d1
 lea artwork_front_original(pc),a0
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
 addi.l #$16226,d0
 lea artwork_front_tail+2(pc),a0
 move.l d0,(a0)
 ; Lifetime hooks belong to the common artwork installer.
 move.l a3,a1
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 jsr resload_FlushCache(a2)
.done
 movem.l (sp)+,d0-a6
 rts
.patch
 PL_START
 PL_P $15f8a,artwork_front_front
 PL_NOP $15f90,18
 PL_END
artwork_front_original:
 dc.w $554f,$7003,$3f00,$4eba,$0936,$7004,$3e80,$4eba,$092e,$584f,$6000,$0286

artwork_front_front:
 movem.l d0-a6,-(sp)
 bsr artwork_front_allocate
 move.l artwork_front_fast(pc),d0
 beq .native
 move.l d0,a5
 move.l artwork_cache_h3(pc),a4
 adda.l #$8000,a4
 moveq #3,d7
 bsr artwork_front_program
 adda.l #OC_ENTRY,a5
 moveq #4,d7
 bsr artwork_front_program
 bra .done
.native
 moveq #3,d7
 bsr artwork_cache_original_program
 moveq #4,d7
 bsr artwork_cache_original_program
.done
 movem.l (sp)+,d0-a6
artwork_front_tail:
 jmp $0.l

; One attempt per slave lifetime. Allocation failure retains native drawing.
artwork_front_allocate:
 lea artwork_front_attempted(pc),a0
 tst.w (a0)
 bne .done
 lea artwork_front_attempted(pc),a0
 move.w #1,(a0)
 move.l 4.w,a6
 lea .workspace(pc),a0
.workspace
 adda.l #memory_workspace_reserved-.workspace,a0
 move.l (a0),d0
 beq .done
 addi.l #$10000,d0
 move.l d0,a5
 move.l d0,a0
 move.w #(OC_ENTRY*2+8000+14338*2)/2-1,d0
.clear
 clr.w (a0)+
 dbf d0,.clear
 move.l a5,d0
 addi.l #OC_ENTRY*2+8000,d0
 move.l d0,OC_PIXELS(a5)
 addi.l #14338,d0
 move.l d0,OC_ENTRY+OC_PIXELS(a5)
 lea artwork_front_fast(pc),a0
 move.l a5,(a0)
.done
 rts

; No resource pointer can be read after its owner has been invalidated.
; Called inside the shared CCR/register-preserving lifetime hook.
artwork_front_invalidate:
 move.l a0,-(sp)
 move.l artwork_front_fast(pc),a0
 cmpa.l #0,a0
 beq .done
 clr.w (a0)
 clr.w OC_ENTRY(a0)
.done
 move.l (sp)+,a0
 rts

; a5=entry, a4=h3+$8000, d7=program. Native interpreter scratch is contained.
artwork_front_program:
 move.l a5,a0
 move.w d7,d0
 bsr overlay_key_matches
 tst.l d0
 bne .hit
 move.l a5,a0
 lea -$8000(a4),a1
 move.w d7,d0
 bsr overlay_cache_key_build
 tst.l d0
 beq .native
 move.w d7,d0
 lsl.w #2,d0
 lea -$4ae(a4),a0
 move.l 0(a0,d0.w),a0
 lea -$8000(a4),a1
 move.l artwork_front_fast(pc),a2
 adda.l #OC_ENTRY*2,a2
 bsr overlay_mask_build
 tst.l d0
 beq .invalidate
 bsr artwork_cache_original_program
 bsr artwork_wait
 move.l $1d72(a4),a0
 move.l artwork_front_fast(pc),a1
 adda.l #OC_ENTRY*2,a1
 move.l OC_PIXELS(a5),a2
 bsr artwork_sparse_pack
 tst.l d0
 beq .uncacheable_drawn
 bsr artwork_cache_save_state
 rts
.invalidate
 clr.w (a5)
.native
 bra artwork_cache_original_program
.uncacheable_drawn
 clr.w (a5)
 rts
.hit
 move.l OC_PIXELS(a5),a0
 move.l $1d72(a4),a1
 bsr cockpit_fast_update
 bsr artwork_cache_restore_state
 rts

artwork_front_fast: dc.l 0
artwork_front_attempted: dc.w 0
