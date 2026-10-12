; Elapsed presentation for the two-history Phantom post-race replay.
_ghost_post_install:
	IFD VERIFY_GHOST_POST_MATH
	bsr _ghost_post_math_test
	ENDC
	movem.l a0-a2,-(a7)
	lea _ghost_post_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_ghost_post_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_GHOST_POST $1111c $0006: post-race replay epoch
	PL_PS $1111c,_ghost_post_begin
	; PERF_RANGE VERIFY_TIME_GHOST_POST $11122 $0030: elapsed stop and both poses
	PL_P $11122,_ghost_post_outer
	PL_NOP $11128,$2a
	; PERF_RANGE VERIFY_TIME_GHOST_POST $111a0 $0016: distance derivative per native step
	PL_PSS $111a0,_ghost_post_pitch,$10
	; PERF_RANGE VERIFY_TIME_GHOST_POST $11262 $000c: replay cleanup and cursor restore
	PL_PSS $11262,_ghost_post_end,6
	PL_END
PG_START equ 0
PG_AGE equ 4
PG_PREVIOUS equ 8
PG_DELTA equ 12
PG_DURATION equ 16
PG_PLAYER equ 20
PG_OPPONENT equ 24
PG_PLAYER_PHASE equ 28
PG_OPPONENT_PHASE equ 30
PG_ACTIVE equ 32
PG_FIRST equ 33
PG_PHASE_SOURCES equ 34
PG_OVERLAY_LAST equ 36
PG_RETURN equ 40
PG_SIZE equ 44
_ghost_post_signature: dc.b 'HDGHPOST'
_ghost_post_state: dcb.b PG_SIZE,0
_ghost_post_begin:
	movem.l d0-d3/a0-a1,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _ghost_post_state(pc),a0
	move.l _replay_state+RP_WALL(pc),PG_START(a0)
	move.l PG_START(a0),PG_OVERLAY_LAST(a0)
	clr.l PG_AGE(a0)
	clr.l PG_PREVIOUS(a0)
	clr.l PG_DELTA(a0)
	clr.w PG_PHASE_SOURCES(a0)
	st PG_ACTIVE(a0)
	st PG_FIRST(a0)
	move.l -$16dc(a4),PG_PLAYER(a0)
	move.l -$16d8(a4),PG_OPPONENT(a0)
	moveq #0,d0
	move.b -$16de(a4),d0
	lsl.w #3,d0
	lea _ghost_record_state(pc),a1
	tst.b GR_VALID(a1)
	beq.s .player_phase
	move.l -4(a5),d1
	cmp.l GR_POINTER(a1),d1
	bne.s .player_phase
	move.w GR_PHASE(a1),d1
	andi.w #$fff8,d1
	cmp.w d0,d1
	bne.s .player_phase
	move.w GR_PHASE(a1),d0
	lea _ghost_post_state(pc),a1
	bset #0,PG_PHASE_SOURCES(a1)
.player_phase:
	lea _ghost_post_state(pc),a0
	move.w d0,PG_PLAYER_PHASE(a0)
	moveq #0,d0
	move.b -$16d4(a4),d0
	lsl.w #3,d0
	lea _ghost_opponent_state(pc),a1
	tst.b GP_VALID(a1)
	beq.s .opponent_phase
	move.l -8(a5),d1
	cmp.l GP_EXPECTED(a1),d1
	bne.s .opponent_phase
	moveq #0,d1
	move.b GP_PHASE(a1),d1
	lsl.w #3,d1
	cmp.w d0,d1
	bne.s .opponent_phase
	move.l GP_POSITION(a1),d0
	divu.w #48,d0
	swap d0
	lea _ghost_post_state(pc),a1
	bset #1,PG_PHASE_SOURCES(a1)
.opponent_phase:
	lea _ghost_post_state(pc),a0
	move.w d0,PG_OPPONENT_PHASE(a0)
	; Stop when either cursor reaches its native saved-pointer-minus-record
	; bound. The native rewind is at most 30 records, hence at most 1392 fields.
	move.l -4(a5),d0
	sub.l PG_PLAYER(a0),d0
	subi.l #12,d0
	lsl.l #2,d0
	moveq #0,d1
	move.w PG_PLAYER_PHASE(a0),d1
	sub.l d1,d0
	bpl.s .player_duration
	moveq #0,d0
.player_duration:
	move.l d0,d2
	move.l -8(a5),d0
	sub.l PG_OPPONENT(a0),d0
	subi.l #12,d0
	lsl.l #2,d0
	moveq #0,d1
	move.w PG_OPPONENT_PHASE(a0),d1
	sub.l d1,d0
	bpl.s .opponent_duration
	moveq #0,d0
.opponent_duration:
	cmp.l d2,d0
	bls.s .duration
	move.l d2,d0
.duration:
	move.l d0,PG_DURATION(a0)
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d3/a0-a1
	move.w #1000,-22(a5)
	rts
_ghost_post_overlay_fields:
	lea _ghost_post_state+PG_OVERLAY_LAST(pc),a0
	move.l _replay_state+RP_WALL(pc),d1
	bra _replay_overlay_interval
_ghost_post_outer:
	movem.l d0-d7/a0-a3,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _ghost_post_state(pc),a3
	IFD VERIFY_DISPATCH_NATIVE
	move.l PG_AGE(a3),d0
	tst.b PG_FIRST(a3)
	bne.s .bounded
	addq.l #8,d0
	bra .bounded
	ELSE
	move.l _replay_state+RP_WALL(pc),d0
	tst.b PG_FIRST(a3)
	beq.s .age
	; Anchor to the first possible pose, excluding the preceding camera setup.
	move.l d0,PG_START(a3)
.age:
	sub.l PG_START(a3),d0
	cmp.l PG_DURATION(a3),d0
	bls.s .bounded
	move.l PG_DURATION(a3),d0
	ENDC
.bounded:
	move.l d0,PG_AGE(a3)
	sub.l PG_PREVIOUS(a3),d0
	move.l d0,PG_DELTA(a3)
	move.l PG_AGE(a3),PG_PREVIOUS(a3)
	move.l PG_AGE(a3),d5
	bsr _ghost_post_player_cursor
	move.l a0,-$16dc(a4)
	move.w d6,d0
	lsr.w #3,d0
	move.b d0,-$16de(a4)
	cmp.l PG_DURATION(a3),d5
	bhs.s .opponent
	tst.b -$5222(a4)
	beq.s .opponent
	lea 12(a0),a1
	movea.l -$6686(a4),a2
	bsr _ghost_playback_pose
.opponent:
	movea.l PG_OPPONENT(a3),a0
	moveq #0,d4
	move.w PG_OPPONENT_PHASE(a3),d4
	bsr _ghost_post_cursor
	move.l a0,-$16d8(a4)
	move.w d6,d0
	lsr.w #3,d0
	move.b d0,-$16d4(a4)
	cmp.l PG_DURATION(a3),d5
	bhs.s .exit
	cmpi.b #4,-$5222(a4)
	blt.s .draw
	lea 12(a0),a1
	movea.l -$6682(a4),a2
	bsr _ghost_playback_pose
	bsr _ghost_finish_native
.draw:
	IFD VERIFY_DISPATCH_NATIVE
	; Native calls publish the NEXT eight-field phase after rendering. Keep
	; that externally visible ordering in the forced-T=1 equivalence build.
	addq.l #8,d5
	bsr _ghost_post_player_cursor
	move.l a0,-$16dc(a4)
	move.w d6,d0
	lsr.w #3,d0
	move.b d0,-$16de(a4)
	movea.l PG_OPPONENT(a3),a0
	moveq #0,d4
	move.w PG_OPPONENT_PHASE(a3),d4
	bsr _ghost_post_cursor
	move.l a0,-$16d8(a4)
	move.w d6,d0
	lsr.w #3,d0
	move.b d0,-$16d4(a4)
	ENDC
	clr.w (a7)
	movea.l _code_start(pc),a0
	adda.l #$11152,a0
	bra.s .return
.exit:
	movea.l _code_start(pc),a0
	adda.l #$1125a,a0
.return:
	move.l a0,PG_RETURN(a3)
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d7/a0-a3
	move.l _ghost_post_state+PG_RETURN(pc),-(a7)
	rts
_ghost_post_player_cursor:
	movea.l PG_PLAYER(a3),a0
	moveq #0,d4
	move.w PG_PLAYER_PHASE(a3),d4
; A0 starting pointer, D4 initial phase, D5 age. Return cursor A0 and phase D6.
_ghost_post_cursor:
	move.l d5,d0
	add.l d4,d0
	divu.w #48,d0
	move.w d0,d1
	mulu.w #12,d1
	adda.l d1,a0
	swap d0
	move.w d0,d6
	rts
_ghost_post_pitch:
	movem.l d2-d3/a0,-(a7)
	lea _ghost_post_state(pc),a0
	move.l PG_DELTA(a0),d1
	tst.b PG_FIRST(a0)
	beq.s .later
	clr.b PG_FIRST(a0)
	moveq #8,d1
.later:
	tst.l d1
	beq.s .hold
	move.w -20(a5),d0
	sub.w -22(a5),d0
	bsr _ghost_post_rate
	move.w #800,d1
	sub.w d0,d1
	move.w d1,-$69fe(a4)
.hold:
	movem.l (a7)+,d2-d3/a0
	rts
; Signed distance-word delta D0, nonzero unsigned fields D1. Return low word
; of trunc(delta*48/fields), preserving the native destination's word wrap.
; Two unsigned divisions avoid DIVS overflow on short, high-derivative frames.
_ghost_post_rate:
	muls.w #48,d0
	moveq #0,d3
	tst.l d0
	bpl.s .positive
	moveq #1,d3
	neg.l d0
.positive:
	move.l d0,d2
	clr.w d2
	swap d2
	divu.w d1,d2
	move.w d0,d2
	divu.w d1,d2
	move.w d2,d0
	tst.b d3
	beq.s .done
	neg.w d0
.done:
	rts
_ghost_post_end:
	move.l a0,-(a7)
	lea _ghost_post_state(pc),a0
	clr.b PG_ACTIVE(a0)
	movea.l (a7)+,a0
	move.l -4(a5),-$16dc(a4)
	move.l -8(a5),-$16d8(a4)
	rts

	IFD VERIFY_GHOST_POST_MATH
_ghost_post_math_test:
	movem.l d0-d7/a0-a2,-(a7)
	lea _ghost_post_math_deltas(pc),a0
	lea _ghost_post_math_results(pc),a2
	moveq #9-1,d5
.delta:
	lea _ghost_post_math_fields(pc),a1
	moveq #8-1,d6
.fields:
	move.w (a0),d0
	moveq #0,d1
	move.w (a1)+,d1
	bsr _ghost_post_rate
	move.w d0,(a2)+
	dbf d6,.fields
	addq.l #2,a0
	dbf d5,.delta
	moveq #0,d4
.phase:
	lea _ghost_post_math_ages(pc),a1
	moveq #8-1,d2
.age:
	movea.l #$10000,a0
	moveq #0,d5
	move.w (a1)+,d5
	bsr _ghost_post_cursor
	move.l a0,(a2)+
	move.w d6,(a2)+
	dbf d2,.age
	addq.w #1,d4
	cmpi.w #48,d4
	blo.s .phase
	movem.l (a7)+,d0-d7/a0-a2
	rts
_ghost_post_math_deltas: dc.w -32768,-32767,-1234,-1,0,1,1234,32766,32767
_ghost_post_math_fields: dc.w 1,2,3,7,8,9,1392,65535
_ghost_post_math_ages: dc.w 0,1,7,8,47,48,1391,1392
_ghost_post_math_signature: dc.b 'HDGHPMA1'
_ghost_post_math_results: dcb.b 9*8*2+48*8*6,0
	ENDC
