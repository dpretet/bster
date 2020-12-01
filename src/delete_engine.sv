// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "bster_h.sv"

// Engine managing the user request to operate over the tree. Rely on
// memory driver to access the AXI4 RAM and tree space manager to get and free
// address

module delete_engine

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
        input  wire                        tree_ready,
        input  wire                        engine_ready,
        output wire [      `FSM_WIDTH-1:0] fsm_state,
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
        // request a search from dedicated engine
        output reg                         search_valid,
        input  wire                        search_ready,
        output reg  [                 7:0] search_cmd,
        output reg  [     TOKEN_WIDTH-1:0] search_token,
        input  wire [  RAM_ADDR_WIDTH-1:0] search_cpl_addr,
        input  wire                        search_cpl_valid,
        input  wire                        search_cpl_status,
        // request an insert from dedicated engine
        output reg                         insert_valid,
        input  wire                        insert_ready,
        output reg  [                 7:0] insert_cmd,
        output reg  [  RAM_DATA_WIDTH-1:0] insert_node,
        output reg  [  RAM_ADDR_WIDTH-1:0] insert_addr,
        input  wire                        insert_cpl_valid,
        output wire                        insert_cpl_ready,
        input  wire                        insert_cpl_status,
        // Tree manager access
        output wire                        tree_mgt_free_valid,
        input  wire                        tree_mgt_free_ready,
        output reg  [  RAM_ADDR_WIDTH-1:0] tree_mgt_free_addr,
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

    //-------------------------------------------
    // TODO: mark tree as not ready if root
    // node is deleted and doesn't store children
    //-------------------------------------------
    // TODO: support tree is ready even if root
    // is deleted but owns children
    //-------------------------------------------

    // Central controller of the engine
    engine_states fsm;
    // Store the previous state as stack for branching in a processor
    // to remember last operations. Usefull to avoid numerous "empty"
    // states to handle the FSM transitions and next operations
    engine_states fsm_stack;

    // Internals to store info during processing
    logic [RAM_ADDR_WIDTH-1:0] token_addr;
    logic [RAM_ADDR_WIDTH-1:0] child_addr;
    logic [RAM_ADDR_WIDTH-1:0] parent_addr;
    logic [RAM_ADDR_WIDTH-1:0] right_child_addr;
    logic [               1:0] nb_child;
    logic                      is_left_child;

    // Memory interface signals
    logic [RAM_ADDR_WIDTH-1:0] addr;
    logic [RAM_DATA_WIDTH-1:0] wrdata;
    logic [RAM_DATA_WIDTH-1:0] rddata;

    // To store the read node content
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
    assign req_ready = ((fsm == IDLE) && aresetn == 1'b1) ? 1'b1 : 1'b0;

    // Complete request once all deletion/allocation is over
    assign cpl_valid = (fsm == REQ_COMPLETION);

    // Accept insert completion anyway
    assign insert_cpl_ready = (fsm == INSERT_TOKEN);

    // Inform the parent about its state to switch correctly interfaces
    // to memory and tree space manager
    assign fsm_state = fsm;

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
    // Memory requests to tree space manager
    // -------------------------------------------------------------------------

    assign tree_mgt_free_valid = (fsm == FREE_ADDR);

    // -------------------------------------------------------------------------
    // Main FSM managing the user requests
    // -------------------------------------------------------------------------

    always @ (posedge aclk or negedge aresetn) begin

        if (aresetn == 1'b0) begin
            addr <= {RAM_ADDR_WIDTH{1'b0}};
            child_addr <= {RAM_ADDR_WIDTH{1'b0}};
            tree_mgt_free_addr <= {RAM_ADDR_WIDTH{1'b0}};
            parent_addr <= {RAM_ADDR_WIDTH{1'b0}};
            right_child_addr <= {RAM_ADDR_WIDTH{1'b0}};
            wrdata <= {RAM_DATA_WIDTH{1'b0}};
            fsm <= IDLE;
            fsm_stack <= IDLE;
            nb_child <= 2'b0;
            cpl_data <= {PAYLOAD_WIDTH{1'b0}};
            cpl_status <= 1'b0;
            search_valid <= 1'b0;
            search_cmd <= 8'b0;
            search_token <= {TOKEN_WIDTH{1'b0}};
            token_addr <= {RAM_ADDR_WIDTH{1'b0}};
            insert_addr <= {RAM_ADDR_WIDTH{1'b0}};
            is_left_child <= 1'b0;
            insert_cmd <= 8'b0;
            insert_node <= {RAM_DATA_WIDTH{1'b0}};
            insert_valid <= 1'b0;
        end else begin

            case (fsm)

                // IDLE state, waiting for user requests
                default: begin

                    fsm_stack <= IDLE;
                    nb_child <= 2'b0;
                    cpl_status <= 1'b0;
                    is_left_child <= 1'b0;

                    // Instruction DELETE_TOKEN
                    if (req_valid && engine_ready &&
                        req_cmd == `DELETE_TOKEN) begin
                        // Complete request with an error if tree
                        // is null
                        if (~tree_ready) begin
                            cpl_status <= 1'b1;
                            fsm <= REQ_COMPLETION;
                        end
                        // Else go to search for the token content
                        else begin
                            fsm <= SEARCH_TOKEN;
                            search_valid <= 1'b1;
                            search_cmd <= `SEARCH_TOKEN;
                            search_token <= req_token;
                        end
                    end
                end

                // Manage search token request to search engine, initiates
                // the request and wait for completion.
                SEARCH_TOKEN: begin

                    // Initiate a search and wait for its accepted
                    if (search_ready)
                        search_valid <= 1'b0;

                    // Once found, ech if cpl is ok or not
                    if (search_cpl_valid) begin
                        // Complete request with an error if
                        // token has not been found
                        if (search_cpl_status) begin
                            cpl_status <= 1'b1;
                            fsm <= REQ_COMPLETION;
                        end
                        // If found, move to read the node
                        // and move then to deletion
                        else begin
                            token_addr <= search_cpl_addr;
                            addr <= search_cpl_addr;
                            fsm <= RD_RAM;
                            fsm_stack <= DELETE_TOKEN;
                        end
                    end

                end

                // Central place to initiate a deletion. Enter here after it
                // initiated a search with search engine.  When entering,
                // node is already read and we can start the deletion
                DELETE_TOKEN : begin

                    // Store this information to avoid address comparaisons
                    // when update parent node info
                    is_left_child <= rdnode_info[3];

                    // If node is a leaf, just free the address and
                    // update the parent information
                    if (rdnode_info[1:0] == 2'b0) begin
                        addr <= rdnode_parent_addr;
                        tree_mgt_free_addr <= addr;
                        nb_child <= 2'b0;
                        fsm <= RD_RAM;
                        fsm_stack <= UPDATE_PARENT;
                    end
                    // If only owns a single child, append this child node on
                    // parent and free the token address
                    else if (rdnode_info[1:0] == 2'b01 || 
                                rdnode_info[1:0] == 2'b10) begin
                        is_left_child <= rdnode_info[3];
                        child_addr <= (rdnode_has_left_child) ?
                                            rdnode_left_child_addr :
                                            rdnode_right_child_addr;
                        tree_mgt_free_addr <= addr;
                        addr <= rdnode_parent_addr;
                        nb_child <= 2'b01;
                        fsm <= RD_RAM;
                        fsm_stack <= UPDATE_PARENT;
                    end
                    // If node owns two children, the node content will be
                    // replaced by left child, which will be freed and right
                    // child will be attached on a slot of the left child
                    else begin
                        // Left child slot will be freed and copy in 
                        // place of parent
                        tree_mgt_free_addr <= rdnode_left_child_addr;
                        // Rigth child will be updated laster
                        right_child_addr <= rdnode_right_child_addr;
                        // Parent address used later to overwrite the existing
                        // parent field of left child
                        parent_addr <= rdnode_parent_addr;
                        addr <= rdnode_left_child_addr;
                        nb_child <= 2'b11;
                        // Read first the left child before parent overwriting
                        fsm <= RD_RAM;
                        fsm_stack <= UPDATE_PARENT;
                    end
                end

                // In charge to update the parent wth the deleted child info
                // if the node to delete is not a leaf. We substitute the
                // node to delete with its child.
                UPDATE_PARENT: begin
                    // When token to delete is a leaf, simply remove it from
                    // parent before releasing the token
                    if (nb_child == 2'b0) begin
                        wrdata <= {rdnode_payload,
                                   rdnode_left_child_addr,
                                   rdnode_right_child_addr,
                                   rdnode_parent_addr,
                                   rdnode_token,
                                   rdnode_info[7:2],
                                   (is_left_child) ? 1'b0 : rdnode_info[1],
                                   (~is_left_child) ? 1'b0 : rdnode_info[0]
                                  };
                        fsm <= WR_RAM;
                        fsm_stack <= FREE_ADDR;
                    end
                    // If the token onws a child, overwrite it with its child
                    // on parent node. We switch with is_left_child to avoid
                    // comparaison in parent with its left/right children
                    // addresses
                    else if (nb_child == 2'b01) begin

                        wrdata <= {rdnode_payload,
                                   (is_left_child) ?
                                        child_addr :
                                        rdnode_left_child_addr,
                                   (~is_left_child) ?
                                        child_addr :
                                        rdnode_right_child_addr,
                                   rdnode_parent_addr,
                                   rdnode_token,
                                   rdnode_info
                                  };
                        fsm <= WR_RAM;
                        fsm_stack <= FREE_ADDR;
                    end
                    // When the token owns two children, we replace it with 
                    // the left child. No need to handle the parent, we'll
                    // handle the right child only, and so save some cycles
                    else begin
                        addr <= parent_addr;
                        wrdata <= rddata;
                        fsm <= WR_RAM;
                        fsm_stack <= READ_CHILD;
                    end

                end

                // Intermediate state to read right child content
                // before requesting a new insert in the tree
                READ_CHILD: begin
                    addr <= right_child_addr;
                    fsm <= RD_RAM;
                    fsm_stack <= INSERT_TOKEN;
                end

                // Request a slot to search engine and wait for the completion
                INSERT_TOKEN: begin

                    insert_node <= rddata;
                    insert_addr <= right_child_addr;
                    insert_cmd <= `INSERT_TOKEN;

                    if (insert_valid == 1'b0 && insert_ready == 1'b1) begin
                        insert_valid <= 1'b1;
                    end
                    else if (insert_valid && insert_ready) begin
                        insert_valid <= 1'b0;
                    end

                    // Once found
                    if (insert_cpl_valid) begin
                        // Complete request with an error if
                        // token has not been found
                        if (insert_cpl_status) begin
                            cpl_status <= 1'b1;
                            fsm <= REQ_COMPLETION;
                        end
                        // Free the token and complete the request
                        else begin
                            fsm <= FREE_ADDR;
                        end
                    end
                end

                // Release the token address in the memory with the
                // tree space manager.
                FREE_ADDR: begin
                    if (tree_mgt_free_ready) begin
                        fsm <= REQ_COMPLETION;
                    end
                end

                // Deliver completion of a search or delete request,
                // handled by tree space manager
                REQ_COMPLETION : begin
                    if (cpl_ready)
                        fsm <= IDLE;
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
