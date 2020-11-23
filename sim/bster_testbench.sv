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
    reg                         awvalid;
    wire                        awready;
    reg  [  CSR_ADDR_WIDTH-1:0] awaddr;
    reg  [               2-1:0] awprot;
    reg                         wvalid;
    wire                        wready;
    reg  [  CSR_DATA_WIDTH-1:0] wdata;
    reg  [CSR_DATA_WIDTH/8-1:0] wstrb;
    wire                        bvalid;
    reg                         bready;
    wire [               2-1:0] bresp;
    reg                         arvalid;
    wire                        arready;
    reg  [  CSR_ADDR_WIDTH-1:0] araddr;
    reg  [               2-1:0] arprot;
    wire                        rvalid;
    reg                         rready;
    wire [  CSR_DATA_WIDTH-1:0] rdata;
    wire [               2-1:0] rresp;
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

    // Tasks to inject commands and sink completions/status
    `include "bster_tasks.sv"

    function print_parameters();
    begin
        $display("Core Parameters Setup:");
        $display("  - TOKEN_WIDTH    = %0d", TOKEN_WIDTH);
        $display("  - PAYLOAD_WIDTH  = %0d", PAYLOAD_WIDTH);
        $display("  - CSR_ADDR_WIDTH = %0d", CSR_ADDR_WIDTH);
        $display("  - CSR_DATA_WIDTH = %0d", CSR_DATA_WIDTH);
        $display("  - AXI4S_WIDTH    = %0d", AXI4S_WIDTH);
        $display("  - RAM_DATA_WIDTH = %0d", RAM_DATA_WIDTH);
        $display("  - RAM_ADDR_WIDTH = %0d", RAM_ADDR_WIDTH);
        $display("  - RAM_STRB_WIDTH = %0d", (RAM_DATA_WIDTH/8));
        $display("  - RAM_ID_WIDTH   = %0d", RAM_ID_WIDTH);
    end
    endfunction


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
    awvalid,
    awready,
    awaddr,
    awprot,
    wvalid,
    wready,
    wdata,
    wstrb,
    bvalid,
    bready,
    bresp,
    arvalid,
    arready,
    araddr,
    arprot,
    rvalid,
    rready,
    rdata,
    rresp,
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
        $dumpfile("bster_testbench.vcd");
        $dumpvars(0, bster_testbench);
    end

    task setup(msg="Initialize core's IOs");
    begin
        // print_parameters();
        aresetn = 0;
        awvalid = 0;
        awaddr = 0;
        awprot = 0;
        wvalid = 0;
        wdata = 0;
        wstrb = 0;
        bready = 0;
        arvalid = 0;
        araddr = 0;
        arprot = 0;
        rready = 0;
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
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("BSTer Testsuite")

    ///    Available macros:"
    ///
    ///    - `INFO("message"):      Print a grey message
    ///    - `SUCCESS("message"):   Print a green message
    ///    - `WARNING("message"):   Print an orange message and increment warning counter
    ///    - `CRITICAL("message"):  Print an pink message and increment critical counter
    ///    - `ERROR("message"):     Print a red message and increment error counter
    ///
    ///    - `FAIL_IF(aSignal):                 Increment error counter if evaluaton is true
    ///    - `FAIL_IF_NOT(aSignal):             Increment error coutner if evaluation is false
    ///    - `FAIL_IF_EQUAL(aSignal, 23):       Increment error counter if evaluation is equal
    ///    - `FAIL_IF_NOT_EQUAL(aSignal, 45):   Increment error counter if evaluation is not equal
    ///    - `ASSERT(aSignal):                  Increment error counter if evaluation is not true
    ///    - `ASSERT((aSignal == 0)):           Increment error counter if evaluation is not true
    ///
    ///    Available flag:
    ///
    ///    - `LAST_STATUS: tied to 1 is last macro did experience a failure, else tied to 0

    `UNIT_TEST("IDLE CHECK")

        `MSG("Check BSTer core is properly IDLE during and after reset");

        @(negedge aclk);
        aresetn = 0;
        @(posedge aclk);

        `MSG("Check IDLE under reset");

        `ASSERT(awready == 1'b0, "awready");
        `ASSERT(wready == 1'b0, "wready");
        `ASSERT(bvalid == 1'b0, "bvalid");
        `ASSERT(bresp == 2'b0, "bresp");
        `ASSERT(arready == 1'b0, "arready");
        `ASSERT(rvalid == 1'b0, "rvalid");
        `ASSERT(rdata == {CSR_DATA_WIDTH{1'b0}}, "rdata");
        `ASSERT(rresp == 1'b0, "rresp");

        // `ASSERT(cmd_tready == 1'b0, "");
        `ASSERT(cpl_tvalid == 1'b0, "tvalid");
        `ASSERT(cpl_tdata == {AXI4S_WIDTH{1'b0}}, "tdata");

        `ASSERT(ram_axi_awid == {RAM_ID_WIDTH{1'b0}}, "awid");
        // `ASSERT(ram_axi_awaddr == {RAM_ADDR_WIDTH{1'b0}}, "awaddr");
        // `ASSERT(ram_axi_awlen == 8'b0, "awlen");
        `ASSERT(ram_axi_awsize == sizedec(RAM_DATA_WIDTH), "awsier");
        `ASSERT(ram_axi_awburst == 2'b1, "awburst");
        `ASSERT(ram_axi_awlock == 1'b0, "awlock");
        `ASSERT(ram_axi_awcache == 4'b0, "awcache");
        `ASSERT(ram_axi_awprot == 3'b0, "awprot");
        `ASSERT(ram_axi_awvalid == 1'b0, "awvalid");
        // `ASSERT(ram_axi_wdata == {RAM_DATA_WIDTH{1'b0}}, "wdata");
        // `ASSERT(ram_axi_wstrb == {RAM_STRB_WIDTH{1'b0}}, "wstrb");
        // `ASSERT(ram_axi_wlast == 1'b0, "wlast");
        `ASSERT(ram_axi_wvalid == 1'b0, "wvalid");
        // `ASSERT(ram_axi_bready == 1'b0, "bready");
        `ASSERT(ram_axi_arid == {RAM_ID_WIDTH{1'b0}}, "arid");
        // `ASSERT(ram_axi_araddr == {RAM_ADDR_WIDTH{1'b0}}, "araddr");
        // `ASSERT(ram_axi_arlen == 8'b0, "arlen");
        `ASSERT(ram_axi_arsize == sizedec(RAM_DATA_WIDTH), "arsize");
        `ASSERT(ram_axi_arburst == 2'b1, "arburst");
        `ASSERT(ram_axi_arlock == 1'b0, "arlock");
        `ASSERT(ram_axi_arcache == 4'b0, "arcache");
        `ASSERT(ram_axi_arprot == 3'b0, "arprot");
        `ASSERT(ram_axi_arvalid == 1'b0, "arvalid");
        `ASSERT(ram_axi_rready == 1'b0, "rready");

        #10;
        @(negedge aclk);
        aresetn = 1;
        @(posedge aclk);
        @(posedge aclk);

        `MSG("Check IDLE after reset release");

        `ASSERT(awready == 1'b1, "awready");
        `ASSERT(wready == 1'b1, "wready");
        `ASSERT(bvalid == 1'b0, "bvalid");
        `ASSERT(bresp == 2'b0, "bresp");
        `ASSERT(arready == 1'b1, "arready");
        `ASSERT(rvalid == 1'b0, "rvalid");
        `ASSERT(rdata == {CSR_DATA_WIDTH{1'b0}}, "rdata");
        `ASSERT(rresp == 1'b0, "rresp");

        `ASSERT(cmd_tready == 1'b1, "tready");
        `ASSERT(cpl_tvalid == 1'b0, "tvalid");
        `ASSERT(cpl_tdata == 0, "tdata");

        `ASSERT(ram_axi_awid == {RAM_ID_WIDTH{1'b0}}, "awid");
        // `ASSERT(ram_axi_awaddr == {RAM_ADDR_WIDTH{1'b0}}, "awaddrc");
        // `ASSERT(ram_axi_awlen == 8'b0, "awlen");
        `ASSERT(ram_axi_awsize == sizedec(RAM_DATA_WIDTH), "awsize");
        `ASSERT(ram_axi_awburst == 2'b1, "awburst");
        `ASSERT(ram_axi_awlock == 1'b0, "awlock");
        `ASSERT(ram_axi_awcache == 4'b0, "awcache");
        `ASSERT(ram_axi_awprot == 3'b0, "awprot");
        `ASSERT(ram_axi_awvalid == 1'b0, "awalid");
        // `ASSERT(ram_axi_wdata == {RAM_DATA_WIDTH{1'b0}}, "wdata");
        // `ASSERT(ram_axi_wstrb == {RAM_STRB_WIDTH{1'b0}}, "wstrb");
        // `ASSERT(ram_axi_wlast == 1'b0, "wlast");
        `ASSERT(ram_axi_wvalid == 1'b0, "wvalid");
        // `ASSERT(ram_axi_bready == 1'b0, "bready");
        `ASSERT(ram_axi_arid == {RAM_ID_WIDTH{1'b0}}, "arid");
        // `ASSERT(ram_axi_araddr == {RAM_ADDR_WIDTH{1'b0}}, "araddr");
        // `ASSERT(ram_axi_arlen == 8'b0, "arlen");
        `ASSERT(ram_axi_arsize == sizedec(RAM_DATA_WIDTH), "arsize");
        `ASSERT(ram_axi_arburst == 2'b1, "arburst");
        `ASSERT(ram_axi_arlock == 1'b0, "arlock");
        `ASSERT(ram_axi_arcache == 4'b0, "arcache");
        `ASSERT(ram_axi_arprot == 3'b0, "arprot");
        `ASSERT(ram_axi_arvalid == 1'b0, "arvalid");
        // `ASSERT(ram_axi_rready == 1'b0, "rready");

    `UNIT_TEST_END

    `UNIT_TEST("Try to issue a command after reset")

        `MSG("Give a try to issue an insert command");
        command(`INSERT_TOKEN, 0, 0);

    `UNIT_TEST_END

    `UNIT_TEST("Insert root token into tree")

        token = $urandom() % 32;
        command(`INSERT_TOKEN, 12, 24);

    `UNIT_TEST_END

    `UNIT_TEST("Insert tokens into tree")

        for (int i = 1; i <= 8; i=i+1) begin
            data = $urandom() % 4096;
            command(`INSERT_TOKEN, i, data);
        end

    `UNIT_TEST_END

    `UNIT_TEST("Search into a NULL tree")

        for (int i = 1; i <= 8; i=i+1) begin
            data = $urandom() % 4096;
            command(`SEARCH_TOKEN, i, data);
            completion(cpl);
            `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1, 
                    "expect an error because the tree is not initialized");
        end

    `UNIT_TEST_END

    `UNIT_TEST("Insert token then read them")

        for (int i = 1; i <= 8; i=i+1) begin
            data = $urandom() % 4096;
            command(`INSERT_TOKEN, i, data);
            command(`SEARCH_TOKEN, i, 0);
            completion(cpl);
            `ASSERT(cpl[PAYLOAD_WIDTH-1:0] == data, 
                    "read data is not written data");
            `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0, 
                    "don't expect an error status");
        end

    `UNIT_TEST_END

    `UNIT_TEST("Insert tokens then try to search a value not stored")

        for (int i = 1; i <= 8; i=i+1) begin
            data = $urandom() % 4096;
            command(`INSERT_TOKEN, i, data);
        end
        command(`SEARCH_TOKEN, 0, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1, 
                "expect an error while we search for a value not stored");

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
