`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/13 21:28:46
// Design Name: 
// Module Name: async_blkfifo
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


module async_blkfifo#(
    parameter       READ_MODE           = "std",            //string; "std" or "fwft";
    parameter       FIFO_MEMORY_TYPE    = "auto",           //string; "auto", "block", or "distributed";
    parameter       DATA_DEPTH          = 2048,
    parameter       DATA_WIDTH          = 32,
    parameter       DATA_COUNT_WIDTH    = $clog2(DATA_DEPTH-1) //positive integer
)(
    input                           rst,
    output                          ready,
    output                          full,
    output                          empty,
    
    input                           wr_clk,
    input                           wr_req,
    input   [DATA_WIDTH-1:0]        wr_data,
    output  [DATA_COUNT_WIDTH-1:0]  wr_count,
    
    input                           rd_clk,
    input                           rd_req,
    output                          rd_vld,
    output  [DATA_WIDTH-1:0]        rd_data,
    output  [DATA_COUNT_WIDTH-1:0]  rd_count
);
    
    wire        wr_rst_busy, rd_rst_busy;
    reg         rd_req_d1, rd_req_d2;
    
    assign      ready   = ~(wr_rst_busy | rd_rst_busy);
    
    always@(posedge rd_clk) begin
        rd_req_d1       <= rd_req;
        rd_req_d2       <= rd_req_d1;
    end
    
    assign  rd_vld  = rd_req_d1;
    
    
    /*
    XPM_FIFO instantiation template for Asynchronous FIFO configurations
    Refer to the targeted device family architecture libraries guide for XPM_FIFO documentation
    =======================================================================================================================
    
    Parameter usage table, organized as follows:
    +---------------------------------------------------------------------------------------------------------------------+
    | Parameter name          | Data type          | Restrictions, if applicable                                          |
    |---------------------------------------------------------------------------------------------------------------------|
    | Description                                                                                                         |
    +---------------------------------------------------------------------------------------------------------------------+
    +---------------------------------------------------------------------------------------------------------------------+
    | FIFO_MEMORY_TYPE        | String             | Must be "auto", "block", or "distributed"                            |
    |---------------------------------------------------------------------------------------------------------------------|
    | Designate the fifo memory primitive (resource type) to use:                                                         |
    |   "auto": Allow Vivado Synthesis to choose                                                                          |
    |   "block": Block RAM FIFO                                                                                           |
    |   "distributed": Distributed RAM FIFO                                                                               |
    +---------------------------------------------------------------------------------------------------------------------+
    | FIFO_WRITE_DEPTH        | Integer            | Must be between 16 and 4194304                                       |
    |---------------------------------------------------------------------------------------------------------------------|
    | Defines the FIFO Write Depth, must be power of two                                                                  |
    | In standard READ_MODE, the effective depth = FIFO_WRITE_DEPTH-1                                                     |
    | In First-Word-Fall-Through READ_MODE, the effective depth = FIFO_WRITE_DEPTH+1                                      |
    +---------------------------------------------------------------------------------------------------------------------+
    | RELATED_CLOCKS          | Integer            | Must be 0 or 1                                                       |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specifies if the wr_clk and rd_clk are related having the same source but different clock ratios                    |
    +---------------------------------------------------------------------------------------------------------------------+
    | WRITE_DATA_WIDTH        | Integer            | Must be between 1 and 4096                                           |
    |---------------------------------------------------------------------------------------------------------------------|
    | Defines the width of the write data port, din                                                                       |
    +---------------------------------------------------------------------------------------------------------------------+
    | WR_DATA_COUNT_WIDTH     | Integer            | Must be between 1 and log2(FIFO_WRITE_DEPTH)+1                       |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specifies the width of wr_data_count                                                                                |
    +---------------------------------------------------------------------------------------------------------------------+
    | READ_MODE               | String             | Must be "std" or "fwft"                                              |
    |---------------------------------------------------------------------------------------------------------------------|
    |  "std": standard read mode                                                                                          |
    |  "fwft": First-Word-Fall-Through read mode                                                                          |
    +---------------------------------------------------------------------------------------------------------------------+
    | FIFO_READ_LATENCY       | Integer            | Must be >= 0                                                         |
    |---------------------------------------------------------------------------------------------------------------------|
    |  Number of output register stages in the read data path                                                             |
    |  If READ_MODE = "fwft", then the only applicable value is 0.                                                        |
    +---------------------------------------------------------------------------------------------------------------------+
    | FULL_RESET_VALUE        | Integer            | Must be 0 or 1                                                       |
    |---------------------------------------------------------------------------------------------------------------------|
    |---------------------------------------------------------------------------------------------------------------------|
    |  Sets FULL, PROG_FULL and ALMOST_FULL to FULL_RESET_VALUE during reset                                              |
    +---------------------------------------------------------------------------------------------------------------------+
    | USE_ADV_FEATURES        | String             | Must be between "0000" and "1F1F"                                    |
    |---------------------------------------------------------------------------------------------------------------------|
    |  Enables data_valid, almost_empty, rd_data_count, prog_empty, underflow, wr_ack, almost_full, wr_data_count,        |
    |  prog_full, overflow features                                                                                       |
    |    Setting USE_ADV_FEATURES[0]  to 1 enables overflow flag;     Default value of this bit is 1                      |
    |    Setting USE_ADV_FEATURES[1]  to 1 enables prog_full flag;    Default value of this bit is 1                      |
    |    Setting USE_ADV_FEATURES[2]  to 1 enables wr_data_count;     Default value of this bit is 1                      |
    |    Setting USE_ADV_FEATURES[3]  to 1 enables almost_full flag;  Default value of this bit is 0                      |
    |    Setting USE_ADV_FEATURES[4]  to 1 enables wr_ack flag;       Default value of this bit is 0                      |
    |    Setting USE_ADV_FEATURES[8]  to 1 enables underflow flag;    Default value of this bit is 1                      |
    |    Setting USE_ADV_FEATURES[9]  to 1 enables prog_empty flag;   Default value of this bit is 1                      |
    |    Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count;     Default value of this bit is 1                      |
    |    Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                      |
    |    Setting USE_ADV_FEATURES[12] to 1 enables data_valid flag;   Default value of this bit is 0                      |
    +---------------------------------------------------------------------------------------------------------------------+
    | READ_DATA_WIDTH         | Integer            | Must be between >= 1                                                 |
    |---------------------------------------------------------------------------------------------------------------------|
    | Defines the width of the read data port, dout                                                                       |
    +---------------------------------------------------------------------------------------------------------------------+
    | RD_DATA_COUNT_WIDTH     | Integer            | Must be between 1 and log2(FIFO_READ_DEPTH)+1                        |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specifies the width of rd_data_count                                                                                |
    | FIFO_READ_DEPTH = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH                                                 |
    +---------------------------------------------------------------------------------------------------------------------+
    | CDC_SYNC_STAGES         | Integer            | Must be between 2 to 8                                               |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specifies the number of synchronization stages on the CDC path                                                      |
    | Must be < 5 if FIFO_WRITE_DEPTH = 16                                                                                |
    +---------------------------------------------------------------------------------------------------------------------+
    | ECC_MODE                | String             | Must be "no_ecc" or "en_ecc"                                         |
    |---------------------------------------------------------------------------------------------------------------------|
    | "no_ecc" : Disables ECC                                                                                             |
    | "en_ecc" : Enables both ECC Encoder and Decoder                                                                     |
    +---------------------------------------------------------------------------------------------------------------------+
    | PROG_FULL_THRESH        | Integer            | Must be between "Min_Value" and "Max_Value"                          |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.                    |
    | Min_Value = 3 + (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))+CDC_SYNC_STAGES                                |
    | Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))                             |
    | If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1                                           |
    +---------------------------------------------------------------------------------------------------------------------+
    | PROG_EMPTY_THRESH       | Integer            | Must be between "Min_Value" and "Max_Value"                          |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted                     |
    | Min_Value = 3 + (READ_MODE_VAL*2)                                                                                   |
    | Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2)                                                                |
    | If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1                                           |
    +---------------------------------------------------------------------------------------------------------------------+
    | DOUT_RESET_VALUE        | String             | Must be >="0". Valid hexa decimal value                              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Reset value of read data path.                                                                                      |
    +---------------------------------------------------------------------------------------------------------------------+
    | WAKEUP_TIME             | Integer            | Must be 0 or 2                                                       |
    |---------------------------------------------------------------------------------------------------------------------|
    | 0 : Disable sleep.                                                                                                  |
    | 2 : Use Sleep Pin.                                                                                                  |
    +---------------------------------------------------------------------------------------------------------------------+
    
    Port usage table, organized as follows:
    +---------------------------------------------------------------------------------------------------------------------+
    | Port name      | Direction | Size, in bits                         | Domain | Sense       | Handling if unused      |
    |---------------------------------------------------------------------------------------------------------------------|
    | Description                                                                                                         |
    +---------------------------------------------------------------------------------------------------------------------+
    +---------------------------------------------------------------------------------------------------------------------+
    | sleep          | Input     | 1                                     |        | Active-high | Tie to 1'b0             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.                              |
    | Synchronous to the slower of wr_clk and rd_clk.                                                                     |
    +---------------------------------------------------------------------------------------------------------------------+
    | rst            | Input     | 1                                     | wr_clk | Active-high | Required                |
    +---------------------------------------------------------------------------------------------------------------------+
    | Reset: Must be synchronous to wr_clk. Must be applied only when wr_clk and rd_clk are stable and free-running.      |
    | Once reset is applied to FIFO, the subsequent reset must be applied only when wr_rst_busy becomes zero from one.    |
    +---------------------------------------------------------------------------------------------------------------------+
    | wr_clk         | Input     | 1                                     |        | Rising edge | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Write clock: Used for write operation. wr_clk must be a free running clock.                                         |
    +---------------------------------------------------------------------------------------------------------------------+
    | wr_en          | Input     | 1                                     | wr_clk | Active-high | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO.        |
    | Must be held active-low when rst or wr_rst_busy or rd_rst_busy is active high.                                      |
    +---------------------------------------------------------------------------------------------------------------------+
    | din            | Input     | WRITE_DATA_WIDTH                      | wr_clk |             | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Write Data: The input data bus used when writing the FIFO.                                                          |
    +---------------------------------------------------------------------------------------------------------------------+
    | full           | Output    | 1                                     | wr_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Full Flag: When asserted, this signal indicates that the FIFO is full.                                              |
    | Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive       |
    | to the contents of the FIFO.                                                                                        |
    +---------------------------------------------------------------------------------------------------------------------+
    | overflow       | Output    | 1                                     | wr_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected,              |
    | because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.                      |
    +---------------------------------------------------------------------------------------------------------------------+
    | wr_rst_busy    | Output    | 1                                     | wr_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.                   |
    +---------------------------------------------------------------------------------------------------------------------+
    | almost_full    | Output    | 1                                     | wr_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.|
    +---------------------------------------------------------------------------------------------------------------------+
    | wr_ack         | Output    | 1                                     | wr_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.    |
    +---------------------------------------------------------------------------------------------------------------------+
    | rd_clk         | Input     | 1                                     |        | Rising edge | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Read clock: Used for read operation. rd_clk must be a free running clock.                                           |
    +---------------------------------------------------------------------------------------------------------------------+
    | rd_en          | Input     | 1                                     | rd_clk | Active-high | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO         |
    | Must be held active-low when rst or wr_rst_busy or rd_rst_busy is active high.                                      |
    +---------------------------------------------------------------------------------------------------------------------+
    | dout           | Output    | READ_DATA_WIDTH                       | rd_clk |             | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Read Data: The output data bus is driven when reading the FIFO.                                                     |
    +---------------------------------------------------------------------------------------------------------------------+
    | empty          | Output    | 1                                     | rd_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Empty Flag: When asserted, this signal indicates that the FIFO is empty.                                            |
    | Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.     |
    +---------------------------------------------------------------------------------------------------------------------+
    | underflow      | Output    | 1                                     | rd_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected                     |
    | because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.                                   |
    +---------------------------------------------------------------------------------------------------------------------+
    | rd_rst_busy    | Output    | 1                                     | rd_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.                     |
    +---------------------------------------------------------------------------------------------------------------------+
    | prog_full      | Output    | 1                                     | wr_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal            |
    | to the programmable full threshold value.                                                                           |
    | It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.          |
    +---------------------------------------------------------------------------------------------------------------------+
    | wr_data_count  | Output    | WR_DATA_COUNT_WIDTH                   | wr_clk |             | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Write Data Count: This bus indicates the number of words written into the FIFO.                                     |
    +---------------------------------------------------------------------------------------------------------------------+
    | prog_empty     | Output    | 1                                     | rd_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal              |
    | to the programmable empty threshold value.                                                                          |
    | It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.              |
    +---------------------------------------------------------------------------------------------------------------------+
    | rd_data_count  | Output    | RD_DATA_COUNT_WIDTH                   | rd_clk |             | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Read Data Count: This bus indicates the number of words read from the FIFO.                                         |
    +---------------------------------------------------------------------------------------------------------------------+
    | almost_empty   | Output    | 1                                     | rd_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to|
    | empty.                                                                                                              |
    +---------------------------------------------------------------------------------------------------------------------+
    | data_valid     | Output    | 1                                     | rd_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).        |
    +---------------------------------------------------------------------------------------------------------------------+
    | injectsbiterr  | Intput    | 1                                     | wr_clk | Active-high | Tie to 1'b0             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or                  |
    | built-in FIFO macros.                                                                                               |
    +---------------------------------------------------------------------------------------------------------------------+
    | injectdbiterr  | Intput    | 1                                     | wr_clk | Active-high | Tie to 1'b0             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or                  |
    | built-in FIFO macros.                                                                                               |
    +---------------------------------------------------------------------------------------------------------------------+
    | sbiterr        | Output    | 1                                     | rd_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.                             |
    +---------------------------------------------------------------------------------------------------------------------+
    | dbiterr        | Output    | 1                                     | rd_clk | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
    +---------------------------------------------------------------------------------------------------------------------+
    */
    
    //  xpm_fifo_async      : In order to incorporate this function into the design, the following module instantiation
    //       Verilog        : needs to be placed in the body of the design code.  The default values for the parameters
    //        module        : may be changed to meet design requirements.  The instance name (xpm_fifo_async)
    //     instantiation    : and/or the port declarations within the parenthesis may be changed to properly reference and
    //         code         : connect this function to the design.  All inputs and outputs must be connected, unless
    //                      : otherwise specified.
    
    //  <--Cut the following instance declaration and paste it into the design-->
    
    // xpm_fifo_async: Asynchronous FIFO
    // Xilinx Parameterized Macro, Version 2017.4
    xpm_fifo_async # (
    
      .FIFO_MEMORY_TYPE          (FIFO_MEMORY_TYPE),    //string; "auto", "block", or "distributed";
      .ECC_MODE                  ("no_ecc"),           //string; "no_ecc" or "en_ecc";
      .RELATED_CLOCKS            (0),                   //positive integer; 0 or 1
      .FIFO_WRITE_DEPTH          (DATA_DEPTH),          //positive integer
      .WRITE_DATA_WIDTH          (DATA_WIDTH),          //positive integer
      .WR_DATA_COUNT_WIDTH       (DATA_COUNT_WIDTH),    //positive integer
      .PROG_FULL_THRESH          (10),                  //positive integer
      .FULL_RESET_VALUE          (0),                   //positive integer; 0 or 1
      .USE_ADV_FEATURES          ("0707"),             //string; "0000" to "1F1F"; 
      .READ_MODE                 (READ_MODE),           //string; "std" or "fwft";
      .FIFO_READ_LATENCY         (1),                   //positive integer;
      .READ_DATA_WIDTH           (DATA_WIDTH),          //positive integer
      .RD_DATA_COUNT_WIDTH       (DATA_COUNT_WIDTH),    //positive integer
      .PROG_EMPTY_THRESH         (10),                  //positive integer
      .DOUT_RESET_VALUE          ("0"),                 //string
      .CDC_SYNC_STAGES           (2),                   //positive integer
      .WAKEUP_TIME               (0)                    //positive integer; 0 or 2;
    
    ) xpm_fifo_async_inst (
    
      .rst              (rst),
      .wr_clk           (wr_clk),
      .wr_en            (wr_req),
      .din              (wr_data),
      .full             (full),
      .overflow         (),
      .prog_full        (),
      .wr_data_count    (wr_count),
      .almost_full      (),
      .wr_ack           (),
      .wr_rst_busy      (wr_rst_busy),
      .rd_clk           (rd_clk),
      .rd_en            (rd_req),
      .dout             (rd_data),
      .empty            (empty),
      .underflow        (),
      .rd_rst_busy      (rd_rst_busy),
      .prog_empty       (),
      .rd_data_count    (rd_count),
      .almost_empty     (),
      .data_valid       (),
      .sleep            (1'b0),
      .injectsbiterr    (1'b0),
      .injectdbiterr    (1'b0),
      .sbiterr          (),
      .dbiterr          ()
    
    );
    
    // End of xpm_fifo_async instance declaration
    
endmodule
