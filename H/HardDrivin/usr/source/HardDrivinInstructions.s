; Pause-aware instruction scroll and seven-step camera transition.
; Native step = eight PAL fields. No physics updates in this presentation epoch.
_instructions_install:
	movem.l a0-a2,-(a7)
	lea _instructions_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_instructions_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_INSTRUCTIONS $114b2 $0006: instruction scroll epoch
	PL_PS $114b2,_instructions_begin
	; PERF_RANGE VERIFY_TIME_INSTRUCTIONS $114be $000c: elapsed scroll position
	PL_PSS $114be,_instructions_scroll,6
	; PERF_RANGE VERIFY_TIME_INSTRUCTIONS $11572 $0008: camera transition epoch
	PL_PSS $11572,_instructions_camera_begin,2
	; PERF_RANGE VERIFY_TIME_INSTRUCTIONS $1157a $0022: elapsed camera pose
	PL_PSS $1157a,_instructions_camera_frame,$1c
	; PERF_RANGE VERIFY_TIME_INSTRUCTIONS $115e4 $000a: camera duration and final pose
	PL_PSS $115e4,_instructions_camera_end,4
	PL_END
IN_START equ 0
IN_AGE equ 4
IN_FIRST equ 8
IN_ACTIVE equ 9
IN_X equ 10
IN_Y equ 12
IN_Z equ 14
IN_PITCH equ 16
IN_HEADING equ 18
_instructions_signature: dc.b 'HDINSTR1'
_instructions_state: dcb.b 20,0
_instructions_begin:
	move.l a0,-(a7)
	lea _instructions_state(pc),a0
	move.l _replay_state+RP_WALL(pc),IN_START(a0)
	clr.l IN_AGE(a0)
	st IN_FIRST(a0)
	move.b #1,IN_ACTIVE(a0)
	movea.l (a7)+,a0
	move.w #15,-2(a5)
	rts
_instructions_scroll:
	movem.l d0-d1/a0,-(a7)
	lea _instructions_state(pc),a0
	bsr _instructions_age
	; The first native displayed position is 18, then +3 per eight fields.
	cmpi.l #232,d0
	bls.s .bounded
	move.l #232,d0
.bounded:
	mulu.w #3,d0
	lsr.l #3,d0
	addi.w #18,d0
	move.w d0,-2(a5)
	movem.l (a7)+,d0-d1/a0
	rts
; Sample after controls; first actual pose starts at age zero. Forced native
; checks use the same code with an eight-field increment per displayed pose.
_instructions_age:
	IFD VERIFY_DISPATCH_NATIVE
	move.l IN_AGE(a0),d0
	tst.b IN_FIRST(a0)
	bne.s .first
	addq.l #8,d0
	ELSE
	move.l _replay_state+RP_WALL(pc),d0
	tst.b IN_FIRST(a0)
	beq.s .elapsed
	move.l d0,IN_START(a0)
.elapsed:
	sub.l IN_START(a0),d0
	ENDC
.first:
	clr.b IN_FIRST(a0)
	move.l d0,IN_AGE(a0)
	rts
_instructions_camera_begin:
	move.w d0,-16(a5)
	bsr _instructions_begin
	move.l a0,-(a7)
	lea _instructions_state(pc),a0
	move.b #2,IN_ACTIVE(a0)
	move.w -$670a(a4),IN_X(a0)
	move.w -$6708(a4),IN_Y(a0)
	move.w -$6706(a4),IN_Z(a0)
	move.w -$66b4(a4),IN_PITCH(a0)
	move.w -$66b6(a4),IN_HEADING(a0)
	movea.l (a7)+,a0
	clr.w -2(a5)
	rts
_instructions_camera_frame:
	movem.l d0-d2/a0,-(a7)
	lea _instructions_state(pc),a0
	bsr _instructions_age
	bsr _instructions_camera_pose
	movem.l (a7)+,d0-d2/a0
	rts
; Absolute interpolation of the native pre-divided displacement. Preserve its
; seven-step endpoint, including division rounding and word destination wrap.
_instructions_camera_pose:
	cmpi.l #48,d0
	bls.s .bounded
	moveq #48,d0
.bounded:
	addq.w #8,d0
	move.w d0,d2
	move.w -12(a5),d1
	bsr _instructions_product
	move.w IN_X(a0),d0
	sub.w d1,d0
	move.w d0,-$670a(a4)
	move.w -14(a5),d1
	bsr _instructions_product
	move.w IN_Y(a0),d0
	sub.w d1,d0
	move.w d0,-$6708(a4)
	move.w -16(a5),d1
	bsr _instructions_product
	move.w IN_Z(a0),d0
	sub.w d1,d0
	move.w d0,-$6706(a4)
	move.w d2,d0
	lsr.w #3,d0
	add.w IN_PITCH(a0),d0
	move.w d0,-$66b4(a4)
	move.w d2,d1
	add.w d1,d1
	move.w IN_HEADING(a0),d0
	sub.w d1,d0
	move.w d0,-$66b6(a4)
	rts
; Signed truncation toward zero; no DIVS quotient overflow at word extremes.
_instructions_product:
	muls.w d2,d1
	bpl.s .positive
	addq.l #7,d1
.positive:
	asr.l #3,d1
	rts
_instructions_camera_end:
	movem.l d0-d2/a0,-(a7)
	lea _instructions_state(pc),a0
	IFD VERIFY_DISPATCH_NATIVE
	move.l IN_AGE(a0),d0
	addq.l #8,d0
	ELSE
	move.l _replay_state+RP_WALL(pc),d0
	sub.l IN_START(a0),d0
	ENDC
	cmpi.l #56,d0
	blo.s .running
	moveq #48,d0
	bsr _instructions_camera_pose
	; A long final frame can skip the last pose. Consume that tail and update
	; its wider positions even though it will not be drawn in this menu.
	moveq #0,d0
	move.w -$670a(a4),d0
	lsl.l #3,d0
	move.l d0,-$6704(a4)
	move.w -$6708(a4),d0
	ext.l d0
	lsl.l #3,d0
	move.l d0,-$6700(a4)
	moveq #0,d0
	move.w -$6706(a4),d0
	lsl.l #3,d0
	move.l d0,-$66fc(a4)
	clr.b IN_ACTIVE(a0)
	moveq #56,d0
.running:
	lsr.l #3,d0
	move.w d0,-2(a5)
	movem.l (a7)+,d0-d2/a0
	andi #$ef,ccr
	cmpi.w #7,-2(a5)
	rts
