// Class-based self-checking testbench for fir_3tap.
// Simulation-only: do not include this file in synthesis.

`timescale 1ns/1ps

// Reference-model class:
// Keeps the two previous samples and computes the expected FIR output.
class fir_reference_model;

    logic [7:0] history_1;
    logic [7:0] history_2;

    function new();
        history_1 = 8'd0;
        history_2 = 8'd0;
    endfunction

    function void reset();
        history_1 = 8'd0;
        history_2 = 8'd0;
    endfunction

    // Returns output for current input using PREVIOUS history,
    // then advances the model's sample history.
    function logic [15:0] step(
        input logic [7:0] sample,
        input logic [7:0] coeff0,
        input logic [7:0] coeff1,
        input logic [7:0] coeff2
    );
        logic [15:0] term0;
        logic [15:0] term1;
        logic [15:0] term2;
        logic [15:0] result;

        term0 = {8'b0, sample}    * {8'b0, coeff0};
        term1 = {8'b0, history_1} * {8'b0, coeff1};
        term2 = {8'b0, history_2} * {8'b0, coeff2};

        result = term0 + term1 + term2;

        // Advance history only after calculating the current result.
        history_2 = history_1;
        history_1 = sample;

        return result;
    endfunction

endclass


module tb_fir_3tap;

    logic clk;
    logic rst_n;
    logic [7:0] Xin;
    logic [7:0] H0, H1, H2;
    logic [15:0] Yout;

    integer errors;
    integer samples_checked;
    logic [15:0] expected;

    // Class handle for the independent reference model.
    fir_reference_model reference_model;

    fir_3tap dut (
        .clk   (clk),
        .rst_n (rst_n),
        .Xin   (Xin),
        .H0    (H0),
        .H1    (H1),
        .H2    (H2),
        .Yout  (Yout)
    );

    // 10 ns clock period.
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Create the class object before the first rising clock edge.
    initial begin
        reference_model = new();
        errors = 0;
        samples_checked = 0;
    end

    // Scoreboard/monitor: class predicts the output; monitor compares DUT.
    // Inputs are driven on falling edges in the stimulus process below.
    always @(posedge clk) begin
        if (!rst_n) begin
            reference_model.reset();
            #1;
            if (Yout !== 16'd0) begin
                $error("RESET FAIL at %0t: Yout=%0d, expected=0", $time, Yout);
                errors = errors + 1;
            end
        end
        else begin
            expected = reference_model.step(Xin, H0, H1, H2);
            #1;
            samples_checked = samples_checked + 1;

            if (Yout !== expected) begin
                $error("MISMATCH at %0t: Xin=%0d, Yout=%0d, expected=%0d",
                       $time, Xin, Yout, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS t=%0t Xin=%0d Yout=%0d",
                         $time, Xin, Yout);
            end
        end
    end

    // Stimulus: change data on negedge to avoid races with DUT posedge logic.
    initial begin
        rst_n = 1'b0;
        Xin   = 8'd0;
        H0    = 8'd10;
        H1    = 8'd20;
        H2    = 8'd30;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        // Original project input sequence: 0,3,1,1,2,1,4,5,6,0.
        Xin = 8'd0; @(negedge clk);
        Xin = 8'd3; @(negedge clk);
        Xin = 8'd1; @(negedge clk);
        Xin = 8'd1; @(negedge clk);
        Xin = 8'd2; @(negedge clk);
        Xin = 8'd1; @(negedge clk);
        Xin = 8'd4; @(negedge clk);
        Xin = 8'd5; @(negedge clk);
        Xin = 8'd6; @(negedge clk);
        Xin = 8'd0; @(negedge clk);

        // Flush the FIR history with zero-valued samples.
        Xin = 8'd0;
        repeat (4) @(negedge clk);

        // Allow monitor to finish the last comparison.
        @(posedge clk);
        #2;

        if (errors == 0)
            $display("TEST PASSED: %0d output samples checked.", samples_checked);
        else
            $fatal(1, "TEST FAILED: %0d errors in %0d checked samples.",
                   errors, samples_checked);

        $finish;
    end

    initial begin
        $dumpfile("fir_3tap_class_tb.vcd");
        $dumpvars(0, tb_fir_3tap);
    end

    initial begin
        #1000;
        $fatal(1, "Simulation timeout.");
    end

endmodule
