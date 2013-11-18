#
# Makefile for generating basic portion of boostlogic
#
# the basic folder should only contain entities that don't rely on anything else 
# in the library except for the utility packages. Their test benches should also 
# be included here.
#

include ../../Makefile.inc

VHDL = $(shell find -type f -name '*.vhd')

COMPILED = $(patsubst %_ea.vhd, ../../$(LIB_DIR)/%/_primary.dat, $(VHDL))

.PHONY: all
all: modelsim

modelsim: rf_blocks_pkg 
	
rf_blocks_pkg: rf_blocks_pkg.vhd $(COMPILED)
	cd ../..; $(VCOM) -work $(LIB_DIR) ./src/rf_blocks/rf_blocks_pkg.vhd

../../$(LIB_DIR)/%/_primary.dat: %_ea.vhd
	cd ../..;	$(VCOM) -work $(LIB_DIR) ./src/rf_blocks/$<
