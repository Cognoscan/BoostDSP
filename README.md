BoostDSP
========

VHDL Library for implementing common DSP functionality.

Compiles into two libraries: boostdsp and boostdsp_tb. The second library, 
boostdsp_tb contains testbenches for each entity.

## Package Overview ##

- Basic Package - basic_pkg
- RF Blocks Package - rf_blocks_pkg

## Basic Package ##

The basic package contains some fundamental components, which don't rely on any 
other portions of the BoostDSP library. It contains:

- trig_table : takes in a value `angle` and uses a lookup table to generate 
cos(2*pi*angle) and sin(2*pi*angle).

## RF Blocks Package ##

The RF blocks package contains components built on top of the components found 
in the Basic Package. It contains:

- dds : Takes in a ufixed value, `freq`, between 0 and 1 and generates two 
sinusoidal waves 90 degrees out of phase based on it. The frequency is `freq * 
clk_freq`, where `clk_freq` is the frequency of the clock driving the DDS 
component.

