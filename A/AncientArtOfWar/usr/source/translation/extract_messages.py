import os,glob,subprocess,json

offset_dict = {"O2" : 0x138, "O3" : 0x876, "O7":0x25A}

def amiga_to_json(filepath,start_offset):
    with open(filepath,"rb") as f:
        contents = f.read()
        offsets = []

        for i in range(start_offset,len(contents),2):
            c1 = contents[i]
            c2 = contents[i+1]
            if c1>0x0C and old_c1 != c1 and old_c1 != c1 - 1:
                # heuristics to detect end of offsets
                # (0x0D can appear in texts)
                break
            offsets.append(c1*256 + c2)
            old_c1 = c1

    messages = []
    for offset in offsets:
        text = []
        i = offset
        while contents[i]:
            text.append(contents[i])
            i += 1
        messages.append(bytes(text).decode())

    return messages

output = {}
input_dir = "data_fr"

for file in glob.glob(os.path.join(input_dir,"O*")):
        bnfile = os.path.basename(file)
        result = amiga_to_json(file,offset_dict.get(bnfile,0))
        output[bnfile] = result

with open("amiga_fr.json","w") as f:
    json.dump(output,f,indent=4)

output_pc = {}
input_pc_dir = "data_pc"
for file in glob.glob(os.path.join(input_pc_dir,"O*")):
    result = subprocess.check_output(["strings",file]).decode()
    bnfile = os.path.basename(file)
    output_pc[bnfile] = result.splitlines()

with open("pc_us_full.json","w") as f:
    json.dump(output_pc,f,indent=4)
