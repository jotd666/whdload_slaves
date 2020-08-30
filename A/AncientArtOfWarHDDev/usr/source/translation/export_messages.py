import os,glob,subprocess,json,shutil

offset_dict = {"O2" : 0x138, "O3" : 0x876, "O6" : 2, "O7":0x25A}

o_files = True
t_files = True

input_amiga_dir = "data_fr"
input_pc_dir = "data_pc"
output_amiga_dir = "data"

def json_to_amiga(file_in,file_out,messages,start_offset):
    contents = b''
    if start_offset:
        with open(file_in,"rb") as f:
            contents = f.read(start_offset)
    # write start of file
    with open(file_out,"wb") as f:
        f.write(contents)
        # now write offsets
        offset = start_offset + len(messages)*2
        for m in messages:
            f.write(bytearray([offset>>8,offset & 0xFF]))
            offset += len(m)+1
        for m in messages:
            f.write(m.encode())
            f.write(b"\x00")

def mix_t_file(input_amiga_file,input_pc_file,output_amiga_file):
    filename = os.path.basename(input_amiga_file)

    with open(input_amiga_file,"rb") as f:
        amiga_contents = f.read()
    with open(input_pc_file,"rb") as f:
        pc_contents = f.read()

    split_offset = 0x348
    output_data = pc_contents[:split_offset] + amiga_contents[split_offset:]
    with open(output_amiga_file,"wb") as f:
        f.write(output_data)

if o_files:

    with open("amiga_us.json") as f:
        english_text = json.load(f)

    for filename,messages in english_text.items():
        json_to_amiga(os.path.join(input_amiga_dir,filename),os.path.join(output_amiga_dir,filename),messages,offset_dict.get(filename,0))

if t_files:
    for i in range(0,11):
        filename = "T{:x}".format(i)
        mix_t_file(os.path.join(input_amiga_dir,filename),os.path.join(input_pc_dir,filename),os.path.join(output_amiga_dir,filename))

    # TITLES as-is
    shutil.copy(os.path.join(input_pc_dir,"TITLES"),output_amiga_dir)



