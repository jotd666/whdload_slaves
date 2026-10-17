; Elapsed-time opponent playback in the Phantom challenge. The optional
; GHOST_POST gate owns the separate post-race presentation epoch.
_ghost_playback_install:
	movem.l d0/a0-a2,-(a7)
	lea _ghost_opponent_native_ptr(pc),a0
	move.l _code_start(pc),(a0)
	addi.l #$8c8c,(a0)
	; This self-contained native range tests the finish box and performs the
	; original message/sound side effects. Its internal exits target our RTS.
	movea.l _code_start(pc),a0
	adda.l #$8de0,a0
	lea _ghost_finish_native(pc),a1
	moveq #($8e52-$8de0)/2-1,d0
.copy:
	move.w (a0)+,(a1)+
	dbf d0,.copy
	IFD VERIFY_GHOST_PLAYBACK_MATH
	movea.l _resload(pc),a2
	jsr resload_FlushCache(a2)
	bsr _ghost_playback_math_test
	ENDC
	lea _ghost_playback_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	jsr resload_FlushCache(a2)
	movem.l (a7)+,d0/a0-a2
	rts
_ghost_playback_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_GHOST_PLAYBACK $08c84 $0008: elapsed opponent pose
	PL_P $8c84,_ghost_opponent
	PL_NOP $8c8a,2
	; PERF_RANGE VERIFY_TIME_GHOST_PLAYBACK $11862 $000a: opponent playback reset
	PL_PSS $11862,_ghost_opponent_reset,4
	PL_END
GP_POSITION equ 0
GP_RENDERED equ 4
GP_STAMP equ 8
GP_EXPECTED equ 12
GP_PHASE equ 16
GP_VALID equ 17
GP_CHECKS equ 20
GP_SIZE equ 24
; Initial ghost generation at $5a80 stops before slot299. Winning-history
; copying fills that slot with a duplicate of slot298. Hold the final known
; initialized record in either case, without reading the initial unused slot.
GP_END equ 298*48
_ghost_playback_signature: dc.b 'HDGHPLY1'
_ghost_opponent_state: dcb.b GP_SIZE,0
_ghost_opponent_native_ptr: dc.l 0
_ghost_finish_native: dcb.b $8e52-$8de0,0
	rts
_ghost_opponent_reset:
	movem.l d0/a0,-(a7)
	lea _ghost_opponent_state(pc),a0
	moveq #GP_SIZE/4-1,d0
.clear:
	clr.l (a0)+
	dbf d0,.clear
	movem.l (a7)+,d0/a0
	move.l -$69c0(a4),-$16d8(a4)
	clr.b -$16d4(a4)
	rts
_ghost_opponent:
	IFND VERIFY_DISPATCH_NATIVE
	move.l a0,-(a7)
	lea _dispatch_state(pc),a0
	tst.b DS_ACTIVE(a0)
	movea.l (a7)+,a0
	beq.s _ghost_opponent_native
	cmpi.b #4,-$5222(a4)
	blt.s _ghost_opponent_native
	movem.l d0-d7/a0-a6,-(a7)
	bsr _ghost_opponent_timed
	; Native final phase increment (or cursor increment) clears X.
	moveq #0,d0
	lsr.w #1,d0
	movem.l (a7)+,d0-d7/a0-a6
	rts
	ENDC
_ghost_opponent_native:
	link a5,#-10
	movem.l d4/a2-a3,-(a7)
	move.l _ghost_opponent_native_ptr(pc),-(a7)
	rts
_ghost_opponent_timed:
	lea _ghost_opponent_state(pc),a3
	tst.b GP_VALID(a3)
	beq.s .seed
	move.l -$16d8(a4),d0
	cmp.l GP_EXPECTED(a3),d0
	bne.s .seed
	move.b -$16d4(a4),d0
	cmp.b GP_PHASE(a3),d0
	bne.s .seed
	move.l _dispatch_state+DS_STEPS(pc),d0
	cmp.l GP_STAMP(a3),d0
	beq .done
	bra.s .crossings
.seed:
	move.l -$16d8(a4),d0
	sub.l -$69c0(a4),d0
	; Native cursors are record-aligned. Convert byte offset to field age.
	lsl.l #2,d0
	moveq #0,d1
	move.b -$16d4(a4),d1
	lsl.w #3,d1
	add.l d1,d0
	cmpi.l #GP_END,d0
	bls.s .seed_bounded
	move.l #GP_END,d0
.seed_bounded:
	move.l d0,GP_POSITION(a3)
	move.l d0,GP_RENDERED(a3)
	st GP_VALID(a3)
.crossings:
	; Test crossed native eight-field positions, then the actual current pose.
	; This preserves native triggers on long frames without extra physics or
	; scene passes. At an eight-field step there are no intermediate tests.
	move.l GP_RENDERED(a3),d7
	andi.l #$fffffff8,d7
	addq.l #8,d7
.loop:
	cmp.l GP_POSITION(a3),d7
	bhs.s .current
	tst.b -$6864(a4)
	bne.s .current
	move.l d7,d4
	bsr _ghost_opponent_pose_at
	bsr _ghost_finish_native
	addq.l #1,GP_CHECKS(a3)
	addq.l #8,d7
	bra.s .loop
.current:
	move.l GP_POSITION(a3),d4
	bsr _ghost_opponent_pose_at
	bsr _ghost_finish_native
	addq.l #1,GP_CHECKS(a3)
	move.l GP_POSITION(a3),GP_RENDERED(a3)
	moveq #0,d0
	move.w _time_scalar_fields(pc),d0
	add.l GP_POSITION(a3),d0
	cmpi.l #GP_END,d0
	bls.s .bounded
	move.l #GP_END,d0
.bounded:
	move.l d0,GP_POSITION(a3)
	divu.w #48,d0
	move.w d0,d1
	mulu.w #12,d1
	add.l -$69c0(a4),d1
	move.l d1,-$16d8(a4)
	move.l d1,GP_EXPECTED(a3)
	swap d0
	lsr.w #3,d0
	move.b d0,-$16d4(a4)
	move.b d0,GP_PHASE(a3)
	move.l _dispatch_state+DS_STEPS(pc),GP_STAMP(a3)
.done:
	rts
; D4 bounded field position, A3 companion preserved. Clamps the right endpoint
; to the final initialized record (slot298) in the 3600-byte allocation.
_ghost_opponent_pose_at:
	move.l d4,d0
	divu.w #48,d0
	move.w d0,d1
	mulu.w #12,d1
	movea.l -$69c0(a4),a0
	adda.l d1,a0
	movea.l a0,a1
	cmpi.w #298,d0
	bhs.s .last
	adda.w #12,a1
.last:
	swap d0
	move.w d0,d6
	movea.l -$6682(a4),a2
	bra _ghost_playback_pose
; A0/A1 history endpoints, A2 actor, D6 phase 0..47. Match native /6
; interpolation at multiples of eight: Y truncates each term separately,
; pitch adjusts only its left endpoint, heading/roll have no wrap correction.
; D0-D3 are scratch. A0-A3/D4-D7 survive.
_ghost_playback_pose:
	moveq #48,d2
	sub.w d6,d2
	move.w (a0),d0
	move.w (a1),d1
	bsr _ghost_playback_unsigned
	move.w d0,8(a2)
	move.w 4(a0),d0
	muls.w d2,d0
	divs.w #48,d0
	move.w d0,d3
	move.w 4(a1),d0
	muls.w d6,d0
	divs.w #48,d0
	add.w d3,d0
	move.w d0,10(a2)
	move.w 2(a0),d0
	move.w 2(a1),d1
	bsr _ghost_playback_unsigned
	move.w d0,12(a2)
	move.w 6(a0),d0
	move.w 6(a1),d1
	move.w d0,d3
	sub.w d1,d3
	bpl.s .positive
	neg.w d3
.positive:
	cmpi.w #720,d3
	ble.s .pitch
	tst.w d0
	bge.s .pitch_positive
	addi.w #1440,d0
	bra.s .pitch
.pitch_positive:
	subi.w #1440,d0
.pitch:
	bsr _ghost_playback_signed
	move.w d0,16(a2)
	move.w 8(a0),d0
	move.w 8(a1),d1
	bsr _ghost_playback_signed
	move.w d0,14(a2)
	move.w 10(a0),d0
	move.w 10(a1),d1
	bsr _ghost_playback_signed
	move.w d0,18(a2)
	rts
_ghost_playback_unsigned:
	mulu.w d2,d0
	mulu.w d6,d1
	add.l d1,d0
	divu.w #48,d0
	rts
_ghost_playback_signed:
	muls.w d2,d0
	muls.w d6,d1
	add.l d1,d0
	divs.w #48,d0
	rts

	IFD VERIFY_GHOST_PLAYBACK_MATH
; Private globals contain only the four native arithmetic jump vectors needed
; by the unpatched opponent routine. The finish flag suppresses side effects.
_ghost_playback_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	movea.l _code_start(pc),a0
	adda.l #$11a76,a0
	movea.l (a0),a0
	lea _ghost_playback_math_globals(pc),a4
	adda.l #$8000,a4
	move.l -$7f62(a0),-$7f62(a4)
	move.w -$7f5e(a0),-$7f5e(a4)
	move.l -$7f5c(a0),-$7f5c(a4)
	move.w -$7f58(a0),-$7f58(a4)
	move.l -$7dfa(a0),-$7dfa(a4)
	move.w -$7df6(a0),-$7df6(a4)
	move.l -$7de8(a0),-$7de8(a4)
	move.w -$7de4(a0),-$7de4(a4)
	move.b #4,-$5222(a4)
	st -$6864(a4)
	lea -$5000(a4),a2
	move.l a2,-$6682(a4)
	lea _ghost_playback_math_inputs(pc),a5
	lea -$4000(a4),a6
	moveq #0,d5
.case:
	moveq #0,d7
.phase:
	movea.l a5,a0
	lea 12(a5),a1
	move.w d7,d6
	bsr _ghost_playback_pose
	move.l 8(a2),(a6)+
	move.l 12(a2),(a6)+
	move.l 16(a2),(a6)+
	lea _ghost_playback_math_results(pc),a0
	addq.l #1,8(a0)
	move.w d7,d0
	andi.w #7,d0
	bne.s .next
	move.l a5,-$16d8(a4)
	move.w d7,d0
	lsr.w #3,d0
	move.b d0,-$16d4(a4)
	movea.l _code_start(pc),a0
	adda.l #$8c84,a0
	jsr (a0)
	lea _ghost_playback_math_results(pc),a0
	addq.l #1,4(a0)
	lea -12(a6),a1
	lea 8(a2),a0
	moveq #6-1,d0
.compare:
	move.w (a0)+,d1
	cmp.w (a1)+,d1
	bne.s .mismatch
	dbf d0,.compare
	bra.s .next
.mismatch:
	lea _ghost_playback_math_results(pc),a0
	addq.l #1,(a0)
.next:
	addq.w #1,d7
	cmpi.w #48,d7
	blo .phase
	adda.w #24,a5
	addq.w #1,d5
	cmpi.w #6,d5
	blo .case
	; Cross a finish box between two displayed poses. Only the original sound
	; vector is replaced, by a private counter; all finish side effects execute.
	move.l _dispatch_state+DS_STEPS(pc),-(a7)
	move.w _time_scalar_fields(pc),-(a7)
	lea _ghost_playback_math_sound(pc),a0
	move.w #$4ef9,-$7fce(a4)
	move.l a0,-$7fcc(a4)
	movea.l _resload(pc),a2
	jsr resload_FlushCache(a2)
	lea -$3000(a4),a0
	move.l a0,-$69c0(a4)
	move.w #1000,2(a0)
	move.w #1200,12(a0)
	move.w #1000,14(a0)
	move.w #30000,3576(a0)
	move.w #50000,3578(a0)
	move.w #500,3580(a0)
	move.w #100,3582(a0)
	move.w #200,3584(a0)
	move.w #300,3586(a0)
	move.w #-700,3594(a0)
	bsr _ghost_opponent_reset
	move.w #600,-$50e0(a4)
	clr.w -$50de(a4)
	move.w #1000,-$50dc(a4)
	clr.b -$6864(a4)
	st -$6a13(a4)
	lea _dispatch_state(pc),a0
	move.l #1,DS_STEPS(a0)
	lea _time_scalar_fields(pc),a0
	move.w #48,(a0)
	bsr _ghost_opponent_timed
	lea _dispatch_state(pc),a0
	move.l #2,DS_STEPS(a0)
	lea _time_scalar_fields(pc),a0
	move.w #8,(a0)
	bsr _ghost_opponent_timed
	lea _ghost_opponent_state(pc),a0
	lea _ghost_playback_math_results+16(pc),a1
	moveq #GP_SIZE/4-1,d0
.copy_event:
	move.l (a0)+,(a1)+
	dbf d0,.copy_event
	move.b -$6864(a4),(a1)+
	move.b -$6a13(a4),(a1)+
	move.b -$16d3(a4),(a1)+
	move.b -$50ce(a4),(a1)+
	move.b -$16d2(a4),(a1)+
	move.b -$16d1(a4),(a1)+
	addq.l #2,a1
	movea.l -$6682(a4),a0
	move.l 8(a0),(a1)+
	move.l 12(a0),(a1)+
	move.l 16(a0),(a1)+
	; Advance far beyond the buffer, then render its held final pose.
	lea _dispatch_state(pc),a0
	move.l #3,DS_STEPS(a0)
	lea _time_scalar_fields(pc),a0
	move.w #65535,(a0)
	bsr _ghost_opponent_timed
	lea _dispatch_state(pc),a0
	move.l #4,DS_STEPS(a0)
	lea _time_scalar_fields(pc),a0
	move.w #8,(a0)
	bsr _ghost_opponent_timed
	lea _ghost_opponent_state(pc),a0
	lea _ghost_playback_math_results+64(pc),a1
	moveq #GP_SIZE/4-1,d0
.copy_end:
	move.l (a0)+,(a1)+
	dbf d0,.copy_end
	movea.l -$6682(a4),a0
	move.l 8(a0),(a1)+
	move.l 12(a0),(a1)+
	move.l 16(a0),(a1)+
	bsr _ghost_opponent_reset
	lea _time_scalar_fields(pc),a0
	move.w (a7)+,(a0)
	lea _dispatch_state(pc),a0
	move.l (a7)+,DS_STEPS(a0)
	movem.l (a7)+,d0-d7/a0-a6
	rts
_ghost_playback_math_sound:
	move.l a0,-(a7)
	lea _ghost_playback_math_results+12(pc),a0
	addq.l #1,(a0)
	movea.l (a7)+,a0
	rts
_ghost_playback_math_inputs:
	dc.w 1000,2000,-3,700,-700,17,1007,1991,4,-700,700,-16
	dc.w 65535,0,-32768,-700,720,-720,0,65535,32767,700,-720,720
	dc.w 0,65535,32767,0,0,0,65535,0,-32768,0,0,0
	dc.w 65534,65534,-5,720,5,5,65535,65535,-5,-720,5,5
	dc.w 31,47,1,-720,-719,-1,31,47,1,720,-720,1
	dc.w 20000,20100,500,359,100,200,20001,20099,-501,-359,99,199
_ghost_playback_math_signature: dc.b 'HDGHPMT1'
_ghost_playback_math_results: dcb.b 112,0
_ghost_playback_math_globals: dcb.b $6930,0
	ENDC
