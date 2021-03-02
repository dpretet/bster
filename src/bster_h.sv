// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`ifndef BSTER
`define BSTER


///////////////////////////////////////////////////////
// Function used to check parameters setup in top level
// Avoid a user configure in a wrong way the core
///////////////////////////////////////////////////////
 
`define CHECKER(condition, msg)\
    if(condition) begin \
        $display("\033[1;31mERROR: %s\033[0m", msg); \
        $finish(1); \
    end

`define LOG_RESET_ASSERTION\
    begin\
        log = $fopen("bster.log", "a");\
        $fwrite(log, "\n----------------------------------------------------------------------------------------------\n");\
        $fwrite(log, "%0t\t\t\tRESET ASSERTED\n", $time);\
        $fwrite(log, "----------------------------------------------------------------------------------------------\n\n");\
        $fclose(log);\
    end

`define LOG_RESET_DEASSERTION\
    begin\
        log = $fopen("bster.log", "a");\
        $fwrite(log, "\n----------------------------------------------------------------------------------------------\n");\
        $fwrite(log, "%0t\t\t\tRESET DEASSERTED\n", $time);\
        $fwrite(log, "----------------------------------------------------------------------------------------------\n\n");\
        $fclose(log);\
    end

`define LOG_HEADER\
    begin\
        log = $fopen("bster.log", "a");\
        $fwrite(log, "----------------------------------------------------------------------------------------------\n");\
        $fwrite(log, "TIME\t\t\tSOURCE\t\t\tOPERATION\t\t\tDESCRIPTION\n");\
        $fwrite(log, "----------------------------------------------------------------------------------------------\n\n");\
        $fclose(log);\
    end


`define LOG_FSM(name, state, desc="")\
    begin\
        log = $fopen("bster.log", "a");\
        if (desc == "")\
            $fwrite(log, "%0t\t\t\t%s\t\t\t%s\n\n", $time, name, state);\
        else\
            $fwrite(log, "%0t\t\t\t%s\t\t\t%s\t\t\t%s\n\n", $time, name, state, desc);\
        $fclose(log);\
    end

`define LOG_REQUEST(cmd, token, data)\
    begin\
        log = $fopen("bster.log", "a");\
        $fwrite(log, "----------------------------------------------------------------------------------------------\n");\
        $fwrite(log, "%0t\t\t\tCmd: %s\t\t\tToken: %0h\t\t\tData: %0h\n", $time, cmd, token, data);\
        $fwrite(log, "----------------------------------------------------------------------------------------------\n\n");\
        $fclose(log);\
    end

`define LOG_COMPLETION(cpl, status)\
    begin\
        log = $fopen("bster.log", "a");\
        $fwrite(log, "----------------------------------------------------------------------------------------------\n");\
        $fwrite(log, "%0t\t\t\tCompletion: %0h\t\t\tStatus: %0h\n", $time, cpl, status);\
        $fwrite(log, "----------------------------------------------------------------------------------------------\n\n");\
        $fclose(log);\
    end

`define LOG_MEM_WRITE(addr, wr_data)\
    begin\
        log = $fopen("bster.log", "a");\
        $fwrite(log, "%0t\t\t\tWriting memory\n\n", $time);\
        $fwrite(log, "\t\t\tAddr: %h\n", addr);\
        $fwrite(log, "\t\t\tHas right child: %h\n", wr_data[0]);\
        $fwrite(log, "\t\t\tHas left child: %h\n", wr_data[1]);\
        $fwrite(log, "\t\t\tIs root: %h\n", wr_data[2]);\
        $fwrite(log, "\t\t\tIs left child: %h\n", wr_data[3]);\
        wrix = 8;\
        $fwrite(log, "\t\t\tToken: %h\n", wr_data[wrix+:TOKEN_WIDTH]);\
        wrix = wrix + TOKEN_WIDTH;\
        $fwrite(log, "\t\t\tParent Address: %h\n", wr_data[wrix+:RAM_ADDR_WIDTH]);\
        wrix = wrix + RAM_ADDR_WIDTH;\
        $fwrite(log, "\t\t\tRight Child Address: %h\n", wr_data[wrix+:RAM_ADDR_WIDTH]);\
        wrix = wrix + RAM_ADDR_WIDTH;\
        $fwrite(log, "\t\t\tLeft Child Address: %h\n", wr_data[wrix+:RAM_ADDR_WIDTH]);\
        wrix = wrix + RAM_ADDR_WIDTH;\
        $fwrite(log, "\t\t\tPayload: %h\n", wr_data[wrix+:PAYLOAD_WIDTH]);\
        $fwrite(log, "\n");\
        $fclose(log);\
    end

`define LOG_MEM_READ(addr)\
    begin\
        log = $fopen("bster.log", "a");\
        $fwrite(log, "%0t\t\t\tReading memory\n\n", $time);\
        $fwrite(log, "\t\t\tAddr: %h\n", addr);\
        $fwrite(log, "\n");\
        $fclose(log);\
    end

`define LOG_MEM_COMPLETION(rd_data)\
    begin\
        log = $fopen("bster.log", "a");\
        $fwrite(log, "%0t\t\t\tReading completion\n\n", $time);\
        $fwrite(log, "\t\t\tHas right child: %h\n", rd_data[0]);\
        $fwrite(log, "\t\t\tHas left child: %h\n", rd_data[1]);\
        $fwrite(log, "\t\t\tIs root: %h\n", rd_data[2]);\
        $fwrite(log, "\t\t\tIs left child: %h\n", rd_data[3]);\
        rdix = 8;\
        $fwrite(log, "\t\t\tToken: %h\n", rd_data[rdix+:TOKEN_WIDTH]);\
        rdix = rdix + TOKEN_WIDTH;\
        $fwrite(log, "\t\t\tParent Address: %h\n", rd_data[rdix+:RAM_ADDR_WIDTH]);\
        rdix = rdix + RAM_ADDR_WIDTH;\
        $fwrite(log, "\t\t\tRight Child Address: %h\n", rd_data[rdix+:RAM_ADDR_WIDTH]);\
        rdix = rdix + RAM_ADDR_WIDTH;\
        $fwrite(log, "\t\t\tLeft Child Address: %h\n", rd_data[rdix+:RAM_ADDR_WIDTH]);\
        rdix = rdix + RAM_ADDR_WIDTH;\
        $fwrite(log, "\t\t\tPayload: %h\n", rd_data[rdix+:PAYLOAD_WIDTH]);\
        $fwrite(log, "\n");\
        $fclose(log);\
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
`define CHECK_TREE_CONFORMANCE 8'h40
`define REORDER_TREE 8'h41
`define GET_TREE_SIZE 8'h42
`define GET_TREE_DEPTH 8'h43

`define DEC_CMD(cmd)\
    case (cmd)\
        8'h10: cmd_str = "SEARCH_TOKEN";\
        8'h11: cmd_str = "SEARCH_SMALLEST_TOKEN";\
        8'h12: cmd_str = "SEARCH_BIGGEST_TOKEN";\
        8'h20: cmd_str = "INSERT_TOKEN";\
        8'h21: cmd_str = "INSERT_DATA";\
        8'h30: cmd_str = "DELETE_TOKEN";\
        8'h31: cmd_str = "DELETE_DATA";\
        8'h32: cmd_str = "DELETE_CHILDREN";\
        8'h33: cmd_str = "DELETE_LEFT_CHILD";\
        8'h34: cmd_str = "DELETE_RIGHT_CHILD";\
        8'h40: cmd_str = "CHECK_TREE_CONFORMANCE";\
        8'h41: cmd_str = "REORDER_TREE";\
        8'h42: cmd_str = "GET_TREE_SIZE";\
        8'h43: cmd_str = "GET_TREE_DEPTH";\
    endcase


////////////////////////////
// BST engines state machine
////////////////////////////

`define FSM_WIDTH 5

typedef enum logic[`FSM_WIDTH-1:0] {
    IDLE = 0,
    WR_RAM = 1,
    RD_RAM = 2,
    WAIT_RAM_CPL = 3,
    REQ_COMPLETION = 4,
    INSERT_TOKEN = 5,
    SEARCH_SLOT = 6,
    SEARCH_TOKEN = 7,
    DELETE_TOKEN = 8,
    FREE_ADDR = 9,
    SEARCH_COMPLETION = 10,
    UPDATE_PARENT = 11,
    READ_CHILD = 12
} engine_states;


`define DEC_FSM(state)\
    case (state)\
        0: fsm_state_str = "IDLE";\
        1: fsm_state_str = "WR_RAM";\
        2: fsm_state_str = "RD_RAM";\
        3: fsm_state_str = "WAIT_RAM_CPL";\
        4: fsm_state_str = "REQ_COMPLETION";\
        5: fsm_state_str = "INSERT_TOKEN";\
        6: fsm_state_str = "SEARCH_SLOT";\
        7: fsm_state_str = "SEARCH_TOKEN";\
        8: fsm_state_str = "DELETE_TOKEN";\
        9: fsm_state_str = "FREE_ADDR";\
        10: fsm_state_str = "SEARCH_COMPLETION";\
        11: fsm_state_str = "UPDATE_PARENT";\
        12: fsm_state_str = "READ_CHILD";\
    endcase


/////////////////////////////////////////////////////
// Index and width of registers handled by CSR core
/////////////////////////////////////////////////////

// Define the APB addr/data width for define purpose
`define CSR_ADDR_WIDTH 8
`define CSR_DATA_WIDTH 32

// Mailbox register, used to check APB interface readiness 
// Internal register, user only
`define ADDR_MAILBOX            0
`define ADDR_RAM_BASE_LSB       1
`define ADDR_RAM_BASE_MSB       2
`define ADDR_RAM_MAX_LSB        3
`define ADDR_RAM_MAX_MSB        4
`define ADDR_CTRL               5
`define ADDR_STATUS             6
`define ADDR_OPCODES            7


/////////////////////////////////////////////////////
// CSR Master bus (CSR core to modules)
/////////////////////////////////////////////////////

// Address of first RAM line
`define RAM_BASE_ADDRESS   0
`define RAM_BASE_ADDRESS_W (`CSR_DATA_WIDTH * 2)

// Max address in the RAM
`define RAM_MAX_ADDRESS   (`RAM_BASE_ADDRESS + `RAM_BASE_ADDRESS_W)
`define RAM_MAX_ADDRESS_W (`CSR_DATA_WIDTH * 2)

`define CSR_MST_W (`RAM_BASE_ADDRESS_W + `RAM_MAX_ADDRESS_W)


/////////////////////////////////////////////////////
// CSR Slave bus (module to CSR core)
/////////////////////////////////////////////////////

// Tree space manager status
`define TSM   0
`define TSM_W 1

// Opcodes of the three BST engines
`define BE   `TSM_W
`define BE_W 25

`define CSR_SLV_W (`TSM_W + `BE_W)

`endif
