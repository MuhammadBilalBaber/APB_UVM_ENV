`include "uvm_macros.svh"
import uvm_pkg::*;
class apb_environment extends uvm_env;

  // factory Registration

  `uvm_component_utils(apb_environment)

  // Agent

  import apb_param_pkg::*;

  apb_agent#(ADDR_W, DATA_W) apb_agnt;

  apb_functional_coverage#(ADDR_W, DATA_W) apb_funct_cov;

  // Constructor

  function new(string name = "apb_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  // Build Phase

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    apb_agnt = apb_agent#(ADDR_W, DATA_W)::type_id::create("apb_agnt", this);
    apb_funct_cov = apb_functional_coverage#(ADDR_W, DATA_W)::type_id::create("apb_funct_cov", this);
  endfunction : build_phase

  // Connect Phase

  virtual function void connect_phase(uvm_phase phase);
    apb_agnt.apb_montr.apb_mon_port.connect(apb_funct_cov.analysis_export);
  endfunction : connect_phase


endclass : apb_environment