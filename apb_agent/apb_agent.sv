//------------------------------------------------------------------------------
// APB agent.
//
// Builds the monitor unconditionally and the sequencer/driver pair only when
// configured active, and hands its configuration object down to its children.
//------------------------------------------------------------------------------

class apb_agent #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_agent;

  `uvm_component_param_utils(apb_agent#(ADDR_WIDTH, DATA_WIDTH))

  typedef apb_config    #(ADDR_WIDTH, DATA_WIDTH) apb_config_t;
  typedef apb_sequencer #(ADDR_WIDTH, DATA_WIDTH) apb_sequencer_t;
  typedef apb_driver    #(ADDR_WIDTH, DATA_WIDTH) apb_driver_t;
  typedef apb_monitor   #(ADDR_WIDTH, DATA_WIDTH) apb_monitor_t;

  apb_config_t    cfg;

  apb_sequencer_t apb_seqr;
  apb_driver_t    apb_drvr;
  apb_monitor_t   apb_montr;

  function new(string name = "apb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(apb_config_t)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "apb_config not found in the configuration database")

    is_active = cfg.is_active;

    // Children look the configuration up by themselves, which keeps the agent
    // reusable when it is instantiated somewhere else in the hierarchy.
    uvm_config_db #(apb_config_t)::set(this, "*", "cfg", cfg);

    apb_montr = apb_monitor_t::type_id::create("apb_montr", this);

    if (is_active == UVM_ACTIVE) begin
      apb_seqr = apb_sequencer_t::type_id::create("apb_seqr", this);
      apb_drvr = apb_driver_t::type_id::create("apb_drvr", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (is_active == UVM_ACTIVE) begin
      apb_drvr.seq_item_port.connect(apb_seqr.seq_item_export);
      apb_seqr.cfg = cfg;
    end
  endfunction : connect_phase

endclass : apb_agent
