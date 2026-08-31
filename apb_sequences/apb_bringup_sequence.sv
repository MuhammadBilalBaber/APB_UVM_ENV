//------------------------------------------------------------------------------
// Bring-up write sequence: a burst of writes into the legal address window.
//------------------------------------------------------------------------------

class apb_bringup_sequence #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends apb_base_sequence #(ADDR_WIDTH, DATA_WIDTH);

  `uvm_object_param_utils(apb_bringup_sequence#(ADDR_WIDTH, DATA_WIDTH))

  function new(string name = "apb_bringup_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    get_cfg();
    `uvm_info(get_type_name(), $sformatf("starting %0d write transfers", num_trans), UVM_LOW)
    repeat (num_trans)
      write_data();
  endtask : body

  virtual task write_data();
    req = new_item("req");
    start_item(req);
    if (!req.randomize() with { pwrite == 1'b1; })
      `uvm_fatal(get_type_name(), "randomization of a write transfer failed")
    finish_item(req);
  endtask : write_data

endclass : apb_bringup_sequence
