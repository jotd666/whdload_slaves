"""Read explicit PERF_RANGE declarations; never infer hook lengths from patch opcodes."""
from pathlib import Path
import re

SOURCE=Path(__file__).resolve().parents[1]/'usr/source'
PATTERN=re.compile(r'PERF_RANGE\s+(sim|sound):([0-9a-fA-F]+)\s+(\d+)\s+bit=(\d+)')

def ranges(source=SOURCE, domain="sim"):
    if domain not in ("sim", "sound"): raise ValueError("Unknown hook domain")
    result=[]
    for p in sorted(source.glob('*.s')):
        for line,text in enumerate(p.read_text().splitlines(),1):
            if 'PERF_RANGE' not in text:continue
            m=PATTERN.search(text)
            if not m:raise ValueError(f'Malformed range: {p.name}:{line}')
            if m[1] != domain: continue
            off=int(m[2],16)-(40 if domain == "sound" else 0);length=int(m[3]);bit=int(m[4])
            if off<0 or length<=0 or off%2 or length%2:raise ValueError('Range must contain whole words')
            result.append((off,off+length,bit,p.name,line))
    for i,(lo,hi,*_) in enumerate(result):
        for x,y,*_ in result[i+1:]:
            if max(lo,x)<min(hi,y):raise ValueError('Overlapping performance hooks')
    return result
