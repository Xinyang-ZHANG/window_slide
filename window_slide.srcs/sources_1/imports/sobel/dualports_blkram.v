`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/13 21:23:14
// Design Name: 
// Module Name: dualports_blkram
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


module dualports_blkram#(   
    parameter       WRITE_DATA_DEPTH_A  = 2048,
    parameter       WRITE_DATA_DEPTH_B  = 2048,
    parameter       WRITE_DATA_WIDTH_A  = 16,                           //positive integer
    parameter       READ_DATA_WIDTH_B   = 16,                           //positive integer
    parameter       ADDR_WIDTH_A        = $clog2(WRITE_DATA_DEPTH_A),   //positive integer
    parameter       ADDR_WIDTH_B        = $clog2(WRITE_DATA_DEPTH_B),   //positive integer
    parameter       MEMORY_PRIMITIVE    = "block",                  //string; "auto", "distributed", "block" or "ultra";,
    parameter       CLOCKING_MODE       = "independent_clock",    //string; "common_clock", "independent_clock" 
    parameter       READ_LATENCY        = 1,
    parameter       WRITE_MODE          = "no_change"               //string; "write_first", "read_first", "no_change" 
)(
    input                               clka,
    input                               wea,
    input   [ADDR_WIDTH_A-1 : 0]        addra,
    input   [WRITE_DATA_WIDTH_A-1 : 0]  dina,
    
    input                               clkb,
    input                               rstb,
    input   [ADDR_WIDTH_B-1 : 0]        addrb,
    output  [READ_DATA_WIDTH_B-1 : 0]   doutb
    );
    
    localparam      MEMORY_SIZE         = WRITE_DATA_DEPTH_A * WRITE_DATA_WIDTH_A;
    localparam      BYTE_WRITE_WIDTH_A  = WRITE_DATA_WIDTH_A;                           //integer; 8, 9, or WRITE_DATA_WIDTH_A value
    
    /*
    XPM_MEMORY instantiation template for simple dual port RAM configurations
    Refer to the targeted device family architecture libraries guide for XPM_MEMORY documentation
    =======================================================================================================================
    
    Parameter usage table, organized as follows:
    +---------------------------------------------------------------------------------------------------------------------+
    | Parameter name          | Data type          | Restrictions, if applicable                                          |
    |---------------------------------------------------------------------------------------------------------------------|
    | Description                                                                                                         |
    +---------------------------------------------------------------------------------------------------------------------+
    +---------------------------------------------------------------------------------------------------------------------+
    | MEMORY_SIZE             | Integer            | Must be integer multiple of [WRITE|READ]_DATA_WIDTH_[A|B]            |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify the total memory array size, in bits.                                                                       |
    | For example, enter 65536 for a 2kx32 RAM.                                                                           |
    | When ECC is enabled and set to "encode_only", then the memory size has to be multiples of READ_DATA_WIDTH_B         |
    | When ECC is enabled and set to "decode_only", then the memory size has to be multiples of WRITE_DATA_WIDTH_A        |
    +---------------------------------------------------------------------------------------------------------------------+
    | MEMORY_PRIMITIVE        | String             | Must be "auto", "distributed", "block" or "ultra"                    |
    |---------------------------------------------------------------------------------------------------------------------|
    | Designate the memory primitive (resource type) to use:                                                              |
    |   "auto": Allow Vivado Synthesis to choose                                                                          |
    |   "distributed": Distributed memory                                                                                 |
    |   "block": Block memory                                                                                             |
    |   "ultra": Ultra RAM memory                                                                                         |
    +---------------------------------------------------------------------------------------------------------------------+
    | CLOCKING_MODE           | String             | Must be "common_clock" or "independent_clock"                        |
    |---------------------------------------------------------------------------------------------------------------------|
    | Designate whether port A and port B are clocked with a common clock or with independent clocks:                     |
    |   "common_clock": Common clocking; clock both port A and port B with clka                                           |
    |   "independent_clock": Independent clocking; clock port A with clka and port B with clkb                            |
    +---------------------------------------------------------------------------------------------------------------------+
    | MEMORY_INIT_FILE        | String             | Must be exactly "none" or the name of the file (in quotes)           |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify "none" (including quotes) for no memory initialization, or specify the name of a memory initialization file:|
    |   Enter only the name of the file with .mem extension, including quotes but without path (e.g. "my_file.mem").      |
    |   File format must be ASCII and consist of only hexadecimal values organized into the specified depth by            |
    |   narrowest data width generic value of the memory.  See the Memory File (MEM) section for more                     |
    |   information on the syntax. Initialization of memory happens through the file name specified only when parameter   |
    |   MEMORY_INIT_PARAM value is equal to "".                                                                           |
    |   When using XPM_MEMORY in a project, add the specified file to the Vivado project as a design source.              |
    +---------------------------------------------------------------------------------------------------------------------+
    | MEMORY_INIT_PARAM       | String             | Must be exactly "" or the string of hex characters (in quotes)       |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify "" or "0" (including quotes) for no memory initialization through parameter, or specify the string          |
    | containing the hex characters.Enter only hex characters and each location separated by delimiter(,).                |
    | Parameter format must be ASCII and consist of only hexadecimal values organized into the specified depth by         |
    | narrowest data width generic value of the memory.  For example, if the narrowest data width is 8, and the depth of  |
    | memory is 8 locations, then the parameter value should be passed as shown below.                                    |
    |   parameter MEMORY_INIT_PARAM = "AB,CD,EF,1,2,34,56,78"                                                             |
    |                                  |                   |                                                              |
    |                                  0th                7th                                                             |
    |                                location            location                                                         |
    +---------------------------------------------------------------------------------------------------------------------+
    | USE_MEM_INIT            | Integer             | Must be 0 or 1                                                      |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify 1 to enable the generation of below message and 0 to disable the generation of below message completely.    |
    | Note: This message gets generated only when there is no Memory Initialization specified either through file or      |
    | Parameter.                                                                                                          |
    |    INFO : MEMORY_INIT_FILE and MEMORY_INIT_PARAM together specifies no memory initialization.                       |
    |    Initial memory contents will be all 0's                                                                          |
    +---------------------------------------------------------------------------------------------------------------------+
    | WAKEUP_TIME             | String             | Must be "disable_sleep" or "use_sleep_pin"                           |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify "disable_sleep" to disable dynamic power saving option, and specify "use_sleep_pin" to enable the           |
    | dynamic power saving option                                                                                         |
    +---------------------------------------------------------------------------------------------------------------------+
    | MESSAGE_CONTROL         | Integer            | Must be 0 or 1                                                       |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify 1 to enable the dynamic message reporting such as collision warnings, and 0 to disable the message reporting|
    +---------------------------------------------------------------------------------------------------------------------+
    | USE_EMBEDDED_CONSTRAINT | Integer            | Must be 0 or 1                                                       |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify 1 to enable the set_false_path constraint addition between clka of Distributed RAM and doutb_reg on clkb    |
    +---------------------------------------------------------------------------------------------------------------------+
    | MEMORY_OPTIMIZATION     | String             | Must be "true" or "false"                                            |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify "false" to disable the optimization of unused memory or bits in the memory structure                        |
    +---------------------------------------------------------------------------------------------------------------------+
    | WRITE_DATA_WIDTH_A      | Integer            | Must be > 0                                                          |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify the width of the port A write data input port dina, in bits.                                                |
    | When ECC is enabled and set to "encode_only" or "both_encode_and_decode", then WRITE_DATA_WIDTH_A has to be         |
    | multiples of 64-bits                                                                                                |
    | When ECC is enabled and set to "decode_only", then WRITE_DATA_WIDTH_A has to be multiples of 72-bits                |
    +---------------------------------------------------------------------------------------------------------------------+
    | BYTE_WRITE_WIDTH_A      | Integer            | Must be 8, 9, or the value of WRITE_DATA_WIDTH_A                     |
    |---------------------------------------------------------------------------------------------------------------------|
    | To enable byte-wide writes on port A, specify the byte width, in bits:                                              |
    |   8: 8-bit byte-wide writes, legal when WRITE_DATA_WIDTH_A is an integer multiple of 8                              |
    |   9: 9-bit byte-wide writes, legal when WRITE_DATA_WIDTH_A is an integer multiple of 9                              |
    | Or to enable word-wide writes on port A, specify the same value as for WRITE_DATA_WIDTH_A.                          |
    +---------------------------------------------------------------------------------------------------------------------+
    | ADDR_WIDTH_A            | Integer            | Must be >= ceiling of log2(MEMORY_SIZE/WRITE_DATA_WIDTH_A)           |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify the width of the port A address port addra, in bits.                                                        |
    | Must be large enough to access the entire memory from port A, i.e. >= $clog2(MEMORY_SIZE/WRITE_DATA_WIDTH_A).       |
    +---------------------------------------------------------------------------------------------------------------------+
    | READ_DATA_WIDTH_B       | Integer            | Must be > 0                                                          |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify the width of the port B read data output port doutb, in bits.                                               |
    | When ECC is enabled and set to "encode_only", then READ_DATA_WIDTH_B has to be multiples of 72-bits                 |
    | When ECC is enabled and set to "decode_only" or "both_encode_and_decode", then READ_DATA_WIDTH_B has to be          |
    | multiples of 64-bits                                                                                                |
    +---------------------------------------------------------------------------------------------------------------------+
    | ADDR_WIDTH_B            | Integer            | Must be >= ceiling of log2(MEMORY_SIZE/READ_DATA_WIDTH_B)            |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify the width of the port B address port addrb, in bits.                                                        |
    | Must be large enough to access the entire memory from port B, i.e. >= $clog2(MEMORY_SIZE/READ_DATA_WIDTH_B).        |
    +---------------------------------------------------------------------------------------------------------------------+
    | READ_RESET_VALUE_B      | String             |                                                                      |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify the reset value of the port B final output register stage in response to rstb input port is assertion.      |
    | As this parameter is a string, please specify the hex values inside double quotes. As an example,                   |
    | If the read data width is 8, then specify READ_RESET_VALUE_B = "EA";                                                |
    | When ECC is enabled, then reset value is not supported                                                              |
    +---------------------------------------------------------------------------------------------------------------------+
    | READ_LATENCY_B          | Integer             | Must be >= 0 for distributed memory, or >= 1 for block memory       |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify the number of register stages in the port B read data pipeline. Read data output to port doutb takes this   |
    | number of clkb cycles (clka when CLOCKING_MODE is "common_clock").                                                  |
    | To target block memory, a value of 1 or larger is required: 1 causes use of memory latch only; 2 causes use of      |
    | output register. To target distributed memory, a value of 0 or larger is required: 0 indicates combinatorial output.|
    | Values larger than 2 synthesize additional flip-flops that are not retimed into memory primitives.                  |
    +---------------------------------------------------------------------------------------------------------------------+
    | WRITE_MODE_B            | String              | Must be "write_first", "read_first", or "no_change".                |
    |                                               | For distributed memory, must be "read_first".                       |
    |---------------------------------------------------------------------------------------------------------------------|
    | Designate the write mode of port B:                                                                                 |
    |   "write_first": Write-first write mode                                                                             |
    |   "read_first": Read-first write mode                                                                               |
    |   "no_change": No-change write mode                                                                                 |
    | Distributed memory configurations require read-first write mode."write_first" mode is compatible only with UltraRAM |
    +---------------------------------------------------------------------------------------------------------------------+
    | ECC_MODE                | String              | Must be "no_ecc", "encode_only", "decode_only"                      |
    |                                               | or "both_encode_and_decode".                                        |
    |---------------------------------------------------------------------------------------------------------------------|
    | Specify ECC mode on both ports of the memory primitive                                                              |
    +---------------------------------------------------------------------------------------------------------------------+
    | AUTO_SLEEP_TIME         | Integer             | Must be 0 or 3-15                                                   |
    |---------------------------------------------------------------------------------------------------------------------|
    | Number of clk[a|b] cycles to auto-sleep, if feature is available in architecture                                    |
    |   0 : Disable auto-sleep feature                                                                                    |
    |   3-15 : Number of auto-sleep latency cycles                                                                        |
    |   Do not change from the value provided in the template instantiation                                               |
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
    | sleep signal to enable the dynamic power saving feature.                                                            |
    +---------------------------------------------------------------------------------------------------------------------+
    | clka           | Input     | 1                                     |        | Rising edge | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Clock signal for port A. Also clocks port B when parameter CLOCKING_MODE is "common_clock".                         |
    +---------------------------------------------------------------------------------------------------------------------+
    | ena            | Input     | 1                                     | clka   | Active-high | Tie to 1'b1             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Memory enable signal for port A.                                                                                    |
    | Must be high on clock cycles when write operations are initiated. Pipelined internally.                             |
    +---------------------------------------------------------------------------------------------------------------------+
    | wea            | Input     | WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A | clka   | Active-high | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Write enable vector for port A input data port dina. 1 bit wide when word-wide writes are used.                     |
    | In byte-wide write configurations, each bit controls the writing one byte of dina to address addra.                 |
    | For example, to synchronously write only bits [15:8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be 4'b0010.   |
    +---------------------------------------------------------------------------------------------------------------------+
    | addra          | Input     | ADDR_WIDTH_A                          | clka   |             | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Address for port A write operations.                                                                                |
    +---------------------------------------------------------------------------------------------------------------------+
    | dina           | Input     | WRITE_DATA_WIDTH_A                    | clka   |             | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Data input for port A write operations.                                                                             |
    +---------------------------------------------------------------------------------------------------------------------+
    | injectsbiterra | Input     | 1                                     | clka   | Active-high | Tie to 1'b0             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Controls single bit error injection on input data when ECC enabled (Error injection capability is not available in  |
    | "decode_only" mode).                                                                                                |
    +---------------------------------------------------------------------------------------------------------------------+
    | injectdbiterra | Input     | 1                                     | clka   | Active-high | Tie to 1'b0             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Controls double bit error injection on input data when ECC enabled (Error injection capability is not available in  |
    | "decode_only" mode).                                                                                                |
    +---------------------------------------------------------------------------------------------------------------------+
    | clkb           | Input     | 1                                     |        | Rising edge | Tie to 1'b0             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Clock signal for port B when parameter CLOCKING_MODE is "independent_clock".                                        |
    | Unused when parameter CLOCKING_MODE is "common_clock".                                                              |
    +---------------------------------------------------------------------------------------------------------------------+
    | rstb           | Input     | 1                                     | *      | Active-high | Tie to 1'b0             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Reset signal for the final port B output register stage.                                                            |
    | Synchronously resets output port doutb to the value specified by parameter READ_RESET_VALUE_B.                      |
    +---------------------------------------------------------------------------------------------------------------------+
    | enb            | Input     | 1                                     | *      | Active-high | Tie to 1'b1             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Memory enable signal for port B.                                                                                    |
    | Must be high on clock cycles when read operations are initiated. Pipelined internally.                              |
    +---------------------------------------------------------------------------------------------------------------------+
    | regceb         | Input     | 1                                     | *      | Active-high | Tie to 1'b1             |
    |---------------------------------------------------------------------------------------------------------------------|
    | Clock Enable for the last register stage on the output data path.                                                   |
    +---------------------------------------------------------------------------------------------------------------------+
    | addrb          | Input     | ADDR_WIDTH_B                          | *      |             | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Address for port B read operations.                                                                                 |
    +---------------------------------------------------------------------------------------------------------------------+
    | doutb          | Output    | READ_DATA_WIDTH_B                     | *      |             | Required                |
    |---------------------------------------------------------------------------------------------------------------------|
    | Data output for port B read operations.                                                                             |
    +---------------------------------------------------------------------------------------------------------------------+
    | sbiterrb       | Output    | 1                                     | *      | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Status signal to indicate single bit error occurrence on the data output of port B.                                 |
    +---------------------------------------------------------------------------------------------------------------------+
    | dbiterrb       | Output    | 1                                     | *      | Active-high | Leave open              |
    |---------------------------------------------------------------------------------------------------------------------|
    | Status signal to indicate double bit error occurrence on the data output of port B.                                 |
    +---------------------------------------------------------------------------------------------------------------------+
    | * clka when parameter CLOCKING_MODE is "common_clock". clkb when parameter CLOCKING_MODE is "independent_clock".    |
    +---------------------------------------------------------------------------------------------------------------------+
    */
    
    //  xpm_memory_sdpram   : In order to incorporate this function into the design, the following instance declaration
    //       Verilog        : needs to be placed in the body of the design code.  The default values for the parameters
    //       instance       : may be changed to meet design requirements.  The instance name (xpm_memory_sdpram)
    //     declaration      : and/or the port declarations within the parenthesis may be changed to properly reference and
    //         code         : connect this function to the design.  All inputs and outputs must be connected.
    
    //  <--Cut the following instance declaration and paste it into the design-->
    
    // xpm_memory_sdpram: Simple Dual Port RAM
    // Xilinx Parameterized Macro, Version 2017.4
    xpm_memory_sdpram # (
    
      // Common module parameters
      .MEMORY_SIZE             (MEMORY_SIZE),            //positive integer
      .MEMORY_PRIMITIVE        (MEMORY_PRIMITIVE),          //string; "auto", "distributed", "block" or "ultra";
      .CLOCKING_MODE           (CLOCKING_MODE),  //string; "common_clock", "independent_clock" 
      .MEMORY_INIT_FILE        ("none"),          //string; "none" or "<filename>.mem" 
      .MEMORY_INIT_PARAM       (""    ),          //string;
      .USE_MEM_INIT            (1),               //integer; 0,1
      .WAKEUP_TIME             ("disable_sleep"), //string; "disable_sleep" or "use_sleep_pin" 
      .MESSAGE_CONTROL         (0),               //integer; 0,1
      .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
      .AUTO_SLEEP_TIME         (0),               //Do not Change
      .USE_EMBEDDED_CONSTRAINT (0),               //integer: 0,1
      .MEMORY_OPTIMIZATION     ("true"),          //string; "true", "false" 
    
      // Port A module parameters
      .WRITE_DATA_WIDTH_A      (WRITE_DATA_WIDTH_A),              //positive integer
      .BYTE_WRITE_WIDTH_A      (BYTE_WRITE_WIDTH_A),              //integer; 8, 9, or WRITE_DATA_WIDTH_A value
      .ADDR_WIDTH_A            (ADDR_WIDTH_A),               //positive integer
    
      // Port B module parameters
      .READ_DATA_WIDTH_B       (READ_DATA_WIDTH_B),              //positive integer
      .ADDR_WIDTH_B            (ADDR_WIDTH_B),               //positive integer
      .READ_RESET_VALUE_B      ("0"),             //string
      .READ_LATENCY_B          (READ_LATENCY),               //non-negative integer
      .WRITE_MODE_B            (WRITE_MODE)      //string; "write_first", "read_first", "no_change" 
    
    ) xpm_memory_sdpram_inst (
    
      // Common module ports
      .sleep                   (1'b0),
    
      // Port A module ports
      .clka                    (clka),
      .ena                     (1'b1),
      .wea                     (wea),
      .addra                   (addra),
      .dina                    (dina),
      .injectsbiterra          (1'b0),
      .injectdbiterra          (1'b0),
    
      // Port B module ports
      .clkb                    (clkb),
      .rstb                    (rstb),
      .enb                     (1'b1),
      .regceb                  (1'b1),
      .addrb                   (addrb),
      .doutb                   (doutb),
      .sbiterrb                (),
      .dbiterrb                ()
    
    );
    // End of xpm_memory_sdpram instance declaration
    
endmodule
