"""Check exact-field W6 capacity censuses without cached-CPU trace timings."""
import argparse
import json
from pathlib import Path
from pacing_model import MASK, safe_line
from time_capacity import interval


def check(data):
    results=[]
    previous=None
    for window in data['windows']:
        a,b=window['before'],window['after']
        if previous is not None and previous!=a:
            raise ValueError('Execution between adjacent windows is not accounted for')
        previous=b
        result=interval(a,b)
        if result['elapsed_fields']!=250:
            raise ValueError('Window must cover exactly 250 native fields')
        swaps=window['publications']
        for row in swaps:
            if (row['field']-a['field']) & MASK >250:
                raise ValueError('Publication outside observed window')
            if not safe_line((row['beam']>>8)&511):
                raise ValueError('Unsafe publication beam position')
        spacing=[(y['field']-x['field'])&MASK for x,y in zip(swaps,swaps[1:])]
        if any(n<1 or n>=1<<31 for n in spacing):
            raise ValueError('Nonmonotonic publication or violated one-field cap')
        if abs(len(swaps)-result['completed_draws'])>1:
            raise ValueError('Draw completions disagree with native publication count')
        result.update(publications=len(swaps),publication_fps=len(swaps)/5,
                      publication_interval_fields=spacing,events=window['events'])
        results.append(result)
    if not results:raise ValueError('No windows')
    return dict(sha256=data['sha256'],windows=results,
                scope='Exact 250-field constant-rate capacity/event windows; not full gameplay-state or sustained-capacity acceptance.')


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('manifest',type=Path);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
    result=check(json.loads(a.manifest.read_text()));a.out.write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
