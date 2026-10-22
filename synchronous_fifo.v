
`timescale 1ns / 1ps

module synchronous_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 4,
    parameter ADDR_WIDTH = 2,
    parameter COUNT_WIDTH = 3
)(
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] data_in,

    output reg [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty,
    output reg [COUNT_WIDTH-1:0] count,
    output reg overflow,
    output reg underflow
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    wire write_accept = wr_en && !full;
    wire read_accept  = rd_en && !empty;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr    <= 0;
            rd_ptr    <= 0;
            count     <= 0;
            data_out  <= 0;
            overflow  <= 0;
            underflow <= 0;
        end else begin
            overflow  <= wr_en && full && !read_accept;
            underflow <= rd_en && empty;

            // Write operation
            if (write_accept) begin
                mem[wr_ptr] <= data_in;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            // Read operation
            if (read_accept) begin
                data_out <= mem[rd_ptr];

                if (rd_ptr == DEPTH-1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            // Occupancy counter
            case ({write_accept, read_accept})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
