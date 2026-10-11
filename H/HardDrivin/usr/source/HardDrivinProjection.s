; Fractional extension of native longitudinal velocity projection. The game
; retains its original integer projection/rounding. Only the signed eighth-unit
; velocity companion is projected here, preserving native T=1 with zero carry.
_projection_signature: dc.b 'HDVPROJ1'
; Current XYZ Q16 corrections, previous XYZ, then Q16 position carries.
_projection_state: dcb.l 9,0
_projection_reset:
	move.l a0,-(a7)
	lea _projection_state(pc),a0
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	clr.l (a0)+
	movea.l (a7)+,a0
	rts
_projection_snapshot:
	move.l a0,-(a7)
	lea _projection_state(pc),a0
	move.l (a0),12(a0)
	move.l 4(a0),16(a0)
	move.l 8(a0),20(a0)
	movea.l (a7)+,a0
	rts
_projection_update:
	movem.l d0-d1/a0,-(a7)
	; Native skidding holds the last projected vector instead of recomputing it.
	tst.b -$50cf(a4)
	bne.s .done
	lea _time_scalar_state(pc),a0
	moveq #0,d0
	move.w -$66d8(a4),d1
	cmp.w SS_VELOCITY_LAST(a0),d1
	bne.s .project
	move.w SS_VELOCITY_CARRY(a0),d0
.project:
	lea _projection_state(pc),a0
	bsr _projection_components
.done:
	movem.l (a7)+,d0-d1/a0
	rts
; D0.W eighth-velocity carry [-7,7], A0 -> XYZ Q16, native Q14 trig globals.
; Factor 3/2 maps velocity to long-position units, hence carry*3*65536/16.
_projection_components:
	movem.l d1-d4,-(a7)
	muls.w #12288,d0
	move.l d0,d4
	move.w -$6bb4(a4),d1
	bsr _contact_project_q16
	move.l d0,4(a0)
	move.l d4,d0
	move.w -$6bb2(a4),d1
	bsr _contact_project_q16
	move.l d0,d4
	move.w -$6bb8(a4),d1
	bsr _contact_project_q16
	move.l d0,(a0)
	move.l d4,d0
	move.w -$6bb6(a4),d1
	bsr _contact_project_q16
	move.l d0,8(a0)
	movem.l (a7)+,d1-d4
	rts
_projection_integrate:
	movem.l d0-d5/a0-a1,-(a7)
	lea _projection_state(pc),a0
	lea -$6704(a4),a1
	move.w _time_scalar_fields(pc),d2
	moveq #2,d5
.axis:
	move.l (a0),d0
	move.l 12(a0),d1
	move.l 24(a0),d3
	bsr _projection_delta
	move.l d3,24(a0)
	add.l d0,(a1)+
	addq.l #4,a0
	dbf d5,.axis
	movem.l (a7)+,d0-d5/a0-a1
	rts
; Same Euler correction as integer position, but for the projected fractional
; extension. D0.L current Q16, D1.L previous Q16 (each abs<=86016), D2.W fields,
; D3.L signed Q16 position carry. Returns integer D0 and Q16 carry D3.
; The /16 rounds down at Q16 precision (<1/65536 long-position unit per call).
_projection_delta:
	movem.l d1-d2/d4-d5,-(a7)
	tst.w d2
	beq.s .zero
	moveq #8,d4
	add.w d2,d4
	bsr _projection_product
	move.l d0,-(a7)
	move.l d1,d0
	moveq #8,d4
	sub.w d2,d4
	bsr _projection_product
	move.l d0,d1
	move.l (a7)+,d0
	sub.l d1,d0
	asr.l #4,d0
	add.l d3,d0
	bsr _time_split_q16
	move.l d2,d3
	bra.s .done
.zero:
	moveq #0,d0
.done:
	movem.l (a7)+,d1-d2/d4-d5
	rts
; Signed long D0 times small unsigned word D4, exact within stated bounds.
_projection_product:
	move.l d0,d5
	swap d5
	muls.w d4,d5
	swap d5
	clr.w d5
	mulu.w d4,d0
	add.l d5,d0
	rts

	IFD VERIFY_PROJECTION_MATH
_projection_math_test:
	movem.l d0-d7/a0-a6,-(a7)
	lea _projection_fake(pc),a4
	adda.l #$6bb8,a4
	lea _projection_component_results(pc),a2
	moveq #-7,d7
.carry:
	lea _projection_trigs(pc),a3
	moveq #3,d6
.trig:
	move.w (a3)+,-$6bb8(a4)
	move.w (a3)+,-$6bb6(a4)
	move.w (a3)+,-$6bb4(a4)
	move.w (a3)+,-$6bb2(a4)
	move.w d7,d0
	lea _projection_state(pc),a0
	bsr _projection_components
	move.l (a0),(a2)+
	move.l 4(a0),(a2)+
	move.l 8(a0),(a2)+
	dbf d6,.trig
	addq.w #1,d7
	cmpi.w #7,d7
	ble.s .carry
	lea _projection_values(pc),a6
	lea _projection_delta_results(pc),a2
	moveq #6,d7
.new:
	move.l (a6)+,d6
	lea _projection_values(pc),a3
	moveq #6,d4
.old:
	move.l (a3)+,d1
	moveq #0,d2
.fields:
	lea _projection_carries(pc),a1
	moveq #2,d5
.fraction:
	move.l d6,d0
	move.l (a1)+,d3
	bsr _projection_delta
	move.l d0,(a2)+
	move.l d3,(a2)+
	dbf d5,.fraction
	addq.w #1,d2
	cmpi.w #8,d2
	ble.s .fields
	dbf d4,.old
	dbf d7,.new
	bsr _projection_reset
	movem.l (a7)+,d0-d7/a0-a6
	rts
_projection_fake: dcb.b 8,0
_projection_trigs:
	dc.w 0,16384,0,16384
	dc.w 11585,11585,8192,14189
	dc.w -11585,11585,-8192,14189
	dc.w 16384,0,16384,0
_projection_values: dc.l -86016,-65535,-1,0,1,65535,86016
_projection_carries: dc.l -65535,0,65535
_projection_component_signature: dc.b 'HDVPCMP1'
_projection_component_results: dcb.b 15*4*12,0
_projection_delta_signature: dc.b 'HDVPDEL1'
_projection_delta_results: dcb.b 7*7*9*3*8,0
	ENDC
