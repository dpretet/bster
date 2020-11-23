// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module scfifo

    #(
    )(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_in,
    input  wire       push,
    output wire       full,
    output wire [7:0] data_out,
    input  wire       pop,
    output wire       empty
    );

    wire       wr_en;
    wire       rd_en;
    wire [2:0] wrptr;
    wire [2:0] rdptr;

    // Write Pointer Management

    always @ (posedge clk or negedge rst_n) begin

        if (rst_n == 1'b0) begin
            wrptr <= 2'b0;
        end else begin
            if (push == 1'b1 && full == 1'b0) begin
                wrptr <= wrptr + 1'b1;
            end
        end
    end

    // Read Pointer Management

    always @ (posedge clk or negedge rst_n) begin

        if (rst_n == 1'b0) begin
            rdptr <= 2'b0;
        end else begin
            if (pull == 1'b1 && empty == 1'b0) begin
                rdptr <= rdptr + 1'b1;
            end
        end
    end

    assign wr_en = push & !full;
    assign rd_end = pull & !empty;

    assign empty = (wrptr == rdptr) ? 1'b1 : 1'b0;
    assign full = ((wrptr - rdptr) == 3'b100) ? 1'b1 : 1'b0;

endmodule

module scram

    #(
    )(
    input  wire       clk,
    input  wire       wr_en,
    input  wire [1:0] addr_in,
    input  wire [7:0] data_in,
    input  wire       rd_en,
    input  wire [1:0] addr_out,
    output wire [7:0] data_out,
    );

    reg [7:0] ram [0:3];

    always @ (posedge clk) begin
        if (wr_en)
            ram[addr_in] <= data_in;
    end

    always @ (posedge clk) begin
        if (rd_en)
            data_out <= ram[addr_out];
    end

endmodule

`resetall

