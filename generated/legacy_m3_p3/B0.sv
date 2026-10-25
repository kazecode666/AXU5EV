
`timescale 1ns/1ps

module B0
          import FOC_DUT_pkg::* ;
          (  input vector_of_signed_logic_64 Vector[0:1],
             output logic signed [63:0] Value);




  assign Value = Vector[1];

endmodule   
