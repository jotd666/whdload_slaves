; CPU work reduction, enabled after CUSTOM2 and Fast RAM selection.
; The caller flushes caches after all one-time patches; no per-frame code writes.
f_cpu_init:
 nop
 nop
 bsr.w f_hud_init
 bsr.w f_saves_init
 bsr.w f_sort_init
 bsr.w f_dispatch_init
 bsr.w f_edge_init
 bsr.w f_span_init
.done:
 rts
; paired plane fills; preserve clipping and rewrite relocated jump tables.
f_span_init:
 lea f_span_sites(pc),a2
 moveq #2,d7
.loop:
 move.l a5,a0
 adda.l (a2)+,a0 ; first table
 move.l a5,a1
 adda.l (a2)+,a1 ; old first-plane fill area
 move.l a5,a3
 adda.l (a2)+,a3 ; native continuation
 move.l a1,d2
 move.l a1,d3
 addi.l #44,d3 ; even-length ladder follows odd-length ladder
 moveq #9,d0
.table:
 move.l d2,d1
 addi.l #36,d1
 move.l d1,(a0)+
 move.l d3,d1
 addi.l #36,d1
 move.l d1,(a0)+
 subq.l #4,d2
 subq.l #4,d3
 dbf d0,.table
 moveq #8,d0
.odd:
 move.l #$2d022100,(a1)+ ; move.l d2,-(a6) / move.l d0,-(a0)
 dbf d0,.odd
 move.l #$3d023100,(a1)+ ; final word in each plane
 bsr .branch
 moveq #9,d0
.even:
 move.l #$2d022100,(a1)+
 dbf d0,.even
 bsr .branch
 dbf d7,.loop
 rts
.branch:
 move.w #$6000,(a1)+
 move.l a3,d1
 sub.l a1,d1
 move.w d1,(a1)+
 rts
f_span_sites:
 dc.l $311a8,$311f8,$312a6
 dc.l $3140a,$3145a,$31508
 dc.l $3157e,$315ce,$3167c

; turn the eight binary palette flags into four stripe dispatch entries.
; Bit 7..4 selects outer masks in d0/d2/d4/d6; bit 3..0 selects inner masks.
; The static cases below contain only the required ORs and a shared return.
f_edge_init:
 lea f_main(pc),a0
 move.l a5,d0
 addi.l #$31950,d0
 move.l d0,(a0)
 move.l a5,a1
 adda.l #$310e2,a1
 lea f_road_colors(pc),a0
 move.w #$4eb9,(a1)
 move.l a0,2(a1)
 move.l a5,a1
 adda.l #$31994,a1
 lea f_edge(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 rts
f_main: dc.l 0
f_edge_choices: ds.l 4
f_road_colors:
 move.l f_main(pc),a5
 move.l $10(a5),a5
 movem.l d0-d3/a0-a2,-(a7)
 lea f_edge_choices(pc),a0
 moveq #0,d3
.state:
 moveq #0,d0
 moveq #0,d1
 move.w d3,d1
 andi.w #1,d1
 lsl.w #3,d1
 lea $20(a5,d1.w),a1
 moveq #3,d2
.outer:
 tst.w (a1)+
 sne d1
 add.b d1,d1
 addx.w d0,d0
 dbf d2,.outer
 move.w d3,d1
 andi.w #2,d1
 lsl.w #2,d1
 lea $10(a5,d1.w),a1
 moveq #3,d2
.inner:
 tst.w (a1)+
 sne d1
 add.b d1,d1
 addx.w d0,d0
 dbf d2,.inner
 add.w d0,d0
 lea f_edge_offsets(pc),a1
 move.w (a1,d0.w),d1
 lea f_edge_code(pc),a1
 adda.w d1,a1
 move.l a1,(a0)+
 addq.w #1,d3
 cmpi.w #4,d3
 bne .state
 movem.l (a7)+,d0-d3/a0-a2
 rts
f_edge:
 movem.l d1/d3/a0,-(a7)
 move.l d4,d1
 move.l d6,d3
 moveq #0,d4
 moveq #0,d6
 move.l f_main(pc),a0
 move.l (a0),a0
 move.w -4(a0),d0
 swap d0
 move.w -4(a0),d0
 and.l d1,d0
 move.w -2(a0),d2
 swap d2
 move.w -2(a0),d2
 and.l d1,d2
 move.w d7,d1
 lsr.w #8,d1
 lsr.w #3,d1
 andi.w #12,d1
 lea f_edge_choices(pc),a0
 move.l (a0,d1.w),a0
 jmp (a0)
f_edge_return:
 movem.l (a7)+,d1/d3/a0
 rts
f_edge_offsets:
 dc.w f_edge_0-f_edge_code
 dc.w f_edge_1-f_edge_code
 dc.w f_edge_2-f_edge_code
 dc.w f_edge_3-f_edge_code
 dc.w f_edge_4-f_edge_code
 dc.w f_edge_5-f_edge_code
 dc.w f_edge_6-f_edge_code
 dc.w f_edge_7-f_edge_code
 dc.w f_edge_8-f_edge_code
 dc.w f_edge_9-f_edge_code
 dc.w f_edge_10-f_edge_code
 dc.w f_edge_11-f_edge_code
 dc.w f_edge_12-f_edge_code
 dc.w f_edge_13-f_edge_code
 dc.w f_edge_14-f_edge_code
 dc.w f_edge_15-f_edge_code
 dc.w f_edge_16-f_edge_code
 dc.w f_edge_17-f_edge_code
 dc.w f_edge_18-f_edge_code
 dc.w f_edge_19-f_edge_code
 dc.w f_edge_20-f_edge_code
 dc.w f_edge_21-f_edge_code
 dc.w f_edge_22-f_edge_code
 dc.w f_edge_23-f_edge_code
 dc.w f_edge_24-f_edge_code
 dc.w f_edge_25-f_edge_code
 dc.w f_edge_26-f_edge_code
 dc.w f_edge_27-f_edge_code
 dc.w f_edge_28-f_edge_code
 dc.w f_edge_29-f_edge_code
 dc.w f_edge_30-f_edge_code
 dc.w f_edge_31-f_edge_code
 dc.w f_edge_32-f_edge_code
 dc.w f_edge_33-f_edge_code
 dc.w f_edge_34-f_edge_code
 dc.w f_edge_35-f_edge_code
 dc.w f_edge_36-f_edge_code
 dc.w f_edge_37-f_edge_code
 dc.w f_edge_38-f_edge_code
 dc.w f_edge_39-f_edge_code
 dc.w f_edge_40-f_edge_code
 dc.w f_edge_41-f_edge_code
 dc.w f_edge_42-f_edge_code
 dc.w f_edge_43-f_edge_code
 dc.w f_edge_44-f_edge_code
 dc.w f_edge_45-f_edge_code
 dc.w f_edge_46-f_edge_code
 dc.w f_edge_47-f_edge_code
 dc.w f_edge_48-f_edge_code
 dc.w f_edge_49-f_edge_code
 dc.w f_edge_50-f_edge_code
 dc.w f_edge_51-f_edge_code
 dc.w f_edge_52-f_edge_code
 dc.w f_edge_53-f_edge_code
 dc.w f_edge_54-f_edge_code
 dc.w f_edge_55-f_edge_code
 dc.w f_edge_56-f_edge_code
 dc.w f_edge_57-f_edge_code
 dc.w f_edge_58-f_edge_code
 dc.w f_edge_59-f_edge_code
 dc.w f_edge_60-f_edge_code
 dc.w f_edge_61-f_edge_code
 dc.w f_edge_62-f_edge_code
 dc.w f_edge_63-f_edge_code
 dc.w f_edge_64-f_edge_code
 dc.w f_edge_65-f_edge_code
 dc.w f_edge_66-f_edge_code
 dc.w f_edge_67-f_edge_code
 dc.w f_edge_68-f_edge_code
 dc.w f_edge_69-f_edge_code
 dc.w f_edge_70-f_edge_code
 dc.w f_edge_71-f_edge_code
 dc.w f_edge_72-f_edge_code
 dc.w f_edge_73-f_edge_code
 dc.w f_edge_74-f_edge_code
 dc.w f_edge_75-f_edge_code
 dc.w f_edge_76-f_edge_code
 dc.w f_edge_77-f_edge_code
 dc.w f_edge_78-f_edge_code
 dc.w f_edge_79-f_edge_code
 dc.w f_edge_80-f_edge_code
 dc.w f_edge_81-f_edge_code
 dc.w f_edge_82-f_edge_code
 dc.w f_edge_83-f_edge_code
 dc.w f_edge_84-f_edge_code
 dc.w f_edge_85-f_edge_code
 dc.w f_edge_86-f_edge_code
 dc.w f_edge_87-f_edge_code
 dc.w f_edge_88-f_edge_code
 dc.w f_edge_89-f_edge_code
 dc.w f_edge_90-f_edge_code
 dc.w f_edge_91-f_edge_code
 dc.w f_edge_92-f_edge_code
 dc.w f_edge_93-f_edge_code
 dc.w f_edge_94-f_edge_code
 dc.w f_edge_95-f_edge_code
 dc.w f_edge_96-f_edge_code
 dc.w f_edge_97-f_edge_code
 dc.w f_edge_98-f_edge_code
 dc.w f_edge_99-f_edge_code
 dc.w f_edge_100-f_edge_code
 dc.w f_edge_101-f_edge_code
 dc.w f_edge_102-f_edge_code
 dc.w f_edge_103-f_edge_code
 dc.w f_edge_104-f_edge_code
 dc.w f_edge_105-f_edge_code
 dc.w f_edge_106-f_edge_code
 dc.w f_edge_107-f_edge_code
 dc.w f_edge_108-f_edge_code
 dc.w f_edge_109-f_edge_code
 dc.w f_edge_110-f_edge_code
 dc.w f_edge_111-f_edge_code
 dc.w f_edge_112-f_edge_code
 dc.w f_edge_113-f_edge_code
 dc.w f_edge_114-f_edge_code
 dc.w f_edge_115-f_edge_code
 dc.w f_edge_116-f_edge_code
 dc.w f_edge_117-f_edge_code
 dc.w f_edge_118-f_edge_code
 dc.w f_edge_119-f_edge_code
 dc.w f_edge_120-f_edge_code
 dc.w f_edge_121-f_edge_code
 dc.w f_edge_122-f_edge_code
 dc.w f_edge_123-f_edge_code
 dc.w f_edge_124-f_edge_code
 dc.w f_edge_125-f_edge_code
 dc.w f_edge_126-f_edge_code
 dc.w f_edge_127-f_edge_code
 dc.w f_edge_128-f_edge_code
 dc.w f_edge_129-f_edge_code
 dc.w f_edge_130-f_edge_code
 dc.w f_edge_131-f_edge_code
 dc.w f_edge_132-f_edge_code
 dc.w f_edge_133-f_edge_code
 dc.w f_edge_134-f_edge_code
 dc.w f_edge_135-f_edge_code
 dc.w f_edge_136-f_edge_code
 dc.w f_edge_137-f_edge_code
 dc.w f_edge_138-f_edge_code
 dc.w f_edge_139-f_edge_code
 dc.w f_edge_140-f_edge_code
 dc.w f_edge_141-f_edge_code
 dc.w f_edge_142-f_edge_code
 dc.w f_edge_143-f_edge_code
 dc.w f_edge_144-f_edge_code
 dc.w f_edge_145-f_edge_code
 dc.w f_edge_146-f_edge_code
 dc.w f_edge_147-f_edge_code
 dc.w f_edge_148-f_edge_code
 dc.w f_edge_149-f_edge_code
 dc.w f_edge_150-f_edge_code
 dc.w f_edge_151-f_edge_code
 dc.w f_edge_152-f_edge_code
 dc.w f_edge_153-f_edge_code
 dc.w f_edge_154-f_edge_code
 dc.w f_edge_155-f_edge_code
 dc.w f_edge_156-f_edge_code
 dc.w f_edge_157-f_edge_code
 dc.w f_edge_158-f_edge_code
 dc.w f_edge_159-f_edge_code
 dc.w f_edge_160-f_edge_code
 dc.w f_edge_161-f_edge_code
 dc.w f_edge_162-f_edge_code
 dc.w f_edge_163-f_edge_code
 dc.w f_edge_164-f_edge_code
 dc.w f_edge_165-f_edge_code
 dc.w f_edge_166-f_edge_code
 dc.w f_edge_167-f_edge_code
 dc.w f_edge_168-f_edge_code
 dc.w f_edge_169-f_edge_code
 dc.w f_edge_170-f_edge_code
 dc.w f_edge_171-f_edge_code
 dc.w f_edge_172-f_edge_code
 dc.w f_edge_173-f_edge_code
 dc.w f_edge_174-f_edge_code
 dc.w f_edge_175-f_edge_code
 dc.w f_edge_176-f_edge_code
 dc.w f_edge_177-f_edge_code
 dc.w f_edge_178-f_edge_code
 dc.w f_edge_179-f_edge_code
 dc.w f_edge_180-f_edge_code
 dc.w f_edge_181-f_edge_code
 dc.w f_edge_182-f_edge_code
 dc.w f_edge_183-f_edge_code
 dc.w f_edge_184-f_edge_code
 dc.w f_edge_185-f_edge_code
 dc.w f_edge_186-f_edge_code
 dc.w f_edge_187-f_edge_code
 dc.w f_edge_188-f_edge_code
 dc.w f_edge_189-f_edge_code
 dc.w f_edge_190-f_edge_code
 dc.w f_edge_191-f_edge_code
 dc.w f_edge_192-f_edge_code
 dc.w f_edge_193-f_edge_code
 dc.w f_edge_194-f_edge_code
 dc.w f_edge_195-f_edge_code
 dc.w f_edge_196-f_edge_code
 dc.w f_edge_197-f_edge_code
 dc.w f_edge_198-f_edge_code
 dc.w f_edge_199-f_edge_code
 dc.w f_edge_200-f_edge_code
 dc.w f_edge_201-f_edge_code
 dc.w f_edge_202-f_edge_code
 dc.w f_edge_203-f_edge_code
 dc.w f_edge_204-f_edge_code
 dc.w f_edge_205-f_edge_code
 dc.w f_edge_206-f_edge_code
 dc.w f_edge_207-f_edge_code
 dc.w f_edge_208-f_edge_code
 dc.w f_edge_209-f_edge_code
 dc.w f_edge_210-f_edge_code
 dc.w f_edge_211-f_edge_code
 dc.w f_edge_212-f_edge_code
 dc.w f_edge_213-f_edge_code
 dc.w f_edge_214-f_edge_code
 dc.w f_edge_215-f_edge_code
 dc.w f_edge_216-f_edge_code
 dc.w f_edge_217-f_edge_code
 dc.w f_edge_218-f_edge_code
 dc.w f_edge_219-f_edge_code
 dc.w f_edge_220-f_edge_code
 dc.w f_edge_221-f_edge_code
 dc.w f_edge_222-f_edge_code
 dc.w f_edge_223-f_edge_code
 dc.w f_edge_224-f_edge_code
 dc.w f_edge_225-f_edge_code
 dc.w f_edge_226-f_edge_code
 dc.w f_edge_227-f_edge_code
 dc.w f_edge_228-f_edge_code
 dc.w f_edge_229-f_edge_code
 dc.w f_edge_230-f_edge_code
 dc.w f_edge_231-f_edge_code
 dc.w f_edge_232-f_edge_code
 dc.w f_edge_233-f_edge_code
 dc.w f_edge_234-f_edge_code
 dc.w f_edge_235-f_edge_code
 dc.w f_edge_236-f_edge_code
 dc.w f_edge_237-f_edge_code
 dc.w f_edge_238-f_edge_code
 dc.w f_edge_239-f_edge_code
 dc.w f_edge_240-f_edge_code
 dc.w f_edge_241-f_edge_code
 dc.w f_edge_242-f_edge_code
 dc.w f_edge_243-f_edge_code
 dc.w f_edge_244-f_edge_code
 dc.w f_edge_245-f_edge_code
 dc.w f_edge_246-f_edge_code
 dc.w f_edge_247-f_edge_code
 dc.w f_edge_248-f_edge_code
 dc.w f_edge_249-f_edge_code
 dc.w f_edge_250-f_edge_code
 dc.w f_edge_251-f_edge_code
 dc.w f_edge_252-f_edge_code
 dc.w f_edge_253-f_edge_code
 dc.w f_edge_254-f_edge_code
 dc.w f_edge_255-f_edge_code
f_edge_code:
f_edge_0:
 bra.w f_edge_return
f_edge_1:
 or.l d3,d6
 bra.w f_edge_return
f_edge_2:
 or.l d3,d4
 bra.w f_edge_return
f_edge_3:
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_4:
 or.l d3,d2
 bra.w f_edge_return
f_edge_5:
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_6:
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_7:
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_8:
 or.l d3,d0
 bra.w f_edge_return
f_edge_9:
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_10:
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_11:
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_12:
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_13:
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_14:
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_15:
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_16:
 or.l d5,d6
 bra.w f_edge_return
f_edge_17:
 or.l d5,d6
 or.l d3,d6
 bra.w f_edge_return
f_edge_18:
 or.l d5,d6
 or.l d3,d4
 bra.w f_edge_return
f_edge_19:
 or.l d5,d6
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_20:
 or.l d5,d6
 or.l d3,d2
 bra.w f_edge_return
f_edge_21:
 or.l d5,d6
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_22:
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_23:
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_24:
 or.l d5,d6
 or.l d3,d0
 bra.w f_edge_return
f_edge_25:
 or.l d5,d6
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_26:
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_27:
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_28:
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_29:
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_30:
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_31:
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_32:
 or.l d5,d4
 bra.w f_edge_return
f_edge_33:
 or.l d5,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_34:
 or.l d5,d4
 or.l d3,d4
 bra.w f_edge_return
f_edge_35:
 or.l d5,d4
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_36:
 or.l d5,d4
 or.l d3,d2
 bra.w f_edge_return
f_edge_37:
 or.l d5,d4
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_38:
 or.l d5,d4
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_39:
 or.l d5,d4
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_40:
 or.l d5,d4
 or.l d3,d0
 bra.w f_edge_return
f_edge_41:
 or.l d5,d4
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_42:
 or.l d5,d4
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_43:
 or.l d5,d4
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_44:
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_45:
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_46:
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_47:
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_48:
 or.l d5,d4
 or.l d5,d6
 bra.w f_edge_return
f_edge_49:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d6
 bra.w f_edge_return
f_edge_50:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d4
 bra.w f_edge_return
f_edge_51:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_52:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 bra.w f_edge_return
f_edge_53:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_54:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_55:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_56:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 bra.w f_edge_return
f_edge_57:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_58:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_59:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_60:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_61:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_62:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_63:
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_64:
 or.l d5,d2
 bra.w f_edge_return
f_edge_65:
 or.l d5,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_66:
 or.l d5,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_67:
 or.l d5,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_68:
 or.l d5,d2
 or.l d3,d2
 bra.w f_edge_return
f_edge_69:
 or.l d5,d2
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_70:
 or.l d5,d2
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_71:
 or.l d5,d2
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_72:
 or.l d5,d2
 or.l d3,d0
 bra.w f_edge_return
f_edge_73:
 or.l d5,d2
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_74:
 or.l d5,d2
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_75:
 or.l d5,d2
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_76:
 or.l d5,d2
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_77:
 or.l d5,d2
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_78:
 or.l d5,d2
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_79:
 or.l d5,d2
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_80:
 or.l d5,d2
 or.l d5,d6
 bra.w f_edge_return
f_edge_81:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d6
 bra.w f_edge_return
f_edge_82:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d4
 bra.w f_edge_return
f_edge_83:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_84:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d2
 bra.w f_edge_return
f_edge_85:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_86:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_87:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_88:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 bra.w f_edge_return
f_edge_89:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_90:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_91:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_92:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_93:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_94:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_95:
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_96:
 or.l d5,d2
 or.l d5,d4
 bra.w f_edge_return
f_edge_97:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_98:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d4
 bra.w f_edge_return
f_edge_99:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_100:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d2
 bra.w f_edge_return
f_edge_101:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_102:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_103:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_104:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 bra.w f_edge_return
f_edge_105:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_106:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_107:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_108:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_109:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_110:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_111:
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_112:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 bra.w f_edge_return
f_edge_113:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d6
 bra.w f_edge_return
f_edge_114:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d4
 bra.w f_edge_return
f_edge_115:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_116:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 bra.w f_edge_return
f_edge_117:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_118:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_119:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_120:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 bra.w f_edge_return
f_edge_121:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_122:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_123:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_124:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_125:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_126:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_127:
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_128:
 or.l d5,d0
 bra.w f_edge_return
f_edge_129:
 or.l d5,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_130:
 or.l d5,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_131:
 or.l d5,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_132:
 or.l d5,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_133:
 or.l d5,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_134:
 or.l d5,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_135:
 or.l d5,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_136:
 or.l d5,d0
 or.l d3,d0
 bra.w f_edge_return
f_edge_137:
 or.l d5,d0
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_138:
 or.l d5,d0
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_139:
 or.l d5,d0
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_140:
 or.l d5,d0
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_141:
 or.l d5,d0
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_142:
 or.l d5,d0
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_143:
 or.l d5,d0
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_144:
 or.l d5,d0
 or.l d5,d6
 bra.w f_edge_return
f_edge_145:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d6
 bra.w f_edge_return
f_edge_146:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d4
 bra.w f_edge_return
f_edge_147:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_148:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d2
 bra.w f_edge_return
f_edge_149:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_150:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_151:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_152:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d0
 bra.w f_edge_return
f_edge_153:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_154:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_155:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_156:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_157:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_158:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_159:
 or.l d5,d0
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_160:
 or.l d5,d0
 or.l d5,d4
 bra.w f_edge_return
f_edge_161:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_162:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d4
 bra.w f_edge_return
f_edge_163:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_164:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d2
 bra.w f_edge_return
f_edge_165:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_166:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_167:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_168:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d0
 bra.w f_edge_return
f_edge_169:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_170:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_171:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_172:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_173:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_174:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_175:
 or.l d5,d0
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_176:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 bra.w f_edge_return
f_edge_177:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d6
 bra.w f_edge_return
f_edge_178:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d4
 bra.w f_edge_return
f_edge_179:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_180:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 bra.w f_edge_return
f_edge_181:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_182:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_183:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_184:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 bra.w f_edge_return
f_edge_185:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_186:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_187:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_188:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_189:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_190:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_191:
 or.l d5,d0
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_192:
 or.l d5,d0
 or.l d5,d2
 bra.w f_edge_return
f_edge_193:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_194:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_195:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_196:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d2
 bra.w f_edge_return
f_edge_197:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_198:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_199:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_200:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d0
 bra.w f_edge_return
f_edge_201:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_202:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_203:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_204:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_205:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_206:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_207:
 or.l d5,d0
 or.l d5,d2
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_208:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 bra.w f_edge_return
f_edge_209:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d6
 bra.w f_edge_return
f_edge_210:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d4
 bra.w f_edge_return
f_edge_211:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_212:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d2
 bra.w f_edge_return
f_edge_213:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_214:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_215:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_216:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 bra.w f_edge_return
f_edge_217:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_218:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_219:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_220:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_221:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_222:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_223:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_224:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 bra.w f_edge_return
f_edge_225:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_226:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d4
 bra.w f_edge_return
f_edge_227:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_228:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d2
 bra.w f_edge_return
f_edge_229:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_230:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_231:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_232:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 bra.w f_edge_return
f_edge_233:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_234:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_235:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_236:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_237:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_238:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_239:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_240:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 bra.w f_edge_return
f_edge_241:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d6
 bra.w f_edge_return
f_edge_242:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d4
 bra.w f_edge_return
f_edge_243:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_244:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 bra.w f_edge_return
f_edge_245:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_246:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_247:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_248:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 bra.w f_edge_return
f_edge_249:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d6
 bra.w f_edge_return
f_edge_250:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 bra.w f_edge_return
f_edge_251:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return
f_edge_252:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 bra.w f_edge_return
f_edge_253:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d6
 bra.w f_edge_return
f_edge_254:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 bra.w f_edge_return
f_edge_255:
 or.l d5,d0
 or.l d5,d2
 or.l d5,d4
 or.l d5,d6
 or.l d3,d0
 or.l d3,d2
 or.l d3,d4
 or.l d3,d6
 bra.w f_edge_return

; direct dispatch for the native nonnegative object-type namespace.
; Negative types retain their separate native overlay/split handling.
f_dispatch_init:
 lea f_dispatch_base(pc),a0
 move.l a5,d0
 addi.l #$30000,d0
 move.l d0,(a0)
 move.l a5,a1
 adda.l #$300fe,a1
 lea f_dispatch(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 rts
f_dispatch_base: dc.l 0
f_dispatch:
 cmpi.w #$234,d4
 bcc .done
 move.w d4,-(a7)
 add.w d4,d4
 lea f_dispatch_table(pc),a3
 move.w (a3,d4.w),d4
 move.l f_dispatch_base(pc),a3
 adda.w d4,a3
 move.w (a7)+,d4
 jmp (a3)
.done:
 rts
; Dense native type namespace $000..$233; holes target the native RTS.
f_dispatch_table:
 dc.w $032c ; $000
 dc.w $032c ; $001
 dc.w $032c ; $002
 dc.w $032c ; $003
 dc.w $032c ; $004
 dc.w $032c ; $005
 dc.w $032c ; $006
 dc.w $032c ; $007
 dc.w $032c ; $008
 dc.w $032c ; $009
 dc.w $032c ; $00a
 dc.w $032c ; $00b
 dc.w $032c ; $00c
 dc.w $032c ; $00d
 dc.w $032c ; $00e
 dc.w $032c ; $00f
 dc.w $032c ; $010
 dc.w $032c ; $011
 dc.w $032c ; $012
 dc.w $032c ; $013
 dc.w $032c ; $014
 dc.w $032c ; $015
 dc.w $032c ; $016
 dc.w $032c ; $017
 dc.w $032c ; $018
 dc.w $032c ; $019
 dc.w $032c ; $01a
 dc.w $032c ; $01b
 dc.w $032c ; $01c
 dc.w $032c ; $01d
 dc.w $032c ; $01e
 dc.w $032c ; $01f
 dc.w $032c ; $020
 dc.w $032c ; $021
 dc.w $032c ; $022
 dc.w $032c ; $023
 dc.w $032c ; $024
 dc.w $032c ; $025
 dc.w $032c ; $026
 dc.w $032c ; $027
 dc.w $032c ; $028
 dc.w $032c ; $029
 dc.w $032c ; $02a
 dc.w $032c ; $02b
 dc.w $032c ; $02c
 dc.w $032c ; $02d
 dc.w $032c ; $02e
 dc.w $032c ; $02f
 dc.w $032c ; $030
 dc.w $032c ; $031
 dc.w $032c ; $032
 dc.w $032c ; $033
 dc.w $032c ; $034
 dc.w $032c ; $035
 dc.w $032c ; $036
 dc.w $032c ; $037
 dc.w $032c ; $038
 dc.w $032c ; $039
 dc.w $032c ; $03a
 dc.w $032c ; $03b
 dc.w $032c ; $03c
 dc.w $032c ; $03d
 dc.w $032c ; $03e
 dc.w $032c ; $03f
 dc.w $032c ; $040
 dc.w $032c ; $041
 dc.w $032c ; $042
 dc.w $032c ; $043
 dc.w $032c ; $044
 dc.w $032c ; $045
 dc.w $032c ; $046
 dc.w $032c ; $047
 dc.w $032c ; $048
 dc.w $032c ; $049
 dc.w $032c ; $04a
 dc.w $032c ; $04b
 dc.w $032c ; $04c
 dc.w $032c ; $04d
 dc.w $032c ; $04e
 dc.w $032c ; $04f
 dc.w $032c ; $050
 dc.w $032c ; $051
 dc.w $032c ; $052
 dc.w $032c ; $053
 dc.w $032c ; $054
 dc.w $032c ; $055
 dc.w $032c ; $056
 dc.w $032c ; $057
 dc.w $032c ; $058
 dc.w $0510 ; $059
 dc.w $0510 ; $05a
 dc.w $0510 ; $05b
 dc.w $0510 ; $05c
 dc.w $0510 ; $05d
 dc.w $0510 ; $05e
 dc.w $01ae ; $05f
 dc.w $01ae ; $060
 dc.w $01ae ; $061
 dc.w $01ae ; $062
 dc.w $01ae ; $063
 dc.w $01ae ; $064
 dc.w $01ae ; $065
 dc.w $01ae ; $066
 dc.w $01ae ; $067
 dc.w $01ae ; $068
 dc.w $01ae ; $069
 dc.w $01ae ; $06a
 dc.w $01ae ; $06b
 dc.w $01ae ; $06c
 dc.w $01ae ; $06d
 dc.w $01ae ; $06e
 dc.w $01ae ; $06f
 dc.w $01ae ; $070
 dc.w $01ae ; $071
 dc.w $01ae ; $072
 dc.w $01ae ; $073
 dc.w $01ae ; $074
 dc.w $01ae ; $075
 dc.w $01ae ; $076
 dc.w $01ae ; $077
 dc.w $01ae ; $078
 dc.w $01ae ; $079
 dc.w $01ae ; $07a
 dc.w $01ae ; $07b
 dc.w $01ae ; $07c
 dc.w $01ae ; $07d
 dc.w $0510 ; $07e
 dc.w $0190 ; $07f
 dc.w $0190 ; $080
 dc.w $0190 ; $081
 dc.w $0190 ; $082
 dc.w $0190 ; $083
 dc.w $0190 ; $084
 dc.w $0190 ; $085
 dc.w $0190 ; $086
 dc.w $01de ; $087
 dc.w $01ee ; $088
 dc.w $01ee ; $089
 dc.w $01ee ; $08a
 dc.w $01ee ; $08b
 dc.w $01ee ; $08c
 dc.w $01ee ; $08d
 dc.w $01ee ; $08e
 dc.w $01ee ; $08f
 dc.w $01ee ; $090
 dc.w $01ee ; $091
 dc.w $01ee ; $092
 dc.w $01ee ; $093
 dc.w $01ee ; $094
 dc.w $01ee ; $095
 dc.w $01ee ; $096
 dc.w $01ee ; $097
 dc.w $01ee ; $098
 dc.w $01ee ; $099
 dc.w $01ee ; $09a
 dc.w $01ee ; $09b
 dc.w $01ee ; $09c
 dc.w $01ee ; $09d
 dc.w $01ee ; $09e
 dc.w $01ee ; $09f
 dc.w $01ee ; $0a0
 dc.w $01ee ; $0a1
 dc.w $01ee ; $0a2
 dc.w $01ee ; $0a3
 dc.w $01ee ; $0a4
 dc.w $01ee ; $0a5
 dc.w $01ee ; $0a6
 dc.w $01ee ; $0a7
 dc.w $01ee ; $0a8
 dc.w $01ee ; $0a9
 dc.w $01ee ; $0aa
 dc.w $01ee ; $0ab
 dc.w $01ee ; $0ac
 dc.w $01ee ; $0ad
 dc.w $01ee ; $0ae
 dc.w $01ee ; $0af
 dc.w $01ee ; $0b0
 dc.w $01ee ; $0b1
 dc.w $01ee ; $0b2
 dc.w $01ee ; $0b3
 dc.w $01ee ; $0b4
 dc.w $01ee ; $0b5
 dc.w $01ee ; $0b6
 dc.w $01ee ; $0b7
 dc.w $01ee ; $0b8
 dc.w $01ee ; $0b9
 dc.w $01ee ; $0ba
 dc.w $01ee ; $0bb
 dc.w $01ee ; $0bc
 dc.w $01ee ; $0bd
 dc.w $01ee ; $0be
 dc.w $01ee ; $0bf
 dc.w $01ee ; $0c0
 dc.w $01ee ; $0c1
 dc.w $01ee ; $0c2
 dc.w $01ee ; $0c3
 dc.w $01ee ; $0c4
 dc.w $01ee ; $0c5
 dc.w $01ee ; $0c6
 dc.w $01ee ; $0c7
 dc.w $01ee ; $0c8
 dc.w $01ee ; $0c9
 dc.w $01ee ; $0ca
 dc.w $01ee ; $0cb
 dc.w $01ee ; $0cc
 dc.w $01ee ; $0cd
 dc.w $01ee ; $0ce
 dc.w $01ee ; $0cf
 dc.w $01ee ; $0d0
 dc.w $01ee ; $0d1
 dc.w $01ee ; $0d2
 dc.w $01ee ; $0d3
 dc.w $01ee ; $0d4
 dc.w $01ee ; $0d5
 dc.w $01ee ; $0d6
 dc.w $01ee ; $0d7
 dc.w $0510 ; $0d8
 dc.w $0510 ; $0d9
 dc.w $0510 ; $0da
 dc.w $0510 ; $0db
 dc.w $0510 ; $0dc
 dc.w $0510 ; $0dd
 dc.w $0510 ; $0de
 dc.w $0510 ; $0df
 dc.w $0510 ; $0e0
 dc.w $0510 ; $0e1
 dc.w $0510 ; $0e2
 dc.w $0510 ; $0e3
 dc.w $0510 ; $0e4
 dc.w $0510 ; $0e5
 dc.w $0510 ; $0e6
 dc.w $0510 ; $0e7
 dc.w $0510 ; $0e8
 dc.w $0510 ; $0e9
 dc.w $0510 ; $0ea
 dc.w $0510 ; $0eb
 dc.w $0510 ; $0ec
 dc.w $0510 ; $0ed
 dc.w $0510 ; $0ee
 dc.w $0510 ; $0ef
 dc.w $0510 ; $0f0
 dc.w $0510 ; $0f1
 dc.w $0510 ; $0f2
 dc.w $0510 ; $0f3
 dc.w $0510 ; $0f4
 dc.w $0510 ; $0f5
 dc.w $0510 ; $0f6
 dc.w $0510 ; $0f7
 dc.w $0510 ; $0f8
 dc.w $0510 ; $0f9
 dc.w $0510 ; $0fa
 dc.w $0510 ; $0fb
 dc.w $0510 ; $0fc
 dc.w $0510 ; $0fd
 dc.w $0510 ; $0fe
 dc.w $0510 ; $0ff
 dc.w $0510 ; $100
 dc.w $0510 ; $101
 dc.w $0510 ; $102
 dc.w $0510 ; $103
 dc.w $0510 ; $104
 dc.w $0510 ; $105
 dc.w $0510 ; $106
 dc.w $0510 ; $107
 dc.w $0510 ; $108
 dc.w $0510 ; $109
 dc.w $0510 ; $10a
 dc.w $0510 ; $10b
 dc.w $0510 ; $10c
 dc.w $0510 ; $10d
 dc.w $0510 ; $10e
 dc.w $0510 ; $10f
 dc.w $0510 ; $110
 dc.w $0510 ; $111
 dc.w $0510 ; $112
 dc.w $0510 ; $113
 dc.w $0510 ; $114
 dc.w $0510 ; $115
 dc.w $0510 ; $116
 dc.w $0510 ; $117
 dc.w $0510 ; $118
 dc.w $0510 ; $119
 dc.w $0510 ; $11a
 dc.w $0510 ; $11b
 dc.w $0510 ; $11c
 dc.w $0510 ; $11d
 dc.w $0510 ; $11e
 dc.w $0510 ; $11f
 dc.w $0510 ; $120
 dc.w $0510 ; $121
 dc.w $0510 ; $122
 dc.w $0510 ; $123
 dc.w $0510 ; $124
 dc.w $0510 ; $125
 dc.w $0510 ; $126
 dc.w $0510 ; $127
 dc.w $0510 ; $128
 dc.w $0510 ; $129
 dc.w $0510 ; $12a
 dc.w $0510 ; $12b
 dc.w $03f2 ; $12c
 dc.w $03f2 ; $12d
 dc.w $03f2 ; $12e
 dc.w $03f2 ; $12f
 dc.w $03f2 ; $130
 dc.w $03f2 ; $131
 dc.w $03f2 ; $132
 dc.w $03f2 ; $133
 dc.w $03f2 ; $134
 dc.w $03f2 ; $135
 dc.w $03f2 ; $136
 dc.w $03f2 ; $137
 dc.w $03f2 ; $138
 dc.w $03f2 ; $139
 dc.w $03f2 ; $13a
 dc.w $03f2 ; $13b
 dc.w $0510 ; $13c
 dc.w $0510 ; $13d
 dc.w $0510 ; $13e
 dc.w $0510 ; $13f
 dc.w $0510 ; $140
 dc.w $0510 ; $141
 dc.w $0510 ; $142
 dc.w $0510 ; $143
 dc.w $0510 ; $144
 dc.w $0510 ; $145
 dc.w $0510 ; $146
 dc.w $0510 ; $147
 dc.w $0510 ; $148
 dc.w $0510 ; $149
 dc.w $0510 ; $14a
 dc.w $0510 ; $14b
 dc.w $0510 ; $14c
 dc.w $0510 ; $14d
 dc.w $0510 ; $14e
 dc.w $0510 ; $14f
 dc.w $0510 ; $150
 dc.w $0510 ; $151
 dc.w $0510 ; $152
 dc.w $0510 ; $153
 dc.w $010c ; $154
 dc.w $010c ; $155
 dc.w $010c ; $156
 dc.w $010c ; $157
 dc.w $010c ; $158
 dc.w $0128 ; $159
 dc.w $0128 ; $15a
 dc.w $0128 ; $15b
 dc.w $0128 ; $15c
 dc.w $0128 ; $15d
 dc.w $0172 ; $15e
 dc.w $0172 ; $15f
 dc.w $0172 ; $160
 dc.w $0172 ; $161
 dc.w $0172 ; $162
 dc.w $0172 ; $163
 dc.w $0172 ; $164
 dc.w $0172 ; $165
 dc.w $02cc ; $166
 dc.w $02cc ; $167
 dc.w $02cc ; $168
 dc.w $02cc ; $169
 dc.w $0300 ; $16a
 dc.w $0300 ; $16b
 dc.w $0300 ; $16c
 dc.w $0300 ; $16d
 dc.w $0510 ; $16e
 dc.w $0510 ; $16f
 dc.w $0510 ; $170
 dc.w $0510 ; $171
 dc.w $02ae ; $172
 dc.w $0520 ; $173
 dc.w $0520 ; $174
 dc.w $0520 ; $175
 dc.w $0520 ; $176
 dc.w $0520 ; $177
 dc.w $0520 ; $178
 dc.w $0520 ; $179
 dc.w $0520 ; $17a
 dc.w $0520 ; $17b
 dc.w $0520 ; $17c
 dc.w $0520 ; $17d
 dc.w $0520 ; $17e
 dc.w $0520 ; $17f
 dc.w $0520 ; $180
 dc.w $0520 ; $181
 dc.w $0520 ; $182
 dc.w $0520 ; $183
 dc.w $0520 ; $184
 dc.w $0520 ; $185
 dc.w $0538 ; $186
 dc.w $0538 ; $187
 dc.w $0538 ; $188
 dc.w $0538 ; $189
 dc.w $0538 ; $18a
 dc.w $0538 ; $18b
 dc.w $0538 ; $18c
 dc.w $0538 ; $18d
 dc.w $0538 ; $18e
 dc.w $0538 ; $18f
 dc.w $0538 ; $190
 dc.w $0538 ; $191
 dc.w $0538 ; $192
 dc.w $0538 ; $193
 dc.w $0538 ; $194
 dc.w $0538 ; $195
 dc.w $0538 ; $196
 dc.w $0538 ; $197
 dc.w $0538 ; $198
 dc.w $0538 ; $199
 dc.w $0538 ; $19a
 dc.w $0538 ; $19b
 dc.w $0538 ; $19c
 dc.w $0538 ; $19d
 dc.w $0538 ; $19e
 dc.w $0538 ; $19f
 dc.w $0538 ; $1a0
 dc.w $0538 ; $1a1
 dc.w $0538 ; $1a2
 dc.w $0538 ; $1a3
 dc.w $0538 ; $1a4
 dc.w $0538 ; $1a5
 dc.w $0538 ; $1a6
 dc.w $0538 ; $1a7
 dc.w $0538 ; $1a8
 dc.w $0538 ; $1a9
 dc.w $0538 ; $1aa
 dc.w $0538 ; $1ab
 dc.w $0538 ; $1ac
 dc.w $0538 ; $1ad
 dc.w $0538 ; $1ae
 dc.w $0538 ; $1af
 dc.w $0538 ; $1b0
 dc.w $0538 ; $1b1
 dc.w $0538 ; $1b2
 dc.w $0538 ; $1b3
 dc.w $0538 ; $1b4
 dc.w $0538 ; $1b5
 dc.w $0538 ; $1b6
 dc.w $0538 ; $1b7
 dc.w $0538 ; $1b8
 dc.w $0538 ; $1b9
 dc.w $0538 ; $1ba
 dc.w $0538 ; $1bb
 dc.w $0538 ; $1bc
 dc.w $0538 ; $1bd
 dc.w $0538 ; $1be
 dc.w $0538 ; $1bf
 dc.w $0538 ; $1c0
 dc.w $0538 ; $1c1
 dc.w $0538 ; $1c2
 dc.w $0538 ; $1c3
 dc.w $0538 ; $1c4
 dc.w $0538 ; $1c5
 dc.w $0538 ; $1c6
 dc.w $0538 ; $1c7
 dc.w $0538 ; $1c8
 dc.w $0538 ; $1c9
 dc.w $0538 ; $1ca
 dc.w $0538 ; $1cb
 dc.w $0538 ; $1cc
 dc.w $0538 ; $1cd
 dc.w $0538 ; $1ce
 dc.w $0538 ; $1cf
 dc.w $0538 ; $1d0
 dc.w $0538 ; $1d1
 dc.w $0538 ; $1d2
 dc.w $0538 ; $1d3
 dc.w $0538 ; $1d4
 dc.w $0538 ; $1d5
 dc.w $0538 ; $1d6
 dc.w $0538 ; $1d7
 dc.w $0538 ; $1d8
 dc.w $0538 ; $1d9
 dc.w $0538 ; $1da
 dc.w $0538 ; $1db
 dc.w $0538 ; $1dc
 dc.w $0538 ; $1dd
 dc.w $0538 ; $1de
 dc.w $0538 ; $1df
 dc.w $0538 ; $1e0
 dc.w $0538 ; $1e1
 dc.w $0538 ; $1e2
 dc.w $0538 ; $1e3
 dc.w $0538 ; $1e4
 dc.w $0538 ; $1e5
 dc.w $0538 ; $1e6
 dc.w $0538 ; $1e7
 dc.w $0538 ; $1e8
 dc.w $0538 ; $1e9
 dc.w $0538 ; $1ea
 dc.w $0538 ; $1eb
 dc.w $0538 ; $1ec
 dc.w $0538 ; $1ed
 dc.w $0538 ; $1ee
 dc.w $0538 ; $1ef
 dc.w $0538 ; $1f0
 dc.w $0538 ; $1f1
 dc.w $0538 ; $1f2
 dc.w $0538 ; $1f3
 dc.w $0538 ; $1f4
 dc.w $0538 ; $1f5
 dc.w $0538 ; $1f6
 dc.w $0538 ; $1f7
 dc.w $0538 ; $1f8
 dc.w $0538 ; $1f9
 dc.w $0538 ; $1fa
 dc.w $0538 ; $1fb
 dc.w $0538 ; $1fc
 dc.w $0538 ; $1fd
 dc.w $0538 ; $1fe
 dc.w $0538 ; $1ff
 dc.w $0538 ; $200
 dc.w $0538 ; $201
 dc.w $0538 ; $202
 dc.w $0538 ; $203
 dc.w $0538 ; $204
 dc.w $0538 ; $205
 dc.w $0538 ; $206
 dc.w $0538 ; $207
 dc.w $0538 ; $208
 dc.w $0538 ; $209
 dc.w $0538 ; $20a
 dc.w $0538 ; $20b
 dc.w $0538 ; $20c
 dc.w $0538 ; $20d
 dc.w $0538 ; $20e
 dc.w $0538 ; $20f
 dc.w $0538 ; $210
 dc.w $0538 ; $211
 dc.w $0538 ; $212
 dc.w $0538 ; $213
 dc.w $0538 ; $214
 dc.w $0538 ; $215
 dc.w $0538 ; $216
 dc.w $0538 ; $217
 dc.w $0538 ; $218
 dc.w $0538 ; $219
 dc.w $0538 ; $21a
 dc.w $0538 ; $21b
 dc.w $0538 ; $21c
 dc.w $0538 ; $21d
 dc.w $0538 ; $21e
 dc.w $0538 ; $21f
 dc.w $0538 ; $220
 dc.w $0538 ; $221
 dc.w $0538 ; $222
 dc.w $0538 ; $223
 dc.w $0538 ; $224
 dc.w $0538 ; $225
 dc.w $0538 ; $226
 dc.w $0538 ; $227
 dc.w $0538 ; $228
 dc.w $0538 ; $229
 dc.w $0538 ; $22a
 dc.w $0538 ; $22b
 dc.w $0538 ; $22c
 dc.w $0538 ; $22d
 dc.w $0538 ; $22e
 dc.w $0538 ; $22f
 dc.w $0538 ; $230
 dc.w $0538 ; $231
 dc.w $0538 ; $232
 dc.w $0538 ; $233

; leaf helpers only. Indirect collision callbacks keep their full saves.
f_saves_init:
 move.l a5,a0
 adda.l #$a716,a0
 move.w #$fc20,2(a0) ; d0-d5/a2, predecrement mask
 move.w #$043f,$122(a0) ; restore at $8a836 + 2
 move.l a5,a0
 adda.l #$b37e,a0
 move.w #$cfd8,2(a0) ; d0-d1/d4-d7/a0-a1/a3-a4
 move.w #$1bf3,$6a(a0) ; restore at $8b3e6 + 2
 rts

; private per-buffer needle keys. Preparation invalidates both buffers.
; Keep all native restore/draw work on a miss; never add a presentation wait.
f_hud_init:
 move.l enhanced_selected(pc),d0
 cmpi.l #3,d0
 bne .done
 bsr f_text_init
 lea f_hud_state(pc),a0
 move.l a5,d0
 addi.l #$25924,d0
 move.l d0,(a0)
 lea f_speed_resume(pc),a0
 move.l a5,d0
 addi.l #$8666,d0
 move.l d0,2(a0)
 lea f_tacho_resume(pc),a0
 addi.l #$92,d0
 move.l d0,2(a0)
 lea f_needle_clear(pc),a0
 move.l a5,d0
 addi.l #$345f4,d0
 move.l d0,2(a0)
 move.l a5,a1
 adda.l #$8636,a1
 lea f_speed(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 move.l a5,a1
 adda.l #$86ac,a1
 lea f_tacho(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
.done:
 rts
f_hud_reset:
 lea f_text_cache(pc),a0
 move.w #512-1,d0
.text:
 clr.l (a0)+
 dbf d0,.text
 lea f_needle_keys(pc),a0
 moveq #7,d0
.clear:
 clr.l (a0)+
 dbf d0,.clear
 rts
f_hud_state: dc.l 0
f_needle_keys: ds.l 8 ; key/valid for speed0, speed1, tacho0, tacho1
f_speed:
 movem.l d0-d2/a0-a2,-(a7)
 lea f_needle_keys(pc),a0
 move.l f_hud_state(pc),a1
 move.w $44e(a1),d0
 cmpi.w #$38a4,d0
 bcs .divide
 move.w #$ff,d0
 bra .key
.divide:
 ext.l d0
 divu.w #$39,d0
.key:
 andi.l #$ffff,d0
 bsr f_needle_check
 bne .draw
 movem.l (a7)+,d0-d2/a0-a2
 rts
.draw:
 addq.l #4,a7
 movem.l (a7)+,d1-d2/a0-a2
 move.l d0,-(a7)
 move.l $408.w,a3
 lea $19ce(a3),a3
 lea $6a2.w,a1
 moveq #0,d6
 moveq #32,d3
 moveq #17,d7
 bsr f_needle_clear
 move.l (a7)+,d0
f_speed_resume:
 jmp $0
f_tacho:
 movem.l d0-d2/a0-a2,-(a7)
 lea f_needle_keys+16(pc),a0
 move.l f_hud_state(pc),a1
 move.w $454(a1),d1
 add.w d1,d1
 move.w $e(a1,d1.w),d1
 ext.l d1
 swap d1
 lsr.l #8,d1
 lsr.l #6,d1
 move.w d1,$32(a1)
 move.w $44e(a1),d0
 ext.l d0
 swap d0
 divu.w d1,d0
 beq .key
 ext.l d0
 divu.w #$53,d0
.key:
 andi.l #$ffff,d0
 bsr f_needle_check
 bne .draw
 movem.l (a7)+,d0-d2/a0-a2
 rts
.draw:
 addq.l #4,a7
 movem.l (a7)+,d1-d2/a0-a2
 move.l d0,-(a7)
 move.l $408.w,a3
 lea $1afc(a3),a3
 lea $7b2.w,a1
 moveq #0,d6
 moveq #32,d3
 moveq #20,d7
 bsr f_needle_clear
 move.l (a7)+,d0
f_tacho_resume:
 jmp $0
f_needle_clear:
 jmp $0
f_needle_check:
 move.l $408.w,d2
 cmpi.l #$6f780,d2
 beq .known
 addq.l #8,a0
 cmpi.l #$77cc0,d2
 bne .miss
.known:
 tst.l 4(a0)
 beq .update
 cmp.l (a0),d0
 beq .hit
.update:
 move.l d0,(a0)
 move.l #1,4(a0)
.miss:
 moveq #1,d2
 rts
.hit:
 moveq #0,d2
 rts

; Cache only the dedicated race clock/rank glyph calls. The odometer shares
; the speed needle's restore rectangle and must keep redrawing. Mirrors contain
; changing object overlays, so their unchanged backgrounds still need clearing.
f_text_init:
 move.l a5,a1
 adda.l #$880e,a1
 lea f_hud_text(pc),a0
 move.w #$4eb9,(a1)
 move.l a0,2(a1)
 move.l a5,a1
 adda.l #$8858,a1
 move.w #$4eb9,(a1)
 move.l a0,2(a1)
 lea f_text_native(pc),a0
 move.l a5,d0
 addi.l #$33740,d0
 move.l d0,2(a0)
 lea f_glyph_native(pc),a0
 move.l a5,d0
 addi.l #$349e0,d0
 move.l d0,2(a0)
 move.l a5,a1
 adda.l #$349d6,a1
 lea f_glyph(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 rts
f_hud_text:
 move.l a0,-(a7)
 lea f_text_active(pc),a0
 st (a0)
 move.l (a7)+,a0
 bsr f_text_native
 move.l a0,-(a7)
 lea f_text_active(pc),a0
 clr.b (a0)
 move.l (a7)+,a0
 rts
f_text_native:
 jmp $0
f_text_active: dc.w 0
f_text_cache: ds.b 2048
f_glyph:
 move.b f_text_active(pc),d6
 beq .draw
 cmpi.w #8,d7
 bne .draw
 movem.l d0/d2/a0/a2,-(a7)
 move.l a3,d0
 andi.w #127,d0
 lsl.w #4,d0
 lea f_text_cache(pc),a2
 adda.w d0,a2
 cmp.l (a2),a3
 bne .update
 cmp.l 4(a2),a1
 bne .update
 cmp.w 8(a2),d4
 bne .update
 movem.l (a7)+,d0/d2/a0/a2
 move.b 7(a1),d1
 addq.l #8,a1
 move.w d4,d5
 lsr.b #4,d5
 move.l #$6270,d6
 move.w #-1,d7
 lea $150(a3),a4
 addq.l #1,a3
 rts
.update:
 move.l a3,(a2)
 move.l a1,4(a2)
 move.w d4,8(a2)
 movem.l (a7)+,d0/d2/a0/a2
.draw:
 move.l a3,a4
 subq.w #1,d7
 move.l #$6270,d6
f_glyph_native:
 jmp $0

; temporal permutation seed, stable ties retain incoming draw-list order.
; Count changes reset to ordinal order; identities need not persist between lists.
f_sort_init:
 move.l a5,a1
 adda.l #$b37e,a1
 lea f_sort_native(pc),a0
 move.l (a1),(a0)
 move.w 4(a1),4(a0)
 move.l a5,d0
 addi.l #$b384,d0
 move.l d0,8(a0)
 lea f_sort(pc),a0
 move.w #$4ef9,(a1)
 move.l a0,2(a1)
 rts
f_sort_native:
 movem.l d0-d7/a0-a7,-(a7)
 move.l (a0)+,(a1)
 jmp $0
f_sort_count: dc.w 0
f_sort_order: ds.w 64
f_sort:
 movem.l d0-d7/a0-a6,-(a7)
 move.l a0,a3
 move.l (a0),d4
 move.l d4,d5
 moveq #0,d7
.count:
 cmpi.w #-1,2(a3)
 beq .counted
 move.l (a3),d0
 cmp.l d4,d0
 bge .minimum
 move.l d0,d4
.minimum:
 cmp.l d5,d0
 ble .maximum
 move.l d0,d5
.maximum:
 addq.l #4,a3
 addq.w #1,d7
 cmpi.w #64,d7
 bcs .count
 bra .native
.counted:
 sub.l d4,d5
 bmi .native ; native subtraction-sign ordering is not transitive across overflow
 cmpi.w #2,d7
 bcs .native
 lea f_sort_count(pc),a3
 cmp.w (a3),d7
 beq .seeded
 move.w d7,(a3)+
 moveq #0,d0
.reset:
 move.w d0,(a3)+
 addq.w #1,d0
 cmp.w d7,d0
 bcs .reset
.seeded:
 lea f_sort_order(pc),a3
 add.w d7,d7
 moveq #2,d4
.insert:
 move.w (a3,d4.w),d0
 move.w d0,d1
 lsl.w #2,d1
 move.l (a0,d1.w),d2
 lea (a3,d4.w),a4
 move.w d4,d5
 lsr.w #1,d5
 subq.w #1,d5
.scan:
 move.w -2(a4),d3
 move.w d3,d6
 lsl.w #2,d6
 cmp.l (a0,d6.w),d2
 bmi .shift
 bne .put
 cmp.w d3,d0
 bcc .put
.shift:
 move.w d3,(a4)
 subq.l #2,a4
 dbf d5,.scan
.put:
 move.w d0,(a4)
 addq.w #2,d4
 cmp.w d7,d4
 bcs .insert
 lsr.w #1,d7
 subq.w #1,d7
.publish:
 move.w (a3)+,d0
 move.w d0,(a2)+
 lsl.w #2,d0
 move.l (a0,d0.w),(a1)+
 dbf d7,.publish
 move.l #-1,(a1)
 move.w #-1,(a2)
 movem.l (a7)+,d0-d7/a0-a6
 rts
.native:
 movem.l (a7)+,d0-d7/a0-a6
 bra f_sort_native
