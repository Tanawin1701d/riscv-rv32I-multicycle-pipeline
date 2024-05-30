`timescale 1ns/1ps

module writeBack #(
    parameter XLEN = 32, parameter REG_IDX = 5,
    parameter AMT_REG = 32
)(
input wire beforePipReadyToSend,
input wire nextPipReadyToRcv,
input wire rst,
input wire startSig,
input wire clk,

input wire                wb_valid,
input wire[REG_IDX-1: 0]  wb_idx,
input wire[XLEN-1   : 0]  wb_val,
input wire                wb_en_valid,
input wire                wb_en_idx,
input wire                wb_en_data,

output wire curPipReadyToRcv,
output wire curPipReadyToSend,

output wire[REG_IDX-1: 0] bp_idx,
output wire[XLEN-1:    0] bp_val,

output wire[REG_IDX-1: 0] regFileWriteIdx,
output wire[XLEN-1   : 0] regFileWriteVal,
output wire               regFileWriteEn
);

reg                writeBack_valid;
reg[REG_IDX-1: 0]  writeBack_idx;
reg[XLEN-1   : 0]  writeBack_val;
reg                writeBack_en_meta;
reg                writeBack_en_data;



always @(posedge clk ) begin

    if (wb_en_valid)begin
        writeBack_valid <= wb_valid;
    end

    if (wb_en_idx)begin
        writeBack_idx   <= wb_idx;
    end

    if (wb_en_data)begin
        writeBack_val   <= wb_val;
    end
    
end

reg[3-1: 0] pipState;
parameter idleState      = 3'b000;
parameter waitBefState   = 3'b001;
parameter sendingState   = 3'b010;
parameter waitSendState  = 3'b100;

assign bp_idx = ((pipState == sendingState) & writeBack_valid & (writeBack_idx != 0)) 
                ? writeBack_idx : 0;
assign bp_val = ((pipState == sendingState) & writeBack_valid & (writeBack_idx != 0)) 
                ? writeBack_val : 0;


assign regFileWriteIdx = writeBack_idx;
assign regFileWriteVal = writeBack_val;
assign regFileWriteEn  = (pipState == sendingState);


assign curPipReadyToRcv  = (pipState == waitBefState) | (curPipReadyToSend & nextPipReadyToRcv);
assign curPipReadyToSend = (pipState == sendingState);



always @(posedge clk ) begin

        if (rst) begin
            pipState <= idleState;
        
        end else if (startSig) begin
            
            if (beforePipReadyToSend) begin
                pipState <= sendingState;
            end else begin
                pipState <= waitBefState;
            end
        end else begin

            if (pipState == waitBefState)begin
                if (beforePipReadyToSend) begin
                    pipState <= sendingState;
                end  else begin
                    pipState <= waitBefState;
                end
            end else if ( (pipState == sendingState) | (pipState == waitSendState)) begin
                if (nextPipReadyToRcv) begin
                    if (beforePipReadyToSend) begin
                        pipState <= sendingState;
                    end else begin
                        pipState <= waitBefState;
                    end
                end else begin
                    pipState <= waitSendState;
                end
            end else begin
                pipState <= idleState;
            end
        end
    end


endmodule