module etx_mux (/*AUTOARG*/
   // Outputs
   mi_dout,
   // Inputs
   sys_clk, reset, mi_addr, mi_tx_emmu_dout, mi_tx_cfg_dout
   );

   parameter AW    = 32;
   parameter DW    = 32;
   parameter GROUP = 0;
   
   //Read write input
   

   input 	   reset;   

   input [19:0]    mi_addr;
  
   input [DW-1:0] mi_tx_emmu_dout;
   input [DW-1:0] mi_tx_cfg_dout;
   
   output [DW-1:0] mi_dout;

 

  
endmodule // etx_mux

