// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`include "bster_h.sv"

`timescale 1 ns / 1 ps

module bster_testbench();

    `SVUT_SETUP

    // Core parameters
    parameter TOKEN_WIDTH = 8;
    parameter PAYLOAD_WIDTH = 32;
    parameter CSR_ADDR_WIDTH = 8;
    parameter CSR_DATA_WIDTH = 32;
    parameter AXI4S_WIDTH = 128;
    parameter RAM_DATA_WIDTH = 128;
    parameter RAM_ADDR_WIDTH = 16;
    parameter RAM_STRB_WIDTH = (RAM_DATA_WIDTH/8);
    parameter RAM_ID_WIDTH = 8;

    // Clock / reset signals
    reg                         aclk;
    reg                         aresetn;
    // AXI4-lite CSR signals
    reg  [  CSR_ADDR_WIDTH-1:0] paddr;
    reg  [               2-1:0] pprot;
    reg                         penable;
    reg                         pwrite;
    wire                        pready;
    reg  [  CSR_DATA_WIDTH-1:0] pwdata;
    reg  [CSR_DATA_WIDTH/8-1:0] pstrb;
    wire [  CSR_DATA_WIDTH-1:0] prdata;
    wire                        pslverr;

    // AXI4-stream command signals
    reg                         cmd_tvalid;
    wire                        cmd_tready;
    reg  [     AXI4S_WIDTH-1:0] cmd_tdata;
    // AXI4-stream completion signals
    wire                        cpl_tvalid;
    reg                         cpl_tready;
    wire [     AXI4S_WIDTH-1:0] cpl_tdata;
    // AXI4 RAM signals
    wire [    RAM_ID_WIDTH-1:0] ram_axi_awid;
    wire [  RAM_ADDR_WIDTH-1:0] ram_axi_awaddr;
    wire [                 7:0] ram_axi_awlen;
    wire [                 2:0] ram_axi_awsize;
    wire [                 1:0] ram_axi_awburst;
    wire                        ram_axi_awlock;
    wire [                 3:0] ram_axi_awcache;
    wire [                 2:0] ram_axi_awprot;
    wire                        ram_axi_awvalid;
    wire                        ram_axi_awready;
    wire [  RAM_DATA_WIDTH-1:0] ram_axi_wdata;
    wire [  RAM_STRB_WIDTH-1:0] ram_axi_wstrb;
    wire                        ram_axi_wlast;
    wire                        ram_axi_wvalid;
    wire                        ram_axi_wready;
    wire [    RAM_ID_WIDTH-1:0] ram_axi_bid;
    wire [                 1:0] ram_axi_bresp;
    wire                        ram_axi_bvalid;
    wire                        ram_axi_bready;
    wire [    RAM_ID_WIDTH-1:0] ram_axi_arid;
    wire [  RAM_ADDR_WIDTH-1:0] ram_axi_araddr;
    wire [                 7:0] ram_axi_arlen;
    wire [                 2:0] ram_axi_arsize;
    wire [                 1:0] ram_axi_arburst;
    wire                        ram_axi_arlock;
    wire [                 3:0] ram_axi_arcache;
    wire [                 2:0] ram_axi_arprot;
    wire                        ram_axi_arvalid;
    wire                        ram_axi_arready;
    wire [    RAM_ID_WIDTH-1:0] ram_axi_rid;
    wire [  RAM_DATA_WIDTH-1:0] ram_axi_rdata;
    wire [                 1:0] ram_axi_rresp;
    wire                        ram_axi_rlast;
    wire                        ram_axi_rvalid;
    wire                        ram_axi_rready;

    // variables used into the testcases
    integer token;
    integer data;
    logic [AXI4S_WIDTH-1:0] cpl;
    logic error;
    integer addr;
    integer wdata;
    integer rdata;

    // Tasks to inject commands and sink completions/status
    `include "bster_tasks.sv"

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

    // BSTer core
    bster
    #(
    TOKEN_WIDTH,
    PAYLOAD_WIDTH,
    CSR_ADDR_WIDTH,
    CSR_DATA_WIDTH,
    AXI4S_WIDTH,
    RAM_DATA_WIDTH,
    RAM_ADDR_WIDTH,
    RAM_STRB_WIDTH,
    RAM_ID_WIDTH
    )
    dut
    (
    aclk,
    aresetn,
    paddr,
    pprot,
    penable,
    pwrite,
    pready,
    pwdata,
    pstrb,
    prdata,
    pslverr,
    cmd_tvalid,
    cmd_tready,
    cmd_tdata,
    cpl_tvalid,
    cpl_tready,
    cpl_tdata,
    ram_axi_awid,
    ram_axi_awaddr,
    ram_axi_awlen,
    ram_axi_awsize,
    ram_axi_awburst,
    ram_axi_awlock,
    ram_axi_awcache,
    ram_axi_awprot,
    ram_axi_awvalid,
    ram_axi_awready,
    ram_axi_wdata,
    ram_axi_wstrb,
    ram_axi_wlast,
    ram_axi_wvalid,
    ram_axi_wready,
    ram_axi_bid,
    ram_axi_bresp,
    ram_axi_bvalid,
    ram_axi_bready,
    ram_axi_arid,
    ram_axi_araddr,
    ram_axi_arlen,
    ram_axi_arsize,
    ram_axi_arburst,
    ram_axi_arlock,
    ram_axi_arcache,
    ram_axi_arprot,
    ram_axi_arvalid,
    ram_axi_arready,
    ram_axi_rid,
    ram_axi_rdata,
    ram_axi_rresp,
    ram_axi_rlast,
    ram_axi_rvalid,
    ram_axi_rready
    );

    // External AXI4 RAM storing the binary tree
    axi_ram
    #(
    RAM_DATA_WIDTH,
    RAM_ADDR_WIDTH,
    RAM_STRB_WIDTH,
    RAM_ID_WIDTH
    )
    ram
    (
    aclk,
    aresetn,
    ram_axi_awid,
    ram_axi_awaddr,
    ram_axi_awlen,
    ram_axi_awsize,
    ram_axi_awburst,
    ram_axi_awlock,
    ram_axi_awcache,
    ram_axi_awprot,
    ram_axi_awvalid,
    ram_axi_awready,
    ram_axi_wdata,
    ram_axi_wstrb,
    ram_axi_wlast,
    ram_axi_wvalid,
    ram_axi_wready,
    ram_axi_bid,
    ram_axi_bresp,
    ram_axi_bvalid,
    ram_axi_bready,
    ram_axi_arid,
    ram_axi_araddr,
    ram_axi_arlen,
    ram_axi_arsize,
    ram_axi_arburst,
    ram_axi_arlock,
    ram_axi_arcache,
    ram_axi_arprot,
    ram_axi_arvalid,
    ram_axi_arready,
    ram_axi_rid,
    ram_axi_rdata,
    ram_axi_rresp,
    ram_axi_rlast,
    ram_axi_rvalid,
    ram_axi_rready
    );

    initial aclk = 0;
    always #1 aclk <= ~aclk;

    initial begin : INIT_BLOCK
        $dumpfile("bster_testbench\.vcd");
        $dumpvars(0, bster_testbench);
    end

    task setup(msg="Initialize core's IOs");
    begin
        aresetn = 0;
        paddr = 0;
        pprot = 0;
        penable = 0;
        pwrite = 0;
        pwdata = 0;
        pstrb = 0;
        cmd_tvalid = 0;
        cmd_tdata = 0;
        cpl_tready = 0;
        #30;
        aresetn = 1;
        #30;
        @(posedge aclk);
    end
    endtask

    task teardown(msg="");
        #20;
    begin
    end
    endtask

    `TEST_SUITE("BSTer Core Testsuite")

    `UNIT_TEST("Write mailbox register with APB")

        `MSG("Write 0 and check we read back. Both ops must receive error=0");

        addr = `ADDR_MAILBOX;
        wdata = 0;

        write_apb(addr, wdata, 4'b1111, error);
        `ASSERT(error === 0, "Error code is not supposed to be 1 when writing mailbox");
        @(posedge aclk);

        read_apb(addr,rdata,error);
        `ASSERT(rdata===wdata, "Mailbox is supposed to be empty");
        `ASSERT(error === 0, "Error code is not supposed to be 1 when reading mailbox");
        @(posedge aclk);

        `MSG("Check STRB is correctly handled");

        addr = `ADDR_MAILBOX;
        wdata = 32'hCAFECACA;

        write_apb(addr, wdata, 4'b0111, error);
        `ASSERT(error === 0, "Error code is not supposed to be 1 when writing mailbox");
        @(posedge aclk);

        read_apb(addr, rdata, error);
        `ASSERT(rdata[31:24]==8'b0, "Mailbox is supposed to contain 0");
        `ASSERT(rdata[23:0]==wdata[23:0], "Mailbox is supposed to contain 0x00FECACA");
        `ASSERT(error === 0, "Error code is not supposed to be 1 when reading mailbox");
        @(posedge aclk);

        `MSG("Check STRB is correctly handled after a second write");
        addr = `ADDR_MAILBOX;
        wdata = 32'hFFFFFFFF;

        write_apb(addr, wdata, 4'b0101, error);
        `ASSERT(error === 0, "Error code is not supposed to be 1 when writing mailbox");
        @(posedge aclk);

        read_apb(addr, rdata, error);
        `ASSERT(rdata[31:24]==8'h00, "Mailbox is supposed to contain 0");
        `ASSERT(rdata[15:8]==8'hCA, "Mailbox is supposed to contain CA");
        `ASSERT(rdata[7:0]==8'hFF, "Mailbox is supposed to contain 0xFF");
        `ASSERT(rdata[23:16]==8'hFF, "Mailbox is supposed to contain 0xFF");
        `ASSERT(error === 0, "Error code is not supposed to be 1 when reading mailbox");
        @(posedge aclk);

    `UNIT_TEST_END;

    `UNIT_TEST("Write read-only registers with APB")

        `MSG("Write 0 and check we read back. Both ops must receive error=0");

        addr = `ADDR_CTRL;
        write_apb(addr, wdata, 4'b0001, error);
        `ASSERT(error === 0, "LSBs are supposed to be writable");
        @(posedge aclk);

        write_apb(addr, wdata, 4'b1110, error);
        `ASSERT(error === 1, "Error is supposed to be 1 when writing CTRL RO MSBs");
        @(posedge aclk);

        addr = `ADDR_STATUS;
        write_apb(addr, wdata, 4'b1111, error);
        `ASSERT(error === 1, "Error is supposed to be 1 when writing RO STATUS");
        @(posedge aclk);

        addr = `ADDR_OPCODES;
        write_apb(addr, wdata, 4'b1111, error);
        `ASSERT(error === 1, "Error is supposed to be 1 when writing RO OPCODES");
        @(posedge aclk);

    `UNIT_TEST_END;

    `TEST_SUITE_END

endmodule
