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
        /// teardown() runs when a test ends
    end
    endtask

    `TEST_SUITE("BSTer Core Testsuite")

    `UNIT_TEST("IDLE CHECK")

        `MSG("Check BSTer core is properly IDLE during and after reset");

        @(negedge aclk);
        aresetn = 0;
        @(posedge aclk);

        `MSG("Check IDLE under reset");

        `ASSERT(pready == 1'b0, "pready");

        `ASSERT(cpl_tvalid == 1'b0, "tvalid");
        `ASSERT(cpl_tdata == {AXI4S_WIDTH{1'b0}}, "tdata");

        `ASSERT(ram_axi_awid == {RAM_ID_WIDTH{1'b0}}, "awid");
        `ASSERT(ram_axi_awsize == sizedec(RAM_DATA_WIDTH), "awsier");
        `ASSERT(ram_axi_awburst == 2'b1, "awburst");
        `ASSERT(ram_axi_awlock == 1'b0, "awlock");
        `ASSERT(ram_axi_awcache == 4'b0, "awcache");
        `ASSERT(ram_axi_awprot == 3'b0, "awprot");
        `ASSERT(ram_axi_awvalid == 1'b0, "awvalid");
        `ASSERT(ram_axi_wvalid == 1'b0, "wvalid");
        `ASSERT(ram_axi_arid == {RAM_ID_WIDTH{1'b0}}, "arid");
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

        `ASSERT(pready == 1'b0, "pready");

        `ASSERT(cmd_tready == 1'b1, "tready");
        `ASSERT(cpl_tvalid == 1'b0, "tvalid");
        `ASSERT(cpl_tdata == 0, "tdata");

        `ASSERT(ram_axi_awid == {RAM_ID_WIDTH{1'b0}}, "awid");
        `ASSERT(ram_axi_awsize == sizedec(RAM_DATA_WIDTH), "awsize");
        `ASSERT(ram_axi_awburst == 2'b1, "awburst");
        `ASSERT(ram_axi_awlock == 1'b0, "awlock");
        `ASSERT(ram_axi_awcache == 4'b0, "awcache");
        `ASSERT(ram_axi_awprot == 3'b0, "awprot");
        `ASSERT(ram_axi_awvalid == 1'b0, "awalid");
        `ASSERT(ram_axi_wvalid == 1'b0, "wvalid");
        `ASSERT(ram_axi_arid == {RAM_ID_WIDTH{1'b0}}, "arid");
        `ASSERT(ram_axi_arsize == sizedec(RAM_DATA_WIDTH), "arsize");
        `ASSERT(ram_axi_arburst == 2'b1, "arburst");
        `ASSERT(ram_axi_arlock == 1'b0, "arlock");
        `ASSERT(ram_axi_arcache == 4'b0, "arcache");
        `ASSERT(ram_axi_arprot == 3'b0, "arprot");
        `ASSERT(ram_axi_arvalid == 1'b0, "arvalid");

    `UNIT_TEST_END

    `UNIT_TEST("Try to issue a command after reset")

        `MSG("Give a try to issue an insert command");
        command(`INSERT_TOKEN, 0, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

    `UNIT_TEST_END

    `UNIT_TEST("Insert root token into tree")

        token = $urandom() % 32;
        command(`INSERT_TOKEN, 12, 24);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

    `UNIT_TEST_END

    `UNIT_TEST("Insert tokens into tree")

        for (int i = 1; i <= 8; i=i+1) begin
            data = $urandom() % 4096;
            command(`INSERT_TOKEN, i, data);
            completion(cpl);
            `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                    "don't expect an error status");
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
            completion(cpl);
            `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                    "don't expect an error status");
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
            completion(cpl);
            `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                    "don't expect an error status");
        end
        command(`SEARCH_TOKEN, 0, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1,
                "expect an error while we search for a value not stored");

    `UNIT_TEST_END

    `UNIT_TEST("Try to delete tokens in tree")

        for (int i = 1; i <= 8; i=i+1) begin
            command(`DELETE_TOKEN, i, 0);
            completion(cpl);
            `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1,
                    "expect an error because the tree is not initialized");
        end
    `UNIT_TEST_END

    `UNIT_TEST("Insert leaf tokens then delete them")

        // Insert first a root token
        command(`INSERT_TOKEN, 10, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

        command(`INSERT_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`DELETE_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`SEARCH_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1,
                "expect an error while we search for a value not stored");

        command(`INSERT_TOKEN, 14, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`DELETE_TOKEN, 14, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`SEARCH_TOKEN, 14, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1,
                "expect an error while we search for a value not stored");

        command(`INSERT_TOKEN, 8, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`DELETE_TOKEN, 8, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`SEARCH_TOKEN, 8, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1,
                "expect an error while we search for a value not stored");

        command(`INSERT_TOKEN, 25, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`DELETE_TOKEN, 25, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`SEARCH_TOKEN, 25, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1,
                "expect an error while we search for a value not stored");

    `UNIT_TEST_END

    `UNIT_TEST("Insert tokens and delete a owning a single child")

        // Insert first a root token
        command(`INSERT_TOKEN, 10, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

        // Add a token, append a child then delete the token
        command(`INSERT_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`INSERT_TOKEN, 14, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

        // Delete the first layer, owning the leaf
        command(`DELETE_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

        // Then search the deleted token and the child
        command(`SEARCH_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1,
                "expect an error while we search for a deleted value ");
        command(`SEARCH_TOKEN, 14, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "Don't expect an error, this child must still available");

    `UNIT_TEST_END

    `UNIT_TEST("Insert tokens and delete a node owning two children")

        // Insert first a root token and a node with 2 children
        command(`INSERT_TOKEN, 10, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

        // insert a right branch to the root
        command(`INSERT_TOKEN, 12, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`INSERT_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`INSERT_TOKEN, 13, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

        // insert a left branch to the root
        command(`INSERT_TOKEN, 2, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`INSERT_TOKEN, 1, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`INSERT_TOKEN, 3, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

        // Delete the first layer, owning the two children
        command(`DELETE_TOKEN, 12, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status after deletion");
        command(`DELETE_TOKEN, 2, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status after deletion");

        // Then search the deleted token and the children
        command(`SEARCH_TOKEN, 12, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1,
                "Expect an error while this token has been deleted");
        command(`SEARCH_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "Don't expect an error while this child must be available");
        command(`SEARCH_TOKEN, 13, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "Don't expect an error while this child must be available");

        command(`SEARCH_TOKEN, 2, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b1,
                "Expect an error while this token has been deleted");
        command(`SEARCH_TOKEN, 1, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "Don't expect an error while this child must be available");
        command(`SEARCH_TOKEN, 3, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "Don't expect an error while this child must be available");

    `UNIT_TEST_END


    `UNIT_TEST("Create a tree then delete the root node")

        // Create a tree, add root and children and check children
        // are still here
        command(`INSERT_TOKEN, 10, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`INSERT_TOKEN, 12, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`INSERT_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");
        command(`INSERT_TOKEN, 13, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

        // Delete the root node
        command(`DELETE_TOKEN, 10, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "don't expect an error status");

        // Then search the children
        command(`SEARCH_TOKEN, 12, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "Don't expect an error while this child must be available");
        command(`SEARCH_TOKEN, 11, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "Don't expect an error while this child must be available");
        command(`SEARCH_TOKEN, 13, 0);
        completion(cpl);
        `ASSERT(cpl[AXI4S_WIDTH-1] == 1'b0,
                "Don't expect an error while this child must be available");
    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
