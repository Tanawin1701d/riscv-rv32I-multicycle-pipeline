module execute #(
    parameter XLEN      = 32, parameter REG_IDX = 5,
    parameter UOP_WIDTH = 7 , parameter AMT_REG = 32,
    parameter READ_ADDR_SIZE = 32
) (

input wire                 beforePipReadyToSend,
input wire                 nextPipReadyToRcv,
input wire                 startSig,
input wire                 rst,
input wire                 clk,
    
input wire                 r1_valid,
input wire[REG_IDX-1 : 0]  r1_idx,
input wire[XLEN-1 : 0]     r1_val,

input wire                 r2_valid,
input wire[REG_IDX-1 : 0]  r2_idx,
input wire[XLEN-1 : 0]     r2_val,

input wire                 r3_valid,
input wire[REG_IDX-1 : 0]  r3_idx,
input wire[XLEN-1 : 0]     r3_val,

input wire                 rd_valid,
input wire[REG_IDX-1 : 0]  rd_idx,
input wire[XLEN-1 : 0]     rd_val,

input wire                 isLsUopUse,
input wire                 isMemLoad,
input wire[1:0]            ldsize,
input wire                 ldextendMode,


input wire                 isAluUopUse,
input wire                 isAdd,
input wire                 isSub,
input wire                 isXor,
input wire                 isOr,
input wire                 isAnd,
input wire                 isCmpLessThanSign,
input wire                 isCmpLessThanUSign,
input wire                 isShiftLeftLogical,
input wire                 isShiftRightLogical,
input wire                 isShiftRightArith,


input wire                 isJmpUopUse,
input wire                 isJalR,
input wire                 isJal,
input wire                 jumpExtendMode,
input wire                 isEq,
input wire                 isNEq,
input wire                 isLt,
input wire                 isGe,

input wire                 isLdPcUopUse,
input wire                 isNeedPc,

input wire                 pc,
input wire                 nextPc,

input wire                 mem_readFin,
input wire[XLEN-1: 0]      mem_radData,

input wire[REG_IDX-1 : 0] bp_idx,
input wire[XLEN-1 : 0]    bp_val,

input  wire[XLEN-1 : 0]    reg1_readData,
input  wire[XLEN-1 : 0]    reg2_readData,

output reg                wb_valid,   ///// act as wire
output reg[REG_IDX-1 : 0] wb_idx,     ///// act as wire
output reg[XLEN-1 : 0]    wb_val,     ///// act as wire 
output reg                wb_en_meta,      ///// act as wire valid to valid and idx
output reg                wb_en_data,      ///// act as wire valid to valid and idx


output wire                      misPredict,
output wire[READ_ADDR_SIZE-1: 0] reqPc,

output reg                      mem_readEn,
output reg[READ_ADDR_SIZE-1: 0] mem_readAddr,
output reg                      mem_writeEn,
output reg[READ_ADDR_SIZE-1: 0] mem_writeAddr,
output reg[XLEN          -1: 0] mem_writeData,

output reg[REG_IDX-1: 0]    regFile1_readIdx,
output reg[REG_IDX-1: 0]    regFile2_readIdx,


output reg                 r1_write_valid, //// act as wire
output reg[XLEN-1 : 0]     r1_write_val,   ///// act as wire 
output reg                 r1_write_en,    ///// act as wire

output reg                 r2_write_valid,
output reg[XLEN-1 : 0]     r2_write_val,
output reg                 r2_write_en,

output wire                      curPipReadyToRcv,
output wire                      curPipReadyToSend


);


/////////// wait recv




reg[6-1: 0] pipState;

parameter idleState       = 6'b000000;
parameter waitBefState    = 6'b000001;
parameter regAccess       = 6'b000010;
parameter simpleExec      = 6'b000100;
parameter shiftLeftReg    = 6'b001000;
parameter shiftRightReg   = 6'b001000;
parameter shiftRightArReg = 6'b001000;
parameter ldstReg         = 6'b010000;
parameter waitSendState   = 6'b100000;

assign curPipReadyToRcv  = (pipState == waitBefState) | (curPipReadyToSend && nextPipReadyToRcv);

assign curPipReadyToSend = 
((pipState == simpleExec) & isAluUopUse & ( 
    isAdd | isSub | isXor | isOr | isAnd | isCmpLessThanSign | isCmpLessThanUSign
)) |
(((pipState == shiftLeftReg) | (pipState == shiftRightReg) | (pipState == shiftRightArReg)) &
    r2_val <= 1
) |
((pipState == simpleExec) & ( isJmpUopUse | isLdPcUopUse)) |
( (pipState == ldstReg) & (isLsUopUse) & (mem_readFin))|
(pipState == waitSendState);

wire cmpLtSign = (r1_val[XLEN-1] & (~r2_val[XLEN-1])) & 
                 ((r1_val[XLEN-1] == r2_val[XLEN-1]) & (r1_val[XLEN-2: 0] < r2_val[XLEN-2: 0]));

wire cmpLtUnSign = r1_val[XLEN-1] < r2_val[XLEN-1];



always @(posedge clk ) begin

        if (rst) begin
            pipState <= idleState;
        
        end else if (startSig) begin
            
            if (beforePipReadyToSend) begin
                pipState <= regAccess;
            end else begin
                pipState <= waitBefState;
            end

        end else begin

            if (pipState == waitBefState)begin
                if (beforePipReadyToSend) begin
                    pipState <= regAccess;
                end  else begin
                    pipState <= waitBefState;
                end
            end else if (pipState == regAccess) begin
                pipState <= simpleExec;
            end else if (pipState == simpleExec) begin
                
                if (isAluUopUse) begin
                    if (isShiftLeftLogical) begin
                        pipState <= shiftLeftReg;
                    end

                    if (isShiftRightLogical) begin
                        pipState <= shiftRightReg;
                    end

                    if (isShiftRightArith) begin
                        pipState <= shiftRightArReg;
                    end
                end
                if (isLsUopUse) begin
                    pipState <= ldstReg;
                end
                if ((~isAluUopUse) & (~isLsUopUse)) begin
                    if (nextPipReadyToRcv)begin
                        if (beforePipReadyToSend) begin
                            pipState <= regAccess;
                        end else begin
                            pipState <= waitBefState;
                        end
                    end else begin
                        pipState <= waitSendState;
                    end
                end

            end else if (
                   ((
                    (pipState == shiftLeftReg   ) | 
                    (pipState == shiftRightReg  ) |
                    (pipState == shiftRightArReg)) & ( r2_val[4:0] == 1)) | 
                    ((pipState == ldstReg) & mem_readFin)
                    ) begin
                        /////// in shift mode
                            if (nextPipReadyToRcv)begin
                                if (beforePipReadyToSend) begin
                                    pipState <= regAccess;
                                end else begin
                                    pipState <= waitBefState;
                                end
                            end else begin
                                pipState <= waitSendState;
                            end          

            end else if (pipState == waitSendState) begin
                if (nextPipReadyToRcv) begin
                    if (beforePipReadyToSend) begin
                        pipState <= regAccess;
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

    ////// reg access
    

always @(*) begin

    regFile1_readIdx = r1_idx;

    if ( (pipState == regAccess) & (~r1_valid) ) begin
        r1_write_valid = 1;
        r1_write_en    = 1;

        if (r1_idx == 0)begin
            r1_write_val = 0;
        end else begin
            if (bp_idx == r1_idx)begin
                r1_write_val = bp_val;
            end else begin
                r1_write_val = reg1_readData; /// read from memory
            end

        end
        
    end else begin
        r1_write_valid <= 0;
        r1_write_val   <= 0;
        r1_write_en    <= 0;
    end
    
end

wire[4:0] r2Reduce = r2_val[4:0]-1;

always @(*) begin

    regFile2_readIdx = r2_idx;

    if ( (pipState == regAccess) & (~r2_valid) ) begin
        r2_write_valid = 1;
        r2_write_en    = 1;

        if (r2_idx == 0)begin
            r2_write_val = 0;
        end else begin
            if (bp_idx == r2_idx)begin
                r2_write_val = bp_val;
            end else begin
                r2_write_val = reg2_readData; /// read from memory
            end

        end

    end else if (((pipState == shiftLeftReg) | (pipState == shiftRightReg) |
                    (pipState == shiftRightArReg)) & (r2_val[4:0] > 1))begin

                    r2_write_valid = 1;
                    r2_write_val   = {r2_val[XLEN-1: 5], r2Reduce};
                    r2_write_en    = 1;
                    
    end else begin
        r2_write_valid = 0;
        r2_write_val   = 0;
        r2_write_en    = 0;
    end
    
end

    ////// write back situation except val

    /////// write back val

always @(*) begin
    wb_valid      = 0;
    wb_idx        = 0;
    wb_val        = 0;
    wb_en_meta    = 0;
    wb_en_data    = 0;
    mem_writeData = 0;

    if (pipState == regAccess) begin
        wb_valid   = rd_valid;
        wb_idx     = rd_idx;
        wb_val     = rd_val;
        wb_en_meta = 1;
        wb_en_data = 1;
    end else if (pipState == simpleExec) begin

        if (isAluUopUse) begin
            wb_valid  = rd_valid;
            wb_en_data = 1;                
            if (isAdd)               begin wb_val = r1_val + r2_val; end          
            if (isSub)               begin wb_val = r1_val - r2_val; end          
            if (isXor)               begin wb_val = r1_val ^ r2_val; end          
            if (isOr)                begin wb_val = r1_val | r2_val; end         
            if (isAnd)               begin wb_val = r1_val & r2_val; end          
            if (isCmpLessThanSign)   begin wb_val = { 31'b0,  cmpLtSign}; end
            if (isCmpLessThanUSign)  begin wb_val = { 31'b0,  cmpLtUnSign}; end
            if (isShiftLeftLogical |
                isShiftRightLogical | 
                isShiftRightArith)  begin wb_val = r1_val; end

        end
        
        if (isJmpUopUse & (isJal | isJalR)) begin
            wb_valid  = rd_valid;
            wb_en_data = 1;
            wb_val = pc + 4;
        end

        if (isLdPcUopUse) begin
            wb_valid  = rd_valid;
            wb_en_data = 1;
            if (isNeedPc) begin
                wb_val = pc + r2_val;
            end else begin
                wb_val = r2_val;
            end
        end
        
    end else if (pipState == shiftLeftReg) begin
        if (r2_val[4:0] > 0)begin
            wb_en_data = 1;
            wb_val = wb_val << 1;
        end
    end else if (pipState == shiftRightReg) begin
        if (r2_val[4:0] > 0)begin
            wb_en_data = 1;
            wb_val = wb_val >> 1;
        end
    end else if (pipState == shiftRightArReg) begin
        if (r2_val[4:0] > 0)begin
            wb_en_data = 1;
            wb_val[XLEN-2:0] = wb_val[XLEN-2:0] >> 1;
        end
    end else if (pipState == ldstReg) begin
        if ( (ldsize == 2'b00) & mem_readFin) begin ///// 8 bit mode
            wb_en_data = 1;
            if (ldextendMode)begin /////// sign extend mode
                wb_val = {{24{mem_radData[7]}},mem_radData[7:0]};
            end else begin
                wb_val = {24'b0,mem_radData[7:0]};
            end

            if (~isMemLoad)begin
                mem_writeData    = {mem_radData[XLEN-1: 8], r2_val[7: 0]};
            end
        end

        if ( (ldsize == 2'b01) & mem_readFin) begin ///// 16 bit mode
            wb_en_data = 1;
            if (ldextendMode)begin /////// sign extend mode
                wb_val = {{16{mem_radData[15]}},mem_radData[15:0]};
            end else begin
                wb_val = {16'b0,mem_radData[15:0]};
            end

            if (~isMemLoad)begin
                mem_writeData    = {mem_radData[XLEN-1: 16], r2_val[15: 0]};
            end
        end

        if ( (ldsize == 2'b10) & mem_readFin) begin ///// 32 bit mode
            wb_en_data = 1;
            wb_val = mem_radData;

            if (~isMemLoad)begin
                mem_writeData    = r2_val;
            end
        end
    end
end

    ///////////// test pip 


always @(*) begin

    mem_readEn       = 0;    
    mem_readAddr     = r1_val + r2_val;      
    mem_writeEn      = 0;     
    mem_writeAddr    = r1_val + r2_val;       
    

    if ( pipState ==  ldstReg) begin
            mem_readEn = 1;
            if ( (~isMemLoad) & mem_readFin)begin
                mem_writeEn      = 1;
            end
    end
    
end

assign misPredict = ((pipState == simpleExec) && isJmpUopUse) & (
isJalR         |         
isJal          |        
(isEq    &  (r1_val == r2_val))           | (isNEq   &  (r1_val != r2_val))              | 
(isLt    &  (jumpExtendMode & cmpLtSign)) | (isGe    &  (jumpExtendMode & ~(cmpLtSign))) |
(isLt    &  ((~jumpExtendMode) &   cmpLtUnSign)) | (isGe    &  ((~jumpExtendMode) & (~cmpLtUnSign)))
);

assign reqPc = ((pipState == simpleExec) && isJmpUopUse) ?
                 (isJal  ? pc + r2_val :
                  isJalR ? r1_val + r2_val :
                           pc + r3_val) : 0;

endmodule