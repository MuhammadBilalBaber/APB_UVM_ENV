#!/bin/bash
#-----------------------------------------------------------------------------
# Run the non-UVM protocol smoke test under Verilator.
#
# Exercises the completer and the protocol assertions at every parameter set in
# apb_param_pkg without needing a UVM-capable simulator. Useful as a quick
# regression on the RTL half of the environment; the UVM tests still need
# script.sh.
#
#   ./apb_script/run_protocol_tb.sh
#-----------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APB_ROOT="${APB_ROOT:-$(dirname "${SCRIPT_DIR}")}"
BUILD_DIR="${APB_ROOT}/obj_dir"

if ! command -v verilator >/dev/null 2>&1; then
  echo "verilator not found; install it or use apb_script/script.sh with a commercial simulator" >&2
  exit 1
fi

rm -rf "${BUILD_DIR}"

verilator --binary --timing --assert \
          --timescale 1ns/1ps \
          --unroll-count 8192 \
          -Wno-fatal \
          --top-module apb_protocol_tb \
          -o apb_sim \
          --Mdir "${BUILD_DIR}" \
          "${APB_ROOT}/apb_packages/apb_param_pkg.sv" \
          "${APB_ROOT}/apb_protocol_checker.sv" \
          "${APB_ROOT}/apb_protocol_checker_bind.sv" \
          "${APB_ROOT}/apb_dut.sv" \
          "${APB_ROOT}/apb_protocol_tb.sv"

"${BUILD_DIR}/apb_sim"
