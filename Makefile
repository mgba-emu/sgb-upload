SRC  := test
PNGS :=

OBJS = $(foreach S,$(SRC),build/$(S).o)

all: test.gb

build/%.o: src/%.s
	@mkdir -p build
	rgbasm -I build/ -I src/ -o $@ $<

%.gb %.sym: $(OBJS)
	rgblink -o $*.gb -n $*.sym -p 0xFF $^
	rgbfix -vp 0xFF $*.gb

clean:
	rm -r build/ *.gb *.sym

.PHONY: all clean
.PRECIOUS: $(OBJS) $(2BPP)
