// copyright damien pretet 2021
// distributed under the mit license
// https://opensource.org/licenses/mit-license.php

`timescale 1 ns / 1 ps
`default_nettype none

`include "bster_h.sv"

module csr_reg

    #(
        // Addr Width in bits for Control/Status Register interface
        parameter CSR_ADDR_WIDTH = 8,
        // Data Width in bits for Control/Status Register interface
        parameter CSR_DATA_WIDTH = 32,
        // Register address
        parameter [  CSR_ADDR_WIDTH-1:0] ADDRESS = 0,
        // RW = 1, RO = 0
        parameter [CSR_DATA_WIDTH/8-1:0] MODE = 4'b0000
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
        input  wire [CSR_DATA_WIDTH/8-1:0] clear,
        input  wire [  CSR_DATA_WIDTH-1:0] reg_i,
        output reg  [  CSR_DATA_WIDTH-1:0] reg_o
    );
    
    always_ff @ (posedge pclk or negedge presetn) begin

        if (presetn == 1'b0) begin
            reg_o <= {CSR_DATA_WIDTH{1'b0}};
            prdata <= {CSR_DATA_WIDTH{1'b0}};
            pready <= 1'b0;
            pslverr <= 1'b0;
        end
        else begin
            // Clear register
            if (|clear) begin
                if (clear[0]) reg_o[0+:8] <= 8'b0;
                if (clear[1]) reg_o[8+:8] <= 8'b0;
                if (clear[2]) reg_o[16+:8] <= 8'b0;
                if (clear[3]) reg_o[24+:8] <= 8'b0;
            end else if (paddr == ADDRESS) begin
                if (penable && pwrite) begin
                    // Write register content if defined as RW
                    if (pstrb[0] && MODE[0]) reg_o[0+:8] <= pwdata[0+:8];
                    if (pstrb[1] && MODE[1]) reg_o[8+:8] <= pwdata[8+:8];
                    if (pstrb[2] && MODE[2]) reg_o[16+:8] <= pwdata[16+:8];
                    if (pstrb[3] && MODE[3]) reg_o[24+:8] <= pwdata[24+:8];
                    // Assert the error signal, if register is read-only
                    if (pstrb[0] && ~MODE[0] ||
                        pstrb[1] && ~MODE[1] ||
                        pstrb[2] && ~MODE[2] ||
                        pstrb[3] && ~MODE[3])  
                    begin
                        pslverr <= 1'b1;
                    end else begin
                        pslverr <= 1'b0;
                    end
                    // Assert anytime pready to complete the transaction
                    pready <= 1'b1;
                end
                // Handles here read access
                else if (penable && ~pwrite) begin
                    prdata <= reg_i;
                    pready <= 1'b1;
                    pslverr <= 1'b0;
                // Goes take a nap if not activated
                end else begin
                    pready <= 1'b0;
                    pslverr <= 1'b0;
                end
            // IDLE
            end else begin
                pready <= 1'b0;
                pslverr <= 1'b0;
            end
        end
    end

endmodule
