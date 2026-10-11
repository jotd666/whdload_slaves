; E2 solid-program coverage helper, not installed by the live cache yet.
; a0=private script prepared with every colour pair replaced by (1,1)
; a1=private 8000-byte MEMF_CHIP mask; a2=native program interpreter
; a4=h3+$8000; d7.w=program index. Caller has validated 320x200/40/5 geometry,
; the program bound and solid-only commands. No bitmap/resource commands allowed.
; d0=1 success / 0 unsupported polygon mode. Other registers preserved.
; Native polygon/line clipping supplies exact coverage; no edge approximation.
overlay_native_mask:
 link a6,#-48
 movem.l d1-d7/a0-a5,-(sp)
 tst.b -$4b0(a4) ; h3:7b50 alternate polygon path has extra side effects
 bne .unsupported
 bsr .wait
 move.l a1,a3
 move.w #1999,d0
.clear
 clr.l (a3)+
 dbf d0,.clear
 ; Save the program slot and all drawing context changed by this helper.
 moveq #0,d0
 move.w d7,d0
 lsl.l #2,d0
 lea -$4ae(a4),a3
 adda.l d0,a3
 move.l a3,-4(a6)
 move.l (a3),-8(a6)
 move.l a0,(a3)
 move.l $1d72(a4),-12(a6)
 move.l a1,$1d72(a4)
 move.w $1d3c(a4),-14(a6)
 move.w #1,$1d3c(a4)
 ; Save aligned surrounding bytes; the selectors and row-zero map are odd.
 move.l -$4542(a4),-18(a6) ; h3:3abe .. 3ac1
 move.l -$6fe4(a4),-22(a6) ; h3:101c .. 101f
 move.l -$6fe0(a4),-26(a6) ; h3:1020 .. 1023
 clr.b -$4541(a4)
 clr.b -$4540(a4)
 move.b #1,-$6fe3(a4)
 move.b #1,-$6fe2(a4)
 move.b #1,-$6fe1(a4)
 move.b #1,-$6fe0(a4)
 move.w -$3e9c(a4),-28(a6) ; native pen
 move.l $1d50(a4),-32(a6) ; background and foreground
 move.w $1d54(a4),-34(a6) ; filled mode
 ; The native interpreter takes a word argument plus padding and preserves A6.
 ; A4 is not in its ABI save mask, so retain the h3 base explicitly.
 move.l a4,-40(a6)
 subq.l #2,sp
 move.w d7,-(sp)
 jsr (a2)
 addq.l #4,sp
 move.l -40(a6),a4
 bsr .wait
 move.l -4(a6),a3
 move.l -8(a6),(a3)
 move.l -12(a6),$1d72(a4)
 move.w -14(a6),$1d3c(a4)
 move.l -18(a6),-$4542(a4)
 move.l -22(a6),-$6fe4(a4)
 move.l -26(a6),-$6fe0(a4)
 move.w -28(a6),-$3e9c(a4)
 move.l -32(a6),$1d50(a4)
 move.w -34(a6),$1d54(a4)
 moveq #1,d0
 bra .done
.unsupported
 moveq #0,d0
.done
 movem.l (sp)+,d1-d7/a0-a5
 unlk a6
 rts
.wait
 tst.w $dff002
.busy
 btst #6,$dff002
 bne .busy
 rts

; Prepare the private solid-only script, preserving exact coordinate arrays.
; a0=bounded source, a1=512-byte output. d0=written bytes, or zero on fallback.
; Other registers preserved. Reject before reading operands beyond 512 bytes.
overlay_mask_script_prepare:
 movem.l d1-d3/a0-a3,-(sp)
 move.l a0,a2
 adda.l #512,a2
 move.l a1,a3
 moveq #0,d3
.next
 cmpa.l a2,a0
 bhs .fail
 move.w (a0)+,d0
 move.w d0,(a1)+
 cmpi.w #$0ff0,d0
 beq .success
 cmpi.w #$2002,d0
 beq .colour
 tst.w d3
 beq .fail
 cmpi.w #$af2f,d0
 beq .polygon
 cmpi.w #$a104,d0
 beq .geometry
 cmpi.w #$a0a4,d0
 bne .fail
.geometry
 moveq #8,d1
 bra .copy_bound
.polygon
 cmpa.l a2,a0
 bhs .fail
 moveq #0,d1
 move.w (a0),d1
 cmpi.w #3,d1
 blo .fail
 cmpi.w #64,d1
 bhi .fail
 lsl.w #2,d1
 addq.w #2,d1 ; count word plus separate x/y arrays
.copy_bound
 move.l a0,d2
 add.l d1,d2
 cmp.l a2,d2
 bhi .fail
 lsr.w #1,d1
 subq.w #1,d1
.copy
 move.w (a0)+,(a1)+
 dbf d1,.copy
 bra .next
.colour
 move.l a0,d2
 addq.l #4,d2
 cmp.l a2,d2
 bhi .fail
 move.w (a0)+,d1
 cmp.w (a0)+,d1
 bne .fail
 move.l #$00010001,(a1)+
 moveq #1,d3
 bra .next
.success
 move.l a1,d0
 sub.l a3,d0
 bra .done
.fail
 moveq #0,d0
.done
 movem.l (sp)+,d1-d3/a0-a3
 rts
