// copyright damien pretet 2020
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "bster_h.sv"

module bster

    #(
        // Define the token width
        parameter TOKEN_WIDTH = 8,
        // Define the payload width
        parameter PAYLOAD_WIDTH = 32,
        // Addr Width in bits for Control/Status Register interface
        parameter CSR_ADDR_WIDTH = 8,
        // Data Width in bits for Control/Status Register interface
        parameter CSR_DATA_WIDTH = 32,
        // Command width in bits for command and completion interface
        parameter AXI4S_WIDTH = 128,
        // Width of data bus in bits
        parameter RAM_DATA_WIDTH = 128,
        // Width of address bus in bits
        parameter RAM_ADDR_WIDTH = 16,
        // Width of wstrb (width of data bus in words)
        parameter RAM_STRB_WIDTH = (RAM_DATA_WIDTH/8),
        // Width of ID signal
        parameter RAM_ID_WIDTH = 8
    )(
        // Clock and reset interface to source the core
        input  wire                        aclk,
        input  wire                        aresetn,
        // AXI4-lite interface for Control/Status Registers
        input  wire                        awvalid,
        output wire                        awready,
        input  wire [  CSR_ADDR_WIDTH-1:0] awaddr,
        input  wire [               2-1:0] awprot,
        input  wire                        wvalid,
        output wire                        wready,
        input  wire [  CSR_DATA_WIDTH-1:0] wdata,
        input  wire [CSR_DATA_WIDTH/8-1:0] wstrb,
        output wire                        bvalid,
        input  wire                        bready,
        output wire [               2-1:0] bresp,
        input  wire                        arvalid,
        output wire                        arready,
        input  wire [  CSR_ADDR_WIDTH-1:0] araddr,
        input  wire [               2-1:0] arprot,
        output wire                        rvalid,
        input  wire                        rready,
        output wire [  CSR_DATA_WIDTH-1:0] rdata,
        output wire [               2-1:0] rresp,
        // AXI4-Stream slave interface to receive commands
        input  wire                        cmd_tvalid,
        output wire                        cmd_tready,
        input  wire [     AXI4S_WIDTH-1:0] cmd_tdata,
        // AXI4-Stream master interface to return completion
        output wire                        cpl_tvalid,
        input  wire                        cpl_tready,
        output wire [     AXI4S_WIDTH-1:0] cpl_tdata,
        // AXI4 Interface to RAM storing the binary tree
        output wire [    RAM_ID_WIDTH-1:0] ram_axi_awid,
        output wire [  RAM_ADDR_WIDTH-1:0] ram_axi_awaddr,
        output wire [                 7:0] ram_axi_awlen,
        output wire [                 2:0] ram_axi_awsize,
        output wire [                 1:0] ram_axi_awburst,
        output wire                        ram_axi_awlock,
        output wire [                 3:0] ram_axi_awcache,
        output wire [                 2:0] ram_axi_awprot,
        output wire                        ram_axi_awvalid,
        input  wire                        ram_axi_awready,
        output wire [  RAM_DATA_WIDTH-1:0] ram_axi_wdata,
        output wire [  RAM_STRB_WIDTH-1:0] ram_axi_wstrb,
        output wire                        ram_axi_wlast,
        output wire                        ram_axi_wvalid,
        input  wire                        ram_axi_wready,
        input  wire [    RAM_ID_WIDTH-1:0] ram_axi_bid,
        input  wire [                 1:0] ram_axi_bresp,
        input  wire                        ram_axi_bvalid,
        output wire                        ram_axi_bready,
        output wire [    RAM_ID_WIDTH-1:0] ram_axi_arid,
        output wire [  RAM_ADDR_WIDTH-1:0] ram_axi_araddr,
        output wire [                 7:0] ram_axi_arlen,
        output wire [                 2:0] ram_axi_arsize,
        output wire [                 1:0] ram_axi_arburst,
        output wire                        ram_axi_arlock,
        output wire [                 3:0] ram_axi_arcache,
        output wire [                 2:0] ram_axi_arprot,
        output wire                        ram_axi_arvalid,
        input  wire                        ram_axi_arready,
        input  wire [    RAM_ID_WIDTH-1:0] ram_axi_rid,
        input  wire [  RAM_DATA_WIDTH-1:0] ram_axi_rdata,
        input  wire [                 1:0] ram_axi_rresp,
        input  wire                        ram_axi_rlast,
        input  wire                        ram_axi_rvalid,
        output wire                        ram_axi_rready
    );

    // Check parameters setup consistency
    // and break up if not supported
    initial begin

        `CHECKER((CSR_ADDR_WIDTH != 8),
            "CSR interface only support 8 bits address width");

        `CHECKER((CSR_ADDR_WIDTH != `CSR_ADDR_WIDTH),
            "CSR address parameter and define must have the same value 8");

        `CHECKER((CSR_DATA_WIDTH != 32),
            "CSR interface only support 32 bits data width");

        `CHECKER((CSR_DATA_WIDTH != `CSR_DATA_WIDTH),
            "CSR data parameter and define must have the same value 32");

        `CHECKER((RAM_ADDR_WIDTH > `ROOT_NODE_W),
            "RAM address width can't be greater than 64 Bits");

        `CHECKER((TOKEN_WIDTH > RAM_ADDR_WIDTH),
            "Token can't use a width wider than RAM address width");

        `CHECKER(((TOKEN_WIDTH+PAYLOAD_WIDTH+8) > AXI4S_WIDTH), // 8 for command width
            "AXI4S interface must be wider to enclose command, token and payload");

        `CHECKER((RAM_STRB_WIDTH != (RAM_DATA_WIDTH/8)),
            "RAM_STRB_WIDTH must be equal to RAM_DATA_WIDTH/8");
    end

    // Control/Status register shared across the IP's modules
    logic [      `CSR_WIDTH-1:0] csr_i;
    logic [      `CSR_WIDTH-1:0] csr_o;
    logic [      `CSR_WIDTH-1:0] csr_temp;

    logic                        itf_valid;
    logic                        itf_ready;
    logic [                 7:0] itf_cmd;
    logic [     TOKEN_WIDTH-1:0] itf_token;
    logic [   PAYLOAD_WIDTH-1:0] itf_data;

    logic                        tree_mgt_req_valid;
    logic                        tree_mgt_req_ready;
    logic [  RAM_ADDR_WIDTH-1:0] tree_mgt_req_addr;
    logic                        tree_mgt_free_valid;
    logic                        tree_mgt_free_ready;
    logic [  RAM_ADDR_WIDTH-1:0] tree_mgt_free_addr;
    logic                        tree_mgt_full;

    logic                        mem_valid;
    logic                        mem_ready;
    logic                        mem_rd;
    logic                        mem_wr;
    logic [  RAM_ADDR_WIDTH-1:0] mem_addr;
    logic [  RAM_DATA_WIDTH-1:0] mem_wr_data;
    logic                        mem_rd_valid;
    logic                        mem_rd_ready;
    logic [  RAM_DATA_WIDTH-1:0] mem_rd_data;

    // AXI4-lite interface to access internal
    // control/status registers
    csr
    #(
        .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
        .CSR_DATA_WIDTH (CSR_DATA_WIDTH)
    )
    csr_inst
    (
        .aclk       (aclk   ),
        .aresetn    (aresetn),
        .awvalid    (awvalid),
        .awready    (awready),
        .awaddr     (awaddr ),
        .awprot     (awprot ),
        .wvalid     (wvalid ),
        .wready     (wready ),
        .wdata      (wdata  ),
        .wstrb      (wstrb  ),
        .bvalid     (bvalid ),
        .bready     (bready ),
        .bresp      (bresp  ),
        .arvalid    (arvalid),
        .arready    (arready),
        .araddr     (araddr ),
        .arprot     (arprot ),
        .rvalid     (rvalid ),
        .rready     (rready ),
        .rdata      (rdata  ),
        .rresp      (rresp  ),
        .csr_i      (csr_i  ),
        .csr_o      (csr_o  )
    );

    // TODO: Connect CSR buses across the modules
    assign csr_i = {`CSR_WIDTH{1'b0}};
    assign csr_temp = csr_o;

    // AXI4-stream interface to inject command
    // and read back completion
    interface_handler
    #(
        .TOKEN_WIDTH   (TOKEN_WIDTH  ),
        .PAYLOAD_WIDTH (PAYLOAD_WIDTH),
        .AXI4S_WIDTH   (AXI4S_WIDTH  )
    )
    itf_inst
    (
        .aclk       (aclk      ),
        .aresetn    (aresetn   ),
        .cmd_tvalid (cmd_tvalid),
        .cmd_tready (cmd_tready),
        .cmd_tdata  (cmd_tdata ),
        .cpl_tvalid (cpl_tvalid),
        .cpl_tready (cpl_tready),
        .cpl_tdata  (cpl_tdata ),
        .itf_valid  (itf_valid ),
        .itf_ready  (itf_ready ),
        .itf_cmd    (itf_cmd   ),
        .itf_token  (itf_token ),
        .itf_data   (itf_data  )
    );

    // BST engine managing the tree operations
    bst_engine
    #(
        .TOKEN_WIDTH    (TOKEN_WIDTH   ),
        .PAYLOAD_WIDTH  (PAYLOAD_WIDTH ),
        .RAM_DATA_WIDTH (RAM_DATA_WIDTH),
        .RAM_ADDR_WIDTH (RAM_ADDR_WIDTH),
        .RAM_STRB_WIDTH (RAM_STRB_WIDTH),
        .RAM_ID_WIDTH   (RAM_ID_WIDTH  )
    )
    bst_engine_inst
    (
        .aclk                (aclk               ),
        .aresetn             (aresetn            ),
        .itf_valid           (itf_valid          ),
        .itf_ready           (itf_ready          ),
        .itf_cmd             (itf_cmd            ),
        .itf_token           (itf_token          ),
        .itf_data            (itf_data           ),
        .tree_mgt_req_valid  (tree_mgt_req_valid ),
        .tree_mgt_req_ready  (tree_mgt_req_ready ),
        .tree_mgt_req_addr   (tree_mgt_req_addr  ),
        .tree_mgt_free_valid (tree_mgt_free_valid),
        .tree_mgt_free_ready (tree_mgt_free_ready),
        .tree_mgt_free_addr  (tree_mgt_free_addr ),
        .tree_mgt_full       (tree_mgt_full      ),
        .mem_valid           (mem_valid          ),
        .mem_ready           (mem_ready          ),
        .mem_rd              (mem_rd             ),
        .mem_wr              (mem_wr             ),
        .mem_addr            (mem_addr           ),
        .mem_wr_data         (mem_wr_data        ),
        .mem_rd_valid        (mem_rd_valid       ),
        .mem_rd_ready        (mem_rd_ready       ),
        .mem_rd_data         (mem_rd_data        )
    );

    // Tree space manager providing available
    // address and releasing unused one
    tree_space_manager
    #(
        .RAM_ADDR_WIDTH (RAM_ADDR_WIDTH)
    )
    tree_space_manager_inst
    (
        .aclk                (aclk                ),
        .aresetn             (aresetn             ),
        .tree_mgt_req_valid  (tree_mgt_req_valid  ),
        .tree_mgt_req_ready  (tree_mgt_req_ready  ),
        .tree_mgt_req_addr   (tree_mgt_req_addr   ),
        .tree_mgt_free_valid (tree_mgt_free_valid ),
        .tree_mgt_free_ready (tree_mgt_free_ready ),
        .tree_mgt_free_addr  (tree_mgt_free_addr  ),
        .tree_mgt_full       (tree_mgt_full       )
    );

    // Memory driver managing the AXI4 interface to
    // external RAM
    memory_driver
    #(
        .RAM_DATA_WIDTH (RAM_DATA_WIDTH),
        .RAM_ADDR_WIDTH (RAM_ADDR_WIDTH),
        .RAM_STRB_WIDTH (RAM_STRB_WIDTH),
        .RAM_ID_WIDTH   (RAM_ID_WIDTH  )
    )
    memory_driver_inst
    (
        .aclk             (aclk           ),
        .aresetn          (aresetn        ),
        .mem_valid        (mem_valid      ),
        .mem_ready        (mem_ready      ),
        .mem_rd           (mem_rd         ),
        .mem_wr           (mem_wr         ),
        .mem_addr         (mem_addr       ),
        .mem_wr_data      (mem_wr_data    ),
        .mem_rd_valid     (mem_rd_valid   ),
        .mem_rd_ready     (mem_rd_ready   ),
        .mem_rd_data      (mem_rd_data    ),
        .ram_axi_awid     (ram_axi_awid   ),
        .ram_axi_awaddr   (ram_axi_awaddr ),
        .ram_axi_awlen    (ram_axi_awlen  ),
        .ram_axi_awsize   (ram_axi_awsize ),
        .ram_axi_awburst  (ram_axi_awburst),
        .ram_axi_awlock   (ram_axi_awlock ),
        .ram_axi_awcache  (ram_axi_awcache),
        .ram_axi_awprot   (ram_axi_awprot ),
        .ram_axi_awvalid  (ram_axi_awvalid),
        .ram_axi_awready  (ram_axi_awready),
        .ram_axi_wdata    (ram_axi_wdata  ),
        .ram_axi_wstrb    (ram_axi_wstrb  ),
        .ram_axi_wlast    (ram_axi_wlast  ),
        .ram_axi_wvalid   (ram_axi_wvalid ),
        .ram_axi_wready   (ram_axi_wready ),
        .ram_axi_bid      (ram_axi_bid    ),
        .ram_axi_bresp    (ram_axi_bresp  ),
        .ram_axi_bvalid   (ram_axi_bvalid ),
        .ram_axi_bready   (ram_axi_bready ),
        .ram_axi_arid     (ram_axi_arid   ),
        .ram_axi_araddr   (ram_axi_araddr ),
        .ram_axi_arlen    (ram_axi_arlen  ),
        .ram_axi_arsize   (ram_axi_arsize ),
        .ram_axi_arburst  (ram_axi_arburst),
        .ram_axi_arlock   (ram_axi_arlock ),
        .ram_axi_arcache  (ram_axi_arcache),
        .ram_axi_arprot   (ram_axi_arprot ),
        .ram_axi_arvalid  (ram_axi_arvalid),
        .ram_axi_arready  (ram_axi_arready),
        .ram_axi_rid      (ram_axi_rid    ),
        .ram_axi_rdata    (ram_axi_rdata  ),
        .ram_axi_rresp    (ram_axi_rresp  ),
        .ram_axi_rlast    (ram_axi_rlast  ),
        .ram_axi_rvalid   (ram_axi_rvalid ),
        .ram_axi_rready   (ram_axi_rready )
    );

endmodule

`resetall
