
class apb_bringup_read_sequence extends uvm_sequence #(apb_seq_item);

  // factory Registration

  `uvm_object_utils(apb_bringup_read_sequence)

  // Constructor

  function new(string name = "apb_bringup_read_sequence");
    super.new(name);
  endfunction : new

  task body();
    write_data();
  endtask: body

  task write_data();
    req = apb_seq_item::type_id::create("req");
    repeat(1) begin
    start_item(req);
     assert(req.randomize() with {
       req.psel   == 1;
       req.pwrite == 0;
       req.paddr  == 'h15;
     });
     finish_item(req);
    end
  endtask : write_data


endclass : apb_bringup_read_sequence