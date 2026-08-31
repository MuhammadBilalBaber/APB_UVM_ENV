//------------------------------------------------------------------------------
// APB environment.
//
// Parameterized on the same widths as everything below it, so a test can
// instantiate this environment as many times as it likes, with a different
// parameter set per instance, and each copy stays independent: its own
// configuration object, virtual interface, coverage model and scoreboard.
//------------------------------------------------------------------------------

class apb_environment #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_env;

  `uvm_component_param_utils(apb_environment#(ADDR_WIDTH, DATA_WIDTH))

  typedef apb_config             #(ADDR_WIDTH, DATA_WIDTH) apb_config_t;
  typedef apb_agent              #(ADDR_WIDTH, DATA_WIDTH) apb_agent_t;
  typedef apb_functional_coverage#(ADDR_WIDTH, DATA_WIDTH) apb_coverage_t;
  typedef apb_scoreboard         #(ADDR_WIDTH, DATA_WIDTH) apb_scoreboard_t;

  apb_config_t     cfg;

  apb_agent_t      apb_agnt;
  apb_coverage_t   apb_funct_cov;
  apb_scoreboard_t apb_scbd;

  function new(string name = "apb_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    string reason;

    super.build_phase(phase);

    if (!uvm_config_db #(apb_config_t)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(),
                 $sformatf("no apb_config#(%0d,%0d) found for %s",
                           ADDR_WIDTH, DATA_WIDTH, get_full_name()))

    if (!cfg.is_legal(reason))
      `uvm_fatal(get_type_name(), {"illegal configuration: ", reason})

    `uvm_info(get_type_name(), {"configuration: ", cfg.convert2string()}, UVM_LOW)

    uvm_config_db #(apb_config_t)::set(this, "*", "cfg", cfg);

    apb_agnt = apb_agent_t::type_id::create("apb_agnt", this);

    if (cfg.enable_coverage)
      apb_funct_cov = apb_coverage_t::type_id::create("apb_funct_cov", this);

    if (cfg.enable_scoreboard)
      apb_scbd = apb_scoreboard_t::type_id::create("apb_scbd", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (apb_funct_cov != null)
      apb_agnt.apb_montr.apb_mon_port.connect(apb_funct_cov.analysis_export);
    if (apb_scbd != null)
      apb_agnt.apb_montr.apb_mon_port.connect(apb_scbd.analysis_export);
  endfunction : connect_phase

  // Convenience accessor so a test does not have to reach through the agent.
  function apb_sequencer #(ADDR_WIDTH, DATA_WIDTH) sequencer();
    return apb_agnt.apb_seqr;
  endfunction : sequencer

endclass : apb_environment
