//------------------------------------------------------------------------------
// APB sequence item.
//
// Only the fields a sequence is allowed to choose are rand: address, direction
// and write payload. PSEL/PENABLE are protocol handshaking owned by the driver
// and are recorded by the monitor for coverage rather than randomized.
//------------------------------------------------------------------------------

class apb_seq_item #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_sequence_item;

  localparam int BYTES_PER_WORD = DATA_WIDTH / 8;

  localparam bit [ADDR_WIDTH-1:0] ALIGN_MASK = BYTES_PER_WORD - 1;

  // Stimulus
  rand bit [ADDR_WIDTH-1:0] paddr;
  rand bit                  pwrite;
  rand bit [DATA_WIDTH-1:0] pwdata;

  // Response, filled in by the driver / monitor
  bit [DATA_WIDTH-1:0] prdata;
  bit                  pslverr;

  // Observed handshaking, filled in by the monitor
  bit psel;
  bit penable;
  bit pready;

  // Upper bound of the legal address window. A sequence sets this from the
  // agent configuration before randomizing so that stimulus stays in range
  // whatever the widths are.
  bit [ADDR_WIDTH-1:0] max_addr = '1;

  constraint c_addr_aligned {
    (paddr & ALIGN_MASK) == '0;
  }

  constraint c_addr_in_range {
    paddr <= max_addr;
  }

  `uvm_object_param_utils(apb_seq_item#(ADDR_WIDTH, DATA_WIDTH))

  function new(string name = "apb_seq_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("%s addr=0x%0h wdata=0x%0h rdata=0x%0h pslverr=%0b (A%0d/D%0d)",
                     pwrite ? "WRITE" : "READ ", paddr, pwdata, prdata, pslverr,
                     ADDR_WIDTH, DATA_WIDTH);
  endfunction : convert2string

  virtual function void do_copy(uvm_object rhs);
    apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) that;
    if (!$cast(that, rhs)) begin
      `uvm_fatal("APB_ITEM", "do_copy: type mismatch")
    end
    super.do_copy(rhs);
    paddr   = that.paddr;
    pwrite  = that.pwrite;
    pwdata  = that.pwdata;
    prdata  = that.prdata;
    pslverr = that.pslverr;
    psel    = that.psel;
    penable = that.penable;
    pready  = that.pready;
    max_addr = that.max_addr;
  endfunction : do_copy

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) that;
    if (!$cast(that, rhs))
      return 0;
    return super.do_compare(rhs, comparer)
           && (paddr   === that.paddr)
           && (pwrite  === that.pwrite)
           && (pwdata  === that.pwdata)
           && (prdata  === that.prdata)
           && (pslverr === that.pslverr);
  endfunction : do_compare

  virtual function void do_print(uvm_printer printer);
    printer.print_string("transfer", convert2string());
  endfunction : do_print

endclass : apb_seq_item
