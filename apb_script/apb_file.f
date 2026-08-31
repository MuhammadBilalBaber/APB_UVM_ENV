// APB UVM environment file list.
// APB_ROOT must point at the root of this repository.

+incdir+${APB_ROOT}/apb_sequence_item
+incdir+${APB_ROOT}/apb_config
+incdir+${APB_ROOT}/apb_agent
+incdir+${APB_ROOT}/apb_env
+incdir+${APB_ROOT}/apb_sequences
+incdir+${APB_ROOT}/apb_tests

// Design units first: the class package below refers to the interface type.
${APB_ROOT}/apb_protocol_checker.sv
${APB_ROOT}/apb_protocol_checker_bind.sv
${APB_ROOT}/apb_interface.sv
${APB_ROOT}/apb_dut.sv

// Parameter sets, then the class library (which includes every class file).
${APB_ROOT}/apb_packages/apb_param_pkg.sv
${APB_ROOT}/apb_packages/apb_pkg.sv

${APB_ROOT}/apb_tb_top.sv
