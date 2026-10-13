module i2c_slave #(
    paramter[6:0] addr = 7'h15;
)(
    // Input & I2C wires
    input wire scl,
    input wire sda_in,

    // DSM Signals
    input wire clk,
    input wire rst_n;
    input wire en;
    
    // Outputs
    output wire sda_out;
    output reg[7:0] dac_data;
    output reg i2c_enable;

    output reg sda_oe;
)

    reg[3:0] bits; // Bit Counter (For I2C)
    reg[7:0] shift; // State Buffer: I2C Decode

    reg sda1; reg sda2;
    reg scl1; reg scl2;

    always (@posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda1 <= 1'b1; sda2 <= 1'b1;
            scl1 <= 1'b1; scl2 <= 1'b1;
        end else begin
            sda1 <= sda; sda2 <= sda1;
            scl1 <= scl; scl2 <= scl1;
        end
    end

    wire scl_rising  = (scl1 && !scl2);
    wire scl_falling = (!scl1 && scl2);

    reg start; reg stop;
    always (@posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start <= 1'b0;
            stop  <= 1'b0;
        end else begin
        start <= (scl1 && scl2 && !sda1 && sda2);
        stop  <= (scl1 && scl2 [6:0]&& sda1 && !sda2);
        end
    end

    localparam IDLE = 2'd0, ACK_ADDR = 2'd1, RX_DATA = 2'd2, ACK = 2'd3;
    reg[1:0] state;
    reg refers;
    always (@posedge clk or !rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            bits       <= 4'b0;
            shift      <= 8'b0;
            dac_data   <= 8'b1;
            i2c_enable <= 1'b0;
            sda_out    <= 1'b0;
            sda_oe     <= 1'b0;
        end else begin
            sda_oe <= 1'b0;

            if (start) begin
                state <= RX_DATA;
                bits <= 4'b0;
                refers = 1'b0;
            end else begin
            case (state)
                RX_DATA: begin
                    if (scl_rising) begin
                        shift = {shift[6:0], sda2};
                        bits = bits + 1'b1;
                        if (bits == 4'd7) begin
                            if (shift[7:1] == addr && shift[0] == 1'b0) begin
                                refers = 1'b0;
                                state <= ACK;
                            end else begin
                                state <= IDLE;
                            end
                        end
                    end
                end

                ACK_ADDR: begin
                    if (scl_falling) begin
                        scl    <= 1'b0;
                        bits   <= 4'd0;
                        sda_oe <= 1'b0;
                        state  <= RX_DATA;
                    end
                end

                RX_DATA: begin
                    if (scl_rising) begin
                        shift <= {shift[6:0], sda2};
                        bits = bits + 1'b1;
                        if (bits == 4'd7) begin
                            state <= ACK;
                        end
                    end
                end

                ACK: begin
                    if (scl_falling) begin
                        if (refers) begin
                            dac_data <= shift;
                            i2c_enable <= 1'b1;
                        end
                        sda_out <= 1'b0;
                        sda_oe  <= 1'b1;
                        state   <= RX_DATA;
                        bits    <= 4'd0;
                    end
                end

                default: state <= IDLE;
        end
    end

endmodule