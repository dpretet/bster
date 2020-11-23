// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

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
