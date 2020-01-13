// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

// accounter monitors the write operations to store which master agent
// last accessed a memory row. when a read agent accesses a memory row,
// the accounter uses this information to control the multiplexer and
// choose the right memory bank.
// internally, the accounter uses ffds to store this information.

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
        parameter STS_WIDTH = 8
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
        input  wire [      DATA_WIDTH-1:0] wdata,
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
        output wire [       STS_WIDTH-1:0] sts_tdata
    );


endmodule

`resetall
