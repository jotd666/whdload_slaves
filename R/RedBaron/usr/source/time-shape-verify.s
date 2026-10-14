; Exercise the same copy helpers on private guarded storage, never live h3.
time_present_shape_selftest:
	movem.l d0-a6,-(sp)
	lea time_present_shape_cases(pc),a3
	lea time_present_shape_test(pc),a4
	move.l #$13579bdf,(a4)
	move.l #$2468ace0,12(a4)
	moveq #2,d7
.next
	lea 4(a4),a0
	lea 8(a4),a1
	move.l (a3)+,(a0)
	move.l (a3)+,(a1)
	bsr time_present_shape_save
	move.l (a0),d0
	cmp.l (a2),d0
	bne time_present_state_bad
	move.l (a1),d0
	cmp.l 4(a2),d0
	bne time_present_state_bad
	not.l (a0)
	not.l (a1)
	bsr time_present_shape_restore
	move.l -8(a3),d0
	cmp.l (a0),d0
	bne time_present_state_bad
	move.l -4(a3),d0
	cmp.l (a1),d0
	bne time_present_state_bad
	cmpi.l #$13579bdf,(a4)
	bne time_present_state_bad
	cmpi.l #$2468ace0,12(a4)
	bne time_present_state_bad
	dbf d7,.next
	lea time_present_shape_result(pc),a0
	move.l #3,(a0)
	movem.l (sp)+,d0-a6
	rts

time_present_shape_cases:
	dc.l 0,$ffffffff,$01000100,$002468ac,$00ff005a,$0013579c
time_present_shape_test: dcb.l 4,0
time_present_shape_result: dc.l 0
