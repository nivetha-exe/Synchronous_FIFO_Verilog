`timescale 1ns / 1ps

module tb_synchronous_fifo;

    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [7:0] data_in;

    wire [7:0] data_out;
    wire full;
    wire empty;
    wire [2:0] count;
    wire overflow;
    wire underflow;

    integer errors;

    synchronous_fifo dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty),
        .count(count),
        .overflow(overflow),
        .underflow(underflow)
    );

    always #5 clk = ~clk;

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task write_byte;
        input [7:0] value;
        begin
            @(negedge clk);
            wr_en = 1;
            rd_en = 0;
            data_in = value;
            tick;
            @(negedge clk);
            wr_en = 0;
        end
    endtask

    task read_byte;
        input [7:0] expected;
        begin
            @(negedge clk);
            wr_en = 0;
            rd_en = 1;
            tick;

            if (data_out !== expected) begin
                $display("ERROR: expected %h, got %h",
                         expected, data_out);
                errors = errors + 1;
            end else begin
                $display("PASS: read %h", data_out);
            end

            @(negedge clk);
            rd_en = 0;
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;
        errors = 0;

        // Reset
        tick;
        @(negedge clk);
        rst = 0;

        if (count !== 0 || empty !== 1 || full !== 0) begin
            $display("ERROR: reset failed");
            errors = errors + 1;
        end

        // Underflow test
        @(negedge clk);
        rd_en = 1;
        tick;

        if (underflow !== 1 || count !== 0 || empty !== 1) begin
            $display("ERROR: underflow protection failed");
            errors = errors + 1;
        end

        @(negedge clk);
        rd_en = 0;

        // Fill FIFO
        write_byte(8'h11);
        write_byte(8'h22);
        write_byte(8'h33);
        write_byte(8'h44);

        if (count !== 4 || full !== 1 || empty !== 0) begin
            $display("ERROR: full flag failed");
            errors = errors + 1;
        end

        // Overflow test
        @(negedge clk);
        wr_en = 1;
        data_in = 8'h55;
        tick;

        if (overflow !== 1 || count !== 4 || full !== 1) begin
            $display("ERROR: overflow protection failed");
            errors = errors + 1;
        end

        @(negedge clk);
        wr_en = 0;

        // FIFO order
        read_byte(8'h11);
        read_byte(8'h22);

        // Simultaneous read and write
        @(negedge clk);
        wr_en = 1;
        rd_en = 1;
        data_in = 8'h55;
        tick;

        if (data_out !== 8'h33 || count !== 2) begin
            $display("ERROR: simultaneous read/write failed");
            errors = errors + 1;
        end

        @(negedge clk);
        wr_en = 0;
        rd_en = 0;

        // Verify remaining data
        read_byte(8'h44);
        read_byte(8'h55);

        if (count !== 0 || empty !== 1 || full !== 0) begin
            $display("ERROR: empty state failed");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTBENCH FAILED: %0d errors", errors);

        $finish;
    end

endmodule
