#!/bin/bash
#-----------------------------------------------------------------------------
# Licence-free elaboration check of the whole environment using slang.
#
# Catches the class of bug that used to sit in this repository: parameter
# mismatches between components, virtual interfaces of the wrong
# specialization, factory registration mistakes and plain syntax errors. It
# does not run the simulation, so it complements script.sh rather than
# replacing it.
#
#   ./apb_script/compile_check.sh
#
#   UVM_SRC   directory holding uvm_pkg.sv (default: ./uvm-core/src, cloned on
#             demand from the Accellera reference implementation)
#-----------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APB_ROOT="${APB_ROOT:-$(dirname "${SCRIPT_DIR}")}"
UVM_SRC="${UVM_SRC:-${APB_ROOT}/uvm-core/src}"

if ! python3 -c "import pyslang" 2>/dev/null; then
  echo "=== installing pyslang"
  python3 -m pip install --quiet pyslang
fi

if [[ ! -f "${UVM_SRC}/uvm_pkg.sv" ]]; then
  echo "=== fetching the UVM reference implementation into ${APB_ROOT}/uvm-core"
  git clone --depth 1 https://github.com/accellera-official/uvm-core.git "${APB_ROOT}/uvm-core"
  UVM_SRC="${APB_ROOT}/uvm-core/src"
fi

python3 - "${APB_ROOT}" "${UVM_SRC}" <<'PY'
import shlex, sys, pyslang

apb_root, uvm_src = sys.argv[1], sys.argv[2]

incdirs = ["apb_sequence_item", "apb_config", "apb_agent",
           "apb_env", "apb_sequences", "apb_tests"]
sources = ["apb_interface.sv",
           "apb_dut.sv",
           "apb_packages/apb_param_pkg.sv",
           "apb_packages/apb_pkg.sv",
           "apb_tb_top.sv"]

args = ["slang", "--top", "apb_tb_top", "-I", uvm_src, f"{uvm_src}/uvm_pkg.sv"]
args += [a for d in incdirs for a in ("-I", f"{apb_root}/{d}")]
args += [f"{apb_root}/{s}" for s in sources]

driver = pyslang.driver.Driver()
driver.addStandardArgs()
driver.setTerminalColorsEnabled(False)
if not driver.parseCommandLine(" ".join(shlex.quote(a) for a in args)):
    sys.exit(2)
if not driver.processOptions():
    sys.exit(3)
if not driver.parseAllSources():
    sys.exit(4)
sys.exit(0 if driver.runFullCompilation() else 1)
PY
