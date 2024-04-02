`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/24 11:47:35
// Design Name: 
// Module Name: window_slide_simp
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


module window_slide_simp#(
    parameter       IMAGE_LENGTH    = 1280,
    parameter       IMAGE_WIDTH     = 720,
    parameter       WINDOW_SIZE     = 3,
    parameter       DATA_WIDTH      = 8,
    parameter       PAD_EN          = 0
)(
input                       clk,
input                       rst,
input                       din_en,
input   [DATA_WIDTH-1:0]    din,
output  reg                dout_en,
output  reg [WINDOW_SIZE*WINDOW_SIZE*DATA_WIDTH-1:0]    dout
);

genvar  i,j;

reg  [15:0]    h_cnt;
reg  [15:0]    v_cnt;

wire [DATA_WIDTH-1:0]     ram_x_in        [WINDOW_SIZE-2:0]   ;
wire                      ram_x_wr_en     [WINDOW_SIZE-2:0]   ;
reg  [15:0]             ram_x_wr_addr   [WINDOW_SIZE-2:0]   ;
wire                      ram_x_rd_en     [WINDOW_SIZE-2:0]   ;
reg  [15:0]             ram_x_rd_addr   [WINDOW_SIZE-2:0]   ;
wire [DATA_WIDTH-1:0]     ram_x_out       [WINDOW_SIZE-2:0]   ;

//[0,0] <= din, [i][0] <= ram_x_out[i-1], [i][j] <= [i][j-1]
reg  [DATA_WIDTH-1:0]   window_data       [WINDOW_SIZE-1:0][WINDOW_SIZE-1:0]   ;

//main counter
always@(posedge clk)begin
if(rst)begin
    h_cnt <= 16'd0;
end else if(din_en) begin
    if(h_cnt == IMAGE_LENGTH - 1'b1)
        h_cnt <= 16'd0;
    else 
        h_cnt <= h_cnt + 16'd1;
end
end

always@(posedge clk)begin
if(rst)begin
    v_cnt <= 16'd0;
end else if(h_cnt == IMAGE_LENGTH - 1'b1) begin
    if(v_cnt == IMAGE_WIDTH - 1'b1)
        v_cnt <= 16'd0;
    else 
        v_cnt <= v_cnt + 16'd1;
end
end

generate
//data matrix
for(i=0; i<WINDOW_SIZE; i=i+1) begin
    if(i==0) begin
        for(j=0; j<WINDOW_SIZE; j=j+1) begin
            if(j==0) begin
                always@(*)           window_data[i][j]  <= din;
            end else begin
                always@(posedge clk) window_data[i][j]  <= window_data[i][j-1];
            end
        end
    end else begin
        for(j=0; j<WINDOW_SIZE; j=j+1) begin
            if(j==0) begin
                always@(*)           window_data[i][j]  <= ram_x_out[i-1];
            end else begin
                always@(posedge clk) window_data[i][j]  <= window_data[i][j-1];
            end
        end
    end
end
//line buffer
for(i=0; i<WINDOW_SIZE-1; i=i+1) begin
    //ram control
    if(i==0) begin
        assign ram_x_in[i]       = din;
        assign ram_x_wr_en[i]  = (v_cnt < IMAGE_WIDTH - 1) ? din_en : 1'b0;
        assign ram_x_rd_en[i]  = (v_cnt > 0) ? din_en : 1'b0;
    end else begin
        assign ram_x_in[i]       = ram_x_out[i-1];     // cascade ram
        assign ram_x_wr_en[i]  = ram_x_rd_en[i-1];
        assign ram_x_rd_en[i]  = (v_cnt > i) ? din_en : 1'b0;
    end
    always@(posedge clk) begin  //wr addr
        if(rst) begin
            ram_x_wr_addr[i]    <= 0;
        end else if(ram_x_wr_en[i]) begin
            if(ram_x_wr_addr[i] == IMAGE_LENGTH-1)
                ram_x_wr_addr[i]    <= 0;
            else
                ram_x_wr_addr[i]    <= ram_x_wr_addr[i] + 1;
        end 
    end
    always@(posedge clk) begin  //rd addr
        if(rst) begin
            ram_x_rd_addr[i]    <= 0;
        end if(ram_x_rd_en[i]) begin
            if(ram_x_rd_addr[i] == IMAGE_LENGTH-1)
                ram_x_rd_addr[i]    <= 0;
            else
                ram_x_rd_addr[i]    <= ram_x_rd_addr[i] + 1;
        end
    end
    //line buffer
    dualports_blkram#(   
        .WRITE_DATA_DEPTH_A (IMAGE_LENGTH),
        .WRITE_DATA_DEPTH_B (IMAGE_LENGTH),
        .WRITE_DATA_WIDTH_A (DATA_WIDTH),                           //positive integer
        .READ_DATA_WIDTH_B  (DATA_WIDTH),                           //positive integer
        .MEMORY_PRIMITIVE   ("distributed"),                  //string; "auto", "distributed", "block" or "ultra";,
        .CLOCKING_MODE      ("common_clock"),    //string; "common_clock", "independent_clock" 
        .READ_LATENCY       (0),
        .WRITE_MODE         ("no_change")               //string; "write_first", "read_first", "no_change" 
    )linebuf_ramx(
        .clka   (clk),
        .wea    (ram_x_wr_en[i]),
        .addra  (ram_x_wr_addr[i]),
        .dina   (ram_x_in[i]),
            
        .clkb   (clk),
        .rstb   (0),
        .addrb  (ram_x_rd_addr[i]),
        .doutb  (ram_x_out[i])  
    );
end
endgenerate

generate
if(PAD_EN)  always@(posedge clk)    dout_en     <= din_en;  //include pad(up WINDOW_SIZE-1 more and left WINDOW_SIZE-1 more) and control circuit is more simplified£¬
else        always@(posedge clk)    dout_en     <= (h_cnt>=WINDOW_SIZE-1 && v_cnt>=WINDOW_SIZE-1) ? din_en : 1'b0;  
endgenerate

generate
//data matrix out
for(i=0; i<WINDOW_SIZE; i=i+1) begin
    for(j=0; j<WINDOW_SIZE; j=j+1) begin
        always@(posedge clk)    dout[(i*WINDOW_SIZE+j)*DATA_WIDTH +: DATA_WIDTH]    <= window_data[i][j];
    end
end
endgenerate

endmodule
