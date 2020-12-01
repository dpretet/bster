// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "bster_h.sv"

// Engine managing the user request to operate over the tree. Rely on
// memory driver to access the AXI4 RAM and tree space manager to get and free
// address

module search_engine

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
        parameter RAM_STRB_WIDTH = (RAM_DATA_WIDTH/8),
        // Width of ID signal
        parameter RAM_ID_WIDTH = 8
    )(
        input  wire                        aclk,
        input  wire                        aresetn,
        output wire [      `FSM_WIDTH-1:0] fsm_state,
        input  wire                        tree_ready,
        input  wire                        engine_ready,
        // Command interface
        input  wire                        req_valid,
        output wire                        req_ready,
        input  wire [                 7:0] req_cmd,
        input  wire [     TOKEN_WIDTH-1:0] req_token,
        input  wire [   PAYLOAD_WIDTH-1:0] req_data,
        // Completion interface
        output wire                        cpl_valid,
        input  wire                        cpl_ready,
        output reg  [   PAYLOAD_WIDTH-1:0] cpl_data,
        output reg                         cpl_status,
        // serves a search for other engines
        input  wire                        search_valid,
        output wire                        search_ready,
        input  wire [                 7:0] search_cmd,
        input  wire [     TOKEN_WIDTH-1:0] search_token,
        output reg  [  RAM_ADDR_WIDTH-1:0] search_cpl_addr,
        output wire                        search_cpl_valid,
        output wire                        search_cpl_status,
        // Memory driver
        output wire                        mem_valid,
        input  wire                        mem_ready,
        output wire                        mem_rd,
        output wire                        mem_wr,
        output wire [  RAM_ADDR_WIDTH-1:0] mem_addr,
        output wire [  RAM_DATA_WIDTH-1:0] mem_wr_data,
        input  wire                        mem_rd_valid,
        output wire                        mem_rd_ready,
        input  wire [  RAM_DATA_WIDTH-1:0] mem_rd_data
    );

    // TODO: Get it from CSR or tree space manager
    localparam [RAM_ADDR_WIDTH-1:0] ROOT_ADDR = {RAM_ADDR_WIDTH{1'b0}};

    // Central controller of the engine
    engine_states fsm;
    // Store the previous state as stack for branching in a processor
    // to remember last operations. Usefull to avoid numerous "empty"
    // states to handle the FSM transitions and next operations
    engine_states fsm_stack;

    logic [   TOKEN_WIDTH-1:0] token_store;

    logic [RAM_ADDR_WIDTH-1:0] next_addr;

    logic [RAM_ADDR_WIDTH-1:0] addr;
    logic [RAM_DATA_WIDTH-1:0] rddata;

    logic [RAM_ADDR_WIDTH-1:0] cpl;

    logic                      status;
    logic                      internal_search;

    logic [ PAYLOAD_WIDTH-1:0] rdnode_payload;
    logic                      rdnode_has_right_child;
    logic                      rdnode_has_left_child;
    logic [RAM_ADDR_WIDTH-1:0] rdnode_right_child_addr;
    logic [RAM_ADDR_WIDTH-1:0] rdnode_left_child_addr;
    logic [RAM_ADDR_WIDTH-1:0] rdnode_parent_addr;
    logic [   TOKEN_WIDTH-1:0] rdnode_token;
    logic [             8-1:0] rdnode_info;
    // -------------------------------------------------------------------------
    // AXI4-stream interface issuing the commands and returning the completion
    // -------------------------------------------------------------------------

    // Accept a new command only if IDLE and out of reset
    assign req_ready = (fsm == IDLE && aresetn == 1'b1) ? 1'b1 : 1'b0;
    assign search_ready = req_ready;

    // Store commands' parameter and available address when activated
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            token_store <= {TOKEN_WIDTH{1'b0}};
        end else begin
            if (req_valid && req_ready) begin
                token_store <= req_token;
            end
            else if (search_valid && search_ready) begin
                token_store <= search_token;
            end
        end
    end

    assign cpl_valid = (fsm == REQ_COMPLETION && ~internal_search);
    assign search_cpl_valid = (fsm == REQ_COMPLETION && internal_search);

    assign cpl_status = status;
    assign search_cpl_status = status;

    // Inform the parent about its state for switching correctly interfaces
    // to memory and tree space manager
    assign fsm_state = fsm;

    // -------------------------------------------------------------------------
    // Data path to memory driver
    // -------------------------------------------------------------------------

    assign mem_valid = (fsm == RD_RAM);
    assign mem_wr = 1'b0;
    assign mem_rd = (fsm == RD_RAM);
    assign mem_addr = addr;
    assign mem_wr_data = {RAM_DATA_WIDTH{1'b0}};
    assign mem_rd_ready = (fsm == WAIT_RAM_CPL);

    // In charge of data storage coming from the RAM
    always @ (posedge aclk or negedge aresetn) begin
        if (~aresetn) begin
            rddata <= {RAM_DATA_WIDTH{1'b0}};
        end else begin
            if (mem_rd_valid && mem_rd_ready)
                rddata <= mem_rd_data;
        end
    end

    // Local split of the different node fields to read
    // easier the code and debug the waveform
    assign {rdnode_payload,
            rdnode_left_child_addr,
            rdnode_right_child_addr,
            rdnode_parent_addr,
            rdnode_token,
            rdnode_info
           } = rddata;

    assign rdnode_has_left_child = rdnode_info[1];
    assign rdnode_has_right_child = rdnode_info[0];

    // -------------------------------------------------------------------------
    // Main FSM managing the user requests
    // -------------------------------------------------------------------------

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            addr <= {RAM_ADDR_WIDTH{1'b0}};
            fsm <= IDLE;
            fsm_stack <= IDLE;
            cpl_data <= {PAYLOAD_WIDTH{1'b0}};
            status <= 1'b0;
            internal_search <= 1'b0;
        end else begin

            case (fsm)

                // IDLE state, waiting for user requests
                default: begin

                    fsm_stack <= IDLE;
                    status <= 1'b0;

                    // Serves as search engine for insert or delete
                    // engines.
                    if (search_valid) begin
                        addr <= ROOT_ADDR;
                        fsm <= RD_RAM;
                        fsm_stack <= SEARCH_TOKEN;
                        internal_search <= 1'b1;
                    end

                    // SEARCH_TOKEN instruction
                    else if (req_valid && 
                             req_cmd == `SEARCH_TOKEN && engine_ready) begin
                        // If root node is NULL, return an error
                        if (~tree_ready) begin
                            status <= 1'b1;
                            cpl <= {PAYLOAD_WIDTH{1'b0}};
                            fsm <= REQ_COMPLETION;
                        end
                        else begin
                            addr <= ROOT_ADDR;
                            fsm <= RD_RAM;
                            fsm_stack <= SEARCH_TOKEN;
                        end
                    end

                end

                // Search engine for insert token instruction
                SEARCH_SLOT: begin

                    // Is smaller than node's token
                    if (token_store <= rdnode_token) begin
                        // If has a left child, continue to search
                        // across its branch
                        if (rdnode_has_left_child) begin
                            addr <= rdnode_left_child_addr;
                            fsm <= RD_RAM;
                            fsm_stack <= SEARCH_SLOT;
                        end
                        // Else use this slot for the new token
                        else begin
                            // Bit1=1: place found, Bit0=0: on left child
                            fsm <= REQ_COMPLETION;
                        end
                    end
                    // Is bigger than node's token
                    else if (token_store > rdnode_token) begin
                        // If has a right child, continue to search
                        // across its branch
                        if (rdnode_has_right_child) begin
                            addr <= rdnode_right_child_addr;
                            fsm <= RD_RAM;
                            fsm_stack <= SEARCH_SLOT;
                        end
                        // Else use this slot for the new token
                        else begin
                            // Bit1=1: place found, Bit0=1: on right child
                            fsm <= REQ_COMPLETION;
                        end
                    end

                end

                // Search engine for user to get a token information.
                // IDLE state starts to search from root, we reach this state
                // after the first read.
                SEARCH_TOKEN: begin
                    // Here we found the token, then we return the payload
                    if (token_store == rdnode_token) begin
                        cpl_data <= rdnode_payload;
                        search_cpl_addr <= addr;
                        status <= 1'b0;
                        fsm <= REQ_COMPLETION;
                    end
                    // If not found, dive into the left branch stored
                    // into the left child if value is smaller than node
                    else if (token_store < rdnode_token) begin
                        // If no left child exists, return an error
                        if (~rdnode_has_left_child) begin
                            status <= 1'b1;
                            cpl <= {PAYLOAD_WIDTH{1'b0}};
                            fsm <= REQ_COMPLETION;
                        end
                        // Else read left child
                        else begin
                            addr <= rdnode_left_child_addr;
                            fsm <= RD_RAM;
                            fsm_stack <= SEARCH_TOKEN;
                        end
                    end
                    // If not found, dive into the right branch stored
                    // into the right child if value is smaller than node
                    else begin
                        // If no right child exists, return an error
                        if (~rdnode_has_right_child) begin
                            status <= 1'b1;
                            cpl <= {PAYLOAD_WIDTH{1'b0}};
                            fsm <= REQ_COMPLETION;
                        end
                        // Else read right child
                        else begin
                            addr <= rdnode_right_child_addr;
                            fsm <= RD_RAM;
                            fsm_stack <= SEARCH_TOKEN;
                        end
                    end
                end

                // Deliver completion of a search or delete request
                REQ_COMPLETION : begin

                    if (internal_search) begin
                        internal_search <= 1'b0;
                        fsm <= IDLE;
                    end
                    else if (cpl_ready)
                        fsm <= IDLE;
                end

                // Read stage handling node read
                RD_RAM: begin
                    if (mem_ready)
                        fsm <= WAIT_RAM_CPL;
                end

                // Once read, move to the state defined in the stack
                // by the operation which specified it
                WAIT_RAM_CPL: begin
                    if (mem_rd_valid)
                        fsm <= fsm_stack;
                end

            endcase
        end
    end

endmodule

`resetall
