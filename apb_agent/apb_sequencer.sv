class apb_sequencer #(int ADDR WIDTH=32, int DATA_WIDTH=32) extends uvm_sequencer#(apb_seq_item);
  
  typedef apb_sequencer #(ADDR_WIDTH, DATA WIDTH) apb_sequencer;
	
  `uvm_component_utils (apb_sequencer #(ADDR WIDTH, DATA_WIDTH))

  // Constructor

  function new(string name = "apb_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction new

endclass apb_sequencer