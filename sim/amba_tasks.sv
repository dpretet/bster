// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`ifndef TIMEOUT
`define TIMEOUT 500
`endif

integer cmd_timer = 0;

// Function used to inject BSTer command. Drives
// the AXI4-Stream command interface directly.
//
// Input:  
//     - cmd: the BSTer command code
//     - token: the user token to store/search/delete
//       in the tree
//     - data: optional data associated to a token
//       if storing a value
//
// Return:
//     - None
//
task axi4s_command(
    input integer cmd,
    input integer token,
    input integer data=0
);
    
    `ifdef VERBOSE
        `MSG("Driving a command");
    `endif

    cmd_tvalid = 1'b1;
    cmd_tdata = cmd;

    for (cmd_timer=0;cmd_timer<`TIMEOUT;cmd_timer=cmd_timer+1) begin
        // Break the loop if commmand is acknowledged
        if (cmd_tready)
            cmd_timer = `TIMEOUT+10;
        // Ensure we don't stay forever driving the interface
        if (cmd_timer == (`TIMEOUT-1))
            `ERROR("Reached timeout during command issue");
        @(posedge aclk);
    end
    
    cmd_tvalid = 1'b0;

    `ifdef VERBOSE
        `MSG("Command received");
    `endif

endtask


// Function used to read back the BSTer command status. 
// Drives the AXI4-Stream status interface directly.
//
// Input:  
//     - None
//
// Return:
//     - the BSTer command's status code 
//
task axi4s_status(
    output integer sts
);

endtask


// Function used to read back the BSTer command completion. 
// Drives the AXI4-Stream completion interface directly.
//
// Input:  
//     - None
//
// Return:
//     - the BSTer command's completion
//
task axi4s_completion(
    output integer cpl
);

endtask
