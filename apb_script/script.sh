#!/bin/bash

echo "===Cleaning Old build"
rm -rf simv simv.daidir csrc ucli.key

file_path=${WA_ROOT}/protocol_a_p_b/apb_script/apb_file.f

vcs -R -sverilog -ntb_opts uvm-1.2 -f $file_path ${WA_ROOT}/protocol_a_p_b/apb_tb_top.sv \
    -debug_access+all +UVM_TIMEOUT=1000000