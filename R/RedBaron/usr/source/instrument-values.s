; E2 gauge-value keys. No game hook yet; reusable by the persistent cockpit cache.
; These are ONLY dynamic value inputs, not complete raster-cache dependencies.
; Geometry, palette, bitmap resource lifetime and output-state replay belong to
; the caller. Keep raw values: no rounded-angle approximation is permitted.
;
; d0.w = gauge 0..6, a0 = h3 base, a1 = 12-byte destination in private fast RAM.
; d0 = 12 on success, 0 on unsupported gauge/missing required aircraft.
; Preserve all other registers. Failure leaves destination untouched.
; Sources are sim:19f62,1a034,1a106,1a1aa,1a262,1a2b2,1a330.
instrument_value_key:
 movem.l d1-d3/a0-a2,-(sp)
 cmpi.w #6,d0
 bhi .bad
 moveq #0,d1
 moveq #0,d2
 moveq #0,d3
 tst.w d0
 beq .altitude
 cmpi.w #1,d0
 beq .attitude
 cmpi.w #2,d0
 beq .speed
 cmpi.w #3,d0
 beq .heading
 cmpi.w #4,d0
 beq .needle4
 cmpi.w #5,d0
 beq .fuel
 move.w $71b8(a0),d1
 bra .write
.altitude
 move.l $4578(a0),a2
 cmpa.l #0,a2
 beq .bad
 move.l $10(a2),d1
 bra .write
.attitude
 move.w $71ae(a0),d1
 bra .write
.speed
 move.w $71b0(a0),d1
 bra .write
.heading
 move.w $71b2(a0),d1
 bra .write
.needle4
 move.w $71d4(a0),d1
 bra .write
.fuel
 move.w $71d2(a0),d2 ; native denominator, also numerator in unlimited mode
 move.l a0,a2
 adda.l #$8000,a2
 move.w $0d9e(a2),d3
 move.w d2,d1
 tst.w d3
 beq .write
 move.l $4578(a0),a2
 cmpa.l #0,a2
 beq .bad
 move.w $86(a2),d1
.write
 move.w d0,(a1)
 move.w d3,2(a1)
 move.l d1,4(a1)
 move.l d2,8(a1)
 moveq #12,d0
 bra .done
.bad
 moveq #0,d0
.done
 movem.l (sp)+,d1-d3/a0-a2
 rts
