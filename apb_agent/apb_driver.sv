class apb driver (int ADDR WIDTH=256, int DATA WIDTH=256) extends uvm driver(apb_seq_item);
	
  typedef apb_driver #(ADDR WIDTH, DATA WIDTH) apb driver;

  //Factory registration

  `uvm_component_utils(apb_driver)

  virtual apb interface apb_intf;

    // Constructor

  function new(string name "apb driver", uvm component parent null);
    super.new(name, parent);
  endfunction new

    // Build Phase

  virtual function void build_phase(uvm phase phase);
    super.build phase (phase);
	req apb seq item type_id::create("req",
	// get interface from config db
    if(!uvm_config_db#(virtual apb interface)::get(this, "", "apb intf", apb intf)) 	
      `uvm_fatal(get_type_name(). "Interface cannot be accessed in Driver")
  endfunction build_phase
      
	// Run phase
  virtual task run phase (uvm phase phase);
	wait(apb intf.reset n);
	forever begin
	  seq item_port.get_next_item(req);
	  drive item();
	  seq_item_port.item done();
     end
  endtask run_phase
      
  task write();
	req.print();
    apb intf.paddr req.paddr;
    apb intf.pwrite <<= req.pwrite;
    apb intf.psel <<<= 1'b1;
    apb_intf.pwdata req.pwdata;
    (posedge apb intf.clock);
    apb intf.penable 1'bl;
    wait(apb intf.pready);
   (posedge apb intf.clock);
    apb intf.penable l'be;
    apb_intf.psel <<<= 1'be;
    (posedge apb intf.clock);
  endtask write
      
  task read();
    req.print();
    apb_intf.paddr <= req.paddr;
    apb intf.pwrite req.pwrite;
    apb intf.psel <<= 1'b1;
    //apb intf.pwdata req.pwdata:
    //@(apb intf.cb);
    (posedge apb intf.clock);
    apb intf.penable I'bl;
    Wait(apb_intf.pready);
    //@(apb intf.cb);
    (posedge apb intf.clock);
    apb_intf.penable 1'be;
    apb intf.psel = 1'be;
  endtask: read
      
  task drive item();
    wait(apb_intf.reset_n);
    case(req.pwrite)
      1'b1: write();
      1'b0: read();
      default: `uvm info(get_type_name(), $sformatf("Pwrite is not of valid type"), UVM HIGH)
    endcase // req.pwrite
    display();
  endtask drive item
      
  task display();
    `uvm_info(get_type_name(), $sformatf("This is the driver class 1"), UVM LOW);
  endtask: display

endclass apb driver