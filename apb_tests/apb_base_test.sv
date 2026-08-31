//------------------------------------------------------------------------------
// Base test: shared reporting and end-of-test bookkeeping.
//------------------------------------------------------------------------------

class apb_base_test extends uvm_test;

  `uvm_component_utils(apb_base_test)

  function new(string name = "apb_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction : end_of_elaboration_phase

  virtual function void report_phase(uvm_phase phase);
    uvm_report_server svr = uvm_report_server::get_server();
    super.report_phase(phase);
    if (svr.get_severity_count(UVM_ERROR) == 0 && svr.get_severity_count(UVM_FATAL) == 0)
      `uvm_info(get_type_name(), "TEST PASSED", UVM_NONE)
    else
      `uvm_info(get_type_name(), "TEST FAILED", UVM_NONE)
  endfunction : report_phase

endclass : apb_base_test
