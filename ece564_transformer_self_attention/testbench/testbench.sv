/***********************************************
*
* NAME        : testbench.sv
* AUTHOR      : Prasanth Prabu Ravichandiran
* EMAIL       : pravich2@ncsu.edu
* AFFILIATION : North Carolina State University, Raleigh, NC.
* 
* DESCRIPTION : This module is used to test the mini project for ECE564  
*               for a single matrix multiplication.  
*             
*
* NOTES:
*
* REVISION HISTORY
*    Date         Programmer        Description
*    01/22/2024   Prasanth Prabu    TB for matrix multiplication
*
************************************************/
`include "common.vh"

module tb_top();


  parameter CLK_PHASE=6.75;
  parameter ADDR_464=12'h000;
  parameter MAX_ROUNDS=200;
  
  typedef enum logic [1:0] {INTEGER, FLOATING_POINT} e_data_format;
  e_data_format data_format=INTEGER;

  // Evaluation variables
  time computeCycle;
  event computeStart;
  event computeEnd;
  event checkFinish;
  time startTime;
  time endTime;

  // Testbench control variables
  event simulationStart;
  event testStart;
  integer totalNumOfCases=0;
  integer totalNumOfPasses=0;
  real epsilon_mult=1.0;          // Overridden by Makefile
  shortreal result;
  integer info_level=0;

  
  // Testbench configuration variables 
  string input_dir;               // Overridden by Makefile
  string output_dir;              // Overridden by Makefile
  integer rounds=1;
  integer timeout=100000000;      // Overridden by Makefile 
  integer num_of_testcases = 1;   // Overridden by Makefile
  integer test_mode = 1;
  integer test_number = 2;

  bit  [31:0 ]     mem            [int] ;
  bit  [31:0 ]     mem_input      [int] ;
  bit  [31:0 ]     mem_weight     [int] ;

  integer num_results=72;
  int correctResult[MAX_ROUNDS];
  reg [15:0] result_array[int];
  reg [15:0] golden_result_array[int];
  int i;
  int j;
  int k;
  int q;
  int p;

  integer num_of_result_elements = 0;
  integer num_of_matching_result_elements = 0;
  //---------------------------------------------------------------------------
  // General
  //
  reg                                   clk            ;
  reg                                   reset_n        ;
  reg                                   dut_valid        ;
  wire                                  dut_ready       ;
  
  //--------------------------------------------------------------------------
  //---------------------- sram_input ---------------------------------------------
  wire                                  dut__tb__sram_input_write_enable  ;
  wire [`SRAM_ADDR_RANGE    ]           dut__tb__sram_input_write_address ;
  wire [`SRAM_DATA_RANGE    ]           dut__tb__sram_input_write_data    ;
  wire [`SRAM_ADDR_RANGE    ]           dut__tb__sram_input_read_address  ; 
  wire [`SRAM_DATA_RANGE    ]           tb__dut__sram_input_read_data     ;
  
  //---------------------------------------------------------------------------

  //---------------------- sram_weight ---------------------------------------------
  wire                                  dut__tb__sram_weight_write_enable  ;
  wire [`SRAM_ADDR_RANGE    ]           dut__tb__sram_weight_write_address ;
  wire [`SRAM_DATA_RANGE    ]           dut__tb__sram_weight_write_data    ;
  wire [`SRAM_ADDR_RANGE    ]           dut__tb__sram_weight_read_address  ; 
  wire [`SRAM_DATA_RANGE    ]           tb__dut__sram_weight_read_data     ;
  
  //---------------------------------------------------------------------------

  //---------------------- sram_result ---------------------------------------------
  wire                                  dut__tb__sram_result_write_enable  ;
  wire [`SRAM_ADDR_RANGE    ]           dut__tb__sram_result_write_address ;
  wire [`SRAM_DATA_RANGE    ]           dut__tb__sram_result_write_data    ;
  wire [`SRAM_ADDR_RANGE    ]           dut__tb__sram_result_read_address  ; 
  wire [`SRAM_DATA_RANGE    ]           tb__dut__sram_result_read_data     ;
  
  //---------------------------------------------------------------------------

  //---------------------- sram_scratchpad ---------------------------------------------
  wire                                  dut__tb__sram_scratchpad_write_enable  ;
  wire [`SRAM_ADDR_RANGE    ]           dut__tb__sram_scratchpad_write_address ;
  wire [`SRAM_DATA_RANGE    ]           dut__tb__sram_scratchpad_write_data    ;
  wire [`SRAM_ADDR_RANGE    ]           dut__tb__sram_scratchpad_read_address  ; 
  wire [`SRAM_DATA_RANGE    ]           tb__dut__sram_scratchpad_read_data     ;
  
  //---------------------------------------------------------------------------

  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  //SRAM
  //sram for inputs
  sram  #(.ADDR_WIDTH   (`SRAM_ADDR_WIDTH    ),
          .DATA_WIDTH   (`SRAM_DATA_WIDTH    ))
          sram_input_mem  (
          .write_enable ( dut__tb__sram_input_write_enable         ),
          .write_address( dut__tb__sram_input_write_address        ),
          .write_data   ( dut__tb__sram_input_write_data           ), 
          .read_address ( dut__tb__sram_input_read_address         ),
          .read_data    ( tb__dut__sram_input_read_data            ),
          .clk          ( clk                                     )
         );

  //sram for weights
  sram  #(.ADDR_WIDTH   (`SRAM_ADDR_WIDTH    ),
          .DATA_WIDTH   (`SRAM_DATA_WIDTH    ))
          sram_weight_mem  (
          .write_enable ( dut__tb__sram_weight_write_enable         ),
          .write_address( dut__tb__sram_weight_write_address        ),
          .write_data   ( dut__tb__sram_weight_write_data           ), 
          .read_address ( dut__tb__sram_weight_read_address         ),
          .read_data    ( tb__dut__sram_weight_read_data            ),
          .clk          ( clk                                     )
         );

  //sram for inputs
  sram  #(.ADDR_WIDTH   (`SRAM_ADDR_WIDTH    ),
          .DATA_WIDTH   (`SRAM_DATA_WIDTH    ))
          sram_result_mem  (
          .write_enable ( dut__tb__sram_result_write_enable         ),
          .write_address( dut__tb__sram_result_write_address        ),
          .write_data   ( dut__tb__sram_result_write_data           ), 
          .read_address ( dut__tb__sram_result_read_address         ),
          .read_data    ( tb__dut__sram_result_read_data            ),
          .clk          ( clk                                     )
         );

  //sram for scratchpad
  sram  #(.ADDR_WIDTH   (`SRAM_ADDR_WIDTH    ),
          .DATA_WIDTH   (`SRAM_DATA_WIDTH    ))
          sram_scratchpad_mem  (
          .write_enable ( dut__tb__sram_scratchpad_write_enable         ),
          .write_address( dut__tb__sram_scratchpad_write_address        ),
          .write_data   ( dut__tb__sram_scratchpad_write_data           ), 
          .read_address ( dut__tb__sram_scratchpad_read_address         ),
          .read_data    ( tb__dut__sram_scratchpad_read_data            ),
          .clk          ( clk                                     )
         );
//---------------------------------------------------------------------------
// DUT 
//---------------------------------------------------------------------------
  MyDesign dut(
//---------------------------------------------------------------------------
//System signals
          .reset_n                    (reset_n                      ),  
          .clk                        (clk                          ),

//---------------------------------------------------------------------------
//Control signals
          .dut_valid                  (dut_valid                    ), 
          .dut_ready                  (dut_ready                    ),

//---------------------------------------------------------------------------
// SRAM input interface
          .dut__tb__sram_input_write_enable       (dut__tb__sram_input_write_enable     ),
          .dut__tb__sram_input_write_address      (dut__tb__sram_input_write_address    ),
          .dut__tb__sram_input_write_data         (dut__tb__sram_input_write_data       ),
          .dut__tb__sram_input_read_address       (dut__tb__sram_input_read_address     ),
          .tb__dut__sram_input_read_data          (tb__dut__sram_input_read_data        ),

//---------------------------------------------------------------------------
// SRAM weight interface
          .dut__tb__sram_weight_write_enable       (dut__tb__sram_weight_write_enable     ),
          .dut__tb__sram_weight_write_address      (dut__tb__sram_weight_write_address    ),
          .dut__tb__sram_weight_write_data         (dut__tb__sram_weight_write_data       ),
          .dut__tb__sram_weight_read_address       (dut__tb__sram_weight_read_address     ),
          .tb__dut__sram_weight_read_data          (tb__dut__sram_weight_read_data        ),

//---------------------------------------------------------------------------
// SRAM result interface
          .dut__tb__sram_result_write_enable       (dut__tb__sram_result_write_enable     ),
          .dut__tb__sram_result_write_address      (dut__tb__sram_result_write_address    ),
          .dut__tb__sram_result_write_data         (dut__tb__sram_result_write_data       ),
          .dut__tb__sram_result_read_address       (dut__tb__sram_result_read_address     ),
          .tb__dut__sram_result_read_data          (tb__dut__sram_result_read_data        ),

//---------------------------------------------------------------------------
// SRAM scratchpad interface
          .dut__tb__sram_scratchpad_write_enable       (dut__tb__sram_scratchpad_write_enable     ),
          .dut__tb__sram_scratchpad_write_address      (dut__tb__sram_scratchpad_write_address    ),
          .dut__tb__sram_scratchpad_write_data         (dut__tb__sram_scratchpad_write_data       ),
          .dut__tb__sram_scratchpad_read_address       (dut__tb__sram_scratchpad_read_address     ),
          .tb__dut__sram_scratchpad_read_data          (tb__dut__sram_scratchpad_read_data        )
         );

       
  //---------------------------------------------------------------------------
  //  clk
  initial 
    begin
        clk                     = 1'b0;
        forever # CLK_PHASE clk = ~clk;
    end

  //---------------------------------------------------------------------------
  // get runtime args 
  initial
  begin
    #1;
    if($value$plusargs("TIMEOUT=%d",timeout));
    if($value$plusargs("input_dir=%s",input_dir));
    if($value$plusargs("num_of_testcases=%d",num_of_testcases));
    if($value$plusargs("info_level=%d",info_level));
    if($value$plusargs("test_mode=%d",test_mode));
    if($value$plusargs("test_number=%d",test_number));
    $display("INFO: number of testcases: %d",num_of_testcases);
    if($value$plusargs("epsilon_mult=%f",epsilon_mult));

    repeat (5) @(posedge clk);
    ->simulationStart;
    @testStart
    wait_n_clks(timeout);
    $display("###################################");
    $display("             TIMEOUT               ");
    $display("###################################");
    $finish();
  end
  //---------------------------------------------------------------------------
  //---------------------------------------------------------------------------
  // Stimulus

  task wait_n_clks;
    input integer i;
  begin
    repeat(i)
    begin
      wait(clk);
      wait(!clk);
    end
  end
  endtask

  task handshake;
  begin
    wait(!clk);
    dut_valid = 1;
    wait(clk);
    wait(!dut_ready);
    wait(!clk);
    dut_valid = 0;
    wait(clk);
    wait(dut_ready);
    wait(!clk);
    wait(clk);
  end
  endtask

/*
  function void compare_results(integer key);
    shortreal expected_result;
    shortreal dut_result;
    shortreal difference;
    num_of_result_elements ++;
    if (sram_result_mem.mem.exists(key)) begin
      expected_result = (data_format == FLOATING_POINT) ? $bitstoshortreal(mem[key]&32'h7fff_ffff) : mem[key]; //Masking sign bit
      dut_result      = (data_format == FLOATING_POINT) ? $bitstoshortreal(sram_result_mem.mem[key]&32'h7fff_ffff) : sram_result_mem.mem[key]; //Masking sign bit
      difference      = expected_result - dut_result;
      if (difference != 0)  begin
        $display("[%d]:Difference = %7.20f, expected_result = %7.20f, dut_result = %7.20f", key, difference, expected_result, dut_result);
      end
      else begin
        $display("[%d] Result MATCH: expected_result = %d, dut_result = %d", key,expected_result, dut_result);
        num_of_matching_result_elements++;
      end
    end
    else begin
      $display("[%d]: ERROR: SRAM result entry is missing",key);  
    end    
  endfunction : compare_results
*/

function void compare_results(integer key);
    integer expected_result;  // Declare expected_result as an integer
    integer dut_result;       // Declare dut_result as an integer
    integer difference;       // Declare difference as an integer
    num_of_result_elements++;

    if (sram_result_mem.mem.exists(key)) begin
        // Handle data format
        if (data_format == INTEGER) begin
            // Read and interpret values as 32-bit signed integers
            expected_result = mem[key];
            dut_result      = sram_result_mem.mem[key];
        end else begin
            $display("[%d]: ERROR: Unsupported data format for comparison", key);
            return;
        end

        // Calculate difference
        difference = expected_result - dut_result;

        // Explicitly check the difference for correctness
        if (expected_result != dut_result) begin
            // Print the mismatch information
            $display("[%d]: Difference = %d, expected_result = %d, dut_result = %d", 
                     key, difference, expected_result, dut_result);
        end else begin
            // Print match information
            $display("[%d] Result MATCH: expected_result = %d, dut_result = %d", 
                     key, expected_result, dut_result);
            num_of_matching_result_elements++;
        end
    end else begin
        // Key does not exist in the memory
        $display("[%d]: ERROR: SRAM result entry is missing", key);
    end
endfunction : compare_results


  function void check_result(integer testNum);
    shortreal epsilon;
    integer num_of_row_result;
    integer num_of_col_result;
    
    mem.delete();

    epsilon = $bitstoshortreal(64'h3CB0_0000);
    if (data_format == INTEGER) begin
      $readmemh($sformatf("%s/proj_int_test_self_attn_%0d_result.dat",input_dir,testNum), mem);
      $readmemh($sformatf("%s/proj_int_test_self_attn_%0d_input.dat",input_dir,testNum), mem_input);
      $readmemh($sformatf("%s/proj_int_test_self_attn_%0d_weight.dat",input_dir,testNum), mem_weight);
    end
    else if (data_format == FLOATING_POINT) begin
      $readmemh($sformatf("%s/proj_fp_test_%0d_result.dat",input_dir,testNum), mem);
    end
    num_of_row_result = mem_input[0][31:16];
    num_of_col_result = mem_weight[0][15:0];

    $display($sformatf("INFO: reading %s/proj_int_test_self_attn_%0d_result.dat",input_dir,testNum));
    $display($sformatf("INFO: Dimension of result matrix [%d, %d]",num_of_row_result, num_of_col_result));
    
    $display("---------------- Checking the Query matrix result------------------ ",);
    for (int key = 0; key < (num_of_row_result*num_of_col_result); key++) begin
      compare_results(key);
    end

    $display("---------------- Checking the Key matrix result------------------ ",);
    for (int key = (num_of_row_result*num_of_col_result); key < (2*num_of_row_result*num_of_col_result); key++) begin
      compare_results(key);
    end

    $display("---------------- Checking the Value matrix result------------------ ",);
    for (int key = (2*num_of_row_result*num_of_col_result); key < (3*num_of_row_result*num_of_col_result); key++) begin
      compare_results(key);
    end

    $display("---------------- Checking the Score matrix result------------------ ",);
    //for (int key = (3*num_of_row_result*num_of_col_result); key < ((3*num_of_row_result*num_of_col_result)+(num_of_row_result*num_of_row_result)); key++) begin
     // compare_results(key + (3*num_of_row_result*num_of_col_result));
    //end
	for (int key = (3*num_of_row_result*num_of_col_result); key < (3*num_of_row_result*num_of_col_result + num_of_row_result*num_of_row_result); key++) begin
      compare_results(key);
    end
	$display("---------------- Checking the Attention matrix result------------------ ",);
	for (int key = (3*num_of_row_result*num_of_col_result + num_of_row_result*num_of_row_result); key < ((3*num_of_row_result*num_of_col_result + num_of_row_result*num_of_row_result)+num_of_row_result*num_of_col_result); key++) begin
      compare_results(key);
    end
  endfunction : check_result

  task test;
    input integer testNum;
  begin
    
    $display("INFO:LVL0: ######## Running Test: %0d ########",testNum);
    wait_n_clks(10);
    if (data_format == INTEGER) begin
      sram_input_mem.loadMem($sformatf("%s/proj_int_test_self_attn_%0d_input.dat",input_dir,testNum));
      sram_weight_mem.loadMem($sformatf("%s/proj_int_test_self_attn_%0d_weight.dat",input_dir,testNum));
    end
    else if (data_format == FLOATING_POINT) begin
      sram_input_mem.loadMem($sformatf("%s/proj_int_test_self_attn_%0d_input.dat",input_dir,testNum));
      sram_weight_mem.loadMem($sformatf("%s/proj_int_test_self_attn_%0d_weight.dat",input_dir,testNum));
    end
    else begin
      $display("ERROR: UNKNOWN DATA_FORMAT. OPTIONS: %p", data_format);
    end
    sram_result_mem.mem.delete();
    wait_n_clks(10);
    handshake();
    wait_n_clks(10);
    check_result(testNum);
    wait_n_clks(10);
  end
  endtask

  initial
  begin
    wait(simulationStart);
    reset_n = 1;
    wait_n_clks(10);
    reset_n = 0;
    wait_n_clks(20);
    dut_valid = 0;
    wait_n_clks(20);
    reset_n = 1;
    wait_n_clks(20);
    $display("INFO: DONE WITH RESETING DUT");
    ->testStart;
    startTime=$time();
    if (!test_mode) begin
      $display("Running individual test: %d", test_number);
      test(test_number);
    end
    else begin
      for(int i=1;i<num_of_testcases+1;i++)
      begin
        test(i);
      end
    end

    endTime=$time();
    if(num_of_testcases != 0)
    begin
      $display("------------------------------------------------------------------------",);
      $display("INFO: Total number of cases       : %0d",num_of_testcases);
      $display("INFO: Total number of result pass : %0d / %0d",num_of_matching_result_elements, num_of_result_elements);
      $display("INFO: Final pass percentage       : %6.2f",(num_of_matching_result_elements * 100)/num_of_result_elements);
      $display("INFO: Final Time Result           : %0t ns",endTime-startTime);
      $display("INFO: Final Cycle Result          : %0d cycles\n",((endTime-startTime)/CLK_PHASE));
    end
    $finish();
  end
endmodule
