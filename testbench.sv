module testbench;

logic clk100 = 0;
logic gt_refclk_p = 0;
logic gt_refclk_n;

logic [31:0] aurora0_tx_tdata = 1;
logic [3:0] aurora0_tx_tkeep = 0;
logic aurora0_tx_tvalid = 0;
logic aurora0_tx_tlast = 0;
logic aurora0_tx_tready;
logic [31:0] aurora1_rx_tdata;
logic [3:0] aurora1_rx_tkeep;
logic aurora1_rx_tvalid;
logic aurora1_rx_tlast;

logic aurora0_gt_rx_n;
logic aurora0_gt_rx_p;
logic aurora0_lane_up;
logic aurora0_channel_up;
logic aurora0_crc_pass_fail;
logic aurora0_crc_valid;
logic aurora0_user_clk;
logic aurora0_gt_reset = 1;
logic [7:0] aurora0_gt_reset_counter = 0;
logic aurora0_reset = 1;
logic [7:0] aurora0_reset_counter = 0;

logic aurora1_gt_rx_n;
logic aurora1_gt_rx_p;
logic aurora1_lane_up;
logic aurora1_channel_up;
logic aurora1_crc_pass_fail;
logic aurora1_crc_valid;
logic aurora1_user_clk;
logic aurora1_gt_reset = 1;
logic [7:0] aurora1_gt_reset_counter = 0;
logic aurora1_reset = 1;
logic [7:0] aurora1_reset_counter = 0;

always
begin
  #5ns clk100 = ~clk100;
end

always
begin
  #3.2ns gt_refclk_p = ~gt_refclk_p;
end
assign gt_refclk_n = ~gt_refclk_p;

//Data
typedef enum {INIT, DATA_WAIT, TX, TX_WAIT} data_state_type;
data_state_type data_state = INIT;
logic [7:0] data_wait_count = 0;

always @ (posedge aurora0_user_clk)
begin
  case (data_state)
    INIT :
      if (aurora0_reset == 0 && aurora0_channel_up == 1 && aurora0_lane_up == 1)
        data_state <= DATA_WAIT;
    DATA_WAIT :
      begin
        data_wait_count <= data_wait_count + 1;
        if (data_wait_count == 8'h5)
          data_state <= TX;
      end
    TX :
      begin
        aurora0_tx_tvalid <= 1;
        aurora0_tx_tlast <= 1;
        aurora0_tx_tkeep <= 4'b1111;
        data_state <= TX_WAIT;
      end
    TX_WAIT :
      if (aurora0_tx_tready)
        begin
          aurora0_tx_tvalid <= 0;
          aurora0_tx_tlast <= 0;
          aurora0_tx_tkeep <= 0;
          aurora0_tx_tdata <= aurora0_tx_tdata + 1;
          data_wait_count <= 0;
          data_state <= DATA_WAIT;
        end
  endcase;
end

//Aurora0
always @ (posedge clk100)
begin
  aurora0_gt_reset_counter <= aurora0_gt_reset_counter + 1;
  if (aurora0_gt_reset_counter == 8'h20)
    aurora0_gt_reset <= 0;
end

always @ (posedge aurora0_user_clk)
begin
  aurora0_reset_counter <= aurora0_reset_counter + 1;
  if (aurora0_reset_counter == 8'h20)
    aurora0_reset <= 0;
end

aurora0 aurora0_inst (
  .s_axi_tx_tdata         (aurora0_tx_tdata),
  .s_axi_tx_tkeep         (aurora0_tx_tkeep),
  .s_axi_tx_tvalid        (aurora0_tx_tvalid),
  .s_axi_tx_tlast         (aurora0_tx_tlast),
  .s_axi_tx_tready        (aurora0_tx_tready),
  .m_axi_rx_tdata         (),
  .m_axi_rx_tkeep         (),
  .m_axi_rx_tvalid        (),
  .m_axi_rx_tlast         (),
  .rxp                    (aurora0_gt_rx_p),
  .rxn                    (aurora0_gt_rx_n),
  .txp                    (aurora1_gt_rx_p),
  .txn                    (aurora1_gt_rx_n),
  .gt_refclk1_p           (gt_refclk_p),
  .gt_refclk1_n           (gt_refclk_n),
  .gt_refclk1_out         (),
  .frame_err              (),
  .hard_err               (),
  .soft_err               (),
  .lane_up                (aurora0_lane_up),
  .channel_up             (aurora0_channel_up),
  .crc_pass_fail_n        (aurora0_crc_pass_fail),
  .crc_valid              (aurora0_crc_valid),
  .user_clk_out           (aurora0_user_clk),
  .sync_clk_out           (),
  .gt_reset               (aurora0_gt_reset),
  .reset                  (aurora0_reset),
  .sys_reset_out          (),
  .gt_reset_out           (),
  .power_down             (1'b0),
  .loopback               (3'b000),
  .tx_lock                (),
  .init_clk_in            (clk100),
  .tx_resetdone_out       (),
  .rx_resetdone_out       (),
  .link_reset_out         (),
  .drpclk_in              (clk100),
  .drpaddr_in             (9'h0),
  .drpen_in               (1'b0),
  .drpdi_in               (16'h0),
  .drprdy_out             (),
  .drpdo_out              (),
  .drpwe_in               (1'b0),
  .gt0_pll0refclklost_out (),
  .quad1_common_lock_out  (),
  .gt0_pll0outclk_out     (),
  .gt0_pll1outclk_out     (),
  .gt0_pll0outrefclk_out  (),
  .gt0_pll1outrefclk_out  (),
  .pll_not_locked_out     ()
);

//Aurora1
always @ (posedge clk100)
begin
  aurora1_gt_reset_counter <= aurora1_gt_reset_counter + 1;
  if (aurora1_gt_reset_counter == 8'h20)
    aurora1_gt_reset <= 0;
end

always @ (posedge aurora1_user_clk)
begin
  aurora1_reset_counter <= aurora1_reset_counter + 1;
  if (aurora1_reset_counter == 8'h20)
    aurora1_reset <= 0;
end

aurora1 aurora1_inst (
  .s_axi_tx_tdata         (32'h0),
  .s_axi_tx_tkeep         (4'b0000),
  .s_axi_tx_tvalid        (1'b0),
  .s_axi_tx_tlast         (1'b0),
  .s_axi_tx_tready        (),
  .m_axi_rx_tdata         (aurora1_rx_tdata),
  .m_axi_rx_tkeep         (aurora1_rx_tkeep),
  .m_axi_rx_tvalid        (aurora1_rx_tvalid),
  .m_axi_rx_tlast         (aurora1_rx_tlast),
  .rxp                    (aurora1_gt_rx_p),
  .rxn                    (aurora1_gt_rx_n),
  .txp                    (aurora0_gt_rx_p),
  .txn                    (aurora0_gt_rx_n),
  .gt_refclk1_p           (gt_refclk_p),
  .gt_refclk1_n           (gt_refclk_n),
  .gt_refclk1_out         (),
  .frame_err              (),
  .hard_err               (),
  .soft_err               (),
  .lane_up                (aurora1_lane_up),
  .channel_up             (aurora1_channel_up),
  .crc_pass_fail_n        (aurora1_crc_pass_fail),
  .crc_valid              (aurora1_crc_valid),
  .user_clk_out           (aurora1_user_clk),
  .sync_clk_out           (),
  .gt_reset               (aurora1_gt_reset),
  .reset                  (aurora1_reset),
  .sys_reset_out          (),
  .gt_reset_out           (),
  .power_down             (1'b0),
  .loopback               (3'b000),
  .tx_lock                (),
  .init_clk_in            (clk100),
  .tx_resetdone_out       (),
  .rx_resetdone_out       (),
  .link_reset_out         (),
  .drpclk_in              (clk100),
  .drpaddr_in             (9'h0),
  .drpen_in               (1'b0),
  .drpdi_in               (16'h0),
  .drprdy_out             (),
  .drpdo_out              (),
  .drpwe_in               (1'b0),
  .gt0_pll0refclklost_out (),
  .quad1_common_lock_out  (),
  .gt0_pll0outclk_out     (),
  .gt0_pll1outclk_out     (),
  .gt0_pll0outrefclk_out  (),
  .gt0_pll1outrefclk_out  (),
  .pll_not_locked_out     ()
);

endmodule

