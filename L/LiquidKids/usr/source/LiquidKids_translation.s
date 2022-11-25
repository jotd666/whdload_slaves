; Liquid Kids; Translation routine coded by Cfou! 12/11/05 v1.5

 include libraries/lowlevel.i

_Patch_Txt_File_4B0
 movem.l d0-a6,-(a7)
 bsr _GetLang
 lea _TXT_Table_Outro(pc),a0
 move.l #$ff,d5  ; first end text octet
 move.l #$ff,d6  ; second end text octet
 bsr _replaceTXT
 lea $de92,a0
 lea $f692,a1
 clr.b (a1)

.enc
 cmp.l a0,a1
 beq .fin
 cmp.b #$a,(a0)+
 bne .enc
 clr.b -1(a0)
 bra .enc
.fin
 movem.l (a7)+,d0-a6
 rts


_Patch_Txt_File_5AE
 movem.l d0-a6,-(a7)
 bsr _GetLang
 lea _TXT_Table_File_5AE(pc),a0
 move.l #$00,d5  ; first end text octet
 move.l #$ff,d6  ; second end text octet
 bsr _replaceTXT  
 movem.l (a7)+,d0-a6
 rts

_Patch_Txt_File_4DB
 movem.l d0-a6,-(a7)
 bsr _GetLang
 lea _TXT_Table_File_4DB(pc),a0
 move.l #$00,d5  ; first end text octet
 move.l #$ff,d6  ; second end text octet
 bsr _replaceTXT
 movem.l (a7)+,d0-a6
 rts

_Patch_Txt_File_4E8
 movem.l d0-a6,-(a7)
 bsr _GetLang
 lea _TXT_Table_File_4E8(pc),a0
 move.l #$00,d5  ; first end text octet
 move.l #$ff,d6  ; second end text octet
 bsr _replaceTXT
 movem.l (a7)+,d0-a6
 rts

_Patch_Txt_Intro
 movem.l d0-a6,-(a7)
 bsr _GetLang
 lea _TXT_Table_Intro(pc),a0
 move.l #$00,d5  ; first end text octet
 move.l #$ff,d6  ; second end text octet
 bsr _replaceTXT
 movem.l (a7)+,d0-a6
 rts

_GetLang
      move.l _language(pc),d0    
      move.l _forced_language(pc),d1
      tst.l d1
      bne .noauto
      lea _forced_language(pc),a0
      cmp.l #LANG_ENGLISH,d0
      bne .next
      move.l #_custom2_ENGLISH,(a0)
      bra .noauto
.next
      cmp.l #LANG_AMERICAN,d0
      bne .next2
      move.l #_custom2_ENGLISH,(a0)
      bra .noauto
.next2
      cmp.l #LANG_GERMAN,d0
      bne .next3
      move.l #_custom2_GERMAN,(a0)
      bra .noauto
.next3
      cmp.l #LANG_FRENCH,d0
      bne .next4
      move.l #_custom2_FRENCH,(a0)
      bra .noauto
.next4
      move.l #_custom2_ENGLISH,(a0)  ; default language
.noauto
      rts

_custom2_ENGLISH=1
_custom2_FRENCH=2
_custom2_GERMAN=3
_custom2_POLISH=4

_replaceTXT
 move.l _forced_language(pc),d7
 cmp.l #_custom2_ENGLISH,d7 ; English?
 beq .ok
 cmp.l #_custom2_FRENCH,d7  ; French?
 beq .ok
 cmp.l #_custom2_GERMAN,d7  ; German?
 beq .ok
 cmp.l #_custom2_POLISH,d7  ; Polish?
 beq .ok
 bra .fin
.ok
 lsl.l #2,d7
 move.l a0,a1

.next
 move.l a0,a2
 move.l (a1)+,d0    ; a1 ; courant text
 tst.l d0
 beq .fin
 add.l d0,a2        ; a2 ; start text table
 move.l a2,a4
 move.l (a2),a3     ; dest adr

 move.l (a2,d7.l),d0
 add.l  d0,a4       ; source test

.enc
  move.b (a3),d0
  cmp.b d5,d0       ; $00 End type 1?
  beq .next
  cmp.b d6,d0       ; $ff End type 2?
  beq .next
  move.b (a4)+,(a3)+
  bra .enc

.fin
 rts
   

;----------------- Table intro 0
_TXT_Table_Intro
 dc.l _TXT_Intro_1-_TXT_Table_Intro
 dc.l _TXT_Intro_2-_TXT_Table_Intro
 dc.l _TXT_Intro_3-_TXT_Table_Intro
 dc.l _TXT_Intro_4-_TXT_Table_Intro
 dc.l _TXT_Intro_5-_TXT_Table_Intro
 dc.l _TXT_Intro_6-_TXT_Table_Intro
 dc.l _TXT_Intro_7-_TXT_Table_Intro
 dc.l _TXT_Intro_8-_TXT_Table_Intro
 dc.l _TXT_Intro_9-_TXT_Table_Intro
 dc.l _TXT_Intro_10-_TXT_Table_Intro
 dc.l _TXT_Intro_11-_TXT_Table_Intro
 dc.l _TXT_Intro_12-_TXT_Table_Intro
 dc.l 0

; Intro 0 Texts 
_TXT_Intro_1  ; intro 
 dc.l $7084b 
 dc.l _TXT_Intro_1_en-_TXT_Intro_1 
 dc.l _TXT_Intro_1_fr-_TXT_Intro_1 
 dc.l _TXT_Intro_1_de-_TXT_Intro_1 
 dc.l _TXT_Intro_1_po-_TXT_Intro_1,0 
_TXT_Intro_2  ; intro 
 dc.l $7095c 
 dc.l _TXT_Intro_2_en-_TXT_Intro_2 
 dc.l _TXT_Intro_2_fr-_TXT_Intro_2 
 dc.l _TXT_Intro_2_de-_TXT_Intro_2 
 dc.l _TXT_Intro_2_po-_TXT_Intro_2,0 
_TXT_Intro_3  ; intro 
 dc.l $70986 
 dc.l _TXT_Intro_3_en-_TXT_Intro_3 
 dc.l _TXT_Intro_3_fr-_TXT_Intro_3 
 dc.l _TXT_Intro_3_de-_TXT_Intro_3 
 dc.l _TXT_Intro_3_po-_TXT_Intro_3,0 
_TXT_Intro_1_en 
 dc.b "  CONGRATULATIONS!  ",0 ; here English translation 
_TXT_Intro_2_en 
 dc.b " YOU'VE BOUGHT THIS ",0 ; here English translation 
_TXT_Intro_3_en 
 dc.b "       GAME.        ",0 ; here English translation 
 dc.b 0 
_TXT_Intro_1_fr 
 dc.b "   FELICITATIONS!   ",0 ; For Cfou! French Translation 
_TXT_Intro_2_fr 
 dc.b "  VOUS AVEZ ACHETE  ",0 ; For Cfou! French Translation 
_TXT_Intro_3_fr 
 dc.b "      CE JEU.       ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_Intro_1_de 
 dc.b "    Gluckwunsch     ",0 ; =>ok For Ber german Translation
_TXT_Intro_2_de 
 dc.b " Sie haben folgendes",0 ; =>ok For Bert german Translation 
_TXT_Intro_3_de 
 dc.b "   gekauft Spiel    ",0 ; =>ok For Bert german Translation 
 dc.b 0 
_TXT_Intro_1_po 
 dc.b "    GRATULUJEMY!    ",0 ;  For polish Translation 
_TXT_Intro_2_po 
 dc.b "     ZAKUPU TEJ     ",0 ;  For polish Translation 
_TXT_Intro_3_po 
 dc.b "       GRY.         ",0 ;  For polish Translation 
 dc.b 0 
 even 
 
_TXT_Intro_4  ; intro 
 dc.l $709b0 
 dc.l _TXT_Intro_4_en-_TXT_Intro_4 
 dc.l _TXT_Intro_4_fr-_TXT_Intro_4 
 dc.l _TXT_Intro_4_de-_TXT_Intro_4 
 dc.l _TXT_Intro_4_po-_TXT_Intro_4,0 
_TXT_Intro_4_en 
 dc.b "IT'S A GOOD CHOICE !" ; here English translation 
 dc.b 0 
_TXT_Intro_4_fr 
 dc.b "C'EST UN BON CHOIX !" ; For Cfou! French Translation 
 dc.b 0 
_TXT_Intro_4_de 
 dc.b "ES IST DIE GUTE WAHL" ; =>OK german Translation 
 dc.b 0 
_TXT_Intro_4_po 
 dc.b " BYL TO DOBRY WYBOR " ;  For polish Translation 
 dc.b 0 
 even 
_TXT_Intro_5  ; intro 
 dc.l $70a82 
 dc.l _TXT_Intro_5_en-_TXT_Intro_5 
 dc.l _TXT_Intro_5_fr-_TXT_Intro_5 
 dc.l _TXT_Intro_5_de-_TXT_Intro_5 
 dc.l _TXT_Intro_5_po-_TXT_Intro_5,0 
_TXT_Intro_6  ; intro
 dc.l $70aac 
 dc.l _TXT_Intro_6_en-_TXT_Intro_6 
 dc.l _TXT_Intro_6_fr-_TXT_Intro_6 
 dc.l _TXT_Intro_6_de-_TXT_Intro_6 
 dc.l _TXT_Intro_6_po-_TXT_Intro_6,0 
_TXT_Intro_7  ; intro 
 dc.l $70b2a 
 dc.l _TXT_Intro_7_en-_TXT_Intro_7 
 dc.l _TXT_Intro_7_fr-_TXT_Intro_7 
 dc.l _TXT_Intro_7_de-_TXT_Intro_7 
 dc.l _TXT_Intro_7_po-_TXT_Intro_7,0 
_TXT_Intro_8  ; intro 
 dc.l $70b54 
 dc.l _TXT_Intro_8_en-_TXT_Intro_8 
 dc.l _TXT_Intro_8_fr-_TXT_Intro_8 
 dc.l _TXT_Intro_8_de-_TXT_Intro_8 
 dc.l _TXT_Intro_8_po-_TXT_Intro_8,0 
_TXT_Intro_5_en 
 dc.b "      This is       ",0 ; here English translation 
_TXT_Intro_6_en 
 dc.b "    a product of    ",0 ; here English translation 
_TXT_Intro_7_en 
 dc.b "  from the famous   ",0 ; here English translation 
_TXT_Intro_8_en 
 dc.b " TAITO arcade game  ",0 ; here English translation 
 dc.b 0 
_TXT_Intro_5_fr 
 dc.b "       C'est        ",0 ; For Cfou! French Translation 
_TXT_Intro_6_fr 
 dc.b "  une production d' ",0 ; For Cfou! French Translation 
_TXT_Intro_7_fr 
 dc.b "basee sur le fameux ",0 ; For Cfou! French Translation 
_TXT_Intro_8_fr 
 dc.b " jeu d'arcade TAITO ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_Intro_5_de 
 dc.b "      Das ist       ",0 ; =>ok For german Translation 
_TXT_Intro_6_de 
 dc.b "  ein produkt von   ",0 ; =>ok For german Translation 
_TXT_Intro_7_de 
 dc.b " von den beruhmten  ",0 ; =>ok For german Translation
_TXT_Intro_8_de 
 dc.b " TAITO Arcade Spiel ",0 ; =>ok For german Translation 
 dc.b 0 
_TXT_Intro_5_po 
 dc.b "        Oto         ",0 ;=>OK  For polish Translation 
_TXT_Intro_6_po 
 dc.b "       produkt      ",0 ;=>OK  For polish Translation 
_TXT_Intro_7_po 
 dc.b "bazujacy na slynnej ",0 ;=>OK  For polish Translation 
_TXT_Intro_8_po 
 dc.b "grze arcade od TAITO",0 ;=>OK  For polish Translation 
 dc.b 0 
 even 
 
_TXT_Intro_9  ; intro 
 dc.l $70c26 
 dc.l _TXT_Intro_9_en-_TXT_Intro_9 
 dc.l _TXT_Intro_9_fr-_TXT_Intro_9 
 dc.l _TXT_Intro_9_de-_TXT_Intro_9 
 dc.l _TXT_Intro_9_po-_TXT_Intro_9,0 
_TXT_Intro_9_en 
 dc.b "   - DEVELOPERS -   " ; here English translation 
 dc.b 0 
_TXT_Intro_9_fr 
 dc.b "  - DEVELOPPEURS -  " ; For Cfou! French Translation 
 dc.b 0 
_TXT_Intro_9_de 
 dc.b "   - Entwickler -   " ;  =>ok For german Translation 
 dc.b 0 
_TXT_Intro_9_po 
 dc.b "  - DEVELOPERZY -   " ;  For polish Translation 
 dc.b 0 
 even 
 
_TXT_Intro_10  ; intro 
 dc.l $70c7a 
 dc.l _TXT_Intro_10_en-_TXT_Intro_10 
 dc.l _TXT_Intro_10_fr-_TXT_Intro_10 
 dc.l _TXT_Intro_10_de-_TXT_Intro_10 
 dc.l _TXT_Intro_10_po-_TXT_Intro_10,0 
_TXT_Intro_10_en 
 dc.b "      Coders:       " ; here English translation 
 dc.b 0 
_TXT_Intro_10_fr 
 dc.b "   Programmeurs:    " ; For Cfou! French Translation 
 dc.b 0 
_TXT_Intro_10_de 
 dc.b "   Programmierer:   " ;  =>ok For german Translation 
 dc.b 0 
_TXT_Intro_10_po 
 dc.b "   Programowanie:   " ;  For polish Translation 
 dc.b 0 
 even 
 
_TXT_Intro_11  ; intro 
 dc.l $70db5 
 dc.l _TXT_Intro_11_en-_TXT_Intro_11 
 dc.l _TXT_Intro_11_fr-_TXT_Intro_11 
 dc.l _TXT_Intro_11_de-_TXT_Intro_11 
 dc.l _TXT_Intro_11_po-_TXT_Intro_11,0 
_TXT_Intro_11_en 
 dc.b "  Graphic Artist:   " ; here English translation 
 dc.b 0 
_TXT_Intro_11_fr 
 dc.b " Artiste graphiste: " ; For Cfou! French Translation 
 dc.b 0 
_TXT_Intro_11_de
 dc.b "     Grafiker:      " ;  =>ok For german Translation 
 dc.b 0 
_TXT_Intro_11_po 
 dc.b "     Grafika:       " ;  For polish Translation 
 dc.b 0 
 even 
_TXT_Intro_12  ; intro 
 dc.l $70ec6 
 dc.l _TXT_Intro_12_en-_TXT_Intro_12 
 dc.l _TXT_Intro_12_fr-_TXT_Intro_12 
 dc.l _TXT_Intro_12_de-_TXT_Intro_12 
 dc.l _TXT_Intro_12_po-_TXT_Intro_12,0 
_TXT_Intro_12_en 
 dc.b "  Music & Sound:    " ; here English translation 
 dc.b 0 
_TXT_Intro_12_fr 
 dc.b "   Musique & Son:   " ; For Cfou! French Translation 
 dc.b 0 
_TXT_Intro_12_de 
 dc.b "   Musik & Sound:   " ;  =>ok For german Translation 
 dc.b 0 
_TXT_Intro_12_po 
 dc.b " Muzyka & Dzwieki:  " ;  For polish Translation 
 dc.b 0 
 even 
 
;***************************************** 
;----------------- Table intro1 
_TXT_Table_File_4DB 
 dc.l _TXT_File_4DB_1-_TXT_Table_File_4DB 
 dc.l _TXT_File_4DB_2-_TXT_Table_File_4DB 
 dc.l _TXT_File_4DB_3-_TXT_Table_File_4DB 
 dc.l _TXT_File_4DB_4-_TXT_Table_File_4DB 
 dc.l _TXT_File_4DB_5-_TXT_Table_File_4DB 
 dc.l _TXT_File_4DB_6-_TXT_Table_File_4DB 
 dc.l 0 
; File 4db Texts 
_TXT_File_4DB_1  ; intro 
 dc.l $6c090 
 dc.l _TXT_File_4DB_1_en-_TXT_File_4DB_1 
 dc.l _TXT_File_4DB_1_fr-_TXT_File_4DB_1 
 dc.l _TXT_File_4DB_1_de-_TXT_File_4DB_1 
 dc.l _TXT_File_4DB_1_po-_TXT_File_4DB_1,0 
_TXT_File_4DB_1_en 
 dc.b " PEACEFUL WOODY-LAKE ....    ",0 ; here English translation 
 dc.b 0 
_TXT_File_4DB_1_fr 
 dc.b " PAISIBLE WOODY-LAKE ....    ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_4DB_1_de 
 dc.b " Friedlicher WOODY-LAKE .... ",0 ; =>ok For german Translation 
 dc.b 0 
_TXT_File_4DB_1_po 
 dc.b " SPOKOJNE WOODY-LAKE ....    ",0 ;  For polish Translation 
 dc.b 0 
 even 
 
_TXT_File_4DB_2 
 dc.l $6c0b0 
 dc.l _TXT_File_4DB_2_en-_TXT_File_4DB_2 
 dc.l _TXT_File_4DB_2_fr-_TXT_File_4DB_2 
 dc.l _TXT_File_4DB_2_de-_TXT_File_4DB_2 
 dc.l _TXT_File_4DB_2_po-_TXT_File_4DB_2,0 
_TXT_File_4DB_3 
 dc.l $6c0d0 
 dc.l _TXT_File_4DB_3_en-_TXT_File_4DB_3 
 dc.l _TXT_File_4DB_3_fr-_TXT_File_4DB_3 
 dc.l _TXT_File_4DB_3_de-_TXT_File_4DB_3 
 dc.l _TXT_File_4DB_3_po-_TXT_File_4DB_3,0 
_TXT_File_4DB_2_en 
 dc.b "DEVIL OF FIRE TOOK WOODY-LAKE",0 ; here English translation 
_TXT_File_4DB_3_en 
 dc.b "        BY SURPRISE           ",0 ; here English translation 
 dc.b 0 
_TXT_File_4DB_2_fr 
 dc.b "  LE DEMON DU FEU ATTAQUE    ",0 ; For Cfou! French Translation 
_TXT_File_4DB_3_fr 
 dc.b "       PAR SURPRISE           ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_4DB_2_de 
 dc.b " FEUERTEUFEL NAHM WOODY-LAKE ",0 ; =>ok For german Translation
_TXT_File_4DB_3_de 
 dc.b "        DURCH UBERRASCHUNG    ",0 ; =>ok For german Translation
 dc.b 0 
_TXT_File_4DB_2_po 
 dc.b " OGNISTY DEMON ZAATAKOWAL    ",0 ;  For polish Translation 
_TXT_File_4DB_3_po 
 dc.b "       Z ZASKOCZENIA          ",0 ;  For polish Translation 
 dc.b 0 
 even 
 
_TXT_File_4DB_4 
 dc.l $6c0f0 
 dc.l _TXT_File_4DB_4_en-_TXT_File_4DB_4 
 dc.l _TXT_File_4DB_4_fr-_TXT_File_4DB_4 
 dc.l _TXT_File_4DB_4_de-_TXT_File_4DB_4 
 dc.l _TXT_File_4DB_4_po-_TXT_File_4DB_4,0 
_TXT_File_4DB_5 
 dc.l $6c110+1 
 dc.l _TXT_File_4DB_5_en-_TXT_File_4DB_5 
 dc.l _TXT_File_4DB_5_fr-_TXT_File_4DB_5 
 dc.l _TXT_File_4DB_5_de-_TXT_File_4DB_5 
 dc.l _TXT_File_4DB_5_po-_TXT_File_4DB_5,0 
_TXT_File_4DB_4_en 
 dc.b "        TRANSMITTED            ",0; here English translation 
_TXT_File_4DB_5_en 
 dc.b "      MIRACULOUS POWER          ",0 ; here English translation 
 dc.b 0 
_TXT_File_4DB_4_fr 
 dc.b "      LE MERVEILLEUX           ",0 ; For Cfou! French Translation 
_TXT_File_4DB_5_fr 
 dc.b "     POUVOIR TRANSMIS           ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_4DB_4_de 
 dc.b "        UBERMITTELT            ",0 ; =>ok For german Translation
_TXT_File_4DB_5_de 
 dc.b "     UBERNATURLICHE MACHT       ",0 ; =>ok For german Translation
 dc.b 0 
_TXT_File_4DB_4_po 
 dc.b "        PRZESYLAJAC            ",0 ;  For polish Translation 
_TXT_File_4DB_5_po 
 dc.b "       CUDOWNE MOCE             ",0 ;  For polish Translation 
 dc.b 0  
 even 
 
;*************************************** 
;----------------- Table intro1b 
_TXT_Table_File_4E8 
 dc.l _TXT_File_4E8_1-_TXT_Table_File_4E8 
 dc.l _TXT_File_4E8_2-_TXT_Table_File_4E8 
 dc.l _TXT_File_4E8_3-_TXT_Table_File_4E8 
 dc.l _TXT_File_4E8_4-_TXT_Table_File_4E8 
 dc.l _TXT_File_4E8_5-_TXT_Table_File_4E8 
 dc.l 0 
 
; File 4E8 Texts 
_TXT_File_4E8_1  ; intro 
 dc.l $20002 
 dc.l _TXT_File_4E8_1_en-_TXT_File_4E8_1 
 dc.l _TXT_File_4E8_1_fr-_TXT_File_4E8_1 
 dc.l _TXT_File_4E8_1_de-_TXT_File_4E8_1 
 dc.l _TXT_File_4E8_1_po-_TXT_File_4E8_1,0 
_TXT_File_4E8_2  ; intro 
 dc.l $20044 
 dc.l _TXT_File_4E8_2_en-_TXT_File_4E8_2 
 dc.l _TXT_File_4E8_2_fr-_TXT_File_4E8_2 
 dc.l _TXT_File_4E8_2_de-_TXT_File_4E8_2 
 dc.l _TXT_File_4E8_2_po-_TXT_File_4E8_2,0 
_TXT_File_4E8_3  ; intro 
 dc.l $20086 
 dc.l _TXT_File_4E8_3_en-_TXT_File_4E8_3 
 dc.l _TXT_File_4E8_3_fr-_TXT_File_4E8_3 
 dc.l _TXT_File_4E8_3_de-_TXT_File_4E8_3 
 dc.l _TXT_File_4E8_3_po-_TXT_File_4E8_3,0 
_TXT_File_4E8_4  ; intro 
 dc.l $200c8 
 dc.l _TXT_File_4E8_4_en-_TXT_File_4E8_4 
 dc.l _TXT_File_4E8_4_fr-_TXT_File_4E8_4 
 dc.l _TXT_File_4E8_4_de-_TXT_File_4E8_4 
 dc.l _TXT_File_4E8_4_po-_TXT_File_4E8_4,0 
_TXT_File_4E8_5  ; intro 
 dc.l $20108+2 
 dc.l _TXT_File_4E8_5_en-_TXT_File_4E8_5 
 dc.l _TXT_File_4E8_5_fr-_TXT_File_4E8_5 
 dc.l _TXT_File_4E8_5_de-_TXT_File_4E8_5 
 dc.l _TXT_File_4E8_5_po-_TXT_File_4E8_5,0 
_TXT_File_4E8_1_en 
 dc.b "    THE SAVIOUR  'HIPOPO'     ",0 ; here English translation 
_TXT_File_4E8_2_en     
 dc.b "     ATTACKS THE DEVIL        ",0 ; here English translation 
_TXT_File_4E8_3_en 
 dc.b "    TO RESCUE HIS TRIBE       ",0 ; here English translation 
_TXT_File_4E8_4_en 
 dc.b "    AND SAVE HIS LOVER        ",0 ; here English translation 
_TXT_File_4E8_5_en 
 dc.b "         'TAMASUN'...         ",0 ; here English translation 
 dc.b 0 
_TXT_File_4E8_1_fr 
 dc.b "    LE SAUVEUR  'HIPOPO'      ",0 ; For Cfou! French Translation 
_TXT_File_4E8_2_fr 
 dc.b "      ATTAQUE LE DEMON        ",0 ; For Cfou! French Translation 
_TXT_File_4E8_3_fr 
 dc.b "   POUR DELIVRER SA TRIBU     ",0 ; For Cfou! French Translation 
_TXT_File_4E8_4_fr 
 dc.b " ET SAUVER SON AMOUREUSE      ",0 ; For Cfou! French Translation 
_TXT_File_4E8_5_fr 
 dc.b "         'TAMASUN'...         ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_4E8_1_de 
 dc.b "    DER RETTER 'HIPOPO'       ",0 ; =>ok For german Translation
_TXT_File_4E8_2_de 
 dc.b "    GREIFT DEN TEUFEL AN      ",0 ; =>ok For german Translation
_TXT_File_4E8_3_de 
 dc.b "  UM SEINEN STAMM ZU RETTEN   ",0 ; =>ok For german Translation
_TXT_File_4E8_4_de 
 dc.b "  UND RETTET SEINE GELIEBTE   ",0 ; =>ok For german Translation
_TXT_File_4E8_5_de 
 dc.b "         'TAMASUN'...         ",0 ; =>ok For german Translation 
 dc.b 0 
_TXT_File_4E8_1_po 
 dc.b "      ODWAZNY  'HIPOPO'       ",0 ; For polish Translation 
_TXT_File_4E8_2_po 
 dc.b "       ATAKUJE DEMONA         ",0 ; For polish Translation 
_TXT_File_4E8_3_po 
 dc.b "   CHCAC RATOWAC SWOJ LUD     ",0 ; For polish Translation 
_TXT_File_4E8_4_po 
 dc.b " ORAZ UWOLNIC SWA UKOCHANA    ",0 ; For polish Translation 
_TXT_File_4E8_5_po 
 dc.b "         'TAMASUN'...         ",0 ; For polish Translation 
 dc.b 0 
 even 
  
;*************************************** 
_TXT_File_4DB_6 
 dc.l $6c220 
 dc.l _TXT_File_4DB_6_en-_TXT_File_4DB_6 
 dc.l _TXT_File_4DB_6_fr-_TXT_File_4DB_6 
 dc.l _TXT_File_4DB_6_de-_TXT_File_4DB_6 
 dc.l _TXT_File_4DB_6_po-_TXT_File_4DB_6,0 
_TXT_File_4DB_6_en 
 dc.b "PRESS FIRE TO START" ; here English translation 
 dc.b 0 
_TXT_File_4DB_6_fr 
 dc.b " FIRE POUR DEBUTER " ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_4DB_6_de 
 dc.b "FEUER ZUM BEGINNEN " ; =>ok For german Translation 
 dc.b 0 
_TXT_File_4DB_6_po 
 dc.b "FIRE ABY ROZPOCZAC " ; For polish Translation 
 dc.b 0 
 even 
 
 
;---------------------- 
;----------------- Table ingame 
_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_1-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_2-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_3-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_4-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_5-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_6-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_7-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_8-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_9-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_10-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_11-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_12-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_13-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_14-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_15-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_16-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_17-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_18-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_19-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_20-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_21-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_22-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_23-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_24-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_25-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_26-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_27-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_28-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_29-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_30-_TXT_Table_File_5AE 
 dc.l _TXT_File_5AE_31-_TXT_Table_File_5AE 
 dc.l 0 
 
; File 5AE Texts 
_TXT_File_5AE_1  ; in game 
 dc.l $23396 
 dc.l _TXT_File_5AE_1_en-_TXT_File_5AE_1 
 dc.l _TXT_File_5AE_1_fr-_TXT_File_5AE_1 
 dc.l _TXT_File_5AE_1_de-_TXT_File_5AE_1 
 dc.l _TXT_File_5AE_1_po-_TXT_File_5AE_1,0 
_TXT_File_5AE_1_en 
 dc.b "  SCORE   ROUND   NAME" ; here English translation 
 dc.b 0 
_TXT_File_5AE_1_fr 
 dc.b "  SCORE   ETAPE   NOM " ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_1_de 
 dc.b "  KERBE   RUND    NAME" ; =>OK german Translation if possible 
 dc.b 0 
_TXT_File_5AE_1_po 
 dc.b "  WYNIK   RUNDA  NAZWA" ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_2  ; in game 
 dc.l $3c1e8 
 dc.l _TXT_File_5AE_2_en-_TXT_File_5AE_2 
 dc.l _TXT_File_5AE_2_fr-_TXT_File_5AE_2 
 dc.l _TXT_File_5AE_2_de-_TXT_File_5AE_2 
 dc.l _TXT_File_5AE_2_po-_TXT_File_5AE_2,0 
_TXT_File_5AE_3  ; in game 
 dc.l $3c1f1 
 dc.l _TXT_File_5AE_3_en-_TXT_File_5AE_3 
 dc.l _TXT_File_5AE_3_fr-_TXT_File_5AE_3 
 dc.l _TXT_File_5AE_3_de-_TXT_File_5AE_3 
 dc.l _TXT_File_5AE_3_po-_TXT_File_5AE_3,0 
_TXT_File_5AE_2_en 
 dc.b "SELECT",0        ; here English translation 
_TXT_File_5AE_3_en 
 dc.b "EITHER DOOR !",0 ; here English translation 
 dc.b 0 
_TXT_File_5AE_2_fr 
 dc.b "CHOISI",0        ; For Cfou! French Translation 
_TXT_File_5AE_3_fr 
 dc.b " UNE PORTE ! ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_2_de 
 dc.b "WHALEN",0        ; =>ok For german Translation 
_TXT_File_5AE_3_de 
 dc.b "SIE JEDE TUR!",0 ; =>ok german Translation 
 dc.b 0 
_TXT_File_5AE_2_po 
 dc.b "WEJDZ ",0        ; For Polish Translation 
_TXT_File_5AE_3_po 
 dc.b "  W DRZWI !  ",0 ; For Polish Translation 
 even 
 
_TXT_File_5AE_4  ; in game 
 dc.l $3c201 
 dc.l _TXT_File_5AE_4_en-_TXT_File_5AE_4 
 dc.l _TXT_File_5AE_4_fr-_TXT_File_5AE_4 
 dc.l _TXT_File_5AE_4_de-_TXT_File_5AE_4 
 dc.l _TXT_File_5AE_4_po-_TXT_File_5AE_4,0 
_TXT_File_5AE_5  ; in game 
 dc.l $3c211 
 dc.l _TXT_File_5AE_5_en-_TXT_File_5AE_5 
 dc.l _TXT_File_5AE_5_fr-_TXT_File_5AE_5 
 dc.l _TXT_File_5AE_5_de-_TXT_File_5AE_5 
 dc.l _TXT_File_5AE_5_po-_TXT_File_5AE_5,0 
_TXT_File_5AE_4_en 
 dc.b "AT WHICH DOOR",0  ; here English translation 
_TXT_File_5AE_5_en 
 dc.b "DO YOU ENTER ?",0 ; here English translation 
 dc.b 0 
_TXT_File_5AE_4_fr 
 dc.b "QUELLE PORTE ",0  ; For Cfou! French Translation 
_TXT_File_5AE_5_fr 
 dc.b " CHOISIS-TU ? ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_4_de 
 dc.b " WELCHE TUR  ",0 ; =>OK german Translation 
_TXT_File_5AE_5_de 
 dc.b "BETRETEN SIE? ",0 ; =>OK german Translation 
 dc.b 0 
_TXT_File_5AE_4_po 
 dc.b " KTORE DRZWI ",0 ;  For Polish Translation 
_TXT_File_5AE_5_po 
 dc.b " WYBIERASZ ?  ",0 ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_6  ; in game 
 dc.l $3c222 
 dc.l _TXT_File_5AE_6_en-_TXT_File_5AE_6 
 dc.l _TXT_File_5AE_6_fr-_TXT_File_5AE_6 
 dc.l _TXT_File_5AE_6_de-_TXT_File_5AE_6 
 dc.l _TXT_File_5AE_6_po-_TXT_File_5AE_6,0 
_TXT_File_5AE_7  ; in game 
 dc.l $3c22e 
 dc.l _TXT_File_5AE_7_en-_TXT_File_5AE_7 
 dc.l _TXT_File_5AE_7_fr-_TXT_File_5AE_7 
 dc.l _TXT_File_5AE_7_de-_TXT_File_5AE_7 
 dc.l _TXT_File_5AE_7_po-_TXT_File_5AE_7,0 
_TXT_File_5AE_6_en 
 dc.b "DASH INTO",0        ; here English translation 
_TXT_File_5AE_7_en 
 dc.b "THE NEXT ROUND !",0 ; here English translation 
 dc.b 0 
_TXT_File_5AE_6_fr 
 dc.b " COURS A ",0        ; For Cfou! French Translation 
_TXT_File_5AE_7_fr 
 dc.b "L'ETAPE SUIVANTE",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_6_de 
 dc.b "LAUFT ZUR",0        ; =>OK german Translation 
_TXT_File_5AE_7_de 
 dc.b "FOLGENDEN ETAPPE",0 ; =>OK german Translation 
 dc.b 0 
_TXT_File_5AE_6_po 
 dc.b " SKACZ W ",0        ;  For Polish Translation 
_TXT_File_5AE_7_po 
 dc.b "NASTEPNA RUNDE !",0 ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_8  ; in game 
 dc.l $3c241 
 dc.l _TXT_File_5AE_8_en-_TXT_File_5AE_8 
 dc.l _TXT_File_5AE_8_fr-_TXT_File_5AE_8 
 dc.l _TXT_File_5AE_8_de-_TXT_File_5AE_8 
 dc.l _TXT_File_5AE_8_po-_TXT_File_5AE_8,0 
_TXT_File_5AE_9  ; in game 
 dc.l $3c24c 
 dc.l _TXT_File_5AE_9_en-_TXT_File_5AE_9 
 dc.l _TXT_File_5AE_9_fr-_TXT_File_5AE_9 
 dc.l _TXT_File_5AE_9_de-_TXT_File_5AE_9 
 dc.l _TXT_File_5AE_9_po-_TXT_File_5AE_9,0 
_TXT_File_5AE_8_en 
 dc.b "WHICH IS",0        ; here English translation 
_TXT_File_5AE_9_en 
 dc.b "A SHORTER WAY ?",0 ; here English translation 
 dc.b 0 
_TXT_File_5AE_8_fr 
 dc.b " EST-CE ",0        ; For Cfou! French Translation 
_TXT_File_5AE_9_fr 
 dc.b "UN RACCOURCI ? ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_8_de 
 dc.b " WELCHES",0        ;  For Bert german Translation 
_TXT_File_5AE_9_de 
 dc.b " IST DER WEG ? ",0 ; MORE LONGER german Translation 
 dc.b 0 
_TXT_File_5AE_8_po 
 dc.b "KTOREDY ",0        ;  For Polish Translation 
_TXT_File_5AE_9_po 
 dc.b " KROCEJ ?      ",0 ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_10  ; in game 
 dc.l $3c25e 
 dc.l _TXT_File_5AE_10_en-_TXT_File_5AE_10 
 dc.l _TXT_File_5AE_10_fr-_TXT_File_5AE_10 
 dc.l _TXT_File_5AE_10_de-_TXT_File_5AE_10 
 dc.l _TXT_File_5AE_10_po-_TXT_File_5AE_10,0 
_TXT_File_5AE_11  ; in game 
 dc.l $3c268 
 dc.l _TXT_File_5AE_11_en-_TXT_File_5AE_11 
 dc.l _TXT_File_5AE_11_fr-_TXT_File_5AE_11 
 dc.l _TXT_File_5AE_11_de-_TXT_File_5AE_11 
 dc.l _TXT_File_5AE_11_po-_TXT_File_5AE_11,0 
_TXT_File_5AE_10_en 
 dc.b "NEXT IS",0         ; here English translation 
_TXT_File_5AE_11_en 
 dc.b "THE FINAL ROUND",0 ; here English translation 
 dc.b 0 
_TXT_File_5AE_10_fr 
 dc.b " C'EST ",0         ; For Cfou! French Translation 
_TXT_File_5AE_11_fr 
 dc.b "L'ETAPE FINALE ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_10_de 
 dc.b "ES IST ",0         ; =>ok german Translation 
_TXT_File_5AE_11_de 
 dc.b "DIE LETZTE RUND",0 ; =>ok german Translation 
 dc.b 0 
_TXT_File_5AE_10_po 
 dc.b " DALEJ ",0         ;  For Polish Translation 
_TXT_File_5AE_11_po 
 dc.b "OSTATNIA RUNDA ",0 ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_12  ; in game 
 dc.l $3c27a 
 dc.l _TXT_File_5AE_12_en-_TXT_File_5AE_12 
 dc.l _TXT_File_5AE_12_fr-_TXT_File_5AE_12 
 dc.l _TXT_File_5AE_12_de-_TXT_File_5AE_12 
 dc.l _TXT_File_5AE_12_po-_TXT_File_5AE_12,0 
_TXT_File_5AE_12_en 
 dc.b "AT LAST !" ; here English translation 
 dc.b 0 
_TXT_File_5AE_12_fr 
 dc.b " ENFIN ! " ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_12_de 
 dc.b "ENDLICH! " ; =>OK german Translation
 dc.b 0 
_TXT_File_5AE_12_po 
 dc.b "WRESZCIE!" ; For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_13  ; in game 
 dc.l $3c286 
 dc.l _TXT_File_5AE_13_en-_TXT_File_5AE_13 
 dc.l _TXT_File_5AE_13_fr-_TXT_File_5AE_13 
 dc.l _TXT_File_5AE_13_de-_TXT_File_5AE_13 
 dc.l _TXT_File_5AE_13_po-_TXT_File_5AE_13,0 
_TXT_File_5AE_14  ; in game 
 dc.l $3c295 
 dc.l _TXT_File_5AE_14_en-_TXT_File_5AE_14 
 dc.l _TXT_File_5AE_14_fr-_TXT_File_5AE_14 
 dc.l _TXT_File_5AE_14_de-_TXT_File_5AE_14 
 dc.l _TXT_File_5AE_14_po-_TXT_File_5AE_14,0 
_TXT_File_5AE_13_en 
 dc.b "ARE YOU SURE",0      ; here English translation 
_TXT_File_5AE_14_en 
 dc.b "OF YOUR VICTORY ?",0 ; here English translation 
 dc.b 0 
_TXT_File_5AE_13_fr 
 dc.b "EST-TU SURE ",0      ; For Cfou! French Translation 
_TXT_File_5AE_14_fr 
 dc.b "DE TA VICTOIRE ? ",0 ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_13_de 
 dc.b " ES DU SAURE",0      ; =>OK german Translation 
_TXT_File_5AE_14_de 
 dc.b "  ZU GEWINNEN ?  ",0 ; =>OK german Translation 
 dc.b 0 
_TXT_File_5AE_13_po 
 dc.b "JESTES PEWNY",0      ;  For Polish Translation 
_TXT_File_5AE_14_po 
 dc.b "SWOJEJ WYGRANEJ ?",0 ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_15  ; in game 
 dc.l $3c2a9 
 dc.l _TXT_File_5AE_15_en-_TXT_File_5AE_15 
 dc.l _TXT_File_5AE_15_fr-_TXT_File_5AE_15 
 dc.l _TXT_File_5AE_15_de-_TXT_File_5AE_15 
 dc.l _TXT_File_5AE_15_po-_TXT_File_5AE_15,0 
_TXT_File_5AE_15_en 
 dc.b "END COMING SOON... " ; here English translation 
 dc.b 0 
_TXT_File_5AE_15_fr 
 dc.b "BIENTOT LA FIN...  " ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_15_de 
 dc.b " BALD DAS ENDE ... " ; =>OK german Translation 
 dc.b 0 
_TXT_File_5AE_15_po 
 dc.b "KONIEC JUZ BLISKI.." ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_16  ; in game 
 dc.l $3c2e0 
 dc.l _TXT_File_5AE_16_en-_TXT_File_5AE_16 
 dc.l _TXT_File_5AE_16_fr-_TXT_File_5AE_16 
 dc.l _TXT_File_5AE_16_de-_TXT_File_5AE_16 
 dc.l _TXT_File_5AE_16_po-_TXT_File_5AE_16,0 
 even 
_TXT_File_5AE_17  ; in game 
 dc.l $3c301 
 dc.l _TXT_File_5AE_17_en-_TXT_File_5AE_17 
 dc.l _TXT_File_5AE_17_fr-_TXT_File_5AE_17 
 dc.l _TXT_File_5AE_17_de-_TXT_File_5AE_17 
 dc.l _TXT_File_5AE_17_po-_TXT_File_5AE_17,0 
_TXT_File_5AE_18  ; in game 
 dc.l $3c322 
 dc.l _TXT_File_5AE_18_en-_TXT_File_5AE_18 
 dc.l _TXT_File_5AE_18_fr-_TXT_File_5AE_18 
 dc.l _TXT_File_5AE_18_de-_TXT_File_5AE_18 
 dc.l _TXT_File_5AE_18_po-_TXT_File_5AE_18,0 
_TXT_File_5AE_19  ; in game 
 dc.l $3c343 
 dc.l _TXT_File_5AE_19_en-_TXT_File_5AE_19 
 dc.l _TXT_File_5AE_19_fr-_TXT_File_5AE_19 
 dc.l _TXT_File_5AE_19_de-_TXT_File_5AE_19 
 dc.l _TXT_File_5AE_19_po-_TXT_File_5AE_19,0 
_TXT_File_5AE_20  ; in game 
 dc.l $3c364 
 dc.l _TXT_File_5AE_20_en-_TXT_File_5AE_20 
 dc.l _TXT_File_5AE_20_fr-_TXT_File_5AE_20 
 dc.l _TXT_File_5AE_20_de-_TXT_File_5AE_20 
 dc.l _TXT_File_5AE_20_po-_TXT_File_5AE_20,0 
_TXT_File_5AE_16_en 
 dc.b " I'VE GONE OVER MOUNTAINS AND ",0 ; here English translation 
_TXT_File_5AE_17_en 
 dc.b "  ACROSSED VALLEYS TO FIND    ",0 ; here English translation 
_TXT_File_5AE_18_en 
 dc.b "  THE WAY TO HERE AT LAST.    ",0 ; here English translation 
_TXT_File_5AE_19_en 
 dc.b " AH, THIS DRAMATIC MOMENT !!  ",0 ; here English translation 
_TXT_File_5AE_20_en 
 dc.b "          HOWEVER ...        ",0  ; here English translation 
 dc.b 0 
_TXT_File_5AE_16_fr 
 dc.b "J'AI ETE PAR DELA LES MONTS ET",0 ; For Cfou! French Translation 
_TXT_File_5AE_17_fr 
 dc.b "A TRAVERS LES VALS ET TROUVER ",0 ; For Cfou! French Translation 
_TXT_File_5AE_18_fr 
 dc.b "LA BONNE ROUTE FINALEMENT ICI.",0 ; For Cfou! French Translation 
_TXT_File_5AE_19_fr 
 dc.b " AH, QUEL MOMENT DRAMATIQUE !!",0 ; For Cfou! French Translation 
_TXT_File_5AE_20_fr 
 dc.b "         CEPENDANT ...       ",0  ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_16_de 
 dc.b " ICH BIN UBER BERGE GEGANGEN  ",0 ; =>OK german Translation
_TXT_File_5AE_17_de 
 dc.b "UND DURCH DORFER UM ZU FINDEN ",0 ; =>ok german Translation
_TXT_File_5AE_18_de 
 dc.b "LETZTENDLICH DEN WEG NACH HIER",0 ; =>OK german Translation 
_TXT_File_5AE_19_de 
 dc.b "AH, DIESER DRAMATISCHE MOMENT!",0 ; =>OK german Translation 
_TXT_File_5AE_20_de 
 dc.b "      WIE AUCH IMMER...      ",0  ; =>OK german Translation 
 
 dc.b 0 
_TXT_File_5AE_16_po 
 dc.b "  PRZEBYLEM GORY I ROWNINY    ",0 ;  For Polish Translation 
_TXT_File_5AE_17_po 
 dc.b "        ABY WRESZCIE          ",0 ;  For Polish Translation 
_TXT_File_5AE_18_po 
 dc.b "       ZNALESC SIE TUTAJ.     ",0 ;  For Polish Translation 
_TXT_File_5AE_19_po 
 dc.b " COZ ZA DRAMATYCZNA CHWILA  !!",0 ;  For Polish Translation 
_TXT_File_5AE_20_po 
 dc.b "         JEDNAKZE ...        ",0 ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_21  ; in game 
 dc.l $3c384 
 dc.l _TXT_File_5AE_21_en-_TXT_File_5AE_21 
 dc.l _TXT_File_5AE_21_fr-_TXT_File_5AE_21 
 dc.l _TXT_File_5AE_21_de-_TXT_File_5AE_21 
 dc.l _TXT_File_5AE_21_po-_TXT_File_5AE_21,0 
_TXT_File_5AE_22  ; in game 
 dc.l $3c3a4 
 dc.l _TXT_File_5AE_22_en-_TXT_File_5AE_22 
 dc.l _TXT_File_5AE_22_fr-_TXT_File_5AE_22 
 dc.l _TXT_File_5AE_22_de-_TXT_File_5AE_22 
 dc.l _TXT_File_5AE_22_po-_TXT_File_5AE_22,0 
_TXT_File_5AE_23  ; in game 
 dc.l $3c3c4 
 dc.l _TXT_File_5AE_23_en-_TXT_File_5AE_23 
 dc.l _TXT_File_5AE_23_fr-_TXT_File_5AE_23 
 dc.l _TXT_File_5AE_23_de-_TXT_File_5AE_23 
 dc.l _TXT_File_5AE_23_po-_TXT_File_5AE_23,0 
_TXT_File_5AE_24  ; in game 
 dc.l $3c3e4 
 dc.l _TXT_File_5AE_24_en-_TXT_File_5AE_24 
 dc.l _TXT_File_5AE_24_fr-_TXT_File_5AE_24 
 dc.l _TXT_File_5AE_24_de-_TXT_File_5AE_24 
 dc.l _TXT_File_5AE_24_po-_TXT_File_5AE_24,0 
_TXT_File_5AE_25  ; in game 
 dc.l $3c404 
 dc.l _TXT_File_5AE_25_en-_TXT_File_5AE_25 
 dc.l _TXT_File_5AE_25_fr-_TXT_File_5AE_25 
 dc.l _TXT_File_5AE_25_de-_TXT_File_5AE_25 
 dc.l _TXT_File_5AE_25_po-_TXT_File_5AE_25,0 
_TXT_File_5AE_21_en 
 dc.b "          AT LAST            ",0  ; here English translation 
_TXT_File_5AE_22_en 
 dc.b " THESE TWO PEOPLE CAN BE MET  ",0 ; here English translation 
_TXT_File_5AE_23_en 
 dc.b "           AGAIN..           ",0  ; here English translation 
_TXT_File_5AE_24_en 
 dc.b " BUT, THEY ARE DESTINED TO BE",0  ; here English translation 
_TXT_File_5AE_25_en 
 dc.b "    SEPARATED HEATLESSLY !!  ",0  ; here English translation 
 dc.b 0 
_TXT_File_5AE_21_fr 
 dc.b "         A LA FIN            ",0  ; For Cfou! French Translation 
_TXT_File_5AE_22_fr 
 dc.b " 2 PERSONNES PEUVENT ETRE LA  ",0 ; For Cfou! French Translation 
_TXT_File_5AE_23_fr 
 dc.b "          ENCORE...          ",0  ; For Cfou! French Translation 
_TXT_File_5AE_24_fr 
 dc.b "MAIS ILS SONT DESTINES A ETRE",0  ; For Cfou! French Translation 
_TXT_File_5AE_25_fr 
 dc.b "  SEPAREMENT IMPITOYABLES !! ",0  ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_21_de 
 dc.b "LETZTENDLICH DIESE ZWEI LEUTE",0  ; =>OK German Translation 
_TXT_File_5AE_22_de 
 dc.b "    KONNEN GETROFFEN WERDEN   ",0 ; =>OK german Translation
_TXT_File_5AE_23_de 
 dc.b "    WIEDER...  SIE SIND      ",0 ; =>OK german Translation
_TXT_File_5AE_24_de 
 dc.b " ABER BESTIMMT ES ZU SEIN    ",0  ; =>ok german Translation 
_TXT_File_5AE_25_de 
 dc.b "    GETRENNT UNERBITTLICH    ",0  ; =>ok german Translation 
 dc.b 0 
_TXT_File_5AE_21_po 
 dc.b "         NARESZCIE           ",0  ;  For Polish Translation 
_TXT_File_5AE_22_po 
 dc.b "TE DWIE OSOBY MOGA SIE SPOTKAC",0 ;  For Polish Translation 
_TXT_File_5AE_23_po
 dc.b "         PONOWNIE...         ",0  ;  For Polish Translation 
_TXT_File_5AE_24_po 
 dc.b " ALE TO IM BYLO PRZEZNACZONE ",0  ;  For Polish Translation 
_TXT_File_5AE_25_po 
 dc.b "  BEZLITOSNIE ROZLACZENI !!  ",0  ;  For Polish Translation 
 dc.b 0 
 even 
  
;***************************************** 
_TXT_File_5AE_26  ; in game 
 dc.l $3c424 
 dc.l _TXT_File_5AE_26_en-_TXT_File_5AE_26 
 dc.l _TXT_File_5AE_26_fr-_TXT_File_5AE_26 
 dc.l _TXT_File_5AE_26_de-_TXT_File_5AE_26 
 dc.l _TXT_File_5AE_26_po-_TXT_File_5AE_26,0 
_TXT_File_5AE_26_en 
 dc.b "         OH, GOD !          ",0   ; here English translation 
 dc.b 0 
_TXT_File_5AE_26_fr 
 dc.b "      OH, MON DIEU !        ",0   ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_26_de 
 dc.b "      OH GOTT!              ",0   ; =>OK german Translation
 dc.b 0 
_TXT_File_5AE_26_po 
 dc.b "      O, MOJ BOZE !         ",0   ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_27  ; in game 
 dc.l $3c443 
 dc.l _TXT_File_5AE_27_en-_TXT_File_5AE_27 
 dc.l _TXT_File_5AE_27_fr-_TXT_File_5AE_27 
 dc.l _TXT_File_5AE_27_de-_TXT_File_5AE_27 
 dc.l _TXT_File_5AE_27_po-_TXT_File_5AE_27,0 
_TXT_File_5AE_27_en 
 dc.b "CREDITS:" ; here English translation 
 dc.b 0 
_TXT_File_5AE_27_fr 
 dc.b "CREDITS:" ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_27_de 
 dc.b "CREDITS:" ; =>OK german Translation 
 dc.b 0 
_TXT_File_5AE_27_po 
 dc.b "TWORCY: " ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_28  ; in game 
 dc.l $3c453 
 dc.l _TXT_File_5AE_28_en-_TXT_File_5AE_28 
 dc.l _TXT_File_5AE_28_fr-_TXT_File_5AE_28 
 dc.l _TXT_File_5AE_28_de-_TXT_File_5AE_28 
 dc.l _TXT_File_5AE_28_po-_TXT_File_5AE_28,0 
_TXT_File_5AE_28_en 
 dc.b "COOK BONUS" ; here English translation 
 dc.b 0 
_TXT_File_5AE_28_fr 
 dc.b "BONUS MIAM" ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_28_de 
 dc.b "COOK BONUS" ; NEED GERMAN Translation 
 dc.b 0 
_TXT_File_5AE_28_po 
 dc.b "KUCHCENIE " ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_29  ; in game 
 dc.l $3c472 
 dc.l _TXT_File_5AE_29_en-_TXT_File_5AE_29 
 dc.l _TXT_File_5AE_29_fr-_TXT_File_5AE_29 
 dc.l _TXT_File_5AE_29_de-_TXT_File_5AE_29 
 dc.l _TXT_File_5AE_29_po-_TXT_File_5AE_29,0 
_TXT_File_5AE_29_en 
 dc.b "CONTINUE:  9" ; here English translation 
 dc.b 0 
_TXT_File_5AE_29_fr 
 dc.b "CONTINUE:  9" ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_29_de 
 dc.b "FORTSETZEN 9" ; =>OK german Translation 
 dc.b 0 
_TXT_File_5AE_29_po 
 dc.b "KONTYNUUJ: 9" ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_30  ; in game 
 dc.l $3c481 
 dc.l _TXT_File_5AE_30_en-_TXT_File_5AE_30 
 dc.l _TXT_File_5AE_30_fr-_TXT_File_5AE_30 
 dc.l _TXT_File_5AE_30_de-_TXT_File_5AE_30 
 dc.l _TXT_File_5AE_30_po-_TXT_File_5AE_30,0 
_TXT_File_5AE_30_en 
 dc.b "GAME OVER" ; here English translation 
 dc.b 0 
_TXT_File_5AE_30_fr 
 dc.b " JEU FINI" ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_30_de 
 dc.b "GAME OVER" ; =>OK german Translation 
 dc.b 0 
_TXT_File_5AE_30_po 
 dc.b "KONIEC ! " ;  For Polish Translation 
 dc.b 0 
 even 
 
_TXT_File_5AE_31  ; in game 
 dc.l $3c48d 
 dc.l _TXT_File_5AE_31_en-_TXT_File_5AE_31 
 dc.l _TXT_File_5AE_31_fr-_TXT_File_5AE_31 
 dc.l _TXT_File_5AE_31_de-_TXT_File_5AE_31 
 dc.l _TXT_File_5AE_31_po-_TXT_File_5AE_31,0 
_TXT_File_5AE_31_en 
 dc.b "TRY AGAIN? 9" ; here English translation 
 dc.b 0 
_TXT_File_5AE_31_fr 
 dc.b "  ENCORE ? 9" ; For Cfou! French Translation 
 dc.b 0 
_TXT_File_5AE_31_de 
 dc.b "    NOCH ? 9" ; MORE LONGER german Translation 
 dc.b 0 
_TXT_File_5AE_31_po 
 dc.b "PROBUJESZ? 9" ;  For Polish Translation 
 dc.b 0 
 even 
   

;----------------- Table intro 0
_TXT_Table_Outro
 dc.l _TXT_Outro_1-_TXT_Table_Outro
 dc.l 0

; Intro 0 Texts
_TXT_Outro_1  ; intro
 dc.l $de89
 dc.l _TXT_Outro_1_en-_TXT_Outro_1
 dc.l _TXT_Outro_1_fr-_TXT_Outro_1
 dc.l _TXT_Outro_1_de-_TXT_Outro_1
 dc.l _TXT_Outro_1_po-_TXT_Outro_1,0
_TXT_Outro_1_en
                                             ; here English translation
 dc.b "        ...IN THIS WAY.         ",$a
 dc.b "       HIPOPO OVERCAME MANY     ",$a
 dc.b "      DIFFICULTIES BY USING     ",$a
 dc.b "   THE LEGENDARY 'WATER MAGIC'  ",$a
 dc.b "       AND DEFEATED DEVILS.     ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$64
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "        HE TOOK BACK THE        ",$a
 dc.b "         WATER PARADISE         ",$a
 dc.b "       'WOODY LAKE'  FROM       ",$a
 dc.b "      THE DEVIL'S HANDS !!      ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$64
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "      THE LEGEND ATTRACTS       ",$a
 dc.b "THE BRAVE, CREATING A NEW LEGEND",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$96
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "      THIS PEACE IS FOREVER     ",$a
 dc.b "     AND AFTER THIS FOREVER...  ",$a
 dc.b "       THE ' J&L ' PROJECT      ",$a
 dc.b "                                ",$a
 dc.b "         *   STAFF   *          ",$a
 dc.b "                                ",$a
 dc.b "    FIRST, WE WANT TO GREET     ",$a
 dc.b "   THIERRY FOR HIS WONDERFUL    ",$a
 dc.b "  GRAPHICS !!   (HI ! TARZAN)   ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "      ' J&L ' is a team         ",$a
 dc.b "           formed by            ",$a
 dc.b "                                ",$a
 dc.b "        Janicki Michel          ",$a
 dc.b "          ( CODER )             ",$a
 dc.b "             and                ",$a
 dc.b "      Loriaux Pierre-Eric       ",$a
 dc.b "      ( CODER & MUSICIAN )      ",$a
 dc.b "                                ",$a
 dc.b "       and additionally         ",$a
 dc.b "       Levastre Thierry         ",$a
 dc.b "          ( TARZAN )            ",$a
 dc.b "                                ",$a
 dc.b $fe,$FA
 dc.b "    Liquid kids was developped  ",$a
 dc.b "         in six months          ",$a
 dc.b " About:                         ",$a
 dc.b "                                ",$a
 dc.b "* Two Amiga 2000 (1.5 MO)       ",$a
 dc.b "* Two monitors CM 8833 & CM 8832",$a
 dc.b "* An external drive (AF 880)    ",$a
 dc.b "* An external drive (S/N 302)   ",$a
 dc.b "* A dot matrix printer          ",$a
 dc.b "* A Commodore Mouse             ",$a
 dc.b "             (made in HONG KONG)",$a
 dc.b "* A Commodore Mouse             ",$a
 dc.b "             (made in MALAYSIA) ",$a
 dc.b "* A multi timbral linear        ",$a
 dc.b "    synthesizer   (DNS 883730)  ",$a
 dc.b "* A video tape stereo HQ(NV_H75)",$a
 dc.b "* A Scientific statistical      ",$a
 dc.b "    calculator F_800 P          ",$a
 dc.b "* A Digit scientific            ",$a
 dc.b "    calculator  (DC 3V)         ",$a
 dc.b "* 6 pens fine carbure  (045)    ",$a
 dc.b "* 2 Criterium 'PLEIN CIEL' (HB) ",$a
 dc.b "* 3 Paper blocs (JPG 4299)      ",$a
 dc.b "* 1800 drink boxes of COCA      ",$a
 dc.b "* 90   litres of coffee         ",$a
 dc.b "* 720  Jam sandwiches           ",$a
 dc.b "* 80   pizzas                   ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "    Some information about      ",$a
 dc.b "         Liquid Kids.           ",$a
 dc.b "                                ",$a
 dc.b " 52211 lines of code            ",$a
 dc.b " 2 Mo   of data on the disk     ",$a
 dc.b " 218 Ko of musics and sounds    ",$a
 dc.b " 1.4 Mo of graphics             ",$a
 dc.b " 1320 hours of work             ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$fa
 dc.b "    Next is an example of code  ",$a
 dc.b "  ==========================    ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "        lea bobtirs-tstruct,a1  ",$a
 dc.b "LABEL1: moveq #0,d4             ",$a
 dc.b "        move.l a1,d3            ",$a
 dc.b "LABEL2: lea tstruct(a1),a1      ",$a
 dc.b "        tst.b FLOK(a1)          ",$a
 dc.b "        blt.s LABEL3            ",$a
 dc.b "        bne.s LABEL1            ",$a
 dc.b "        addq.w #1,d4            ",$a
 dc.b "        cmp.w d0,d4             ",$a
 dc.b "        bne.s LABEL2            ",$a
 dc.b "        add.l #tstruct,d3       ",$a
 dc.b "        rts                     ",$a
 dc.b "LABEL3: moveq #0,d3             ",$a
 dc.b "        rts                     ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "MESSAGE FOR OUR FRENCHE FRIENDS.",$a
 dc.b "                                ",$a
 dc.b "    < Salut Jean-Charles  >     ",$a
 dc.b " On attend toujours les disques ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "        < Salut  Mike >         ",$a
 dc.b "   Tu... vaas... biieenn...?    ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$64
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$96
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "     THANK YOU FOR PLAYING !    ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$fa
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b 0


_TXT_Outro_1_fr
                                               ; For Cfou! French Translation
 dc.b "        ...A CETTE ETAPE,       ",$a
 dc.b "  HIPOPO A PASSER DIFFERENTES   ",$a
 dc.b "      EPREUVES EN UTILISANT     ",$a
 dc.b "  LA LEGENDAIRE 'EAU MAGIQUE'   ",$a
 dc.b "       ET BATTU LE DEMON.       ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$64
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "          IL LIBERA LE          ",$a
 dc.b "        PARADIS DE L'EAU        ",$a
 dc.b "        'WOODY-LAKE' DES        ",$a
 dc.b "        MAINS DU DEMON !!       ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$64
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "        LA LEGENDE ATTIRE       ",$a
 dc.b "      LE BRAVE, CREANT UNE      ",$a
 dc.b "        NOUVELLE LEGENDE        ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$96
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "    LA PAIX ET POUR TOUJOURS    ",$a
 dc.b " ET APRES CE POUR 'TOUJOURS'... ",$a
 dc.b "        LE PROJET ' J&L '       ",$a
 dc.b "                                ",$a
 dc.b "         *   EQUIPE   *         ",$a
 dc.b "                                ",$a
 dc.b "   PREMIEREMENT, NOUS VOULONS   ",$a
 dc.b "   REMERCIER THIERRY POUR SES   ",$a
 dc.b "     SUPERBES GRAPHIQUES !!      ",$a
 dc.b "        (HI ! TARZAN)           ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "    ' J&L ' est une equipe      ",$a
 dc.b "          formee par            ",$a
 dc.b "                                ",$a
 dc.b "        Janicki Michel          ",$a
 dc.b "        ( PROGRAMMEUR )         ",$a
 dc.b "              ET                ",$a
 dc.b "      Loriaux Pierre-Eric       ",$a
 dc.b "    ( PROGRAMMEUR & MUSICIEN )  ",$a
 dc.b "                                ",$a
 dc.b "    et additionnellement        ",$a
 dc.b "       Levastre Thierry         ",$a
 dc.b "          ( TARZAN )            ",$a
 dc.b "                                ",$a
 dc.b $fe,$FA
 dc.b "   Liquid kids a ete developpe  ",$a
 dc.b "          en six mois           ",$a
 dc.b " et a necessite:               ",$a
 dc.b "                                ",$a
 dc.b "* 2 Amiga 2000 (1.5 MO)         ",$a
 dc.b "* 2 moniteurs CM 8833 & CM 8832 ",$a
 dc.b "* Un lecteur externe (AF 880)   ",$a
 dc.b "* Un lecteur ecterne (S/N 302)  ",$a
 dc.b "* Une imprimante matricielle    ",$a
 dc.b "* Une souris commodore          ",$a
 dc.b "             (made in HONG KONG)",$a
 dc.b "* Une souris commodore          ",$a
 dc.b "             (made in MALAYSIA) ",$a
 dc.b "* Un synthesizer multi-piste    ",$a
 dc.b "                  (DNS 883730)  ",$a
 dc.b "* Un cassette video HQ(NV_H75)  ",$a
 dc.b "* Une calculatrice scientifique ",$a
 dc.b "  et statistique (F_800 P)      ",$a
 dc.b "* Un calculateur scientifique   ",$a
 dc.b "  digital        (DC 3V)        ",$a
 dc.b "* 6 stylos carbone fin  (045)   ",$a
 dc.b "* 2 Criterium 'PLEIN CIEL' (HB) ",$a
 dc.b "* 3 blocs de papier (JPG 4299)  ",$a
 dc.b "* 1800 boites de COCA           ",$a
 dc.b "* 90   litres de cafe           ",$a
 dc.b "* 720  sandwiches au jambon     ",$a
 dc.b "* 80   pizzas                   ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "    Quelques informations sur   ",$a
 dc.b "         Liquid Kids.           ",$a
 dc.b "                                ",$a
 dc.b " 52211 lignes de code           ",$a
 dc.b " 2 Mo de donnees sur le disk    ",$a
 dc.b " 218 Ko de musique et de son    ",$a
 dc.b " 1.4 Mo de graphiques           ",$a
 dc.b " 1320 heures de travail         ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$fa
 dc.b "  Ensuite un exemple de code    ",$a
 dc.b "  ==========================    ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "        lea bobtirs-tstruct,a1  ",$a
 dc.b "LABEL1: moveq #0,d4             ",$a
 dc.b "        move.l a1,d3            ",$a
 dc.b "LABEL2: lea tstruct(a1),a1      ",$a
 dc.b "        tst.b FLOK(a1)          ",$a
 dc.b "        blt.s LABEL3            ",$a
 dc.b "        bne.s LABEL1            ",$a
 dc.b "        addq.w #1,d4            ",$a
 dc.b "        cmp.w d0,d4             ",$a
 dc.b "        bne.s LABEL2            ",$a
 dc.b "        add.l #tstruct,d3       ",$a
 dc.b "        rts                     ",$a
 dc.b "LABEL3: moveq #0,d3             ",$a
 dc.b "        rts                     ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "MESSAGE POUR NOS AMIS FRANCAIS. ",$a
 dc.b "                                ",$a
 dc.b "    < Salut Jean-Charles  >     ",$a
 dc.b " On attend toujours les disques ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "        < Salut  Mike >         ",$a
 dc.b "   Tu... vaas... biieenn...?    ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$64
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$96
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "      MERCI D'AVOIR JOUER !     ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$fa
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b 0

_TXT_Outro_1_de 
                                             ; ALL OUTRO NEED GERMAN translation 
 dc.b "   ...AUF DIESE ART UBERWAND.   ",$a
 dc.b "  HIPOPO VIELE SCHWIERIGKEITEN, ",$a 
 dc.b "     INDEM ES DAS LEGENDARE     ",$a
 dc.b "   'MAGISCHE WASSER'VERWENDETE  ",$a 
 dc.b "       UND BESIEGTE TEUFEL.     ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b $fe,$64 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "           ER NAHM DAS          ",$a 
 dc.b "         WASSERCPARADIES        ",$a 
 dc.b "      'WOODY LAKE' VON DEN      ",$a 
 dc.b "       HANDEN DES TEUFELS !     ",$a
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b $fe,$64 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "       DIE LEGENDE ZIEHT        ",$a 
 dc.b " DAS TAPFERE AN UND VERURSACHT  ",$a 
 dc.b "         NEUE LEGENDE.          ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b $fe,$96 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "  DIESER FRIEDEN IST FUR IMMER  ",$a
 dc.b "  UND NACH DIESEM FUR IMMER...  ",$a
 dc.b "       DAS ' J&L ' PROJEKT      ",$a 
 dc.b "                                ",$a 
 dc.b "      *   MANNSCHAFT   *        ",$a 
 dc.b "                                ",$a 
 dc.b "       ZUERST MOCHTEN WIR       ",$a
 dc.b "     FUR SEINE WUNDERVOLLEN     ",$a
 dc.b "      GRAPHIKEN GRUSSEN !!      ",$a
 dc.b "         (HI ! TARZAN)          ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "  ' J&L ' is eine Mannschaft    ",$a 
 dc.b "         die von besteht:       ",$a 
 dc.b "                                ",$a 
 dc.b "        Janicki Michel          ",$a 
 dc.b "       ( PROGRAMMIERER )        ",$a 
 dc.b "             und                ",$a 
 dc.b "      Loriaux Pierre-Eric       ",$a 
 dc.b "   ( PROGRAMMIERER & MUSIKER )  ",$a 
 dc.b "                                ",$a 
 dc.b "         und zusatzlich         ",$a
 dc.b "       Levastre Thierry         ",$a 
 dc.b "          ( TARZAN )            ",$a 
 dc.b "                                ",$a 
 dc.b $fe,$FA 
 dc.b "    Liquid kids wurde in sechs  ",$a 
 dc.b "       Monaten verursacht       ",$a 
 dc.b " uber:                          ",$a
 dc.b "                                ",$a 
 dc.b "* Zwei Amiga 2000 (1.5 MO)      ",$a 
 dc.b "* Zwei Monitoren CM8833 & CM8832",$a 
 dc.b "* Ein externer Antrieb (AF 880) ",$a 
 dc.b "* Ein externer Antrieb (S/N 302)",$a 
 dc.b "* Ein Matrixdrucker             ",$a 
 dc.b "* Eine Commodore Computermaus   ",$a 
 dc.b "             (made in HONG KONG)",$a 
 dc.b "* Eine Commodore Computermaus   ",$a 
 dc.b "             (made in MALAYSIA) ",$a 
 dc.b "* Ein multi timbral linearer    ",$a 
 dc.b "    synthesizer   (DNS 883730)  ",$a 
 dc.b "* Ein Videobandstereo HQ(NV_H75)",$a 
 dc.b "* Ein wissenschaftlicher        ",$a 
 dc.b "  statistischer Rechner F_800 P ",$a 
 dc.b "* Ein wissenschaftlicher Rechner",$a 
 dc.b "    der Stelle  (DC 3V)         ",$a 
 dc.b "* 6 Federn verurteilen (045)    ",$a 
 dc.b "* 2 Fullfederhalter 'PLEIN CIEL'",$a
 dc.b "* 3 Blocke Papier (JPG 4299)    ",$a
 dc.b "* 1800 Boxdrink of COCA         ",$a 
 dc.b "* 90   Liter Kaffee             ",$a 
 dc.b "* 720  Schinkenbrote            ",$a 
 dc.b "* 80   pizzas                   ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "  Etwas Informationen ungefahr  ",$a
 dc.b "         Liquid Kids.           ",$a 
 dc.b "                                ",$a 
 dc.b " 52211 lines of code            ",$a 
 dc.b " 2 Mo   of data on the disk     ",$a 
 dc.b " 218 Ko of musics and sounds    ",$a 
 dc.b " 1.4 Mo of graphics             ",$a 
 dc.b " 1320 hours of work             ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b $fe,$fa 
 dc.b "  Ist zunachst ein Beispiel:    ",$a
 dc.b "  ==========================    ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "        lea bobtirs-tstruct,a1  ",$a 
 dc.b "LABEL1: moveq #0,d4             ",$a 
 dc.b "        move.l a1,d3            ",$a 
 dc.b "LABEL2: lea tstruct(a1),a1      ",$a 
 dc.b "        tst.b FLOK(a1)          ",$a 
 dc.b "        blt.s LABEL3            ",$a 
 dc.b "        bne.s LABEL1            ",$a 
 dc.b "        addq.w #1,d4            ",$a 
 dc.b "        cmp.w d0,d4             ",$a 
 dc.b "        bne.s LABEL2            ",$a 
 dc.b "        add.l #tstruct,d3       ",$a 
 dc.b "        rts                     ",$a 
 dc.b "LABEL3: moveq #0,d3             ",$a 
 dc.b "        rts                     ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "      ANZEIGE FUR UNSERE        ",$a
 dc.b "        FRENCHE-FREUNDE.        ",$a 
 dc.b "    < Salut Jean-Charles  >     ",$a 
 dc.b " On attend toujours les disques ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "        < Salut  Mike >         ",$a 
 dc.b "   Tu... vaas... biieenn...?    ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b $fe,$64 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b $fe,$96 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "     DANKE FUR DAS SPIELEN!     ",$a
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b $fe,$fa 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b "                                ",$a 
 dc.b 0 
 




_TXT_Outro_1_po
                                             ;  For polish Translation
 dc.b "    ...TYM OTO SPOSOBEM.        ",$a
 dc.b "      HIPOPO POKONUJAC          ",$a
 dc.b "    WIELE TRUDNOSCI, UZYL       ",$a
 dc.b "  LEGENDARNEJ 'WODNEJ MAGII'    ",$a
 dc.b "       I ZNISZCZYL ZLO.         ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$64
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "       NA POWROT ODEBRAL        ",$a
 dc.b "           WODNY RAJ            ",$a
 dc.b "        'WOODY LAKE'  Z         ",$a
 dc.b "          RAK DEMONA !!         ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$64
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "      LEGENDA PRZYCIAGA         ",$a
 dc.b "ODWAZNYCH, TWORZAC NOWE LEGENDY ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$96
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "    POKOJ JEST WIECZNY          ",$a
 dc.b "   I BEDZIE TRWAL WIECZNIE...   ",$a
 dc.b "         PROJEKT ' J&L '        ",$a
 dc.b "                                ",$a
 dc.b "         *   EKIPA   *          ",$a
 dc.b "                                ",$a
 dc.b " PO PIERWSZE, CHCEMY POZDROWIC  ",$a
 dc.b " THIERRY'EGO ZA JEGO WSPANIALA  ",$a
 dc.b "  GRAFIKE !!   (HI ! TARZAN)    ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "      ' J&L ' to grupa          ",$a
 dc.b "        tworzona przez:         ",$a
 dc.b "                                ",$a
 dc.b "        Janicki Michel          ",$a
 dc.b "           ( KODER )            ",$a
 dc.b "             oraz               ",$a
 dc.b "      Loriaux Pierre-Eric       ",$a
 dc.b "       ( KODER & MUZYK )        ",$a
 dc.b "                                ",$a
 dc.b "        oraz dodatkowo          ",$a
 dc.b "       Levastre Thierry         ",$a
 dc.b "          ( TARZAN )            ",$a
 dc.b "                                ",$a
 dc.b $fe,$FA
 dc.b "  Liquid kids zostaly zrobione  ",$a
 dc.b "       w szesc miesiecy         ",$a
 dc.b " Uzyto do tego:                 ",$a
 dc.b "                                ",$a
 dc.b "* Dwie Amigi 2000 (1.5 MB)      ",$a
 dc.b "* Dwa monitory CM 8833 & CM 8832",$a
 dc.b "* Zewnetrzny naped (AF 880)     ",$a
 dc.b "* Zewnetrzny naped (S/N 302)    ",$a
 dc.b '* Drukarka "plujka"             ',$a
 dc.b "* Myszka Commodore              ",$a
 dc.b "   (wyprodukowana w HONG KONGU) ",$a
 dc.b "* Myszka Commodore              ",$a
 dc.b "    (wyprodukowana w MALAYSII)  ",$a
 dc.b "* Wielosciezkowy syntezator     ",$a
 dc.b "                  (DNS 883730)  ",$a
 dc.b "* Odtwarzacz video HQ (NV_H75)  ",$a
 dc.b "* Naukowy kalkulator            ",$a
 dc.b "    statystyczny F_800 P        ",$a
 dc.b "* Naukowy cyfrowy               ",$a
 dc.b "    kalkulator  (DC 3V)         ",$a
 dc.b "* 6 dlugopisow (045)            ",$a
 dc.b "* 2 olowki 'PLEIN CIEL' (HB)    ",$a
 dc.b "* 3 bloki papierowe (JPG 4299)  ",$a
 dc.b "* 1800 puszek COCA-COLI         ",$a
 dc.b "* 90   litrow kawy              ",$a
 dc.b "* 720  kanapek z drzemem        ",$a
 dc.b "* 80   pizz                     ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "    Kilka faktow na temat       ",$a
 dc.b "         Liquid Kids.           ",$a
 dc.b "                                ",$a
 dc.b " 52211  linii kodu              ",$a
 dc.b " 2 MB   danych na dysku         ",$a
 dc.b " 218 KB muzyki i dzwiekow       ",$a
 dc.b " 1.4 MB danych graficznych      ",$a
 dc.b " 1320   godzin pracy            ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$fa
 dc.b "    Przykladowy kod gry:        ",$a
 dc.b "  ==========================    ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "        lea bobtirs-tstruct,a1  ",$a
 dc.b "LABEL1: moveq #0,d4             ",$a
 dc.b "        move.l a1,d3            ",$a
 dc.b "LABEL2: lea tstruct(a1),a1      ",$a
 dc.b "        tst.b FLOK(a1)          ",$a
 dc.b "        blt.s LABEL3            ",$a
 dc.b "        bne.s LABEL1            ",$a
 dc.b "        addq.w #1,d4            ",$a
 dc.b "        cmp.w d0,d4             ",$a
 dc.b "        bne.s LABEL2            ",$a
 dc.b "        add.l #tstruct,d3       ",$a
 dc.b "        rts                     ",$a
 dc.b "LABEL3: moveq #0,d3             ",$a
 dc.b "        rts                     ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "MESSAGE FOR OUR FRENCHE FRIENDS.",$a
 dc.b "                                ",$a
 dc.b "    < Salut Jean-Charles  >     ",$a
 dc.b " On attend toujours les disques ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "        < Salut  Mike >         ",$a
 dc.b "   Tu... vaas... biieenn...?    ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$64
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$96
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "    DZIEKUJEMY ZA GRANIE!       ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b $fe,$fa
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b "                                ",$a
 dc.b 0
 dc.b 0
 even


  
