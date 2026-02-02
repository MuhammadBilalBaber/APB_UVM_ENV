class apb_bring_up_test extends uvm_test;
  
  // Factory registration

  `uvm_component_utils(apb_bring_up_test)

  apb_bringup_sequence      apb_bringup_seq;
  apb_bringup_read_sequence apb_bringup_read_seq;
  apb_environment           apb_env;


  // Constructor

  function new(string name = "apb_bring_up_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  // Build Phase

  virtual function void build_phase(uvm_phase phase);
   super.build_phase(phase);
   apb_env              = apb_environment::type_id::create("apb_env",this);
   apb_bringup_read_seq = apb_bringup_read_sequence::type_id::create("apb_bringup_read_seq",this);
   apb_bringup_seq      = apb_bringup_sequence::type_id::create("apb_bringup_seq",this);
  endfunction : build_phase

  virtual function void show_arb_cfg();
    UVM_SEQ_ARB_TYPE cur_arb;
    cur_arb = apb_env.apb_agnt.apb_seqr.get_arbitration();
    `uvm_info(get_type_name(),$sformatf("The Seqr is set to the arbitratio  is %0s", cur_arb.name()), UVM_LOW);
  endfunction : show_arb_cfg

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
      apb_env.apb_agnt.apb_seqr.set_arbitration(UVM_SEQ_ARB_FIFO);
      show_arb_cfg();
      fork
        apb_bringup_seq.start(apb_env.apb_agnt.apb_seqr);
        apb_bringup_read_seq.start(apb_env.apb_agnt.apb_seqr);
      join
    phase.drop_objection(this);
  endtask : run_phase

endclass : apb_bring_up_test