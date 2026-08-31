//------------------------------------------------------------------------------
// Parameter sets for the APB instances in the testbench.
//
// Single source of truth shared by apb_tb_top (which elaborates the interfaces
// and completers) and the tests (which specialize the environments), so the two
// sides can never drift apart.
//
// Index 0 and 3 deliberately use the same widths: two identical
// specializations of the same environment have to be able to coexist, which is
// exactly what a name-registered factory would have broken.
//------------------------------------------------------------------------------

package apb_param_pkg;

  parameter int NUM_APB = 4;

  parameter int APB_ADDR_W   [NUM_APB] = '{32,   16,  12,   32};
  parameter int APB_DATA_W   [NUM_APB] = '{32,   64,   8,   32};
  parameter int APB_MEM_DEPTH[NUM_APB] = '{1024, 256, 64, 1024};

  // Configuration database key used by apb_tb_top to publish instance i's
  // virtual interface, and by the tests to pick it up again.
  function automatic string apb_vif_key(int unsigned idx);
    return $sformatf("apb_vif_%0d", idx);
  endfunction : apb_vif_key

endpackage : apb_param_pkg
