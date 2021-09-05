// copyright damien pretet 2021
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
        // APB interface for Control/Status Registers
        input  wire [  CSR_ADDR_WIDTH-1:0] paddr,
        input  wire [               2-1:0] pprot,
        input  wire                        penable,
        input  wire                        pwrite,
        output wire                        pready,
        input  wire [  CSR_DATA_WIDTH-1:0] pwdata,
        input  wire [CSR_DATA_WIDTH/8-1:0] pstrb,
        output wire [  CSR_DATA_WIDTH-1:0] prdata,
        output wire                        pslverr,
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

        `CHECKER((RAM_ADDR_WIDTH > `RAM_BASE_ADDRESS_W),
            "RAM address width can't be greater than 64 Bits");

        `CHECKER((TOKEN_WIDTH > RAM_ADDR_WIDTH),
            "Token can't use a width wider than RAM address width");

        `CHECKER(((TOKEN_WIDTH+PAYLOAD_WIDTH+8) > AXI4S_WIDTH), // 8 for command width
            "AXI4S interface must be wider to enclose command, token and payload");

        `CHECKER((PAYLOAD_WIDTH+1) > AXI4S_WIDTH,
            "AXI4S completion must be greater than PAYLOAD_WIDTH + 1");

        `CHECKER((RAM_STRB_WIDTH != (RAM_DATA_WIDTH/8)),
            "RAM_STRB_WIDTH must be equal to RAM_DATA_WIDTH/8");
    end

    // Control/Status register shared across the IP's modules
    logic [      `CSR_SLV_W-1:0] csr_slv;
    logic [      `CSR_MST_W-1:0] csr_mst;

    logic                        req_valid;
    logic                        req_ready;
    logic [                 7:0] req_cmd;
    logic [     TOKEN_WIDTH-1:0] req_token;
    logic [   PAYLOAD_WIDTH-1:0] req_data;
    logic                        cpl_valid;
    logic                        cpl_ready;
    logic [   PAYLOAD_WIDTH-1:0] cpl_data;
    logic                        cpl_status;

    logic                        tree_mgt_req_valid;
    logic                        tree_mgt_req_ready;
    logic [  RAM_ADDR_WIDTH-1:0] tree_mgt_req_addr;
    logic                        tree_mgt_free_valid;
    logic                        tree_mgt_free_is_root;
    logic                        tree_mgt_free_ready;
    logic [  RAM_ADDR_WIDTH-1:0] tree_mgt_free_addr;

    logic                        mem_valid;
    logic                        mem_ready;
    logic                        mem_rd;
    logic                        mem_wr;
    logic [  RAM_ADDR_WIDTH-1:0] mem_addr;
    logic [  RAM_DATA_WIDTH-1:0] mem_wr_data;
    logic                        mem_rd_valid;
    logic                        mem_rd_ready;
    logic [  RAM_DATA_WIDTH-1:0] mem_rd_data;
    logic                        swrst;
    logic                        tree_ready;

    // AMBA APB interface to access internal control/status registers
    csr
    #(
        .RAM_ADDR_WIDTH (RAM_ADDR_WIDTH),
        .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
        .CSR_DATA_WIDTH (CSR_DATA_WIDTH)
    )
    csr_inst
    (
        .pclk    (aclk   ),
        .presetn (aresetn),
        .paddr   (paddr  ),
        .pprot   (pprot  ),
        .penable (penable),
        .pwrite  (pwrite ),
        .pready  (pready ),
        .pwdata  (pwdata ),
        .pstrb   (pstrb  ),
        .prdata  (prdata ),
        .pslverr (pslverr),
        .csr_slv (csr_slv),
        .csr_mst (csr_mst),
        .swrst   (swrst  )
    );

    // AXI4-stream interface to inject command
    // and read back completion
    interface_handler
    #(
        .TOKEN_WIDTH   (TOKEN_WIDTH  ),
        .PAYLOAD_WIDTH (PAYLOAD_WIDTH),
        .AXI4S_WIDTH   (AXI4S_WIDTH  )
    )
    intf_inst
    (
        .aclk       (aclk      ),
        .aresetn    (aresetn   ),
        .tree_ready (tree_ready),
        .cmd_tvalid (cmd_tvalid),
        .cmd_tready (cmd_tready),
        .cmd_tdata  (cmd_tdata ),
        .cpl_tvalid (cpl_tvalid),
        .cpl_tready (cpl_tready),
        .cpl_tdata  (cpl_tdata ),
        .req_valid  (req_valid ),
        .req_ready  (req_ready ),
        .req_cmd    (req_cmd   ),
        .req_token  (req_token ),
        .req_data   (req_data  ),
        .cpl_valid  (cpl_valid ),
        .cpl_ready  (cpl_ready ),
        .cpl_data   (cpl_data  ),
        .cpl_status (cpl_status)
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
        .aclk                  (aclk                       ),
        .aresetn               (aresetn                    ),
        .tree_ready            (tree_ready                 ),
        .req_valid             (req_valid                  ),
        .req_ready             (req_ready                  ),
        .req_cmd               (req_cmd                    ),
        .req_token             (req_token                  ),
        .req_data              (req_data                   ),
        .cpl_valid             (cpl_valid                  ),
        .cpl_ready             (cpl_ready                  ),
        .cpl_data              (cpl_data                   ),
        .cpl_status            (cpl_status                 ),
        .tree_mgt_req_valid    (tree_mgt_req_valid         ),
        .tree_mgt_req_ready    (tree_mgt_req_ready         ),
        .tree_mgt_req_addr     (tree_mgt_req_addr          ),
        .tree_mgt_free_valid   (tree_mgt_free_valid        ),
        .tree_mgt_free_is_root (tree_mgt_free_is_root      ),
        .tree_mgt_free_ready   (tree_mgt_free_ready        ),
        .tree_mgt_free_addr    (tree_mgt_free_addr         ),
        .mem_valid             (mem_valid                  ),
        .mem_ready             (mem_ready                  ),
        .mem_rd                (mem_rd                     ),
        .mem_wr                (mem_wr                     ),
        .mem_addr              (mem_addr                   ),
        .mem_wr_data           (mem_wr_data                ),
        .mem_rd_valid          (mem_rd_valid               ),
        .mem_rd_ready          (mem_rd_ready               ),
        .mem_rd_data           (mem_rd_data                ),
        .csr_mst               (csr_slv[`BE+:`BE_W]        )
    );

    // Tree space manager providing available
    // address and releasing unused one
    tree_space_manager
    #(
        .RAM_ADDR_WIDTH (RAM_ADDR_WIDTH)
    )
    tree_space_manager_inst
    (
        .aclk                  (aclk                  ),
        .aresetn               (aresetn               ),
        .tree_mgt_req_valid    (tree_mgt_req_valid    ),
        .tree_mgt_req_ready    (tree_mgt_req_ready    ),
        .tree_mgt_req_addr     (tree_mgt_req_addr     ),
        .tree_mgt_free_valid   (tree_mgt_free_valid   ),
        .tree_mgt_free_is_root (tree_mgt_free_is_root ),
        .tree_mgt_free_ready   (tree_mgt_free_ready   ),
        .tree_mgt_free_addr    (tree_mgt_free_addr    ),
        .csr_slv               (csr_mst[0+:`CSR_MST_W]),
        .csr_mst               (csr_slv[`TSM+:`TSM_W] )
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
        .aclk            (aclk           ),
        .aresetn         (aresetn        ),
        .mem_valid       (mem_valid      ),
        .mem_ready       (mem_ready      ),
        .mem_rd          (mem_rd         ),
        .mem_wr          (mem_wr         ),
        .mem_addr        (mem_addr       ),
        .mem_wr_data     (mem_wr_data    ),
        .mem_rd_valid    (mem_rd_valid   ),
        .mem_rd_ready    (mem_rd_ready   ),
        .mem_rd_data     (mem_rd_data    ),
        .ram_axi_awid    (ram_axi_awid   ),
        .ram_axi_awaddr  (ram_axi_awaddr ),
        .ram_axi_awlen   (ram_axi_awlen  ),
        .ram_axi_awsize  (ram_axi_awsize ),
        .ram_axi_awburst (ram_axi_awburst),
        .ram_axi_awlock  (ram_axi_awlock ),
        .ram_axi_awcache (ram_axi_awcache),
        .ram_axi_awprot  (ram_axi_awprot ),
        .ram_axi_awvalid (ram_axi_awvalid),
        .ram_axi_awready (ram_axi_awready),
        .ram_axi_wdata   (ram_axi_wdata  ),
        .ram_axi_wstrb   (ram_axi_wstrb  ),
        .ram_axi_wlast   (ram_axi_wlast  ),
        .ram_axi_wvalid  (ram_axi_wvalid ),
        .ram_axi_wready  (ram_axi_wready ),
        .ram_axi_bid     (ram_axi_bid    ),
        .ram_axi_bresp   (ram_axi_bresp  ),
        .ram_axi_bvalid  (ram_axi_bvalid ),
        .ram_axi_bready  (ram_axi_bready ),
        .ram_axi_arid    (ram_axi_arid   ),
        .ram_axi_araddr  (ram_axi_araddr ),
        .ram_axi_arlen   (ram_axi_arlen  ),
        .ram_axi_arsize  (ram_axi_arsize ),
        .ram_axi_arburst (ram_axi_arburst),
        .ram_axi_arlock  (ram_axi_arlock ),
        .ram_axi_arcache (ram_axi_arcache),
        .ram_axi_arprot  (ram_axi_arprot ),
        .ram_axi_arvalid (ram_axi_arvalid),
        .ram_axi_arready (ram_axi_arready),
        .ram_axi_rid     (ram_axi_rid    ),
        .ram_axi_rdata   (ram_axi_rdata  ),
        .ram_axi_rresp   (ram_axi_rresp  ),
        .ram_axi_rlast   (ram_axi_rlast  ),
        .ram_axi_rvalid  (ram_axi_rvalid ),
        .ram_axi_rready  (ram_axi_rready )
    );

endmodule

`resetall
