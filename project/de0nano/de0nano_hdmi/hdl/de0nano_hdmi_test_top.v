// ===================================================================
// TITLE : CycloneIV E HDMI output sample (DE0-nano + KYANITE2)
//
//     DESIGN : s.osafune@j7system.jp (J-7SYSTEM WORKS LIMITED)
//     DATE   : 2022/12/01 -> 2023/01/02
//            : 2023/03/28
//
//
// ===================================================================
//
// The MIT License (MIT)
// Copyright (c) 2022 J-7SYSTEM WORKS LIMITED.
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


// Verilog-2001 / IEEE 1364-2001
`default_nettype none

module de0nano_hdmi_test_top(
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

//	localparam COLORSPACE	= "RGB";
//	localparam VGACLOCK_MHZ	= 25.2;
//	localparam FSCLOCK_KHZ	= 48.0;
	localparam COLORSPACE	= "BT709";
	localparam VGACLOCK_MHZ	= 74.286;
	localparam FSCLOCK_KHZ	= 44.1;

	localparam FSDIVIDER	= $unsigned(VGACLOCK_MHZ * 1000.0 / FSCLOCK_KHZ + 0.5) - 1;
	localparam FSDIVHALF	= FSDIVIDER / 2;
	localparam COUNTER_WIDTH= 11;
	localparam FSDIVNUM		= FSDIVIDER[COUNTER_WIDTH-1:0];
	localparam FSHALFNUM	= FSDIVHALF[COUNTER_WIDTH-1:0];


/* ===== ノード宣言 ====================== */

	wire			vga_clk_sig, tx_clk_sig, locked_sig, reset_sig;

	reg  [12:0]		ms_counter_reg;
	reg  [COUNTER_WIDTH-1:0] fs_counter_reg;
	reg				fs_timing_reg;
	wire			timing_1ms_sig;
	wire [15:0]		wav_chime_sig;

	wire			active_sig, vsync_sig, hsync_sig;
	wire [7:0]		cb_r_sig, cb_g_sig, cb_b_sig;
	wire			de_out_sig, vs_out_sig, hs_out_sig;
	wire [23:0]		pix_out_sig;
	wire			logo_move_sig;
	wire [23:0]		logo_color_sig;


/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	assign {DRAMCLK_OUT,DRAM_CKE} = 2'b00;					// SDRAMを使わない場合 
	assign {EPCS_DCLK,EPCS_ASDO,EPCS_NCSO} = 3'b001;		// コンフィグROMをユーザーモードで使わない場合 
	assign {SD_CLK,SD_CMD,SD_DAT[3],SD_PWREN_N} = 4'bzzz1;	// SDカードを使わない場合 
	assign {EDID_SCL,EDID_SDA} = 2'bzz;



	///// クロックとリセット /////

generate if (VGACLOCK_MHZ == 25.2) begin
	hdmi_vgapll		// c0:25.2MHz, c1:c0x5(126.0MHz)
	u_pll (
		.areset		(1'b0),
		.inclk0		(CLOCK_50),
		.c0			(vga_clk_sig),
		.c1			(tx_clk_sig),
		.locked		(locked_sig)
	);
end
else if (VGACLOCK_MHZ == 74.286) begin
	hdmi_hdpll		// c0:74.286MHz, c1:c0x5(371.43MHz)
	u_pll (
		.areset		(1'b0),
		.inclk0		(CLOCK_50),
		.c0			(vga_clk_sig),
		.c1			(tx_clk_sig),
		.locked		(locked_sig)
	);
end
endgenerate

	assign reset_sig = ~locked_sig;
	assign LED[0] = locked_sig;



	///// サウンド生成 /////

	always @(posedge vga_clk_sig or posedge reset_sig) begin
		if (reset_sig) begin
			ms_counter_reg <= 1'd0;
			fs_counter_reg <= 1'd0;
			fs_timing_reg <= 1'b0;
		end
		else begin
			if (timing_1ms_sig) begin
				ms_counter_reg <= ms_counter_reg + 1'd1;
			end

			if (fs_counter_reg == FSDIVNUM) begin
				fs_counter_reg <= 1'd0;
				fs_timing_reg <= 1'b1;
			end
			else begin
				fs_counter_reg <= fs_counter_reg + 1'd1;

				if (fs_counter_reg == FSHALFNUM) begin
					fs_timing_reg <= 1'b0;
				end
			end

		end
	end

	melodychime #(
		.CLOCK_FREQ_HZ	($unsigned(VGACLOCK_MHZ * 1000000.0))
	)
	u_chime (
		.reset		(reset_sig),
		.clk		(vga_clk_sig),
		.start		(ms_counter_reg[12]),

		.timing_1ms	(timing_1ms_sig),
		.tempo_led	(LED[1]),
		.wave_out	(wav_chime_sig)
	);



	///// ビデオ同期信号・カラーバー生成 /////

	assign logo_move_sig = 1'b1;

generate if (VGACLOCK_MHZ == 25.2) begin
	video_syncgen #(
		.BAR_MODE	("SD"),
		.COLORSPACE	(COLORSPACE),
		.H_TOTAL	(800),		// VGA(640x480) : 25.20MHz/25.175MHz
		.H_SYNC		(96),
		.H_BACKP	(48),
		.H_ACTIVE	(640),
		.V_TOTAL	(525),
		.V_SYNC		(2),
		.V_BACKP	(33),
		.V_ACTIVE	(480)
	)
	u_vga (
		.reset			(reset_sig),
		.video_clk		(vga_clk_sig),
		.active			(active_sig),
		.hsync			(hsync_sig),
		.vsync			(vsync_sig),
		.cb_rout		(cb_r_sig),
		.cb_gout		(cb_g_sig),
		.cb_bout		(cb_b_sig)
	);

	assign logo_color_sig = 24'hffffff;		// RGB

	logo_overlay #(
		.VIEW_X_SIZE	(640),
		.VIEW_Y_SIZE	(480)
	)
	u_logo (
		.reset			(reset_sig),
		.clock			(vga_clk_sig),
		.logo_color		(logo_color_sig),
		.logo_move		(logo_move_sig),
		.vsync_in		(vsync_sig),
		.hsync_in		(hsync_sig),
		.de_in			(active_sig),
		.pixel_in		({cb_r_sig, cb_g_sig, cb_b_sig}),
		.vsync_out		(vs_out_sig),
		.hsync_out		(hs_out_sig),
		.de_out			(de_out_sig),
		.pixel_out		(pix_out_sig)
	);
end
else if (VGACLOCK_MHZ == 74.286) begin
	video_syncgen #(
		.BAR_MODE	("WIDE"),
		.COLORSPACE	(COLORSPACE),
		.H_TOTAL	(1650),		// HD720p(1280x720) : 74.25MHz/74.176MHz
		.H_SYNC		(40),
		.H_BACKP	(260),
		.H_ACTIVE	(1280),
		.V_TOTAL	(750),
		.V_SYNC		(5),
		.V_BACKP	(20),
		.V_ACTIVE	(720)
	)
	u_vga (
		.reset			(reset_sig),
		.video_clk		(vga_clk_sig),
		.active			(active_sig),
		.hsync			(hsync_sig),
		.vsync			(vsync_sig),
		.cb_rout		(cb_r_sig),
		.cb_gout		(cb_g_sig),
		.cb_bout		(cb_b_sig)
	);

	assign logo_color_sig = 24'h80eb80;		// YCbCr

	logo_overlay #(
		.VIEW_X_SIZE	(1280),
		.VIEW_Y_SIZE	(720)
	)
	u_logo (
		.reset			(reset_sig),
		.clock			(vga_clk_sig),
		.logo_color		(logo_color_sig),
		.logo_move		(logo_move_sig),
		.vsync_in		(vsync_sig),
		.hsync_in		(hsync_sig),
		.de_in			(active_sig),
		.pixel_in		({cb_r_sig, cb_g_sig, cb_b_sig}),
		.vsync_out		(vs_out_sig),
		.hsync_out		(hs_out_sig),
		.de_out			(de_out_sig),
		.pixel_out		(pix_out_sig)
	);
end
endgenerate



	///// HDMI-TX /////

	hdmi_tx #(
		.DEVICE_FAMILY		("Cyclone IV E"),
		.CLOCK_FREQUENCY	(VGACLOCK_MHZ),
		.SCANMODE			("UNDER"),
		.COLORSPACE			(COLORSPACE),
		.AUDIO_FREQUENCY	(FSCLOCK_KHZ)
	)
	u_tx (
		.reset		(reset_sig),
		.clk		(vga_clk_sig),
		.clk_x5		(tx_clk_sig),

		.active		(de_out_sig),
		.r_data		(pix_out_sig[23:16]),
		.g_data		(pix_out_sig[15:8]),
		.b_data		(pix_out_sig[7:0]),
		.hsync		(hs_out_sig),
		.vsync		(vs_out_sig),

		.pcm_fs		(fs_timing_reg),
		.pcm_l		({{2{wav_chime_sig[15]}}, wav_chime_sig, 6'd0}),	// -12dB
		.pcm_r		({{2{wav_chime_sig[15]}}, wav_chime_sig, 6'd0}),	// -12dB

		.data		(TMDS_DATA),
		.data_n		(TMDS_DATA_N),
		.clock		(TMDS_CLOCK),
		.clock_n	(TMDS_CLOCK_N)
	);

	assign LED[2] = ~DISP_HPD_N;



endmodule
