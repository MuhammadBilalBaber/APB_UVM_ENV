//------------------------------------------------------------------------------
// Multi-parameter test.
//
// The point of the whole environment: four instances of the *same*
// apb_environment class, specialized differently, running at the same time
// against four differently sized completers. Instances 0 and 3 share a
// parameterization to prove that duplicate specializations coexist too.
//------------------------------------------------------------------------------

class apb_multi_param_test extends apb_base_test;

  `uvm_component_utils(apb_multi_param_test)

  localparam int AW0 = apb_param_pkg::APB_ADDR_W[0];
  localparam int DW0 = apb_param_pkg::APB_DATA_W[0];
  localparam int AW1 = apb_param_pkg::APB_ADDR_W[1];
  localparam int DW1 = apb_param_pkg::APB_DATA_W[1];
  localparam int AW2 = apb_param_pkg::APB_ADDR_W[2];
  localparam int DW2 = apb_param_pkg::APB_DATA_W[2];
  localparam int AW3 = apb_param_pkg::APB_ADDR_W[3];
  localparam int DW3 = apb_param_pkg::APB_DATA_W[3];

  apb_environment #(AW0, DW0) env0;
  apb_environment #(AW1, DW1) env1;
  apb_environment #(AW2, DW2) env2;
  apb_environment #(AW3, DW3) env3;

  function new(string name = "apb_multi_param_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env0 = apb_env_builder #(AW0, DW0)::build(this, "env0",
             apb_param_pkg::apb_vif_key(0), apb_param_pkg::APB_MEM_DEPTH[0]);
    env1 = apb_env_builder #(AW1, DW1)::build(this, "env1",
             apb_param_pkg::apb_vif_key(1), apb_param_pkg::APB_MEM_DEPTH[1]);
    env2 = apb_env_builder #(AW2, DW2)::build(this, "env2",
             apb_param_pkg::apb_vif_key(2), apb_param_pkg::APB_MEM_DEPTH[2]);
    env3 = apb_env_builder #(AW3, DW3)::build(this, "env3",
             apb_param_pkg::apb_vif_key(3), apb_param_pkg::APB_MEM_DEPTH[3]);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    apb_write_read_sequence #(AW0, DW0) seq0 = apb_write_read_sequence #(AW0, DW0)::type_id::create("seq0");
    apb_write_read_sequence #(AW1, DW1) seq1 = apb_write_read_sequence #(AW1, DW1)::type_id::create("seq1");
    apb_write_read_sequence #(AW2, DW2) seq2 = apb_write_read_sequence #(AW2, DW2)::type_id::create("seq2");
    apb_write_read_sequence #(AW3, DW3) seq3 = apb_write_read_sequence #(AW3, DW3)::type_id::create("seq3");

    phase.raise_objection(this);

    if (!seq0.randomize() with { num_trans == 8; }) `uvm_fatal(get_type_name(), "seq0 randomization failed")
    if (!seq1.randomize() with { num_trans == 8; }) `uvm_fatal(get_type_name(), "seq1 randomization failed")
    if (!seq2.randomize() with { num_trans == 8; }) `uvm_fatal(get_type_name(), "seq2 randomization failed")
    if (!seq3.randomize() with { num_trans == 8; }) `uvm_fatal(get_type_name(), "seq3 randomization failed")

    fork
      seq0.start(env0.sequencer());
      seq1.start(env1.sequencer());
      seq2.start(env2.sequencer());
      seq3.start(env3.sequencer());
    join

    phase.drop_objection(this);
  endtask : run_phase

endclass : apb_multi_param_test
