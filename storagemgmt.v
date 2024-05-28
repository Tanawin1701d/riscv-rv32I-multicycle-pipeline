module storageMgmt #( ////////////// multiread single write
    parameter READ_ADDR_SIZE = 28, parameter ROW_WIDTH = 32,
    parameter AMT_READER = 2 //// writer fix to one 
) (
input wire[READ_ADDR_SIZE*AMT_READER-1: 0] readAddrs,
input wire[AMT_READER-1:                0] readEns,

input wire[READ_ADDR_SIZE-1:            0] writeAddr,
input wire[ROW_WIDTH-1:                 0] writeData,
input wire                                 writeEn,
input wire                                 rst,
input wire                                 startSig,
input wire                                 clk,


output wire[AMT_READER-1:                0] readfin,
output reg[ROW_WIDTH-1 :0]                poolReadData

);




wire[READ_ADDR_SIZE-1: 0] readIdxMaster;
wire[AMT_READER-1    : 0]     actualEnable;
wire[AMT_READER-1    : 0]     prevfalse;


assign readfin = actualEnable;

reg [ROW_WIDTH-1: 0] mem [0: 2**READ_ADDR_SIZE -1];


assign prevfalse[0] = ~readEns[0];
assign actualEnable[0] = readEns[0];


genvar i;

generate
    
    for (i = 1; i < AMT_READER; i = i + 1)begin
        
        assign actualEnable[i] = prevfalse[i-1] & readEns[i];
        assign prevfalse[i]    = prevfalse[i-1] & (~readEns[i]);

        always @(*) begin
              if (actualEnable[i]) begin
                    poolReadData = mem[readAddrs[READ_ADDR_SIZE*(i+1)-1: READ_ADDR_SIZE*(i)]];
              end

        end

    end


endgenerate 


always @(*) begin
    
    if (actualEnable[0]) begin
        poolReadData = mem[readAddrs[READ_ADDR_SIZE-1: 0]];
    end

end


always @(posedge  clk) begin
    if (writeEn) begin
        mem[writeAddr] <<= writeData;
    end
    
end


endmodule