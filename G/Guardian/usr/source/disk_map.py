import struct
with open("disk.1","rb") as f:   # disk.1 is created with islave with FL_DISKIMAGE set
    root_block = f.read(0x1800)

four_cc = root_block[0:4].decode()

nb_files = struct.unpack_from(">H",root_block,4)[0]

print("disk {}, nb_files {}".format(four_cc,nb_files))

offset = 12
files = []
for i in range(1,nb_files+1):
    block = root_block[offset:offset+40]
    filename = block[0:4].decode()
    size,track,track_offset = struct.unpack_from(">IHH",block,32)
    disk_offset = track_offset + track*0x1800
    files.append([filename,disk_offset,size])
    print("file {:02d}: name: {}, size: ${:x}, track: {:03d}, track_offset: ${:x}, offset: ${:x}".format(i,filename,size,track,track_offset,disk_offset))
    offset += 40

print("\ntracks_0:")
for x in files:
    print("\tFLENTRY\tfn_{},${:x},${:x}".format(*x))

print("\tFLEND\n")
for filename,_,_ in files:
    print('fn_{0}:\n\tdc.b\t"{0}",0'.format(filename))
print("\teven\n")