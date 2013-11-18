# Makefile for generating boostlogic VHDL library
#
# Author: Scott Teal (Scott@Teals.org)
# Created: 2013-10-11
#
# All targets beginning with "ms_" are to compile code for simulation with 
# Modelsim.

include Makefile.inc

.PHONY: all basic basic_tb init clean
all: modelsim

modelsim: ms_comm_systems_tb ms_rf_blocks_tb ms_basic_tb

modelsim_test: ms_basic_tb

test: ms_basic_tb

ms_comm_systems_tb: ms_comm_systems
	cd src/comm_systems_tb; $(MAKE) $(MFLAGS) modelsim

ms_comm_systems: ms_rf_blocks
	cd src/comm_systems; $(MAKE) $(MFLAGS) modelsim

ms_rf_blocks_tb: ms_rf_blocks
	cd src/rf_blocks_tb; $(MAKE) $(MFLAGS) modelsim

ms_rf_blocks: ms_basic
	cd src/rf_blocks; $(MAKE) $(MFLAGS) modelsim

ms_basic_tb: ms_basic
	cd src/basic_tb; $(MAKE) $(MFLAGS) modelsim

ms_basic: ms_fixed ms_util
	cd src/basic; $(MAKE) $(MFLAGS) modelsim

ms_util: ms_vendor ms_fixed ./src/util_pkg.vhd
	$(VCOM) -work $(LIB_DIR) ./src/util_pkg.vhd

ms_vendor: ms_fixed
	cd src/$(VENDOR); $(MAKE) $(MFLAGS) modelsim

ms_fixed: ./src/fixed_pkg.vhd
	$(VCOM) -work $(LIB_DIR) ./src/fixed_pkg.vhd


init:
	vmap -c
	vlib $(LIB_DIR)
	vmap $(LIB_DIR) $(LIB_DIR)
	vlib $(TEST_DIR)
	vmap $(TEST_DIR) $(TEST_DIR)

clean:
	rm -r $(LIB_DIR)
	rm -r $(TEST_DIR)
	vlib $(LIB_DIR)
	vlib $(TEST_DIR)

hardclean: clean
	rm -rf modelsim.ini
