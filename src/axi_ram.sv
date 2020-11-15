`timescale 1 ns / 1 ps
`default_nettype none


module axi_ram
    #(
        // Width of data bus in bits
        parameter DATA_WIDTH = 32,
        // Width of address bus in bits
        parameter ADDR_WIDTH = 16,
        // Width of wstrb (width of data bus in words)
        parameter STRB_WIDTH = (DATA_WIDTH/8),
        // Width of ID signal
        parameter ID_WIDTH = 8,
        // Extra pipeline register on output
        parameter PIPELINE_OUTPUT = 0
    ) (
        input  wire                   aclk,
        input  wire                   aresetn,
        input  wire [ID_WIDTH-1:0]    s_axi_awid,
        input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
        input  wire [7:0]             s_axi_awlen,
        input  wire [2:0]             s_axi_awsize,
        input  wire [1:0]             s_axi_awburst,
        input  wire                   s_axi_awlock,
        input  wire [3:0]             s_axi_awcache,
        input  wire [2:0]             s_axi_awprot,
        input  wire                   s_axi_awvalid,
        output wire                   s_axi_awready,
        input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
        input  wire [STRB_WIDTH-1:0]  s_axi_wstrb,
        input  wire                   s_axi_wlast,
        input  wire                   s_axi_wvalid,
        output wire                   s_axi_wready,
        output wire [ID_WIDTH-1:0]    s_axi_bid,
        output wire [1:0]             s_axi_bresp,
        output wire                   s_axi_bvalid,
        input  wire                   s_axi_bready,
        input  wire [ID_WIDTH-1:0]    s_axi_arid,
        input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
        input  wire [7:0]             s_axi_arlen,
        input  wire [2:0]             s_axi_arsize,
        input  wire [1:0]             s_axi_arburst,
        input  wire                   s_axi_arlock,
        input  wire [3:0]             s_axi_arcache,
        input  wire [2:0]             s_axi_arprot,
        input  wire                   s_axi_arvalid,
        output wire                   s_axi_arready,
        output wire [ID_WIDTH-1:0]    s_axi_rid,
        output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
        output wire [1:0]             s_axi_rresp,
        output wire                   s_axi_rlast,
        output reg                    s_axi_rvalid,
        input  wire                   s_axi_rready
    );

        logic [DATA_WIDTH-1:0] mem [ADDR_WIDTH-1:0];
        logic wait_wdata;

        assign s_axi_awready = ~wait_wdata;
        assign s_axi_wready = 1'b1;
        assign s_axi_arready = ~s_axi_rvalid;
        assign s_axi_bvalid = 1'b0;
        assign s_axi_rlast = 1'b1;
        assign s_axi_bresp = 2'b0;
        assign s_axi_rresp = 2'b0;

        // Simple AXI RAM, supported basic write
        always @ (posedge aclk) begin
            if (aresetn ==  1'b0) begin
                wait_wdata <= 1'b0;
            end else begin
                if (s_axi_awvalid && s_axi_awready ) begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        mem[s_axi_awaddr] <= s_axi_wdata;
                    end else begin
                        wait_wdata <= 1'b1;
                    end
                end else if (wait_wdata) begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        mem[s_axi_awaddr] <= s_axi_wdata;
                        wait_wdata <= 1'b0;
                    end
                end
            end
        end

        // TODO: Manage BRESP completion, based on number of write issued

        always @ (posedge aclk or negedge aresetn) begin
            if (aresetn ==  1'b0) begin
                s_axi_rvalid <= 1'b0;
                s_axi_rdata <= {DATA_WIDTH{1'b0}};
            end else begin
                // Manage one by one the read request, block new read
                // until completion is not passed
                if (s_axi_rvalid == 1'b0 && s_axi_arvalid && s_axi_arready) begin
                    s_axi_rvalid <= 1'b1;
                    s_axi_rdata <= mem[s_axi_araddr];
                end else if (s_axi_rvalid) begin
                    if (s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                    end
                end

            end
        end

endmodule

`resetall

