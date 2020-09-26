// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 100 ps
`default_nettype none

`include "bster_h.sv"

module bst_engine

    #(
        // Define the token width
        parameter TOKEN_WIDTH = 8,
        // Define the payload width
        parameter PAYLOAD_WIDTH = 32,
        // Width of data bus in bits
        parameter RAM_DATA_WIDTH = 32,
        // Width of address bus in bits
        parameter RAM_ADDR_WIDTH = 16,
        // Width of wstrb (width of data bus in words)
        parameter RAM_STRB_WIDTH = (DATA_WIDTH/8),
        // Width of ID signal
        parameter RAM_ID_WIDTH = 8
    )(
        input  wire                        aclk,
        input  wire                        aresetn,
        // Command interface
        input  wire                        itf_valid,
        output wire                        itf_ready,
        input  wire [                 7:0] itf_cmd,
        input  wire [     TOKEN_WIDTH-1:0] itf_token,
        input  wire [   PAYLOAD_WIDTH-1:0] itf_data,
        // Tree manager access
        output wire                        tree_mgt_req_valid,
        input  wire                        tree_mgt_req_ready,
        input  wire [     TOKEN_WIDTH-1:0] tree_mgt_req_addr,
        output wire                        tree_mgt_free_valid,
        input  wire                        tree_mgt_free_ready,
        output wire [     TOKEN_WIDTH-1:0] tree_mgt_free_addr,
        input  wire                        tree_mgt_full,
        // Memory driver
        output wire                        mem_valid,
        input  wire                        mem_ready,
        output wire                        mem_rd,
        output wire                        mem_wr,
        output wire [  RAM_ADDR_WIDTH-1:0] mem_addr,
        output wire [  RAM_DATA_WIDTH-1:0] mem_wr_data,
        input  wire                        mem_rd_valid,
        input  wire [  RAM_DATA_WIDTH-1:0] mem_rd_data
    );

    localparam IDLE = 0,
               INSERT_TOKEN = 1,
               DELETE = 2,
               WAIT_WR_TO_RAM = 3;

    logic [3:0] fsm;
    logic [3:0] fsm_last;

    logic tree_ready;
    logic [              7:0] cmd_store;
    logic [  TOKEN_WIDTH-1:0] token_store;
    logic [PAYLOAD_WIDTH-1:0] data_store;

    logic [  TOKEN_WIDTH-1:0] next_addr;


    // -------------------------------------------------------------------------
    // Inputs from AXI4-stream interface issuing the commands
    // -------------------------------------------------------------------------

    // Accept a new command only if IDLE and out of reset
    assign itf_ready = ((fsm == IDLE || fsm_last == IDLE) &&
                            aresetn == 1'b1) ? 1'b1 : 1'b0;

    // Store commands' parameter and avaialble address when activated
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            cmd_store <= 8'b0;
            token_store <= {TOKEN_WIDTH{1'b0}};
            data_store <= {PAYLOAD_WIDTH{1'b0}};
            next_addr  <= {TOKEN_WIDTH{1'b0}};
        end else begin
            if (itf_valid && itf_ready) begin
                cmd_store <= itf_cmd;
                token_store <= itf_token;
                data_store <= itf_data;
            end
            if (itf_valid && itf_ready && ~tree_mgt_full) begin
                next_addr <= tree_mgt_req_addr;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Data path to memory driver
    // -------------------------------------------------------------------------

    assign mem_valid = (fsm == WAIT_WR_TO_RAM);
    assign mem_wr = (fsm == WAIT_WR_TO_RAM);
    assign mem_rd = 1'b0;
    assign mem_addr = next_addr;
    assign mem_wr_data = {  data_store,
                            {1'b0,1'b1,1'b0,1'b0,1'b0},
                            {RAM_ADDR_WIDTH{1'b0}},
                            {RAM_ADDR_WIDTH{1'b0}},
                            {RAM_ADDR_WIDTH{1'b0}},
                            token_store};

    // -------------------------------------------------------------------------
    // Memory requests to tree space manager
    // -------------------------------------------------------------------------

    assign tree_mgt_req_valid = (itf_valid && itf_cmd == `INSERT_TOKEN &&
                                 fsm == IDLE && ~tree_mgt_full);

    assign tree_mgt_free_valid = 1'b0;
    assign tree_mgt_free_addr = {TOKEN_WIDTH{1'b0}};

    // -------------------------------------------------------------------------
    // Main FSM managing the user requests
    // -------------------------------------------------------------------------

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            tree_ready <= 1'b0;
            fsm <= IDLE;
            fsm_last <= IDLE;
        end else begin

            fsm_last <= fsm;

            case (fsm)

                default: begin

                    if (itf_valid && itf_cmd == `INSERT_TOKEN &&
                            ~tree_mgt_full) begin
                        fsm <= INSERT_TOKEN;
                    end

                end

                INSERT_TOKEN: begin
                    // Indicate if the root node is already usable or not. If
                    // not, first token will become the root and initialize the
                    // tree. No need to search for its place
                    tree_ready <= 1'b1;

                    if (~tree_ready)
                        fsm <= WAIT_WR_TO_RAM;
                end

                WAIT_WR_TO_RAM: begin
                    if (mem_ready)
                        fsm <= IDLE;
                end

            endcase
        end
    end

endmodule

`resetall
