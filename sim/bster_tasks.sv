// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

// Will stop any access after MAXTIME cycle
`ifdef maxtime
localparam MAXTIME = maxtime;
`else
localparam MAXTIME = 100;
`endif

task command(input integer cmd, input integer token, input integer data);

    axi4s_command(cmd, token, data);

endtask

task status(output integer sts);

endtask

task completion(output integer cpl);

endtask
