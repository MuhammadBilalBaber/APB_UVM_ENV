//------------------------------------------------------------------------------
// APB completer (slave) with a single wait state.
//
// PADDR is a byte address; the memory is DATA_WIDTH wide and MEM_DEPTH words
// deep, so the legal address window is 0 .. MEM_DEPTH*(DATA_WIDTH/8)-1.
// An unaligned, out-of-range or unknown address, or unknown write data, is
// reported back with PSLVERR and leaves the memory untouched.
//------------------------------------------------------------------------------

module apb_s #(
  parameter int ADDR_WIDTH = 32,
  parameter int DATA_WIDTH = 32,
  parameter int MEM_DEPTH  = 1024
) (
  input  logic                  pclk,
  input  logic                  presetn,
  input  logic [ADDR_WIDTH-1:0] paddr,
  input  logic                  psel,
  input  logic                  penable,
  input  logic                  pwrite,
  input  logic [DATA_WIDTH-1:0] pwdata,

  output logic [DATA_WIDTH-1:0] prdata,
  output logic                  pready,
  output logic                  pslverr
);

  localparam int BYTES_PER_WORD = DATA_WIDTH / 8;
  localparam int ADDR_LSB       = $clog2(BYTES_PER_WORD);
  localparam int INDEX_WIDTH    = $clog2(MEM_DEPTH);

  localparam logic [ADDR_WIDTH-1:0] ALIGN_MASK = BYTES_PER_WORD - 1;

  if (DATA_WIDTH < 8 || (DATA_WIDTH % 8) != 0)
    $error("apb_s: DATA_WIDTH (%0d) must be a multiple of 8 and at least 8", DATA_WIDTH);
  if (MEM_DEPTH < 2 || (MEM_DEPTH != (1 << INDEX_WIDTH)))
    $error("apb_s: MEM_DEPTH (%0d) must be a power of two and at least 2", MEM_DEPTH);
  if ((ADDR_LSB + INDEX_WIDTH) > ADDR_WIDTH)
    $error("apb_s: ADDR_WIDTH (%0d) is too narrow for MEM_DEPTH (%0d) x DATA_WIDTH (%0d)",
           ADDR_WIDTH, MEM_DEPTH, DATA_WIDTH);

  logic [DATA_WIDTH-1:0] mem [MEM_DEPTH];

  wire                   access    = psel && penable;
  wire [INDEX_WIDTH-1:0] word_idx  = paddr[ADDR_LSB +: INDEX_WIDTH];

  wire addr_unknown   = $isunknown(paddr);
  wire addr_unaligned = |(paddr & ALIGN_MASK);
  wire addr_oor       = (paddr >> ADDR_LSB) >= MEM_DEPTH;
  wire data_unknown   = pwrite && $isunknown(pwdata);

  wire transfer_err = addr_unknown | addr_unaligned | addr_oor | data_unknown;

  // A transfer is accepted on the first ACCESS-phase edge, which gives the
  // requester exactly one wait state.
  wire accept = access && !pready;

  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      pready  <= 1'b0;
      pslverr <= 1'b0;
      prdata  <= '0;
    end
    else if (accept) begin
      pready  <= 1'b1;
      pslverr <= transfer_err;
      if (!pwrite)
        prdata <= transfer_err ? '0 : mem[word_idx];
    end
    else begin
      pready  <= 1'b0;
      pslverr <= 1'b0;
    end
  end

  // Reset clears the model so that a read of a never-written location returns a
  // defined value rather than X, which keeps the scoreboard prediction simple.
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn)
      foreach (mem[i]) mem[i] <= '0;
    else if (accept && pwrite && !transfer_err)
      mem[word_idx] <= pwdata;
  end

endmodule : apb_s
