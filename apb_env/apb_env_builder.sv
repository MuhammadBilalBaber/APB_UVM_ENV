//------------------------------------------------------------------------------
// Helper that wires up one parameterized environment instance.
//
// Fetching a virtual interface, creating a configuration object and publishing
// it for a single environment is the same five steps every time, but the types
// involved differ per parameterization, so the helper itself is parameterized.
// This is what lets a test bring up N environments without repeating the
// boilerplate N times.
//------------------------------------------------------------------------------

class apb_env_builder #(
  int ADDR_WIDTH = 32,
  int DATA_WIDTH = 32
);

  typedef apb_config      #(ADDR_WIDTH, DATA_WIDTH) apb_config_t;
  typedef apb_environment #(ADDR_WIDTH, DATA_WIDTH) apb_environment_t;
  typedef virtual apb_interface #(ADDR_WIDTH, DATA_WIDTH) apb_vif_t;

  static function apb_environment_t build(uvm_component            parent,
                                          string                   name,
                                          string                   vif_key,
                                          int unsigned             mem_depth,
                                          uvm_active_passive_enum  is_active = UVM_ACTIVE);
    apb_vif_t    vif;
    apb_config_t cfg;

    if (!uvm_config_db #(apb_vif_t)::get(parent, "", vif_key, vif))
      `uvm_fatal("APB_ENV_BUILDER",
                 $sformatf("no virtual apb_interface#(%0d,%0d) published as '%s'",
                           ADDR_WIDTH, DATA_WIDTH, vif_key))

    cfg           = apb_config_t::type_id::create({name, "_cfg"});
    cfg.vif       = vif;
    cfg.mem_depth = mem_depth;
    cfg.is_active = is_active;

    uvm_config_db #(apb_config_t)::set(parent, name, "cfg", cfg);

    return apb_environment_t::type_id::create(name, parent);
  endfunction : build

endclass : apb_env_builder
