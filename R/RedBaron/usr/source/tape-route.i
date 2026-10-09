; Menu route for the prepared RedBaron_v2.1 archive, v1 executables.
; Delay units are native keyboard polls, not wall time or PAL fields.
; The first Return skips the opening sequence / scrolling credits.
 REPT 4
 dc.w 100,RAW_RETURN
 ENDR
 ; Ace list -> Select.
 REPT 4
 dc.w 100,RAW_TAB
 ENDR
 dc.w 100,RAW_RETURN
 ; Mission setup -> Begin. The simulation handles the tape prompt separately.
 dc.w 100,RAW_TAB,100,RAW_RETURN
 dc.w 0

; VERIFY CUSTOM5 bit 2: four-versus-four squadron, British side.
; Keep the ace and dense routes in the same binary for controlled comparisons.
tape_dense:
 dc.w 100,RAW_RETURN,100,RAW_TAB,100,RAW_RETURN
 ; Fly Single Mission: third Tab selects Dogfight a Squadron.
 REPT 3
 dc.w 100,RAW_TAB
 ENDR
 dc.w 100,RAW_RETURN,100,RAW_TAB,100,RAW_RETURN
 ; Leave all eleven mission settings unchanged; select ACCEPT.
 REPT 12
 dc.w 100,RAW_TAB
 ENDR
 dc.w 100,RAW_RETURN
 ; Briefing starts without keyboard focus: third Tab selects Begin Mission.
 dc.w 100,RAW_TAB,100,RAW_TAB,100,RAW_TAB,100,RAW_RETURN
 dc.w 0
