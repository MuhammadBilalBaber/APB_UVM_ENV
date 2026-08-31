//------------------------------------------------------------------------------
// Per-instance APB configuration.
//
// Carries the virtual interface plus the knobs that decide what an environment
// instance builds. Because the class is parameterized, uvm_config_db entries
// for two different width combinations are different types and cannot be
// accidentally crossed over.
//------------------------------------------------------------------------------

class apb_config #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_object;

  `uvm_object_param_utils(apb_config#(ADDR_WIDTH, DATA_WIDTH))

  virtual apb_interface #(ADDR_WIDTH, DATA_WIDTH) vif;

  uvm_active_passive_enum is_active         = UVM_ACTIVE;
  bit                     enable_coverage   = 1'b1;
  bit                     enable_scoreboard = 1'b1;

  // Must match the MEM_DEPTH parameter of the connected completer so that
  // stimulus and the scoreboard agree on the legal address window.
  int unsigned mem_depth = 1024;

  // Number of clocks the driver waits for PREADY before flagging an error.
  int unsigned max_wait_cycles = 64;

  function new(string name = "apb_config");
    super.new(name);
  endfunction : new

  function int unsigned bytes_per_word();
    return DATA_WIDTH / 8;
  endfunction : bytes_per_word

  // Highest legal (aligned) byte address of the completer.
  function bit [ADDR_WIDTH-1:0] max_addr();
    return ADDR_WIDTH'((longint'(mem_depth) - 1) * bytes_per_word());
  endfunction : max_addr

  // Catches a configuration that cannot be addressed with the chosen widths
  // before it turns into a stream of confusing PSLVERR responses.
  function bit is_legal(output string reason);
    if (DATA_WIDTH < 8 || (DATA_WIDTH % 8) != 0) begin
      reason = $sformatf("DATA_WIDTH (%0d) must be a multiple of 8 and at least 8", DATA_WIDTH);
      return 0;
    end
    if (mem_depth < 2 || (mem_depth & (mem_depth - 1)) != 0) begin
      reason = $sformatf("mem_depth (%0d) must be a power of two and at least 2", mem_depth);
      return 0;
    end
    if (ADDR_WIDTH < 64 &&
        (longint'(mem_depth) * bytes_per_word()) > (longint'(1) << ADDR_WIDTH)) begin
      reason = $sformatf("ADDR_WIDTH (%0d) cannot address %0d words of %0d bits",
                         ADDR_WIDTH, mem_depth, DATA_WIDTH);
      return 0;
    end
    reason = "";
    return 1;
  endfunction : is_legal

  virtual function string convert2string();
    return $sformatf("ADDR_WIDTH=%0d DATA_WIDTH=%0d mem_depth=%0d max_addr=0x%0h %s cov=%0b scb=%0b",
                     ADDR_WIDTH, DATA_WIDTH, mem_depth, max_addr(),
                     is_active.name(), enable_coverage, enable_scoreboard);
  endfunction : convert2string

endclass : apb_config
