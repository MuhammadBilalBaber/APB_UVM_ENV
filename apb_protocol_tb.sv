//------------------------------------------------------------------------------
// Non-UVM protocol testbench.
//
// Reproduces the bus timing of apb_driver (SETUP -> ACCESS -> sample on the
// edge where PREADY is high) so that the completer and the protocol assertions
// can be exercised in a simulator with no UVM support, for example Verilator.
// It is a smoke test for the RTL half of the environment, not a replacement for
// the UVM tests.
//
// Signals are driven with non-blocking assignments at the clock edge and read
// immediately after it, which is the same scheduling the mst_cb clocking block
// gives ("output #0 / input #1step").
//------------------------------------------------------------------------------

module apb_master_check #(
  parameter int ID         = 0,
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int MEM_DEPTH  = 1024
) (
  input  logic        pclk,
  input  logic        presetn,

  output logic [ADDR_WIDTH-1:0] paddr,
  output logic                  psel,
  output logic                  penable,
  output logic                  pwrite,
  output logic [DATA_WIDTH-1:0] pwdata,
  input  logic [DATA_WIDTH-1:0] prdata,
  input  logic                  pready,
  input  logic                  pslverr,

  output int unsigned num_checks,
  output int unsigned num_errors,
  output bit          done
);

  localparam int     BYTES    = DATA_WIDTH / 8;
  localparam longint MAX_ADDR = (longint'(MEM_DEPTH) - 1) * longint'(BYTES);

  // Stimulus is applied DRIVE_SKEW after the rising edge and responses are read
  // in the active region of an edge, before the completer's non-blocking
  // updates land. That is the same ordering the mst_cb clocking block gives the
  // UVM driver, expressed so it holds in a simulator that rewrites '<=' inside
  // an initial block into a blocking assignment.
  localparam time DRIVE_SKEW = 1ns;

  task automatic transfer(input  bit [ADDR_WIDTH-1:0] addr,
                          input  bit                  wr,
                          input  bit [DATA_WIDTH-1:0] wdata,
                          output bit [DATA_WIDTH-1:0] rdata,
                          output bit                  slverr);
    int unsigned edges = 0;

    @(posedge pclk);
    #DRIVE_SKEW;
    paddr   = addr;
    pwrite  = wr;
    pwdata  = wr ? wdata : '0;
    psel    = 1'b1;
    penable = 1'b0;

    @(posedge pclk);
    #DRIVE_SKEW;
    penable = 1'b1;

    do begin
      @(posedge pclk);
      edges++;
      if (edges > 64) begin
        $error("[%0d] PREADY never asserted for addr=0x%0h", ID, addr);
        num_errors++;
        break;
      end
    end while (pready !== 1'b1);

    rdata  = wr ? '0 : prdata;
    slverr = pslverr;

    #DRIVE_SKEW;
    psel    = 1'b0;
    penable = 1'b0;

    // A completer with a single wait state answers on the second ACCESS edge.
    if (edges != 2) begin
      $error("[%0d] expected 2 ACCESS edges, saw %0d for addr=0x%0h", ID, edges, addr);
      num_errors++;
    end
  endtask

  task automatic check(input string what, input bit ok);
    num_checks++;
    if (!ok) begin
      num_errors++;
      $error("[%0d] FAILED: %s", ID, what);
    end
  endtask

  initial begin
    bit [ADDR_WIDTH-1:0] addr;
    bit [DATA_WIDTH-1:0] wdata;
    bit [DATA_WIDTH-1:0] rdata;
    bit                  slverr;
    int unsigned         step;

    num_checks = 0;
    num_errors = 0;
    done       = 1'b0;

    paddr   = '0;
    pwdata  = '0;
    psel    = 1'b0;
    penable = 1'b0;
    pwrite  = 1'b0;

    @(posedge presetn);
    @(posedge pclk);

    $display("[%0d] ADDR_WIDTH=%0d DATA_WIDTH=%0d MEM_DEPTH=%0d max_addr=0x%0h",
             ID, ADDR_WIDTH, DATA_WIDTH, MEM_DEPTH, MAX_ADDR);

    // Reset must leave the memory readable and zero.
    transfer(ADDR_WIDTH'(0), 1'b0, '0, rdata, slverr);
    check("read after reset returns 0", rdata == '0);
    check("read after reset has no PSLVERR", slverr == 1'b0);

    // Write / read-back across the legal window.
    step = (MEM_DEPTH > 16) ? MEM_DEPTH / 8 : 1;
    for (int unsigned w = 0; w < MEM_DEPTH; w += step) begin
      addr  = ADDR_WIDTH'(w * BYTES);
      wdata = '0;
      for (int b = 0; b < DATA_WIDTH; b += 8)
        wdata[b +: 8] = 8'((w + b) ^ 32'hA5);
      transfer(addr, 1'b1, wdata, rdata, slverr);
      check($sformatf("write to 0x%0h accepted", addr), slverr == 1'b0);
      transfer(addr, 1'b0, '0, rdata, slverr);
      check($sformatf("read-back of 0x%0h has no PSLVERR", addr), slverr == 1'b0);
      check($sformatf("read-back of 0x%0h expected 0x%0h got 0x%0h", addr, wdata, rdata),
            rdata === wdata);
    end

    // Highest legal word: where an off-by-one in the range check shows up.
    addr  = ADDR_WIDTH'(MAX_ADDR);
    wdata = '1;
    transfer(addr, 1'b1, wdata, rdata, slverr);
    check("write to the last legal word is accepted", slverr == 1'b0);
    transfer(addr, 1'b0, '0, rdata, slverr);
    check("last legal word reads back all ones", rdata === wdata);

    // First word past the end must report PSLVERR.
    if ((MAX_ADDR + longint'(BYTES)) <= ((longint'(1) << ADDR_WIDTH) - 1)) begin
      addr = ADDR_WIDTH'(MAX_ADDR + longint'(BYTES));
      transfer(addr, 1'b1, '1, rdata, slverr);
      check("write past the end reports PSLVERR", slverr == 1'b1);
      transfer(addr, 1'b0, '0, rdata, slverr);
      check("read past the end reports PSLVERR", slverr == 1'b1);
      check("read past the end returns 0", rdata == '0);
    end

    // Unaligned access must report PSLVERR and leave the word untouched.
    if (BYTES > 1) begin
      addr = ADDR_WIDTH'(BYTES) + ADDR_WIDTH'(1);
      transfer(addr, 1'b1, '1, rdata, slverr);
      check("unaligned write reports PSLVERR", slverr == 1'b1);
      transfer(addr, 1'b0, '0, rdata, slverr);
      check("unaligned read reports PSLVERR", slverr == 1'b1);
      transfer(ADDR_WIDTH'(BYTES), 1'b0, '0, rdata, slverr);
      check("word targeted by a rejected unaligned write is untouched", slverr == 1'b0);
    end

    // Back-to-back transfers: the case a combinational completer gets wrong.
    for (int unsigned n = 0; n < 4; n++) begin
      transfer(ADDR_WIDTH'(n * BYTES), 1'b1, DATA_WIDTH'(n) + DATA_WIDTH'(1), rdata, slverr);
      check("back-to-back write accepted", slverr == 1'b0);
    end
    for (int unsigned n = 0; n < 4; n++) begin
      transfer(ADDR_WIDTH'(n * BYTES), 1'b0, '0, rdata, slverr);
      check($sformatf("back-to-back read of word %0d returns %0d", n, n + 1),
            rdata === (DATA_WIDTH'(n) + DATA_WIDTH'(1)));
    end

    $display("[%0d] done: %0d checks, %0d errors", ID, num_checks, num_errors);
    done = 1'b1;
  end

endmodule : apb_master_check


module apb_protocol_tb;

  import apb_param_pkg::*;

  localparam time CLK_PERIOD = 10ns;

  bit   pclk;
  logic presetn;

  int unsigned checks_per_inst [NUM_APB];
  int unsigned errors_per_inst [NUM_APB];
  bit          done_per_inst   [NUM_APB];

  always #(CLK_PERIOD / 2) pclk = ~pclk;

  initial begin
    presetn = 1'b0;
    // Released off the active edge so the completer's asynchronous reset can
    // never race with a clock edge.
    repeat (5) @(negedge pclk);
    presetn = 1'b1;
  end

  for (genvar i = 0; i < NUM_APB; i++) begin : apb_inst

    // Raw signals rather than apb_interface, because a clocking-block output
    // cannot be the target of a continuous assignment from a module port. The
    // protocol assertions still apply: apb_protocol_checker_bind.sv binds them
    // onto every apb_s instance.
    logic [APB_ADDR_W[i]-1:0] paddr;
    logic                     psel;
    logic                     penable;
    logic                     pwrite;
    logic [APB_DATA_W[i]-1:0] pwdata;
    logic [APB_DATA_W[i]-1:0] prdata;
    logic                     pready;
    logic                     pslverr;

    apb_s #(
      .ADDR_WIDTH (APB_ADDR_W[i]),
      .DATA_WIDTH (APB_DATA_W[i]),
      .MEM_DEPTH  (APB_MEM_DEPTH[i])
    ) apb_completer (
      .pclk    (pclk),
      .presetn (presetn),
      .paddr   (paddr),
      .psel    (psel),
      .penable (penable),
      .pwrite  (pwrite),
      .pwdata  (pwdata),
      .prdata  (prdata),
      .pready  (pready),
      .pslverr (pslverr)
    );

    apb_master_check #(
      .ID         (i),
      .ADDR_WIDTH (APB_ADDR_W[i]),
      .DATA_WIDTH (APB_DATA_W[i]),
      .MEM_DEPTH  (APB_MEM_DEPTH[i])
    ) apb_check (
      .pclk       (pclk),
      .presetn    (presetn),
      .paddr      (paddr),
      .psel       (psel),
      .penable    (penable),
      .pwrite     (pwrite),
      .pwdata     (pwdata),
      .prdata     (prdata),
      .pready     (pready),
      .pslverr    (pslverr),
      .num_checks (checks_per_inst[i]),
      .num_errors (errors_per_inst[i]),
      .done       (done_per_inst[i])
    );

  end : apb_inst

  initial begin
    int unsigned total_checks;
    int unsigned total_errors;
    bit          all_done;

    total_checks = 0;
    total_errors = 0;
    all_done     = 0;

    // Bounded wait so a hang fails the run instead of spinning forever.
    fork
      begin
        while (!all_done) begin
          @(posedge pclk);
          all_done = 1;
          foreach (done_per_inst[j])
            if (!done_per_inst[j]) all_done = 0;
        end
      end
      begin
        #(CLK_PERIOD * 20000);
        $display("TIMEOUT: not every instance finished");
        total_errors++;
      end
    join_any

    foreach (checks_per_inst[j]) total_checks += checks_per_inst[j];
    foreach (errors_per_inst[j]) total_errors += errors_per_inst[j];

    $display("--------------------------------------------------------");
    $display("instances       : %0d", NUM_APB);
    $display("checks executed : %0d", total_checks);
    $display("errors          : %0d", total_errors);
    if (total_errors == 0 && total_checks > 0)
      $display("APB PROTOCOL TB PASSED");
    else
      $display("APB PROTOCOL TB FAILED");
    $display("--------------------------------------------------------");
    $finish;
  end

endmodule : apb_protocol_tb
