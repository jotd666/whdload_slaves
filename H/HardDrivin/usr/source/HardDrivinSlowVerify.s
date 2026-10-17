; Developer instrument, SPS 0126 only: -DVERIFY_SLOW=1, CUSTOM4=N.
; May be combined with VERIFY_DRIVE or VERIFY_ATTRACT, or used manually.
; Zero installs neither hook. Nonzero values saturate at 255 extra PAL VBLs
; per frame submission. Not a user-facing option or a performance patch.
;
; Delay AFTER $00740 consumes the preceding ready frame, BEFORE $00756 marks
; this frame ready. The native handshake is unchanged; the VBL, clocks and
; input tape continue throughout the wait. All users of $00750 are delayed,
; including menus, attract, gameplay and replay. Do not reinterpret the
; unchanged VERIFY_DRIVE tape as a guaranteed route at the slower frame rate.
; VERIFY_GHOST_POST_SLOW restricts this instrument to the post-race epoch.
; VERIFY_REPLAY_SLOW restricts it to the instant-replay request/playback epoch.
; VERIFY_GAMEPLAY_SLOW restricts it to the active gameplay clock.
;
; At entry A0 is game base, D0 is code length, after normal patch installation.
; The caller flushes caches after the final executable writes as usual.
_verify_slow_install:
	cmpi.l #$11a4e,d0	; other releases have different code layouts
	bne.s .done
	movem.l d0-d1/a0-a2,-(a7)
	move.l _ct_ct4(pc),d0
	beq.s .restore
	cmpi.l #255,d0
	bls.s .bounded
	move.l #255,d0
.bounded:
	subq.w #1,d0
	lea _verify_slow_count(pc),a1
	move.w d0,(a1)		; DBF trip count = requested VBLs - 1
	movea.l a0,a1
	lea _verify_slow_patches(pc),a0
	movea.l _resload(pc),a2
	jsr resload_Patch(a2)
.restore:
	movem.l (a7)+,d0-d1/a0-a2
.done:
	rts

_verify_slow_patches:
	PL_START
	; PERF_RANGE VERIFY_SLOW $003e2 $0006: independent VBL counter
	PL_PS $3e2,_verify_slow_vbl
	; PERF_RANGE VERIFY_SLOW $00756 $0006: delay then native ready store
	PL_PS $756,_verify_slow_submit
	PL_END

_verify_slow_vbl:
	move.l a2,-(a7)
	lea _verify_slow_fields(pc),a2
	addq.l #1,(a2)
	movea.l (a7)+,a2
	move.l (a0)+,(a1)+	; three displaced palette writes
	move.l (a0)+,(a1)+
	move.l (a0)+,(a1)+
	rts

_verify_slow_submit:
	movem.l d0-d1,-(a7)
	IFD VERIFY_GAMEPLAY_SLOW
	move.b _time_state+TS_ACTIVE(pc),d0
	beq.s _verify_slow_publish
	ENDC
	IFD VERIFY_REPLAY_SLOW
	tst.b -$5229(a4)
	beq.s _verify_slow_publish
	ENDC
	IFD VERIFY_GHOST_POST_SLOW
	move.b _ghost_post_state+PG_ACTIVE(pc),d0
	beq.s _verify_slow_publish
	ENDC
	move.w _verify_slow_count(pc),d0
_verify_slow_next:
	move.l _verify_slow_fields(pc),d1
_verify_slow_poll:
	cmp.l _verify_slow_fields(pc),d1
	beq.s _verify_slow_poll
	dbf d0,_verify_slow_next
_verify_slow_publish:
	movem.l (a7)+,d0-d1
	move.b #$ff,-$69ff(a4)	; displaced ready store, including CCR
	rts

	; CMP/DBF polling preserves X; the final MOVE sets native NZVC.
	; Equality polling also handles the 32-bit VBL counter wrapping to zero.
	; The counter is independent of the input tape's title/race epochs.
_verify_slow_fields: dc.l 0
_verify_slow_count: dc.w 0
