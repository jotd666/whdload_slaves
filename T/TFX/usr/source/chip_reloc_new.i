; tfx.020 (571008 bytes): HUNK_RELOC32 sites targeting the original DMA groups.
; Each group: source section, number of longword offsets, then offsets.
; CPU-only palettes, sprite pointer tables and page selectors are excluded.
chip_reloc_mouse:
        dc.w 0,8
        dc.l $2574c,$25752,$25b44,$25b4a,$3f908,$3f910,$423fc,$42cb0
        dc.w 1,10
        dc.l $0fcb0,$0fcc0,$0fe7a,$0fe7e,$0fe8e,$0fe92,$0fea2,$0fea6
        dc.l $0feb6,$0feba
        dc.w -1
chip_reloc_display:
        dc.w 0,26
        dc.l $4c45e,$4c468,$4c47e,$4c482,$4c4fa,$4c516,$4c548,$4c54e
        dc.l $4c568,$4f67a,$4f680,$4f690,$4f6b8,$4f6be,$4f6ce,$4f720
        dc.l $4f726,$4f732,$4f738,$4f74c,$4f752,$4f75e,$4f764,$4f788
        dc.l $4f79e,$4f7d0
        dc.w 1,2
        dc.l $027d6,$027da
        dc.w -1
chip_reloc_audio:
        dc.w 0,7
        dc.l $4d35c,$4d37e,$4d412,$4d4b2,$4d4e6,$4d53a,$4d70c
        dc.w -1
chip_reloc_video:
        dc.w 0,9
        dc.l $4c6f2,$4c744,$4c748,$4c74c,$4c750,$4c754,$4c758,$4c75c
        dc.l $4c760
        dc.w -1
