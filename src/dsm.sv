module dsm_dac (
    input wire clk;
    input wire[7:0] din;
    
    input wire rst_n;
    input wire en;

    output reg aout;
)

    // 8 input bits, 1 overflow bit
    reg[8:0] accum;

    always (@posedge clk or negedge rst_n) begin
        if (!en or !rst_n) begin
            accum = 9'b0;
            aout = 1'b0;
        end else begin
            reg[8:0] sum;

            // Niche swap
            sum <= {1'b0, accum[7:0]} + {1'b0, din};
            accum <= sum;
            
            // sum[8] changes value between 0 and 1
            // s.t, per the clock cycle, is modulated
            // by the values of din
            aout <= sum[8];
        end
    end
endmodule