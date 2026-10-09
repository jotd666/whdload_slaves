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
