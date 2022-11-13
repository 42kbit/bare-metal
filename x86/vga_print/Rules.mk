ASOBJS_$(d)	:=$(od)/vga.o
OBJS_$(d)	:=$(ASOBJS_$(d))

ASF_$(od)/vga.o	:= -m32

TGTS_$(d)	:=$(bd)/vga.bin
$(call append,TGT_BIN,$(d))

LF_$(TGTS_$(d))	:=-T $(d)/ls.ld

$(d): $(TGTS_$(d))

$(TGTS_$(d)): $(d)/ls.ld $(OBJS_$(d))
	$(L_LINK)
