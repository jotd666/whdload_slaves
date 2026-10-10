"""Native automatic-menu predicate and signed-word countdown at a 128-unit tick.

The booleans are results of the original player/threat queries. This model does
not replace those queries or assert that a given aircraft is eligible.
"""
from dataclasses import dataclass, replace


@dataclass(frozen=True)
class State:
    timer: int = 30000
    entered: int = 0
    completion: int = 0


def service(state, player_ready, blocked, mission_status):
    if not all(0<=x<=65535 for x in (state.timer,state.entered,state.completion,mission_status)):
        raise ValueError('Native state must contain unsigned words')
    eligible=player_ready and (not blocked or mission_status!=0)
    eligible=eligible and (state.entered==0 or (state.completion==0 and mission_status!=0))
    if not eligible:return state,False
    timer=(state.timer-128)&65535
    if timer<32768:return replace(state,timer=timer),False
    return State(timer if mission_status else 10000,1,mission_status),True


def command_result(menu_choice):
    return 3 if menu_choice==5 else 2 if menu_choice==8 else 4
