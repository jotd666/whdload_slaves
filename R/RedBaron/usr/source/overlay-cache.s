; E2 developer candidate: front scripts 3/4, 020+ only, sim v1 only.
; The whole call sequence is replaced: volatile return registers are dead at
; sim:16226 (D0 is ultimately the saved D7 at sim:16398). Preserve live registers.
; Other views/scripts retain native drawing. Normal verified mask excludes bit 18.
; PERF_RANGE sim:15f8a 24 bit=18
OC_DESC = (OVERLAY_KEY_BYTES+3)&-4
OC_STATE = OC_DESC+12
OC_CHIP = OC_STATE+24
OC_ENTRY = OC_CHIP+4
OC_FAST = OC_ENTRY*2+8000

overlay_cache_install:
 movem.l d0-a6,-(sp)
 lea .attn_base(pc),a0
.attn_base
	adda.l #perf_attnflags+3-.attn_base,a0
	btst #1,(a0)
 beq .done
 move.l a1,a3
 move.l #$15f8a,d0
 moveq #24,d1
 lea overlay_cache_original(pc),a0
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
 lea overlay_cache_tail+2(pc),a0
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
 PL_P $15f8a,overlay_cache_front
 PL_NOP $15f90,18
 PL_END
overlay_cache_original:
 dc.w $554f,$7003,$3f00,$4eba,$0936,$7004,$3e80,$4eba,$092e,$584f,$6000,$0286

overlay_cache_front:
 movem.l d0-a6,-(sp)
 bsr overlay_cache_allocate
 move.l overlay_cache_fast(pc),d0
 beq .native
 move.l d0,a5
 move.l overlay_cache_h3(pc),a4
 adda.l #$8000,a4
 moveq #3,d7
 bsr overlay_cache_program
 adda.l #OC_ENTRY,a5
 moveq #4,d7
 bsr overlay_cache_program
 bra .done
.native
 moveq #3,d7
 bsr overlay_cache_original_program
 moveq #4,d7
 bsr overlay_cache_original_program
.done
 movem.l (sp)+,d0-a6
overlay_cache_tail:
 jmp $0.l

; One attempt per slave lifetime. Allocation failure retains native drawing.
overlay_cache_allocate:
 lea overlay_cache_attempted(pc),a0
 tst.w (a0)
 bne .done
 lea overlay_cache_attempted(pc),a0
 move.w #1,(a0)
 move.l 4.w,a6
 move.l #OC_FAST,d0
 move.l #$10000,d1 ; MEMF_CLEAR | MEMF_ANY
 jsr _LVOAllocMem(a6)
 move.l d0,a5
 tst.l d0
 beq .done
 move.l #10416,d0
 moveq #2,d1 ; two bounded packed entries in chip RAM
 jsr _LVOAllocMem(a6)
 tst.l d0
 beq .free_fast
 move.l d0,OC_CHIP(a5)
 addi.l #5208,d0
 move.l d0,OC_ENTRY+OC_CHIP(a5)
 lea overlay_cache_fast(pc),a0
 move.l a5,(a0)
 bra .done
.free_fast
 move.l a5,a1
 move.l #OC_FAST,d0
 jsr _LVOFreeMem(a6)
.done
 rts

; No resource pointer can be read after its owner has been invalidated.
; Called inside the shared CCR/register-preserving lifetime hook.
overlay_cache_invalidate:
 move.l a0,-(sp)
 move.l overlay_cache_fast(pc),a0
 cmpa.l #0,a0
 beq .done
 clr.w (a0)
 clr.w OC_ENTRY(a0)
.done
 move.l (sp)+,a0
 rts

; a5=entry, a4=h3+$8000, d7=program. Native interpreter scratch is contained.
overlay_cache_program:
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
 move.l overlay_cache_fast(pc),a2
 adda.l #OC_ENTRY*2,a2
 bsr overlay_mask_build
 tst.l d0
 beq .invalidate
 bsr overlay_cache_original_program
 bsr overlay_blit_wait
 move.l $1d72(a4),a0
 move.l overlay_cache_fast(pc),a1
 adda.l #OC_ENTRY*2,a1
 move.l OC_CHIP(a5),a2
 lea OC_DESC(a5),a3
 bsr overlay_pack
 tst.l d0
 beq .uncacheable_drawn
 bsr overlay_cache_save_state
 IFD VERIFY
 lea overlay_cache_stats(pc),a0
 addq.l #1,4(a0)
 ENDC
 rts
.invalidate
 clr.w (a5)
.native
 IFD VERIFY
 lea overlay_cache_stats(pc),a0
 addq.l #1,8(a0)
 ENDC
 bra overlay_cache_original_program
.uncacheable_drawn
 clr.w (a5)
 rts
.hit
 IFD VERIFY
 bsr overlay_cache_twin_before
 ENDC
 move.l OC_CHIP(a5),a0
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
 bsr overlay_blit
 bsr overlay_cache_restore_state
 IFD VERIFY
 bsr overlay_cache_twin_after
 lea overlay_cache_stats(pc),a0
 addq.l #1,(a0)
 ENDC
 rts

overlay_cache_original_program:
 movem.l d0-a6,-(sp)
 subq.l #2,sp
 move.w d7,-(sp)
overlay_cache_native:
 jsr $0.l
 addq.l #4,sp
 movem.l (sp)+,d0-a6
 rts

; Capture output values, replay only fields written by this program's commands.
overlay_cache_save_state:
 lea OC_STATE(a5),a0
overlay_cache_read_state:
 move.w -$3e9c(a4),(a0)+ ; h3:4164 pen
 move.l $1d50(a4),(a0)+ ; background, foreground
 move.w -$3de(a4),(a0)+ ; h3:7c22 image set
 move.l -$3dc(a4),(a0)+ ; table
 move.l -$3d4(a4),(a0)+ ; alternate table
 move.l -$3d8(a4),(a0)+ ; image descriptor
 move.w -$3e4(a4),(a0)+ ; bitmap mode
 move.w $1d54(a4),(a0)+ ; filled rectangle mode
 rts

overlay_cache_restore_state:
 lea OC_STATE(a5),a0
 move.w OVERLAY_KEY_EFFECTS(a5),d0
 btst #0,d0
 beq .set
 move.w (a0),-$3e9c(a4)
 move.l 2(a0),$1d50(a4)
.set
 btst #1,d0
 beq .image
 move.w 6(a0),-$3de(a4)
 move.l 8(a0),-$3dc(a4)
 move.l 12(a0),-$3d4(a4)
.image
 btst #2,d0
 beq .bitmap
 move.l 16(a0),-$3d8(a4)
.bitmap
 btst #3,d0
 beq .rectangle
 move.w 20(a0),-$3e4(a4)
.rectangle
 btst #4,d0
 beq .done
 move.w 22(a0),$1d54(a4)
.done
 rts

overlay_cache_fast: dc.l 0
overlay_cache_h3: dc.l 0
overlay_cache_attempted: dc.w 0
 IFD VERIFY
overlay_cache_stats: dc.l 0,0,0 ; hits, fills, fallbacks
 ENDC

 IFD VERIFY
; One pixel/post-state twin per cached front script. Native output is retained.
; Only private snapshots are allocated; no redirected DMA or hidden game state.
overlay_cache_twin_before:
 movem.l d0-a6,-(sp)
 lea overlay_cache_twin_result(pc),a6
 clr.l 4(a6)
 move.w d7,d0
 subq.w #3,d0
 move.l (a6),d1
 btst d0,d1
 bne .done
 move.l 8(a6),d0
 bne .allocated
 move.l a6,-(sp)
 move.l 4.w,a6
 move.l #80000,d0
 moveq #0,d1
 jsr _LVOAllocMem(a6)
 move.l (sp)+,a6
 move.l d0,8(a6)
 beq overlay_blit_bad
.allocated
 bsr overlay_blit_wait
 move.l d0,a1
 move.l $1d72(a4),a0
 move.w #9999,d0
.copy
 move.l (a0)+,(a1)+
 dbf d0,.copy
 move.l #1,4(a6)
.done
 movem.l (sp)+,d0-a6
 rts

overlay_cache_twin_after:
 movem.l d0-a6,-(sp)
 lea overlay_cache_twin_result(pc),a6
 tst.l 4(a6)
 beq .done
 suba.w #48,sp
 move.l sp,a0
 bsr overlay_cache_read_state
 move.l 8(a6),a0
 move.l a0,a1
 adda.l #40000,a1
 move.l $1d72(a4),a2
 move.w #9999,d0
.swap
 move.l (a2),(a1)+
 move.l (a0)+,(a2)+
 dbf d0,.swap
 bsr overlay_cache_original_program
 bsr overlay_blit_wait
 move.l 8(a6),a0
 adda.l #40000,a0
 move.l $1d72(a4),a1
 move.w #39999,d0
.compare
 cmpm.b (a0)+,(a1)+
 bne overlay_blit_bad
 dbf d0,.compare
 lea 24(sp),a0
 bsr overlay_cache_read_state
 move.l sp,a0
 lea 24(sp),a1
 moveq #5,d0
.state
 cmpm.l (a0)+,(a1)+
 bne overlay_blit_bad
 dbf d0,.state
 adda.w #48,sp
 move.w d7,d0
 subq.w #3,d0
 move.l (a6),d1
 bset d0,d1
 move.l d1,(a6)
 addq.l #1,12(a6)
 cmpi.l #3,d1
 bne .done
 move.l a6,-(sp)
 move.l 8(a6),a1
 clr.l 8(a6)
 move.l 4.w,a6
 move.l #80000,d0
 jsr _LVOFreeMem(a6)
 move.l (sp)+,a6
.done
 movem.l (sp)+,d0-a6
 rts
overlay_cache_twin_result: dc.l 0,0,0,0 ; checked bits, active, scratch, passes
 ENDC
