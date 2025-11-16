`timescale 1ns/1ns

module storageMgmt #( ////////////// multiread single write
    parameter READ_ADDR_SIZE = 28, parameter ROW_WIDTH = 32,
    parameter AMT_READER = 2 //// writer fix to one 
) (
input wire[READ_ADDR_SIZE*AMT_READER-1: 0] readAddrs,
//input wire[AMT_READER-1:                0] readEns,
input wire                                 readEns0,
input wire                                 readEns1,

input wire[READ_ADDR_SIZE-1:            0] writeAddr,
input wire[ROW_WIDTH-1:                 0] writeData,
input wire                                 writeEn,
input wire                                 rst,
input wire                                 startSig,
input wire                                 clk,

output wire                                 readfin0,
output wire                                 readfin1,

output wire[ROW_WIDTH-1 :0]                 poolReadData

);




wire[READ_ADDR_SIZE-1: 0] readIdxMaster; //// act as wire

reg [ROW_WIDTH-1: 0] mem [0: 2**READ_ADDR_SIZE -1];



assign readIdxMaster = readEns1 ? readAddrs[READ_ADDR_SIZE*2-1 : READ_ADDR_SIZE] :
                       readEns0 ? readAddrs[READ_ADDR_SIZE  -1 :              0] :
                       0;
assign poolReadData = mem[readIdxMaster];

assign readfin1    = readEns1;
assign readfin0    = readEns0 & (~readEns1);



always @(posedge  clk) begin
    if (writeEn) begin
        ///$display("save to %d with val %d", writeAddr, writeData);
        mem[writeAddr] <= writeData;
    end
    
end


endmodule