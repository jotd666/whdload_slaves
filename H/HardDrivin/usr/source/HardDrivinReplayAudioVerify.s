; Private ring and private audio vector. No live history, game globals or Paula
; registers are used. Both real playback companions are saved and restored.
_replay_audio_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _replay_state(pc),a0
	moveq #7,d0
.save:
	move.l (a0)+,-(a7)
	dbf d0,.save
	move.l _replay_audio_state(pc),-(a7)
	move.l _replay_audio_state+4(pc),-(a7)
	lea _replay_audio_private_vector(pc),a0
	lea _replay_audio_private_event(pc),a1
	move.l a1,2(a0)
	movea.l _resload(pc),a2
	jsr resload_FlushCache(a2)
	lea _replay_audio_private_end(pc),a4
	adda.l #$16e2,a4
	lea _replay_audio_test_output(pc),a6
	moveq #0,d6
.case:
	lea _replay_audio_state(pc),a0
	move.w #-1,(a0)
	clr.l 4(a0)
	lea _replay_state(pc),a0
	lea -$4e6e(a4),a1
	adda.l #79*158,a1
	move.l a1,RP_OLDEST(a0)
	move.w #90,RP_COUNT(a0)
	cmpi.w #1,d6
	bne.s .nonshort
	move.w #4,RP_COUNT(a0)
.nonshort:
	cmpi.w #2,d6
	bne.s .nonempty
	clr.w RP_COUNT(a0)
.nonempty:
	lea _replay_audio_case_events(pc),a0
	clr.w (a0)
	move.l a6,2(a0)
	; Reserve 30 events (index,id), initialized with a recognizable sentinel.
	moveq #29,d0
.clear:
	move.l #$deadbeef,(a6)+
	dbf d0,.clear
	cmpi.w #3,d6
	beq.s .native
	lea _replay_audio_test_visits(pc),a3
	moveq #9,d5
.visits:
	move.w (a3)+,d4
	bsr _replay_sound_records
	dbf d5,.visits
	bra.s .result
.native:
	moveq #0,d4
.native_loop:
	bsr _replay_sound_records
	addq.w #1,d4
	cmpi.w #91,d4
	blo.s .native_loop
.result:
	move.w _replay_audio_case_events(pc),(a6)+
	move.w _replay_audio_state(pc),(a6)+
	move.l _replay_audio_state+4(pc),(a6)+
	addq.w #1,d6
	cmpi.w #4,d6
	blo .case
	lea _replay_audio_state(pc),a0
	move.l (a7)+,4(a0)
	move.l (a7)+,(a0)
	lea _replay_state+32(pc),a0
	moveq #7,d0
.restore:
	move.l (a7)+,-(a0)
	dbf d0,.restore
	movem.l (a7)+,d0-d7/a0-a6
	rts
_replay_audio_private_event:
	movem.l d0/a0-a1,-(a7)
	lea _replay_audio_case_events(pc),a0
	addq.w #1,(a0)
	movea.l 2(a0),a1
	move.w _replay_audio_state(pc),(a1)+
	move.w 16(a7),(a1)+
	move.l a1,2(a0)
	movem.l (a7)+,d0/a0-a1
	rts
_replay_audio_test_visits: dc.w 0,0,1,7,7,12,35,88,90,90
_replay_audio_case_events: dc.w 0
	dc.l 0
_replay_audio_math_signature: dc.b 'HDRASND1'
_replay_audio_test_output: dcb.b 4*128,0
; A4-$7fce is the event vector; A4-$4e6e starts the 90-record ring.
_replay_audio_private_vector: dc.w $4ef9
	dc.l 0
	dcb.b $7fce-$4e6e-6,0
_replay_audio_private_ring:
	REPT 30
	dcb.b 12,0
	dc.w $8000
	dcb.b 144,0
	dcb.b 158*2,0
	ENDR
_replay_audio_private_end:
