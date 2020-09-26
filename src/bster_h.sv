// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`ifndef BSTER
`define BSTER


///////////////////////////////////////////////////////
// Function used to check parameters setup in top level
// Avoid a user configure in a wrong way the core
///////////////////////////////////////////////////////
 
`define CHECKER(condition, msg)\
    if(condition) begin\
        $display("\033[1;31mERROR: %s\033[0m", msg);\
        $finish(1);\
    end


/////////////////////////////////
// List of all available commands
/////////////////////////////////

`define SEARCH_TOKEN 8'h10
`define SEARCH_SMALLEST_TOKEN 8'h11
`define SEARCH_BIGGEST_TOKEN 8'h12
`define INSERT_TOKEN 8'h20
`define INSERT_DATA 8'h21
`define DELETE_TOKEN 8'h30
`define DELETE_DATA 8'h31
`define DELETE_CHILDREN 8'h32
`define DELETE_LEFT_CHILD 8'h33
`define DELETE_RIGHT_CHILD 8'h34
`define CREATE_TREE 8'h40
`define CHECK_TREE_IS_CONFORM 8'h41
`define REORDER_TREE 8'h42
`define GET_TREE_SIZE 8'h43
`define GET_TREE_DEPTH 8'h44


/////////////////////////////////////////////////////
// Index and width of registers handled by csr module
/////////////////////////////////////////////////////

// Define the AXI4-lite addr/data width for define purpose
`define CSR_ADDR_WIDTH 8
`define CSR_DATA_WIDTH 32

// AXI4-lite register, used to check AXI4-lite readiness
`define MAILBOX 0
`define MAILBOX_W `CSR_DATA_WIDTH

// Address of the root node in the tree
`define ROOT_NODE   (`MAILBOX + `MAILBOX_W)
`define ROOT_NODE_W 64

// Total width of CSR register shared across the IP
`define CSR_WIDTH (`ROOT_NODE + `ROOT_NODE_W)

`endif
