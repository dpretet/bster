// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module interface_handler

    #(
        // Define the token width
        parameter TOKEN_WIDTH = 8,
        // Define the payload width
        parameter PAYLOAD_WIDTH = 32,
        // Command width in bits for command and completion interface
        parameter AXI4S_WIDTH = 128
    )(
        input  wire                        aclk,
        input  wire                        aresetn,
        // AXI4-Stream slave interface to receive commands
        input  wire                        cmd_tvalid,
        output wire                        cmd_tready,
        input  wire [     AXI4S_WIDTH-1:0] cmd_tdata,
        // AXI4-Stream master interface to return completion
        output wire                        cpl_tvalid,
        input  wire                        cpl_tready,
        output wire [     AXI4S_WIDTH-1:0] cpl_tdata,
        // Command interface
        output wire                        itf_valid,
        input  wire                        itf_ready,
        output wire [                 7:0] itf_cmd ,
        output wire [     TOKEN_WIDTH-1:0] itf_token,
        output wire [   PAYLOAD_WIDTH-1:0] itf_data
    );

    // Extract command and payload
    assign itf_valid = cmd_tvalid;
    assign itf_cmd = cmd_tdata[AXI4S_WIDTH-1-8+:8];
    assign itf_token = cmd_tdata[0+:TOKEN_WIDTH];
    assign itf_data = cmd_tdata[TOKEN_WIDTH+:PAYLOAD_WIDTH];

    // Enable the interface when out of reset
    assign cmd_tready = itf_ready;

    // Drive completion interface
    assign cpl_tvalid = 1'b0;
    assign cpl_tdata = {AXI4S_WIDTH{1'b0}};

    // TODO: Manage un known command
    // and drive back an unsupported status

endmodule

`resetall
