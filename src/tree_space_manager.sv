// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

module tree_space_manager

    #(
        // Width of address bus in bits
        parameter RAM_ADDR_WIDTH = 16
    )(
        input  wire                      aclk,
        input  wire                      aresetn,
        input  wire                      tree_mgt_req_valid,
        output wire                      tree_mgt_req_ready,
        output reg  [RAM_ADDR_WIDTH-1:0] tree_mgt_req_addr,
        input  wire                      tree_mgt_free_valid,
        output wire                      tree_mgt_free_ready,
        input  wire [RAM_ADDR_WIDTH-1:0] tree_mgt_free_addr,
        output wire                      tree_mgt_full
    );

    localparam [RAM_ADDR_WIDTH-1:0] ROOT_ADDR = {RAM_ADDR_WIDTH{1'b0}};

    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0)
            tree_mgt_req_addr <= ROOT_ADDR;
        else if (tree_mgt_req_valid == 1'b1)
            tree_mgt_req_addr <= tree_mgt_req_addr + 1'b1;
    end

    assign tree_mgt_req_ready = 1'b0;
    assign tree_mgt_free_ready = 1'b0;
    assign tree_mgt_full = 1'b0;

endmodule

`resetall
