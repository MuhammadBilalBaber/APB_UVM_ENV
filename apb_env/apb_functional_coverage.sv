//------------------------------------------------------------------------------
// APB functional coverage.
//
// Address and data are bucketed before sampling instead of being covered
// directly: a coverpoint on a raw 64-bit PADDR would ask the simulator for an
// unusable number of automatic bins, and the bin set would change meaning every
// time the widths change. Buckets are derived from the configured address
// window, so the same coverage model is meaningful at every parameterization.
//------------------------------------------------------------------------------

class apb_functional_coverage #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_subscriber #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH));

  `uvm_component_param_utils(apb_functional_coverage#(ADDR_WIDTH, DATA_WIDTH))

  typedef apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) apb_item_t;
  typedef apb_config   #(ADDR_WIDTH, DATA_WIDTH) apb_config_t;

  localparam int NUM_ADDR_BINS = 8;

  typedef enum int unsigned {
    DATA_ZERO, DATA_LOW, DATA_MID, DATA_HIGH, DATA_ALL_ONES
  } data_bin_e;

  apb_config_t cfg;

  int unsigned num_sampled;

  covergroup apb_cov_group with function sample(bit                dir,
                                                bit                err,
                                                int unsigned       addr_bin,
                                                data_bin_e         data_bin);
    option.per_instance = 1;
    option.name         = "apb_cov_group";

    APB_WRITE: coverpoint dir {
      bins write = {1'b1};
      bins read  = {1'b0};
    }

    APB_SLVERR: coverpoint err {
      bins ok     = {1'b0};
      bins slverr = {1'b1};
    }

    APB_ADDR: coverpoint addr_bin {
      bins region[NUM_ADDR_BINS] = {[0:NUM_ADDR_BINS-1]};
    }

    APB_DATA: coverpoint data_bin {
      bins zero     = {DATA_ZERO};
      bins low      = {DATA_LOW};
      bins mid      = {DATA_MID};
      bins high     = {DATA_HIGH};
      bins all_ones = {DATA_ALL_ONES};
    }

    APB_DIR_X_ADDR : cross APB_WRITE, APB_ADDR;
    APB_DIR_X_SLVERR: cross APB_WRITE, APB_SLVERR;
  endgroup : apb_cov_group

  function new(string name = "apb_functional_coverage", uvm_component parent = null);
    super.new(name, parent);
    apb_cov_group = new();
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(apb_config_t)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "apb_config not found in the configuration database")
  endfunction : build_phase

  // Maps an address onto one of NUM_ADDR_BINS equal slices of the legal window.
  virtual function int unsigned addr_bin_of(bit [ADDR_WIDTH-1:0] addr);
    longint unsigned window = longint'(cfg.max_addr()) + 1;
    longint unsigned slice  = (window + NUM_ADDR_BINS - 1) / NUM_ADDR_BINS;
    int unsigned     idx;
    if (slice == 0)
      return 0;
    idx = int'(longint'(addr) / slice);
    return (idx >= NUM_ADDR_BINS) ? NUM_ADDR_BINS - 1 : idx;
  endfunction : addr_bin_of

  virtual function data_bin_e data_bin_of(bit [DATA_WIDTH-1:0] data);
    if (data == '0)
      return DATA_ZERO;
    if (data == '1)
      return DATA_ALL_ONES;
    if (data[DATA_WIDTH-1])
      return DATA_HIGH;
    if (DATA_WIDTH > 2 && data[DATA_WIDTH-2])
      return DATA_MID;
    return DATA_LOW;
  endfunction : data_bin_of

  virtual function void write(apb_item_t t);
    bit [DATA_WIDTH-1:0] payload = t.pwrite ? t.pwdata : t.prdata;
    num_sampled++;
    apb_cov_group.sample(t.pwrite, t.pslverr, addr_bin_of(t.paddr), data_bin_of(payload));
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(),
              $sformatf("sampled %0d transfers, functional coverage = %0.2f%%",
                        num_sampled, apb_cov_group.get_inst_coverage()), UVM_LOW)
  endfunction : report_phase

endclass : apb_functional_coverage
