; Motorola MC68881/82 FPU emulation code for 68040
;
; adapted from RTEM by JOTD in january 2021
;
; built with vasm
; vasmm68k_mot -maxerrors=0 -devpac -nosym -Fhunkexe -o fpsp code.s
;
; note: this creates an executable (could not embed it into whdload slave
; because of the many code relocations), but if you run it it will quit
; and free the memory. The startup code should wait indefinitely instead
; and be started with "run" so it remains in background.
; it's also started in supervisor state to be able to read VBR without amigaos syscalls
;
; but with a few changes this could be used to fix FPU calls on standard
; programs, like oxypatcher or others (except that this version allows
; to make TFX work, when oxypatcher fails)
;
; currently, the calling program uses LoadSeg on it, and calls it. Then
; it does NOT call UnloadSeg so the resident part remains in memory
;
; this is dirty but does exactly what we want in the case of whdload
; with a custom kickemu slave
;
; note: whdload flags need to have Private7 tag set (write to VBR without exception)
; and whdload 18.7+. Emul_LineF worked most of the time but there are other vectors
; and sometimes an underflow occurs that must be handled
;
; the startup code has been manually (and freely in a sense of 
; artistic freedom :)) converted from C to asm by JOTD

    opt a+
    MC68040
_entry:

; 
; Attach floating point exception vectors to M68040FPSP entry points
; 
    lea M68040FPSPUserExceptionHandlers(pc),a1
    lea handler_table(pc),a0
    movec   vbr,d3
.loop
    move.l  (a0)+,d0
    beq.b   .out
    move.l  (a0)+,d1
    add.l   d0,d0
    add.l   d0,d0
    move.l  d0,d2
    add.l   d3,d0
    move.l  d0,a2   ; a2 points to VBR vector to be saved/modified
    bsr     vectorconvert   ; "compress" save table to 8 vectors only
    move.l  (a2),(a1,d2.l)    ; save previous vector in table
    move.l  d1,(a2)             ; now store new hander in system vector table   
    bra.b   .loop
.out
    rts
    
; there are 9 useful vectors, pack the 64-vector table to only 9
; (only the LineF vector is effective on exception, but maybe that
; other vectors are called directly by the FPSP routine)

vectorconvert:
    cmp.l   #48,d0
    bcs.b   .lower
    sub.l   #47,d0
    add.l   d0,d0
    add.l   d0,d0
    rts
.lower:
    moveq.l #0,d0
    rts

    ; include the big fp emulation code by Motorola
    include fp040.s


handler_table:
    dc.l 11,  _fpspEntry_fline
    dc.l 48,  _fpspEntry_bsun
    dc.l 49,  _fpspEntry_inex
    dc.l 50,  _fpspEntry_dz
    dc.l 51,  _fpspEntry_unfl
    dc.l 52,  _fpspEntry_operr
    dc.l 53,  _fpspEntry_ovfl
    dc.l 54,  _fpspEntry_snan
    dc.l 55,  _fpspEntry_unsupp
    dc.l  0
    
    ; reduced that table from 100 values to 16 since only 9 are used.
M68040FPSPUserExceptionHandlers
    ds.l    $10
    

    