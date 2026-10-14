;*---------------------------------------------------------------------------
;  :Contents.	VERIFY-only measurement instruments for Prince of Persia,
;		version 1 (UK) only. Not part of normal builds.
;---------------------------------------------------------------------------*

pl_verify_v1
	PL_START
	PL_END

; The harness finds this block in memory by its marker and reads it at the end of a run.
verify_block
	dc.b	"POPVERIFY",0
	even
