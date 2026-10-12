; Renderer-specific sim v1 instruction boundaries; relocation operands are
; copied from the loaded code into the private launch trampolines.
SF_BASE_COUNT = 13
SF_LAUNCH_COUNT = 21
scene_frame_base_table:
 dc.l $2e4c8
 dc.w 0,$41f9
 dc.l $2e552
 dc.w 0,$41f9
 dc.l $2e810
 dc.w 1,$43f9
 dc.l $2e8a2
 dc.w 1,$43f9
 dc.l $2e93a
 dc.w 1,$43f9
 dc.l $2e9d4
 dc.w 1,$43f9
 dc.l $2ec12
 dc.w 0,$41f9
 dc.l $2ecf4
 dc.w 0,$41f9
 dc.l $2edaa
 dc.w 0,$41f9
 dc.l $2f646
 dc.w 0,$41f9
 dc.l $2feba
 dc.w 0,$41f9
 dc.l $2ff46
 dc.w 0,$41f9
 dc.l $30576
 dc.w 3,$47f9
scene_frame_launch_table:
 dc.l $2e514
 dc.w 8,$2141,$3143,0
 dc.l $2e586
 dc.w 12,$217c,$3140,0
 dc.l $2e858
 dc.w 8,$2341,$3343,1
 dc.l $2e98a
 dc.w 8,$2341,$3343,1
 dc.l $2ec86
 dc.w 8,$3146,$3143,0
 dc.l $2ed44
 dc.w 8,$2149,$3143,0
 dc.l $2edf2
 dc.w 8,$2149,$3143,0
 dc.l $2f416
 dc.w 8,$3141,$3142,0
 dc.l $2f476
 dc.w 12,$217c,$3143,0
 dc.l $2f502
 dc.w 8,$2143,$3142,0
 dc.l $2f66e
 dc.w 8,$3140,$3141,0
 dc.l $2f99a
 dc.w 12,$217c,$3143,0
 dc.l $2fb8c
 dc.w 8,$3142,$3143,0
 dc.l $2fc22
 dc.w 8,$3146,$3143,0
 dc.l $2fc46
 dc.w 8,$3146,$3142,0
 dc.l $2fd8a
 dc.w 8,$2141,$3143,0
 dc.l $2ff0c
 dc.w 8,$2141,$3143,0
 dc.l $2ff6a
 dc.w 10,$317c,$3140,0
 dc.l $3064c
 dc.w 12,$2779,$3740,3
 dc.l $306a0
 dc.w 8,$2740,$3741,3
 dc.l $307b2
 dc.w 8,$2741,$3746,3

