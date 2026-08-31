//------------------------------------------------------------------------------
// Bring-up test: one environment on APB instance 0.
//
// Also exercises sequencer arbitration by starting a write and a read stream on
// the same sequencer concurrently.
//------------------------------------------------------------------------------

class apb_bring_up_test extends apb_base_test;

  `uvm_component_utils(apb_bring_up_test)

  localparam int AW = apb_param_pkg::APB_ADDR_W[0];
  localparam int DW = apb_param_pkg::APB_DATA_W[0];

  typedef apb_environment           #(AW, DW) apb_env_t;
  typedef apb_env_builder           #(AW, DW) apb_env_builder_t;
  typedef apb_bringup_sequence      #(AW, DW) apb_write_seq_t;
  typedef apb_bringup_read_sequence #(AW, DW) apb_read_seq_t;

  apb_env_t       apb_env;
  apb_write_seq_t apb_bringup_seq;
  apb_read_seq_t  apb_bringup_read_seq;

  function new(string name = "apb_bring_up_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_env = apb_env_builder_t::build(this, "apb_env",
                                       apb_param_pkg::apb_vif_key(0),
                                       apb_param_pkg::APB_MEM_DEPTH[0]);
  endfunction : build_phase

  virtual function void show_arb_cfg();
    UVM_SEQ_ARB_TYPE cur_arb = apb_env.sequencer().get_arbitration();
    `uvm_info(get_type_name(),
              $sformatf("sequencer arbitration is set to %s", cur_arb.name()), UVM_LOW)
  endfunction : show_arb_cfg

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    apb_env.sequencer().set_arbitration(UVM_SEQ_ARB_FIFO);
    show_arb_cfg();

    apb_bringup_seq      = apb_write_seq_t::type_id::create("apb_bringup_seq");
    apb_bringup_read_seq = apb_read_seq_t::type_id::create("apb_bringup_read_seq");

    if (!apb_bringup_seq.randomize() with { num_trans == 8; })
      `uvm_fatal(get_type_name(), "write sequence randomization failed")
    if (!apb_bringup_read_seq.randomize() with { num_trans == 8; })
      `uvm_fatal(get_type_name(), "read sequence randomization failed")

    // Both streams share one sequencer so the arbiter interleaves them. The
    // scoreboard predicts from the monitored order rather than the sequence
    // order, so interleaving cannot produce a false failure.
    fork
      apb_bringup_seq.start(apb_env.sequencer());
      apb_bringup_read_seq.start(apb_env.sequencer());
    join

    phase.drop_objection(this);
  endtask : run_phase

endclass : apb_bring_up_test
