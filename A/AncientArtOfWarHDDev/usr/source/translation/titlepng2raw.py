import bitplanelib

##with open("aaow_title.raw","rb") as f:
##    bitplanes = f.read()
##
##bitplanes_raw2image(bitplanes,4,320,200,"out.png")

#
z = bitplanelib.palette_regdump2palette("""180 COLOR00     0000
094 DDFSTOP     00D0    182 COLOR01     0060
096 DMACON      03D0    184 COLOR02     0EA8
098 CLXCON      0000    186 COLOR03     068E
09A INTENA      602C    188 COLOR04     0A64
09C INTREQ      0050    18A COLOR05     0842
09E ADKCON      1100    18C COLOR06     0E80
0A0 AUD0LCH     0000    18E COLOR07     0ACE
0A2 AUD0LCL     1004    190 COLOR08     0040
0A4 AUD0LEN     0001    192 COLOR09     0444
0A6 AUD0PER     0004    194 COLOR10     0666
0A8 AUD0VOL     0000    196 COLOR11     0888
0AA AUD0DAT     0000    198 COLOR12     062A
0B0 AUD1LCH     0000    19A COLOR13     0620
0B2 AUD1LCL     1004    19C COLOR14     0408
0B4 AUD1LEN     0001    19E COLOR15     0EEE""")

#bitplanelib.palette_tojascpalette(z,"aaow_title.pal")
#bitplanelib.bitplanes_planarimage2raw("out.png",4,r"C:\DATA\jff\AmigaHD\PROJETS\HDInstall\ARetoucher\AncientArtOfWarHDDev\data\aaow_title.raw")
#bitplanelib.bitplanes_raw2image(bitplanes,4,320,200,"aaow_title.png",z)

##with open("aaow_title.clist","rb") as f:
##    palette = f.read()
##x = bitplanelib.palette_16bitbe2palette(palette)

bitplanelib.palette_image2raw('final_uk_pngs/aaow_title_translated.png',r"..\data\aaow_title.raw",z,add_dimensions=False)

