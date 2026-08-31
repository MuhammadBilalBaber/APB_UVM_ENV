//------------------------------------------------------------------------------
// APB scoreboard.
//
// Keeps a reference memory image built purely from observed traffic, so it works
// for any width combination without knowing anything about the completer's
// internals. Transfers that come back with PSLVERR are counted but never
// change the reference image, matching the completer's error behaviour.
//------------------------------------------------------------------------------

class apb_scoreboard #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_subscriber #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH));

  `uvm_component_param_utils(apb_scoreboard#(ADDR_WIDTH, DATA_WIDTH))

  typedef apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) apb_item_t;
  typedef apb_config   #(ADDR_WIDTH, DATA_WIDTH) apb_config_t;

  localparam bit [ADDR_WIDTH-1:0] ALIGN_MASK = (DATA_WIDTH / 8) - 1;

  apb_config_t cfg;

  bit [DATA_WIDTH-1:0] ref_mem [bit [ADDR_WIDTH-1:0]];

  int unsigned num_writes;
  int unsigned num_reads;
  int unsigned num_matches;
  int unsigned num_mismatches;
  int unsigned num_slverr;

  function new(string name = "apb_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(apb_config_t)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "apb_config not found in the configuration database")
  endfunction : build_phase

  virtual function void write(apb_item_t t);
    bit [DATA_WIDTH-1:0] expected;
    bit                  expect_err;

    expect_err = !addr_is_legal(t.paddr);

    if (t.pslverr !== expect_err) begin
      `uvm_error(get_type_name(),
                 $sformatf("PSLVERR mismatch: expected %0b, got %0b for %s",
                           expect_err, t.pslverr, t.convert2string()))
    end

    if (t.pslverr) begin
      num_slverr++;
      return;
    end

    if (t.pwrite) begin
      ref_mem[t.paddr] = t.pwdata;
      num_writes++;
    end
    else begin
      expected = ref_mem.exists(t.paddr) ? ref_mem[t.paddr] : '0;
      num_reads++;
      if (t.prdata === expected) begin
        num_matches++;
        `uvm_info(get_type_name(),
                  $sformatf("read matched: addr=0x%0h data=0x%0h", t.paddr, t.prdata), UVM_HIGH)
      end
      else begin
        num_mismatches++;
        `uvm_error(get_type_name(),
                   $sformatf("read data mismatch at addr=0x%0h: expected 0x%0h, got 0x%0h",
                             t.paddr, expected, t.prdata))
      end
    end
  endfunction : write

  virtual function bit addr_is_legal(bit [ADDR_WIDTH-1:0] addr);
    if ((addr & ALIGN_MASK) != 0)
      return 0;
    return (addr <= cfg.max_addr());
  endfunction : addr_is_legal

  virtual function void check_phase(uvm_phase phase);
    if ((num_writes + num_reads + num_slverr) == 0)
      `uvm_error(get_type_name(), "no APB traffic reached the scoreboard")
    if (num_reads == 0)
      `uvm_warning(get_type_name(), "no read transfers were checked against the reference memory")
  endfunction : check_phase

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("writes=%0d reads=%0d matches=%0d mismatches=%0d pslverr=%0d",
                        num_writes, num_reads, num_matches, num_mismatches, num_slverr),
              UVM_LOW)
  endfunction : report_phase

endclass : apb_scoreboard
