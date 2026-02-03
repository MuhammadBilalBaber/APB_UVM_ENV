`include "uvm_macros.svh"
import uvm_pkg::*;
class apb_monitor #(int ADDR_WIDTH=256, int DATA_WIDTH=256) extends uvm_monitor;

  typedef apb_monitor #(ADDR_WIDTH, DATA_WIDTH) apb_monitor;

  // Factor registration

  `uvm_component_utils(apb_monitor)

  virtual apb_interface apb_intf;

  apb_seq_item#(ADDR_WIDTH, DATA_WIDTH) trans;
    
  uvm_analysis_port#(apb_seq_item#(ADDR_WIDTH, DATA_WIDTH)) apb_mon_port;

   // Constructor

  function new(string name ="apb_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

    // Build Phase

  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
      if(!uvm_config_db#(virtual apb_interface)::get(this, "", "apb_intf", apb_intf)) 	
        `uvm_fatal(get_type_name(), "Interface cannot be accessed in Monitor")
	  apb_mon_port = new("apb_mon_port",this);
  endfunction : build_phase

    // Task run Phase

  task run_phase (uvm_phase phase);
    forever begin
	    collect_trans();
	  end
  endtask: run_phase

  task collect_trans();
    trans =  apb_seq_item#(ADDR_WIDTH, DATA_WIDTH)::type_id::create("trans",this);
	  // waitfapb intf.pready):
      wait (apb_intf.penable && apb_intf.pready && apb_intf.psel);
	  trans.psel    = apb_intf.psel;
	  trans.paddr   = apb_intf.paddr;
	  trans.pwdata  = apb_intf.pwdata;
	  trans.pwrite  = apb_intf.pwrite;
	  trans.penable = apb_intf.penable;
	  trans.prdata  = apb_intf.prdata;
	  trans.pready  = apb_intf.pready;
	  trans.pslver  = apb_intf.pslverr;
    // (posedge apb intf.clock):
    `uvm_info(get_type_name(), $sformatf("The psel is %0d",    trans.psel),    UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("The paddr is %0d",   trans.paddr),   UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("The pwdata is %0d",  trans.pwdata),  UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("The pwrite is %0d",  trans.pwrite),  UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("The penable is %0d", trans.penable), UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("The prdata is %0d",  trans.prdata),  UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("The pready is %0d",  trans.pready),  UVM_LOW);
    `uvm_info(get_type_name(), $sformatf("The pslver is %0d",  trans.pslver),  UVM_LOW);
    
    apb_mon_port.write(trans);

    @(posedge apb_intf.clock);
    @(posedge apb_intf.clock);
    
  endtask : collect_trans
      
endclass : apb_monitor