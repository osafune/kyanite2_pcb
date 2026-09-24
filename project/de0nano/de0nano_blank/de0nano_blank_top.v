// ===================================================================
// TITLE : Kyanite2 for DE0-nano
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

module de0nano_blank_top
(
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



/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = ~KEY[0];			// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = CLOCK_50;			// モジュール内部駆動クロック 


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */




endmodule
