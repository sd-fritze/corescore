module base
  (input wire 	     i_clk,
   input wire 	      i_rst,
   output wire [31:0] o_wb_coll_adr,
   output wire [31:0] o_wb_coll_dat,
   output wire 	      o_wb_coll_we,
   output wire 	      o_wb_coll_stb,
   input wire [31:0]  i_wb_coll_rdt,
   input wire 	      i_wb_coll_ack,
   output wire [7:0]  o_tdata,
   output wire 	      o_tlast,
   output wire 	      o_tvalid,
   input wire 	      i_tready);

   parameter memfile = "";
   parameter memsize = 8192;
   parameter sim = 0;
   parameter with_csr = 1;

   wire 	timer_irq;

   wire [31:0] 	wb_ibus_adr;
   wire 	wb_ibus_cyc;
   wire [31:0] 	wb_ibus_rdt;
   wire 	wb_ibus_ack;

   wire [31:0] 	wb_dbus_adr;
   wire [31:0] 	wb_dbus_dat;
   wire [3:0] 	wb_dbus_sel;
   wire 	wb_dbus_we;
   wire 	wb_dbus_cyc;
   wire [31:0] 	wb_dbus_rdt;
   wire 	wb_dbus_ack;

   wire [31:0] 	wb_dmem_adr;
   wire [31:0] 	wb_dmem_dat;
   wire [3:0] 	wb_dmem_sel;
   wire 	wb_dmem_we;
   wire 	wb_dmem_cyc;
   wire [31:0] 	wb_dmem_rdt;
   wire 	wb_dmem_ack;

   wire [31:0] 	wb_mem_adr;
   wire [31:0] 	wb_mem_dat;
   wire [3:0] 	wb_mem_sel;
   wire 	wb_mem_we;
   wire 	wb_mem_cyc;
   wire [31:0] 	wb_mem_rdt;
   wire 	wb_mem_ack;

   wire [31:0] 	wb_timer_dat;
   wire 	wb_timer_we;
   wire 	wb_timer_cyc;
   wire [31:0] 	wb_timer_rdt;

   wire [8:0] 	wb_fifo_dat;
   wire 	wb_fifo_we;
   wire 	wb_fifo_stb;
   wire  	wb_fifo_ack;

   servant_arbiter arbiter
     (.i_wb_cpu_dbus_adr (wb_dmem_adr),
      .i_wb_cpu_dbus_dat (wb_dmem_dat),
      .i_wb_cpu_dbus_sel (wb_dmem_sel),
      .i_wb_cpu_dbus_we  (wb_dmem_we ),
      .i_wb_cpu_dbus_cyc (wb_dmem_cyc),
      .o_wb_cpu_dbus_rdt (wb_dmem_rdt),
      .o_wb_cpu_dbus_ack (wb_dmem_ack),

      .i_wb_cpu_ibus_adr (wb_ibus_adr),
      .i_wb_cpu_ibus_cyc (wb_ibus_cyc),
      .o_wb_cpu_ibus_rdt (wb_ibus_rdt),
      .o_wb_cpu_ibus_ack (wb_ibus_ack),

      .o_wb_cpu_adr (wb_mem_adr),
      .o_wb_cpu_dat (wb_mem_dat),
      .o_wb_cpu_sel (wb_mem_sel),
      .o_wb_cpu_we  (wb_mem_we ),
      .o_wb_cpu_cyc (wb_mem_cyc),
      .i_wb_cpu_rdt (wb_mem_rdt),
      .i_wb_cpu_ack (wb_mem_ack));

   base_mux #(sim) dmux
     (
      .i_clk (i_clk),
      .i_rst (i_rst),
      .i_wb_cpu_adr (wb_dbus_adr),
      .i_wb_cpu_dat (wb_dbus_dat),
      .i_wb_cpu_sel (wb_dbus_sel),
      .i_wb_cpu_we  (wb_dbus_we),
      .i_wb_cpu_cyc (wb_dbus_cyc),
      .o_wb_cpu_rdt (wb_dbus_rdt),
      .o_wb_cpu_ack (wb_dbus_ack),

      .o_wb_mem_adr (wb_dmem_adr),
      .o_wb_mem_dat (wb_dmem_dat),
      .o_wb_mem_sel (wb_dmem_sel),
      .o_wb_mem_we  (wb_dmem_we),
      .o_wb_mem_cyc (wb_dmem_cyc),
      .i_wb_mem_rdt (wb_dmem_rdt),

      .o_wb_coll_adr (o_wb_coll_adr),
      .o_wb_coll_dat (o_wb_coll_dat),
      .o_wb_coll_we  (o_wb_coll_we),
      .o_wb_coll_stb (o_wb_coll_stb),
      .i_wb_coll_rdt (i_wb_coll_rdt),
      .i_wb_coll_ack (i_wb_coll_ack),

      .o_wb_timer_dat (wb_timer_dat),
      .o_wb_timer_we  (wb_timer_we),
      .o_wb_timer_cyc (wb_timer_cyc),
      .i_wb_timer_rdt (wb_timer_rdt),

      .o_wb_fifo_dat (wb_fifo_dat),
      .o_wb_fifo_we  (wb_fifo_we),
      .o_wb_fifo_stb (wb_fifo_stb),
      .i_wb_fifo_ack (wb_fifo_ack));

   servant_ram
     #(.memfile (memfile),
       .depth (memsize))
   ram
     (// Wishbone interface
      .i_wb_clk (i_clk),
      .i_wb_adr (wb_mem_adr[$clog2(memsize)-1:2]),
      .i_wb_cyc (wb_mem_cyc),
      .i_wb_we  (wb_mem_we) ,
      .i_wb_sel (wb_mem_sel),
      .i_wb_dat (wb_mem_dat),
      .o_wb_rdt (wb_mem_rdt),
      .o_wb_ack (wb_mem_ack));

   generate
      if (with_csr) begin
	 servant_timer
	   #(.WIDTH (32))
	 timer
	   (.i_clk    (i_clk),
	    .o_irq    (timer_irq),
	    .i_wb_cyc (wb_timer_cyc),
	    .i_wb_we  (wb_timer_we) ,
	    .i_wb_dat (wb_timer_dat),
	    .o_wb_dat (wb_timer_rdt));
      end else begin
	 assign wb_timer_rdt = 32'd0;
	 assign timer_irq = 1'b0;
      end
   endgenerate

   wb2axis w2s
     (.i_clk (i_clk),
      .i_rst (i_rst),
      .i_wb_dat (wb_fifo_dat),
      .i_wb_we  (wb_fifo_we),
      .i_wb_stb (wb_fifo_stb),
      .o_wb_ack (wb_fifo_ack),
      .o_tdata  (o_tdata),
      .o_tlast  (o_tlast),
      .o_tvalid (o_tvalid),
      .i_tready (i_tready));

   serv_rf_top
     #(.RESET_PC (32'h0000_0000),
       .WITH_CSR (with_csr))
   cpu
     (
      .clk      (i_clk),
      .i_rst    (i_rst),
      .i_timer_irq  (timer_irq),
`ifdef RISCV_FORMAL
      .rvfi_valid     (),
      .rvfi_order     (),
      .rvfi_insn      (),
      .rvfi_trap      (),
      .rvfi_halt      (),
      .rvfi_intr      (),
      .rvfi_mode      (),
      .rvfi_ixl       (),
      .rvfi_rs1_addr  (),
      .rvfi_rs2_addr  (),
      .rvfi_rs1_rdata (),
      .rvfi_rs2_rdata (),
      .rvfi_rd_addr   (),
      .rvfi_rd_wdata  (),
      .rvfi_pc_rdata  (),
      .rvfi_pc_wdata  (),
      .rvfi_mem_addr  (),
      .rvfi_mem_rmask (),
      .rvfi_mem_wmask (),
      .rvfi_mem_rdata (),
      .rvfi_mem_wdata (),
`endif

      .o_ibus_adr   (wb_ibus_adr),
      .o_ibus_cyc   (wb_ibus_cyc),
      .i_ibus_rdt   (wb_ibus_rdt),
      .i_ibus_ack   (wb_ibus_ack),

      .o_dbus_adr   (wb_dbus_adr),
      .o_dbus_dat   (wb_dbus_dat),
      .o_dbus_sel   (wb_dbus_sel),
      .o_dbus_we    (wb_dbus_we),
      .o_dbus_cyc   (wb_dbus_cyc),
      .i_dbus_rdt   (wb_dbus_rdt),
      .i_dbus_ack   (wb_dbus_ack));

endmodule
