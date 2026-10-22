; Fast RAM copy of the native $b1994..$b1ab7 raster-edge helper.
; The mutable edge table pointer remains at native $b1950.
; Omit redundant D0/D2 clears before full word/swap/word assignment, and
; ANDs into freshly zeroed D4/D6. Other arithmetic and branch tests are native.
; Labels identify the corresponding native instructions.
raster_edge_fast:
edge_b1994:
 move.l a0,-(a7)
edge_b1996:
 movea.l $b1950,a0
public_ref_18 equ *-4
edge_b199a:
 movem.l d1/d3,-(a7)
edge_b199e:
 move.l d4,d1
edge_b19a0:
 move.l d6,d3
edge_b19a2:
edge_b19a4:
edge_b19a6:
 moveq #$0,d4
edge_b19a8:
 moveq #$0,d6
edge_b19aa:
 move.w -$4(a0),d0
edge_b19ae:
 swap d0
edge_b19b0:
 move.w -$4(a0),d0
edge_b19b4:
 and.l d1,d0
edge_b19b6:
 move.w -$2(a0),d2
edge_b19ba:
 swap d2
edge_b19bc:
 move.w -$2(a0),d2
edge_b19c0:
 and.l d1,d2
edge_b19c2:
edge_b19c4:
edge_b19c6:
 btst #$d,d7
edge_b19ca:
 bne.b edge_b1a42
edge_b19cc:
 tst.w $20(a5)
edge_b19d0:
 beq.b edge_b19d4
edge_b19d2:
 or.l d5,d0
edge_b19d4:
 tst.w $22(a5)
edge_b19d8:
 beq.b edge_b19dc
edge_b19da:
 or.l d5,d2
edge_b19dc:
 tst.w $24(a5)
edge_b19e0:
 beq.b edge_b19e4
edge_b19e2:
 or.l d5,d4
edge_b19e4:
 tst.w $26(a5)
edge_b19e8:
 beq.b edge_b19ec
edge_b19ea:
 or.l d5,d6
edge_b19ec:
 btst #$e,d7
edge_b19f0:
 bne.b edge_b1a1a
edge_b19f2:
 tst.w $10(a5)
edge_b19f6:
 beq.b edge_b19fa
edge_b19f8:
 or.l d3,d0
edge_b19fa:
 tst.w $12(a5)
edge_b19fe:
 beq.b edge_b1a02
edge_b1a00:
 or.l d3,d2
edge_b1a02:
 tst.w $14(a5)
edge_b1a06:
 beq.b edge_b1a0a
edge_b1a08:
 or.l d3,d4
edge_b1a0a:
 tst.w $16(a5)
edge_b1a0e:
 beq.b edge_b1a12
edge_b1a10:
 or.l d3,d6
edge_b1a12:
 movem.l (a7)+,d1/d3
edge_b1a16:
 movea.l (a7)+,a0
edge_b1a18:
 rts
edge_b1a1a:
 tst.w $18(a5)
edge_b1a1e:
 beq.b edge_b1a22
edge_b1a20:
 or.l d3,d0
edge_b1a22:
 tst.w $1a(a5)
edge_b1a26:
 beq.b edge_b1a2a
edge_b1a28:
 or.l d3,d2
edge_b1a2a:
 tst.w $1c(a5)
edge_b1a2e:
 beq.b edge_b1a32
edge_b1a30:
 or.l d3,d4
edge_b1a32:
 tst.w $1e(a5)
edge_b1a36:
 beq.b edge_b1a3a
edge_b1a38:
 or.l d3,d6
edge_b1a3a:
 movem.l (a7)+,d1/d3
edge_b1a3e:
 movea.l (a7)+,a0
edge_b1a40:
 rts
edge_b1a42:
 tst.w $28(a5)
edge_b1a46:
 beq.b edge_b1a4a
edge_b1a48:
 or.l d5,d0
edge_b1a4a:
 tst.w $2a(a5)
edge_b1a4e:
 beq.b edge_b1a52
edge_b1a50:
 or.l d5,d2
edge_b1a52:
 tst.w $2c(a5)
edge_b1a56:
 beq.b edge_b1a5a
edge_b1a58:
 or.l d5,d4
edge_b1a5a:
 tst.w $2e(a5)
edge_b1a5e:
 beq.b edge_b1a62
edge_b1a60:
 or.l d5,d6
edge_b1a62:
 btst #$e,d7
edge_b1a66:
 bne.b edge_b1a90
edge_b1a68:
 tst.w $10(a5)
edge_b1a6c:
 beq.b edge_b1a70
edge_b1a6e:
 or.l d3,d0
edge_b1a70:
 tst.w $12(a5)
edge_b1a74:
 beq.b edge_b1a78
edge_b1a76:
 or.l d3,d2
edge_b1a78:
 tst.w $14(a5)
edge_b1a7c:
 beq.b edge_b1a80
edge_b1a7e:
 or.l d3,d4
edge_b1a80:
 tst.w $16(a5)
edge_b1a84:
 beq.b edge_b1a88
edge_b1a86:
 or.l d3,d6
edge_b1a88:
 movem.l (a7)+,d1/d3
edge_b1a8c:
 movea.l (a7)+,a0
edge_b1a8e:
 rts
edge_b1a90:
 tst.w $18(a5)
edge_b1a94:
 beq.b edge_b1a98
edge_b1a96:
 or.l d3,d0
edge_b1a98:
 tst.w $1a(a5)
edge_b1a9c:
 beq.b edge_b1aa0
edge_b1a9e:
 or.l d3,d2
edge_b1aa0:
 tst.w $1c(a5)
edge_b1aa4:
 beq.b edge_b1aa8
edge_b1aa6:
 or.l d3,d4
edge_b1aa8:
 tst.w $1e(a5)
edge_b1aac:
 beq.b edge_b1ab0
edge_b1aae:
 or.l d3,d6
edge_b1ab0:
 movem.l (a7)+,d1/d3
edge_b1ab4:
 movea.l (a7)+,a0
edge_b1ab6:
 rts
