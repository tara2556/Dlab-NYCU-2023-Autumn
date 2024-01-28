`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab10(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// Declare system variables
reg  [31:0] fish1_clock, fish2_clock, fish3_clock, fish4_clock, fish5_clock, fish6_clock, fish7_clock, fish8_clock, fish9_clock, fish9_vclock;
wire [9:0]  pos1, pos2, pos3, pos4, pos5, pos6, pos7, pos8, pos9;
wire        fish1_region, fish2_region, fish3_region, fish4_region, fish5_region, fish6_region, fish7_region, fish8_region, fish9_region;

// declare SRAM control signals
wire [16:0] sram_addr, fish_addr9;
wire [16:0] sram_rf_addr;
wire [11:0] data_in;
wire [11:0] data_out, data_rf_out, data_out2, data_rf_out2, fish_out9;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr, pixel_rf_addr, fish9;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam FISH1_VPOS   = 24; // Vertical location of the fish in the sea image.
localparam FISH2_VPOS   = 44; // Vertical location of the fish in the sea image.
localparam FISH3_VPOS   = 64; // Vertical location of the fish in the sea image.
localparam FISH4_VPOS   = 104; // Vertical location of the fish in the sea image.
localparam FISH5_VPOS   = 124; // Vertical location of the fish in the sea image.
localparam FISH6_VPOS   = 134; // Vertical location of the fish in the sea image.
localparam FISH7_VPOS   = 154; // Vertical location of the fish in the sea image.
localparam FISH8_VPOS   = 174; // Vertical location of the fish in the sea image.
reg[7:0] FISH9_VPOS   = 194; // Vertical location of the fish in the sea image.
localparam FISH1_W      = 64; // Width of the fish.
localparam FISH1_H      = 32; // Height of the fish.
localparam FISH2_W      = 64; // Width of the fish.
localparam FISH2_H      = 44; // Height of the fish.
localparam FISH3_W      = 64; // Width of the fish.
localparam FISH3_H      = 72; // Height of the fish.
localparam FISH4_W      = 64; // Width of the fish.
localparam FISH4_H      = 32; // Height of the fish.
localparam FISH5_W      = 64; // Width of the fish.
localparam FISH5_H      = 44; // Height of the fish.
localparam FISH6_W      = 64; // Width of the fish.
localparam FISH6_H      = 72; // Height of the fish.
localparam FISH7_W      = 64; // Width of the fish.
localparam FISH7_H      = 32; // Height of the fish.
localparam FISH8_W      = 64; // Width of the fish.
localparam FISH8_H      = 44; // Height of the fish.
localparam FISH9_W      = 64; // Width of the fish.
localparam FISH9_H      = 72; // Height of the fish.

reg [17:0] fish1_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish2_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish3_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish4_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish5_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish6_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish7_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish8_addr[0:8];   // Address array for up to 8 fish images.
reg [17:0] fish9_addr[0:8];   // Address array for up to 8 fish images.
wire[3:0] btn_level, btn_pressed;
reg [3:0] prev_btn_level;

// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish1_addr[0] = VBUF_W*VBUF_H;
  fish1_addr[1] = VBUF_W*VBUF_H + FISH1_W*FISH1_H;
  fish1_addr[2] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*2;
  fish1_addr[3] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*3;
  fish1_addr[4] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*4;
  fish1_addr[5] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*5;
  fish1_addr[6] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*6;
  fish1_addr[7] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*7;

  fish2_addr[0] = 93184;
  fish2_addr[1] = 93184 + FISH2_W*FISH2_H;
  fish2_addr[2] = 93184 + FISH2_W*FISH2_H*2;
  fish2_addr[3] = 93184 + FISH2_W*FISH2_H*3;
  fish2_addr[4] = 93184 + FISH2_W*FISH2_H*4;
  fish2_addr[5] = 93184 + FISH2_W*FISH2_H*5;
  fish2_addr[6] = 93184 + FISH2_W*FISH2_H*6;
  fish2_addr[7] = 93184 + FISH2_W*FISH2_H*7;

  fish3_addr[0] = 115712;
  fish3_addr[1] = 115712 + FISH3_W*FISH3_H;
  
  fish4_addr[0] = VBUF_W*VBUF_H;
  fish4_addr[1] = VBUF_W*VBUF_H + FISH1_W*FISH1_H;
  fish4_addr[2] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*2;
  fish4_addr[3] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*3;
  fish4_addr[4] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*4;
  fish4_addr[5] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*5;
  fish4_addr[6] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*6;
  fish4_addr[7] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*7;

  fish5_addr[0] = 93184;
  fish5_addr[1] = 93184 + FISH2_W*FISH2_H;
  fish5_addr[2] = 93184 + FISH2_W*FISH2_H*2;
  fish5_addr[3] = 93184 + FISH2_W*FISH2_H*3;
  fish5_addr[4] = 93184 + FISH2_W*FISH2_H*4;
  fish5_addr[5] = 93184 + FISH2_W*FISH2_H*5;
  fish5_addr[6] = 93184 + FISH2_W*FISH2_H*6;
  fish5_addr[7] = 93184 + FISH2_W*FISH2_H*7;

  fish6_addr[0] = 115712;
  fish6_addr[1] = 115712 + FISH3_W*FISH3_H;
  
  fish7_addr[0] = VBUF_W*VBUF_H;
  fish7_addr[1] = VBUF_W*VBUF_H + FISH1_W*FISH1_H;
  fish7_addr[2] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*2;
  fish7_addr[3] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*3;
  fish7_addr[4] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*4;
  fish7_addr[5] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*5;
  fish7_addr[6] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*6;
  fish7_addr[7] = VBUF_W*VBUF_H + FISH1_W*FISH1_H*7;

  fish8_addr[0] = 93184;
  fish8_addr[1] = 93184 + FISH2_W*FISH2_H;
  fish8_addr[2] = 93184 + FISH2_W*FISH2_H*2;
  fish8_addr[3] = 93184 + FISH2_W*FISH2_H*3;
  fish8_addr[4] = 93184 + FISH2_W*FISH2_H*4;
  fish8_addr[5] = 93184 + FISH2_W*FISH2_H*5;
  fish8_addr[6] = 93184 + FISH2_W*FISH2_H*6;
  fish8_addr[7] = 93184 + FISH2_W*FISH2_H*7;

  fish9_addr[0] = 115712;
  fish9_addr[1] = 115712 + FISH3_W*FISH3_H;
end

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);
debounce btn_db0(.clk(clk), .btn_input(usr_btn[0]), .btn_output(btn_level[0]));
debounce btn_db1(.clk(clk), .btn_input(usr_btn[1]), .btn_output(btn_level[1]));
debounce btn_db2(.clk(clk), .btn_input(usr_btn[2]), .btn_output(btn_level[2]));
debounce btn_db3(.clk(clk), .btn_input(usr_btn[3]), .btn_output(btn_level[3]));

always @(posedge clk) begin
  if (~reset_n) prev_btn_level <= 4'h0;
  else prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & (~prev_btn_level));


// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(17), .RAM_SIZE(124928), .FILE("images1.mem"))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr1(sram_addr), .addr2(sram_rf_addr), .data_i(data_in), .data_o1(data_out), .data_o2(data_rf_out));
assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign sram_rf_addr = pixel_rf_addr;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos1 = fish1_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos2 = fish2_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos3 = fish3_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos4 = fish4_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos5 = fish5_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos6 = fish6_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos7 = fish7_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos8 = fish8_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
assign pos9 = fish9_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
                                
                                
always @(posedge clk) begin
  if (~reset_n || fish1_clock[31:21] > VBUF_W + FISH1_W)
    fish1_clock <= 0;
  else
    fish1_clock <= fish1_clock + 1 + btn_level[0] ;
end
always @(posedge clk) begin
  if (~reset_n)
    fish2_clock <= 201344456;
  else if(fish2_clock[31:21] > VBUF_W + FISH3_W)
    fish2_clock <= 0;
  else
    fish2_clock <= fish2_clock + 2 + btn_level[1];
end
always @(posedge clk) begin
  if (~reset_n || fish3_clock[31:21] < 0)
    fish3_clock <= (fish2_clock+fish1_clock)>>1;
  else
    fish3_clock <= fish3_clock - 1 + btn_level[2];
end
always @(posedge clk) begin
  if (~reset_n || fish4_clock[31:21] > VBUF_W + FISH1_W)
    fish4_clock <= 0;
  else
    fish4_clock <= fish4_clock + fish8_clock[25:23] - fish5_clock[25:24];
end
always @(posedge clk) begin
  if (~reset_n)
    fish5_clock <= 301344456;
  else if(fish5_clock[31:21] > VBUF_W + FISH3_W)
    fish5_clock <= 0;
  else
    fish5_clock <= fish5_clock + 4;
end
always @(posedge clk) begin
  if (~reset_n || fish6_clock[31:21] < 0)
    fish6_clock <= (fish4_clock+fish5_clock)>>1;
  else
    fish6_clock <= fish6_clock - 1 - fish1_clock[25:23] + fish2_clock[25:24];
end
always @(posedge clk) begin
  if (~reset_n || fish7_clock[31:21] > VBUF_W + FISH1_W)
    fish7_clock <= 153153445;
  else
    fish7_clock <= fish7_clock + fish4_clock[24:23];
end
always @(posedge clk) begin
  if (~reset_n)
    fish8_clock <= 201344456;
  else if(fish8_clock[31:21] > VBUF_W + FISH2_W)
    fish8_clock <= 0;
  else
    fish8_clock <= fish8_clock + 3+ fish7_clock[24:23] - fish6_clock[25:24];
end
always @(posedge clk) begin
  if (~reset_n || fish9_clock[31:21] < 0)
    fish9_clock <= (fish1_clock+fish2_clock)>>1;
  else
    fish9_clock <= fish9_clock - 1;
end
always @(posedge clk) begin
    FISH9_VPOS <= fish9_vclock[31:21];
end
always @(posedge clk) begin
  if (~reset_n || fish9_vclock[31:21] > VBUF_H + FISH9_H)
    fish9_vclock <= 0;
  else
    fish9_vclock <= fish9_vclock + 1;
end
// End of the animation clock code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish1_region =
           pixel_y >= (FISH1_VPOS<<1) && pixel_y < (FISH1_VPOS+FISH1_H)<<1 &&
           (pixel_x + 127) >= pos1 && pixel_x < pos1 + 1 ;
assign fish2_region =
           pixel_y >= (FISH2_VPOS<<1) && pixel_y < (FISH2_VPOS+FISH2_H)<<1 &&
           (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1;
assign fish3_region =
           pixel_y >= (FISH3_VPOS<<1) && pixel_y < (FISH3_VPOS+FISH3_H)<<1 &&
           (pixel_x + 127) >= pos3 && pixel_x < pos3 + 1;
assign fish4_region =
           pixel_y >= (FISH4_VPOS<<1) && pixel_y < (FISH4_VPOS+FISH4_H)<<1 &&
           (pixel_x + 127) >= pos4 && pixel_x < pos4 + 1 ;
assign fish5_region =
           pixel_y >= (FISH5_VPOS<<1) && pixel_y < (FISH5_VPOS+FISH5_H)<<1 &&
           (pixel_x + 127) >= pos5 && pixel_x < pos5 + 1;
assign fish6_region =
           pixel_y >= (FISH6_VPOS<<1) && pixel_y < (FISH6_VPOS+FISH6_H)<<1 &&
           (pixel_x + 127) >= pos6 && pixel_x < pos6 + 1;
assign fish7_region =
           pixel_y >= (FISH7_VPOS<<1) && pixel_y < (FISH7_VPOS+FISH7_H)<<1 &&
           (pixel_x + 127) >= pos7 && pixel_x < pos7+ 1 ;
assign fish8_region =
           pixel_y >= (FISH8_VPOS<<1) && pixel_y < (FISH8_VPOS+FISH8_H)<<1 &&
           (pixel_x + 127) >= pos8 && pixel_x < pos8 + 1;
assign fish9_region =
           pixel_y >= (FISH9_VPOS<<1) && pixel_y < (FISH9_VPOS+FISH9_H)<<1 &&
           (pixel_x + 127) >= pos9 && pixel_x < pos9 + 1;


always @ (posedge clk) begin
  if (~reset_n)
    pixel_rf_addr <= 0;
  else
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    pixel_rf_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
end
always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr <= 0;
  end else if (fish1_region)
    pixel_addr <= fish1_addr[fish1_clock[25:23]] +
                  ((pixel_y>>1)-FISH1_VPOS)*FISH1_W +
                  ((pixel_x +(FISH1_W*2-1)-pos1)>>1);
  else if (!fish1_region && fish2_region)
    pixel_addr <= fish2_addr[fish2_clock[25:23]] +
                  ((pixel_y>>1)-FISH2_VPOS)*FISH2_W +
                  ((pixel_x +(FISH2_W*2-1)-pos2)>>1);
  else if (!fish1_region && !fish2_region && fish3_region)
    pixel_addr <= fish3_addr[fish3_clock[23]] +
                  ((pixel_y>>1)-FISH3_VPOS)*FISH3_W +
                  ((pixel_x +(FISH3_W*2-1)-pos3)>>1); 
  else if (!fish1_region && !fish2_region && !fish3_region && fish4_region)
    pixel_addr <= fish4_addr[fish4_clock[25:23]] +
                  ((pixel_y>>1)-FISH4_VPOS)*FISH4_W +
                  ((pixel_x +(FISH4_W*2-1)-pos4)>>1);
  else if (!fish1_region && !fish2_region && !fish3_region && !fish4_region && fish5_region)
    pixel_addr <= fish5_addr[fish5_clock[25:23]] +
                  ((pixel_y>>1)-FISH5_VPOS)*FISH5_W +
                  ((pixel_x +(FISH5_W*2-1)-pos5)>>1);
  else if (!fish1_region && !fish2_region && !fish3_region && !fish4_region && !fish5_region && fish6_region)
    pixel_addr <= fish6_addr[fish6_clock[23]] +
                  ((pixel_y>>1)-FISH6_VPOS)*FISH6_W +
                  ((pixel_x +(FISH6_W*2-1)-pos6)>>1); 
  else if (!fish1_region && !fish2_region && !fish3_region && !fish4_region && !fish5_region && !fish6_region && fish7_region)
    pixel_addr <= fish7_addr[fish7_clock[25:23]] +
                  ((pixel_y>>1)-FISH7_VPOS)*FISH7_W +
                  ((pixel_x +(FISH7_W*2-1)-pos7)>>1);
  else if (!fish1_region && !fish2_region && !fish3_region && !fish4_region && !fish5_region && !fish6_region && !fish7_region && fish8_region)
    pixel_addr <= fish8_addr[fish8_clock[25:23]] +
                  ((pixel_y>>1)-FISH8_VPOS)*FISH8_W +
                  ((pixel_x +(FISH8_W*2-1)-pos8)>>1);                    
  else if (!fish1_region && !fish2_region && !fish3_region && !fish4_region && !fish5_region && !fish6_region && !fish7_region && !fish8_region && fish9_region)
    pixel_addr <= fish9_addr[fish9_clock[23]] +
                  ((pixel_y>>1)-FISH9_VPOS)*FISH9_W +
                  ((pixel_x +(FISH9_W*2-1)-pos9)>>1); 
  else
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
               
end

// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if(data_out!=12'h0f0)
    rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
  else 
    rgb_next = data_rf_out;
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date:    09:43:16 10/20/2015 
// Design Name: 
// Module Name:    debounce
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module debounce(input clk, input btn_input, output btn_output);

parameter DEBOUNCE_PERIOD = 2_000_000; /* 20 msec = (100,000,000*0.2) ticks @100MHz */

reg [$clog2(DEBOUNCE_PERIOD):0] counter;

assign btn_output = (counter == DEBOUNCE_PERIOD);

always@(posedge clk) begin
  if (btn_input == 0)
    counter <= 0;
  else
    counter <= counter + (counter != DEBOUNCE_PERIOD);
end

endmodule
