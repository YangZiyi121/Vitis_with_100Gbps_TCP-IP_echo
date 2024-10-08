`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 03/17/2023 11:41:12 AM
// Design Name:
// Module Name: packet_parser
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
 
module pkt_sender (
        input wire clk,
        input wire rst,

        input wire [512+32-1 + 1: 0] pkt_rx_TDATA,  //metadata + tlast + tdata
        input wire                pkt_rx_TVALID,
        output reg                pkt_rx_TREADY,

        input wire [63:0]    s_axis_tx_status_TDATA,
        input wire           s_axis_tx_status_TVALID,
        output wire          s_axis_tx_status_TREADY,

        output wire [31:0]   m_axis_tx_metadata_TDATA,
        output wire          m_axis_tx_metadata_TVALID,
        input wire           m_axis_tx_metadata_TREADY,
        
        output wire [511:0]  m_axis_tx_data_TDATA,
        output reg           m_axis_tx_data_TVALID,
        output reg [64:0] 	 m_axis_tx_data_TKEEP,
        output wire         	 m_axis_tx_data_TLAST,
        input wire           m_axis_tx_data_TREADY        
    ); 

    wire status_tx_TVALID;
    reg  status_tx_TREADY;
    wire status_tx_TDATA;
    
    //For debug
    wire [31:0] size_metadata;
    assign size_metadata = pkt_rx_TDATA[512 + 32: 512 + 1];

    //FIFO for storing status
    nukv_fifogen #(
        .DATA_SIZE(1),
        .ADDR_BITS(12)
    ) fifo_status (
        .clk(clk),
        .rst(rst),
        .s_axis_tvalid(s_axis_tx_status_TVALID),
        .s_axis_tready(s_axis_tx_status_TREADY),
        .s_axis_tdata(s_axis_tx_status_TDATA[62:62]), // 1'b0: OK 1'b1: Error (Send to closed conn)
        .m_axis_tvalid(status_tx_TVALID),
        .m_axis_tready(status_tx_TREADY),
        .m_axis_tdata(status_tx_TDATA)
    );
    
    /**********/    
    reg [511 + 1:0]  payload_rx_TDATA;
    reg          payload_rx_TVALID;
    wire         payload_rx_TREADY;

    wire         payload_tx_TVALID;
    reg          payload_tx_TREADY;
    
    wire [512: 0] output_tx;
    
    //FIFO for storing payload
    nukv_fifogen #(
        .DATA_SIZE(512 + 1), //tlast + tdata
        .ADDR_BITS(12)
    ) fifo_payload (
        .clk(clk),
        .rst(rst),
        .s_axis_tvalid(payload_rx_TVALID),
        .s_axis_tready(payload_rx_TREADY),
        .s_axis_tdata(payload_rx_TDATA),
        .m_axis_tvalid(payload_tx_TVALID),
        .m_axis_tready(payload_tx_TREADY),
        .m_axis_tdata(output_tx)
    );
    
    assign m_axis_tx_data_TLAST = output_tx[512] && m_axis_tx_data_TVALID;
    assign m_axis_tx_data_TDATA = output_tx[511:0];

    /**********/

    //reg [31:0]  metadata_rx_TDATA;//original 16-bit
    reg         metadata_rx_TVALID;
    wire        metadata_rx_TREADY = 1;
    
    //FIFO for storing metadata
//    nukv_fifogen #(
//        .DATA_SIZE(32),
//        .ADDR_BITS(5)
//    ) fifo_metadata (
//        .clk(clk),
//        .rst(rst),
//        .s_axis_tvalid(metadata_rx_TVALID),
//        .s_axis_tready(metadata_rx_TREADY),
//        .s_axis_tdata({dataSize_metadata, metadata_wire}),
//        .m_axis_tvalid(m_axis_tx_metadata_TVALID),
//        .m_axis_tready(m_axis_tx_metadata_TREADY),
//        .m_axis_tdata(m_axis_tx_metadata_TDATA)
//    ); 
    nukv_fifogen #(
        .DATA_SIZE(32),
        .ADDR_BITS(12)
    ) fifo_metadata (
        .clk(clk),
        .rst(rst),
        .s_axis_tvalid(payload_rx_TVALID && pkt_rx_TDATA[512]),
        .s_axis_tready(metadata_rx_TREADY),
        .s_axis_tdata(size_metadata),
        .m_axis_tvalid(m_axis_tx_metadata_TVALID),
        .m_axis_tready(m_axis_tx_metadata_TREADY),
        .m_axis_tdata(m_axis_tx_metadata_TDATA)
    );   
    /**********/



   /**Counter logic for dataline number to send**/
   //This part is to count how many datalines in one packet, to echo back the same size of payload back
//   wire [15:0] metadata_wire;
//   assign metadata_wire = previous_metadata;
//   reg [15:0] current_metadata = 16'hffff;
//   reg [31:0] current_count = 32'h0;
//   reg [31:0] previous_count = 32'h0;
//   reg [15:0] previous_metadata = 16'hffff; 
   
//   always@(posedge clk) begin
//       if(pkt_rx_TVALID) begin
//          current_metadata = metadata_rx_TDATA;
//          if (pkt_rx_TDATA[512] == 1) begin
//            current_count = current_count + 1; // Reset count for new metadata
//            previous_count = current_count;
//            previous_metadata = current_metadata;
//            current_count = 0;
//          end
//          else begin
//            current_count = current_count + 1;
//          end
//       end
//   end


//reg [15:0] dataSize_metadata;
//reg meta_high_TVALID = 0;
///**new metadata clock**/
//always @(posedge clk) begin
//    metadata_rx_TVALID = 0;
//    if(pkt_rx_TVALID && pkt_rx_TDATA[512] == 1) begin
//       meta_high_TVALID = 1;
//    end
//    else if (meta_high_TVALID == 1) begin
//       metadata_rx_TVALID = 1;
//       meta_high_TVALID = 0;
//    end
//end


reg payload_tx_ready_hold = 0; // Register to hold the state of payload_tx_TREADY

always @(posedge clk) begin
    if (status_tx_TREADY) begin
        // Set the hold register high when status_tx_TREADY is high
        payload_tx_ready_hold <= 1'b1;
    end else if (output_tx[512] == 1) begin
        // Reset the hold register when TLAST is 1
        payload_tx_ready_hold <= 1'b0;
    end
end

reg m_axis_tx_data_TVALID_inst = 0;
always @(*) begin
    //metadata_rx_TDATA = pkt_rx_TDATA[512+16-1 + 1 : 512 + 1]; // Packet Size: 64 Byte
    payload_rx_TDATA = pkt_rx_TDATA[511 + 1:0]; //tlast + tdata
    pkt_rx_TREADY = metadata_rx_TREADY & payload_rx_TREADY;
    payload_rx_TVALID = pkt_rx_TREADY & pkt_rx_TVALID;
    m_axis_tx_data_TKEEP = 64'hFFFFFFFFFFFFFFFFF;
    //dataSize_metadata = previous_count * 16'd64;
   
    if (status_tx_TVALID == 1'b1 && payload_tx_TVALID == 1'b1 && status_tx_TDATA == 1'b1) begin //Payload sent the same time as status
        // exception handler: sent to closed connection
        // discard payload and status
        m_axis_tx_data_TVALID = 1'b0;
        status_tx_TREADY = 1'b1;
        payload_tx_TREADY = 1'b1;
    end else begin
        m_axis_tx_data_TVALID_inst = status_tx_TVALID & payload_tx_TVALID;
        status_tx_TREADY = m_axis_tx_data_TVALID_inst & m_axis_tx_data_TREADY;
        payload_tx_TREADY = payload_tx_ready_hold;
        m_axis_tx_data_TVALID = payload_tx_TVALID & payload_tx_TREADY;
    end 
end

endmodule
