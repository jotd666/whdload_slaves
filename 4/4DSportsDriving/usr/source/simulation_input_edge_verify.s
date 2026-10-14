; Ordinary input.device transitions for field-to-display latency acceptance.
; No native history, car state or scheduler queue is written by this driver.
; Optional SIM_INPUT_EDGE_STEERING exercises Left/Right while Up stays held;
; otherwise retain the original release/press Up sequence.
; Starting after step 200 with 40-field gaps avoids the 100-field profile
; joins when the acceptance capture starts at step 160.
 IFND SIM_LIVE_DRIVE
 FAIL "SIM_INPUT_EDGE_TEST requires SIM_LIVE_DRIVE"
 ENDC

tape_input_edge_test:
 move.w #499,d7
.wait_start:
 move.l tape_a4(pc),a0
 cmp.w #200,-$940(a0)
 bhs .ready
 bsr tape_edge_field
 dbra d7,.wait_start
 lea tape_edge_phase(pc),a0
 move.w #$ffff,(a0)         ; bounded failure, inspected by the acceptance tool
 rts
.ready:
 moveq #0,d7
 lea tape_edge_records(pc),a3
tape_edge_next:
 IFD SIM_INPUT_EDGE_STEERING
 move.w d7,d0
 add.w d0,d0
 lea tape_edge_steering_keys(pc),a0
 move.w (a0,d0.w),d3
 ELSE
 move.w #$cc,d3            ; release cursor Up
 btst #0,d7
 beq .key
 move.w #$4c,d3            ; press cursor Up
.key:
 ENDC
 lea tape_event(pc),a0
 move.b #IECLASS_RAWKEY,ie_Class(a0)
 move.w d3,ie_Code(a0)
 clr.w ie_Qualifier(a0)
 lea tape_io(pc),a1
 move.w #IND_WRITEEVENT,IO_COMMAND(a1)
 move.l a0,IO_DATA(a1)
 move.l #ie_SIZEOF,IO_LENGTH(a1)
 lea tape_input_edge_test(pc),a0
 adda.l #sim_clock_fields-tape_input_edge_test,a0
 move.l (a0),(a3)
 ; Global labels are stable observation sites in the saved listing.
tape_edge_send:
 jsr _LVODoIO(a6)
tape_edge_return:
 lea tape_input_edge_test(pc),a0
 adda.l #sim_clock_fields-tape_input_edge_test,a0
 move.l (a0),4(a3)
 move.w d3,8(a3)
 lea tape_io(pc),a0
 moveq #0,d0
 move.b IO_ERROR(a0),d0
 move.w d0,10(a3)
 move.l tape_a4(pc),a0
 move.w -$940(a0),12(a3)
 move.w d7,14(a3)
 addq.w #1,d7
 lea tape_edge_phase(pc),a0
 move.w d7,(a0)
 adda.w #16,a3
 cmp.w #4,d7
 beq .done
 moveq #39,d2
.wait:
 bsr tape_edge_field
 dbra d2,.wait
 bra tape_edge_next
.done:
 rts
tape_edge_field:
 exg a5,a6
 jsr _LVOWaitTOF(a6)
 exg a5,a6
 rts
 even
 dc.b "4DEDGET!"
 dc.w 1,16
tape_edge_phase: dc.w 0
 dc.w 0
tape_edge_records: dcb.b 64,0

 IFD SIM_INPUT_EDGE_STEERING
; Keep ordinary cursor Up held. Original $37190/$371A4 maps Left to bit3,
; Right to bit2: sampled bytes must be9,1,5,1 for these four transitions.
tape_edge_steering_keys: dc.w $4f,$cf,$4e,$ce
 ENDC
