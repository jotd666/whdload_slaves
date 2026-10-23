; Complete tfx.020 FINTRZ/FMOVECR census; generated from disassembly.
; Constants: $0f = 0, $32 = 1, $34 = 100.
native_fpu_patches:
        PL_START
        PL_IFC5
        PL_ELSE
        PL_L $85a,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $876,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $892,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $900,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $94c,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $998,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $2f72,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $2fb4,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $4874,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $4890,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $48ac,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $857a,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $85b0,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $d386,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $d65a,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $e928,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $ebc6,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $ec0e,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $ed7c,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $fa18,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $fa70,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $10b4a,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $136d6,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $137b2,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $15fd0,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1600e,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $16072,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $160da,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $16292,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $162aa,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $16450,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $164aa,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $167c6,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $17164,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $171a8,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1a812,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $1a884,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $1a8f6,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $1aae0,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $1ab6c,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $1ab84,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $1b668,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $1b6d0,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $1b6e0,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1b704,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $1bf12,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1c2ac,$4eb80000+$172 ; fmovecrx #50,fp3
        PL_L $1c2c6,$4eb80000+$178 ; fintrzx fp4,fp1
        PL_L $1c314,$4eb80000+$178 ; fintrzx fp4,fp1
        PL_L $1c340,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $1c742,$4eb80000+$17e ; fintrzx fp0,fp3
        PL_L $1c74e,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $1c75a,$4eb80000+$184 ; fintrzx fp2,fp0
        PL_L $1c80e,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $1cdcc,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1cdde,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1cdf0,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $1ce5a,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $1d138,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1d156,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $1d2cc,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1d2de,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1d2f0,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1d356,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $1d54c,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1d55e,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1d570,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1d6a0,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $1d6ca,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $1d6f4,$4eb80000+$184 ; fintrzx fp2,fp0
        PL_L $1d886,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $1d8b0,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $1d8da,$4eb80000+$184 ; fintrzx fp2,fp0
        PL_L $1da24,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $1da46,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $1da62,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $1e714,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1e726,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1e738,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1e924,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $1e9e4,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1ea0e,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $1ee6c,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $209c6,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $209f0,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $20a1a,$4eb80000+$184 ; fintrzx fp2,fp0
        PL_L $20bac,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $20bd6,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $20c00,$4eb80000+$184 ; fintrzx fp2,fp0
        PL_L $20d4a,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $20d6c,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $20d88,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $20e5e,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $20ea4,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $20eea,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $237da,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $23d74,$4eb80000+$184 ; fintrzx fp2,fp0
        PL_L $23d9e,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $24da6,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $24dd8,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $29b76,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $2afe2,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $2b042,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $2b08e,$4eb80000+$18a ; fmovecrx #15,fp6
        PL_L $2b0a0,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $2b2b4,$4eb80000+$190 ; fmovecrx #50,fp2
        PL_L $2c7f6,$4eb80000+$196 ; fmovecrx #52,fp3
        PL_L $2d376,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $2d388,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $2d394,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $2d806,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $2d84c,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $2ddd6,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $2de7e,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $2e202,$4eb80000+$142 ; fintrzx fp1,fp0
        PL_L $2e36a,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $2e6c6,$4eb80000+$190 ; fmovecrx #50,fp2
        PL_L $2e78c,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $2e79c,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $2e7c0,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $2eb82,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $2ed1e,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $2ed2e,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $2edcc,$4eb80000+$190 ; fmovecrx #50,fp2
        PL_L $2f302,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $2f30e,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $2f336,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $2f3d6,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $2f448,$4eb80000+$172 ; fmovecrx #50,fp3
        PL_L $2f5f0,$4eb80000+$19c ; fmovecrx #50,fp1
        PL_L $2fc16,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $2fc34,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $2fc52,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $2fede,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $30218,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $30298,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $303d6,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $3059c,$4eb80000+$172 ; fmovecrx #50,fp3
        PL_L $30b30,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $30c54,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $30c72,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $30c90,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $30e00,$4eb80000+$1a2 ; fmovecrx #15,fp7
        PL_L $30e06,$4eb80000+$1a2 ; fmovecrx #15,fp7
        PL_L $30e86,$4eb80000+$18a ; fmovecrx #15,fp6
        PL_L $310b0,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $310ca,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $310d6,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $315fc,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $316d8,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $318d8,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $31bd8,$4eb80000+$1a8 ; fmovecrx #50,fp5
        PL_L $32260,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $3228a,$4eb80000+$19c ; fmovecrx #50,fp1
        PL_L $322c4,$4eb80000+$19c ; fmovecrx #50,fp1
        PL_L $322f8,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $32320,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $3283a,$4eb80000+$1a2 ; fmovecrx #15,fp7
        PL_L $32d04,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $3334c,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $33390,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $33b14,$4eb80000+$1ae ; fmovecrx #15,fp2
        PL_L $33b58,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $33bdc,$4eb80000+$1b4 ; fmovecrx #15,fp3
        PL_L $3423e,$4eb80000+$1ba ; fmovecrx #15,fp4
        PL_L $3484e,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $34a76,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $34b8a,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $34d5a,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $34f0c,$4eb80000+$1c0 ; fmovecrx #15,fp5
        PL_L $351d6,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $35438,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $35816,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $3599c,$4eb80000+$1c6 ; fintrzx fp3,fp2
        PL_L $35afa,$4eb80000+$16c ; fintrzx fp2,fp1
        PL_L $35b24,$4eb80000+$1cc ; fintrzx fp1,fp4
        PL_L $35b4a,$4eb80000+$1d2 ; fintrzx fp0,fp4
        PL_L $35cda,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $35ce4,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $35d28,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $35d44,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $35d60,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $35d7c,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $35d98,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $35db4,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $35dd0,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $35de8,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $35e00,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $35e12,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $35e24,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $35e36,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $36066,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $361fa,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $36332,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $3633c,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $36380,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $3639c,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $363b8,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $363d4,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $363f0,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $3640c,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $36428,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $36440,$4eb80000+$14e ; fintrzx fp1,fp2
        PL_L $36458,$4eb80000+$148 ; fintrzx fp0,fp1
        PL_L $365ba,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $365fa,$4eb80000+$15a ; fintrzx fp2,fp3
        PL_L $41e36,$4eb80000+$19c ; fmovecrx #50,fp1
        PL_L $41e6a,$4eb80000+$1d8 ; fintrzx fp0,fp2
        PL_L $41efc,$4eb80000+$19c ; fmovecrx #50,fp1
        PL_L $41f30,$4eb80000+$1d8 ; fintrzx fp0,fp2
        PL_L $50fd8,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $51032,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $51044,$4eb80000+$19c ; fmovecrx #50,fp1
        PL_L $5106e,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $5107e,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $5108a,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $510a6,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $51118,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $5114a,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $51170,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $51192,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $511da,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $512bc,$4eb80000+$1de ; fintrzx fp6,fp0
        PL_L $51320,$4eb80000+$1e4 ; fintrzx fp5,fp0
        PL_L $51330,$4eb80000+$1ea ; fintrzx fp4,fp0
        PL_L $51348,$4eb80000+$1de ; fintrzx fp6,fp0
        PL_L $5137c,$4eb80000+$1f0 ; fmovecrx #50,fp6
        PL_L $51382,$4eb80000+$154 ; fmovecrx #50,fp0
        PL_L $514f0,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $514f8,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $51532,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $515f0,$4eb80000+$1f6 ; fintrzx fp7,fp0
        PL_L $51648,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $51664,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $51670,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $5181e,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $5182a,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $51874,$4eb80000+$160 ; fmovecrx #15,fp0
        PL_L $51880,$4eb80000+$166 ; fmovecrx #15,fp1
        PL_L $50f82,$4eb80000+$1fc ; native tan
        PL_L $5169e,$4eb80000+$202 ; native sin
        PL_L $516b6,$4eb80000+$208 ; native cos
        PL_L $517a4,$4eb80000+$20e ; native atan2
        PL_L $517f2,$4eb80000+$214 ; native atan
        PL_L $5183c,$4eb80000+$21a ; native asin
        PL_L $51682,$4eb80000+$220 ; native exp
        PL_ENDIF
        PL_END

install_native_fpu:
        patch $142,ni_1_0
        patch $148,ni_0_1
        patch $14e,ni_1_2
        patch $154,nc_50_0
        patch $15a,ni_2_3
        patch $160,nc_15_0
        patch $166,nc_15_1
        patch $16c,ni_2_1
        patch $172,nc_50_3
        patch $178,ni_4_1
        patch $17e,ni_0_3
        patch $184,ni_2_0
        patch $18a,nc_15_6
        patch $190,nc_50_2
        patch $196,nc_52_3
        patch $19c,nc_50_1
        patch $1a2,nc_15_7
        patch $1a8,nc_50_5
        patch $1ae,nc_15_2
        patch $1b4,nc_15_3
        patch $1ba,nc_15_4
        patch $1c0,nc_15_5
        patch $1c6,ni_3_2
        patch $1cc,ni_1_4
        patch $1d2,ni_0_4
        patch $1d8,ni_0_2
        patch $1de,ni_6_0
        patch $1e4,ni_5_0
        patch $1ea,ni_4_0
        patch $1f0,nc_50_6
        patch $1f6,ni_7_0
        patch $1fc,native_tan
        patch $202,native_sin
        patch $208,native_cos
        patch $20e,native_atan2
        patch $214,native_atan
        patch $21a,native_asin
        patch $220,native_exp
        rts

        mc68040
        NATIVE_INT 1,0
        NATIVE_INT 0,1
        NATIVE_INT 1,2
nc_50_0:
        fmove.s #1,fp0
        rts
        NATIVE_INT 2,3
nc_15_0:
        fmove.s #0,fp0
        rts
nc_15_1:
        fmove.s #0,fp1
        rts
        NATIVE_INT 2,1
nc_50_3:
        fmove.s #1,fp3
        rts
        NATIVE_INT 4,1
        NATIVE_INT 0,3
        NATIVE_INT 2,0
nc_15_6:
        fmove.s #0,fp6
        rts
nc_50_2:
        fmove.s #1,fp2
        rts
nc_52_3:
        fmove.s #100,fp3
        rts
nc_50_1:
        fmove.s #1,fp1
        rts
nc_15_7:
        fmove.s #0,fp7
        rts
nc_50_5:
        fmove.s #1,fp5
        rts
nc_15_2:
        fmove.s #0,fp2
        rts
nc_15_3:
        fmove.s #0,fp3
        rts
nc_15_4:
        fmove.s #0,fp4
        rts
nc_15_5:
        fmove.s #0,fp5
        rts
        NATIVE_INT 3,2
        NATIVE_INT 1,4
        NATIVE_INT 0,4
        NATIVE_INT 0,2
        NATIVE_INT 6,0
        NATIVE_INT 5,0
        NATIVE_INT 4,0
nc_50_6:
        fmove.s #1,fp6
        rts
        NATIVE_INT 7,0
        mc68020
