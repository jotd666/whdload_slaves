; Development replay playback clock and pose interpolation. Add TIME_RECORD
; for fixed-field history generation; full gameplay acceptance remains open.
_replay_install:
	IFD VERIFY_REPLAY_AUDIO_MATH
	bsr _replay_audio_math_test
	ENDC
	IFD VERIFY_TIME_RECORD
	bsr _record_install
	ENDC
	IFD VERIFY_REPLAY_MATH
	bsr _replay_math_test
	bsr _replay_overlay_math_test
	ENDC
	movem.l a0-a2,-(a7)
	lea _replay_patches(pc),a0
	movea.l _code_start(pc),a1
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
	movem.l (a7)+,a0-a2
	rts
_replay_patches:
	PL_START
	; PERF_RANGE VERIFY_TIME_REPLAY_TIMING $10bb0 $0006: playback epoch
	PL_PS $10bb0,_replay_begin
	; PERF_RANGE VERIFY_TIME_REPLAY_TIMING $10bb6 $0008: interpolated playback pose
	PL_PSS $10bb6,_replay_pose,2
	; PERF_RANGE VERIFY_TIME_REPLAY_TIMING $10c18 $0012: skid requests by history record
	PL_PSS $10c18,_replay_sound_records,$c
	; PERF_RANGE VERIFY_TIME_REPLAY_TIMING $10e46 $0016: elapsed playback cursor
	PL_PSS $10e46,_replay_advance,$10
	; PERF_RANGE VERIFY_TIME_REPLAY_TIMING $10db4 $000a: timed effect pose and RNG1
	PL_PSS $10db4,_replay_effect_first,4
	; PERF_RANGE VERIFY_TIME_REPLAY_TIMING $10dc6 $0006: cached RNG2 for this phase
	PL_PS $10dc6,_replay_effect_second
	IFND VERIFY_DISPATCH_NATIVE
	; PERF_RANGE VERIFY_TIME_REPLAY_TIMING $10dd8 $002e: replace per-draw effect counter
	PL_PSS $10dd8,_replay_effect_counter,$28
	ENDC
	PL_END
_replay_signature: dc.b 'HDRPLAY1'
RP_WALL equ 0
RP_START equ 4
RP_AGE equ 8
RP_OLDEST equ 12
RP_COUNT equ 16
RP_PAUSED equ 18
RP_EFFECT_LAST equ 20
RP_EFFECT_TARGET equ 22
RP_RNG1 equ 24
RP_RNG2 equ 28
_replay_state: dcb.b 32,0
_replay_frame: dcb.b 158,0
; Separate publication keeps the playback state/scratch layout stable.
_replay_overlay_last: dc.l 0
_replay_audio_signature: dc.b 'HDRAUD01'
; Last consumed record.w, padding.w, number of historical skid requests.l.
_replay_audio_state: dc.w -1,0
	dc.l 0
_replay_overlay_reset:
	move.l a0,-(a7)
	lea _replay_overlay_last(pc),a0
	move.l _replay_state+RP_WALL(pc),(a0)
	movea.l (a7)+,a0
	rts
; D1 elapsed presentation fields, A0 scratch. Consume each interval once.
_replay_overlay_fields:
	lea _replay_overlay_last(pc),a0
	move.l _replay_state+RP_WALL(pc),d1
_replay_overlay_interval:
	move.l d2,-(a7)
	move.l d1,d2
	sub.l (a0),d1
	move.l d2,(a0)
	move.l (a7)+,d2
	IFD VERIFY_DISPATCH_NATIVE
	moveq #8,d1
	ELSE
	cmpi.l #65535,d1
	bls.s .bounded
	move.l #65535,d1
.bounded:
	ENDC
	rts
_replay_pause:
	move.l a0,-(a7)
	lea _replay_state(pc),a0
	st RP_PAUSED(a0)
	movea.l (a7)+,a0
	rts
_replay_resume:
	move.l a0,-(a7)
	lea _replay_state(pc),a0
	clr.b RP_PAUSED(a0)
	movea.l (a7)+,a0
	rts
_replay_begin:
	move.l a0,-(a7)
	lea _replay_audio_state(pc),a0
	move.w #-1,(a0)
	clr.l 4(a0)
	movea.l (a7)+,a0
	bsr _replay_overlay_reset
	movem.l d0/a0,-(a7)
	lea _replay_state(pc),a0
	move.l RP_WALL(a0),RP_START(a0)
	clr.l RP_AGE(a0)
	move.w #-1,RP_EFFECT_LAST(a0)
	move.l a3,RP_OLDEST(a0)
	move.w d6,RP_COUNT(a0)
	movea.l _code_start(pc),a0
	adda.l #$10e5c,a0
	move.l a0,8(a7)
	movem.l (a7)+,d0/a0
	moveq #0,d4
	rts
_replay_advance:
	movem.l d0-d1/a0,-(a7)
	lea _replay_state(pc),a0
	IFD VERIFY_DISPATCH_NATIVE
	addq.l #8,RP_AGE(a0)
	move.l RP_AGE(a0),d0
	ELSE
	move.l RP_WALL(a0),d0
	sub.l RP_START(a0),d0
	move.l d0,RP_AGE(a0)
	ENDC
	lsr.l #3,d0
	moveq #0,d1
	move.w RP_COUNT(a0),d1
	cmp.l d1,d0
	bls.s .bounded
	move.l d1,d0
.bounded:
	move.w d0,d4
	cmp.w RP_COUNT(a0),d4
	blo.s .return
	; Complete invisible tail events too, preserving the RNG sequence by duration.
	moveq #25,d0
	cmpi.w #26,RP_COUNT(a0)
	bge.s .target
	move.w RP_COUNT(a0),d0
	subq.w #1,d0
.target:
	move.w d0,RP_EFFECT_TARGET(a0)
	bsr _replay_rng_advance
	bsr _replay_sound_records
.return:
	movem.l (a7)+,d0-d1/a0
	rts
_replay_pose:
	movem.l d0-d7/a0-a2,-(a7)
	lea _replay_state(pc),a2
	movea.l RP_OLDEST(a2),a0
	moveq #0,d0
	move.w d4,d0
	mulu.w #158,d0
	adda.l d0,a0
	lea -$16e2(a4),a1
	cmpa.l a1,a0
	blo.s .left
	suba.l #14220,a0
.left:
	movea.l a0,a1
	move.w d4,d0
	addq.w #1,d0
	cmp.w RP_COUNT(a2),d0
	bge.s .right
	adda.w #158,a1
	lea -$16e2(a4),a2
	cmpa.l a2,a1
	blo.s .right
	suba.l #14220,a1
.right:
	move.l _replay_state+RP_AGE(pc),d2
	andi.w #7,d2
	lea _replay_frame(pc),a2
	bsr _replay_interpolate
	lea _replay_frame(pc),a3
	movem.l (a7)+,d0-d7/a0-a2
	; Native first two instructions; A3 deliberately points at the scratch pose.
	movea.l -$6686(a4),a0
	move.w 6(a3),d0
	rts

; Consume each recorded skid request once, including records crossed without
; drawing. Paula's existing per-channel busy gate still arbitrates actual starts.
; D4 may equal COUNT on final advance; clamp before reading the native ring.
_replay_sound_records:
	movem.l d0-d7/a0-a3,-(a7)
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,-(a7)
	lea _replay_audio_state(pc),a2
	move.w d4,d7
	move.w _replay_state+RP_COUNT(pc),d0
	subq.w #1,d0
	cmp.w d0,d7
	ble.s .next
	move.w d0,d7
.next:
	move.w (a2),d0
	cmp.w d7,d0
	bge.s .done
	addq.w #1,d0
	move.w d0,(a2)
	mulu.w #158,d0
	movea.l _replay_state+RP_OLDEST(pc),a0
	adda.l d0,a0
	lea -$16e2(a4),a1
	cmpa.l a1,a0
	blo.s .record
	suba.l #14220,a0
.record:
	btst #7,12(a0)
	beq.s .next
	addq.l #1,4(a2)
	move.w #4,-(a7)
	jsr -$7fce(a4)
	addq.w #2,a7
	; Preserve the native event handler's X when a request is made. The
	; bookkeeping loop must not replace it with its own arithmetic carry.
	moveq #0,d0
	roxl.b #1,d0
	move.w d0,(a7)
	bra.s .next
.done:
	move.w (a7)+,d0
	lsr.b #1,d0
	movem.l (a7)+,d0-d7/a0-a3
	rts

; Replay effect phase k0..25, independent of how often it is drawn.
_replay_effect_first:
	movem.l d0-d3/a0,-(a7)
	move.w d6,d0
	subi.w #26,d0
	bpl.s .threshold
	moveq #0,d0
.threshold:
	move.w d4,d1
	sub.w d0,d1
	lea _replay_state(pc),a0
	move.w d1,RP_EFFECT_TARGET(a0)
	moveq #0,d0
	move.w d1,d0
	divu.w #3,d0
	andi.l #$ffff,d0
	cmpi.w #5,d0
	ble.s .sprite
	moveq #10,d1
	sub.w d0,d1
	move.w d1,d0
.sprite:
	mulu.w #16,d0
	lea -$5160(a4),a0
	adda.l d0,a0
	move.l a0,-8(a5)
	bsr _replay_rng_advance
.cached:
	movem.l (a7)+,d0-d3/a0
	; Insert the native persistent PEA argument below this hook's return PC.
	move.l (a7),-(a7)
	move.l -8(a5),4(a7)
	move.l _replay_state+RP_RNG1(pc),d0
	moveq #13,d1
	rts
_replay_rng_advance:
	lea _replay_state(pc),a0
	move.w RP_EFFECT_LAST(a0),d0
	cmp.w RP_EFFECT_TARGET(a0),d0
	bge.s .done
	jsr -$7fc8(a4)
	lea _replay_state(pc),a0
	move.l d0,RP_RNG1(a0)
	jsr -$7fc8(a4)
	lea _replay_state(pc),a0
	move.l d0,RP_RNG2(a0)
	addq.w #1,RP_EFFECT_LAST(a0)
	bra.s _replay_rng_advance
.done:
	rts
_replay_effect_second:
	move.l _replay_state+RP_RNG2(pc),d0
	moveq #13,d1
	rts
_replay_effect_counter:
	rts

; A0 left record, A1 right, A2 output; D2 fraction0..8. Fixed native format:
; player X,Z,Y, yaw,pitch,roll, packed engine/flags; then12 traffic X,Y,Z/angles.
; Endpoint copies preserve every original bit, including angle representation.
_replay_interpolate:
	tst.w d2
	beq.s .copy_left
	cmpi.w #8,d2
	beq.s .copy_right
	bsr _replay_unsigned_word
	bsr _replay_unsigned_word
	bsr _replay_signed_word
	bsr _replay_angle_word
	bsr _replay_angle_word
	bsr _replay_angle_word
	move.w (a0)+,d4
	move.w (a1)+,d1
	move.w d4,d0
	andi.w #$fff,d0
	andi.w #$fff,d1
	bsr _replay_lerp_unsigned
	andi.w #$f000,d4
	or.w d4,d0
	move.w d0,(a2)+
	moveq #11,d5
.traffic:
	bsr _replay_unsigned_word
	bsr _replay_signed_word
	bsr _replay_unsigned_word
	bsr _replay_angle_word
	bsr _replay_angle_word
	bsr _replay_angle_word
	dbf d5,.traffic
	rts
.copy_right:
	movea.l a1,a0
.copy_left:
	moveq #78,d3
.copy:
	move.w (a0)+,(a2)+
	dbf d3,.copy
	rts
_replay_unsigned_word:
	move.w (a0)+,d0
	move.w (a1)+,d1
	bsr _replay_lerp_unsigned
	move.w d0,(a2)+
	rts
_replay_signed_word:
	move.w (a0)+,d0
	move.w (a1)+,d1
	bsr _replay_lerp_signed
	move.w d0,(a2)+
	rts
_replay_angle_word:
	move.w (a0)+,d0
	move.w (a1)+,d1
	move.w d1,d3
	sub.w d0,d3
	cmpi.w #720,d3
	ble.s .negative
	subi.w #1440,d1
	bra.s .lerp
.negative:
	cmpi.w #-720,d3
	bge.s .lerp
	addi.w #1440,d1
.lerp:
	bsr _replay_lerp_signed
	cmpi.w #720,d0
	ble.s .low
	subi.w #1440,d0
.low:
	cmpi.w #-720,d0
	bge.s .store
	addi.w #1440,d0
.store:
	move.w d0,(a2)+
	rts
; Weighted endpoints avoid overflowing a signed-word difference across extrema.
_replay_lerp_unsigned:
	moveq #8,d3
	sub.w d2,d3
	mulu.w d3,d0
	mulu.w d2,d1
	add.l d1,d0
	lsr.l #3,d0
	rts
_replay_lerp_signed:
	moveq #8,d3
	sub.w d2,d3
	muls.w d3,d0
	muls.w d2,d1
	add.l d1,d0
	asr.l #3,d0
	rts

	IFD VERIFY_REPLAY_MATH
; Private clock/countdown cases: no native overlay or game state is written.
_replay_overlay_math_test:
	movem.l d0-d7/a0-a2,-(a7)
	lea _replay_overlay_cases(pc),a1
	lea _replay_overlay_results(pc),a2
	moveq #8,d7
.case:
	lea _replay_overlay_test_clock(pc),a0
	move.l (a1)+,(a0)
	move.l (a1)+,d1
	bsr _replay_overlay_interval
	move.l d1,(a2)+
	move.l (a0),(a2)+
	lea _replay_overlay_test_count(pc),a0
	move.w #320,(a0)
	move.w #40,2(a0)
	moveq #40,d0
	bsr _presentation_countdown
	move.w d0,(a2)+
	move.w (a0),(a2)+
	; A second call at the same wall time must not consume time twice.
	lea _replay_overlay_test_clock(pc),a0
	move.l -4(a1),d1
	bsr _replay_overlay_interval
	move.l d1,(a2)+
	dbf d7,.case
	movem.l (a7)+,d0-d7/a0-a2
	rts
_replay_overlay_cases:
	dc.l 100,100,100,101,100,107,100,108,100,111
	dc.l 100,420,100,421,$fffffffc,3,100,70100
_replay_overlay_test_clock: dc.l 0
_replay_overlay_test_count: dc.l 0
_replay_overlay_math_signature: dc.b 'HDRPOM01'
_replay_overlay_results: dcb.b 9*16,0
_replay_math_test:
	movem.l d0-d7/a0-a2,-(a7)
	moveq #0,d6
	lea _replay_math_results(pc),a2
.fraction:
	lea _replay_math_left(pc),a0
	lea _replay_math_right(pc),a1
	move.w d6,d2
	bsr _replay_interpolate
	addq.w #1,d6
	cmpi.w #8,d6
	ble.s .fraction
	movem.l (a7)+,d0-d7/a0-a2
	rts
_replay_math_left:
	dc.w $ffff,$0000,$8000,$02cf,$fd31,$0000,$8fff,$0000
	dc.w $7fff,$0000,$02cf,$02cf,$02cf,$ffff,$8000,$1388
	dc.w $fd31,$fd31,$fd31,$0000,$7fff,$2710,$02d0,$02d0
	dc.w $02d0,$ffff,$8000,$3a98,$fd30,$fd30,$fd30,$0000
	dc.w $7fff,$4e20,$0000,$0000,$0000,$ffff,$8000,$61a8
	dc.w $02d0,$02d0,$02d0,$0000,$7fff,$7530,$0000,$0000
	dc.w $0000,$ffff,$8000,$88b8,$fd30,$fd30,$fd30,$0000
	dc.w $7fff,$9c40,$059f,$059f,$059f,$ffff,$8000,$afc8
	dc.w $0001,$0001,$0001,$0000,$7fff,$c350,$0064,$0064
	dc.w $0064,$ffff,$8000,$d6d8,$ff9c,$ff9c,$ff9c
_replay_math_right:
	dc.w $0000,$ffff,$7fff,$fd31,$02cf,$02d0,$0123,$ffff
	dc.w $8000,$ffff,$fd31,$fd31,$fd31,$0000,$7fff,$ec77
	dc.w $02cf,$02cf,$02cf,$ffff,$8000,$d8ef,$fd30,$fd30
	dc.w $fd30,$0000,$7fff,$c567,$02d0,$02d0,$02d0,$ffff
	dc.w $8000,$b1df,$02d0,$02d0,$02d0,$0000,$7fff,$9e57
	dc.w $0000,$0000,$0000,$ffff,$8000,$8acf,$fd30,$fd30
	dc.w $fd30,$0000,$7fff,$7747,$0000,$0000,$0000,$ffff
	dc.w $8000,$63bf,$0001,$0001,$0001,$0000,$7fff,$5037
	dc.w $059f,$059f,$059f,$ffff,$8000,$3caf,$ff9c,$ff9c
	dc.w $ff9c,$0000,$7fff,$2927,$0064,$0064,$0064
_replay_math_signature: dc.b 'HDRPMAT1'
_replay_math_results: dcb.b 9*158,0
	ENDC

	IFD VERIFY_TIME_RECORD
	INCLUDE "HardDrivinRecord.s"
	ENDC

	IFD VERIFY_REPLAY_AUDIO_MATH
	INCLUDE "HardDrivinReplayAudioVerify.s"
	ENDC
