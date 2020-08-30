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
p2 = bitplanelib.palette_regdump2palette(color2)
dump_dir = r"C:\Users\Public\Documents\Amiga Files\WinUAE"

for m,(pox,poy) in [("march",(0,0))]: #[("info_slow",(128,158)),("info_slow",(128,125)),("info_slow",(174,141)),("info2",(176,142)),("clear_mess",(240,192))]: #,("fighter_types",(102,72))]:
#for m,(pox,poy) in [("lost",(174,141))]:
    img = os.path.join(dump_dir,m)
    with open(img,"rb") as f:
        contents = f.read()
    bitplanelib.bitplanes_raw2image(contents,4,320,200,m+".png",p)
    for i in range(4):
        offset = poy*40+(pox//8) + 8000*i
        print(m,(pox,poy),i,offset,hex(struct.unpack(">I",contents[offset:offset+4])[0]))

#annule_route = PIL.Image.open("annule_route.png")
#annule_route.crop((120,180,160,200)).save("annule_route_icon.png")
#bitplanelib.palette_image2raw("annule_route_icon.png","../data/cancel_route.raw",p)