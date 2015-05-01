module erx (/*AUTOARG*/
   // Outputs
   rx_lclk_div4, rxo_wr_wait_p, rxo_wr_wait_n, rxo_rd_wait_p,
   rxo_rd_wait_n, rxwr_access, rxwr_packet, rxrd_access, rxrd_packet,
   rxrr_access, rxrr_packet, erx_cfg_wait, timeout, mailbox_full,
   mailbox_not_empty,
   // Inputs
   reset, sys_clk, rxi_lclk_p, rxi_lclk_n, rxi_frame_p, rxi_frame_n,
   rxi_data_p, rxi_data_n, rxwr_wait, rxrd_wait, rxrr_wait,
   erx_cfg_access, erx_cfg_packet
   );

   parameter AW      = 32;
   parameter DW      = 32;
   parameter PW      = 104;
   parameter RFAW    = 6;
   parameter ID      = 12'h800;

   
   //reset
   input           reset;
   output          rx_lclk_div4;    //for synchronization outside erx
   input 	   sys_clk;	    //system input clock for fifos

   //FROM IO Pins
   input 	  rxi_lclk_p,  rxi_lclk_n;     //link rx clock input
   input 	  rxi_frame_p,  rxi_frame_n;   //link rx frame signal
   input [7:0] 	  rxi_data_p,   rxi_data_n;    //link rx data
   output 	  rxo_wr_wait_p,rxo_wr_wait_n; //link rx write pushback output
   output 	  rxo_rd_wait_p,rxo_rd_wait_n; //link rx read pushback output

   //Master write
   output 	   rxwr_access;		
   output [PW-1:0] rxwr_packet;
   input 	   rxwr_wait;

   //Master read request
   output 	   rxrd_access;		
   output [PW-1:0] rxrd_packet;
   input 	   rxrd_wait;

   //Slave read response
   output 	   rxrr_access;		
   output [PW-1:0] rxrr_packet;
   input 	   rxrr_wait;
  
   //Configuration Interface (from ETX)
   input 	   erx_cfg_access;
   input [PW-1:0]  erx_cfg_packet;
   output 	   erx_cfg_wait;
   
   //Readback timeout (synchronized to sys_c
   output 	   timeout;
   output 	   mailbox_full;
   output 	   mailbox_not_empty;
   
   /*AUTOOUTPUT*/
   /*AUTOINPUT*/

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			edma_access;		// From edma of edma.v
   wire			edma_wait;		// From erx_disty of erx_disty.v
   wire			emesh_remap_access;	// From erx_remap of erx_remap.v
   wire [PW-1:0]	emesh_remap_packet;	// From erx_remap of erx_remap.v
   wire			emmu_access;		// From emmu of emmu.v
   wire [PW-1:0]	emmu_packet;		// From emmu of emmu.v
   wire			erx_access;		// From erx_protocol of erx_protocol.v
   wire [PW-1:0]	erx_packet;		// From erx_protocol of erx_protocol.v
   wire			erx_wait;		// From erx_disty of erx_disty.v
   wire [8:0]		gpio_datain;		// From erx_io of erx_io.v
   wire [14:0]		mi_addr;		// From ecfg_if of ecfg_if.v
   wire [DW-1:0]	mi_cfg_dout;		// From ecfg_rx of ecfg_rx.v
   wire			mi_cfg_en;		// From ecfg_if of ecfg_if.v
   wire [63:0]		mi_din;			// From ecfg_if of ecfg_if.v
   wire [DW-1:0]	mi_dma_dout;		// From edma of edma.v
   wire			mi_dma_en;		// From ecfg_if of ecfg_if.v
   wire [31:0]		mi_mailbox_dout;	// From emailbox of emailbox.v
   wire [DW-1:0]	mi_mmu_dout;		// From emmu of emmu.v
   wire			mi_mmu_en;		// From ecfg_if of ecfg_if.v
   wire			mi_we;			// From ecfg_if of ecfg_if.v
   wire			mmu_enable;		// From ecfg_rx of ecfg_rx.v
   wire [31:0]		remap_base;		// From ecfg_rx of ecfg_rx.v
   wire			remap_bypass;		// From erx_protocol of erx_protocol.v
   wire [1:0]		remap_mode;		// From ecfg_rx of ecfg_rx.v
   wire [11:0]		remap_pattern;		// From ecfg_rx of ecfg_rx.v
   wire [11:0]		remap_sel;		// From ecfg_rx of ecfg_rx.v
   wire [63:0]		rx_data_par;		// From erx_io of erx_io.v
   wire			rx_enable;		// From ecfg_rx of ecfg_rx.v
   wire [7:0]		rx_frame_par;		// From erx_io of erx_io.v
   wire			rx_rd_wait;		// From erx_disty of erx_disty.v
   wire			rx_wr_wait;		// From erx_disty of erx_disty.v
   wire			rxrd_fifo_access;	// From erx_disty of erx_disty.v
   wire [PW-1:0]	rxrd_fifo_packet;	// From erx_disty of erx_disty.v
   wire			rxrd_fifo_wait;		// From rxrd_fifo of fifo_async.v
   wire			rxrr_fifo_access;	// From erx_disty of erx_disty.v
   wire [PW-1:0]	rxrr_fifo_packet;	// From erx_disty of erx_disty.v
   wire			rxrr_fifo_wait;		// From rxrr_fifo of fifo_async.v
   wire			rxwr_fifo_access;	// From erx_disty of erx_disty.v
   wire [PW-1:0]	rxwr_fifo_packet;	// From erx_disty of erx_disty.v
   wire			rxwr_fifo_wait;		// From rxwr_fifo of fifo_async.v
   // End of automatics

   //regs
   wire [15:0] 	rx_status;
   wire 	rxwr_fifo_full;
   wire 	rxrr_fifo_full;
   wire 	rxrd_fifo_full;
   wire 	rxrd_empty;
   wire 	rxwr_empty;
   wire 	rxrr_empty;
   wire [103:0] edma_packet;		// From edma of edma.v, ...
   
   /***********************************************************/
   /*RECEIVER  I/O LOGIC                                      */
   /***********************************************************/
   erx_io erx_io (
		    /*AUTOINST*/
		  // Outputs
		  .rxo_wr_wait_p	(rxo_wr_wait_p),
		  .rxo_wr_wait_n	(rxo_wr_wait_n),
		  .rxo_rd_wait_p	(rxo_rd_wait_p),
		  .rxo_rd_wait_n	(rxo_rd_wait_n),
		  .rx_lclk_div4		(rx_lclk_div4),
		  .rx_frame_par		(rx_frame_par[7:0]),
		  .rx_data_par		(rx_data_par[63:0]),
		  .gpio_datain		(gpio_datain[8:0]),
		  // Inputs
		  .reset		(reset),
		  .rxi_lclk_p		(rxi_lclk_p),
		  .rxi_lclk_n		(rxi_lclk_n),
		  .rxi_frame_p		(rxi_frame_p),
		  .rxi_frame_n		(rxi_frame_n),
		  .rxi_data_p		(rxi_data_p[7:0]),
		  .rxi_data_n		(rxi_data_n[7:0]),
		  .rx_wr_wait		(rx_wr_wait),
		  .rx_rd_wait		(rx_rd_wait));

   /**************************************************************/
   /*ELINK PROTOCOL LOGIC                                        */
   /**************************************************************/

   defparam erx_protocol.ID=ID;     
   erx_protocol erx_protocol (/*AUTOINST*/
			      // Outputs
			      .erx_access	(erx_access),
			      .erx_packet	(erx_packet[PW-1:0]),
			      .remap_bypass	(remap_bypass),
			      // Inputs
			      .reset		(reset),
			      .rx_enable	(rx_enable),
			      .rx_lclk_div4	(rx_lclk_div4),
			      .rx_frame_par	(rx_frame_par[7:0]),
			      .rx_data_par	(rx_data_par[63:0]));
   
   /**************************************************************/
   /*ADDRESS REMPAPPING                                          */
   /**************************************************************/
   //TODO: clean up signaling

   /*erx_remap AUTO_TEMPLATE ( 
                        .emesh_\(.*\)_out	(emesh_remap_\1[]),   
                         //Inputs
                        .emesh_\(.*\)_in	(erx_\1[]),   
                        .mmu_en			(ecfg_rx_mmu_enable),
                        .clk			(rx_lclk_div4),

                        .emesh_packet_hi_out	(),
                           );
   */

   defparam erx_remap.ID = ID;
   erx_remap erx_remap (/*AUTOINST*/
			// Outputs
			.emesh_access_out(emesh_remap_access),	 // Templated
			.emesh_packet_out(emesh_remap_packet[PW-1:0]), // Templated
			// Inputs
			.clk		(rx_lclk_div4),		 // Templated
			.reset		(reset),
			.emesh_access_in(erx_access),		 // Templated
			.emesh_packet_in(erx_packet[PW-1:0]),	 // Templated
			.remap_mode	(remap_mode[1:0]),
			.remap_sel	(remap_sel[11:0]),
			.remap_pattern	(remap_pattern[11:0]),
			.remap_base	(remap_base[31:0]),
			.remap_bypass	(remap_bypass),
			.emesh_wait_in	(erx_wait));		 // Templated
   
 
   
   /************************************************************/
   /*ELINK MEMORY MANAGEMENT UNIT                              */
   /************************************************************/
   /*emmu AUTO_TEMPLATE ( 
                        .emesh_\(.*\)_out	(emmu_\1[]),   
                         //Inputs
                        .emesh_\(.*\)_in	(emesh_remap_\1[]),   
                        .mmu_en			(mmu_enable),
                        .clk	        	(rx_lclk_div4),
                        .mi_dout   	        (mi_mmu_dout[DW-1:0]),
                        .emesh_packet_hi_out	(),
                        .mmu_bp	    	        (remap_bypass),
                        .emesh_wait_in		(erx_wait),
                        .mi_en	                (mi_mmu_en),	 
                           );
   */

   emmu emmu (
	      /*AUTOINST*/
	      // Outputs
	      .mi_dout			(mi_mmu_dout[DW-1:0]),	 // Templated
	      .emesh_access_out		(emmu_access),		 // Templated
	      .emesh_packet_out		(emmu_packet[PW-1:0]),	 // Templated
	      .emesh_packet_hi_out	(),			 // Templated
	      // Inputs
	      .reset			(reset),
	      .clk			(rx_lclk_div4),		 // Templated
	      .mmu_en			(mmu_enable),		 // Templated
	      .mmu_bp			(remap_bypass),		 // Templated
	      .mi_en			(mi_mmu_en),		 // Templated
	      .mi_we			(mi_we),
	      .mi_addr			(mi_addr[14:0]),
	      .mi_din			(mi_din[DW-1:0]),
	      .emesh_access_in		(emesh_remap_access),	 // Templated
	      .emesh_packet_in		(emesh_remap_packet[PW-1:0]), // Templated
	      .emesh_wait_in		(erx_wait));		 // Templated
   
 
   
   /************************************************************/
   /* CONFIGURATION INTERFACE                                  */
   /************************************************************/
   /*ecfg_if AUTO_TEMPLATE ( 
    .\(.*\)_in          (erx_cfg_\1[]),
    .\(.*\)_out         (),
    .mi_dout0		({32'b0,mi_cfg_dout[31:0]}),
    .mi_dout1		({32'b0,mi_dma_dout[31:0]}),
    .mi_dout2		({32'b0,mi_mmu_dout[31:0]}),
    .mi_dout3		(mi_mailbox_dout[63:0]),
    .clk                (rx_lclk_div4),  
    );
    */
   
   defparam ecfg_if.RX=1;
   ecfg_if ecfg_if (/*AUTOINST*/
		    // Outputs
		    .wait_out		(),			 // Templated
		    .mi_mmu_en		(mi_mmu_en),
		    .mi_dma_en		(mi_dma_en),
		    .mi_cfg_en		(mi_cfg_en),
		    .mi_we		(mi_we),
		    .mi_addr		(mi_addr[14:0]),
		    .mi_din		(mi_din[63:0]),
		    .access_out		(),			 // Templated
		    .packet_out		(),			 // Templated
		    // Inputs
		    .clk		(rx_lclk_div4),		 // Templated
		    .reset		(reset),
		    .access_in		(erx_cfg_access),	 // Templated
		    .packet_in		(erx_cfg_packet[PW-1:0]), // Templated
		    .mi_dout0		({32'b0,mi_cfg_dout[31:0]}), // Templated
		    .mi_dout1		({32'b0,mi_dma_dout[31:0]}), // Templated
		    .mi_dout2		({32'b0,mi_mmu_dout[31:0]}), // Templated
		    .mi_dout3		(mi_mailbox_dout[63:0]), // Templated
		    .wait_in		(erx_cfg_wait));		 // Templated
   
   
   /************************************************************/
   /* ERX CONFIGURATION                                        */
   /************************************************************/
   /*ecfg_rx AUTO_TEMPLATE (.mi_dout       (mi_cfg_dout[DW-1:0]),
                            .mi_en	   (mi_cfg_en),
                            .clk	   (rx_lclk_div4),
    );
        */   
   
   assign rx_status[15:0] = {2'b0,                     //15:14
			      rx_rd_wait,               //13
			      rx_wr_wait,               //12
			      rxrr_wait,                //11
			      rxrr_fifo_wait,           //10
			      rxrr_fifo_access,         //9			
			      rxrd_wait,                //8
			      rxrd_fifo_wait,           //7
			      rxrd_fifo_access,         //6		 
			      rxwr_wait,                //5
			      rxwr_fifo_wait,           //4
			      rxwr_fifo_access,         //3
			      rxrr_fifo_full,           //2
			      rxrd_fifo_full,           //1
			      rxwr_fifo_full	          //0	
			      };



   ecfg_rx ecfg_rx (.rx_status    	(rx_status[15:0]),
		    .timer_cfg		(),
		     /*AUTOINST*/
		    // Outputs
		    .mi_dout		(mi_cfg_dout[DW-1:0]),	 // Templated
		    .rx_enable		(rx_enable),
		    .mmu_enable		(mmu_enable),
		    .remap_mode		(remap_mode[1:0]),
		    .remap_base		(remap_base[31:0]),
		    .remap_pattern	(remap_pattern[11:0]),
		    .remap_sel		(remap_sel[11:0]),
		    // Inputs
		    .reset		(reset),
		    .clk		(rx_lclk_div4),		 // Templated
		    .mi_en		(mi_cfg_en),		 // Templated
		    .mi_we		(mi_we),
		    .mi_addr		(mi_addr[14:0]),
		    .mi_din		(mi_din[31:0]),
		    .gpio_datain	(gpio_datain[8:0]));
    
   
   
  
   
   /************************************************************/
   /*EMAILBOX                                                  */
   /************************************************************/
   /*emailbox AUTO_TEMPLATE ( 
    .mi_en              (mi_cfg_en),
    .mi_dout            (mi_mailbox_dout[]),
    .wr_clk		(rx_lclk_div4),
    .rd_clk		(rx_lclk_div4),
        );
        */

   //shares register space with ecfg_rx
   emailbox emailbox(.mi_en		(mi_cfg_en),
		     /*AUTOINST*/
		     // Outputs
		     .mi_dout		(mi_mailbox_dout[31:0]), // Templated
		     .mailbox_full	(mailbox_full),
		     .mailbox_not_empty	(mailbox_not_empty),
		     // Inputs
		     .reset		(reset),
		     .wr_clk		(rx_lclk_div4),		 // Templated
		     .rd_clk		(rx_lclk_div4),		 // Templated
		     .mi_we		(mi_we),
		     .mi_addr		(mi_addr[19:0]),
		     .mi_din		(mi_din[63:0]));
   
   
   /************************************************************/
   /*ELINK DMA                                                 */
   /************************************************************/
   
   /*edma AUTO_TEMPLATE (.clk		(rx_lclk_div4),
                         .mi_en		(mi_dma_en),
                         .edma_access	(edma_access),   
                         .mi_dout       (mi_dma_dout[DW-1:0]),
                             
                               );
   */   
   edma edma(/*AUTOINST*/
	     // Outputs
	     .mi_dout			(mi_dma_dout[DW-1:0]),	 // Templated
	     .edma_access		(edma_access),		 // Templated
	     .edma_packet		(edma_packet[PW-1:0]),
	     // Inputs
	     .reset			(reset),
	     .clk			(rx_lclk_div4),		 // Templated
	     .mi_en			(mi_dma_en),		 // Templated
	     .mi_we			(mi_we),
	     .mi_addr			(mi_addr[RFAW+1:0]),
	     .mi_din			(mi_din[63:0]),
	     .edma_wait			(edma_wait));
   
           

				 
   /************************************************************/
   /*ELINK RECEIVE DISTRIBUTOR ("DEMUX")                       */
   /*(figures out who RX transaction belongs to)               */
   /********************1***************************************/
   /*erx_disty AUTO_TEMPLATE ( 
                        //Inputs
                        .mmu_en		(ecfg_rx_mmu_enable),
                        .clk		(rx_lclk_div4),
    )
    */

   defparam erx_disty.ID    = ID;
   erx_disty erx_disty (.timeout	(1'b0),//TODO
			/*AUTOINST*/
			// Outputs
			.erx_wait	(erx_wait),
			.rx_rd_wait	(rx_rd_wait),
			.rx_wr_wait	(rx_wr_wait),
			.edma_wait	(edma_wait),
			.erx_cfg_wait	(erx_cfg_wait),
			.rxwr_fifo_access(rxwr_fifo_access),
			.rxwr_fifo_packet(rxwr_fifo_packet[PW-1:0]),
			.rxrd_fifo_access(rxrd_fifo_access),
			.rxrd_fifo_packet(rxrd_fifo_packet[PW-1:0]),
			.rxrr_fifo_access(rxrr_fifo_access),
			.rxrr_fifo_packet(rxrr_fifo_packet[PW-1:0]),
			// Inputs
			.erx_access	(erx_access),
			.erx_packet	(erx_packet[PW-1:0]),
			.emmu_access	(emmu_access),
			.emmu_packet	(emmu_packet[PW-1:0]),
			.edma_access	(edma_access),
			.edma_packet	(edma_packet[PW-1:0]),
			.erx_cfg_access	(erx_cfg_access),
			.erx_cfg_packet	(erx_cfg_packet[PW-1:0]),
			.rxwr_fifo_wait	(rxwr_fifo_wait),
			.rxrd_fifo_wait	(rxrd_fifo_wait),
			.rxrr_fifo_wait	(rxrr_fifo_wait));


   /************************************************************/
   /*FIFOs                                                     */
   /*(for AXI 1. read request, 2. write, and 3. read response) */
   /************************************************************/

   /*fifo_async   AUTO_TEMPLATE ( 
 			       // Outputs
			       
			       .dout       (@"(substring vl-cell-name  0 4)"_packet[PW-1:0]),
			       .empty	   (@"(substring vl-cell-name  0 4)"_empty),
			       .full	   (@"(substring vl-cell-name  0 4)"_fifo_full),
			       .prog_full  (@"(substring vl-cell-name  0 4)"_fifo_wait),
    			       .valid      (@"(substring vl-cell-name  0 4)"_access),
			       // Inputs
			       .rd_clk	   (sys_clk),
                               .wr_clk	   (rx_lclk_div4),
                               .wr_en      (@"(substring vl-cell-name  0 4)"_fifo_access),
                               .rd_en      (~@"(substring vl-cell-name  0 4)"_wait & ~@"(substring vl-cell-name  0 4)"_empty),
			       .reset	   (reset),
                               .din	   (@"(substring vl-cell-name  0 4)"_fifo_packet[PW-1:0]),
    );
   */

   
      
   //Read request fifo (from Epiphany)
   fifo_async #(.DW(104), .AW(5)) 
   rxrd_fifo   (.full			(rxrd_fifo_full),
		.empty			(rxrd_empty),
		/*AUTOINST*/
		// Outputs
		.prog_full		(rxrd_fifo_wait),	 // Templated
		.dout			(rxrd_packet[PW-1:0]),	 // Templated
		.valid			(rxrd_access),		 // Templated
		// Inputs
		.reset			(reset),		 // Templated
		.wr_clk			(rx_lclk_div4),		 // Templated
		.rd_clk			(sys_clk),		 // Templated
		.wr_en			(rxrd_fifo_access),	 // Templated
		.din			(rxrd_fifo_packet[PW-1:0]), // Templated
		.rd_en			(~rxrd_wait & ~rxrd_empty)); // Templated

 

   //Write fifo (from Epiphany)
   fifo_async #(.DW(104), .AW(5)) 
   rxwr_fifo(.full			(rxwr_fifo_full),
	     .empty			(rxwr_empty),
	     /*AUTOINST*/
	     // Outputs
	     .prog_full			(rxwr_fifo_wait),	 // Templated
	     .dout			(rxwr_packet[PW-1:0]),	 // Templated
	     .valid			(rxwr_access),		 // Templated
	     // Inputs
	     .reset			(reset),		 // Templated
	     .wr_clk			(rx_lclk_div4),		 // Templated
	     .rd_clk			(sys_clk),		 // Templated
	     .wr_en			(rxwr_fifo_access),	 // Templated
	     .din			(rxwr_fifo_packet[PW-1:0]), // Templated
	     .rd_en			(~rxwr_wait & ~rxwr_empty)); // Templated
   
 

   //Read response fifo (for host)
   fifo_async #(.DW(104), .AW(5))  
   rxrr_fifo(.full			(rxrr_fifo_full),
	     .empty			(rxrr_empty),
	     /*AUTOINST*/
	     // Outputs
	     .prog_full			(rxrr_fifo_wait),	 // Templated
	     .dout			(rxrr_packet[PW-1:0]),	 // Templated
	     .valid			(rxrr_access),		 // Templated
	     // Inputs
	     .reset			(reset),		 // Templated
	     .wr_clk			(rx_lclk_div4),		 // Templated
	     .rd_clk			(sys_clk),		 // Templated
	     .wr_en			(rxrr_fifo_access),	 // Templated
	     .din			(rxrr_fifo_packet[PW-1:0]), // Templated
	     .rd_en			(~rxrr_wait & ~rxrr_empty)); // Templated
      
  
   /************************************************************/
   /*Debug signals                                             */
   /************************************************************/
 
   
endmodule // erx
// Local Variables:
// verilog-library-directories:("." "../../emmu/hdl" "../../edma/hdl" "../../memory/hdl" "../../emailbox/hdl")
// End:

/*
 Copyright (C) 2014 Adapteva, Inc.
  
 Contributed by Andreas Olofsson <andreas@adapteva.com>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.This program is distributed in the hope 
 that it will be useful,but WITHOUT ANY WARRANTY; without even the implied 
 warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details. You should have received a copy 
 of the GNU General Public License along with this program (see the file 
 COPYING).  If not, see <http://www.gnu.org/licenses/>.
 */

