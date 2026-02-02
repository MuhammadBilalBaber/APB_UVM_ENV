

interface apb_interface #(parameter ADDR_WIDTH= 256, parameter DATA_WIDTH=256) (input bit clock, input logic reset_n);
  logic [ADDR_WIDTH-1:0] paddr   ;
  logic                  psel    ;
  logic				     penable ;
  logic [DATA_WIDTH-1:0] pwdata  ;
  logic                  pwrite  ;
  logic [DATA_WIDTH-1:0] prdata  ;
  logic                  pready  ;
  logic				     pslverr ;

endinterface : apb_interface