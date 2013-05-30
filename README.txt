AFIT
CSCE 587 - Microprocessor Design
Final Project - Booth Multiplier
Jonathon Reinhart, Scott Dalrymple

Directory structure:

  asm         - PicoBlaze assembly code / related files
  vhdl        - Main project VHDL directory

  modelsim    - Altera Modelsim project. Used mainly for initial tests/simulations.
  ise         - Xilinx ISE project and related design files.


Key files:

  asm/program.psm               PicoBlaze assembly program
  vhdl/boothmult.vhdl           The actual Booth Multiplier component
  vhdl/booth_io_if.vhdl         I/O Interface to Booth Multiplier
  vhdl/top_level_entity.vhdl    Top-Level Entity, overall system integration with KCPSM3.



Build instructions:


 1)  Build PicoBlaze assembly code.

     To avoid errors when opening ISE project run /asm/build.bat first to build PROGRAM.VHD.
     This requires DOSBox 0.74 to be installed in C:\Program Files (x86)\DOSBox-0.74\

 2)  Build ISE project.

     Open the Xilinx ISE project in /ise/boothmult.xise, and build as usual.



     

