// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "bster_h.sv"

// Engine managing the user request to operate over the tree. Rely on
// memory driver to access the AXI4 RAM and tree space manager to get and free
// address

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
        parameter RAM_STRB_WIDTH = (RAM_DATA_WIDTH/8),
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
        input  wire [  RAM_ADDR_WIDTH-1:0] tree_mgt_req_addr,
        output wire                        tree_mgt_free_valid,
        input  wire                        tree_mgt_free_ready,
        output wire [  RAM_ADDR_WIDTH-1:0] tree_mgt_free_addr,
        input  wire                        tree_mgt_full,
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

    typedef enum logic[3:0] {
                            IDLE = 0,
                            INSERT_TOKEN = 1,
                            WR_RAM = 2,
                            RD_RAM = 3,
                            WAIT_RAM_CPL = 4,
                            FIND_EMPTY_PLACE = 5
    } ctrlr_states;

    // Central controller of the engine
    ctrlr_states fsm;
    // Store the previous state as stack for branching in a processor
    // to remember last operations. Usefull to avoid numerous "empty"
    // states to handle the FSM transitions and next operations
    ctrlr_states fsm_stack;

    logic                      tree_ready;
    logic [   TOKEN_WIDTH-1:0] token_store;
    logic [ PAYLOAD_WIDTH-1:0] data_store;

    logic [RAM_ADDR_WIDTH-1:0] next_addr;

    logic [RAM_ADDR_WIDTH-1:0] addr;
    logic [RAM_ADDR_WIDTH-1:0] parent_addr;
    logic [RAM_DATA_WIDTH-1:0] wrdata;
    logic [RAM_DATA_WIDTH-1:0] rddata;

    logic [               1:0] place_found;
    logic                      update_parent;

    logic [ PAYLOAD_WIDTH-1:0] rdnode_payload;
    logic                      rdnode_has_right_child;
    logic                      rdnode_has_left_child;
    logic [RAM_ADDR_WIDTH-1:0] rdnode_right_child_addr;
    logic [RAM_ADDR_WIDTH-1:0] rdnode_left_child_addr;
    logic [RAM_ADDR_WIDTH-1:0] rdnode_parent_addr;
    logic [   TOKEN_WIDTH-1:0] rdnode_token;
    logic [             8-1:0] rdnode_info;
    // -------------------------------------------------------------------------
    // Inputs from AXI4-stream interface issuing the commands
    // -------------------------------------------------------------------------

    // Accept a new command only if IDLE and out of reset
    assign itf_ready = ((fsm == IDLE /*&& fsm_stack == IDLE*/) &&
                            aresetn == 1'b1) ? 1'b1 : 1'b0;

    // Store commands' parameter and available address when activated
    always @ (posedge aclk or negedge aresetn) begin
        if (aresetn == 1'b0) begin
            token_store <= {TOKEN_WIDTH{1'b0}};
            data_store <= {PAYLOAD_WIDTH{1'b0}};
            next_addr  <= {RAM_ADDR_WIDTH{1'b0}};
        end else begin
            if (itf_valid && itf_ready) begin
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

    assign mem_valid = (fsm == WR_RAM || fsm == RD_RAM);
    assign mem_wr = (fsm == WR_RAM);
    assign mem_rd = (fsm == RD_RAM);
    assign mem_addr = addr;
    assign mem_wr_data = wrdata;
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
    // easier the code and waveform
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
    // Memory requests to tree space manager
    // -------------------------------------------------------------------------

    assign tree_mgt_req_valid = (itf_valid && itf_cmd == `INSERT_TOKEN &&
                                 fsm == IDLE && ~tree_mgt_full);

    assign tree_mgt_free_valid = 1'b0;
    assign tree_mgt_free_addr = {RAM_ADDR_WIDTH{1'b0}};

    // -------------------------------------------------------------------------
    // Main FSM managing the user requests
    // -------------------------------------------------------------------------

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            addr <= {RAM_ADDR_WIDTH{1'b0}};
            parent_addr <= {RAM_ADDR_WIDTH{1'b0}};
            wrdata <= {RAM_DATA_WIDTH{1'b0}};
            tree_ready <= 1'b0;
            fsm <= IDLE;
            fsm_stack <= IDLE;
            place_found <= 2'b0;
            update_parent <= 1'b0;
        end else begin

            case (fsm)

                // IDLE state, waiting for user requests
                default: begin

                    fsm_stack <= IDLE;
                    update_parent <= 1'b0;
                    place_found <= 2'b0;
                    // Instruction 1: INSERT_TOKEN
                    if (itf_valid && itf_cmd == `INSERT_TOKEN &&
                            ~tree_mgt_full) begin
                        fsm <= INSERT_TOKEN;
                    end

                end

                // Central state to insert a new token
                INSERT_TOKEN: begin

                    // Tree is not yet ready, so first simply
                    // write the new value as the root node.
                    if (~tree_ready) begin

                        wrdata <= {data_store,             // data payload
                                   {RAM_ADDR_WIDTH{1'b0}}, // left child addr
                                   {RAM_ADDR_WIDTH{1'b0}}, // right child addr
                                   {RAM_ADDR_WIDTH{1'b0}}, // parent address
                                   token_store,            // token
                                   {
                                      5'b0,                // reserved
                                      1'b1,                // is root node
                                      1'b0,                // has left child
                                      1'b0                 // has right child
                                   }
                                  };

                        tree_ready <= 1'b1;
                        addr <= ROOT_ADDR;
                        update_parent <= 1'b0;
                        fsm <= WR_RAM;
                        fsm_stack <= IDLE;
                    end
                    // A place has been found to insert a new node, but it
                    // updates first the parent, thus avoid to read it
                    // again. New node will store in the next phase.
                    else if (update_parent && place_found[1]) begin

                        wrdata <= {rdnode_payload,
                                   (~place_found[0]) ? next_addr : rdnode_left_child_addr,
                                   (place_found[0]) ? next_addr : rdnode_right_child_addr,
                                   rdnode_parent_addr,
                                   rdnode_token,
                                   rdnode_info[7:2],
                                   (~place_found[0]) ? 1'b1 : rdnode_info[1],
                                   (place_found[0]) ? 1'b1 : rdnode_info[0]
                                  };

                        addr <= parent_addr;
                        update_parent <= 1'b0;
                        fsm <= WR_RAM;
                        fsm_stack <= INSERT_TOKEN;

                    end
                    // After parent has been updated by the new child info,
                    // write the child in the tree
                    else if (place_found[1]) begin

                        wrdata <= {data_store,
                                   {RAM_ADDR_WIDTH{1'b0}},
                                   {RAM_ADDR_WIDTH{1'b0}},
                                   parent_addr,
                                   token_store,
                                   8'b0
                                  };

                        addr <= next_addr;
                        update_parent <= 1'b0;
                        fsm <= WR_RAM;
                        fsm_stack <= IDLE;
                    end
                    // Start to dive into the tree, starting from the
                    // root node to find a place for the new token
                    else begin
                        addr <= ROOT_ADDR;
                        fsm <= RD_RAM;
                        fsm_stack <= FIND_EMPTY_PLACE;
                    end
                end

                // Search engine for insert token instruction
                FIND_EMPTY_PLACE: begin

                    // Is smaller than node's token
                    if (token_store <= rdnode_token) begin
                        // If has a left child, continue to search
                        // across its branch
                        if (rdnode_has_left_child) begin
                            addr <= rdnode_left_child_addr;
                            update_parent <= 1'b0;
                            place_found <= 2'b0;
                            fsm <= RD_RAM;
                            fsm_stack <= FIND_EMPTY_PLACE;
                        end
                        // Else use this slot for the new token
                        else begin
                            // Bit1=1: place found, Bit0=0: on left child
                            place_found <= 2'b10;
                            update_parent <= 1'b1;
                            parent_addr <= addr;
                            fsm <= INSERT_TOKEN;
                        end
                    end
                    // Is bigger than node's token
                    else if (token_store > rdnode_token) begin
                        // If has a right child, continue to search
                        // across its branch
                        if (rdnode_has_right_child) begin
                            addr <= rdnode_right_child_addr;
                            update_parent <= 1'b0;
                            place_found <= 2'b0;
                            fsm <= RD_RAM;
                            fsm_stack <= FIND_EMPTY_PLACE;
                        end
                        // Else use this slot for the new token
                        else begin
                            // Bit1=1: place found, Bit0=1: on right child
                            place_found <= 2'b11;
                            update_parent <= 1'b1;
                            parent_addr <= addr;
                            fsm <= INSERT_TOKEN;
                        end
                    end

                end

                // Write state to handle node storage
                // Once written, move to the state defined in the stack
                // by the operation which specified it
                WR_RAM: begin
                    if (mem_ready)
                        fsm <= fsm_stack;
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
