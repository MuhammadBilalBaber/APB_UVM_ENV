//------------------------------------------------------------------------------
// APB sequencer.
//
// The base class is specialized with the *parameterized* item type, so a
// sequencer, its driver and the sequences running on it all agree on one type.
//------------------------------------------------------------------------------

class apb_sequencer #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_sequencer #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH));

  `uvm_component_param_utils(apb_sequencer#(ADDR_WIDTH, DATA_WIDTH))

  // Published to sequences through p_sequencer so that stimulus can size
  // itself to the instance it is running on.
  apb_config #(ADDR_WIDTH, DATA_WIDTH) cfg;

  function new(string name = "apb_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

endclass : apb_sequencer
