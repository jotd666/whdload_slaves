; scenery cache: presentation-side native scenery cache. CUSTOM2 bit 25, fixed-step timing, 040/060.
; Packed snapshot: h3:5270..54da (618), h3:54de..54ec (14),
; render count (2), view (2), static pointer/count (6), visibility root (4),
; registration count (2), active registered pointers (up to 500*4).
SCENERY_FIXED = 648
SCENERY_BYTES = SCENERY_FIXED+2000
SC_ADDR MACRO
	lea .base\@(pc),\1
.base\@
	adda.l #\2-.base\@,\1
 ENDM

; Allocate only for enabled 040/060 fixed-step timing. No extra resident buffers on slower
; machines or when disabled. Allocation failure retains the forced-rebuild path.
time_scenery_world = 0
time_scenery_fingerprint = time_scenery_world+SCENERY_BYTES
time_scenery_present = time_scenery_fingerprint+SCENERY_BYTES
time_scenery_world_list = time_scenery_present+SCENERY_BYTES
time_scenery_present_list = time_scenery_world_list+2000
time_scenery_hash = time_scenery_present_list+2000
time_scenery_entries = time_scenery_hash+16384
time_scenery_verify_snapshot = time_scenery_entries+TIME_MODEL_CAPACITY*12
SCENERY_ALLOC = time_scenery_verify_snapshot
SC_BUF MACRO
	lea time_scenery_storage(pc),\1
	move.l (\1),\1
	adda.l #\2,\1
 ENDM

time_scenery_install:
	bsr time_scenery_invalidate
	SC_ADDR a0,perf_mask
	btst #1,(a0)
	beq .done
	movem.l d0-a6,-(sp)
	move.l #$f5f4,d0
	moveq #8,d1
	lea .exit_bytes(pc),a0
	movem.l a6,-(sp)
	SC_ADDR a6,perf_check_bytes
	jsr (a6)
	movem.l (sp)+,a6
	SC_ADDR a0,time_loop_sim
	move.l (a0),a0
	adda.l #$f06c,a0
	cmpi.w #$3039,(a0)
	bne time_scenery_bad
	SC_ADDR a3,time_loop_h3
	move.l (a3),d0
	addi.l #$5270,d0
	cmp.l 2(a0),d0
	bne time_scenery_bad
	lea time_scenery_storage(pc),a0
	tst.l (a0)
	bne .allocated
	movem.l a1-a2,-(sp)
	move.l $4.w,a6
	move.l #SCENERY_ALLOC,d0
	moveq #MEMF_FAST,d1
	jsr _LVOAllocMem(a6)
	movem.l (sp)+,a1-a2
	lea time_scenery_storage(pc),a0
	move.l d0,(a0)
	bne .allocated
	SC_ADDR a0,perf_mask
	bclr #1,(a0)
	bra .restore
.allocated
	lea .patch(pc),a0
	jsr resload_Patch(a2)
.restore
	movem.l (sp)+,d0-a6
.done
	rts
.exit_bytes: dc.w $4cdf,$4ce4,$4e5d,$4e75
.patch:
	PL_START
	PL_PS $f06c,time_scenery_rebuild
	PL_P $f5f4,time_scenery_return
	PL_END

time_scenery_invalidate:
	move.l a0,-(sp)
	lea time_scenery_valid(pc),a0
	clr.w (a0)
	move.l (sp)+,a0
	rts

; A world-side rebuild invalidates even when it happens to reproduce the key.
time_scenery_rebuild:
	movem.l a0,-(sp)
	SC_ADDR a0,time_present_active
	tst.w (a0)
	bne .draw
	bsr time_scenery_invalidate
.draw
	SC_ADDR a0,time_loop_h3
	move.l (a0),a0
	move.w $5270(a0),d0
	movem.l (sp)+,a0
	rts

; A0 snapshot destination; preserve A5/A6. All lengths checked before use.
time_scenery_snapshot:
	SC_ADDR a1,time_loop_h3
	move.l (a1),a1
	lea $5270(a1),a2
	move.w #308,d0
.first
	move.w (a2)+,(a0)+
	dbf d0,.first
	lea $54de(a1),a2
	moveq #6,d0
.key
	move.w (a2)+,(a0)+
	dbf d0,.key
	move.w $3fa8(a1),d0
	cmpi.w #500,d0
	bhi time_scenery_bad
	move.w d0,(a0)+
	move.w $6712(a1),(a0)+
	move.l $526a(a1),(a0)+
	move.w $526e(a1),(a0)+
	move.l $54da(a1),(a0)+
	adda.l #$859e,a1
	moveq #0,d0
	move.w (a1)+,d0
	cmpi.w #500,d0
	bhi time_scenery_bad
	move.w d0,(a0)+
	tst.w d0
	beq .done
	subq.w #1,d0
.registry
	move.l (a1)+,(a0)+
	dbf d0,.registry
.done
	rts

; A0 snapshot source: install only native output fields, never input roots.
time_scenery_unpack:
	SC_ADDR a1,time_loop_h3
	move.l (a1),a1
	lea $5270(a1),a2
	move.w #308,d0
.first
	move.w (a0)+,(a2)+
	dbf d0,.first
	lea $54de(a1),a2
	moveq #6,d0
.key
	move.w (a0)+,(a2)+
	dbf d0,.key
	move.w (a0),$3fa8(a1)
	rts

; Compare the live world snapshot and active list to the last draw's world.
; Also compare journal destinations: a world edit of visibility/model invalidates.
time_scenery_matches:
	SC_BUF a0,time_scenery_world
	SC_BUF a1,time_scenery_fingerprint
	moveq #0,d0
	move.w 646(a0),d0
	add.w d0,d0
	addi.w #SCENERY_FIXED/2-1,d0
.words
	cmpm.w (a0)+,(a1)+
	bne .no
	dbf d0,.words
	SC_ADDR a0,time_present_list_buffer_ptr
	move.l (a0),a0
	SC_BUF a1,time_scenery_world_list
	SC_BUF a2,time_scenery_world
	move.w 632(a2),d0
	beq .entries
	subq.w #1,d0
.list
	cmpm.l (a0)+,(a1)+
	bne .no
	dbf d0,.list
.entries
	SC_BUF a1,time_scenery_entries
	move.w time_scenery_count(pc),d0
	beq .yes
	subq.w #1,d0
.entry
	move.l (a1),a0
	move.b (a0),d1
	cmp.b 4(a1),d1
	bne .no
	cmpi.w #2,6(a1)
	bne .next
	move.b 1(a0),d1
	cmp.b 5(a1),d1
	bne .no
.next
	lea 12(a1),a1
	dbf d0,.entry
.yes
	moveq #1,d0
	rts
.no
	moveq #0,d0
	rts

time_scenery_begin:
	lea time_scenery_seen(pc),a0
	clr.w (a0)
	SC_BUF a0,time_scenery_world
	bsr time_scenery_snapshot
	lea time_scenery_valid(pc),a0
	tst.w (a0)
	beq .miss
	bsr time_scenery_matches
	tst.w d0
	beq .miss
	SC_BUF a0,time_scenery_present
	bsr time_scenery_unpack
	SC_BUF a0,time_scenery_present_list
	SC_ADDR a1,time_loop_h3
	move.l (a1),a1
	move.w $3fa8(a1),d0
	adda.l #$7dc8,a1
	movem.l a6,-(sp)
	SC_ADDR a6,time_present_list_copy
	jsr (a6)
	movem.l (sp)+,a6
	SC_BUF a3,time_scenery_entries
	move.w time_scenery_count(pc),d3
	beq .installed
	subq.w #1,d3
.install
	move.l (a3),a0
	move.w 6(a3),d0
	movem.l a6,-(sp)
	SC_ADDR a6,time_model_record
	jsr (a6)
	movem.l (sp)+,a6
	move.b 8(a3),(a0)
	cmpi.w #2,6(a3)
	bne .one
	move.b 9(a3),1(a0)
.one
	lea 12(a3),a3
	dbf d3,.install
.installed
	rts
.miss
	bsr time_scenery_invalidate
	SC_ADDR a0,time_loop_h3
	move.l (a0),a0
	move.l #-1,$54e6(a0)
	rts

; Capture terrain-only writes before object projection/model selection runs.
; Duplicate journal entries share their first world value and final draw value.
time_scenery_return:
	dc.w $42e7 ; MOVE CCR,-(SP), 040/060-only hook
	movem.l d0-a6,-(sp)
	SC_ADDR a0,time_present_active
	tst.w (a0)
	beq .done
	lea time_scenery_seen(pc),a0
	move.w #1,(a0)
	SC_ADDR a0,time_loop_h3
	move.l (a0),a0
	tst.w $54ea(a0)
	beq .done ; native cache hit: existing selected values are still installed
	lea time_scenery_count(pc),a4
	clr.w (a4)
	SC_BUF a5,time_scenery_hash
	move.l a5,a0
	move.w #4095,d0
.clear_hash
	clr.l (a0)+
	dbf d0,.clear_hash
	SC_BUF a6,time_scenery_entries
	SC_ADDR a3,time_model_buffer_ptr
	move.l (a3),a3
	SC_ADDR a0,time_model_count
	move.w (a0),d4
	beq .done
	subq.w #1,d4
.journal
	move.l (a3),d0
	move.l d0,d1
	lsr.l #8,d1
	eor.l d0,d1
	andi.w #8191,d1
	add.w d1,d1
.find
	moveq #0,d2
	move.w (a5,d1.w),d2
	beq .append
	subq.w #1,d2
	mulu.w #12,d2
	move.l a6,a1
	adda.l d2,a1
	cmp.l (a1),d0
	bne .collision
	move.w 6(a3),d2
	cmp.w 6(a1),d2
	beq .value
.collision
	addq.w #2,d1
	andi.w #16383,d1
	bra .find
.append
	moveq #0,d2
	move.w (a4),d2
	cmpi.w #TIME_MODEL_CAPACITY,d2
	bhs time_scenery_bad
	addq.w #1,(a4)
	move.w (a4),(a5,d1.w)
	mulu.w #12,d2
	move.l a6,a1
	adda.l d2,a1
	move.l (a3),(a1)
	move.l 4(a3),4(a1)
.value
	move.l (a3),a0
	move.b (a0),8(a1)
	clr.b 9(a1)
	cmpi.w #2,6(a3)
	bne .next
	move.b 1(a0),9(a1)
.next
	addq.l #8,a3
	dbf d4,.journal
.done
	movem.l (sp)+,d0-a6
	move.w (sp)+,ccr
	movem.l (sp)+,d2/d5-d7/a2-a3/a6
	unlk a5
	rts

time_scenery_end:
	lea time_scenery_seen(pc),a0
	tst.w (a0)
	beq .invalidate
	SC_BUF a0,time_scenery_present
	bsr time_scenery_snapshot
	SC_BUF a1,time_scenery_present_list
	SC_ADDR a0,time_loop_h3
	move.l (a0),a0
	move.w $3fa8(a0),d0
	adda.l #$7dc8,a0
	movem.l a6,-(sp)
	SC_ADDR a6,time_present_list_copy
	jsr (a6)
	movem.l (sp)+,a6
	SC_BUF a0,time_scenery_world
	SC_BUF a1,time_scenery_fingerprint
	moveq #0,d0
	move.w 646(a0),d0
	add.w d0,d0
	addi.w #SCENERY_FIXED/2-1,d0
.copy
	move.w (a0)+,(a1)+
	dbf d0,.copy
	SC_ADDR a0,time_present_list_buffer_ptr
	move.l (a0),a0
	SC_BUF a1,time_scenery_world_list
	SC_BUF a2,time_scenery_world
	move.w 632(a2),d0
	movem.l a6,-(sp)
	SC_ADDR a6,time_present_list_copy
	jsr (a6)
	movem.l (sp)+,a6
	lea time_scenery_valid(pc),a0
	move.w #1,(a0)
	bra .restore
.invalidate
	bsr time_scenery_invalidate
.restore
	SC_BUF a0,time_scenery_world
	bsr time_scenery_unpack
	rts

time_scenery_storage: dc.l 0
time_scenery_valid: dc.w 0
time_scenery_seen: dc.w 0
time_scenery_count: dc.w 0

time_scenery_bad:
	SC_ADDR a0,time_model_bad
	jmp (a0)
