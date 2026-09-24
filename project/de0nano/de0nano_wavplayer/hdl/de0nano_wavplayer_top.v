// ===================================================================
// TITLE : DE0-nano / VGA component test top
//
//     DESIGN : s.osafune@j7system.jp (J-7SYSTEM WORKS LIMITED)
//     DATE   : 2023/01/01 -> 2023/01/11
//            : 2023/04/03
//
// ===================================================================
//
// The MIT License (MIT)
// Copyright (c) 2023 J-7SYSTEM WORKS LIMITED.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

`default_nettype none

module de0nano_wavplayer_top(
	// clk and system reset
	input wire			CLOCK_50,
	input wire			EXTCLK_48,

	// KEY and LED
	input wire  [1:0]	KEY,
	input wire  [3:0]	SW,
	output wire [7:0]	LED,

	// Interface: EPCS memory controller
	output wire			EPCS_NCSO,
	output wire			EPCS_DCLK,
	output wire			EPCS_ASDO,
	input wire			EPCS_DATA0,

	// Interface: SDRAM
	output wire			DRAMCLK_OUT,
	output wire			DRAM_CKE,
	output wire			DRAM_CS_N,
	output wire			DRAM_RAS_N,
	output wire			DRAM_CAS_N,
	output wire			DRAM_WE_N,
	output wire [12:0]	DRAM_ADDR,
	output wire [1:0]	DRAM_BA,
	inout wire  [15:0]	DRAM_DQ,
	output wire [1:0]	DRAM_DQM,

	// Interface: GPIO-0
	input wire  [1:0]	GPIO_0_IN,
	inout wire  [33:0]	GPIO_0,

	// Interface: TMDS display
	output wire [2:0]	TMDS_DATA,
	output wire [2:0]	TMDS_DATA_N,
	output wire			TMDS_CLOCK,
	output wire			TMDS_CLOCK_N,
	inout wire			EDID_SCL,
	inout wire			EDID_SDA,
	input wire			DISP_HPD_N,

	// Interface: SD-card controller
	output wire			SD_CLK,
	output wire			SD_CMD,
	inout wire  [3:0]	SD_DAT,
	output wire			SD_PWREN_N,		// SD-card Power enable
	input wire			SD_CD_N,		// SD-card Detect

	// Interface: USB
	inout wire			USB_DP,
	inout wire			USB_DM,
	output wire			USB_PWREN_N,	// VUSB Power enable

	// Interface: Audio
	output wire			AUD_L,
	output wire			AUD_R,

	// Interface: Ethernet
	output wire			ETH_SS_N,
	output wire			ETH_SCLK,
	output wire			ETH_MOSI,
	input wire			ETH_MISO,
	input wire			ETH_INT_N,
	output wire			ETH_RST_N,

	// Access LED
	output wire			LED_ACCESS
);


/* ===== 外部変更可能パラメータ ========== */



/* ----- 内部パラメータ ------------------ */

	localparam VGACLOCK_MHZ	= 74.286;
	localparam FSCLOCK_KHZ	= 44.1;


/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = ~KEY[0];			// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = CLOCK_50;			// モジュール内部駆動クロック 

	wire			qsys_reset_n_sig;
	wire			clock_core_sig, clock_peri_sig;
	wire			vpll_locked_sig;
	wire			vga_clk_sig, tx_clk_sig, pcm_clk_sig;

	wire			sd_ssn_sig, sd_pwr_sig;
	wire [1:0]		led_sig;
//	wire			uart_rxd_sig, uart_txd_sig;
	wire			vga_active_sig, vga_hsyncn_sig, vga_vsyncn_sig;
	wire [7:0]		vga_rout_sig, vga_gout_sig, vga_bout_sig;
	wire			pcm_fs_sig, mute_sig;
	wire [15:0]		pcm_l_sig, pcm_r_sig;
	wire [11:0]		barcolor_sig;

	wire			bar_active_sig, bar_hsyncn_sig, bar_vsyncn_sig;
	wire [7:0]		bar_r_sig, bar_g_sig, bar_b_sig;

	reg  [6:0]		fsdivcount_reg;
	wire			fs8_timing_sig, fs_timing_sig;


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	///// 未使用ピンの処理 /////

	assign {EPCS_DCLK,EPCS_ASDO,EPCS_NCSO} = 3'b001;		// コンフィグROMをユーザーモードで使わない場合 
	assign {EDID_SCL,EDID_SDA} = 2'bzz;



	///// クロックとリセット /////

	syspll		// c0:100.0MHz(-2.60ns), c1:100.0MHz, c2:25.0MHz, c3:5.6452MHz
	u0 (
		.areset		(reset_sig),
		.inclk0		(clock_sig),
		.c0			(DRAMCLK_OUT),
		.c1			(clock_core_sig),
		.c2			(clock_peri_sig),
		.c3			(pcm_clk_sig),
		.locked		(qsys_reset_n_sig)
	);

	hdpll		// c0:74.286MHz, c1:c0x5(371.43MHz)
	u1 (
		.areset		(reset_sig),
		.inclk0		(clock_sig),
		.c0			(vga_clk_sig),
		.c1			(tx_clk_sig),
		.locked		(vpll_locked_sig)
	);



	///// Platform Designerコンポーネントのインスタンス /////

    c4e_pcmplay_core
	u2 (
        .reset_reset_n		(qsys_reset_n_sig),	//    reset.reset_n
        .clk_100m_clk		(clock_core_sig),	// clk_100m.clk
        .clk_25m_clk		(clock_peri_sig),	//  clk_25m.clk

        .uart_rxd			(1'b1),				//     uart.rxd
        .uart_txd			(),					//         .txd

        .sdr_addr			(DRAM_ADDR),		//      sdr.addr
        .sdr_ba				(DRAM_BA),			//         .ba
        .sdr_cs_n			(DRAM_CS_N),		//         .cs_n
        .sdr_ras_n			(DRAM_RAS_N),		//         .ras_n
        .sdr_cas_n			(DRAM_CAS_N),		//         .cas_n
        .sdr_we_n			(DRAM_WE_N),		//         .we_n
        .sdr_dq				(DRAM_DQ),			//         .dq
        .sdr_dqm			(DRAM_DQM),			//         .dqm
        .sdr_cke			(DRAM_CKE),			//         .cke

        .sd_clk				(SD_CLK),			//       sd.clk
        .sd_cmd				(SD_CMD),			//         .cmd
        .sd_dat0			(SD_DAT[0]),		//         .dat0
        .sd_dat3			(sd_ssn_sig),		//         .dat3
        .sd_cd_n			(SD_CD_N),			//         .cd_n
        .sd_pwr				(sd_pwr_sig),		//         .pwr

        .vga_videoclk		(vga_clk_sig),		//      vga.videoclk
        .vga_active			(vga_active_sig),	//         .active
        .vga_rout			(vga_rout_sig),		//         .rout
        .vga_gout			(vga_gout_sig),		//         .gout
        .vga_bout			(vga_bout_sig),		//         .bout
        .vga_hsync_n		(vga_hsyncn_sig),	//         .hsync_n
        .vga_vsync_n		(vga_vsyncn_sig),	//         .vsync_n

        .pcm_clk_128fs		(pcm_clk_sig),		//      pcm.clk_128fs
        .pcm_fs				(pcm_fs_sig),		//         .fs
        .pcm_ldata			(pcm_l_sig),		//         .ldata
        .pcm_rdata			(pcm_r_sig),		//         .rdata
		.pcm_mute			(mute_sig),			//         .mute
        .bar_export			(barcolor_sig),		//      bar.export

        .gpio_export		()					//     gpio.export
    );

	assign SD_DAT = {sd_ssn_sig, 3'bzzz};
	assign SD_PWREN_N = ~sd_pwr_sig;

	assign LED_ACCESS = ~sd_ssn_sig;


	// LED

	assign LED[0] = vpll_locked_sig;



	///// サウンドバー合成 /////

	audiobar
	u_bar (
		.reset		(reset_sig),
		.clk		(vga_clk_sig),

		.mute		(mute_sig),
		.bar_color	({{2{barcolor_sig[11:8]}}, {2{barcolor_sig[7:4]}}, {2{barcolor_sig[3:0]}}}),
		.pcm_l_in	(pcm_l_sig),
		.pcm_r_in	(pcm_r_sig),

		.active_in	(vga_active_sig),
		.r_in		(vga_rout_sig),
		.g_in		(vga_gout_sig),
		.b_in		(vga_bout_sig),
		.hsyncn_in	(vga_hsyncn_sig),
		.vsyncn_in	(vga_vsyncn_sig),

		.active_out	(bar_active_sig),
		.r_out		(bar_r_sig),
		.g_out		(bar_g_sig),
		.b_out		(bar_b_sig),
		.hsyncn_out	(bar_hsyncn_sig),
		.vsyncn_out	(bar_vsyncn_sig)
	);



	///// HDMI-TX /////

	hdmi_tx #(
		.DEVICE_FAMILY		("Cyclone IV E"),
		.CLOCK_FREQUENCY	(VGACLOCK_MHZ),
		.SCANMODE			("UNDER"),
		.AUDIO_FREQUENCY	(FSCLOCK_KHZ)
	)
	u_tx (
		.reset		(reset_sig),
		.clk		(vga_clk_sig),
		.clk_x5		(tx_clk_sig),

		.active		(bar_active_sig),
		.r_data		(bar_r_sig),
		.g_data		(bar_g_sig),
		.b_data		(bar_b_sig),
		.hsync		(~bar_hsyncn_sig),
		.vsync		(~bar_vsyncn_sig),

		.pcm_fs		(pcm_fs_sig),
		.pcm_l		({pcm_l_sig, 8'd0}),
		.pcm_r		({pcm_r_sig, 8'd0}),

		.data		(TMDS_DATA),
		.data_n		(TMDS_DATA_N),
		.clock		(TMDS_CLOCK),
		.clock_n	(TMDS_CLOCK_N)
	);



	///// LINE出力 /////

	always @(posedge pcm_clk_sig or negedge qsys_reset_n_sig) begin
		if (!qsys_reset_n_sig) begin
			fsdivcount_reg <= 1'd0;
		end
		else begin
			fsdivcount_reg <= fsdivcount_reg + 1'd1;
		end
	end

	assign fs8_timing_sig = (fsdivcount_reg[3:0])? 1'b0 : 1'b1;
	assign fs_timing_sig = (fsdivcount_reg)? 1'b0 : 1'b1;

	peridot_wsg_dsdac8 #(
		.PCMBITWIDTH	(16)
	)
	u_aud_l (
		.reset		(~qsys_reset_n_sig),
		.clk		(pcm_clk_sig),
		.fs_timing	(fs_timing_sig),
		.fs8_timing	(fs8_timing_sig),

		.pcmdata_in	(pcm_l_sig),
		.dac_out	(AUD_L)
	);

	peridot_wsg_dsdac8 #(
		.PCMBITWIDTH	(16)
	)
	u_aud_r (
		.reset		(~qsys_reset_n_sig),
		.clk		(pcm_clk_sig),
		.fs_timing	(fs_timing_sig),
		.fs8_timing	(fs8_timing_sig),

		.pcmdata_in	(pcm_r_sig),
		.dac_out	(AUD_R)
	);



endmodule
