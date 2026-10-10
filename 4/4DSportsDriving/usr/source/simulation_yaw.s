; Fractional atan2(x,y), with 1024 angles/revolution and eight fraction bits.
; Inputs D0.W=x, D1.W=y (full signed-word range). D0.L returns 0..$3ffff.
; Zero vector returns zero. Preserve D1-D5/A0; CCR unspecified.
; This arithmetic kernel is not yet a live geometry hook. Its caller must
; remove wheel-reconstruction bias before carrying a geometric angle delta.
sim_yaw_atan_q8:
 movem.l d1-d5/a0,-(sp)
 ext.l d0
 ext.l d1
 moveq #0,d2
 tst.l d0
 bpl .x_positive
 neg.l d0
 bset #0,d2
.x_positive:
 tst.l d1
 bpl .y_positive
 neg.l d1
 bset #1,d2
.y_positive:
 cmp.l d1,d0
 bne .unequal
 tst.l d0
 beq .done
 move.l #32768,d0
 bra .quadrant
.unequal:
 blo .ratio
 exg d0,d1
 bset #2,d2
.ratio:
 ; min < max <=32768: unsigned DIVU quotient always fits a word.
 swap d0
 divu d1,d0
 and.l #$ffff,d0
 move.w d0,d3
 and.w #255,d3
 lsr.w #8,d0
 add.w d0,d0
 lea sim_yaw_atan_table(pc),a0
 moveq #0,d4
 move.w (a0,d0.w),d4
 moveq #0,d5
 move.w 2(a0,d0.w),d5
 sub.w d4,d5
 mulu d3,d5
 add.l #128,d5
 lsr.l #8,d5
 move.l d4,d0
 add.l d5,d0
 btst #2,d2
 beq .quadrant
 neg.l d0
 add.l #65536,d0
.quadrant:
 btst #1,d2
 beq .x_sign
 neg.l d0
 add.l #131072,d0
.x_sign:
 btst #0,d2
 beq .wrap
 neg.l d0
.wrap:
 and.l #$3ffff,d0
.done:
 movem.l (sp)+,d1-d5/a0
 rts

; round(atan(i/256)*512/pi*256), i=0..256. Unsigned Q8 words.
sim_yaw_atan_table:
 dc.w 0,163,326,489,652,815,978,1141
 dc.w 1303,1466,1629,1792,1954,2117,2279,2442
 dc.w 2604,2767,2929,3091,3253,3415,3577,3738
 dc.w 3900,4061,4223,4384,4545,4706,4867,5028
 dc.w 5188,5349,5509,5669,5829,5989,6148,6308
 dc.w 6467,6626,6784,6943,7101,7260,7418,7575
 dc.w 7733,7890,8047,8204,8361,8517,8673,8829
 dc.w 8985,9140,9296,9450,9605,9759,9914,10067
 dc.w 10221,10374,10527,10680,10832,10984,11136,11287
 dc.w 11439,11590,11740,11890,12040,12190,12339,12488
 dc.w 12637,12785,12933,13081,13228,13375,13522,13668
 dc.w 13814,13959,14105,14249,14394,14538,14682,14825
 dc.w 14968,15111,15253,15395,15537,15678,15819,15960
 dc.w 16100,16239,16379,16518,16656,16794,16932,17069
 dc.w 17206,17343,17479,17615,17750,17885,18020,18154
 dc.w 18288,18421,18554,18687,18819,18951,19083,19213
 dc.w 19344,19474,19604,19733,19862,19991,20119,20247
 dc.w 20374,20501,20627,20753,20879,21004,21129,21254
 dc.w 21378,21501,21624,21747,21870,21992,22113,22234
 dc.w 22355,22475,22595,22714,22834,22952,23070,23188
 dc.w 23306,23423,23539,23655,23771,23886,24001,24116
 dc.w 24230,24344,24457,24570,24682,24795,24906,25017
 dc.w 25128,25239,25349,25459,25568,25677,25785,25893
 dc.w 26001,26108,26215,26321,26427,26533,26638,26743
 dc.w 26848,26952,27056,27159,27262,27364,27467,27568
 dc.w 27670,27771,27871,27972,28072,28171,28270,28369
 dc.w 28467,28565,28663,28760,28857,28953,29050,29145
 dc.w 29241,29336,29430,29525,29619,29712,29805,29898
 dc.w 29991,30083,30175,30266,30357,30448,30538,30628
 dc.w 30718,30807,30896,30985,31073,31161,31248,31336
 dc.w 31423,31509,31595,31681,31767,31852,31937,32022
 dc.w 32106,32190,32273,32357,32439,32522,32604,32686
 dc.w 32768
