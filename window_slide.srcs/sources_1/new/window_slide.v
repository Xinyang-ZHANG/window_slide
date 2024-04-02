`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/17 22:46:14
// Design Name: 
// Module Name: window_slide
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


module window_slide#(
    parameter       IMAGE_LENGTH    = 1280,
    parameter       IMAGE_WIDTH     = 720,
    parameter       WINDOW_SIZE     = 4,    
    parameter       WINDOW_STRIDE   = 2,
    parameter       DATA_WIDTH      = 8
)(
    input                       clk,
    input                       rst,
    input                       din_en,
    input   [DATA_WIDTH-1:0]    din,
    output                      dout_en,
    output  [WINDOW_SIZE*WINDOW_SIZE*DATA_WIDTH-1:0]    dout
);

localparam      WRITE_EN    = (IMAGE_LENGTH-1)%WINDOW_STRIDE;
localparam      READ_LEN    = IMAGE_LENGTH/WINDOW_STRIDE+(IMAGE_LENGTH%WINDOW_STRIDE!=0);
localparam      READ_STOP   = IMAGE_LENGTH-1;
localparam      READ_START  = READ_STOP-READ_LEN;     //len=8, size=5, stride=3: read length = 8/3+1 = 3, from addr=1
                                                      //len=7, size=5, stride=2: read length = 7/2+1 = 4, from addr=0
                                                      //len=6, size=2, stride=2, read length = 6/2+0 = 3, from addr=1 ......
localparam      OUT_START   = WINDOW_SIZE/WINDOW_STRIDE-(WINDOW_SIZE%WINDOW_STRIDE==0);     //size=5, stride=2, leaving the first 2 outputs disabled
                                                                                            //size=4. stride=2, leaving the first 1 outputs disabled
                                                                                            //size=2, stride=2, all enabled

genvar  i,j;

reg  [15:0]	            h_cnt;
reg  [15:0]	            v_cnt, v_cnt_d;  //ram_x_rd_en has 1 cycle delay
reg  [ 2:0]             stride_h_cnt;
reg  [ 2:0]             stride_v_cnt, stride_v_cnt_d;

wire 		             ram_x_wr_en     [WINDOW_SIZE-1:0]   ;
reg  [15:0]             ram_x_wr_addr   [WINDOW_SIZE-1:0]   ;
reg 		             ram_x_rd_en     [WINDOW_SIZE-1:0]   ;
reg  [15:0]             ram_x_rd_addr   [WINDOW_SIZE-1:0]   ;
wire [DATA_WIDTH-1:0]	 ram_x_out       [WINDOW_SIZE-1:0][WINDOW_STRIDE-1:0]    ;

//[0,0] <= din, [i][0] <= ram_x_out[i-1], [i][j] <= [i][j-1]
reg  [DATA_WIDTH-1:0]   din_dx            [WINDOW_SIZE-1:0][WINDOW_STRIDE-1:0]   ;
reg  [DATA_WIDTH-1:0]   window_data       [WINDOW_SIZE-1:0][WINDOW_SIZE-1:0]    ;

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
        stride_h_cnt <= 3'd0;
    end else if(din_en && (h_cnt < READ_STOP)) begin
		if(stride_h_cnt == WINDOW_STRIDE - 1'b1)
			stride_h_cnt <= 3'd0;
		else 
			stride_h_cnt <= stride_h_cnt + 3'd1;
    end else begin
        stride_h_cnt <= 3'd0;
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

always@(posedge clk)begin
    if(rst)begin
        stride_v_cnt <= 3'd0;
    end else if(h_cnt == IMAGE_LENGTH - 1'b1) begin
		if(stride_v_cnt == WINDOW_STRIDE - 1'b1)
			stride_v_cnt <= 3'd0;
		else begin
		    if(v_cnt < READ_STOP)
			    stride_v_cnt <= stride_v_cnt + 3'd1;
			else
			    stride_v_cnt <= 3'd0;
	    end
    end 
end

always@(posedge clk)begin
    v_cnt_d         <= v_cnt;
    stride_v_cnt_d  <= stride_v_cnt;
end

generate
    for(i=0; i<WINDOW_SIZE; i=i+1) begin
        //data into ram
        if(i==0) begin
            for(j=0; j<WINDOW_STRIDE; j=j+1) begin    
                if(j==0) begin
                    always@(*)           din_dx[i][j]   <= din;  // (0,0)
                end else begin
                    always@(posedge clk) din_dx[i][j]   <= din_dx[i][j-1];
                end
            end
        end else begin
            for(j=0; j<WINDOW_STRIDE; j=j+1) begin    
                always@(*)              din_dx[i][j]   <= ram_x_out[i-1][j];  // cascade ram (i,stride j)
            end
        end
    end
endgenerate

generate
    for(i=0; i<WINDOW_SIZE; i=i+1) begin
        //data matrix out
        for(j=0; j<WINDOW_SIZE; j=j+1) begin    
            if(j<WINDOW_STRIDE) begin
                always@(*)           window_data[i][j]  <= ram_x_out[i][j];  // cascade ram
            end else begin
                always@(posedge clk) window_data[i][j]  <= window_data[i][j-WINDOW_STRIDE];
            end
        end
    end
endgenerate

generate
    //line buffer(including the 1st line)
    for(i=0; i<WINDOW_SIZE; i=i+1) begin
        //ram control
        if(i==0) begin
            assign               ram_x_wr_en[i]  = (din_en && (stride_h_cnt == WRITE_EN));    // write data into x=STRIDE ram at the last cycle of one stride
            always@(posedge clk) ram_x_rd_en[i] <= (din_en && (h_cnt > READ_START) && (h_cnt <= READ_STOP));     // read data from x=STRIDE ram after the half(STRIDE=2) cycle of one image
        end else begin
            assign               ram_x_wr_en[i]  = ram_x_rd_en[i-1];
            always@(posedge clk) ram_x_rd_en[i] <= (v_cnt >= i) ? (din_en && (h_cnt > READ_START) && (h_cnt <= READ_STOP)) : 1'b0;
        end
        always@(posedge clk) begin  //wr addr
            if(rst) begin
                ram_x_wr_addr[i]    <= 0;
            end else if(ram_x_wr_en[i]) begin
                if(ram_x_wr_addr[i] == READ_LEN-1)
                    ram_x_wr_addr[i]    <= 0;
                else
                    ram_x_wr_addr[i]    <= ram_x_wr_addr[i] + 1;
            end 
        end
        //read in same time
        always@(posedge clk) begin  //rd addr
            if(rst) begin
                ram_x_rd_addr[i]    <= 0;
            end if(ram_x_rd_en[i]) begin
                if(ram_x_rd_addr[i] == READ_LEN-1)
                    ram_x_rd_addr[i]    <= 0;
                else
                    ram_x_rd_addr[i]    <= ram_x_rd_addr[i] + 1;
            end
        end
        //line buffer(i=size, j=stride)(including the 1st line)
        for(j=0; j<WINDOW_STRIDE; j=j+1) begin
            dualports_blkram#(   
                .WRITE_DATA_DEPTH_A (READ_LEN),
                .WRITE_DATA_DEPTH_B (READ_LEN),
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
                .dina   (din_dx[i][j]),
                    
                .clkb   (clk),
                .rstb   (0),
                .addrb  (ram_x_rd_addr[i]),
                .doutb  (ram_x_out[i][j])  
            );
        end
    end
endgenerate

assign    dout_en     = (ram_x_rd_en[0] && ram_x_rd_addr[0]>=OUT_START //horizontal
                         && v_cnt_d>=WINDOW_SIZE-1 && stride_v_cnt_d == WRITE_EN);  //vertical //no pad

generate
    //data matrix out
    for(i=0; i<WINDOW_SIZE; i=i+1) begin
        for(j=0; j<WINDOW_SIZE; j=j+1) begin
            assign    dout[(i*WINDOW_SIZE+j)*DATA_WIDTH +: DATA_WIDTH]    = window_data[i][j];
        end
    end
endgenerate
    
endmodule
