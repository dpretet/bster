// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 100 ps
`default_nettype none

`include "bster_h.sv"

module csr

    #(
        // Addr Width in bits for Control/Status Register interface
        parameter CSR_ADDR_WIDTH = 8,
        // Data Width in bits for Control/Status Register interface
        parameter CSR_DATA_WIDTH = 32
    )(
        input  wire                         aclk,
        input  wire                         aresetn,
        input  wire                         awvalid,
        output wire                         awready,
        input  wire  [  CSR_ADDR_WIDTH-1:0] awaddr,
        input  wire  [               2-1:0] awprot,
        input  wire                         wvalid,
        output wire                         wready,
        input  wire  [  CSR_DATA_WIDTH-1:0] wdata,
        input  wire  [CSR_DATA_WIDTH/8-1:0] wstrb,
        output wire                         bvalid,
        input  wire                         bready,
        output wire  [               2-1:0] bresp,
        input  wire                         arvalid,
        output wire                         arready,
        input  wire  [  CSR_ADDR_WIDTH-1:0] araddr,
        input  wire  [               2-1:0] arprot,
        output wire                         rvalid,
        input  wire                         rready,
        output wire  [  CSR_DATA_WIDTH-1:0] rdata,
        output wire  [               2-1:0] rresp,
        input  logic [      `CSR_WIDTH-1:0] csr_i,
        output logic [      `CSR_WIDTH-1:0] csr_o
    );

    assign awready = aresetn;
    assign wready = aresetn;
    assign bvalid = 1'b0;
    assign bresp = 2'b0;
    assign arready = aresetn;
    assign rvalid = 1'b0;
    assign rdata = {CSR_DATA_WIDTH{1'b0}};
    assign rresp = 1'b0;

endmodule

`resetall
