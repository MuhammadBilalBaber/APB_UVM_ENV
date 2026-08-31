#!/bin/bash
#-----------------------------------------------------------------------------
# Compile and run the APB UVM environment.
#
#   ./apb_script/script.sh [test_name]
#
#   SIM       vcs (default) | questa | xcelium
#   APB_ROOT  repository root, defaults to the parent of this script
#-----------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export APB_ROOT="${APB_ROOT:-$(dirname "${SCRIPT_DIR}")}"

SIM="${SIM:-vcs}"
TEST="${1:-apb_multi_param_test}"
FILELIST="${APB_ROOT}/apb_script/apb_file.f"
UVM_VERBOSITY="${UVM_VERBOSITY:-UVM_LOW}"

echo "=== APB_ROOT : ${APB_ROOT}"
echo "=== simulator: ${SIM}"
echo "=== test     : ${TEST}"

echo "=== cleaning previous build"
rm -rf simv simv.daidir csrc ucli.key vc_hdrs.h work transcript \
       xcelium.d xrun.log INCA_libs .simvision novas.* ucli.key

case "${SIM}" in
  vcs)
    vcs -R -sverilog -full64 -timescale=1ns/1ps \
        -ntb_opts uvm-1.2 \
        -assert svaext \
        -debug_access+all \
        -cm line+cond+fsm+tgl+assert \
        -f "${FILELIST}" \
        +UVM_TESTNAME="${TEST}" \
        +UVM_VERBOSITY="${UVM_VERBOSITY}" \
        +UVM_TIMEOUT=1000000
    ;;

  questa)
    vlib work
    vlog -sv -timescale 1ns/1ps +acc \
         -L mtiUvm -mfcu \
         -f "${FILELIST}"
    vsim -c -do "run -all; quit -f" \
         -sv_seed random \
         +UVM_TESTNAME="${TEST}" \
         +UVM_VERBOSITY="${UVM_VERBOSITY}" \
         apb_tb_top
    ;;

  xcelium)
    xrun -sv -timescale 1ns/1ps \
         -uvmhome CDNS-1.2 \
         -access +rwc \
         -f "${FILELIST}" \
         +UVM_TESTNAME="${TEST}" \
         +UVM_VERBOSITY="${UVM_VERBOSITY}"
    ;;

  *)
    echo "unknown SIM '${SIM}', expected vcs, questa or xcelium" >&2
    exit 1
    ;;
esac
