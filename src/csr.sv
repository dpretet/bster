// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "bster_h.sv"

module csr

    #(
        // Addr Width in bits for Control/Status Register interface
        parameter CSR_ADDR_WIDTH = 8,
        // Data Width in bits for Control/Status Register interface
        parameter CSR_DATA_WIDTH = 32
    )(
        input  wire                        pclk,
        input  wire                        presetn,
        input  wire [  CSR_ADDR_WIDTH-1:0] paddr,
        input  wire [               2-1:0] pprot,
        input  wire                        penable,
        input  wire                        pwrite,
        output reg                         pready,
        input  wire [  CSR_DATA_WIDTH-1:0] pwdata,
        input  wire [CSR_DATA_WIDTH/8-1:0] pstrb,
        output reg  [  CSR_DATA_WIDTH-1:0] prdata,
        output reg                         pslverr,
        input  wire [      `CSR_SLV_W-1:0] csr_slv,
        output wire [      `CSR_MST_W-1:0] csr_mst
    );

    /////////////////////////////////////////////////
    // Local declarations
    /////////////////////////////////////////////////

    // Registers input/output
    logic [  CSR_DATA_WIDTH-1:0] mail_box;
    logic [  CSR_DATA_WIDTH-1:0] base_lsb;
    logic [  CSR_DATA_WIDTH-1:0] base_msb;
    logic [  CSR_DATA_WIDTH-1:0] max_lsb;
    logic [  CSR_DATA_WIDTH-1:0] max_msb;
    logic [  CSR_DATA_WIDTH-1:0] control;
    logic [  CSR_DATA_WIDTH-1:0] opcodes;
    logic [  CSR_DATA_WIDTH-1:0] status;

    // intermediate signals to drive the APB output
    logic [  CSR_DATA_WIDTH-1:0] prdata_mb;
    logic                        pready_mb;
    logic                        pslverr_mb;
    logic [  CSR_DATA_WIDTH-1:0] prdata_blsb;
    logic                        pready_blsb;
    logic                        pslverr_blsb;
    logic [  CSR_DATA_WIDTH-1:0] prdata_bmsb;
    logic                        pready_bmsb;
    logic                        pslverr_bmsb;
    logic [  CSR_DATA_WIDTH-1:0] prdata_mlsb;
    logic                        pready_mlsb;
    logic                        pslverr_mlsb;
    logic [  CSR_DATA_WIDTH-1:0] prdata_mmsb;
    logic                        pready_mmsb;
    logic                        pslverr_mmsb;
    logic [  CSR_DATA_WIDTH-1:0] prdata_ctrl;
    logic                        pready_ctrl;
    logic                        pslverr_ctrl;
    logic [  CSR_DATA_WIDTH-1:0] prdata_op;
    logic                        pready_op;
    logic                        pslverr_op;
    logic [  CSR_DATA_WIDTH-1:0] prdata_st;
    logic                        pready_st;
    logic                        pslverr_st;

    logic                        clear_ctrl;

    /////////////////////////////////////////////////
    // Mailbox register
    /////////////////////////////////////////////////

    csr_reg
    #(
    .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
    .CSR_DATA_WIDTH (CSR_DATA_WIDTH),
    .ADDRESS        (`ADDR_MAILBOX),
    .MODE           (4'b1111)
    )
    mailbox_reg
    (
    .pclk    (pclk),
    .presetn (presetn),
    .paddr   (paddr),
    .pprot   (pprot),
    .penable (penable),
    .pwrite  (pwrite),
    .pready  (pready_mb),
    .pwdata  (pwdata),
    .pstrb   (pstrb),
    .prdata  (prdata_mb),
    .pslverr (pslverr_mb),
    .clear   (4'b0),
    .reg_i   (mail_box),
    .reg_o   (mail_box)
    );

    /////////////////////////////////////////////////
    // Base Address LSB/MSB register
    /////////////////////////////////////////////////

    csr_reg
    #(
    .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
    .CSR_DATA_WIDTH (CSR_DATA_WIDTH),
    .ADDRESS        (`ADDR_RAM_BASE_LSB),
    .MODE           (4'b1111)
    )
    base_addr_lsb_reg
    (
    .pclk    (pclk),
    .presetn (presetn),
    .paddr   (paddr),
    .pprot   (pprot),
    .penable (penable),
    .pwrite  (pwrite),
    .pready  (pready_blsb),
    .pwdata  (pwdata),
    .pstrb   (pstrb),
    .prdata  (prdata_blsb),
    .pslverr (pslverr_blsb),
    .clear   (4'b0),
    .reg_i   (base_lsb),
    .reg_o   (base_lsb)
    );

    csr_reg
    #(
    .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
    .CSR_DATA_WIDTH (CSR_DATA_WIDTH),
    .ADDRESS        (`ADDR_RAM_BASE_MSB),
    .MODE           (4'b1111)
    )
    base_addr_msb_reg
    (
    .pclk    (pclk),
    .presetn (presetn),
    .paddr   (paddr),
    .pprot   (pprot),
    .penable (penable),
    .pwrite  (pwrite),
    .pready  (pready_bmsb),
    .pwdata  (pwdata),
    .pstrb   (pstrb),
    .prdata  (prdata_bmsb),
    .pslverr (pslverr_bmsb),
    .clear   (4'b0),
    .reg_i   (base_msb),
    .reg_o   (base_msb)
    );

    /////////////////////////////////////////////////
    // Max Address LSB/MSB register
    /////////////////////////////////////////////////

    csr_reg
    #(
    .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
    .CSR_DATA_WIDTH (CSR_DATA_WIDTH),
    .ADDRESS        (`ADDR_RAM_MAX_LSB),
    .MODE           (4'b1111)
    )
    max_addr_lsb_reg
    (
    .pclk    (pclk),
    .presetn (presetn),
    .paddr   (paddr),
    .pprot   (pprot),
    .penable (penable),
    .pwrite  (pwrite),
    .pready  (pready_mlsb),
    .pwdata  (pwdata),
    .pstrb   (pstrb),
    .prdata  (prdata_mlsb),
    .pslverr (pslverr_mlsb),
    .clear   (4'b0),
    .reg_i   (max_lsb),
    .reg_o   (max_lsb)
    );

    csr_reg
    #(
    .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
    .CSR_DATA_WIDTH (CSR_DATA_WIDTH),
    .ADDRESS        (`ADDR_RAM_MAX_MSB),
    .MODE           (4'b1111)
    )
    max_addr_msb_reg
    (
    .pclk    (pclk),
    .presetn (presetn),
    .paddr   (paddr),
    .pprot   (pprot),
    .penable (penable),
    .pwrite  (pwrite),
    .pready  (pready_mmsb),
    .pwdata  (pwdata),
    .pstrb   (pstrb),
    .prdata  (prdata_mmsb),
    .pslverr (pslverr_mmsb),
    .clear   (4'b0),
    .reg_i   (max_msb),
    .reg_o   (max_msb)
    );

    /////////////////////////////////////////////////
    // Control and status register
    /////////////////////////////////////////////////

    assign clear_ctrl = 1'b0;

    csr_reg
    #(
    .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
    .CSR_DATA_WIDTH (CSR_DATA_WIDTH),
    .ADDRESS        (`ADDR_CTRL),
    .MODE           (4'b0001)
    )
    ctrl_reg
    (
    .pclk    (pclk),
    .presetn (presetn),
    .paddr   (paddr),
    .pprot   (pprot),
    .penable (penable),
    .pwrite  (pwrite),
    .pready  (pready_ctrl),
    .pwdata  (pwdata),
    .pstrb   (pstrb),
    .prdata  (prdata_ctrl),
    .pslverr (pslverr_ctrl),
    .clear   ({3'b000,clear_ctrl}),
    .reg_i   (control),
    .reg_o   (control)
    );

    csr_reg
    #(
    .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
    .CSR_DATA_WIDTH (CSR_DATA_WIDTH),
    .ADDRESS        (`ADDR_STATUS),
    .MODE           (4'b0000)
    )
    status_reg
    (
    .pclk    (pclk),
    .presetn (presetn),
    .paddr   (paddr),
    .pprot   (pprot),
    .penable (penable),
    .pwrite  (pwrite),
    .pready  (pready_st),
    .pwdata  (pwdata),
    .pstrb   (pstrb),
    .prdata  (prdata_st),
    .pslverr (pslverr_st),
    .clear   (4'b0),
    .reg_i   (status),
    .reg_o   (status)
    );

    csr_reg
    #(
    .CSR_ADDR_WIDTH (CSR_ADDR_WIDTH),
    .CSR_DATA_WIDTH (CSR_DATA_WIDTH),
    .ADDRESS        (`ADDR_OPCODES),
    .MODE           (4'b0000)
    )
    opcodes_reg
    (
    .pclk    (pclk),
    .presetn (presetn),
    .paddr   (paddr),
    .pprot   (pprot),
    .penable (penable),
    .pwrite  (pwrite),
    .pready  (pready_op),
    .pwdata  (pwdata),
    .pstrb   (pstrb),
    .prdata  (prdata_op),
    .pslverr (pslverr_op),
    .clear   (4'b0),
    .reg_i   (opcodes),
    .reg_o   (opcodes)
    );

    //////////////////////////////////////////////////////////////
    // Switch between the regsiter target the output of the module
    //////////////////////////////////////////////////////////////

    always @ * begin
        if (penable) begin
            if (paddr == `ADDR_MAILBOX) begin
                prdata = prdata_mb;
                pready = pready_mb;
                pslverr = pslverr_mb;
            end else if (paddr == `ADDR_RAM_BASE_LSB) begin
                prdata = prdata_blsb;
                pready = pready_blsb;
                pslverr = pslverr_blsb;
            end else if (paddr == `ADDR_RAM_BASE_MSB) begin
                prdata = prdata_bmsb;
                pready = pready_bmsb;
                pslverr = pslverr_bmsb;
            end else if (paddr == `ADDR_RAM_MAX_LSB) begin
                prdata = prdata_mlsb;
                pready = pready_mlsb;
                pslverr = pslverr_mlsb;
            end else if (paddr == `ADDR_RAM_MAX_MSB) begin
                prdata = prdata_mmsb;
                pready = pready_mmsb;
                pslverr = pslverr_mmsb;
            end else if (paddr == `ADDR_CTRL) begin
                prdata = prdata_ctrl;
                pready = pready_ctrl;
                pslverr = pslverr_ctrl;
            end else if (paddr == `ADDR_OPCODES) begin
                prdata = prdata_op;
                pready = pready_op;
                pslverr = pslverr_op;
            end else if (paddr == `ADDR_STATUS) begin
                prdata = prdata_st;
                pready = pready_st;
                pslverr = pslverr_st;
            end else begin
                prdata = {CSR_DATA_WIDTH{1'b0}};
                pready = 1'b1;
                pslverr = 1'b1;
            end
        end
        else begin
            prdata = {CSR_DATA_WIDTH{1'b0}};
            pready = 1'b0;
            pslverr = 1'b0;
        end
    end

    /////////////////////////////////////////////////
    // Shared bus routed to the core
    /////////////////////////////////////////////////

    assign csr_mst = {`CSR_MST_W{1'b0}};

endmodule

`resetall
