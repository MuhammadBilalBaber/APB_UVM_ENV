`include "uvm_macros.svh"
import uvm_pkg::*;
class apb_agent #(int ADDR_WIDTH=256, int DATA_WIDTH=256) extends uvm_agent;

  typedef apb_agent #(ADDR_WIDTH, DATA_WIDTH) apb_agent;

  // Factory Registration

  `uvm_component_utils (apb_agent#(ADDR_WIDTH, DATA_WIDTH))

  // Sequencer

  apb_sequencer#(ADDR_WIDTH, DATA_WIDTH) apb_seqr;
  // Driver
  apb_driver#(ADDR_WIDTH, DATA_WIDTH)    apb_drvr;
  // Monitor
  apb_monitor#(ADDR_WIDTH, DATA_WIDTH)   apb_montr;

  // Constructor
  function new(string name = "apb_agent", uvm_component parent = null); 
    super.new(name, parent);
  endfunction: new

  // Build Phase

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_seqr = apb_sequencer#(ADDR_WIDTH, DATA_WIDTH)::type_id::create("apb_seqr", this);
    apb_drvr = apb_driver#(ADDR_WIDTH, DATA_WIDTH)::type_id::create("apb drvr", this);
    apb_montr= apb_monitor#(ADDR_WIDTH, DATA_WIDTH)::type_id::create("apb_montr", this);
  endfunction : build_phase

  // Connect Phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase); 
    apb_drvr.seq_item_port.connect(apb_seqr.seq_item_export);
  endfunction: connect_phase
                                   
endclass: apb_agent