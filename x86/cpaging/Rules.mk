COBJS_$(d)	:=$(od)/paging.o
ASOBJS_$(d)	:=$(od)/boot.o
OBJS_$(d)	:=$(ASOBJS_$(d)) $(COBJS_$(d))

ASF_$(od)/paging.o	:= -m32

TGTS_$(d)	:=$(bd)/cpaging.bin
$(call append,TGT_BIN,$(d))

LF_$(TGTS_$(d))	:=-T $(d)/ls.ld -Map=$(bd)/ls.ld.map

$(d): $(TGTS_$(d))

$(TGTS_$(d)): $(d)/ls.ld $(OBJS_$(d))
	$(L_LINK)
