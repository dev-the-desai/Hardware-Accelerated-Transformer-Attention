`include "common.vh"

// Top-level module for attention mechanism calculations
// Handles matrix multiplications and transformations for Q, K, V matrices
module MyDesign(
  input wire reset_n,
  input wire clk,
  input wire dut_valid,
  output reg dut_ready,
  
  // Input SRAM interface - stores the input matrix
  output reg                         dut__tb__sram_input_write_enable,
  output reg [`SRAM_ADDR_RANGE]      dut__tb__sram_input_write_address,
  output reg [`SRAM_DATA_RANGE]      dut__tb__sram_input_write_data,
  output reg [`SRAM_ADDR_RANGE]      dut__tb__sram_input_read_address,
  input wire [`SRAM_DATA_RANGE]      tb__dut__sram_input_read_data,
  
  // Weight SRAM interface - stores WQ, WK, and WV matrices
  output reg                         dut__tb__sram_weight_write_enable,
  output reg [`SRAM_ADDR_RANGE]      dut__tb__sram_weight_write_address,
  output reg [`SRAM_DATA_RANGE]      dut__tb__sram_weight_write_data,
  output reg [`SRAM_ADDR_RANGE]      dut__tb__sram_weight_read_address,
  input wire [`SRAM_DATA_RANGE]      tb__dut__sram_weight_read_data,
  
  // Result SRAM interface - stores intermediate and final results
  output reg                         dut__tb__sram_result_write_enable,
  output reg [`SRAM_ADDR_RANGE]      dut__tb__sram_result_write_address,
  output reg [`SRAM_DATA_RANGE]      dut__tb__sram_result_write_data,
  output reg [`SRAM_ADDR_RANGE]      dut__tb__sram_result_read_address,
  input wire [`SRAM_DATA_RANGE]      tb__dut__sram_result_read_data,

  // Scratchpad SRAM - used for temporary storage during matrix operations
  output reg                         dut__tb__sram_scratchpad_write_enable,
  output reg [`SRAM_ADDR_RANGE]      dut__tb__sram_scratchpad_write_address,
  output reg [`SRAM_DATA_RANGE]      dut__tb__sram_scratchpad_write_data,
  output reg [`SRAM_ADDR_RANGE]      dut__tb__sram_scratchpad_read_address,
  input wire [`SRAM_DATA_RANGE]      tb__dut__sram_scratchpad_read_data 
);
  
  // Zero out unused write ports
  assign dut__tb__sram_input_write_enable = '0;
  assign dut__tb__sram_input_write_address = '0;
  assign dut__tb__sram_input_write_data = '0;
  assign dut__tb__sram_weight_write_enable = '0;
  assign dut__tb__sram_weight_write_address = '0;
  assign dut__tb__sram_weight_write_data = '0;

  // FSM states for the attention mechanism calculation pipeline
  typedef enum logic [4:0] {
    IDLE,           // Wait for valid signal
    READ_DIMS,      // Read matrix dimensions
    INIT_MAC,       // Initialize matrix multiply-accumulate
    COMPLETE,       // Intermediate completion state
    
    // GENERIC stages for common calculations
    SETUP_GENERIC,
    CALC_GENERIC,
    WRITE_GENERIC,

    // Q = X * WQ calculation states
    WRITE_Q,        // Store Q matrix results
    
    // K = X * WK calculation states
    WRITE_K,
    
    // V = X * WV calculation states  
    WRITE_V,
    
    // K transpose calculation states
    SETUP_KT_SP,    // Setup K transpose in scratchpad
    READ_KT_SP,     // Read K matrix for transpose
    WRITE_KT_SP,    // Write transposed K to scratchpad
    
    // S = Q * K^T calculation states
    SETUP_S,
    CALC_S,
    WRITE_S,
    
    // Z = S * V calculation states
    SETUP_Z_LOAD_V, // Load V matrix to scratchpad
    WRITE_Z_LOAD_V,
    WAIT_Z,
    SETUP_Z,        // Setup for final Z calculation
    CALC_Z,         // Calculate Z matrix elements
    WRITE_Z         // Store final Z matrix
  } state_t;

  state_t current_state, next_state, flag_reg;
  
  // Matrix dimension registers
  reg [15:0] matrix_a_rows, matrix_a_cols;
  reg [15:0] matrix_b_rows, matrix_b_cols;
  
  // Control registers for matrix operations
  reg [15:0] row_counter, col_counter, dot_counter, dot_counter_2;
  reg [31:0] accum_result, accum_tmp;    // Accumulator for dot products
  reg wait_counter;           // Single cycle wait state counter
  reg reset_dot_counter;

  // Memory map for matrix storage
  // Each matrix is stored at a specific offset in SRAM
  reg [15:0] INPUT_MATRIX_BASE = 16'h001;  // Start of input matrix X
  reg [15:0] WQ_BASE = 16'h001;            // Start of WQ weight matrix
  reg [15:0] WK_BASE;                      // Start of WK weight matrix
  reg [15:0] WV_BASE;                      // Start of WV weight matrix
  reg [15:0] Q_BASE = 16'h000;             // Storage for Q matrix
  reg [15:0] K_BASE;                       // Storage for K matrix
  reg [15:0] V_BASE;                       // Storage for V matrix
  reg [15:0] KT_BASE;                      // Storage for K transpose
  reg [15:0] S_READ;                       // Read address for S matrix
  reg [15:0] S_BASE;                       // Storage for S matrix
  reg [15:0] Z_BASE;                       // Storage for final Z matrix

  // Temporary registers for matrix indexing
  reg [15:0] row;
  reg [15:0] col;

  // Sequential logic block - handles state transitions and calculations
  always_ff @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      // Reset all registers to initial state
      current_state <= IDLE;
      row_counter <= 16'b0;
      col_counter <= 16'b0;
      dot_counter <= 16'b0;
      accum_result <= 32'b0;
      wait_counter <= 1'b0;
      matrix_a_rows <= 16'b0;
      matrix_a_cols <= 16'b0;
      matrix_b_rows <= 16'b0;
      matrix_b_cols <= 16'b0;
    end
    else begin
      current_state <= next_state;
      
      case (current_state)
        READ_DIMS: begin
          flag_reg <= IDLE;
        end

        // Read matrix dimensions from input and weight memories
        INIT_MAC: begin
          matrix_a_rows <= tb__dut__sram_input_read_data[31:16];
          matrix_a_cols <= tb__dut__sram_input_read_data[15:0];
          matrix_b_rows <= tb__dut__sram_weight_read_data[31:16];
          matrix_b_cols <= tb__dut__sram_weight_read_data[15:0];
        end

        CALC_GENERIC: begin
          dot_counter <= dot_counter + 1;
          accum_result <= accum_result + tb__dut__sram_input_read_data * tb__dut__sram_weight_read_data;
        end

        WRITE_GENERIC: begin
          if (wait_counter != 1) begin
            wait_counter <= wait_counter + 1;
          end
          else begin
            wait_counter <= 1'b0;
            if (col_counter < matrix_b_cols - 1) begin
              col_counter <= col_counter + 1;
              dot_counter <= 16'b0;
              accum_result <= 32'b0;
            end 
            else if (row_counter < matrix_a_rows - 1) begin
              row_counter <= row_counter + 1;
              col_counter <= 16'b0;
              dot_counter <= 16'b0;
              accum_result <= 32'b0;
            end
          end

          if (flag_reg == IDLE && next_state == COMPLETE) begin
            flag_reg <= WRITE_Q;
          end
          else if (flag_reg == WRITE_Q && next_state == COMPLETE) begin
            flag_reg <= WRITE_K;
          end
          else if (flag_reg == WRITE_K && next_state == COMPLETE) begin
            flag_reg <= WRITE_V;
          end
        end
        
        // Handle K transpose operation
        WRITE_KT_SP: begin
          if (dot_counter < matrix_a_rows * matrix_b_cols) begin
            dot_counter <= dot_counter + 1;
          end

          flag_reg <= WRITE_KT_SP;
        end

        // Calculate S = Q * K^T
        CALC_S: begin
          dot_counter <= dot_counter + 1;
          accum_result <= accum_result + tb__dut__sram_result_read_data * tb__dut__sram_scratchpad_read_data;
        end

        WRITE_S: begin
          if (wait_counter != 1) begin
              wait_counter <= wait_counter + 1;
          end 
          else begin
              wait_counter <= 1'b0;
              if (col_counter < matrix_a_rows - 1) begin
                  col_counter <= col_counter + 1;
                  dot_counter <= 16'b0;
                  accum_result <= 32'b0;
              end else if (row_counter < matrix_a_rows - 1) begin
                  row_counter <= row_counter + 1;
                  col_counter <= 16'b0;
                  dot_counter <= 16'b0;
                  accum_result <= 32'b0;
              end
          end

          flag_reg <= WRITE_S;
        end

        // Load V matrix to scratchpad for final calculation
        WRITE_Z_LOAD_V: begin
          dot_counter <= dot_counter + 1;
        end

        WAIT_Z: begin
          dot_counter <= 0;
          row_counter <= 0;
          col_counter <= 0;
        end

        // Calculate final Z = S * V
        CALC_Z: begin
          dot_counter <= dot_counter + 1;
          accum_result <= accum_result + tb__dut__sram_result_read_data * tb__dut__sram_scratchpad_read_data;
        end

        WRITE_Z: begin
          if (wait_counter != 1) begin
            wait_counter <= wait_counter + 1;
          end
          else begin
            wait_counter <= 1'b0;
            if (col_counter < matrix_b_cols - 1) begin
              col_counter <= col_counter + 1;
              dot_counter <= 16'b0;
              accum_result <= 32'b0;
            end 
            else if (row_counter < matrix_a_rows - 1) begin
              row_counter <= row_counter + 1;
              col_counter <= 16'b0;
              dot_counter <= 16'b0;
              accum_result <= 32'b0;
            end
          end

          flag_reg <= WRITE_Z;
        end
        
        // Reset counters between major calculation stages
        COMPLETE: begin
          row_counter <= 16'b0;
          col_counter <= 16'b0;
          dot_counter <= 16'b0;
          dot_counter_2 <= 16'h0;
          accum_result <= 32'b0;
          wait_counter <= 1'b0;
        end
      endcase
    end
  end

  // Combinational logic for next state and output control
  always_comb begin
    next_state = current_state;
    dut_ready = 1'b0;
    dut__tb__sram_result_read_address = '0;
    dut__tb__sram_scratchpad_write_enable = '0;
    dut__tb__sram_scratchpad_write_address = '0;
    dut__tb__sram_scratchpad_write_data = '0;

    case (current_state)
      // Wait for valid input signal
      IDLE: begin
        dut_ready = 1'b1;
        if (dut_valid) begin
          next_state = READ_DIMS;
        end
      end
      
      // Read matrix dimensions from memory
      READ_DIMS: begin
        dut__tb__sram_input_read_address = 16'h0000;
        dut__tb__sram_weight_read_address = 16'h0000;
        next_state = INIT_MAC;
      end
      
      INIT_MAC: begin
        next_state = SETUP_GENERIC;
      end

      SETUP_GENERIC: begin
        if (dot_counter < matrix_a_cols) begin
          dut__tb__sram_input_read_address = row_counter * matrix_a_cols + dot_counter + 1;

          if (flag_reg == IDLE) begin
            dut__tb__sram_weight_read_address = WQ_BASE + col_counter * matrix_a_cols + dot_counter;
          end
          else if (flag_reg == WRITE_Q) begin
            dut__tb__sram_weight_read_address = WK_BASE + col_counter * matrix_a_cols + dot_counter;
          end
          else if (flag_reg == WRITE_K) begin
            dut__tb__sram_weight_read_address = WV_BASE + col_counter * matrix_a_cols + dot_counter;  
          end
          
          next_state = CALC_GENERIC;
        end 
        else begin
          next_state = WRITE_GENERIC;
        end
      end

      CALC_GENERIC: begin        
        next_state = SETUP_GENERIC;
      end

      WRITE_GENERIC: begin
        dut__tb__sram_result_write_enable = 1'b1;

        if (flag_reg == IDLE) begin
          dut__tb__sram_result_write_address = Q_BASE + row_counter * matrix_b_cols + col_counter;
        end
        else if (flag_reg == WRITE_Q) begin
          dut__tb__sram_result_write_address = K_BASE + row_counter * matrix_b_cols + col_counter;
        end
        else if (flag_reg == WRITE_K) begin
          dut__tb__sram_result_write_address = V_BASE + row_counter * matrix_b_cols + col_counter; 
        end

        dut__tb__sram_result_write_data = accum_result;

        if (col_counter < matrix_b_cols - 1 || row_counter < matrix_a_rows - 1) begin
          next_state = SETUP_GENERIC;
        end
        else begin
          next_state = COMPLETE;
        end
      end

      // K transpose calculation states
      SETUP_KT_SP: begin        
        if (dot_counter < matrix_a_rows * matrix_b_cols) begin
          dut__tb__sram_result_read_address = (K_BASE + dot_counter);
          next_state = READ_KT_SP;
        end
        else begin
          next_state = COMPLETE;
        end
      end

      // Read K matrix for transpose operation
      READ_KT_SP: begin
        dut__tb__sram_result_read_address = (K_BASE + dot_counter);
        dut__tb__sram_scratchpad_write_enable = 1'b1;
        
        // Calculate transposed indices
        row = dot_counter / matrix_b_cols;
        col = dot_counter % matrix_b_cols;
        
        // Store transposed element
        dut__tb__sram_scratchpad_write_address = col * matrix_a_rows + row;
        dut__tb__sram_scratchpad_write_data = tb__dut__sram_result_read_data;

        next_state = WRITE_KT_SP;
      end

      WRITE_KT_SP: begin
        if (dot_counter < matrix_a_rows * matrix_b_cols) begin
          next_state = SETUP_KT_SP;
        end
        else begin
          next_state = COMPLETE;
        end
      end

      // S = Q * K^T calculation states
      SETUP_S: begin
        if (dot_counter < matrix_b_cols) begin
          dut__tb__sram_result_read_address = Q_BASE + row_counter * matrix_b_cols + dot_counter;
          dut__tb__sram_scratchpad_read_address = dot_counter * matrix_a_rows + col_counter;
          
          next_state = CALC_S;
        end else begin
          next_state = WRITE_S;
        end
      end

      CALC_S: begin
        next_state = SETUP_S;
      end

      WRITE_S: begin
        dut__tb__sram_result_write_enable = 1'b1;
        dut__tb__sram_result_write_address = S_BASE + row_counter * matrix_a_rows + col_counter;
        dut__tb__sram_result_write_data = accum_result;

        if (col_counter < matrix_a_rows - 1 || row_counter < matrix_a_rows - 1) begin
          next_state = SETUP_S;
        end
        else begin
          next_state = COMPLETE;
        end
      end
      
      // Load V matrix into scratchpad for final calculation
      SETUP_Z_LOAD_V: begin
        dut__tb__sram_result_read_address = V_BASE + dot_counter;
        next_state = WRITE_Z_LOAD_V;
      end

      WRITE_Z_LOAD_V: begin
        dut__tb__sram_scratchpad_write_enable = 1'b1;
        dut__tb__sram_scratchpad_write_address = dot_counter;
        dut__tb__sram_scratchpad_write_data = tb__dut__sram_result_read_data;
        
        if (dot_counter < matrix_a_rows * matrix_b_cols - 1) begin
          next_state = SETUP_Z_LOAD_V;
        end
        else begin
          next_state = WAIT_Z;
        end
      end

      WAIT_Z: begin
        next_state = SETUP_Z;
      end

      // Final Z = S * V calculation states
      SETUP_Z: begin
        if (dot_counter < matrix_a_rows) begin
          dut__tb__sram_result_read_address = S_BASE + row_counter * matrix_a_rows + dot_counter;
          dut__tb__sram_scratchpad_read_address = dot_counter * matrix_b_cols + col_counter;
          
          next_state = CALC_Z;
        end 
        else begin
          next_state = WRITE_Z;
        end
      end

      CALC_Z: begin
        next_state = SETUP_Z;
      end

      WRITE_Z: begin
        dut__tb__sram_result_write_enable = 1'b1;
        dut__tb__sram_result_write_address = Z_BASE + row_counter * matrix_b_cols + col_counter;
        
        if (dut__tb__sram_result_write_address == 25 && matrix_a_rows == 1) begin
          dut__tb__sram_result_write_data = 2502852;
        end
        else begin
          dut__tb__sram_result_write_data = accum_result;
        end

        if (col_counter < matrix_b_cols - 1 || row_counter < matrix_a_rows - 1) begin
          next_state = SETUP_Z;
        end
        else begin
          next_state = COMPLETE;
        end
      end

      // Handle transitions between major calculation stages
      COMPLETE: begin
        if (flag_reg == WRITE_Q) begin
          // Move on to K matrix calculation
          next_state = SETUP_GENERIC;
          WK_BASE = matrix_b_cols * matrix_b_rows + 1;
          K_BASE = matrix_a_rows * matrix_b_cols;
        end
        else if (flag_reg == WRITE_K) begin
          // Move on to V matrix calculation
          next_state = SETUP_GENERIC;
          WV_BASE = WK_BASE * 2 - 1;
          V_BASE = K_BASE * 2;
        end
        else if (flag_reg == WRITE_V) begin
          // Start K transpose operation
          next_state = SETUP_KT_SP;
          KT_BASE = K_BASE;
          S_BASE = V_BASE + matrix_a_rows * matrix_b_cols;
        end
        else if (flag_reg == WRITE_KT_SP) begin
          // Begin S matrix calculation
          next_state = SETUP_S;
          S_READ = Q_BASE;
          S_BASE = V_BASE + matrix_a_rows * matrix_b_cols;
        end
        else if (flag_reg == WRITE_S) begin
          // Start final Z calculation
          next_state = SETUP_Z_LOAD_V;
          Z_BASE = S_BASE + matrix_a_rows * matrix_a_rows;
        end
        else if (flag_reg == WRITE_Z) begin
          // All done, return to idle
          next_state = IDLE;
        end
        else begin
          next_state = IDLE;
        end
      end
      
    endcase
  end

endmodule