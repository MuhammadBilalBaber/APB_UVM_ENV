//------------------------------------------------------------------------------
// APB monitor.
//
// Samples the bus on every clock through the passive clocking block and
// publishes one item per completed transfer (PSEL & PENABLE & PREADY).
//------------------------------------------------------------------------------

class apb_monitor #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_monitor;

  `uvm_component_param_utils(apb_monitor#(ADDR_WIDTH, DATA_WIDTH))

  typedef apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) apb_item_t;
  typedef apb_config   #(ADDR_WIDTH, DATA_WIDTH) apb_config_t;

  apb_config_t                                    cfg;
  virtual apb_interface #(ADDR_WIDTH, DATA_WIDTH) vif;

  uvm_analysis_port #(apb_item_t) apb_mon_port;

  int unsigned num_transfers;

  function new(string name = "apb_monitor", uvm_component parent = null);
    super.new(name, parent);
    apb_mon_port = new("apb_mon_port", this);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(apb_config_t)::get(this, "", "cfg", cfg))
      `uvm_fatal(get_type_name(), "apb_config not found in the configuration database")
    if (cfg.vif == null)
      `uvm_fatal(get_type_name(), "apb_config.vif is null")
    vif = cfg.vif;
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    forever collect_trans();
  endtask : run_phase

  virtual task collect_trans();
    apb_item_t trans;

    @(vif.mon_cb);

    if (vif.presetn !== 1'b1)
      return;

    if (!(vif.mon_cb.psel === 1'b1 && vif.mon_cb.penable === 1'b1 && vif.mon_cb.pready === 1'b1))
      return;

    trans = apb_item_t::type_id::create("trans");

    trans.paddr   = vif.mon_cb.paddr;
    trans.pwrite  = vif.mon_cb.pwrite;
    trans.pwdata  = vif.mon_cb.pwdata;
    trans.prdata  = vif.mon_cb.pwrite ? '0 : vif.mon_cb.prdata;
    trans.pslverr = vif.mon_cb.pslverr;
    trans.psel    = vif.mon_cb.psel;
    trans.penable = vif.mon_cb.penable;
    trans.pready  = vif.mon_cb.pready;

    num_transfers++;

    `uvm_info(get_type_name(), {"observed ", trans.convert2string()}, UVM_MEDIUM)

    apb_mon_port.write(trans);
  endtask : collect_trans

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("observed %0d APB transfers", num_transfers), UVM_LOW)
  endfunction : report_phase

endclass : apb_monitor
