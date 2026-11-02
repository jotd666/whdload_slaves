; A4000 chase camera. Keep geometry/target selection native; normalize motion
; to A2500 speed without interpolating or delaying the current vehicle state.
; Two records: X fraction,Z fraction,reserved[2], each fraction0..4.
sim_camera_prepare:
 lea sim_camera_prepare(pc),a0
 adda.l #sim_game-sim_camera_prepare,a0
 movea.l (a0),a2
 lea $7e9c(a2),a0
 lea sim_camera_native_vertical(pc),a1
 moveq #30/2-1,d0
.vertical:
 move.w (a0)+,(a1)+
 dbra d0,.vertical
 lea $7f6e(a2),a0
 lea sim_camera_native_horizontal(pc),a1
 moveq #38/2-1,d0
.horizontal:
 move.w (a0)+,(a1)+
 dbra d0,.horizontal
 rts

; $7E9C..$7EBA. Signed vertical correction already in -4(A5).
sim_camera_vertical:
 cmp.w #50,-$15fa(a4)
 bne sim_camera_native_vertical
 cmp.w #12,-4(a5)
 ble .negative
 move.w #12,-4(a5)
 rts
.negative:
 cmp.w #-12,-4(a5)
 bge .done
 move.w #-12,-4(a5)
.done:
 rts
sim_camera_native_vertical:
 dcb.b 30,0
 rts

; $7F6E..$7F94. Native code has already subtracted the450-unit dead zone.
; Near corrections finish immediately; far corrections project radius120,
; then emit2/5 of the native Q14 component with a per-axis remainder.
sim_camera_horizontal:
 cmp.w #50,-$15fa(a4)
 bne sim_camera_native_horizontal
 cmp.w #48,-4(a5)
 ble .near
 move.w #120,-4(a5)
 rts
.near:
 movem.l d0/a0,-(sp)
 move.w -2(a5),d0
 mulu #4,d0               ; MULU leaves X unchanged, as does native clamp
 lea sim_camera_state(pc),a0
 adda.l d0,a0
 clr.w (a0)               ; discard both dormant axis remainders at target
 movem.l (sp)+,d0/a0
 rts
sim_camera_native_horizontal:
 dcb.b 38,0
 rts

; $7FA0/$7FD0: native radius load and Q14 multiply. Preserve D1 and all
; extra scratch registers. Native caller stores D0.w then defines flags.
sim_camera_x:
 movem.l d1-d2/a0-a1,-(sp)
 moveq #0,d2
 bra.s sim_camera_project
sim_camera_z:
 movem.l d1-d2/a0-a1,-(sp)
 moveq #1,d2
sim_camera_project:
 move.w -4(a5),d0
 jsr -$7ba8(a4)
 cmp.w #50,-$15fa(a4)
 bne .done
 cmp.w #120,-4(a5)
 bne .done                ; unsaturated near correction uses native result
 move.w -2(a5),d1
 mulu #4,d1
 lea sim_camera_state(pc),a0
 adda.l d1,a0
 adda.w d2,a0
 ; Helper uses floor division, preserving exact signed Q14 rounding bias.
 lea sim_camera_project(pc),a1
 adda.l #sim_aux_component_50-sim_camera_project,a1
 jsr (a1)
.done:
 movem.l (sp)+,d1-d2/a0-a1
 rts

 even
 dc.b "4DCAM050"
 dc.w 1,SIM_CAMERA_BYTES
sim_camera_state: dcb.b SIM_CAMERA_BYTES,0
 dc.b "CAMG"
