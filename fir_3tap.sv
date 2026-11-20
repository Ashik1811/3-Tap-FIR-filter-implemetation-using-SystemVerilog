// 3-tap FIR filter - synthesizable SystemVerilog RTL
// The synthesizable DUT intentionally contains no class constructs.
// Classes are used in the separate verification testbench.

module fir_3tap (
    input  logic        clk,
    input  logic        rst_n,   // synchronous active-low reset
    input  logic [7:0]  Xin,
    input  logic [7:0]  H0,
    input  logic [7:0]  H1,
    input  logic [7:0]  H2,
    output logic [15:0] Yout
);

    logic [7:0] x_d1;
    logic [7:0] x_d2;

    logic [15:0] product0;
    logic [15:0] product1;
    logic [15:0] product2;
    logic [15:0] sum01;
    logic [15:0] sum012;

    // Combinational FIR datapath. Arithmetic is unsigned.
    // The 16-bit destinations retain the low 16 bits.
    always_comb begin
        product0 = {8'b0, Xin}  * {8'b0, H0};
        product1 = {8'b0, x_d1} * {8'b0, H1};
        product2 = {8'b0, x_d2} * {8'b0, H2};

        sum01  = product0 + product1;
        sum012 = sum01 + product2;
    end

    // Two-sample delay line and registered output.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            x_d1 <= 8'd0;
            x_d2 <= 8'd0;
            Yout <= 16'd0;
        end
        else begin
            x_d1 <= Xin;
            x_d2 <= x_d1;
            Yout <= sum012;
        end
    end

endmodule
