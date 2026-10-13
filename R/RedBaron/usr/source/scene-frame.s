; Private Fast-RAM scene viewport: sim v1 and 030+, developer bit 20.
; PERF_RANGE sim:2e4c8 6 bit=20
; PERF_RANGE sim:2e552 6 bit=20
; PERF_RANGE sim:2e810 6 bit=20
; PERF_RANGE sim:2e8a2 6 bit=20
; PERF_RANGE sim:2e93a 6 bit=20
; PERF_RANGE sim:2e9d4 6 bit=20
; PERF_RANGE sim:2ec12 6 bit=20
; PERF_RANGE sim:2ecf4 6 bit=20
; PERF_RANGE sim:2edaa 6 bit=20
; PERF_RANGE sim:2f646 6 bit=20
; PERF_RANGE sim:2feba 6 bit=20
; PERF_RANGE sim:2ff46 6 bit=20
; PERF_RANGE sim:30576 6 bit=20
; PERF_RANGE sim:2e514 8 bit=20
; PERF_RANGE sim:2e586 12 bit=20
; PERF_RANGE sim:2e858 8 bit=20
; PERF_RANGE sim:2e98a 8 bit=20
; PERF_RANGE sim:2ec86 8 bit=20
; PERF_RANGE sim:2ed44 8 bit=20
; PERF_RANGE sim:2edf2 8 bit=20
; PERF_RANGE sim:2f416 8 bit=20
; PERF_RANGE sim:2f476 12 bit=20
; PERF_RANGE sim:2f502 8 bit=20
; PERF_RANGE sim:2f66e 8 bit=20
; PERF_RANGE sim:2f99a 12 bit=20
; PERF_RANGE sim:2fb8c 8 bit=20
; PERF_RANGE sim:2fc22 8 bit=20
; PERF_RANGE sim:2fc46 8 bit=20
; PERF_RANGE sim:2fd8a 8 bit=20
; PERF_RANGE sim:2ff0c 8 bit=20
; PERF_RANGE sim:2ff6a 10 bit=20
; PERF_RANGE sim:3064c 12 bit=20
; PERF_RANGE sim:306a0 8 bit=20
; PERF_RANGE sim:307b2 8 bit=20
; PERF_RANGE sim:2c552 8 bit=20
; PERF_RANGE sim:2c800 8 bit=20
; Native clipping/geometry stays intact. Direct primitives bypass per-plane
; blitter descriptions; uncommon operations use the compatibility kernel.
scene_frame_install:
 movem.l d0-a6,-(sp)
 move.l a1,a5
 move.l a1,a0
 adda.l #$301b2,a0
 move.l (a0),d0
 subi.l #$9a2c,d0
 lea scene_frame_h3(pc),a0
 move.l d0,(a0)
 lea .workspace_base(pc),a0
.workspace_base
 adda.l #memory_workspace_reserved-.workspace_base,a0
 move.l (a0),d0
 addi.l #PERF_SCENE_OFFSET+15,d0
 andi.l #$fffffff0,d0
 lea scene_frame_storage(pc),a0
 move.l d0,(a0)
 lea .cpu_flags(pc),a0
.cpu_flags
 adda.l #perf_attnflags-.cpu_flags,a0
 move.l (a0),d0
 andi.l #$88,d0 ; ASF_68040 / ASF_68060 only
 lea scene_frame_move16(pc),a0
 move.w d0,(a0)
 lea scene_frame_resume+2(pc),a0
 move.l a5,d0
 addi.l #$2c55a,d0
 move.l d0,(a0)
 move.l #$2c552,d0
 moveq #8,d1
 lea .entry_bytes(pc),a0
 bsr .check_bytes
 move.l #$2c800,d0
 moveq #8,d1
 lea .exit_bytes(pc),a0
 bsr .check_bytes
 lea .frame_patches(pc),a0
 jsr resload_Patch(a2)
 ; Replace the custom-register LEAs without changing any flags.
 lea scene_frame_base_table(pc),a3
 moveq #SF_BASE_COUNT-1,d7
.bases
 move.l (a3)+,d0
 move.l a5,a0
 adda.l d0,a0
 move.w (a3)+,d0
 move.w (a3)+,d1
 cmp.w (a0),d1
 bne scene_frame_bad
 cmpi.l #$00dff000,2(a0)
 bne scene_frame_bad
 bsr .base_target
 move.w #$4eb9,(a0)
 move.l a4,2(a0)
 dbf d7,.bases
 ; D1 owns the rectangle setup site; redirect only its LEA, not its masks.
 lea .fill_setup_base(pc),a0
.fill_setup_base
 adda.l #fill_setup_custom-.fill_setup_base,a0
 ; This helper lives in the slave, so its redirect survives sim unloads.
 ; Accept only the original LEA or our exact existing JSR on later loads.
 lea scene_frame_base_a0(pc),a4
 cmpi.w #$41f9,(a0)
 beq .fill_original
 cmpi.w #$4eb9,(a0)
 bne scene_frame_bad
 cmp.l 2(a0),a4
 bne scene_frame_bad
 bra .fill_ready
.fill_original
 cmpi.l #$00dff000,2(a0)
 bne scene_frame_bad
 move.w #$4eb9,(a0)
 move.l a4,2(a0)
.fill_ready
 ; Clone each complete store prefix plus BLTSIZE, then call the backend.
 lea scene_frame_launch_table(pc),a3
 lea .tramp_base(pc),a6
.tramp_base
 adda.l #scene_frame_trampolines-.tramp_base,a6
 moveq #SF_LAUNCH_COUNT-1,d7
.launches
 move.l (a3)+,d0
 move.l a5,a0
 adda.l d0,a0
 move.w (a3)+,d6
 move.w (a3)+,d0
 cmp.w (a0),d0
 bne scene_frame_bad
 move.w (a3)+,d0
 move.l a0,a1
 adda.w d6,a1
 cmp.w -4(a1),d0
 bne scene_frame_bad
 cmpi.w #$0058,-2(a1)
 bne scene_frame_bad
 move.l a6,a1
 move.l a0,a4
 move.w d6,d0
 lsr.w #1,d0
 subq.w #1,d0
.clone
 move.w (a4)+,(a1)+
 dbf d0,.clone
 move.l a4,d5 ; continuation
 move.w (a3)+,d0
 bsr .launch_target
 move.w #$4eb9,(a1)+
 move.l a4,(a1)+
 move.w #$4ef9,(a1)+
 move.l d5,(a1)+
 move.w #$4ef9,(a0)
 move.l a6,2(a0)
 adda.w #32,a6
 dbf d7,.launches
 move.l a5,a1
 bsr scene_primitives_install
 jsr resload_FlushCache(a2)
 movem.l (sp)+,d0-a6
 rts
.check_bytes
 lea .check_base(pc),a4
.check_base
 adda.l #perf_check_bytes-.check_base,a4
 jmp (a4)

.base_target
 lea scene_frame_base_a0(pc),a4
 tst.w d0
 beq .bt_done
 lea scene_frame_base_a1(pc),a4
 cmpi.w #1,d0
 beq .bt_done
 lea scene_frame_base_a3(pc),a4
.bt_done
 rts
.launch_target
 lea scene_frame_clear_a0(pc),a4
 cmpi.w #4,d0
 beq .lt_done
 lea scene_frame_blit_a0(pc),a4
 tst.w d0
 beq .lt_done
 lea scene_frame_blit_a1(pc),a4
 cmpi.w #1,d0
 beq .lt_done
 lea scene_frame_blit_a3(pc),a4
.lt_done
 rts
.entry_bytes: dc.w $4e55,$fff4,$48e7,$2332
.exit_bytes: dc.w $4cdf,$4cc4,$4e5d,$4e75
.frame_patches
 PL_START
 PL_P $2c552,scene_frame_enter
 PL_P $2c800,scene_frame_exit
 PL_END

SF_BASE MACRO
scene_frame_base_a\1:
 dc.w $42e7 ; move.w ccr,-(sp), legal on the gated 020+ classes
 lea scene_frame_active(pc),a\1
 tst.w (a\1)
 lea $dff000,a\1
 beq .done\@
 lea scene_frame_custom(pc),a\1
.done\@
 ; Hardware fallbacks cannot write a page still waiting for publication.
 bsr fence_wait_native
 move.w (sp)+,ccr
 rts
 ENDM
 SF_BASE 0
 SF_BASE 1
 SF_BASE 3

SF_BLIT MACRO
scene_frame_blit_a\1:
 dc.w $42e7 ; preserve the original BLTSIZE MOVE's CCR, including X
 movem.l d0-a6,-(sp)
 move.l a\1,a4
 cmpa.l #$dff000,a4
 beq .done\@
 lea scene_frame_custom(pc),a0
 cmpa.l a0,a4
 bne scene_frame_bad
 ; Every destination in the redirected scene must be one of our two buffers.
 move.l $54(a4),d0
 sub.l scene_frame_buffer(pc),d0
 cmpi.l #48000,d0
 blo .bounds_ok\@
 bsr scene_frame_prefix_check
 tst.l d0
 beq scene_frame_bad
.bounds_ok\@
 move.l a4,-(sp)
 lea .kernel_base\@(pc),a0
.kernel_base\@
 adda.l #scene_compat_code-.kernel_base\@,a0
 jsr (a0)
 addq.l #4,sp
 tst.l d0
 bne scene_frame_bad
.done\@
 movem.l (sp)+,d0-a6
 move.w (sp)+,ccr
 rts
 ENDM
 SF_BLIT 0
 SF_BLIT 1
 SF_BLIT 3

; R2: the native clipped sprite at sim:307b2 may start one word before
; the first plane. Its shifted first-word A mask is zero, so the first
; destination word is preserved. Admit only that proven ascending cookie-cut
; operation, with a bounded 40-byte pitch, into our reserved prefix padding.
; Input: D0 = destination offset, A4 = private custom registers. D0 = boolean.
scene_frame_prefix_check:
 cmpi.l #-2,d0
 bne .bad
 move.w $40(a4),d1
 move.w d1,d2
 andi.w #$0fff,d2
 cmpi.w #$0fca,d2 ; A/B/C/D enabled, D = A ? B : C
 bne .bad
 move.w $42(a4),d2
 andi.w #$0fff,d2 ; ascending, no line/fill mode
 bne .bad
 lsr.w #8,d1
 lsr.w #4,d1
 move.w $44(a4),d2
 lsr.w d1,d2 ; no incoming A hold on the first word
 bne .bad
 move.l $48(a4),d1
 cmp.l $54(a4),d1
 bne .bad
 move.w $58(a4),d1
 move.w d1,d2
 andi.w #63,d1
 beq .bad ; encoded zero means 64 words
 cmpi.w #20,d1
 bhi .bad
 lsr.w #6,d2
 beq .bad ; encoded zero means 1024 rows
 cmpi.w #200,d2
 bhi .bad
 add.w d1,d1
 neg.w d1
 addi.w #40,d1
 cmp.w $60(a4),d1
 bne .bad
 cmp.w $66(a4),d1
 bne .bad
 moveq #1,d0
 rts
.bad
 moveq #0,d0
 rts

; The native scratch clear must finish before CPU endpoint corrections begin.
; Other native launches retain their asynchronous behavior; private scene
; clears continue through the compatibility kernel. Preserve BLTSIZE's CCR.
scene_frame_clear_a0:
 dc.w $42e7
 cmpa.l #$dff000,a0
 bne .private
 bsr scene_frame_wait
 move.w (sp)+,ccr
 rts
.private
 move.w (sp)+,ccr
 bra scene_frame_blit_a0

scene_frame_enter:
 movem.l d0-a6,-(sp)
 lea scene_frame_active(pc),a0
 tst.w (a0)
 bne scene_frame_bad
 bsr scene_frame_wait
 lea fence_scene_owned(pc),a0
 clr.w (a0)
 move.l 64(sp),a0 ; camera argument before the saved register frame
 btst #3,(a0) ; no background clear: keep native ownership
 bne .native
 tst.w 14(a0)
 bne .native
 cmpi.w #319,16(a0)
 bne .native
 move.w 18(a0),d0
 bmi .native
 move.w 20(a0),d1
 cmpi.w #200,d1
 bhs .native
 sub.w d0,d1
 bmi .native
 addq.w #1,d1
 lea scene_frame_view(pc),a1
 move.w d0,(a1)+
 move.w d1,(a1)
 move.l scene_frame_h3(pc),a6
 adda.l #$8000,a6
 cmpi.l #8000,$1d34(a6)
 bne .native
 cmpi.w #5,$1d3c(a6)
 bne .native
 cmpi.w #40,$1d42(a6)
 bne .native
 cmpi.w #200,$1d44(a6)
 bne .native
 lea scene_frame_original(pc),a3
 move.l $1d72(a6),(a3)
 move.l $1d76(a6),4(a3)
 move.l $1d6e(a6),8(a3)
 ; Match the native page alignment for outbound cache-line transfers.
 move.l (a3),d0
 andi.l #15,d0
 add.l scene_frame_storage(pc),d0
 addi.l #PERF_SCENE_PREFIX,d0
 lea scene_frame_buffer(pc),a0
 move.l d0,(a0)
 ; No inbound screen or scratch copy. The native background fully paints
 ; this guarded viewport; native polygons clear their own scratch bounds.
 move.l scene_frame_buffer(pc),d0
 move.l d0,$1d72(a6)
 move.l 8(a3),d1
 cmp.l (a3),d1
 bne .source_ready
 move.l d0,$1d6e(a6)
.source_ready
 addi.l #40000,d0
 move.l d0,$1d76(a6)
 lea scene_frame_active(pc),a0
 move.w #1,(a0)
 lea fence_scene_owned(pc),a0
 move.w #1,(a0)
 bra .ready
.native
 bsr fence_wait
.ready
 movem.l (sp)+,d0-a6
 link a5,#-12
 movem.l d2/d6-d7/a2-a3/a6,-(sp)
scene_frame_resume:
 jmp $0.l

scene_frame_exit:
 movem.l (sp)+,d2/d6-d7/a2-a3/a6
 unlk a5
 movem.l d0-a6,-(sp)
 move.w scene_frame_active(pc),d0
 beq .inactive
 bsr cockpit_fast_compose
 bsr fence_wait
 lea scene_frame_original(pc),a3
 move.l scene_frame_buffer(pc),a0
 move.l (a3),a1
 moveq #0,d0
 move.w scene_frame_view(pc),d0
 mulu #40,d0
 adda.l d0,a0
 adda.l d0,a1
 moveq #4,d6
.plane
 move.l a0,-(sp)
 move.l a1,-(sp)
 move.l d6,-(sp)
 moveq #0,d7
 move.w scene_frame_view+2(pc),d7
 mulu #10,d7
 move.l d7,d5
 andi.w #7,d5
 move.w d5,-(sp)
 lsr.l #3,d7
 subq.w #1,d7
 bsr scene_frame_copy32
 move.w (sp)+,d7
 beq .row_tail_done
 subq.w #1,d7
.row_tail
 move.l (a0)+,(a1)+
 dbf d7,.row_tail
.row_tail_done
 move.l (sp)+,d6
 move.l (sp)+,a1
 move.l (sp)+,a0
 adda.l #8000,a0
 adda.l #8000,a1
 dbf d6,.plane
 move.l scene_frame_h3(pc),a6
 adda.l #$8000,a6
 move.l (a3),$1d72(a6)
 move.l 4(a3),$1d76(a6)
 move.l 8(a3),$1d6e(a6)
 bsr scene_frame_restore_hardware
 lea scene_frame_active(pc),a0
 clr.w (a0)
.inactive
 movem.l (sp)+,d0-a6
 rts

 ; d7 = 32-byte blocks minus one. Preserve a3-a6 on both paths.
scene_frame_copy32:
 move.w scene_frame_move16(pc),d0
 beq .movem
 move.l a0,d0
 move.l a1,d1
 eor.l d0,d1
 andi.l #15,d1
 bne .movem
 andi.l #15,d0
 beq .aligned
 cmpi.w #8,d0
 bne .movem
 ; Matching half-line alignment: eight-byte head and tail surround full lines.
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 add.w d7,d7
.body8
 dc.w $f620,$9000 ; move16 (a0)+,(a1)+, 040/060 only
 dbf d7,.body8
 move.l (a0)+,(a1)+
 move.l (a0)+,(a1)+
 rts
.aligned
 add.w d7,d7
 addq.w #1,d7
.body16
 dc.w $f620,$9000
 dbf d7,.body16
 rts
.movem
 movem.l (a0)+,d0-d6/a2
 movem.l d0-d6/a2,(a1)
 lea 32(a1),a1
 dbf d7,.movem
 rts
scene_frame_wait:
 tst.w $dff002
.wait
 btst #6,$dff002
 bne .wait
 rts

; Map the private framebuffer/scratch address in d0 back to its native chip
; counterpart. Register values which are not buffer pointers remain unchanged.
scene_frame_native_pointer:
 move.l d0,d1
 sub.l scene_frame_buffer(pc),d1
 cmpi.l #48000,d1
 bhs .done
 cmpi.l #40000,d1
 bhs .scratch
 add.l scene_frame_original(pc),d1
 move.l d1,d0
 rts
.scratch
 subi.l #40000,d1
 add.l scene_frame_original+4(pc),d1
 move.l d1,d0
.done
 rts
scene_frame_restore_hardware:
 lea scene_frame_custom(pc),a0
 lea $dff000,a1
 move.l $40(a0),$40(a1)
 move.l $44(a0),$44(a1)
 moveq #$48,d2
.ptr
 move.l 0(a0,d2.w),d0
 ; In line mode BLTAPT is an error accumulator, even if its stale upper
 ; word resembles a Fast-RAM bitmap address. Only C/D are line pointers.
 cmpi.w #$50,d2
 bne .map_ptr
 btst #0,$43(a0)
 bne .write_ptr
.map_ptr
 bsr scene_frame_native_pointer
.write_ptr
 move.l d0,0(a1,d2.w)
 addq.w #4,d2
 cmpi.w #$58,d2
 bne .ptr
 move.l $60(a0),$60(a1)
 move.l $64(a0),$64(a1)
 move.l $70(a0),$70(a1)
 move.w $74(a0),$74(a1)
 rts

scene_frame_bad:
 pea .message(pc)
 pea TDREASON_FAILMSG
 lea .resload_base(pc),a2
.resload_base
 adda.l #_resload-.resload_base,a2
 move.l (a2),a2
 jmp resload_Abort(a2)
.message: dc.b "Red Baron: fast-frame renderer bounds or pixel mismatch",0
 even
scene_frame_h3: dc.l 0
scene_frame_storage: dc.l 0
scene_frame_buffer: dc.l 0
scene_frame_move16: dc.w 0
scene_frame_original: dc.l 0,0,0
scene_frame_view: dc.w 0,0
scene_frame_active: dc.w 0
scene_frame_custom: dcb.w 128,0
 include "scene-hooks.i"

scene_frame_trampolines: dcb.b SF_LAUNCH_COUNT*32,0
