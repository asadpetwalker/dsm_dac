/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
`include 'i2c.sv'
`include 'dsm.sv'

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Submodule Pins
  wire sda_in   = ui_in[3];
  wire scl   = ui_in[4];
  wire rst_n = ui_in[2];
  wire clk   = ui_in[5];
  wire en    = ui_in[1];

  // Intramodule
  wire din[7:0]; 
  wire i2c_enable;
  wire sda_oe; 

  // Output
  wire dsm_out;

  i2c_slave i2c(
    .clk (clk),
    .scl(scl),
    .sda(sda_in),
    .sda_oe (sda_oe),
    .rst(rst),
    .en(en),
    .dac_data (din),
    .i2c_enable (i2c_enable)
  )

  dsm_dac dac(
    .clk (clk),
    .din (din),
    .aout (dsm_out),
    .rst_n (rst_n),
    .en (en)
  )
  
  assign uo_out[0] = aout;
  assign uo_out[7:1] = 7'd0;

  assign uio_out = din;
  assign uio_oe = {7'd0, sda_oe};

endmodule
