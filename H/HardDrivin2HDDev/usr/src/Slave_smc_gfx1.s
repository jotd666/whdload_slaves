
SMC_GFX1B:	MACRO
	IFEQ \1
	IFEQ \2
	bclr	d6,(a0)
	ELSE
	bclr	d6,\2(a0)
	ENDC
	ELSE
	IFEQ \2
	bset	d6,(a0)
	ELSE
	bset	d6,\2(a0)
	ENDC
	ENDC
	ENDM

SMC_GFX1A:	MACRO
	SMC_GFX1B	\1&1,0
	SMC_GFX1B	\1&2,$1f40
	SMC_GFX1B	\1&4,$3e80
	SMC_GFX1B	\1&8,$5dc0
	rts
	ENDM

	CNOP	0,4
_smc_gfx1_0:	SMC_GFX1A	$0
	CNOP	0,4
_smc_gfx1_1:	SMC_GFX1A	$1
	CNOP	0,4
_smc_gfx1_2:	SMC_GFX1A	$2
	CNOP	0,4
_smc_gfx1_3:	SMC_GFX1A	$3
	CNOP	0,4
_smc_gfx1_4:	SMC_GFX1A	$4
	CNOP	0,4
_smc_gfx1_5:	SMC_GFX1A	$5
	CNOP	0,4
_smc_gfx1_6:	SMC_GFX1A	$6
	CNOP	0,4
_smc_gfx1_7:	SMC_GFX1A	$7
	CNOP	0,4
_smc_gfx1_8:	SMC_GFX1A	$8
	CNOP	0,4
_smc_gfx1_9:	SMC_GFX1A	$9
	CNOP	0,4
_smc_gfx1_a:	SMC_GFX1A	$a
	CNOP	0,4
_smc_gfx1_b:	SMC_GFX1A	$b
	CNOP	0,4
_smc_gfx1_c:	SMC_GFX1A	$c
	CNOP	0,4
_smc_gfx1_d:	SMC_GFX1A	$d
	CNOP	0,4
_smc_gfx1_e:	SMC_GFX1A	$e
	CNOP	0,4
_smc_gfx1_f:	SMC_GFX1A	$f

