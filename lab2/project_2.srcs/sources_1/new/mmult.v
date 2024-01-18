
module mmult(
           input  wire clk, reset_n, enable,
           input  wire [0:9*8-1] A_mat, B_mat,
           output wire valid,
           output wire [0:9*17-1] C_mat);

reg [0:9*8-1] A;
reg [0:9*8-1] B;
reg [0:9*17-1] C;
reg temp, temp2;
assign valid = temp;
assign C_mat = C;
integer cnt = 0;
always @(posedge clk)
begin
    if(~reset_n)
    begin
        A <= A_mat;
        B <= B_mat;
        C <= 0;
        temp <= 0;
        temp2 <= 1;
        cnt = 0;
    end
    else if(enable && ~valid)
    begin
        C <= C << 51;
        A <= A << 24;

        C[102:118] <= A[0:7]*B[0:7]+A[8:15]*B[24:31]+A[16:23]*B[48:55];
        C[119:135] <= A[0:7]*B[8:15]+A[8:15]*B[32:39]+A[16:23]*B[56:63];
        C[136:152] <= A[0:7]*B[16:23]+A[8:15]*B[40:47]+A[16:23]*B[64:71];
        cnt <= cnt+1;
        temp <= |(cnt==2);
    end
end
endmodule
