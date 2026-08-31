//------------------------------------------------------------------------------
// Base APB sequence.
//
// Holds the boilerplate every APB sequence needs: the parameterized item type,
// access to the sequencer's configuration and a helper that creates an item
// already limited to the legal address window of the instance it runs on.
//------------------------------------------------------------------------------

class apb_base_sequence #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
) extends uvm_sequence #(apb_seq_item #(ADDR_WIDTH, DATA_WIDTH));

  `uvm_object_param_utils(apb_base_sequence#(ADDR_WIDTH, DATA_WIDTH))

  typedef apb_seq_item  #(ADDR_WIDTH, DATA_WIDTH) apb_item_t;
  typedef apb_config    #(ADDR_WIDTH, DATA_WIDTH) apb_config_t;
  typedef apb_sequencer #(ADDR_WIDTH, DATA_WIDTH) apb_sequencer_t;

  `uvm_declare_p_sequencer(apb_sequencer_t)

  rand int unsigned num_trans;

  constraint c_num_trans {
    soft num_trans inside {[1:8]};
  }

  apb_config_t cfg;

  function new(string name = "apb_base_sequence");
    super.new(name);
  endfunction : new

  virtual function void get_cfg();
    if (cfg == null && p_sequencer != null)
      cfg = p_sequencer.cfg;
  endfunction : get_cfg

  virtual function bit [ADDR_WIDTH-1:0] max_addr();
    return (cfg != null) ? cfg.max_addr() : '1;
  endfunction : max_addr

  virtual function apb_item_t new_item(string name = "req");
    apb_item_t item = apb_item_t::type_id::create(name);
    item.max_addr = max_addr();
    return item;
  endfunction : new_item

endclass : apb_base_sequence
