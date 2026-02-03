`include "uvm_macros.svh"
import uvm_pkg::*;
class apb_sequencer #(int ADDR_WIDTH=32, int DATA_WIDTH=32) extends uvm_sequencer#(apb_seq_item);
  
  typedef apb_sequencer #(ADDR_WIDTH, DATA_WIDTH) apb_sequencer;
	
  `uvm_component_utils (apb_sequencer #(ADDR_WIDTH, DATA_WIDTH))

  // Constructor

  function new(string name = "apb_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

endclass : apb_sequencer