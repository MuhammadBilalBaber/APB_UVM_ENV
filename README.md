# APB UVM Verification Environment

A parameterized UVM environment for the AMBA APB protocol. The same environment
class can be instantiated as many times as a test needs, each instance with its
own address/data width, its own completer and its own checking, all inside one
testbench.

## How the parameterization works

Every class from the sequence item up to the environment carries the same two
parameters:

```systemverilog
class apb_environment #(int ADDR_WIDTH = 32, int DATA_WIDTH = 32) extends uvm_env;
  `uvm_component_param_utils(apb_environment#(ADDR_WIDTH, DATA_WIDTH))
```

Three details make repeated instantiation actually work:

- **`*_param_utils` instead of `*_utils`.** The name-registered macros give every
  specialization of a parameterized class the same factory name, which collides
  as soon as a second instance exists. The param variants register by type.
- **Base classes are specialized too.** `apb_driver#(A,D)` extends
  `uvm_driver #(apb_seq_item #(A,D))` and `apb_sequencer#(A,D)` extends
  `uvm_sequencer #(apb_seq_item #(A,D))`, so a sequencer, its driver and the
  sequences on it all agree on one item type.
- **Configuration is carried in a parameterized object.** `apb_config#(A,D)`
  holds the virtual interface, so a `uvm_config_db` entry for a 32-bit instance
  is a different type from a 64-bit one and the two cannot be crossed over.

`apb_env_builder#(A,D)::build()` wraps the five steps needed to bring one
instance up (fetch the virtual interface, create the config, publish it, create
the environment), so a test adds an instance in one line.

## Structure

| Path | Contents |
| --- | --- |
| `apb_dut.sv` | `apb_s`, a parameterized APB completer with one wait state |
| `apb_interface.sv` | Interface with requester and monitor clocking blocks |
| `apb_protocol_checker.sv` | APB protocol assertions |
| `apb_protocol_checker_bind.sv` | Binds the checker onto every completer instance |
| `apb_tb_top.sv` | One interface + completer per entry in `apb_param_pkg` |
| `apb_protocol_tb.sv` | Non-UVM smoke test for the RTL half of the environment |
| `apb_packages/apb_param_pkg.sv` | The parameter sets used by the testbench and tests |
| `apb_packages/apb_pkg.sv` | The class library |
| `apb_config/` | `apb_config`, per-instance configuration |
| `apb_sequence_item/` | `apb_seq_item` |
| `apb_agent/` | Sequencer, driver, monitor, agent |
| `apb_env/` | Coverage, scoreboard, environment, environment builder |
| `apb_sequences/` | Base, write, read and write/read-back sequences |
| `apb_tests/` | Base test, bring-up test, multi-parameter test |
| `apb_script/` | File list and run scripts |

## Parameter sets

`apb_packages/apb_param_pkg.sv` is the single source of truth for both
`apb_tb_top` and the tests, so the two can never drift apart:

| Instance | ADDR_WIDTH | DATA_WIDTH | MEM_DEPTH |
| --- | --- | --- | --- |
| 0 | 32 | 32 | 1024 |
| 1 | 16 | 64 | 256 |
| 2 | 12 | 8 | 64 |
| 3 | 32 | 32 | 1024 |

Instance 3 repeats instance 0's widths on purpose: two identical
specializations of the environment have to be able to coexist, which is exactly
what name-based factory registration used to break. Adding an instance means
adding a column here and one line to a test.

## Tests

- **`apb_bring_up_test`** — one environment on instance 0. Starts a write and a
  read sequence concurrently on the same sequencer to exercise arbitration.
- **`apb_multi_param_test`** — four environments, one per parameter set, running
  write/read-back traffic at the same time.

## Checking

- **Scoreboard.** Builds a reference memory image from monitored traffic only,
  so it works at any width without knowing anything about the completer. It
  predicts read data and `PSLVERR`, and because it predicts from the monitored
  order rather than the sequence order, interleaved sequences cannot produce a
  false failure.
- **Protocol assertions.** SETUP is always followed by ACCESS, `PENABLE` implies
  `PSEL`, control and payload hold still across wait states, and `PREADY` and
  `PSLVERR` only appear in an ACCESS phase. Bound onto every completer instance;
  compile with `APB_NO_ASSERTIONS` defined to leave them out.
- **Functional coverage.** Direction, `PSLVERR`, address region and data class,
  plus direction crosses. Address and data are bucketed before sampling, so a
  wide bus does not ask the simulator for an unusable number of automatic bins
  and the bin set keeps its meaning at every width.

## Completer behaviour

`PADDR` is a byte address. The memory is `DATA_WIDTH` wide and `MEM_DEPTH` words
deep, so the legal window is `0 .. MEM_DEPTH*(DATA_WIDTH/8)-1`. An unaligned,
out-of-range or unknown address, or unknown write data, is answered with
`PSLVERR` and leaves the memory unchanged. Illegal parameter combinations
(`DATA_WIDTH` not a multiple of 8, `MEM_DEPTH` not a power of two, `ADDR_WIDTH`
too narrow for the memory) are rejected at elaboration rather than silently
mis-sizing the memory.

## Running

With a commercial simulator:

```bash
export APB_ROOT=/path/to/APB_UVM_ENV
./apb_script/script.sh apb_multi_param_test      # SIM=vcs (default), questa or xcelium
./apb_script/script.sh apb_bring_up_test
```

Without one, two license-free checks cover most of what breaks in a
parameterized environment:

```bash
./apb_script/compile_check.sh      # full elaboration against UVM, via slang
./apb_script/run_protocol_tb.sh    # completer + assertions at every parameter set, via Verilator
```

`compile_check.sh` elaborates the whole environment, including every class
specialization the tests create, which is what catches parameter mismatches
between components, virtual interfaces of the wrong specialization and factory
registration mistakes. `run_protocol_tb.sh` simulates the completer and the
protocol assertions at all four parameter sets.
