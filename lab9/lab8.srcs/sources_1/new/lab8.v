`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
//
// Create Date: 2017/05/08 15:29:41
// Design Name:
// Module Name: lab6
// Project Name:
// Target Devices:
// Tool Versions:
// Description: The sample top module of lab 6: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then displayer the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
//
// Dependencies: clk_divider, LCD_module, debounce, sd_card
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module lab9(
           // General system I/O ports
           input  clk,
           input  reset_n,
           input  [3:0] usr_btn,
           output [3:0] usr_led,


           // 1602 LCD Module Interface
           output LCD_RS,
           output LCD_RW,
           output LCD_E,
           output [3:0] LCD_D
       );

localparam [1:0] S_MAIN_INIT = 2'b00, S_MAIN_CALC = 2'b01, S_MAIN_SHOW = 2'b10;
// Declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  [2:0] P, P_next;
reg  done;
reg  [95:0]timer;
reg [0:127] passwd_hash = 128'hE8CD0953ABDFDE433DFEC7FAA70DF7F6;
reg [63:0] ans_reg;
reg [63:0] in [0:2];
wire [63:0] ans [0:2];
wire [127:0] hash0, hash1, hash2;
reg  [127:0] row_A = "SD card cannot  ";
reg  [127:0] row_B = "be initialized! ";
md5 m0(.test(in[0]), .clk(clk), .hash(hash0), .out(ans[0]));
md5 m1(.test(in[1]), .clk(clk), .hash(hash1), .out(ans[1]));
md5 m2(.test(in[2]), .clk(clk), .hash(hash2), .out(ans[2]));
integer i;
always @(posedge clk)
begin
    if (P == S_MAIN_INIT) done <= 0;
    else if (hash0 == passwd_hash)
    begin
        done <= 1; ans_reg <= ans[0];
    end
    else if (hash1 == passwd_hash)
    begin
        done <= 1; ans_reg <= ans[1];
    end
    else if (hash2 == passwd_hash)
    begin
        done <= 1; ans_reg <= ans[2];
    end

end


always@(posedge clk)
begin
    if(P == S_MAIN_INIT)
    begin
        in[0] <= "00000000";
        in[1] <= "33333333";
        in[2] <= "66666666";
    end
    else if(P == S_MAIN_CALC)
    begin
        for(i = 0; i < 3; i = i+1)
        begin
            if (in[i][ 0 +: 8] == "9")
            begin
                in[i][ 0 +: 8] <= "0";
                if (in[i][ 8 +: 8] == "9")
                begin
                    in[i][ 8 +: 8] <= "0";
                    if (in[i][16 +: 8] == "9")
                    begin
                        in[i][16 +: 8] <= "0";
                        if (in[i][24 +: 8] == "9")
                        begin
                            in[i][24 +: 8] <= "0";
                            if (in[i][32 +: 8] == "9")
                            begin
                                in[i][32 +: 8] <= "0";
                                if (in[i][40 +: 8] == "9")
                                begin
                                    in[i][40 +: 8] <= "0";
                                    if (in[i][48 +: 8] == "9")
                                    begin
                                        in[i][48 +: 8] <= "0";
                                        if (in[i][56 +: 8] == "9")
                                        begin
                                            in[i][56 +: 8] <= "0";
                                        end
                                        else in[i][56 +: 8] <= in[i][56 +: 8] + 1;
                                    end
                                    else in[i][48 +: 8] <= in[i][48 +: 8] + 1;
                                end
                                else in[i][40 +: 8] <= in[i][40 +: 8] + 1;
                            end
                            else in[i][32 +: 8] <= in[i][32 +: 8] + 1;
                        end
                        else in[i][24 +: 8] <= in[i][24 +: 8] + 1;
                    end
                    else in[i][16 +: 8] <= in[i][16 +: 8] + 1;
                end
                else in[i][ 8 +: 8] <= in[i][ 8 +: 8] + 1;
            end
            else in[i][ 0 +: 8] <= in[i][ 0 +: 8] + 1;
        end
    end
end


debounce btn_db0(
             .clk(clk),
             .btn_input(usr_btn[2]),
             .btn_output(btn_level)
         );

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


//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk)
begin
    if (~reset_n)
        prev_btn_level <= 0;
    else
        prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;



always @(posedge clk)
begin
    if(~reset_n) P <= S_MAIN_INIT;
    else P <= P_next;
end

always @(*)
begin
    case(P)
        S_MAIN_INIT:
            if(btn_pressed) P_next = S_MAIN_CALC;
            else P_next = S_MAIN_INIT;
        S_MAIN_CALC:
            if (done || timer == "001000000000") P_next <= S_MAIN_SHOW;
            else P_next <= S_MAIN_CALC;
        S_MAIN_SHOW:
            if (btn_pressed) P_next <= S_MAIN_INIT;
            else P_next <= S_MAIN_SHOW;
        default:
            P_next <= S_MAIN_INIT;
    endcase
end



// LCD Display function.
always @(posedge clk)
begin
    if (P == S_MAIN_INIT)
    begin
        row_A <= "Press  BTN2  to ";
        row_B <= "start calcualte ";
    end
    else if (P == S_MAIN_CALC)
    begin
        row_A <= "Calculating.....";
        row_B <= "                ";
    end
    else if (P == S_MAIN_SHOW)
    begin
        row_A <= {"Passwd: ", ans_reg};
        row_B <= {"Time: ", timer[40 +: 56], " ms"};
    end
end

always@(posedge clk)
begin
    if(P==S_MAIN_INIT) timer <= "000000000000";
    else if(P==S_MAIN_CALC)
    begin
        if (timer[ 0 +: 8] == "9")
        begin
            timer[ 0 +: 8] <= "0";
            if (timer[ 8 +: 8] == "9")
            begin
                timer[ 8 +: 8] <= "0";
                if (timer[16 +: 8] == "9")
                begin
                    timer[16 +: 8] <= "0";
                    if (timer[24 +: 8] == "9")
                    begin
                        timer[24 +: 8] <= "0";
                        if (timer[32 +: 8] == "9")
                        begin
                            timer[32 +: 8] <= "0";
                            if (timer[40 +: 8] == "9")
                            begin
                                timer[40 +: 8] <= "0";
                                if (timer[48 +: 8] == "9")
                                begin
                                    timer[48 +: 8] <= "0";
                                    if (timer[56 +: 8] == "9")
                                    begin
                                        timer[56 +: 8] <= "0";
                                        if (timer[64 +: 8] == "9")
                                        begin
                                            timer[64 +: 8] <= "0";
                                            if (timer[72 +: 8] == "9")
                                            begin
                                                timer[72 +: 8] <= "0";
                                                if (timer[80 +: 8] == "9")
                                                begin
                                                    timer[80 +: 8] <= "0";
                                                    if(timer[88+: 8] == "9") timer[88+:8] <= "0";
                                                    else timer[88 +: 8] <= timer[88+:8]+1;
                                                end
                                                else timer[80 +: 8] <= timer[80 +: 8] + 1;
                                            end
                                            else timer[72 +: 8] <= timer[72 +: 8] + 1;
                                        end
                                        else timer[64 +: 8] <= timer[64 +: 8] + 1;
                                    end
                                    else timer[56 +: 8] <= timer[56 +: 8] + 1;
                                end
                                else timer[48 +: 8] <= timer[48 +: 8] + 1;
                            end
                            else timer[40 +: 8] <= timer[40 +: 8] + 1;
                        end
                        else timer[32 +: 8] <= timer[32 +: 8] + 1;
                    end
                    else timer[24 +: 8] <= timer[24 +: 8] + 1;
                end
                else timer[16 +: 8] <= timer[16 +: 8] + 1;
            end
            else timer[ 8 +: 8] <= timer[ 8 +: 8] + 1;
        end
        else timer[ 0 +: 8] <= timer[ 0 +: 8] + 1;
    end
end
// End of the LCD display function
// ------------------------------------------------------------------------

endmodule


    module md5(input [63:0] test, input clk, output[127:0] hash, output [0:63]  out
);
localparam h0 = 32'h67452301,
           h1 = 32'hefcdab89,
           h2 = 32'h98badcfe,
           h3 = 32'h10325476;
reg [0:63] w, w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15, w16, w17, w18, w19, w20, w21, w22, w23, w24, w25, w26, w27, w28, w29, w30, w31, w32, w33, w34, w35, w36, w37, w38, w39, w40, w41, w42, w43, w44, w45, w46, w47, w48, w49, w50, w51, w52, w53, w54, w55, w56, w57, w58, w59, w60, w61, w62, w63, w64;
reg [0:31]    A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, A40, A41, A42, A43, A44, A45, A46, A47, A48, A49, A50, A51, A52, A53, A54, A55, A56, A57, A58, A59, A60, A61, A62, A63, A64;
reg [0:31]    B0, B1, B2, B3, B4, B5, B6, B7, B8, B9, B10, B11, B12, B13, B14, B15, B16, B17, B18, B19, B20, B21, B22, B23, B24, B25, B26, B27, B28, B29, B30, B31, B32, B33, B34, B35, B36, B37, B38, B39, B40, B41, B42, B43, B44, B45, B46, B47, B48, B49, B50, B51, B52, B53, B54, B55, B56, B57, B58, B59, B60, B61, B62, B63, B64;
reg [0:31]    C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10, C11, C12, C13, C14, C15, C16, C17, C18, C19, C20, C21, C22, C23, C24, C25, C26, C27, C28, C29, C30, C31, C32, C33, C34, C35, C36, C37, C38, C39, C40, C41, C42, C43, C44, C45, C46, C47, C48, C49, C50, C51, C52, C53, C54, C55, C56, C57, C58, C59, C60, C61, C62, C63, C64;
reg [0:31]    D0, D1, D2, D3, D4, D5, D6, D7, D8, D9, D10, D11, D12, D13, D14, D15, D16, D17, D18, D19, D20, D21, D22, D23, D24, D25, D26, D27, D28, D29, D30, D31, D32, D33, D34, D35, D36, D37, D38, D39, D40, D41, D42, D43, D44, D45, D46, D47, D48, D49, D50, D51, D52, D53, D54, D55, D56, D57, D58, D59, D60, D61, D62, D63, D64;
reg [127:0] hash_reg;
reg [0:63] out_reg;

assign hash = hash_reg;
assign out = out_reg;

always@(posedge clk)
begin
    w0<=w;  w1<=w0; w2<=w1; w3<=w2; w4<=w3; w5<=w4; w6<=w5; w7<=w6; w8<=w7; w9 <=w8; w10<=w9;  w11<=w10; w12<=w11; w13<=w12; w14<=w13; w15<=w14; w16<=w15; w17<=w16; w18<=w17; w19<=w18; w20<=w19; w21<=w20; w22<=w21; w23<=w22; w24<=w23; w25<=w24; w26<=w25; w27<=w26; w28<=w27; w29<=w28; w30<=w29; w31<=w30; w32<=w31; w33<=w32; w34<=w33; w35<=w34; w36<=w35; w37<=w36; w38<=w37; w39<=w38; w40<=w39; w41<=w40; w42<=w41; w43<=w42; w44<=w43; w45<=w44; w46<=w45; w47<=w46; w48<=w47; w49<=w48; w50<=w49; w51<=w50; w52<=w51; w53<=w52; w54<=w53; w55<=w54; w56<=w55; w57<=w56; w58<=w57; w59<=w58; w60<=w59; w61<=w60; w62<=w61; w63<=w62;
    A3<=D2; A4<=D3; A5<=D4; A6<=D5; A7<=D6; A8<=D7; A9<=D8; A10<=D9; A11<=D10; A12<=D11; A13<=D12; A14<=D13; A15<=D14; A16<=D15; A17<=D16; A18<=D17; A19<=D18; A20<=D19; A21<=D20; A22<=D21; A23<=D22; A24<=D23; A25<=D24; A26<=D25; A27<=D26; A28<=D27; A29<=D28; A30<=D29; A31<=D30; A32<=D31; A33<=D32; A34<=D33; A35<=D34; A36<=D35; A37<=D36; A38<=D37; A39<=D38; A40<=D39; A41<=D40; A42<=D41; A43<=D42; A44<=D43; A45<=D44; A46<=D45; A47<=D46; A48<=D47; A49<=D48; A50<=D49; A51<=D50; A52<=D51; A53<=D52; A54<=D53; A55<=D54; A56<=D55; A57<=D56; A58<=D57; A59<=D58; A60<=D59; A61<=D60; A62<=D61;
    w[0+:8] <= test[32+:8];
    w[8+:8] <= test[40+:8];
   w[16+:8] <= test[48+:8];
   w[24+:8] <= test[56+:8];
   w[32+:8] <= test[0+:8];
   w[40+:8] <= test[8+:8];
   w[48+:8] <= test[16+:8];
   w[56+:8] <= test[24+:8];
   
    out_reg[56+:8] <= w63[32+:8];
    out_reg[48+:8] <= w63[40+:8];
   out_reg[40+:8] <= w63[48+:8];
   out_reg[32+:8] <= w63[56+:8];
   out_reg[24+:8] <= w63[0+:8];
   out_reg[16+:8] <= w63[8+:8];
   out_reg[8+:8] <= w63[16+:8];
   out_reg[0+:8] <= w63[24+:8];
     A0 <= h0; A1 <= D0; A2 <= D1; A3 <= D2; A4 <= D3; A5 <= D4; A6 <= D5; A7 <= D6; A8 <= D7; A9 <= D8; A10 <= D9; A11 <= D10; A12 <= D11; A13 <= D12; A14 <= D13; A15 <= D14; A16 <= D15; A17 <= D16; A18 <= D17; A19 <= D18; A20 <= D19; A21 <= D20; A22 <= D21; A23 <= D22; A24 <= D23; A25 <= D24; A26 <= D25; A27 <= D26; A28 <= D27; A29 <= D28; A30 <= D29; A31 <= D30; A32 <= D31; A33 <= D32; A34 <= D33; A35 <= D34; A36 <= D35; A37 <= D36; A38 <= D37; A39 <= D38; A40 <= D39; A41 <= D40; A42 <= D41; A43 <= D42; A44 <= D43; A45 <= D44; A46 <= D45; A47 <= D46; A48 <= D47; A49 <= D48; A50 <= D49; A51 <= D50; A52 <= D51; A53 <= D52; A54 <= D53; A55 <= D54; A56 <= D55; A57 <= D56; A58 <= D57; A59 <= D58; A60 <= D59; A61 <= D60; A62 <= D61; A63 <= D62; A64 <= D63+h0;
    B0 <= h1;
    C0 <= h2; C1 <= B0; C2 <= B1; C3 <= B2; C4 <= B3; C5 <= B4; C6 <= B5; C7 <= B6; C8 <= B7; C9 <= B8; C10 <= B9; C11 <= B10; C12 <= B11; C13 <= B12; C14 <= B13; C15 <= B14; C16 <= B15; C17 <= B16; C18 <= B17; C19 <= B18; C20 <= B19; C21 <= B20; C22 <= B21; C23 <= B22; C24 <= B23; C25 <= B24; C26 <= B25; C27 <= B26; C28 <= B27; C29 <= B28; C30 <= B29; C31 <= B30; C32 <= B31; C33 <= B32; C34 <= B33; C35 <= B34; C36 <= B35; C37 <= B36; C38 <= B37; C39 <= B38; C40 <= B39; C41 <= B40; C42 <= B41; C43 <= B42; C44 <= B43; C45 <= B44; C46 <= B45; C47 <= B46; C48 <= B47; C49 <= B48; C50 <= B49; C51 <= B50; C52 <= B51; C53 <= B52; C54 <= B53; C55 <= B54; C56 <= B55; C57 <= B56; C58 <= B57; C59 <= B58; C60 <= B59; C61 <= B60; C62 <= B61; C63 <= B62; C64 <= B63+h2;
    D0 <= h3; D1 <= C0; D2 <= C1; D3 <= C2; D4 <= C3; D5 <= C4; D6 <= C5; D7 <= C6; D8 <= C7; D9 <= C8; D10 <= C9; D11 <= C10; D12 <= C11; D13 <= C12; D14 <= C13; D15 <= C14; D16 <= C15; D17 <= C16; D18 <= C17; D19 <= C18; D20 <= C19; D21 <= C20; D22 <= C21; D23 <= C22; D24 <= C23; D25 <= C24; D26 <= C25; D27 <= C26; D28 <= C27; D29 <= C28; D30 <= C29; D31 <= C30; D32 <= C31; D33 <= C32; D34 <= C33; D35 <= C34; D36 <= C35; D37 <= C36; D38 <= C37; D39 <= C38; D40 <= C39; D41 <= C40; D42 <= C41; D43 <= C42; D44 <= C43; D45 <= C44; D46 <= C45; D47 <= C46; D48 <= C47; D49 <= C48; D50 <= C49; D51 <= C50; D52 <= C51; D53 <= C52; D54 <= C53; D55 <= C54; D56 <= C55; D57 <= C56; D58 <= C57; D59 <= C58; D60 <= C59; D61 <= C60; D62 <= C61; D63 <= C62; D64 <= C63+h3;
    hash_reg <= {A64[24 +: 8], A64[16 +: 8], A64[ 8 +: 8], A64[ 0 +: 8],
                 B64[24 +: 8], B64[16 +: 8], B64[ 8 +: 8], B64[ 0 +: 8],
                 C64[24 +: 8], C64[16 +: 8], C64[ 8 +: 8], C64[ 0 +: 8],
                 D64[24 +: 8], D64[16 +: 8], D64[ 8 +: 8], D64[ 0 +: 8]};

    B1 <= B0+(((A0+((B0&C0)|((~B0)&D0))+32'hd76aa478+w[0+:32])<<7)|((A0+((B0&C0)|((~B0)&D0))+32'hd76aa478+w[0+:32])>>25));
    B2 <= B1+(((A1+((B1&C1)|((~B1)&D1))+32'he8c7b756+w0[32+:32])<<12)|((A1+((B1&C1)|((~B1)&D1))+32'he8c7b756+w0[32+:32])>>20));
    B3 <= B2+(((A2+((B2&C2)|((~B2)&D2))+32'h242070db+32'h00000080)<<17)|((A2+((B2&C2)|((~B2)&D2))+32'h242070db+32'h00000080)>>15));
    B4 <= B3+(((A3+((B3&C3)|((~B3)&D3))+32'hc1bdceee)<<22)|((A3+((B3&C3)|((~B3)&D3))+32'hc1bdceee)>>10));
    B5 <= B4+(((A4+((B4&C4)|((~B4)&D4))+32'hf57c0faf)<<7)|((A4+((B4&C4)|((~B4)&D4))+32'hf57c0faf)>>25));
    B6 <= B5+(((A5+((B5&C5)|((~B5)&D5))+32'h4787c62a)<<12)|((A5+((B5&C5)|((~B5)&D5))+32'h4787c62a)>>20));
    B7 <= B6+(((A6+((B6&C6)|((~B6)&D6))+32'ha8304613)<<17)|((A6+((B6&C6)|((~B6)&D6))+32'ha8304613)>>15));
    B8 <= B7+(((A7+((B7&C7)|((~B7)&D7))+32'hfd469501)<<22)|((A7+((B7&C7)|((~B7)&D7))+32'hfd469501)>>10));
    B9 <= B8+(((A8+((B8&C8)|((~B8)&D8))+32'h698098d8)<<7)|((A8+((B8&C8)|((~B8)&D8))+32'h698098d8)>>25));
    B10 <= B9+(((A9+((B9&C9)|((~B9)&D9))+32'h8b44f7af)<<12)|((A9+((B9&C9)|((~B9)&D9))+32'h8b44f7af)>>20));
    B11 <= B10+(((A10+((B10&C10)|((~B10)&D10))+32'hffff5bb1)<<17)|((A10+((B10&C10)|((~B10)&D10))+32'hffff5bb1)>>15));
    B12 <= B11+(((A11+((B11&C11)|((~B11)&D11))+32'h895cd7be)<<22)|((A11+((B11&C11)|((~B11)&D11))+32'h895cd7be)>>10));
    B13 <= B12+(((A12+((B12&C12)|((~B12)&D12))+32'h6b901122)<<7)|((A12+((B12&C12)|((~B12)&D12))+32'h6b901122)>>25));
    B14 <= B13+(((A13+((B13&C13)|((~B13)&D13))+32'hfd987193)<<12)|((A13+((B13&C13)|((~B13)&D13))+32'hfd987193)>>20));
    B15 <= B14+(((A14+((B14&C14)|((~B14)&D14))+32'ha679438e+32'h00000040)<<17)|((A14+((B14&C14)|((~B14)&D14))+32'ha679438e+32'h00000040)>>15));
    B16 <= B15+(((A15+((B15&C15)|((~B15)&D15))+32'h49b40821)<<22)|((A15+((B15&C15)|((~B15)&D15))+32'h49b40821)>>10));

    B17 <= B16+(((A16+((B16&D16)|((~D16)&C16))+32'hf61e2562+w15[32+:32])<<5)|((A16+((B16&D16)|((~D16)&C16))+32'hf61e2562+w15[32+:32])>>27));
    B18 <= B17+(((A17+((B17&D17)|((~D17)&C17))+32'hc040b340)<<9)|((A17+((B17&D17)|((~D17)&C17))+32'hc040b340)>>23));
    B19 <= B18+(((A18+((B18&D18)|((~D18)&C18))+32'h265e5a51)<<14)|((A18+((B18&D18)|((~D18)&C18))+32'h265e5a51)>>18));
    B20 <= B19+(((A19+((B19&D19)|((~D19)&C19))+32'he9b6c7aa+w18[0+:32])<<20)|((A19+((B19&D19)|((~D19)&C19))+32'he9b6c7aa+w18[0+:32])>>12));
    B21 <= B20+(((A20+((B20&D20)|((~D20)&C20))+32'hd62f105d)<<5)|((A20+((B20&D20)|((~D20)&C20))+32'hd62f105d)>>27));
    B22 <= B21+(((A21+((B21&D21)|((~D21)&C21))+32'h02441453)<<9)|((A21+((B21&D21)|((~D21)&C21))+32'h02441453)>>23));
    B23 <= B22+(((A22+((B22&D22)|((~D22)&C22))+32'hd8a1e681)<<14)|((A22+((B22&D22)|((~D22)&C22))+32'hd8a1e681)>>18));
    B24 <= B23+(((A23+((B23&D23)|((~D23)&C23))+32'he7d3fbc8)<<20)|((A23+((B23&D23)|((~D23)&C23))+32'he7d3fbc8)>>12));
    B25 <= B24+(((A24+((B24&D24)|((~D24)&C24))+32'h21e1cde6)<<5)|((A24+((B24&D24)|((~D24)&C24))+32'h21e1cde6)>>27));
    B26 <= B25+(((A25+((B25&D25)|((~D25)&C25))+32'hc33707d6+32'h00000040)<<9)|((A25+((B25&D25)|((~D25)&C25))+32'hc33707d6+32'h00000040)>>23));
    B27 <= B26+(((A26+((B26&D26)|((~D26)&C26))+32'hf4d50d87)<<14)|((A26+((B26&D26)|((~D26)&C26))+32'hf4d50d87)>>18));
    B28 <= B27+(((A27+((B27&D27)|((~D27)&C27))+32'h455a14ed)<<20)|((A27+((B27&D27)|((~D27)&C27))+32'h455a14ed)>>12));
    B29 <= B28+(((A28+((B28&D28)|((~D28)&C28))+32'ha9e3e905)<<5)|((A28+((B28&D28)|((~D28)&C28))+32'ha9e3e905)>>27));
    B30 <= B29+(((A29+((B29&D29)|((~D29)&C29))+32'hfcefa3f8+32'h00000080)<<9)|((A29+((B29&D29)|((~D29)&C29))+32'hfcefa3f8+32'h00000080)>>23));
    B31 <= B30+(((A30+((B30&D30)|((~D30)&C30))+32'h676f02d9)<<14)|((A30+((B30&D30)|((~D30)&C30))+32'h676f02d9)>>18));
    B32 <= B31+(((A31+((B31&D31)|((~D31)&C31))+32'h8d2a4c8a)<<20)|((A31+((B31&D31)|((~D31)&C31))+32'h8d2a4c8a)>>12));

    B33 <= B32+(((A32+(B32^C32^D32)+32'hfffa3942)<<4)|((A32+(B32^C32^D32)+32'hfffa3942)>>28));
    B34 <= B33+(((A33+(B33^C33^D33)+32'h8771f681)<<11)|((A33+(B33^C33^D33)+32'h8771f681)>>21));
    B35 <= B34+(((A34+(B34^C34^D34)+32'h6d9d6122)<<16)|((A34+(B34^C34^D34)+32'h6d9d6122)>>16));
    B36 <= B35+(((A35+(B35^C35^D35)+32'hfde5380c+32'h00000040)<<23)|((A35+(B35^C35^D35)+32'hfde5380c+32'h00000040)>>9));
    B37 <= B36+(((A36+(B36^C36^D36)+32'ha4beea44+w35[32+:32])<<4)|((A36+(B36^C36^D36)+32'ha4beea44+w35[32+:32])>>28));
    B38 <= B37+(((A37+(B37^C37^D37)+32'h4bdecfa9)<<11)|((A37+(B37^C37^D37)+32'h4bdecfa9)>>21));
    B39 <= B38+(((A38+(B38^C38^D38)+32'hf6bb4b60)<<16)|((A38+(B38^C38^D38)+32'hf6bb4b60)>>16));
    B40 <= B39+(((A39+(B39^C39^D39)+32'hbebfbc70)<<23)|((A39+(B39^C39^D39)+32'hbebfbc70)>>9));
    B41 <= B40+(((A40+(B40^C40^D40)+32'h289b7ec6)<<4)|((A40+(B40^C40^D40)+32'h289b7ec6)>>28));
    B42 <= B41+(((A41+(B41^C41^D41)+32'heaa127fa+w40[0+:32])<<11)|((A41+(B41^C41^D41)+32'heaa127fa+w40[0+:32])>>21));
    B43 <= B42+(((A42+(B42^C42^D42)+32'hd4ef3085)<<16)|((A42+(B42^C42^D42)+32'hd4ef3085)>>16));
    B44 <= B43+(((A43+(B43^C43^D43)+32'h04881d05)<<23)|((A43+(B43^C43^D43)+32'h04881d05)>>9));
    B45 <= B44+(((A44+(B44^C44^D44)+32'hd9d4d039)<<4)|((A44+(B44^C44^D44)+32'hd9d4d039)>>28));
    B46 <= B45+(((A45+(B45^C45^D45)+32'he6db99e5)<<11)|((A45+(B45^C45^D45)+32'he6db99e5)>>21));
    B47 <= B46+(((A46+(B46^C46^D46)+32'h1fa27cf8)<<16)|((A46+(B46^C46^D46)+32'h1fa27cf8)>>16));
    B48 <= B47+(((A47+(B47^C47^D47)+32'hc4ac5665+32'h00000080)<<23)|((A47+(B47^C47^D47)+32'hc4ac5665+32'h00000080)>>9));

    B49 <= B48+(((A48+(C48^(B48|(~D48)))+32'hf4292244+w47[0+:32])<<6)|((A48+(C48^(B48|(~D48)))+32'hf4292244+w47[0+:32])>>26));
    B50 <= B49+(((A49+(C49^(B49|(~D49)))+32'h432aff97)<<10)|((A49+(C49^(B49|(~D49)))+32'h432aff97)>>22));
    B51 <= B50+(((A50+(C50^(B50|(~D50)))+32'hab9423a7+32'h00000040)<<15)|((A50+(C50^(B50|(~D50)))+32'hab9423a7+32'h00000040)>>17));
    B52 <= B51+(((A51+(C51^(B51|(~D51)))+32'hfc93a039)<<21)|((A51+(C51^(B51|(~D51)))+32'hfc93a039)>>11));
    B53 <= B52+(((A52+(C52^(B52|(~D52)))+32'h655b59c3)<<6)|((A52+(C52^(B52|(~D52)))+32'h655b59c3)>>26));
    B54 <= B53+(((A53+(C53^(B53|(~D53)))+32'h8f0ccc92)<<10)|((A53+(C53^(B53|(~D53)))+32'h8f0ccc92)>>22));
    B55 <= B54+(((A54+(C54^(B54|(~D54)))+32'hffeff47d)<<15)|((A54+(C54^(B54|(~D54)))+32'hffeff47d)>>17));
    B56 <= B55+(((A55+(C55^(B55|(~D55)))+32'h85845dd1+w54[32+:32])<<21)|((A55+(C55^(B55|(~D55)))+32'h85845dd1+w54[32+:32])>>11));
    B57 <= B56+(((A56+(C56^(B56|(~D56)))+32'h6fa87e4f)<<6)|((A56+(C56^(B56|(~D56)))+32'h6fa87e4f)>>26));
    B58 <= B57+(((A57+(C57^(B57|(~D57)))+32'hfe2ce6e0)<<10)|((A57+(C57^(B57|(~D57)))+32'hfe2ce6e0)>>22));
    B59 <= B58+(((A58+(C58^(B58|(~D58)))+32'ha3014314)<<15)|((A58+(C58^(B58|(~D58)))+32'ha3014314)>>17));
    B60 <= B59+(((A59+(C59^(B59|(~D59)))+32'h4e0811a1)<<21)|((A59+(C59^(B59|(~D59)))+32'h4e0811a1)>>11));
    B61 <= B60+(((A60+(C60^(B60|(~D60)))+32'hf7537e82)<<6)|((A60+(C60^(B60|(~D60)))+32'hf7537e82)>>26));
    B62 <= B61+(((A61+(C61^(B61|(~D61)))+32'hbd3af235)<<10)|((A61+(C61^(B61|(~D61)))+32'hbd3af235)>>22));
    B63 <= B62+(((A62+(C62^(B62|(~D62)))+32'h2ad7d2bb+32'h00000080)<<15)|((A62+(C62^(B62|(~D62)))+32'h2ad7d2bb+32'h00000080)>>17));
    B64 <= h1+B63+(((A63+(C63^(B63|(~D63)))+32'heb86d391)<<21)|((A63+(C63^(B63|(~D63)))+32'heb86d391)>>11));

end

endmodule


