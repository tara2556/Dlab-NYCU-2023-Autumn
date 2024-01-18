`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab7(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D,
  
  // Uart input and output
  input uart_rx,
  output uart_tx
);

localparam [1:0] S_MAIN_ADDR = 3'b000, S_MAIN_READ = 3'b001,
                 S_MAIN_SHOW = 3'b010, S_MAIN_WAIT = 3'b011;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
localparam STR1 = 0;
localparam LEN1 = 39;
localparam STR2 = 39;  // h27
localparam LEN2 = 33;
localparam MEM_SIZE = 72;  // h48

// declare system variables
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
wire print_enable, print_done;
reg  [$clog2(MEM_SIZE):0] send_counter;
reg  [0:LEN1*8-1] msg1 = {"The matrix multiplication result is:\015\012", 8'h00};
reg  [0:LEN2*8-1] msg2 = {"[ XXXXX, XXXXX, XXXXX, XXXXX ]\015\012",       8'h00};
reg  [1:0]  P, P_next;
reg  [1:0]  Q, Q_next;
reg  [7:0]  data[0:MEM_SIZE-1];
reg  [11:0] user_addr;
reg  [7:0]  user_data;
reg  [17:0] solution [17:0];
reg  [17:0] temp [32:0];
reg  [127:0] row_A, row_B;

// declare SRAM control signals
wire [7:0]  data_in, data_out;
reg [7:0]  data1 [16:0];
reg [7:0]  data2 [16:0];
wire        sram_we, sram_en;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

assign usr_led = 4'h00;

LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
  
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

// ------------------------------------------------------------------------
// The following code creates an initialized SRAM memory block that
// stores an 1024x8-bit unsigned numbers.
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(user_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block.
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

always @(posedge clk) begin
    if(P == S_MAIN_READ) begin
        if(user_addr < 16) data1[user_addr] <= user_data;
        else data2[user_addr-16] <= user_data;
    end
end

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_ADDR; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_WAIT:
        if (|btn_pressed==1) P_next <= S_MAIN_SHOW;
        else P_next <= S_MAIN_WAIT;
    S_MAIN_SHOW:
        if (print_done) P_next <= S_MAIN_READ;
        else P_next <= S_MAIN_SHOW;
    S_MAIN_READ:
        if (~print_done) P_next <= S_MAIN_READ;
        else if (index_counter == 16) P_next <= S_MAIN_WAIT;
        else P_next <= S_MAIN_ADDR;
    S_MAIN_ADDR:
        P_next <= S_MAIN_READ;
  endcase
end

always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end


always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next <= S_UART_WAIT;
      else Q_next <= S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next <= S_UART_SEND;
      else Q_next <= S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next <= S_UART_INCR; // transmit next character
      else Q_next <= S_UART_SEND;
    S_UART_INCR:
      if (print_done) Q_next <= S_UART_IDLE; // string transmission ends
      else Q_next <= S_UART_WAIT;
  endcase
end
assign print_enable = (P != S_MAIN_SHOW && P_next == S_MAIN_SHOW) ||
                      (P == S_MAIN_READ  && index_counter >= 4);//(Q != S_UART_WAIT && Q_next == S_UART_WAIT) ||
                      //(Q == S_UART_INCR  && index_counter>0);
assign print_done = (tx_byte == 8'h0);        
always @(posedge clk) begin
    if (~reset_n) begin
        send_counter <= 0;
    end else if (P == S_MAIN_WAIT)
        send_counter <= STR1;
    else if (index_counter[1:0]==2'h3)
        send_counter <= STR2;
    else 
        send_counter <= send_counter + (Q_next == S_UART_INCR);
end
assign transmit = (Q_next == S_UART_WAIT ||
                   print_enable);

assign tx_byte = data[send_counter];

always@(posedge clk) begin
    case(user_addr)
    20: begin
    temp[0] <= data2[0]*data1[0];
    temp[1] <= data2[1]*data1[4];
    temp[2] <=data2[2]*data1[8];
    temp[3] <= data2[3]*data1[12];
    temp[4] <= data2[0]*data1[1];
    temp[5] <= data2[1]*data1[5];
    temp[6] <= data2[2]*data1[9];
    temp[7] <= data2[3]*data1[13];
    temp[8] <= data2[0]*data1[2];
    temp[9] <= data2[1]*data1[6];
    temp[10] <= data2[2]*data1[10];
    temp[11] <= data2[3]*data1[14];
    temp[12] <= data2[0]*data1[3];
    temp[13] <= data2[1]*data1[7];
    temp[14] <= data2[2]*data1[11];
    temp[15] <= data2[3]*data1[15];
    end
    24: begin
    temp[0] <= data2[4]*data1[0];
    temp[1] <= data2[5]*data1[4];
    temp[2] <=data2[6]*data1[8];
    temp[3] <= data2[7]*data1[12];
    temp[4] <= data2[4]*data1[1];
    temp[5] <= data2[5]*data1[5];
    temp[6] <= data2[6]*data1[9];
    temp[7] <= data2[7]*data1[13];
    temp[8] <= data2[4]*data1[2];
    temp[9] <= data2[5]*data1[6];
    temp[10] <= data2[6]*data1[10];
    temp[11] <= data2[7]*data1[14];
    temp[12] <= data2[4]*data1[3];
    temp[13] <= data2[5]*data1[7];
    temp[14] <= data2[6]*data1[11];
    temp[15] <= data2[7]*data1[15];
    end
    28: begin
    temp[0] <= data2[8]*data1[0];
    temp[1] <= data2[9]*data1[4];
    temp[2] <=data2[10]*data1[8];
    temp[3] <= data2[11]*data1[12];
    temp[4] <= data2[8]*data1[1];
    temp[5] <= data2[9]*data1[5];
    temp[6] <= data2[10]*data1[9];
    temp[7] <= data2[11]*data1[13];
    temp[8] <= data2[8]*data1[2];
    temp[9] <= data2[9]*data1[6];
    temp[10] <= data2[10]*data1[10];
    temp[11] <= data2[11]*data1[14];
    temp[12] <= data2[8]*data1[3];
    temp[13] <= data2[9]*data1[7];
    temp[14] <= data2[10]*data1[11];
    temp[15] <= data2[11]*data1[15];
    end
    32: begin
    temp[0] <= data2[12]*data1[0];
    temp[1] <= data2[13]*data1[4];
    temp[2] <=data2[14]*data1[8];
    temp[3] <= data2[15]*data1[12];
    temp[4] <= data2[12]*data1[1];
    temp[5] <= data2[13]*data1[5];
    temp[6] <= data2[14]*data1[9];
    temp[7] <= data2[15]*data1[13];
    temp[8] <= data2[12]*data1[2];
    temp[9] <= data2[13]*data1[6];
    temp[10] <= data2[14]*data1[10];
    temp[11] <= data2[15]*data1[14];
    temp[12] <= data2[12]*data1[3];
    temp[13] <= data2[13]*data1[7];
    temp[14] <= data2[14]*data1[11];
    temp[15] <= data2[15]*data1[15];
    end
    
    endcase
end
always@(posedge clk) begin
    if(user_addr == 20) begin
        solution[4] <= temp[0]+temp[1]+temp[2]+temp[3];
        solution[8] <= temp[4]+temp[5]+temp[6]+temp[7];
        solution[12] <= temp[8]+temp[9]+temp[10]+temp[11];
        solution[16] <=temp[12]+temp[13]+temp[14]+temp[15];
    end
    else if(user_addr == 24) begin
        solution[1] <= temp[0]+temp[1]+temp[2]+temp[3];
        solution[5] <= temp[4]+temp[5]+temp[6]+temp[7];
        solution[9] <= temp[8]+temp[9]+temp[10]+temp[11];
        solution[13] <=temp[12]+temp[13]+temp[14]+temp[15];
    end
     if(user_addr == 28) begin
        solution[2] <= temp[0]+temp[1]+temp[2]+temp[3];
        solution[6] <= temp[4]+temp[5]+temp[6]+temp[7];
        solution[10] <= temp[8]+temp[9]+temp[10]+temp[11];
        solution[14] <=temp[12]+temp[13]+temp[14]+temp[15];
    end
     if(user_addr == 32) begin
        solution[3] <= temp[0]+temp[1]+temp[2]+temp[3];
        solution[7] <= temp[4]+temp[5]+temp[6]+temp[7];
        solution[11] <= temp[8]+temp[9]+temp[10]+temp[11];
        solution[15] <=temp[12]+temp[13]+temp[14]+temp[15];
    end
end

reg[4:0] index_counter;

always@(posedge clk) begin
    if (P == S_MAIN_SHOW)
        index_counter <= 0;
    if(P==S_MAIN_ADDR) begin
        if (index_counter[0] == 1'b0) begin  // Print row and process next
            if (print_done || index_counter < 16)
                 index_counter <= index_counter + 1;
            else
              index_counter <= index_counter;
        end else if (index_counter == 16)  // End of 4 row
            index_counter <= index_counter;
        else
            index_counter <= index_counter + 1;
    end
end

integer idx;
always @(posedge clk) begin
  if (~reset_n) begin
    for (idx = 0; idx < LEN1; idx = idx + 1) data[idx+STR1] = msg1[idx*8 +: 8];
    for (idx = 0; idx < LEN2; idx = idx + 1) data[idx+STR2] = msg2[idx*8 +: 8];    
  end
  else if (P == S_MAIN_READ) begin
        data[STR2 +  2 + (index_counter[1:0])*7] <=   solution[index_counter][16 +: 2] | "0";
        data[STR2 +  3 + (index_counter[1:0])*7] <= ((solution[index_counter][12 +: 4] > 9) ? "7" : "0") + solution[index_counter][12 +: 4];
        data[STR2 +  4 + (index_counter[1:0])*7] <= ((solution[index_counter][ 8 +: 4] > 9) ? "7" : "0") + solution[index_counter][ 8 +: 4];
        data[STR2 +  5 + (index_counter[1:0])*7] <= ((solution[index_counter][ 4 +: 4] > 9) ? "7" : "0") + solution[index_counter][ 4 +: 4];
        data[STR2 +  6 + (index_counter[1:0])*7] <= ((solution[index_counter][ 0 +: 4] > 9) ? "7" : "0") + solution[index_counter][ 0 +: 4];
       
  end
end
// FSM ouput logic: Fetch the data bus of sram[] for display
always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we) user_data <= data_out;
end
// End of the main controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following code updates the 1602 LCD text messages.
always @(posedge clk) begin
  if (~reset_n) begin
    row_A <= "Data at [0x---] ";
  end
  else begin
    row_A[39:32] <= ((user_addr[11:08] > 9)? "7" : "0") + user_addr[11:08];
    row_A[31:24] <= ((user_addr[07:04] > 9)? "7" : "0") + user_addr[07:04];
    row_A[23:16] <= ((user_addr[03:00] > 9)? "7" : "0") + user_addr[03:00];
  end
end

always @(posedge clk) begin
  if (~reset_n) begin
    row_B <= "is equal to 0x--";
  end
  else begin
    row_B[15:08] <= ((user_data[7:4] > 9)? "7" : "0") + user_data[7:4];
    row_B[07: 0] <= ((user_data[3:0] > 9)? "7" : "0") + user_data[3:0];
  end
end
// End of the 1602 LCD text-updating code.
// ------------------------------------------------------------------------



// ------------------------------------------------------------------------
// The circuit block that processes the user's button event.
always @(posedge clk) begin
  if (~reset_n)
    user_addr <= 12'h000;
  else if (btn_pressed[1])
    user_addr <= (user_addr < 2048)? user_addr + 1 : user_addr;
  else if (btn_pressed[0])
    user_addr <= (user_addr > 0)? user_addr - 1 : user_addr;
end
// End of the user's button control.
// ------------------------------------------------------------------------

// calculution matrix multiplication results

endmodule