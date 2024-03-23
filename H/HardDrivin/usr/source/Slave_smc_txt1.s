
SMC_TXT1B:	MACRO
	IFEQ \1
	and.b	d1,\2(a0)
	ELSE
	or.b	d0,\2(a0)
	ENDC
	ENDM

SMC_TXT1A:	MACRO
	SMC_TXT1B	\1&1,$1f40
	SMC_TXT1B	\1&2,$3e80
	SMC_TXT1B	\1&4,$5dc0
	SMC_TXT1B	\1&8,$7d00
	rts
	ENDM

_smc_txt1_0:	SMC_TXT1A	$0
_smc_txt1_1:	SMC_TXT1A	$1
_smc_txt1_2:	SMC_TXT1A	$2
_smc_txt1_3:	SMC_TXT1A	$3
_smc_txt1_4:	SMC_TXT1A	$4
_smc_txt1_5:	SMC_TXT1A	$5
_smc_txt1_6:	SMC_TXT1A	$6
_smc_txt1_7:	SMC_TXT1A	$7
_smc_txt1_8:	SMC_TXT1A	$8
_smc_txt1_9:	SMC_TXT1A	$9
_smc_txt1_a:	SMC_TXT1A	$a
_smc_txt1_b:	SMC_TXT1A	$b
_smc_txt1_c:	SMC_TXT1A	$c
_smc_txt1_d:	SMC_TXT1A	$d
_smc_txt1_e:	SMC_TXT1A	$e
_smc_txt1_f:	SMC_TXT1A	$f

