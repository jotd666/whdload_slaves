; Development-only elapsed presentation clocks. Requires REPLAY_TIMING's
; pause-aware wall counter, which continues after gameplay TS_ACTIVE clears.
; GAME OVER retains its native 35-step duration: 280 eligible PAL fields.
_timeline_install:
	IFD VERIFY_TIME_INSTRUCTIONS
	bsr _instructions_install
	ENDC
	movem.l a0-a2,-(a7)
	movea.l _code_start(pc),a1
	lea _timeline_scene_ptr(pc),a0
	move.l a1,(a0)
	addi.l #$e49a,(a0)
	lea _timeline_patches(pc),a0
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_timeline_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_TIMELINES $10f62 $0008: GAME OVER epoch
	PL_PSS $10f62,_timeline_gameover_begin,2
	; PERF_RANGE VERIFY_TIME_TIMELINES $10f6a $0008: elapsed animation phase
	PL_PSS $10f6a,_timeline_gameover_frame,2
	; PERF_RANGE VERIFY_TIME_TIMELINES $10fe6 $000a: elapsed GAME OVER expiry
	PL_PSS $10fe6,_timeline_gameover_end,4
	PL_END
_timeline_signature: dc.b 'HDTMLIN1'
TL_START equ 0
TL_AGE equ 4
TL_OVERLAY_LAST equ 8
TL_ACTIVE equ 12
_timeline_state: dcb.b 16,0
_timeline_scene_ptr: dc.l 0
_timeline_overlay_reset:
	move.l a0,-(a7)
	lea _timeline_state(pc),a0
	move.l _replay_state+RP_WALL(pc),TL_OVERLAY_LAST(a0)
	movea.l (a7)+,a0
	rts
; Same bounded interval/forced-native policy as replay overlays.
_timeline_overlay_fields:
	lea _timeline_state+TL_OVERLAY_LAST(pc),a0
	move.l _replay_state+RP_WALL(pc),d1
	bra _replay_overlay_interval
_timeline_gameover_begin:
	move.l a0,-(a7)
	lea _timeline_state(pc),a0
	move.l _replay_state+RP_WALL(pc),TL_START(a0)
	clr.l TL_AGE(a0)
	st TL_ACTIVE(a0)
	bsr _timeline_overlay_reset
	movea.l (a7)+,a0
	clr.b -$6a13(a4)
	clr.w -2(a5)
	rts
_timeline_gameover_frame:
	jsr -$7e7e(a4)
	IFND VERIFY_DISPATCH_NATIVE
	; Sample after controls: a modal pause must not age the animation.
	bsr _timeline_gameover_phase
	ENDC
	; Tail-call the second displaced JSR with its original return address.
	move.l _timeline_scene_ptr(pc),-(a7)
	rts
; Publish min(floor(age/8),35). Long age handles slow frames without wrapping
; the native signed-word animation counter. Preserve registers and X.
_timeline_gameover_phase:
	movem.l d0-d1/a0,-(a7)
	moveq #0,d1
	roxl.b #1,d1
	move.w d1,-(a7)
	lea _timeline_state(pc),a0
	move.l _replay_state+RP_WALL(pc),d0
	sub.l TL_START(a0),d0
	move.l d0,TL_AGE(a0)
	lsr.l #3,d0
	cmpi.l #35,d0
	bls.s .bounded
	moveq #35,d0
.bounded:
	move.w d0,-2(a5)
	move.w (a7)+,d1
	lsr.b #1,d1
	movem.l (a7)+,d0-d1/a0
	rts
_timeline_gameover_end:
	IFD VERIFY_DISPATCH_NATIVE
	addq.w #1,-2(a5)
	ELSE
	bsr _timeline_gameover_phase
	; Native ADDQ of the bounded counter always clears X.
	andi #$ef,ccr
	ENDC
	cmpi.w #35,-2(a5)
	blt.s .compare
	move.l a0,-(a7)
	lea _timeline_state(pc),a0
	clr.b TL_ACTIVE(a0)
	movea.l (a7)+,a0
.compare:
	; Supply the native BLT's flags (CMP leaves X unchanged).
	cmpi.w #35,-2(a5)
	rts

	IFD VERIFY_TIME_INSTRUCTIONS
	INCLUDE "HardDrivinInstructions.s"
	ENDC
