import bitplanelib,PIL.Image,os,struct

dump = """092 DDFSTRT     0038    180 COLOR00     0000
094 DDFSTOP     00D0    182 COLOR01     0EEE
096 DMACON      03D0    184 COLOR02     0AAA
098 CLXCON      0000    186 COLOR03     0666
09A INTENA      602C    188 COLOR04     0222
09C INTREQ      0050    18A COLOR05     0E22
09E ADKCON      1100    18C COLOR06     0E66
0A0 AUD0LCH     0000    18E COLOR07     0A62
0A2 AUD0LCL     1004    190 COLOR08     0EA6
0A4 AUD0LEN     0001    192 COLOR09     0ECA
0A6 AUD0PER     0004    194 COLOR10     006E
0A8 AUD0VOL     0000    196 COLOR11     00AE
0AA AUD0DAT     0000    198 COLOR12     00EE
0B0 AUD1LCH     0000    19A COLOR13     0060
0B2 AUD1LCL     1004    19C COLOR14     00A0
0B4 AUD1LEN     0001    19E COLOR15     00C0"""

p = bitplanelib.palette_regdump2palette(dump)

dump_dir = "final_uk_pngs"

for m in ["barbarian","march","spy","marching","west","when_moving","stopped","fast","slow","very_slow","warrior","cancel_route","clear_message"]:
    img = os.path.join(dump_dir,m+".png")
    out = os.path.join("..",m+".raw")
    bitplanelib.palette_image2raw(img,out,p)

color2 = """ 180 COLOR00     0000
094 DDFSTOP     00D0    182 COLOR01     0060
096 DMACON      23D0    184 COLOR02     0EA8
098 CLXCON      0000    186 COLOR03     068E
09A INTENA      602C    188 COLOR04     0A64
09C INTREQ      0070    18A COLOR05     0842
09E ADKCON      1100    18C COLOR06     0E00
0A0 AUD0LCH     0000    18E COLOR07     0ACE
0A2 AUD0LCL     1004    190 COLOR08     0040
0A4 AUD0LEN     0001    192 COLOR09     0444
0A6 AUD0PER     0004    194 COLOR10     0666
0A8 AUD0VOL     0000    196 COLOR11     0888
0AA AUD0DAT     0000    198 COLOR12     062A
0B0 AUD1LCH     0000    19A COLOR13     0620
0B2 AUD1LCL     1004    19C COLOR14     0408
0B4 AUD1LEN     0001    19E COLOR15     0EEE
"""
p = bitplanelib.palette_regdump2palette(color2)
for m in ["stats"]:
    img = os.path.join(dump_dir,m+".png")
    out = os.path.join("..",m+".raw")
    bitplanelib.palette_image2raw(img,out,p)
