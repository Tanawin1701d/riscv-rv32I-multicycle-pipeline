`timescale 1ns/1ps

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
output wire[ROW_WIDTH-1 :0]                 poolReadData

);




wire[READ_ADDR_SIZE-1: 0] readIdxMaster; //// act as wire

reg [ROW_WIDTH-1: 0] mem [0: 2**READ_ADDR_SIZE -1];



assign readIdxMaster = readEns[1] ? readAddrs[READ_ADDR_SIZE*2-1 : READ_ADDR_SIZE] :
                       readEns[0] ? readAddrs[READ_ADDR_SIZE  -1 :              0] :
                       0;
assign poolReadData = mem[readIdxMaster];

assign readfin[1]    = readEns[1];
assign readfin[0]    = readEns[0] & (~readEns[1]);



always @(posedge  clk) begin
    if (writeEn) begin
        ///$display("save to %d with val %d", writeAddr, writeData);
        mem[writeAddr] <= writeData;
    end
    
end


endmodule