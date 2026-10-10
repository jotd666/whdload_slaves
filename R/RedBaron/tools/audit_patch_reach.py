"""Check WHDLoad patch-list signed-word destinations in a vasm listing.

The stock PL_P/PL_PS macros emit dc.w target-.patchlist; a positive value
above 32767 can assemble successfully yet resolve outside the slave at runtime.
"""
import argparse
import re
from pathlib import Path


def audit(text):
    symbols={m[1]:int(m[2],16) for line in text.splitlines()
             if (m:=re.match(r'^(\w+)\s+00:([0-9A-Fa-f]+)\s*$',line))}
    active=False;base=None;checked=0;errors=[]
    for line in text.splitlines():
        if re.search(r':\s+(?:\w+\s+)?PL_START\s*$',line):active=True;base=None
        emitted=re.match(r'00:([0-9A-Fa-f]+)\s+([0-9A-Fa-f]+)\s',line)
        if active and emitted and base is None:base=int(emitted[1],16)
        target=re.search(r'\bdc\.w\s+(\w+)-\.patchlist\b',line)
        if emitted and target:
            if not active or base is None or target[1] not in symbols:
                errors.append('Cannot resolve patch destination: '+line.strip());continue
            checked+=1;delta=symbols[target[1]]-base
            encoded=int(emitted[2],16)
            if not -32768<=delta<=32767 or encoded!=(delta&65535):
                errors.append(f'{target[1]}: displacement {delta} is not the encoded signed word')
        if re.search(r':\s+PL_END\s*$',line):active=False;base=None
    if not checked:errors.append('No emitted patch destinations checked')
    return checked,errors


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('listing',type=Path);a=p.parse_args()
    checked,errors=audit(a.listing.read_text(encoding='latin-1'))
    print(f'{checked} patch destinations; {len(errors)} errors')
    for error in errors:print(error)
    raise SystemExit(bool(errors))
