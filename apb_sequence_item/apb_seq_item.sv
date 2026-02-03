
// Parameterized sequence item that takes the address
// and Data_width as a parameter from the user
class apb_seq_item #(int ADDR_WIDTH=256, int DATA_WIDTH=256) extends uvm_sequence_item;

  typedef apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) apb_seq_item;

  function new(string name="apb_seq_item");
    super.new(name);
  endfunction : new
  
  // Request data Properties
  
  rand logic [ADDR_WIDTH-1:0] paddr;
  rand logic psel ;
  rand logic penable;
  rand logic [DATA_WIDTH-1:0] pwdata;
  rand logic pwrite;

  // Response data Properties
  
  logic [DATA_WIDTH-1:0] prdata;
  logic pready;
  logic pslver;

  // Factory registration

  // uvm_object_param_utils_begin(apb_seq_item#(ADDR_WIDTH, DATA_WIDTH))// #(ADDR_WIDTH, DATA_WIDTH))

  `uvm_object_param_utils_begin(apb_seq_item)// #(ADDR_WIDTH, DATA_WIDTH))
    `uvm_field_int (paddr,   UVM_ALL_ON)
	  `uvm_field_int(psel,     UVM_ALL_ON)
	  `uvm_field_int (penable, UVM_ALL_ON)
	  `uvm_field_int(pwdata,   UVM_ALL_ON)
	  `uvm_field_int (pwrite,  UVM_ALL_ON)
	`uvm_object_utils_end
	
  // Constraint
endclass : apb_seq_item