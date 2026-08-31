//------------------------------------------------------------------------------
// Write/read-back sequence.
//
// Each iteration writes a random aligned address and immediately reads the same
// address, which is what turns the scoreboard into a real end-to-end data
// integrity check at whatever width the instance is configured for.
//------------------------------------------------------------------------------

class apb_write_read_sequence #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends apb_base_sequence #(ADDR_WIDTH, DATA_WIDTH);

  `uvm_object_param_utils(apb_write_read_sequence#(ADDR_WIDTH, DATA_WIDTH))

  function new(string name = "apb_write_read_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bit [ADDR_WIDTH-1:0] addr;
    bit [DATA_WIDTH-1:0] data;

    get_cfg();
    `uvm_info(get_type_name(),
              $sformatf("starting %0d write/read-back pairs", num_trans), UVM_LOW)

    repeat (num_trans) begin
      req = new_item("wr");
      start_item(req);
      if (!req.randomize() with { pwrite == 1'b1; })
        `uvm_fatal(get_type_name(), "randomization of a write transfer failed")
      addr = req.paddr;
      data = req.pwdata;
      finish_item(req);

      req = new_item("rd");
      start_item(req);
      if (!req.randomize() with { pwrite == 1'b0; paddr == local::addr; })
        `uvm_fatal(get_type_name(), "randomization of a read transfer failed")
      finish_item(req);

      if (req.pslverr === 1'b0 && req.prdata !== data)
        `uvm_error(get_type_name(),
                   $sformatf("read-back mismatch at addr=0x%0h: wrote 0x%0h, read 0x%0h",
                             addr, data, req.prdata))
    end
  endtask : body

endclass : apb_write_read_sequence
