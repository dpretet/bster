// copyright damien pretet 2021
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
        input  wire                        tree_ready,
        // AXI4-Stream slave interface to receive commands
        input  wire                        cmd_tvalid,
        output wire                        cmd_tready,
        input  wire [     AXI4S_WIDTH-1:0] cmd_tdata,
        // AXI4-Stream master interface to return completion
        output wire                        cpl_tvalid,
        input  wire                        cpl_tready,
        output wire [     AXI4S_WIDTH-1:0] cpl_tdata,
        // Command interface to engine
        output wire                        req_valid,
        input  wire                        req_ready,
        output wire [                 7:0] req_cmd,
        output wire [     TOKEN_WIDTH-1:0] req_token,
        output wire [   PAYLOAD_WIDTH-1:0] req_data,
        // Completion interface from engine 
        input  wire                        cpl_valid,
        output wire                        cpl_ready,
        input  wire [   PAYLOAD_WIDTH-1:0] cpl_data,
        input  wire                        cpl_status
    );

    logic is_valid_req;
    logic ret_fail;
                          // Tree not filled and receives an insert command
    assign is_valid_req = (tree_ready == 1'b0 && req_cmd[7:4] == 4'h2) ? 1'b1 :
                          // Tree is filled and receives insert/search/delete
                          (tree_ready && (req_cmd[7:4] == 4'h1 || 
                                          req_cmd[7:4] == 4'h3 || 
                                          req_cmd[7:4] == 4'h2)) ? 1'b1 : 1'b0;

    // Extract command and payload
    assign req_valid = cmd_tvalid && is_valid_req;
    assign req_cmd = cmd_tdata[AXI4S_WIDTH-1-8+:8];
    assign req_token = cmd_tdata[0+:TOKEN_WIDTH];
    assign req_data = cmd_tdata[TOKEN_WIDTH+:PAYLOAD_WIDTH];

    // Enable the interface when out of reset
    assign cmd_tready = req_ready;

    // Store a failling return code to completion channel
    always @(posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            ret_fail <= 1'b0;
        end else if (cmd_tvalid && ~is_valid_req) begin
            ret_fail <= 1'b1;
        end else if (cpl_tready) begin
            ret_fail <= 1'b0;
        end
    end

    // Drive completion interface
    // Complete the request with bst engines completion or with fail flag
    // when request is not support
    assign cpl_tvalid = cpl_valid || ret_fail;
    assign cpl_ready = cpl_tready;
    assign cpl_tdata = {cpl_status || ret_fail,
                        {AXI4S_WIDTH-1-PAYLOAD_WIDTH{1'b0}}, 
                        cpl_data};

    // TODO: Manage un known command
    // and drive back an unsupported status

endmodule

`resetall
