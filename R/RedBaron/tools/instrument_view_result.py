"""Check bounded gauge-cache view transitions, not full-composition or timing acceptance.

The front case requires the native seven-gauge pixel/state twin. Other cockpit
views take the original dispatcher's early exit before either gauge patch;
zero patch entries over five publications establishes that bypass dynamically.
"""
from instrument_cache_result import check as check_front


def check(header, counters, rows):
    front = check_front(header, counters)
    expected = [('front', 0), ('rear', 1), ('left', 2), ('right', 3), ('front-return', 0)]
    if len(rows) != len(expected):
        raise ValueError('Incomplete view transition sequence')
    for row, (label, view) in zip(rows, expected):
        if row.get('label') != label or row.get('view') != view or row.get('publications') != 5:
            raise ValueError('Wrong view or incomplete publication window')
        count = row.get('gauge_entries')
        if type(count) is not int or count < 0 or (view != 0 and count != 0) or (view == 0 and count == 0):
            raise ValueError('Gauge patch activity contradicts native view dispatch')
    return dict(front=front, views=rows,
                scope='Front native twin; rear/left/right native bypass; cockpit return. Full-composition acceptance remains separate.')
