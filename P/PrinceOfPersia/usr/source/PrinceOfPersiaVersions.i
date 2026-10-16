VR_EARLY_DATA = 0
VR_EARLY_CODE = 1
VR_GAME_CODE = 2
VR_GLOBALS = 3
VR_BOOT_TABLES = 4
VR_IMAGE_LOOKUP = 5

; D2: one-time address fixups, before resload_Patch flushes the instruction cache.
; VERSION_REF id, byte offset within the following instruction/patch, address group.
; EQU leaves the enclosing routine's local-label scope intact. No runtime overhead.
; The original operands remain UK addresses; see INTERNALS.md for the version map.
VERSION_REF:MACRO
version_ref_\1 EQU *+\2
version_group_\1 EQU \3
	ENDM

VERSION_ENTRY:MACRO
	dc.w	version_ref_\1-_base,version_group_\1*6
	ENDM
