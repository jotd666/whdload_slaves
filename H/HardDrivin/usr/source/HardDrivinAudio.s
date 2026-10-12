; Live off-road, skid, partial-contact and ground-penetration sample cadence.
; Requests use pause-aware presentation fields because Paula runs in wall time
; even when physics takes multiple substeps.
_audio_install:
	IFD VERIFY_AUDIO_MATH
	bsr _audio_math_test
	ENDC
	movem.l a0-a2,-(a7)
	lea _audio_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_audio_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_AUDIO $0b162 $000a: off-road requests at elapsed cadence
	PL_PSS $b162,_audio_offroad,4
	; PERF_RANGE VERIFY_TIME_AUDIO $0b620 $000a: skid requests at elapsed cadence
	PL_PSS $b620,_audio_skid,4
	; PERF_RANGE VERIFY_TIME_AUDIO $0cd4e $000a: sustained mask-3 pitch contact
	PL_PSS $cd4e,_audio_pitch_contact,4
	; PERF_RANGE VERIFY_TIME_AUDIO $0cc80 $000a: sustained ground penetration, immediate landings
	PL_PSS $cc80,_audio_landing,4
	PL_END
AU_WALL equ 0
AU_STEP equ 4
AU_REQUESTS equ 8
AU_EMITTED equ 12
AU_VALID equ 16
AU_SIZE equ 20
_audio_signature: dc.b 'HDLIVEAU'
_audio_offroad_state: dcb.b AU_SIZE,0
_audio_skid_signature: dc.b 'HDSKIDAU'
_audio_skid_state: dcb.b AU_SIZE,0
_audio_pitch_signature: dc.b 'HDCONTAU'
_audio_pitch_state: dcb.b AU_SIZE,0
_audio_landing_signature: dc.b 'HDLANDAU'
_audio_landing_state: dcb.b AU_SIZE,0
_audio_offroad:
	IFND VERIFY_DISPATCH_NATIVE
	movem.l d0-d3/a0-a1,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _dispatch_state(pc),a1
	tst.b DS_ACTIVE(a1)
	beq.s .native_restore
	move.l DS_STEPS(a1),d1
	move.l _replay_state+RP_WALL(pc),d0
	lea _audio_offroad_state(pc),a0
	bsr _audio_due
	tst.w d0
	bne.s .native_restore
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d3/a0-a1
	rts
.native_restore:
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d3/a0-a1
	ENDC
	; Exact native call/cleanup, including the handler's returned X.
	move.w #8,-(a7)
	jsr -$7fce(a4)
	addq.w #2,a7
	rts
_audio_skid:
	IFND VERIFY_DISPATCH_NATIVE
	movem.l d0-d3/a0-a1,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _dispatch_state(pc),a1
	tst.b DS_ACTIVE(a1)
	beq.s .native_restore
	move.l DS_STEPS(a1),d1
	move.l _replay_state+RP_WALL(pc),d0
	lea _audio_skid_state(pc),a0
	bsr _audio_due
	tst.w d0
	bne.s .native_restore
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d3/a0-a1
	rts
.native_restore:
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d3/a0-a1
	ENDC
	; Exact native call/cleanup, including the handler's returned X.
	move.w #4,-(a7)
	jsr -$7fce(a4)
	addq.w #2,a7
	rts
; Only the mask-3 correction loop uses this state. Ground penetration uses
; a separate state; object-impact event7 callers keep native requests.
_audio_pitch_contact:
	IFND VERIFY_DISPATCH_NATIVE
	movem.l d0-d3/a0-a1,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _dispatch_state(pc),a1
	tst.b DS_ACTIVE(a1)
	beq.s .native_restore
	move.l DS_STEPS(a1),d1
	move.l _replay_state+RP_WALL(pc),d0
	lea _audio_pitch_state(pc),a0
	bsr _audio_due
	tst.w d0
	bne.s .native_restore
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d3/a0-a1
	rts
.native_restore:
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d3/a0-a1
	ENDC
	; Exact native call/cleanup, including the handler's returned X.
	move.w #7,-(a7)
	jsr -$7fce(a4)
	addq.w #2,a7
	rts
_audio_landing:
	IFND VERIFY_DISPATCH_NATIVE
	movem.l d0-d3/a0-a1,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _dispatch_state(pc),a1
	tst.b DS_ACTIVE(a1)
	beq.s .native_restore
	move.l DS_STEPS(a1),d1
	move.l _replay_state+RP_WALL(pc),d0
	lea _audio_landing_state(pc),a0
	move.w -$66f2(a4),d2
	bsr _audio_landing_due
	tst.w d0
	bne.s .native_restore
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d3/a0-a1
	rts
.native_restore:
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d3/a0-a1
	ENDC
	; Exact native call/cleanup, including the handler's returned X.
	move.w #7,-(a7)
	jsr -$7fce(a4)
	addq.w #2,a7
	rts
; A nonzero fall velocity marks a discrete landing: request immediately even
; inside the prior correction cadence. Subsequent zero-velocity penetration
; consumes that request's cadence rather than restarting on the next frame.
; Inputs as _audio_due, plus D2.W fall velocity.
_audio_landing_due:
	tst.w d2
	beq _audio_due
	clr.b AU_VALID(a0)
	bra _audio_due

; D0 wall fields, D1 completed/active step serial, A0 state. Return D0=0/1.
; First encounter after a missing eligible step is a new episode and immediate.
; Same-step rebuilds do not restart audio. A continuous episode can request at
; one request per elapsed eight-field cadence crossing. Retain the fractional
; interval when a frame arrives late; never burst historical restarts.
_audio_due:
	addq.l #1,AU_REQUESTS(a0)
	move.l d1,d2
	sub.l AU_STEP(a0),d2
	move.l d1,AU_STEP(a0)
	tst.b AU_VALID(a0)
	beq.s .episode
	cmpi.l #1,d2
	bhi.s .episode
	tst.l d2
	beq.s .skip
	move.l d0,d3
	sub.l AU_WALL(a0),d3
	cmpi.l #8,d3
	blo.s .skip
	; Advance to the latest due cadence boundary, preserving residual fields.
	; Even after several crossed boundaries, issue only one current request.
	andi.l #7,d3
	sub.l d3,d0
.episode:
	st AU_VALID(a0)
	move.l d0,AU_WALL(a0)
	addq.l #1,AU_EMITTED(a0)
	moveq #1,d0
	rts
.skip:
	moveq #0,d0
	rts

	IFD VERIFY_AUDIO_MATH
_audio_math_test:
	movem.l d0-d7/a0-a3,-(a7)
	lea _audio_test_inputs(pc),a1
	lea _audio_test_results(pc),a2
	lea _audio_test_state(pc),a0
	moveq #19-1,d7
.case:
	move.l (a1)+,d0
	beq.s .keep
	lea _audio_test_state(pc),a3
	moveq #4,d6
.clear:
	clr.l (a3)+
	dbf d6,.clear
.keep:
	move.l (a1)+,d0
	move.l (a1)+,d1
	bsr _audio_due
	move.l d0,(a2)+
	lea _audio_test_state(pc),a3
	moveq #4,d6
.copy:
	move.l (a3)+,(a2)+
	dbf d6,.copy
	dbf d7,.case
	movem.l (a7)+,d0-d7/a0-a3
	rts
_audio_test_inputs:
	dc.l 1,100,10
	dc.l 0,100,10
	dc.l 0,101,11
	dc.l 0,107,12
	dc.l 0,108,13
	dc.l 0,108,14
	dc.l 0,109,16
	dc.l 0,120,16
	dc.l 0,120,17
	dc.l 0,128,18
	dc.l 1,$fffffffc,$fffffffe
	dc.l 0,3,$ffffffff
	dc.l 0,4,0
	dc.l 0,4,1
	dc.l 0,4,2
	dc.l 0,4,4
	dc.l 0,65539,5
	dc.l 0,65539,5
	dc.l 0,65540,6
_audio_test_state: dcb.b AU_SIZE,0
_audio_math_signature: dc.b 'HDAUDMAT'
_audio_test_results: dcb.b 19*24,0
	ENDC
