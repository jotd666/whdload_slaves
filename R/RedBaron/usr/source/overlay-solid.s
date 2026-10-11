; E2 solid front-cockpit candidate (program 2), 020+ and sim v1 only.
; Developer/VERIFY bit 18; normal verified mask does not select it.
; PERF_RANGE sim:15f1e 12 bit=18
OS_PIXELS = 28800
OS_FAST = OC_ENTRY+512

overlay_solid_install:
 movem.l d0-a6,-(sp)
 lea .attn(pc),a0
.attn
 adda.l #perf_attnflags+3-.attn,a0
 btst #1,(a0)
 beq .done
 move.l a1,a3
 move.l #$15f1e,d0
 moveq #12,d1
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
 addi.l #$15f2a,d0
 lea overlay_solid_tail+2(pc),a0
 move.l d0,(a0)
 bsr ovlife_install
 move.l a3,a1
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 jsr resload_FlushCache(a2)
.done
 movem.l (sp)+,d0-a6
 rts
.patch
 PL_START
 PL_P $15f1e,overlay_solid_front
 PL_NOP $15f24,6
 PL_END
overlay_solid_bytes: dc.w $554f,$7002,$3f00,$4eba,$09a2,$584f

overlay_solid_front:
 movem.l d0-a6,-(sp)
 bsr overlay_solid_allocate
 moveq #2,d7
 move.l overlay_solid_entry(pc),d0
 beq .native
 move.l d0,a5
 move.l overlay_cache_h3(pc),a4
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
 bsr overlay_solid_key
 tst.l d0
 beq .native
 lea OC_ENTRY(a5),a0
 move.l overlay_solid_mask(pc),a1
 lea overlay_cache_native(pc),a2 ; its JSR/RTS wrapper is not the interpreter
 move.l 2(a2),a2 ; relocated native entry
 bsr overlay_native_mask
 tst.l d0
 beq .native
 bsr overlay_cache_original_program
 bsr overlay_blit_wait
 move.l $1d72(a4),a0
 move.l overlay_solid_mask(pc),a1
 move.l OC_PIXELS(a5),a2
 lea OC_DESC(a5),a3
 bsr overlay_pack_large
 tst.l d0
 beq .done
 bsr overlay_cache_save_state
 move.w #1,(a5)
 IFD VERIFY
 lea overlay_cache_stats(pc),a0
 addq.l #1,4(a0)
 ENDC
 bra .done
.hit
 IFD VERIFY
 bsr overlay_cache_twin_before
 ENDC
 move.l OC_PIXELS(a5),a0
 move.l a0,a1
 moveq #0,d0
 move.w OC_DESC+8(a5),d0
 mulu.w #5,d0
 adda.l d0,a1
 move.l $1d72(a4),a2
 moveq #0,d0
 move.w OC_DESC+2(a5),d0
 mulu.w #40,d0
 add.w OC_DESC(a5),d0
 adda.l d0,a2
 move.w OC_DESC+4(a5),d0
 lsr.w #1,d0
 move.w OC_DESC+6(a5),d1
 bsr overlay_fast
 bsr overlay_cache_restore_state
 IFD VERIFY
 bsr overlay_cache_twin_after
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
.done
 movem.l (sp)+,d0-a6
overlay_solid_tail:
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
 bra overlay_key_append

overlay_solid_allocate:
 lea overlay_solid_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 move.l #OS_FAST+OS_PIXELS,d0
 move.l #$10004,d1 ; cleared fast RAM, including pixels and private script
 jsr _LVOAllocMem(a6)
 move.l d0,a5
 tst.l d0
 beq .done
 move.l #8000,d0
 moveq #2,d1
 jsr _LVOAllocMem(a6)
 tst.l d0
 beq .free_fast
 lea overlay_solid_mask(pc),a0
 move.l d0,(a0)
 move.l a5,d0
 addi.l #OS_FAST,d0
 move.l d0,OC_PIXELS(a5)
 lea overlay_solid_entry(pc),a0
 move.l a5,(a0)
 bra .done
.free_fast
 move.l a5,a1
 move.l #OS_FAST+OS_PIXELS,d0
 jsr _LVOFreeMem(a6)
.done
 rts

overlay_solid_entry: dc.l 0
overlay_solid_mask: dc.l 0
overlay_solid_attempted: dc.w 0
