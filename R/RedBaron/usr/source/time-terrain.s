; Drawing and world registration/removal share h3:03fa8 + h3:07dc8.
; Preserve the active prefix and count; append always overwrites an inactive slot.
time_present_list_save:
	move.l time_pose_h3(pc),a0
	moveq #0,d0
	move.w $3fa8(a0),d0
	cmpi.w #500,d0
	bhi time_model_bad
	lea time_present_list_count(pc),a1
	move.w d0,(a1)
	adda.l #$7dc8,a0
	lea .buffer_base(pc),a1
.buffer_base
	adda.l #time_present_list_buffer_ptr-.buffer_base,a1
	move.l (a1),a1
	bra time_present_list_copy

time_present_list_restore:
	move.l time_pose_h3(pc),a1
	moveq #0,d0
	move.w time_present_list_count(pc),d0
	move.w d0,$3fa8(a1)
	adda.l #$7dc8,a1
	lea .buffer_base(pc),a0
.buffer_base
	adda.l #time_present_list_buffer_ptr-.buffer_base,a0
	move.l (a0),a0
	bra time_present_list_copy

; Count is bounded by the native 500-entry registration limit. Copy only the
; active prefix: stale tail entries are never read without first being replaced.
time_present_list_copy:
	tst.w d0
	beq .done
	subq.w #1,d0
.next
	move.l (a0)+,(a1)+
	dbf d0,.next
.done
	rts

time_present_list_count: dc.w 0

; The native terrain early-out at sim:0f038 reuses both cached visibility and
; selected model IDs. Those are restored after our draw, so a later draw must
; rebuild, even for an unchanged camera, on the original fixed-step timing path. scenery cache instead
; leases the complete presentation cache on supported CPUs. Keep the fallback
; key/flag/countdown coherent
; with the restored data. No IRQ-owned data is included.
time_terrain_cache_begin:
	lea .mask_base(pc),a0
.mask_base
	adda.l #perf_mask-.mask_base,a0
	btst #1,(a0)
	beq .original
	lea .target_base(pc),a0
.target_base
	adda.l #time_scenery_begin-.target_base,a0
	jmp (a0)
.original
	bsr time_terrain_cache_addresses
	bra time_terrain_cache_save

time_terrain_cache_end:
	lea .mask_base(pc),a0
.mask_base
	adda.l #perf_mask-.mask_base,a0
	btst #1,(a0)
	beq .original
	lea .target_base(pc),a0
.target_base
	adda.l #time_scenery_end-.target_base,a0
	jmp (a0)
.original
	bsr time_terrain_cache_addresses
	bra time_terrain_cache_restore

time_terrain_cache_addresses:
	lea .h3_base(pc),a0
.h3_base
	adda.l #time_loop_h3-.h3_base,a0
	move.l (a0),a0
	lea $5270(a0),a1
	adda.l #$54de,a0
	rts

; a0 = 12-byte cached camera position + two-byte recomputation flag;
; a1 = two-byte view-change countdown. The sentinel bypasses sim:0f038's
; positive-height test without changing native arguments or branch semantics.
time_terrain_cache_save:
	lea time_terrain_cache_saved(pc),a2
	move.w (a1),(a2)+
	move.l (a0)+,(a2)+
	move.l (a0)+,(a2)+
	move.l (a0)+,(a2)+
	move.w (a0),(a2)
	move.l #-1,-4(a0)
	rts

time_terrain_cache_restore:
	lea time_terrain_cache_saved(pc),a2
	move.w (a2)+,(a1)
	move.l (a2)+,(a0)+
	move.l (a2)+,(a0)+
	move.l (a2)+,(a0)+
	move.w (a2),(a0)
	rts

time_terrain_cache_saved: dcb.b 16,0
