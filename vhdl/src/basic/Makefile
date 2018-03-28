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

modelsim: basic_pkg
	
basic_pkg: basic_pkg.vhd $(COMPILED)
	cd ../..; $(VCOM) -work $(LIB_DIR) ./src/basic/basic_pkg.vhd

../../$(LIB_DIR)/%/_primary.dat: %_ea.vhd
	cd ../..;	$(VCOM) -work $(LIB_DIR) ./src/basic/$<
