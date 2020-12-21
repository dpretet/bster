// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "bster_h.sv"

module tree_space_manager

    #(
        // Width of address bus in bits
        parameter RAM_ADDR_WIDTH = 16
    )(
        input  wire                      aclk,
        input  wire                      aresetn,
        input  wire                      tree_mgt_req_valid,
        output wire                      tree_mgt_req_ready,
        output wire [RAM_ADDR_WIDTH-1:0] tree_mgt_req_addr,
        input  wire                      tree_mgt_free_valid,
        output wire                      tree_mgt_free_ready,
        input  wire [RAM_ADDR_WIDTH-1:0] tree_mgt_free_addr,
        input  wire [       `CTRL_W-1:0] csr_slv,
        output wire [     `STATUS_W-1:0] csr_mst
    );

    localparam [RAM_ADDR_WIDTH-1:0] ROOT_ADDR = {RAM_ADDR_WIDTH{1'b0}};

    reg  [RAM_ADDR_WIDTH-1:0] addr_counter;
    wire [RAM_ADDR_WIDTH-1:0] freed_addr;
    reg                       freed_addr_req;
    wire                      freed_addr_empty;
    wire                      freed_addr_full;
    wire                      end_of_addr;

    // This counter delivers address in the memory space when an engine
    // needs to insert a new node
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0)
            addr_counter <= ROOT_ADDR;
        else if (tree_mgt_req_valid && tree_mgt_req_ready &&
                     ~end_of_addr && freed_addr_empty)
            addr_counter <= addr_counter + 1'b1;
    end

    // Check address counter overflow
    assign end_of_addr = (addr_counter == {RAM_ADDR_WIDTH{1'b1}}) ? 1'b1 : 1'b0;

    // Tree manager is ready as long the counter is not about to overflow
    // or the scfifo is not empty
    assign tree_mgt_req_ready = (end_of_addr && freed_addr_empty) ? 1'b0 : 1'b1;

    // Agree to store an address to clear as long the FIFO is not full
    assign tree_mgt_free_ready = ~freed_addr_full;

    // Manage the storage of a node to free in the tree
    assign freed_addr_req = ~freed_addr_empty &&
                            tree_mgt_req_valid &&
                            tree_mgt_req_ready;

    // SC-FIFO to store an address to recycle in the tree
    scfifo
    #(
    .ADDR_WIDTH (RAM_ADDR_WIDTH),
    .DATA_WIDTH (RAM_ADDR_WIDTH)
    )
    freed_addr_inst
    (
    .aclk     (aclk                ),
    .aresetn  (aresetn             ),
    .data_in  (tree_mgt_free_addr  ),
    .push     (tree_mgt_free_valid ),
    .full     (freed_addr_full     ),
    .data_out (freed_addr          ),
    .pull     (freed_addr_req      ),
    .empty    (freed_addr_empty    )
    );

    // Deliver an address from the FIFO if is not empty, else use the counter
    assign tree_mgt_req_addr = (~freed_addr_empty) ? freed_addr : addr_counter;

endmodule

`resetall
