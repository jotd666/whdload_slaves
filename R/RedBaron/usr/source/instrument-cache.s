; E2 persistent native gauge cache, sim v1, measured 020/040 classes only, CUSTOM2 bit 18.
; Reuse pixels only with identical raw inputs/context AND a matching packed
; pixel guard. Native forced redraws, changing bounds and unsupported geometry
; fall back. The normal verified mask must not select this until measured.
; PERF_RANGE sim:19d22 8 bit=18
; PERF_RANGE sim:19de0 8 bit=18
IC_KEY = 4
IC_KEY_BYTES = 288
IC_AREA = 292
IC_POST = 300
IC_PIXELS = 340
IC_SIZE = 2260
IC_SLOTS = 14
IC_RECT_KEY = 88
IC_DEST_KEY = 60

instrument_cache_install:
 movem.l d0-a6,-(sp)
 lea .cpu(pc),a0
.cpu
 adda.l #perf_instrument_cpu-.cpu,a0
 jsr (a0)
 tst.l d1
 bne .cpu_ready
 lea .options(pc),a0
.options
 adda.l #perf_mask-.options,a0
 btst #3,1(a0) ; bit 19 requests gauge-layer capture on every supported 020+
 beq .done
.cpu_ready
 move.l a1,a3
 move.l a3,a0
 adda.l #$301b2,a0
 move.l (a0),d0
 subi.l #$9a2c,d0
 lea instrument_cache_h3(pc),a0
 move.l d0,(a0)
 addi.l #$9d46,d0
 lea .before_bytes+4(pc),a0
 move.l d0,(a0)
 lea .check(pc),a6
.check
 adda.l #perf_check_bytes-.check,a6
 move.l #$19d22,d0
 moveq #8,d1
 lea .before_bytes(pc),a0
 jsr (a6)
 move.l #$19de0,d0
 moveq #8,d1
 lea .after_bytes(pc),a0
 jsr (a6)
 move.l a3,d0
 addi.l #$19d2a,d0
 lea instrument_cache_native_tail+2(pc),a0
 move.l d0,(a0)
 move.l a3,d0
 addi.l #$19de0,d0
 lea instrument_cache_skip_tail+2(pc),a0
 move.l d0,(a0)
 move.l a3,d0
 addi.l #$19c60,d0
 lea instrument_cache_loop_tail+2(pc),a0
 move.l d0,(a0)
 bsr instrument_cache_invalidate
 bsr ovlife_install
 move.l a3,a1
 lea .patch(pc),a0
 jsr resload_Patch(a2)
 jsr resload_FlushCache(a2)
.done
 movem.l (sp)+,d0-a6
 rts
.before_bytes: dc.w $33fc,$0001
 dc.l 0
.after_bytes: dc.w $5244,$588b,$6000,$fe7a
.patch
 PL_START
 PL_P $19d22,instrument_cache_before
 PL_NOP $19d28,2
 PL_P $19de0,instrument_cache_after
 PL_NOP $19de6,2
 PL_END

instrument_cache_invalidate:
 movem.l d0/a0,-(sp)
 move.l instrument_cache_pool(pc),a0
 cmpa.l #0,a0
 beq .done
 moveq #IC_SLOTS-1,d0
.loop
 clr.l (a0)
 adda.l #IC_SIZE,a0
 dbf d0,.loop
.done
 movem.l (sp)+,d0/a0
 rts

instrument_cache_allocate:
 movem.l d0-d1/a0-a1/a6,-(sp)
 lea instrument_cache_attempted(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 move.l 4.w,a6
 move.l #IC_SIZE*IC_SLOTS,d0
 move.l #$10004,d1 ; cleared fast RAM, no chip fallback
 jsr _LVOAllocMem(a6)
 lea instrument_cache_pool(pc),a0
 move.l d0,(a0)
.done
 movem.l (sp)+,d0-d1/a0-a1/a6
 rts

instrument_cache_before:
 movem.l d0-a6,-(sp)
 lea instrument_cache_pending(pc),a0
 clr.l (a0)
 move.l instrument_cache_h3(pc),a4
 adda.l #$8000,a4
 lea .layers_before(pc),a0
.layers_before
 adda.l #cockpit_gauges_before-.layers_before,a0
 jsr (a0)
 ; Complete-composition records have the same post-state layout. Their
 ; stricter whole-coverage guard makes an unchanged draw a native fixed point.
 lea .full_reuse(pc),a0
.full_reuse
 adda.l #cockpit_gauge_reuse-.full_reuse,a0
 move.l (a0),a6
 cmpa.l #0,a6
 beq .standalone
 IFD VERIFY
 lea instrument_cache_twin_result(pc),a0
 tst.l 16(a0)
 bne ic_before_native
 bsr instrument_cache_twin_begin
 tst.l d0
 bne ic_before_native
 lea cockpit_gauge_reuse_count(pc),a0
 addq.l #1,(a0)
 ENDC
 bsr instrument_cache_restore
 movem.l (sp)+,d0-a6
 jmp instrument_cache_skip_tail(pc)
.standalone
 ; Standalone gauge reuse keeps its measured 020/040 policy. Other CPUs
 ; use the shared hooks for the bit-19 compositor and its own guarded reuse.
 lea .reuse_cpu(pc),a0
.reuse_cpu
 adda.l #perf_instrument_cpu-.reuse_cpu,a0
 jsr (a0)
 tst.l d1
 beq ic_before_native
 IFD VERIFY
 lea instrument_cache_twin_result(pc),a0
 tst.l 16(a0)
 bne ic_before_native
 ENDC
 tst.w d7
 bne ic_before_native
 ; With modal clip mode clear, sim:1efdc extends the background clip to
 ; h3:7670. The bounded previous-rectangle guard does not cover that path.
 tst.b -$6178(a4)
 beq ic_before_native
 tst.b -$ee4(a4) ; h3:711c native redraw count
 bne ic_before_native
 cmpi.w #6,d4
 bhi ic_before_native
 cmpi.b #1,-$ee3(a4) ; h3:711d native page
 bhi ic_before_native
 cmpi.l #8000,$1d34(a4)
 bne ic_before_native
 cmpi.w #5,$1d3c(a4)
 bne ic_before_native
 cmpi.w #320,$1d40(a4)
 bne ic_before_native
 cmpi.w #40,$1d42(a4)
 bne ic_before_native
 cmpi.w #200,$1d44(a4)
 bne ic_before_native
 bsr instrument_cache_allocate
 move.l instrument_cache_pool(pc),d0
 beq ic_before_native
 move.l d0,a6
 move.w d4,d0
 add.w d0,d0
 moveq #0,d1
 move.b -$ee3(a4),d1
 add.w d1,d0
 mulu.w #IC_SIZE,d0
 adda.l d0,a6
 move.l a2,a3 ; native background descriptor
 bsr instrument_cache_key
 tst.l d0
 beq ic_before_reject
 lea -26(a5),a0 ; native saved previous rectangle
 lea -$64e6(a4),a1 ; h3:1b1a signed byte padding
 lea instrument_cache_area(pc),a2
 bsr instrument_region
 tst.l d0
 beq ic_before_reject
 tst.l (a6)
 beq ic_before_miss
 lea instrument_cache_key_temp(pc),a0
 lea IC_KEY(a6),a1
 moveq #IC_KEY_BYTES/4-1,d0
ic_before_compare_key
 cmpm.l (a0)+,(a1)+
 bne ic_before_miss
 dbf d0,ic_before_compare_key
 move.l $1d72(a4),a0
 lea IC_PIXELS(a6),a1
 lea IC_AREA(a6),a2
 moveq #0,d0
 bsr instrument_pixels
 tst.l d0
 beq ic_before_miss
 IFD VERIFY
 bsr instrument_cache_twin_begin
 tst.l d0
 bne ic_before_native
 ENDC
 bsr instrument_cache_restore
 IFD VERIFY
 lea instrument_cache_stats(pc),a0
 addq.l #1,(a0)
 ENDC
 movem.l (sp)+,d0-a6
instrument_cache_skip_tail:
 jmp $0.l
ic_before_miss
 clr.l (a6)
 lea instrument_cache_key_temp(pc),a0
 lea IC_KEY(a6),a1
 moveq #IC_KEY_BYTES/4-1,d0
ic_before_copy_key
 move.l (a0)+,(a1)+
 dbf d0,ic_before_copy_key
 lea instrument_cache_area(pc),a0
 move.l (a0)+,IC_AREA(a6)
 move.l (a0),IC_AREA+4(a6)
 lea instrument_cache_pending(pc),a0
 move.l a6,(a0)
 bra ic_before_native
ic_before_reject
 clr.l (a6)
ic_before_native
 move.w #1,$1d46(a4) ; original replaced instruction
 movem.l (sp)+,d0-a6
instrument_cache_native_tail:
 jmp $0.l

instrument_cache_after:
 movem.l d0-a6,-(sp)
 move.l instrument_cache_h3(pc),a4
 adda.l #$8000,a4
 lea .layers_after(pc),a0
.layers_after
 adda.l #cockpit_gauges_after-.layers_after,a0
 jsr (a0)
 IFD VERIFY
 bsr instrument_cache_twin_end
 ENDC
 lea instrument_cache_pending(pc),a0
 move.l (a0),a6
 clr.l (a0)
 cmpa.l #0,a6
 beq .done
 move.l instrument_cache_h3(pc),a4
 adda.l #$8000,a4
 move.w d4,d0
 lsl.w #4,d0
 moveq #0,d1
 move.b -$ee3(a4),d1
 lsl.w #3,d1
 add.w d1,d0
 lea -$ecc(a4),a0 ; h3:7134 rectangle history, now updated
 adda.w d0,a0
 lea IC_KEY+IC_RECT_KEY(a6),a1
 cmpm.l (a0)+,(a1)+
 bne .done
 cmpm.l (a0)+,(a1)+
 bne .done
 ; Only a stable rectangle can establish a repeated-draw fixed point.
 move.l $1d72(a4),a0
 lea IC_PIXELS(a6),a1
 lea IC_AREA(a6),a2
 moveq #1,d0
 bsr instrument_pixels
 tst.l d0
 beq .done
 bsr instrument_cache_save
 move.l #1,(a6)
 IFD VERIFY
 lea instrument_cache_stats(pc),a0
 addq.l #1,4(a0)
 ; Altitude commonly changes every presented frame. Exercise one exact
 ; same-input hit after a stable native rectangle, without modifying world
 ; state or waiting for coincidentally equal altitude on a later frame.
 tst.w d4
 bne .done
 lea instrument_cache_twin_repeat(pc),a0
 tst.w (a0)
 bne .done
 move.w #1,(a0)
 movem.l (sp)+,d0-a6
 jmp instrument_cache_before(pc)
 ENDC
.done
 movem.l (sp)+,d0-a6
 addq.w #1,d4
 addq.l #4,a3
instrument_cache_loop_tail:
 jmp $0.l

; Build a fixed, zero-padded key. a3=background descriptor; native d4/d5/d6
; are gauge/y/x. Preserve them, a4/a5/a6. Return d0=1 or 0, temp invalid on 0.
instrument_cache_key:
 lea instrument_cache_key_temp(pc),a1
 move.l a1,a0
 moveq #IC_KEY_BYTES/4-1,d0
.clear
 clr.l (a0)+
 dbf d0,.clear
 move.l a4,a0
 suba.l #$8000,a0
 move.w d4,d0
 bsr instrument_value_key
 tst.l d0
 beq .bad
 lea 12(a1),a1
 move.w d6,(a1)+
 move.w d5,(a1)+
 move.l a3,d0
 beq .bad
 btst #0,d0
 bne .bad
 tst.w 16(a3) ; require already-unmirrored sources, native requests flags 0
 bne .bad
 move.l a3,(a1)+
 move.l a3,a0
 moveq #8,d0
 bsr .copy_words
 moveq #0,d0
 cmpi.w #1,d4
 beq .attitude
 cmpi.w #3,d4
 bne .no_dynamic
 move.l -$ee0(a4),a0 ; h3:7120 image table
 cmpa.l #0,a0
 beq .bad
 move.l a0,d0
 btst #0,d0
 bne .bad
 move.l 24(a0),d0
 bra .dynamic
.attitude
 move.l -$ee0(a4),a0
 cmpa.l #0,a0
 beq .bad
 move.l a0,d0
 btst #0,d0
 bne .bad
 move.l 8(a0),d0
.dynamic
 beq .bad
 btst #0,d0
 bne .bad
 move.l d0,(a1)+
 move.l d0,a0
 tst.w 16(a0)
 bne .bad
 moveq #8,d0
 bsr .copy_words
 bra .geometry
.no_dynamic
 adda.w #22,a1
.geometry
 move.l $1d72(a4),(a1)+
 lea $1d34(a4),a0
 moveq #8,d0
 bsr .copy_words
 move.b -$6178(a4),(a1)+ ; h3:1e88 native clip mode
 addq.l #1,a1
 move.w -$64e6(a4),(a1)+ ; h3:1b1a padding
 move.w -$990(a4),(a1)+ ; h3:7670 modal/message clip limit
 lea -26(a5),a0
 moveq #3,d0
 bsr .copy_words
 lea -$64e6(a4),a0 ; lookup/calibration rows h3:1b1a..1bcd
 moveq #89,d0
 bsr .copy_words
 move.w -$eec(a4),(a1)+ ; h3:7114 speed table input, not overwritten
 move.w -$ee8(a4),(a1)+ ; h3:7118 speed table input, not overwritten
 ; Native bitmap wrappers also inspect high coordinate/flag bits.
 move.l d4,d0
 swap d0
 move.w d0,(a1)+
 move.l d5,d0
 swap d0
 move.w d0,(a1)+
 move.l d6,d0
 swap d0
 move.w d0,(a1)+
 move.l d7,d0
 swap d0
 move.w d0,(a1)+
 moveq #1,d0
 rts
.copy_words
 move.w (a0)+,(a1)+
 dbf d0,.copy_words
 rts
.bad
 moveq #0,d0
 rts

; Only replay fields actually written by this gauge. Other gauges' scratch
; rectangles and calibration words must retain the current frame's values.
instrument_cache_save:
 lea IC_POST(a6),a0
instrument_cache_state_read:
 lea $1d46(a4),a1
 moveq #4,d0
.clip
 move.w (a1)+,(a0)+
 dbf d0,.clip
 move.w $1d52(a4),(a0)+
 move.l -$6e4(a4),(a0)+ ; h3:791c needle bounds
 move.l -$6e0(a4),(a0)+
 move.l -$6ec(a4),(a0)+ ; h3:7914 altitude union bounds
 move.l -$6e8(a4),(a0)+
 move.l -$ed4(a4),(a0)+ ; h3:712c bitmap bounds
 move.l -$ed0(a4),(a0)+
 move.w -$eea(a4),(a0)+ ; h3:7116 speed calibration words
 move.w -$ee6(a4),(a0)+
 rts
instrument_cache_restore:
 lea IC_POST(a6),a0
 lea $1d46(a4),a1
 moveq #4,d0
.clip
 move.w (a0)+,(a1)+
 dbf d0,.clip
 cmpi.w #1,d4
 beq .bitmap
 cmpi.w #3,d4
 beq .bitmap
 move.w (a0),$1d52(a4)
 move.l 2(a0),-$6e4(a4)
 move.l 6(a0),-$6e0(a4)
 tst.w d4
 bne .speed
 move.l 10(a0),-$6ec(a4)
 move.l 14(a0),-$6e8(a4)
.speed
 cmpi.w #2,d4
 bne .done
 move.w 26(a0),-$eea(a4)
 move.w 28(a0),-$ee6(a4)
.done
 rts
.bitmap
 move.l 18(a0),-$ed4(a4)
 move.l 22(a0),-$ed0(a4)
 rts

instrument_cache_h3: dc.l 0
instrument_cache_pool: dc.l 0
instrument_cache_pending: dc.l 0
instrument_cache_attempted: dc.w 0
instrument_cache_area: dcb.w 4,0
instrument_cache_key_temp: dcb.b IC_KEY_BYTES,0
 IFD VERIFY
cockpit_gauge_reuse_count: dc.l 0
instrument_cache_stats: dc.l 0,0 ; hits, fixed-point fills
 ENDC
