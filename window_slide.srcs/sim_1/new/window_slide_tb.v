`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/18 19:29:20
// Design Name: 
// Module Name: window_slide_tb
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


module window_slide_tb();

    parameter       IMAGE_LENGTH    = 25;
    parameter       IMAGE_WIDTH     = 25;
    parameter       WINDOW_SIZE     = 5;
    parameter       WINDOW_STRIDE   = 2;
    parameter       DATA_WIDTH      = 8;
    parameter       IMAGEL_GAP      = 4;
    parameter       IMAGEW_GAP      = 25*4;

    reg     clk = 0;
    reg     rst = 1;
    reg     [DATA_WIDTH-1:0]       data_generator = 0;
    wire    [DATA_WIDTH-1:0]       dout;
    reg     lv = 0;
    reg     fv = 0;
    wire    lv_o;
    reg     [3:0]       state = 0;
    reg     [11:0]      hsi_cnt = 0;
    reg     [11:0]      vsi_cnt = 0;
    reg     [11:0]      hsi_gapcnt = 0;
    reg     [11:0]      vsi_gapcnt = 0;
    
    initial begin
        #58;
        rst <= 1'b0;
        #10000
        $finish;
    end
    
     /////////////////// data generator二选一 ///////////////////
    //第n行RAM的数据是i=i+1
    always@(posedge clk) begin
        if(rst) begin
            data_generator  <= 0;
            state           <= 0;
            lv         <= 0;
            fv         <= 0;
            hsi_cnt         <= 0;
            vsi_cnt         <= 0;
            hsi_gapcnt      <= 0;
            vsi_gapcnt      <= 0;
        end
        else begin
            //视频使能信号生成
            case(state)
                0:  //列gap
                begin
                    hsi_cnt         <= 0;
                    vsi_cnt         <= 0;
                    hsi_gapcnt      <= 0;
                    if(vsi_gapcnt == IMAGEW_GAP-1) begin
                        lv     <= 1;
                        fv     <= 1;
                        vsi_gapcnt  <= 0;
                        //随机数据
                        //data_generator    <= {$random};
                        data_generator  <= data_generator + 1;  
                        state       <= 1;
                    end else begin
                        lv     <= 0;
                        fv     <= 0;
                        vsi_gapcnt  <= vsi_gapcnt + 1;
                        state       <= 0;
                    end
                end
                1:  //1行行使能
                begin
                    vsi_gapcnt      <= 0;
                    hsi_gapcnt      <= 0;
                    if(hsi_cnt == IMAGE_LENGTH-1) begin
                        lv     <= 0;
                        hsi_cnt     <= 0;
                        if(vsi_cnt == IMAGE_WIDTH-1) begin
                            fv <= 0;
                            vsi_cnt <= 0;
                            state   <= 0;
                        end else begin
                            fv <= 1;
                            vsi_cnt <= vsi_cnt + 1;
                            state   <= 2;
                        end
                    end else begin
                        lv     <= 1;
                        fv     <= 1;
                        hsi_cnt     <= hsi_cnt + 1;
                        vsi_cnt     <= vsi_cnt;
                        state       <= 1;
                    end
                end
                2:  //1行行gap
                begin
                    fv         <= 1;
                    hsi_cnt         <= 0;
                    vsi_cnt         <= vsi_cnt;
                    vsi_gapcnt      <= 0;
                    if(hsi_gapcnt == IMAGEL_GAP-1) begin
                        lv     <= 1;
                        hsi_gapcnt  <= 0;
                        //随机数据
                        //data_generator    <= {$random};
                        data_generator  <= data_generator + 1;  
                        state       <= 1;
                    end else begin
                        lv     <= 0;
                        hsi_gapcnt  <= hsi_gapcnt + 1;
                        state       <= 2;
                    end
                end
            endcase
         end
     end
    
    /////////////////// data generator二选一 ///////////////////
    
    always #5 clk <= ~clk;   //10MHz
    
    window_slide #(
        .IMAGE_LENGTH   (IMAGE_LENGTH),
        .IMAGE_WIDTH    (IMAGE_WIDTH),
        .WINDOW_SIZE    (WINDOW_SIZE),
        .WINDOW_STRIDE  (WINDOW_STRIDE),
        .DATA_WIDTH     (DATA_WIDTH),
        .PAD_EN         (0)
    )
    window_slide_uut(
        .clk(clk),
        .rst(rst),
        .din_en(lv),
        .din(data_generator+hsi_cnt),
        .dout_en(),
        .dout()
    );
    
    window_slide_simp #(
        .IMAGE_LENGTH   (IMAGE_LENGTH),
        .IMAGE_WIDTH    (IMAGE_WIDTH),
        .WINDOW_SIZE    (WINDOW_SIZE),
        .DATA_WIDTH     (DATA_WIDTH),
        .PAD_EN         (0)
    )
    window_slide_stride1(
        .clk(clk),
        .rst(rst),
        .din_en(lv),
        .din(data_generator+hsi_cnt),
        .dout_en(),
        .dout()
    );


endmodule
