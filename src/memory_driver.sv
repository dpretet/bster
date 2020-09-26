// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 100 ps
`default_nettype none


module memory_driver

    #(
        // Define the token width
        parameter TOKEN_WIDTH = 8,
        // Define the payload width
        parameter PAYLOAD_WIDTH = 32,
        // Width of data bus in bits
        parameter RAM_DATA_WIDTH = 32,
        // Width of address bus in bits
        parameter RAM_ADDR_WIDTH = 16,
        // Width of wstrb (width of data bus in words)
        parameter RAM_STRB_WIDTH = (DATA_WIDTH/8),
        // Width of ID signal
        parameter RAM_ID_WIDTH = 8
    )(
        input  wire                        aclk,
        input  wire                        aresetn,
        // BST engine interface
        input  wire                        mem_valid,
        output wire                        mem_ready,
        input  wire                        mem_rd,
        input  wire                        mem_wr,
        input  wire [  RAM_ADDR_WIDTH-1:0] mem_addr,
        input  wire [  RAM_DATA_WIDTH-1:0] mem_wr_data,
        output wire                        mem_rd_valid,
        output wire [  RAM_DATA_WIDTH-1:0] mem_rd_data,
        // AXI4 Interface to RAM storing the binary tree
        output wire [    RAM_ID_WIDTH-1:0] ram_axi_awid,
        output wire [  RAM_ADDR_WIDTH-1:0] ram_axi_awaddr,
        output wire [                 7:0] ram_axi_awlen,
        output wire [                 2:0] ram_axi_awsize,
        output wire [                 1:0] ram_axi_awburst,
        output wire                        ram_axi_awlock,
        output wire [                 3:0] ram_axi_awcache,
        output wire [                 2:0] ram_axi_awprot,
        output wire                        ram_axi_awvalid,
        input  wire                        ram_axi_awready,
        output wire [  RAM_DATA_WIDTH-1:0] ram_axi_wdata,
        output wire [  RAM_STRB_WIDTH-1:0] ram_axi_wstrb,
        output wire                        ram_axi_wlast,
        output wire                        ram_axi_wvalid,
        input  wire                        ram_axi_wready,
        input  wire [    RAM_ID_WIDTH-1:0] ram_axi_bid,
        input  wire [                 1:0] ram_axi_bresp,
        input  wire                        ram_axi_bvalid,
        output wire                        ram_axi_bready,
        output wire [    RAM_ID_WIDTH-1:0] ram_axi_arid,
        output wire [  RAM_ADDR_WIDTH-1:0] ram_axi_araddr,
        output wire [                 7:0] ram_axi_arlen,
        output wire [                 2:0] ram_axi_arsize,
        output wire [                 1:0] ram_axi_arburst,
        output wire                        ram_axi_arlock,
        output wire [                 3:0] ram_axi_arcache,
        output wire [                 2:0] ram_axi_arprot,
        output wire                        ram_axi_arvalid,
        input  wire                        ram_axi_arready,
        input  wire [    RAM_ID_WIDTH-1:0] ram_axi_rid,
        input  wire [  RAM_DATA_WIDTH-1:0] ram_axi_rdata,
        input  wire [                 1:0] ram_axi_rresp,
        input  wire                        ram_axi_rlast,
        input  wire                        ram_axi_rvalid,
        output wire                        ram_axi_rready
    );

    /////////////////////////////////////////////////////////////
    // Maximum number of bytes to transfer in each data transfer,
    // or beat, in a burst
    /////////////////////////////////////////////////////////////
    function [2:0] sizedec;
        input integer width;
        begin
            case (width)
                1: sizedec = 3'h0;
                2: sizedec = 3'h1;
                4: sizedec = 3'h2;
                8: sizedec = 3'h3;
                16: sizedec = 3'h4;
                32: sizedec = 3'h5;
                64: sizedec = 3'h6;
                128: sizedec = 3'h7;
            endcase
        end
    endfunction

    logic awc_winc;
    logic awc_full;
    logic awc_rinc;
    logic awc_empty;

    logic dwc_winc;
    logic dwc_full;
    logic dwc_rinc;
    logic dwc_empty;

    assign mem_ready = ~awc_full & ~dwc_full;
    assign awc_winc = mem_valid & mem_wr & mem_ready;
    assign dwc_winc = awc_winc;

    async_fifo #(
    .ASIZE  (4),
    .DSIZE  (RAM_ADDR_WIDTH)
    ) address_channel (
    .wclk    (aclk          ),
    .wrst_n  (aresetn       ),
    .winc    (awc_winc      ),
    .wdata   (mem_addr      ),
    .wfull   (awc_full      ),
    .awfull  (              ),
    .rclk    (aclk          ),
    .rrst_n  (aresetn       ),
    .rinc    (awc_rinc      ),
    .rdata   (ram_axi_awaddr),
    .rempty  (awc_empty     ),
    .arempty (              )
    );

    assign awc_rinc = ram_axi_awready & ~awc_empty;

    async_fifo #(
    .ASIZE  (4),
    .DSIZE  (RAM_DATA_WIDTH)
    ) data_channel (
    .wclk    (aclk          ),
    .wrst_n  (aresetn       ),
    .winc    (dwc_winc      ),
    .wdata   (mem_wr_data   ),
    .wfull   (dwc_full      ),
    .awfull  (              ),
    .rclk    (aclk          ),
    .rrst_n  (aresetn       ),
    .rinc    (dwc_rinc      ),
    .rdata   (ram_axi_wdata ),
    .rempty  (dwc_empty     ),
    .arempty (              )
    );

    assign dwc_rinc = ram_axi_wready & ~dwc_empty;

    assign mem_rd_valid = 1'b0;
    assign mem_rd_data = {RAM_DATA_WIDTH{1'b0}};

    assign ram_axi_awid = {RAM_ID_WIDTH{1'b0}};
    // assign ram_axi_awaddr = {RAM_ADDR_WIDTH{1'b0}};
    assign ram_axi_awlen = 8'b0;
    assign ram_axi_awsize = sizedec(RAM_DATA_WIDTH);
    assign ram_axi_awburst = 2'b1;
    assign ram_axi_awlock = 1'b0;
    assign ram_axi_awcache = 4'b0;
    assign ram_axi_awprot = 3'b0;
    assign ram_axi_awvalid = ~awc_empty;
    // assign ram_axi_wdata = {RAM_DATA_WIDTH{1'b0}};
    assign ram_axi_wstrb = {RAM_STRB_WIDTH{1'b1}};
    assign ram_axi_wlast = 1'b1;
    assign ram_axi_wvalid = ~dwc_empty;
    assign ram_axi_bready = aresetn;


    assign ram_axi_arid = {RAM_ID_WIDTH{1'b0}};
    assign ram_axi_araddr = {RAM_ADDR_WIDTH{1'b0}};
    assign ram_axi_arlen = 8'b0;
    assign ram_axi_arsize = sizedec(RAM_DATA_WIDTH);
    assign ram_axi_arburst = 2'b1;
    assign ram_axi_arlock = 1'b0;
    assign ram_axi_arcache = 4'b0;
    assign ram_axi_arprot = 3'b0;
    assign ram_axi_arvalid = 1'b0;
    assign ram_axi_rready = 1'b0;

endmodule

`resetall
