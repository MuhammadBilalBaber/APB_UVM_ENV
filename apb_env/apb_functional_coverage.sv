
class apb_functional_coverage #(int ADDR_WIDTH=256, int DATA_WIDTH=256) extends uvm_subscriber#(apb_seq_item#(ADDR_WIDTH,DATA_WIDTH));

  typedef apb_functional_coverage #(ADDR_WIDTH, DATA_WIDTH) apb_functional_coverage;

  `uvm_component_utils(apb_functional_coverage)

  apb_seq_item#(ADDR_WIDTH, DATA_WIDTH) trans;

  function new(string name = "apb_functional_coverage", uvm_component parent = null);
    super.new(name, parent);
    apb_cov_group = new();
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans = apb_seq_item#(ADDR_WIDTH, DATA_WIDTH)::type_id::create("trans",this);
  endfunction : build_phase

  covergroup apb_cov_group;
     option.per_instance = 1;
       APB_WRITE: coverpoint trans.pwrite{
       bins write = {'1};
       bins read = {'0};
       }

       APB_ADDR: coverpoint trans.paddr iff (trans.psel && trans.penable && trans.pready){

       }

       APB_WRITE_DATA: coverpoint trans.pwdata iff (trans.psel && trans.penable && trans.pready){
       
       }

  endgroup : apb_cov_group

  function void write(apb_seq_item#(ADDR_WIDTH, DATA_WIDTH) trans);
    this.trans = trans;
    apb_cov_group.sample();
  endfunction : write

  function void report_phase(uvm_phase phase);
     super.report_phase(phase);
     `uvm_info(get_type_name(),$sformatf("The APB_coverage is %0f", $get_coverage()), UVM_LOW);
  endfunction : report_phase


endclass : apb_functional_coverage