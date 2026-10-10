include ../../options.mk

PROGNAME = 4DSportsDriving


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) simulation_runtime_context.s simulation_clock.s simulation_schedule.s simulation_verify.s simulation_physics.s simulation_a4000.s simulation_physics_verify.s simulation_physics_cases.i driving_tape.s simulation_input_edge_verify.s performance.s geometry.s geometry_verify.s math.s math_verify.s math_cases.i bookkeeping.s bookkeeping_verify.s bookkeeping_cases.i
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)
