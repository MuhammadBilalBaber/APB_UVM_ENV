//------------------------------------------------------------------------------
// APB requester (master) driver.
//
// Drives one IDLE -> SETUP -> ACCESS transfer per sequence item through the
// requester clocking block, so stimulus is always applied in the NBA region and
// responses are sampled with #1step skew.
//------------------------------------------------------------------------------

class apb_driver #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_driver #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH));

  `uvm_component_param_utils(apb_driver#(ADDR_WIDTH, DATA_WIDTH))

  typedef apb_seq_item #(ADDR_WIDTH, DATA_WIDTH) apb_item_t;
  typedef apb_config   #(ADDR_WIDTH, DATA_WIDTH) apb_config_t;

  apb_config_t                                    cfg;
  virtual apb_interface #(ADDR_WIDTH, DATA_WIDTH) vif;

  int unsigned num_transfers;

  function new(string name = "apb_driver", uvm_component parent = null);
    super.new(name, parent);
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
    idle_bus();
    wait_for_reset_release();
    forever begin
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      num_transfers++;
      seq_item_port.item_done();
    end
  endtask : run_phase

  virtual task idle_bus();
    vif.mst_cb.psel    <= 1'b0;
    vif.mst_cb.penable <= 1'b0;
    vif.mst_cb.pwrite  <= 1'b0;
    vif.mst_cb.paddr   <= '0;
    vif.mst_cb.pwdata  <= '0;
  endtask : idle_bus

  virtual task wait_for_reset_release();
    if (vif.presetn !== 1'b1)
      @(posedge vif.presetn);
    @(vif.mst_cb);
  endtask : wait_for_reset_release

  virtual task drive_transfer(apb_item_t item);
    int unsigned waits = 0;

    `uvm_info(get_type_name(), {"driving ", item.convert2string()}, UVM_HIGH)

    // SETUP phase
    @(vif.mst_cb);
    vif.mst_cb.paddr   <= item.paddr;
    vif.mst_cb.pwrite  <= item.pwrite;
    vif.mst_cb.pwdata  <= item.pwrite ? item.pwdata : '0;
    vif.mst_cb.psel    <= 1'b1;
    vif.mst_cb.penable <= 1'b0;

    // ACCESS phase
    @(vif.mst_cb);
    vif.mst_cb.penable <= 1'b1;

    do begin
      @(vif.mst_cb);
      waits++;
      if (waits > cfg.max_wait_cycles) begin
        `uvm_error(get_type_name(),
                   $sformatf("PREADY not asserted within %0d cycles for %s",
                             cfg.max_wait_cycles, item.convert2string()))
        break;
      end
    end while (vif.mst_cb.pready !== 1'b1);

    item.prdata  = item.pwrite ? '0 : vif.mst_cb.prdata;
    item.pslverr = vif.mst_cb.pslverr;

    // Back to IDLE
    vif.mst_cb.psel    <= 1'b0;
    vif.mst_cb.penable <= 1'b0;
  endtask : drive_transfer

  virtual function void report_phase(uvm_phase phase);
    `uvm_info(get_type_name(), $sformatf("drove %0d APB transfers", num_transfers), UVM_LOW)
  endfunction : report_phase

endclass : apb_driver
