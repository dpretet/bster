// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`include "bster_h.sv"

`ifndef TIMEOUT
`define TIMEOUT 500
`endif

integer cmd_timer = 0;
integer sts_timer = 0;
integer cpl_timer = 0;

// Function used to inject BSTer command. Drives
// the AXI4-Stream command interface directly.
//
// Input:
//     - cmd: the BSTer command code
//     - token: the user token to store/search/delete
//       in the tree
//     - data: optional data associated to a token
//       if storing a value
//
// Return:
//     - None
//     - Support a timeout and drive an SVUT `ERROR
//
task command(
    input integer cmd,
    input [TOKEN_WIDTH-1:0] token,
    input [PAYLOAD_WIDTH-1:0] data=0
);

    `ifdef VERBOSE
        `MSG("Injecting a command");
    `endif

    @(posedge aclk);#0.01;
    cmd_tdata[AXI4S_WIDTH-1-8+:8] = cmd;
    cmd_tdata[0+:TOKEN_WIDTH] = token;
    cmd_tdata[TOKEN_WIDTH+:PAYLOAD_WIDTH] = data;
    cmd_tvalid = 1'b1;

    for (cmd_timer=0;cmd_timer<`TIMEOUT;cmd_timer=cmd_timer+1) begin
        // Break the loop if commmand is acknowledged
        if (cmd_tready)
            cmd_timer = `TIMEOUT+1;
        // Ensure we don't stay forever driving the interface
        if (cmd_timer == (`TIMEOUT-1))
            `ERROR("Reached timeout during command issue");
        @(posedge aclk);#0.01;
    end

    cmd_tvalid = 1'b0;

    `ifdef VERBOSE
        `MSG("Exiting command injection");
    `endif

endtask


// Function used to read back the BSTer command completion.
// Drives the AXI4-Stream completion interface directly.
//
// Input:
//     - None
//
// Return:
//     - the BSTer command's completion (status, payload)
//     - Support a timeout and drive an SVUT `ERROR
//
task completion(
    output [AXI4S_WIDTH-1:0] cpl
);

    @(posedge aclk);#0.01;

    for (cpl_timer=0;cpl_timer<`TIMEOUT;cpl_timer=cpl_timer+1) begin
        // Break the loop if commmand is acknowledged
        if (cpl_tvalid) begin
            cpl_tready = 1'b1;
            cpl = cpl_tdata;
            cpl_timer = `TIMEOUT+1;
        end
        // Ensure we don't stay forever driving the interface
        if (cpl_timer == (`TIMEOUT-1))
            `ERROR("Reached timeout when reading completion");
        @(posedge aclk);#0.01;
    end

    cpl_tready = 1'b0;

    `ifdef VERBOSE
        `MSG("Exiting completion read");
    `endif

endtask


task write_apb(
    input   [  CSR_ADDR_WIDTH-1:0] addr,
    input   [  CSR_DATA_WIDTH-1:0] wdata,
    input   [CSR_DATA_WIDTH/8-1:0] strb,
    output                         error
);
    integer temp;
    apb(1'b1, addr, wdata, strb, temp, error);
endtask

task read_apb(
    input   [  CSR_ADDR_WIDTH-1:0] addr,
    output  [  CSR_DATA_WIDTH-1:0] rdata,
    output                         error
);
    apb(1'b0, addr, 0, 0, rdata, error);
endtask

task apb(
    input                          mode,
    input   [  CSR_ADDR_WIDTH-1:0] addr,
    input   [  CSR_DATA_WIDTH-1:0] wdata,
    input   [CSR_DATA_WIDTH/8-1:0] strb,
    output  [  CSR_DATA_WIDTH-1:0] rdata,
    output                         error
);

    `ifdef VERBOSE
        `MSG("Accessing APB interface");
    `endif

    paddr = addr;
    pwdata = wdata;
    pstrb = strb;
    pwrite = mode;
    @(posedge aclk);#0.01;
    penable = 1'b1;

    for (cmd_timer=0;cmd_timer<`TIMEOUT;cmd_timer=cmd_timer+1) begin
        @(posedge aclk);
        // Break the loop if commmand is acknowledged
        if (pready) begin
            error = pslverr;
            rdata = prdata;
            cmd_timer = `TIMEOUT+1;
        end
        // Ensure we don't stay forever driving the interface
        if (cmd_timer == (`TIMEOUT-1))
            `ERROR("Reached timeout during command issue");
    end

    penable = 1'b0;

    `ifdef VERBOSE
        `MSG("Exiting APB accessing");
    `endif

endtask
