include ../../options.mk

PROGNAME = RedBaron


WHDLOADER = $(PROGNAME).slave
SOURCE = $(PROGNAME)HD.s

all :  $(WHDLOADER)

$(WHDLOADER) : $(SOURCE) tape.s tape-route.i observe.s perf.s mirror.s mirror-cache.s mirror-verify.s cache-verify.s originals.s paint-observe.s projection.s projection-verify.s projection-cases.i dot.s dot-verify.s dot-cases.i clip.s clip-verify.s clip-cases.i vertex.s vertex-verify.s vertex-cases.i sound-sequence.s sound-driver.s fill.s pacing.s time-core.s time-core-cases.i time-input.s time-loop.s time-exponent.s time-exponent-cases.i time-pause.s time-keys.s time-devices.s time-mouse.s time-rate.s time-message.s time-camera.s time-compress.s time-auto-menu.s time-present-core.s time-present-state.s time-present-model.s time-poses.s time-pose-blend.s time-render.s overlay-probe.s overlay-blit.s time-terrain-verify.s time-present-cases.i time-message-cases.i time-mouse-cases.i time-mouse-ownership-cases.i time-input-observe.s time-probe.s
	$(WDATE)
	$(VASM) -o $(WHDLOADER) $(SOURCE)

developer : $(PROGNAME)-developer.slave

verify : $(PROGNAME)-verify.slave

$(PROGNAME)-developer.slave : $(SOURCE) tape.s tape-route.i observe.s perf.s mirror.s mirror-cache.s mirror-verify.s cache-verify.s originals.s paint-observe.s projection.s projection-verify.s projection-cases.i dot.s dot-verify.s dot-cases.i clip.s clip-verify.s clip-cases.i vertex.s vertex-verify.s vertex-cases.i sound-sequence.s sound-driver.s fill.s pacing.s time-core.s time-core-cases.i time-input.s time-loop.s time-exponent.s time-exponent-cases.i time-pause.s time-keys.s time-devices.s time-mouse.s time-rate.s time-message.s time-camera.s time-compress.s time-auto-menu.s time-present-core.s time-present-state.s time-present-model.s time-poses.s time-pose-blend.s time-render.s overlay-probe.s overlay-blit.s time-terrain-verify.s time-present-cases.i time-message-cases.i time-mouse-cases.i time-mouse-ownership-cases.i time-input-observe.s time-probe.s
	$(WDATE)
	$(VASM) -DDEVELOPER=1 -o $@ $(SOURCE)

$(PROGNAME)-verify.slave : $(SOURCE) tape.s tape-route.i observe.s perf.s mirror.s mirror-cache.s mirror-verify.s cache-verify.s originals.s paint-observe.s projection.s projection-verify.s projection-cases.i dot.s dot-verify.s dot-cases.i clip.s clip-verify.s clip-cases.i vertex.s vertex-verify.s vertex-cases.i sound-sequence.s sound-driver.s fill.s pacing.s time-core.s time-core-cases.i time-input.s time-loop.s time-exponent.s time-exponent-cases.i time-pause.s time-keys.s time-devices.s time-mouse.s time-rate.s time-message.s time-camera.s time-compress.s time-auto-menu.s time-present-core.s time-present-state.s time-present-model.s time-poses.s time-pose-blend.s time-render.s overlay-probe.s overlay-blit.s time-terrain-verify.s time-present-cases.i time-message-cases.i time-mouse-cases.i time-mouse-ownership-cases.i time-input-observe.s time-probe.s
	$(WDATE)
	$(VASM) -DVERIFY=1 -o $@ $(SOURCE)
