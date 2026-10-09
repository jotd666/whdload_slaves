"""Read explicit PERF_RANGE declarations; never infer hook lengths from patch opcodes."""
from pathlib import Path
import re

SOURCE=Path(__file__).resolve().parents[1]/'usr/source'
PATTERN=re.compile(r'PERF_RANGE\s+sim:([0-9a-fA-F]+)\s+(\d+)\s+bit=(\d+)')

def ranges(source=SOURCE):
    result=[]
    for p in sorted(source.glob('*.s')):
        for line,text in enumerate(p.read_text().splitlines(),1):
            if 'PERF_RANGE' not in text:continue
            m=PATTERN.search(text)
            if not m:raise ValueError(f'Malformed range: {p.name}:{line}')
            off=int(m[1],16);length=int(m[2]);bit=int(m[3])
            if length<=0 or off%2 or length%2:raise ValueError('Range must contain whole words')
            result.append((off,off+length,bit,p.name,line))
    for i,(lo,hi,*_) in enumerate(result):
        for x,y,*_ in result[i+1:]:
            if max(lo,x)<min(hi,y):raise ValueError('Overlapping performance hooks')
    return result
