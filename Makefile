ASMFLAGS = -Wall -Wextra
LNKFLAGS_MINIMAL = --sym $*.sym
LNKFLAGS = --dmg --tiny --wramx --sym $*.sym
FIXFLAGS = -f lhg --non-japanese

# for debugging symbols, add "-n hello.sym" to LNKFLAGS

all: hello.gb tile.gb wave.gb actual-wave.gb

%.o: %.asm
	rgbasm $(ASMFLAGS) -o $@ $<

%.gb: %.o
	rgblink $(LNKFLAGS) -o $@ $<
	rgbfix $(FIXFLAGS) $@
	@hexdump -C $@

clean:
	rm -vf *.o
	rm -vf *.gb
	rm -vf *.sym

.PHONY: clean, all
