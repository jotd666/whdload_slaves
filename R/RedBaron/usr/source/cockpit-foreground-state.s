; Foreground layer state replay for native front programs 2/3/4.
OC_DESC = (OVERLAY_KEY_BYTES+3)&-4
OC_STATE = OC_DESC+12
OC_PIXELS = OC_STATE+24
OC_ENTRY = OC_PIXELS+4

; Called by the shared resource-lifetime hook with CCR saved.
overlay_cache_invalidate:
 move.l a0,-(sp)
 lea cockpit_foreground_layer(pc),a0
 clr.l (a0)+
 clr.l (a0)
 move.l overlay_solid_entry(pc),a0
 cmpa.l #0,a0
 beq .done
 clr.w (a0)
.done
 move.l (sp)+,a0
 rts

overlay_cache_original_program:
 movem.l d0-a6,-(sp)
 moveq #2,d7
overlay_cache_program_loop:
 movem.l d7/a4-a5,-(sp)
 subq.l #2,sp
 move.w d7,-(sp)
overlay_cache_native:
 jsr $0.l
 addq.l #4,sp
 movem.l (sp)+,d7/a4-a5
 addq.w #1,d7
 cmpi.w #5,d7
 blo overlay_cache_program_loop
 movem.l (sp)+,d0-a6
 rts

; Capture output values, replay only fields written by this program's commands.
overlay_cache_save_state:
 lea OC_STATE(a5),a0
overlay_cache_read_state:
 move.w -$3e9c(a4),(a0)+ ; h3:4164 pen
 move.l $1d50(a4),(a0)+ ; background, foreground
 move.w -$3de(a4),(a0)+ ; h3:7c22 image set
 move.l -$3dc(a4),(a0)+ ; table
 move.l -$3d4(a4),(a0)+ ; alternate table
 move.l -$3d8(a4),(a0)+ ; image descriptor
 move.w -$3e4(a4),(a0)+ ; bitmap mode
 move.w $1d54(a4),(a0)+ ; filled rectangle mode
 rts

overlay_cache_restore_state:
 lea OC_STATE(a5),a0
 move.w OVERLAY_KEY_EFFECTS(a5),d0
 btst #0,d0
 beq .set
 move.w (a0),-$3e9c(a4)
 move.l 2(a0),$1d50(a4)
.set
 btst #1,d0
 beq .image
 move.w 6(a0),-$3de(a4)
 move.l 8(a0),-$3dc(a4)
 move.l 12(a0),-$3d4(a4)
.image
 btst #2,d0
 beq .bitmap
 move.l 16(a0),-$3d8(a4)
.bitmap
 btst #3,d0
 beq .rectangle
 move.w 20(a0),-$3e4(a4)
.rectangle
 btst #4,d0
 beq .done
 move.w 22(a0),$1d54(a4)
.done
 rts

overlay_cache_h3: dc.l 0
 IFD VERIFY
overlay_cache_stats: dc.l 0,0,0 ; hits, fills, fallbacks
 ENDC
