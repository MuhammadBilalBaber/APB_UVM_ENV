//------------------------------------------------------------------------------
// APB verification package.
//
// All UVM classes live in one package instead of being dropped into the
// compilation unit scope by each file. That removes the environment's
// dependency on the whole file list being compiled as a single unit, and makes
// the include order below the only place where class dependencies are stated.
//------------------------------------------------------------------------------

package apb_pkg;

  import uvm_pkg::*;
`include "uvm_macros.svh"

  // Sequence item and configuration
`include "apb_seq_item.sv"
`include "apb_config.sv"

  // Agent
`include "apb_sequencer.sv"
`include "apb_driver.sv"
`include "apb_monitor.sv"
`include "apb_agent.sv"

  // Analysis components and environment
`include "apb_functional_coverage.sv"
`include "apb_scoreboard.sv"
`include "apb_environment.sv"
`include "apb_env_builder.sv"

  // Sequences
`include "apb_base_sequence.sv"
`include "apb_bringup_sequence.sv"
`include "apb_bringup_read_sequence.sv"
`include "apb_write_read_sequence.sv"

  // Tests
`include "apb_base_test.sv"
`include "apb_bring_up_test.sv"
`include "apb_multi_param_test.sv"

endpackage : apb_pkg
