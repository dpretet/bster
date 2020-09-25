// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

/// Mandatory file to be able to launch SVUT flow
`include "svut_h.sv"
`include "bster_h.sv"

`timescale 1 ns / 100 ps

module bster_testbench();

    `SVUT_SETUP

    parameter CSR_ADDR_WIDTH = 3;
    parameter CSR_DATA_WIDTH = 32;
    parameter CMD_WIDTH = 128;
    parameter STS_WIDTH = 8;
    parameter RAM_DATA_WIDTH = 32;
    parameter RAM_ADDR_WIDTH = 16;
    parameter RAM_STRB_WIDTH = (RAM_DATA_WIDTH/8);
    parameter RAM_ID_WIDTH = 8;

    reg                         aclk;
    reg                         aresetn;

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

    reg                         cmd_tvalid;
    wire                        cmd_tready;
    reg  [       CMD_WIDTH-1:0] cmd_tdata;

    wire                        cpl_tvalid;
    reg                         cpl_tready;
    wire [       CMD_WIDTH-1:0] cpl_tdata;

    wire                        sts_tvalid;
    reg                         sts_tready;
    wire [       STS_WIDTH-1:0] sts_tdata;

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

    // Tasks to inject commands and sink completions/status
    `include "amba_tasks.sv"
    `include "bster_tasks.sv"

    // BSTer core
    bster
    #(
    CSR_ADDR_WIDTH,
    CSR_DATA_WIDTH,
    CMD_WIDTH,
    STS_WIDTH,
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
    sts_tvalid,
    sts_tready,
    sts_tdata,
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
    always #2 aclk <= ~aclk;

    initial begin : INIT_BLOCK
        $dumpfile("bster_testbench.vcd");
        $dumpvars(0, bster_testbench);
    end

    task setup(msg="Initialize core's IOs");
    begin
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
        sts_tready = 0;
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

        aresetn = 0;

        `MSG("Check IDLE under reset");

        `ASSERT(awready == 1'b0);
        `ASSERT(wready == 1'b0);
        `ASSERT(bvalid == 1'b0);
        `ASSERT(bresp == 2'b0);
        `ASSERT(arready == 1'b0);
        `ASSERT(rvalid == 1'b0);
        `ASSERT(rdata == {CSR_DATA_WIDTH{1'b0}});
        `ASSERT(rresp == 1'b0);
        `ASSERT(cmd_tready == 1'b0);
        `ASSERT(ram_axi_awid == {RAM_ID_WIDTH{1'b0}});
        `ASSERT(ram_axi_awaddr == {RAM_ADDR_WIDTH{1'b0}});
        `ASSERT(ram_axi_awlen == 8'b0);
        `ASSERT(ram_axi_awsize == 3'b0);
        `ASSERT(ram_axi_awburst == 2'b0);
        `ASSERT(ram_axi_awlock == 1'b0);
        `ASSERT(ram_axi_awcache == 4'b0);
        `ASSERT(ram_axi_awprot == 3'b0);
        `ASSERT(ram_axi_awvalid == 1'b0);
        `ASSERT(ram_axi_wdata == {RAM_DATA_WIDTH{1'b0}});
        `ASSERT(ram_axi_wstrb == {RAM_STRB_WIDTH{1'b0}});
        `ASSERT(ram_axi_wlast == 1'b0);
        `ASSERT(ram_axi_wvalid == 1'b0);
        `ASSERT(ram_axi_bready == 1'b0);
        `ASSERT(ram_axi_arid == {RAM_ID_WIDTH{1'b0}});
        `ASSERT(ram_axi_araddr == {RAM_ADDR_WIDTH{1'b0}});
        `ASSERT(ram_axi_arlen == 8'b0);
        `ASSERT(ram_axi_arsize == 3'b0);
        `ASSERT(ram_axi_arburst == 2'b0);
        `ASSERT(ram_axi_arlock == 1'b0);
        `ASSERT(ram_axi_arcache == 4'b0);
        `ASSERT(ram_axi_arprot == 3'b0);
        `ASSERT(ram_axi_arvalid == 1'b0);
        `ASSERT(ram_axi_rready == 1'b0);

        #10;
        aresetn = 1;
        #10;

        `MSG("Check IDLE after reset release");

        `ASSERT(awready == 1'b1);
        `ASSERT(wready == 1'b1);
        `ASSERT(bvalid == 1'b0);
        `ASSERT(bresp == 2'b0);
        `ASSERT(arready == 1'b1);
        `ASSERT(rvalid == 1'b0);
        `ASSERT(rdata == {CSR_DATA_WIDTH{1'b0}});
        `ASSERT(rresp == 1'b0);
        `ASSERT(cmd_tready == 1'b1);
        `ASSERT(ram_axi_awid == {RAM_ID_WIDTH{1'b0}});
        `ASSERT(ram_axi_awaddr == {RAM_ADDR_WIDTH{1'b0}});
        `ASSERT(ram_axi_awlen == 8'b0);
        `ASSERT(ram_axi_awsize == 3'b0);
        `ASSERT(ram_axi_awburst == 2'b0);
        `ASSERT(ram_axi_awlock == 1'b0);
        `ASSERT(ram_axi_awcache == 4'b0);
        `ASSERT(ram_axi_awprot == 3'b0);
        `ASSERT(ram_axi_awvalid == 1'b0);
        `ASSERT(ram_axi_wdata == {RAM_DATA_WIDTH{1'b0}});
        `ASSERT(ram_axi_wstrb == {RAM_STRB_WIDTH{1'b0}});
        `ASSERT(ram_axi_wlast == 1'b0);
        `ASSERT(ram_axi_wvalid == 1'b0);
        `ASSERT(ram_axi_bready == 1'b0);
        `ASSERT(ram_axi_arid == {RAM_ID_WIDTH{1'b0}});
        `ASSERT(ram_axi_araddr == {RAM_ADDR_WIDTH{1'b0}});
        `ASSERT(ram_axi_arlen == 8'b0);
        `ASSERT(ram_axi_arsize == 3'b0);
        `ASSERT(ram_axi_arburst == 2'b0);
        `ASSERT(ram_axi_arlock == 1'b0);
        `ASSERT(ram_axi_arcache == 4'b0);
        `ASSERT(ram_axi_arprot == 3'b0);
        `ASSERT(ram_axi_arvalid == 1'b0);
        `ASSERT(ram_axi_rready == 1'b0);

    `UNIT_TEST_END

    `UNIT_TEST("Try to issue some commands")

        `MSG("Give a try to issue an insert command");
        command(`INSERT_TOKEN, 0, 0);

    `UNIT_TEST_END

    `TEST_SUITE_END

endmodule
