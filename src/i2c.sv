module i2c_slave (
    // Input & I2C wires
    input wire scl,
    input wire sda,

    input wire rst_n;

    // DSM CLK
    input wire clk,

    // Internal configs
    output wire rst;
    output wire[7:0] din;
    



)