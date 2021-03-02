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
        input  wire                      swrst,
        input  wire                      tree_mgt_req_valid,
        output wire                      tree_mgt_req_ready,
        output wire [RAM_ADDR_WIDTH-1:0] tree_mgt_req_addr,
        input  wire                      tree_mgt_free_valid,
        input  wire                      tree_mgt_free_is_root,
        output wire                      tree_mgt_free_ready,
        input  wire [RAM_ADDR_WIDTH-1:0] tree_mgt_free_addr,
        input  wire [    `CSR_MST_W-1:0] csr_slv,
        output wire [        `TSM_W-1:0] csr_mst
    );

    logic [RAM_ADDR_WIDTH-1:0] addr_counter;
    logic [RAM_ADDR_WIDTH-1:0] freed_addr;
    logic                      freed_addr_req;
    logic                      freed_addr_empty;
    logic                      freed_addr_full;
    logic                      end_of_addr;
    logic                      store_freed_addr;
    logic                      root_freed;

    // This counter delivers address in the memory space when an engine
    // needs to insert a new node
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            addr_counter <= csr_slv[0+:RAM_ADDR_WIDTH];
        end
        else if (swrst) begin
            addr_counter <= csr_slv[0+:RAM_ADDR_WIDTH];
        end
        else if (tree_mgt_req_valid && tree_mgt_req_ready &&
                 ~end_of_addr && freed_addr_empty)
        begin
            addr_counter <= addr_counter + 1'b1;
        end
    end

    // Check address counter overflow
    assign end_of_addr = (addr_counter == 
                            csr_slv[`RAM_MAX_ADDRESS+:RAM_ADDR_WIDTH]) ? 
                          1'b1 : 1'b0;

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
    
    // Don't store root address if freed, previous circuit will reboot
    // the address space first with CSR setup
    assign store_freed_addr = tree_mgt_free_valid & ~tree_mgt_free_is_root;

    scfifo
    #(
    .ADDR_WIDTH (RAM_ADDR_WIDTH),
    .DATA_WIDTH (RAM_ADDR_WIDTH)
    )
    freed_addr_inst
    (
    .aclk     (aclk                ),
    .aresetn  (aresetn             ),
    .swrst    (swrst               ),
    .data_in  (tree_mgt_free_addr  ),
    .push     (store_freed_addr    ),
    .full     (freed_addr_full     ),
    .data_out (freed_addr          ),
    .pull     (freed_addr_req      ),
    .empty    (freed_addr_empty    )
    );

    // Flag to feed back the root address if the tree has been completely
    // deleted
    
    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            root_freed <= 1'b0;
        end
        else if (swrst) begin
            root_freed <= 1'b0;
        end 
        else begin
            if (tree_mgt_free_valid && tree_mgt_free_ready && 
                    tree_mgt_free_is_root) begin
                root_freed <= 1'b1;
            end 
            else if (tree_mgt_req_valid && tree_mgt_req_ready) begin
                root_freed <= 1'b0;
            end
        end
    end

    // Deliver an address from the FIFO if is not empty, else use the counter
    assign tree_mgt_req_addr = (root_freed) ?        csr_slv[0+:RAM_ADDR_WIDTH] :
                               (~freed_addr_empty) ? freed_addr : 
                                                     addr_counter;

    // Status moving back to CSR module to expose them to the host
    assign csr_mst = (end_of_addr & freed_addr_empty);

endmodule

`resetall
