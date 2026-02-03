`include "uvm_macros.svh"
import uvm_pkg::*;
class apb_driver #(int ADDR_WIDTH=256, int DATA_WIDTH=256) extends uvm_driver#(apb_seq_item);
	
  typedef apb_driver #(ADDR_WIDTH, DATA_WIDTH) apb_driver;

  //Factory registration

  `uvm_component_utils(apb_driver)

  virtual apb_interface apb_intf;

    // Constructor

  function new(string name = "apb_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

    // Build Phase

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
	req = apb_seq_item::type_id::create("req",this);
	// get interface from config db
    if(!uvm_config_db#(virtual apb_interface)::get(this, "", "apb_intf", apb_intf)) 	
      `uvm_fatal(get_type_name(), "Interface cannot be accessed in Driver")
  endfunction : build_phase
      
	// Run phase
  virtual task run_phase (uvm_phase phase);
	wait(apb_intf.reset_n);
	forever begin
	  seq_item_port.get_next_item(req);
	  drive_item();
	  seq_item_port.item_done();
     end
  endtask : run_phase
      
  task write();
	req.print();
    apb_intf.paddr   <= req.paddr;
    apb_intf.pwrite  <= req.pwrite;
    apb_intf.psel    <= 1'b1;
    apb_intf.pwdata  <= req.pwdata;
    @(posedge apb_intf.clock);
    apb_intf.penable <= 1'b1;
    wait(apb_intf.pready);
    @(posedge apb_intf.clock);
    apb_intf.penable <= 1'b0;
    apb_intf.psel    <= 1'b0;
    @(posedge apb_intf.clock);
  endtask : write
      
  task read();
    req.print();
    apb_intf.paddr  <= req.paddr;
    apb_intf.pwrite <= req.pwrite;
    apb_intf.psel   <= 1'b1;
    //apb intf.pwdata req.pwdata:
    //@(apb intf.cb);
    @(posedge apb_intf.clock);
    apb_intf.penable <= 1'b1;
    wait(apb_intf.pready);
    //@(apb intf.cb);
    @(posedge apb_intf.clock);
    apb_intf.penable <= 1'b0;
    apb_intf.psel = 1'b0;
  endtask: read
      
  task drive_item();
    wait(apb_intf.reset_n);
    case(req.pwrite)
      1'b1: write();
      1'b0: read();
      default: `uvm_info(get_type_name(), $sformatf("Pwrite is not of valid type"), UVM_HIGH)
    endcase // req.pwrite
    display();
  endtask : drive_item
      
  task display();
    `uvm_info(get_type_name(), $sformatf("This is the driver class 1"), UVM_LOW);
  endtask: display

endclass : apb_driver