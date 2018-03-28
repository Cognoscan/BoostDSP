BoostDSP Library
================

This is a library of HDL modules for implementing common DSP functionality. The 
library is split into two sections: a set of modules written in Verilog and a 
set of modules written in VHDL. The module sets are not identical; modules in 
Verilog may not be available in VHDL and vice-versa.

This library primarily consists of useful DSP functions I have needed for my 
personal projects, as well as any interesting DSP algorithms I've felt like 
implementing. As such, it reflects my areas of focus:

- VHDL: RF system functions, with a focus on high throughput
- Verilog: Filters, controllers, and sigma-delta modulators, with a focus on 
  efficient resource usage.
