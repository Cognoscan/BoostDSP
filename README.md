BoostDSP
========

VHDL Library for implementing common DSP functionality.

It compiles into two libraries: boostdsp and boostdsp_tb. The second library, 
boostdsp_tb contains testbenches for each entity.

## Introduction ##

I'm creating the BoostDSP library so there can be a general signal processing 
library available in VHDL. To my knowledge, no such library existed before this 
one. While OpenCores does have some signal processing code available, I found it 
both completely inadequete for my use and inconsistant in coding style. As 
someone still learning VHDL and real-world DSP techniques, I was really hoping 
for a more complete set of reference code; something I could use to learn better 
coding practices. There's a fair bit available if one is interested in 
re-implementing a particular digital architecture, but very little for signal 
processing applications, especially ones targeting the RF and Software-Defined 
Radio domain. 

My hope is that this library will help people avoid the problems I ran into when 
starting out. It should serve as a good set of examples of VHDL-2008, and should 
help tie theory to actual implementation.

I'm calling this library BoostDSP after the popular Boost C++ libraries, as I 
hope it can be similarly useful for VHDL programmers. The library is designed to 
be as reusable as possible, and will hopefully grow to be an example of good 
VHDL coding practices and techniques.

## Design Decisions ##

No design is truly optimal; there are always compromises to be made, and this 
library is no different. First is that the default blocks assume new data 
arrives with each rising clock edge. This is a pretty big assumption; the reason 
I'm doing it is that I find pipelined implementations to be the easiest to 
write and understand, especially when viewed as a flowchart. Polyphase 
implementations and ones that use a data strobe are present in this library as 
well, but their entity names either begin with `polyphase_` or `strobed_`. When 
someone is first learning to do signal processing with VHDL, I hope they will 
find the pipeline implementations easy to understand, and that they will help 
facilitate understanding of the polyphase and data strobe implementations.

Another major design decision made is one of efficiency vs. delay time: when 
given an option between the two, efficiency comes first. It is always assumed 
that a bit of extra delay in the processing pipeline is acceptable to the 
system. When delay between input and output needs to be minimized, other 
implementations besides the ones found here may fit your needs better. If you 
don't care, then you'll find the implementations in this library to (hopefully) 
be close to optimal in terms of size and efficiency.

This library makes heavy use of the VHDL-2008 fixed-point library; in fact, all 
data is formated as fixed-point data. This better mirrors other DSP toolkits 
like GNURadio and Simulink, and internally functions very much like a library 
using signed and unsigned VHDL data types, with the advantage of having rounding 
and saturation rules. I find it also helps tie DSP theory to practice better, as 
one doesn't have to worry about scaling numbers to integers.

The final decision is to design everything to be as reusable as possible; if 
something can be parameterized, it will be. To do this, the library is written 
using VHDL-2008 constructs, and makes heavy use of unconstrained array types. If 
you cannot use VHDL-2008 for whatever reason, this is probably not the library 
for you.

## Contributing ##

I am still very new to VHDL, digital signal processing, and the industry in 
general. So if you find code errors, or know how to make one of these designs 
more efficient, please tell me! Even better: fork this repository and show me! 
Any contributions to this code base will be greatly appreciated and 
acknowledged, and will help improve this library for everyone. I would love to 
discuss use cases as well, especially if you think this library is insufficient 
or makes some very poor design assumptions. There is, after all, *always* room 
for improvement.

## Package Overview ##

- Basic Package - basic_pkg
- RF Blocks Package - rf_blocks_pkg
- Communications Systems Package - comm_systems_pkg

## Basic Package ##

The basic package contains some fundamental components, which don't rely on any 
other portions of the BoostDSP library. It contains:

- file_sink: writes data to a file on each rising edge of clk.

- file_source: outputs data from a file on each rising edge of clk. Can act like 
an arbitrary waveform generator.

- fir: Pipelined (systolic) FIR filter. Can be configured to be more efficient 
for symmetric filters (even or odd). Coefficients are configured via a port, so 
it can be adjusted while running.

- lfsr_direct: Uses an LFSR to generate random-looking data. Uses direct 
feedback, rather than a Galois LFSR implementation.

- lfsr_galois: Uses an LFSR to generate random-looking data. Uses a Galois 
feedback implementation.

- mapper: Maps symbols to I and Q values using a lookup table.

- symbolizer: Takes data of arbitrary length and turns it into a series of 
shorter-length symbols

- symbolizer_even: Like symbolizer, but optimized for when the data divides 
perfectly into symbols (ex. 8-bit data to 2-bit symbols).

- trig_table: takes in a value `angle` and uses a lookup table to generate 
cos(2*pi*angle) and sin(2*pi*angle).

## RF Blocks Package ##

The RF blocks package contains components built on top of the components found 
in the Basic Package. It contains:

- dds: Takes in a ufixed value, `freq`, between 0 and 1 and generates two 
sinusoidal waves 90 degrees out of phase based on it. The frequency is `freq * 
clk_freq`, where `clk_freq` is the frequency of the clock driving the DDS 
component.

- frame_tx: Controller for frame transmission. It provides a buffer to read and 
write to, and will take care of turning the entire buffer into a stream of 
symbols when told to.

- poly_dds: Polyphase Direct Digital Synthesizer. Works like the dds component, 
but generates multiple phase-shifted versions of the signal. Makes it possible 
to generate sinusoidal waves at frequencies higher than the system clock.

## Communication Systems Package ##

The Communication Systems package contains components that actually implement 
the PHY layer of a wireless communication system. It does not cover higher-layer 
features, like any kind of flow control. Really, this is a reference for what 
kind of things can be done with the rest of the BoostDSP library.

- simple_tx: Provides a frame buffer, maps data to I and Q value pairs, and has 
the option of using a DDS to modulate the I and Q data onto a particular 
frequency.


