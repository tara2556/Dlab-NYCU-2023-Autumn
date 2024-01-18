`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
           input clk,
           input reset_n,
           input [3:0] usr_btn,
           output [3:0] usr_led,
           output LCD_RS,
           output LCD_RW,
           output LCD_E,
           output [3:0] LCD_D
       );

// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row.
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
reg [15:0] fibo [25:0];
wire [31:0] true_fibo [25:0];
reg [5:0] fibo_counter = 2;
reg openCycle = 0;
reg [5:0] fact_counter = 0;
wire sl_clk;
reg rev;
reg [5:0] temp1, temp2;

slow_clk sl(.clk(clk), .sl_clk(sl_clk));

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
             .btn_input(usr_btn[3]),
             .btn_output(btn_level)
         );


always @(posedge clk)
begin
    if (~reset_n)
        prev_btn_level <= 1;
    else
        prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);
always@(posedge clk)
begin
    if(~reset_n)
    begin
        fibo[0] <= 16'h0000;
        fibo[1] <= 16'h0001;
        fibo_counter <= 2;
    end
    else
    begin
        if(fibo_counter<26)
        begin
            fibo[fibo_counter] <= fibo[fibo_counter-1]+fibo[fibo_counter-2];
            fibo_counter <= fibo_counter+1;
        end
    end
end

intToChar I0(.in(fibo[0]), .clk(clk), .reset_n(reset_n), .o(true_fibo[0]));
intToChar I1(.in(fibo[1]), .clk(clk), .reset_n(reset_n), .o(true_fibo[1]));
intToChar I2(.in(fibo[2]), .clk(clk), .reset_n(reset_n), .o(true_fibo[2]));
intToChar I3(.in(fibo[3]), .clk(clk), .reset_n(reset_n), .o(true_fibo[3]));
intToChar I4(.in(fibo[4]), .clk(clk), .reset_n(reset_n), .o(true_fibo[4]));
intToChar I5(.in(fibo[5]), .clk(clk), .reset_n(reset_n), .o(true_fibo[5]));
intToChar I6(.in(fibo[6]), .clk(clk), .reset_n(reset_n), .o(true_fibo[6]));
intToChar I7(.in(fibo[7]), .clk(clk), .reset_n(reset_n), .o(true_fibo[7]));
intToChar I8(.in(fibo[8]), .clk(clk), .reset_n(reset_n), .o(true_fibo[8]));
intToChar I9(.in(fibo[9]), .clk(clk), .reset_n(reset_n), .o(true_fibo[9]));
intToChar I10(.in(fibo[10]), .clk(clk), .reset_n(reset_n), .o(true_fibo[10]));
intToChar I11(.in(fibo[11]), .clk(clk), .reset_n(reset_n), .o(true_fibo[11]));
intToChar I12(.in(fibo[12]), .clk(clk), .reset_n(reset_n), .o(true_fibo[12]));
intToChar I13(.in(fibo[13]), .clk(clk), .reset_n(reset_n), .o(true_fibo[13]));
intToChar I14(.in(fibo[14]), .clk(clk), .reset_n(reset_n), .o(true_fibo[14]));
intToChar I15(.in(fibo[15]), .clk(clk), .reset_n(reset_n), .o(true_fibo[15]));
intToChar I16(.in(fibo[16]), .clk(clk), .reset_n(reset_n), .o(true_fibo[16]));
intToChar I17(.in(fibo[17]), .clk(clk), .reset_n(reset_n), .o(true_fibo[17]));
intToChar I18(.in(fibo[18]), .clk(clk), .reset_n(reset_n), .o(true_fibo[18]));
intToChar I19(.in(fibo[19]), .clk(clk), .reset_n(reset_n), .o(true_fibo[19]));
intToChar I20(.in(fibo[20]), .clk(clk), .reset_n(reset_n), .o(true_fibo[20]));
intToChar I21(.in(fibo[21]), .clk(clk), .reset_n(reset_n), .o(true_fibo[21]));
intToChar I22(.in(fibo[22]), .clk(clk), .reset_n(reset_n), .o(true_fibo[22]));
intToChar I23(.in(fibo[23]), .clk(clk), .reset_n(reset_n), .o(true_fibo[23]));
intToChar I24(.in(fibo[24]), .clk(clk), .reset_n(reset_n), .o(true_fibo[24]));
reg [5:0]count;
always @(posedge clk)
begin
    if (~reset_n)
    begin
        // Initialize the text when the user hit the reset button
        row_A <= "Press BTN3 to   ";
        row_B <= "show a message..";
        openCycle <= 0;
        temp1 <= 0;
        temp2 <= 0;
        rev <= 1;
        count <=0;
    end
    else if (btn_pressed)
    begin
        openCycle <= 1;
        rev <= ~rev;
    end
    else
    begin
        if(openCycle && sl_clk)
        begin
            if(rev)
            begin
                row_A <= "Fibo #__ is ____";
                temp1 <= fact_counter+1;
                temp2 <= fact_counter+2;
                row_A[79:72] <= (temp1/10+48);
                row_A[71:64] <= (temp1%10+48);
                row_A[31:0] <= true_fibo[fact_counter];
                row_B <= "Fibo #__ is ____";
                row_B[79:72] <= (temp2/10+48);
                row_B[71:64] <= (temp2%10+48);
                row_B[31:0] <= true_fibo[fact_counter+1];
                fact_counter <= (fact_counter < 23)? fact_counter+1 : 0;
            end
            else
            begin
                row_A <= "Fibo #__ is ____";
                temp1 <= fact_counter+2;
                temp2 <= fact_counter+1;
                row_A[79:72] <= (temp1/10+48);
                row_A[71:64] <= (temp1%10+48);
                row_A[31:0] <= true_fibo[fact_counter+1];
                row_B <= "Fibo #__ is ____";
                row_B[79:72] <= (temp2/10+48);
                row_B[71:64] <= (temp2%10+48);
                row_B[31:0] <= true_fibo[fact_counter];
                fact_counter <= (fact_counter > 0)? fact_counter-1 : 23;
            end
        end
    end
end


endmodule

    module debounce(
        input clk,
        input btn_input,
        output btn_output
    );
assign btn_output = btn_input;
endmodule

    module slow_clk(input clk, output sl_clk);
reg[29:0] counter = 749999;
always@(posedge clk)
begin
    counter <= (counter>=74999999)?0:counter+1;
end
assign sl_clk = (counter==74999999)?1'b1:1'b0;
endmodule

    module intToChar(input [15:0] in, clk, reset_n, output [31:0] o);
reg [31:0] te;
assign o = te;
always@*
begin
    begin
        if (in[15:12] > 9)
            te[31:24] <= 8'h37 + in[15:12];
        else
            te[31:24] <= 8'h30 + in[15:12];
        if (in[11:8] > 9)
            te[23:16] <= 8'h37 + in[11:8];
        else
            te[23:16] <= 8'h30 + in[11:8];
        if (in[7:4] > 9)
            te[15:8] <= 8'h37 + in[7:4];
        else
            te[15:8] <= 8'h30 + in[7:4];
        if (in[3:0] > 9)
            te[7:0] <= 8'h37 + in[3:0];
        else
            te[7:0] <= 8'h30 + in[3:0];

    end
end
endmodule
