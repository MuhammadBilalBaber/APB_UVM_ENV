//------------------------------------------------------------------------------
// APB interface
//
// Parameterized on address and data width so that a single interface
// definition can serve every APB instance in the testbench. Each parameter
// combination is a distinct SystemVerilog type, which is what keeps the
// virtual-interface handles of two differently sized agents from being mixed up.
//------------------------------------------------------------------------------

interface apb_interface #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32
) (
  input logic pclk,
  input logic presetn
);

  logic [ADDR_WIDTH-1:0] paddr;
  logic                  psel;
  logic                  penable;
  logic                  pwrite;
  logic [DATA_WIDTH-1:0] pwdata;
  logic [DATA_WIDTH-1:0] prdata;
  logic                  pready;
  logic                  pslverr;

  // Requester (master) view: outputs are driven in the NBA region of the clock
  // edge and inputs are sampled just before it, so the driver can never race
  // with the completer.
  clocking mst_cb @(posedge pclk);
    default input #1step output #0;
    output paddr, psel, penable, pwrite, pwdata;
    input  prdata, pready, pslverr;
  endclocking

  // Passive view used by the monitor.
  clocking mon_cb @(posedge pclk);
    default input #1step;
    input paddr, psel, penable, pwrite, pwdata, prdata, pready, pslverr;
  endclocking

  // The protocol assertions live in apb_protocol_checker and are attached with
  // a bind statement (see apb_protocol_checker_bind.sv): an interface is not
  // allowed to instantiate a module directly.

endinterface : apb_interface
