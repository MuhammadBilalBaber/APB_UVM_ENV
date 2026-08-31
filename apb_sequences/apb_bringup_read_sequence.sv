//------------------------------------------------------------------------------
// Bring-up read sequence: a burst of reads from the legal address window.
//------------------------------------------------------------------------------

class apb_bringup_read_sequence #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends apb_base_sequence #(ADDR_WIDTH, DATA_WIDTH);

  `uvm_object_param_utils(apb_bringup_read_sequence#(ADDR_WIDTH, DATA_WIDTH))

  function new(string name = "apb_bringup_read_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    get_cfg();
    `uvm_info(get_type_name(), $sformatf("starting %0d read transfers", num_trans), UVM_LOW)
    repeat (num_trans)
      read_data();
  endtask : body

  virtual task read_data();
    req = new_item("req");
    start_item(req);
    if (!req.randomize() with { pwrite == 1'b0; })
      `uvm_fatal(get_type_name(), "randomization of a read transfer failed")
    finish_item(req);
    `uvm_info(get_type_name(), {"read back ", req.convert2string()}, UVM_HIGH)
  endtask : read_data

endclass : apb_bringup_read_sequence
