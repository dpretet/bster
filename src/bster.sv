// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 100 ps
`default_nettype none

module bster

    #(
        // Addr Width in bits for Control/Status Register interface
        parameter CSR_ADDR_WIDTH = 3,
        // Data Width in bits for Control/Status Register interface
        parameter CSR_DATA_WIDTH = 32,
        // Command width in bits for command and completion interface
        parameter CMD_WIDTH = 128,
        // Status width in bits for status interface
        parameter STS_WIDTH = 8,
        // Width of data bus in bits
        parameter RAM_DATA_WIDTH = 32,
        // Width of address bus in bits
        parameter RAM_ADDR_WIDTH = 16,
        // Width of wstrb (width of data bus in words)
        parameter RAM_STRB_WIDTH = (DATA_WIDTH/8),
        // Width of ID signal
        parameter RAM_ID_WIDTH = 8
    )(
        // Clock and reset interface to source the core
        input  wire                        aclk,
        input  wire                        aresetn,
        // AXI4-lite interface for Control/Status Registers
        input  wire                        awvalid,
        output wire                        awready,
        input  wire [  CSR_ADDR_WIDTH-1:0] awaddr,
        input  wire [               2-1:0] awprot,
        input  wire                        wvalid,
        output wire                        wready,
        input  wire [  CSR_DATA_WIDTH-1:0] wdata,
        input  wire [CSR_DATA_WIDTH/8-1:0] wstrb,
        output wire                        bvalid,
        input  wire                        bready,
        output wire [               2-1:0] bresp,
        input  wire                        arvalid,
        output wire                        arready,
        input  wire [  CSR_ADDR_WIDTH-1:0] araddr,
        input  wire [               2-1:0] arprot,
        output wire                        rvalid,
        input  wire                        rready,
        output wire [  CSR_DATA_WIDTH-1:0] rdata,
        output wire [               2-1:0] rresp,
        // AXI4-Stream slave interface to receive commands
        input  wire                        cmd_tvalid,
        output wire                        cmd_tready,
        input  wire [       CMD_WIDTH-1:0] cmd_tdata,
        // AXI4-Stream master interface to return completion payload
        output wire                        cpl_tvalid,
        input  wire                        cpl_tready,
        output wire [       CMD_WIDTH-1:0] cpl_tdata,
        // AXI4-Stream master interface to return completion status
        output wire                        sts_tvalid,
        input  wire                        sts_tready,
        output wire [       STS_WIDTH-1:0] sts_tdata,
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

    assign awready = 1'b0;
    assign wready = 1'b0;
    assign bvalid = 1'b0;
    assign bresp = 2'b0;
    assign arready = 1'b0;
    assign rvalid = 1'b0;
    assign rdata = {CSR_DATA_WIDTH{1'b0}};
    assign rresp = 1'b0;

    assign ram_axi_awid = {RAM_ID_WIDTH{1'b0}};
    assign ram_axi_awaddr = {RAM_ADDR_WIDTH{1'b0}};
    assign ram_axi_awlen = 8'b0;
    assign ram_axi_awsize = 3'b0;
    assign ram_axi_awburst = 2'b0;
    assign ram_axi_awlock = 1'b0;
    assign ram_axi_awcache = 4'b0;
    assign ram_axi_awprot = 3'b0;
    assign ram_axi_awvalid = 1'b0;
    assign ram_axi_wdata = {RAM_DATA_WIDTH{1'b0}};
    assign ram_axi_wstrb = {RAM_STRB_WIDTH{1'b0}};
    assign ram_axi_wlast = 1'b0;
    assign ram_axi_wvalid = 1'b0;
    assign ram_axi_bready = 1'b0;
    assign ram_axi_arid = {RAM_ID_WIDTH{1'b0}};
    assign ram_axi_araddr = {RAM_ADDR_WIDTH{1'b0}};
    assign ram_axi_arlen = 8'b0;
    assign ram_axi_arsize = 3'b0;
    assign ram_axi_arburst = 2'b0;
    assign ram_axi_arlock = 1'b0;
    assign ram_axi_arcache = 4'b0;
    assign ram_axi_arprot = 3'b0;
    assign ram_axi_arvalid = 1'b0;
    assign ram_axi_rready = 1'b0;

endmodule

`resetall
