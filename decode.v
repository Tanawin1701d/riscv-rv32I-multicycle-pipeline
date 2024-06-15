`timescale 1ns/1ns

module decoder #(
    parameter XLEN      = 32, parameter REG_IDX = 5,
    parameter UOP_WIDTH = 7 , parameter AMT_REG = 32,
    parameter READ_ADDR_SIZE = 32
)(

input wire [XLEN          -1: 0] fetch_data,
input wire [READ_ADDR_SIZE-1: 0] fetch_cur_pc,
input wire [READ_ADDR_SIZE-1: 0] fetch_nxt_pc,
input wire                       beforePipReadyToSend,
input wire                       nextPipReadyToRcv,
input wire                       rst,
input wire                       startSig,
input wire                       interrupt_start,
input wire                       clk,

input wire                       r1_write_valid,
input wire [XLEN          -1: 0] r1_write_val,
input wire                       r1_write_en,

input wire                       r2_write_valid,
input wire [XLEN          -1: 0] r2_write_val,
input wire                       r2_write_en,



output wire                     curPipReadyToRcv,
output wire                     curPipReadyToSend,

output reg                      r1_valid,
output reg[REG_IDX-1 : 0]       r1_idx,
output reg[XLEN-1 : 0]          r1_val,

output reg                      r2_valid,
output reg[REG_IDX-1 : 0]       r2_idx,
output reg[XLEN-1 : 0]          r2_val,

output reg                      r3_valid,
output reg[REG_IDX-1 : 0]       r3_idx,
output reg[XLEN-1 : 0]          r3_val,

output reg                      rd_valid,
output reg[REG_IDX-1 : 0]       rd_idx,
output reg[XLEN-1 : 0]          rd_val,

output reg                      isLsUopUse,
output reg                      isMemLoad,
output reg[1:0]                 ldsize,
output reg                      ldextendMode,


output reg                      isAluUopUse,
output reg                      isAdd,
output reg                      isSub,
output reg                      isXor,
output reg                      isOr,
output reg                      isAnd,
output reg                      isCmpLessThanSign,
output reg                      isCmpLessThanUSign,
output reg                      isShiftLeftLogical,
output reg                      isShiftRightLogical,
output reg                      isShiftRightArith,


output reg                      isJmpUopUse,
output reg                      isJalR,
output reg                      isJal,
output reg                      jumpExtendMode,
output reg                      isEq,
output reg                      isNEq,
output reg                      isLt,
output reg                      isGe,

output reg                      isLdPcUopUse,
output reg                      isNeedPc,

output reg[READ_ADDR_SIZE-1: 0] pc,
output reg[READ_ADDR_SIZE-1: 0] nextPc

);

parameter OP_ALL_h = 7;       parameter OP_ALL_l =  0;
parameter OP_H_h   = 7;       parameter OP_H_l   =  5;
parameter OP_L_h   = 5;       parameter OP_L_l   =  2;
parameter IDX_RD_h =12;       parameter IDX_RD_l =  7;
parameter IDX_R1_h =20;       parameter IDX_R1_l = 15;
parameter IDX_R2_h =25;       parameter IDX_R2_l = 20;
parameter FUNCT3_h =15;       parameter FUNCT3_l = 12;
parameter FUNCT7_h =32;       parameter FUNCT7_l = 25;

parameter IMM_I_0_12_h = 32;  parameter IMM_I_0_12_l = 20;

parameter IMM_S_5_12_h = 32;  parameter IMM_S_5_12_l = 25;
parameter IMM_S_0_5_h  = 12;  parameter IMM_S_0_5_l  = 7;

parameter IMM_B_12_h   =  32; parameter IMM_B_12_l    = 31;
parameter IMM_B_5_11_h =  31; parameter IMM_B_5_11_l  = 25;
parameter IMM_B_11_h   =   8; parameter   IMM_B_11_l  = 7;
parameter IMM_B_1_5_h  =  12; parameter  IMM_B_1_5_l  = 8;

parameter IMM_U_12_32_h  = 32;  parameter IMM_U_12_32_l = 12;
parameter fixdown = 12;

parameter IMM_J_20_h    = 32; parameter IMM_J_20_l    = 31;
parameter IMM_J_1_11_h  = 31; parameter IMM_J_1_11_l  = 21;
parameter IMM_J_11_h    = 21; parameter IMM_J_11_l    = 20;
parameter IMM_J_12_20_h = 20; parameter IMM_J_12_20_l = 12;


parameter loadSizeBit_h = 14; parameter loadSizeBit_l = 12;
parameter loadExtendModeBit = 14; 


reg[3-1: 0] pipState;
parameter idleState      = 3'b000;
parameter waitBefState   = 3'b001;
parameter sendingState   = 3'b010;
parameter waitSendState  = 3'b100;


parameter LOADSIZE_BIT_l  = FUNCT3_l;
parameter LOADSIZE_BIT_h  = FUNCT3_l + 2;

wire[UOP_WIDTH-1: 0] op = fetch_data[UOP_WIDTH-1:0];

assign curPipReadyToRcv  = (pipState == waitBefState) | (curPipReadyToSend & nextPipReadyToRcv);
assign curPipReadyToSend = (( (pipState == sendingState) & nextPipReadyToRcv) | (pipState == waitSendState)) & (~interrupt_start);



always @(posedge clk ) begin

        if (rst) begin
            pipState <= idleState;
        
        end else if (startSig) begin
            
            if (beforePipReadyToSend) begin
                pipState <= sendingState;
            end else begin
                pipState <= waitBefState;
            end

        end else if (interrupt_start) begin
            if (beforePipReadyToSend)begin
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
            end else if (pipState == sendingState) begin
                if (nextPipReadyToRcv) begin
                    if (beforePipReadyToSend) begin
                        pipState <= sendingState;
                    end else begin
                        pipState <= waitBefState;
                    end
                end else begin
                    pipState <= sendingState;
                end
            end else if (pipState == waitSendState) begin
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



    always @(posedge clk ) begin


        if (nextPipReadyToRcv && (pipState == sendingState)) begin
            
            pc     <= fetch_cur_pc;
            nextPc <= fetch_nxt_pc;


            if (op[1:0] == 2'b11)begin

            

                if (op[OP_H_h-1:OP_H_l] == 2'b00)begin

                    if (op[OP_L_h-1:OP_L_l] == 3'b000) begin
                        /////////////// do load 
                        isLsUopUse   <= 1;
                        isAluUopUse  <= 0;
                        isJmpUopUse  <= 0;
                        isLdPcUopUse <= 0;

                        r1_valid <= 0;
                        r1_idx   <= fetch_data[IDX_R1_h-1: IDX_R1_l];

                        r2_valid <= 0;
                        r2_idx   <= 0;

                        r3_valid <= 1;
                        r3_idx   <= 0;
                        r3_val   <= {{20{fetch_data[IMM_I_0_12_h-1]}}, fetch_data[IMM_I_0_12_h-1: IMM_I_0_12_l]};

                        rd_valid <= 0;
                        rd_idx   <= fetch_data[IDX_RD_h-1: IDX_RD_l];

                        isMemLoad    <= 1;
                        ldsize       <= fetch_data[LOADSIZE_BIT_h-1: LOADSIZE_BIT_l];
                        ldextendMode <= fetch_data[loadExtendModeBit];


                    end else if (op[OP_L_h-1:OP_L_l] == 3'b100) begin
                        /////////////// do op imm decode
                        isLsUopUse   <= 0;
                        isAluUopUse  <= 1;
                        isJmpUopUse  <= 0;
                        isLdPcUopUse <= 0;

                        r1_valid <= 0;
                        r1_idx   <= fetch_data[IDX_R1_h-1: IDX_R1_l];

                        r2_valid <= 1;
                        r2_idx   <= 0;
                        r2_val   <= {{20{fetch_data[IMM_I_0_12_h-1]}}, fetch_data[IMM_I_0_12_h-1: IMM_I_0_12_l]};

                        r3_valid <= 0;
                        r3_idx   <= 0;

                        rd_valid <= 0;
                        rd_idx   <= fetch_data[IDX_RD_h-1: IDX_RD_l];

                        isAdd                <= fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b000;
                        isSub                <= 0;
                        isXor                <= fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b100;
                        isOr                 <= fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b110;
                        isAnd                <= fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b111;
                        isCmpLessThanSign    <= fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b010;
                        isCmpLessThanUSign   <= fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b011;
                        isShiftLeftLogical   <= fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b001;
                        isShiftRightLogical  <= fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b101 & (fetch_data[30] == 0);
                        isShiftRightArith    <= fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b101 & (fetch_data[30] == 1);



                    end else begin 
                        /////////////// do aul pc decoder
                        isLsUopUse   <= 0;
                        isAluUopUse  <= 0;
                        isJmpUopUse  <= 0;
                        isLdPcUopUse <= 1;

                        r1_valid <= 0;
                        r1_idx   <= 0;

                        r2_valid <= 1;
                        r2_idx   <= 0;
                        r2_val   <= {fetch_data[IMM_U_12_32_h-1: IMM_U_12_32_l], 12'b0};

                        r3_valid <= 0;
                        r3_idx   <= 0;

                        rd_valid <= 0;
                        rd_idx   <= fetch_data[IDX_RD_h-1: IDX_RD_l];

                        isNeedPc <= 1;

                    end

                end else if (op[OP_H_h-1:OP_H_l] == 2'b01) begin
                    if (op[OP_L_h-1:OP_L_l] == 3'b000) begin
                        /////////////// do store store 
                        isLsUopUse   <= 1;
                        isAluUopUse  <= 0;
                        isJmpUopUse  <= 0;
                        isLdPcUopUse <= 0;

                        r1_valid <= 0;
                        r1_idx   <= fetch_data[IDX_R1_h-1: IDX_R1_l];

                        r2_valid <= 0;
                        r2_idx   <= fetch_data[IDX_R2_h-1: IDX_R2_l];

                        r3_valid <= 1;
                        r3_idx   <= 0;
                        r3_val   <= { {20{
                                       fetch_data[IMM_I_0_12_h-1]}}, 
                                       fetch_data[IMM_S_5_12_h-1: IMM_S_5_12_l],
                                       fetch_data[IMM_S_0_5_h-1 :  IMM_S_0_5_l]
                                       };

                        rd_valid <= 0;
                        rd_idx   <= 0;

                        isMemLoad    <= 0;
                        ldsize       <= fetch_data[LOADSIZE_BIT_h-1: LOADSIZE_BIT_l];
                        ldextendMode <= fetch_data[loadExtendModeBit];

                    end else if (op[OP_L_h-1:OP_L_l] == 3'b100) begin
                        /////////////// do op decode
                        isLsUopUse   <= 0;
                        isAluUopUse  <= 1;
                        isJmpUopUse  <= 0;
                        isLdPcUopUse <= 0;

                        r1_valid <= 0;
                        r1_idx   <= fetch_data[IDX_R1_h-1: IDX_R1_l];

                        r2_valid <= 0;
                        r2_idx   <= fetch_data[IDX_R2_h-1: IDX_R2_l];

                        r3_valid <= 0;
                        r3_idx   <= 0;

                        rd_valid <= 0;
                        rd_idx   <= fetch_data[IDX_RD_h-1: IDX_RD_l];

                        isAdd                <= (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b000) & (fetch_data[30] == 0);
                        isSub                <= (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b000) & (fetch_data[30] == 1);
                        isXor                <=  fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b100;
                        isOr                 <=  fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b110;
                        isAnd                <=  fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b111;
                        isCmpLessThanSign    <=  fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b010;
                        isCmpLessThanUSign   <=  fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b011;
                        isShiftLeftLogical   <=  fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b001;
                        isShiftRightLogical  <= (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b101) & (fetch_data[30] == 0);
                        isShiftRightArith    <= (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b101) & (fetch_data[30] == 1);

                    end else begin 
                        /////////////// do lui pc decoder
                        isLsUopUse   <= 0;
                        isAluUopUse  <= 0;
                        isJmpUopUse  <= 0;
                        isLdPcUopUse <= 1;

                        r1_valid <= 0;
                        r1_idx   <= 0;

                        r2_valid <= 1;
                        r2_idx   <= 0;
                        r2_val   <= {fetch_data[IMM_U_12_32_h-1: IMM_U_12_32_l], 12'b0};

                        r3_valid <= 0;
                        r3_idx   <= 0;

                        rd_valid <= 0;
                        rd_idx   <= fetch_data[IDX_RD_h-1: IDX_RD_l];

                        isNeedPc <= 0;

                    end
                end else if (op[OP_H_h-1:OP_H_l] == 2'b11) begin
                    if (op[OP_L_h-1:OP_L_l] == 3'b000) begin
                        /////////////// do branch store 
                        isLsUopUse   <= 0;
                        isAluUopUse  <= 0;
                        isJmpUopUse  <= 1;
                        isLdPcUopUse <= 0;

                        r1_valid <= 0;
                        r1_idx   <= fetch_data[IDX_R1_h-1: IDX_R1_l];

                        r2_valid <= 0;
                        r2_idx   <= fetch_data[IDX_R2_h-1: IDX_R2_l];
                        

                        r3_valid <= 1;
                        r3_idx   <= 0;
                        r3_val   <= {
                            {20{fetch_data[IMM_B_12_h-1]}},
                                fetch_data[IMM_B_12_h  -1: IMM_B_12_l  ],
                                fetch_data[IMM_B_11_h  -1: IMM_B_11_l  ],
                                fetch_data[IMM_B_5_11_h-1: IMM_B_5_11_l],
                                fetch_data[IMM_B_1_5_h -1: IMM_B_1_5_l ],
                            1'b0
                        };

                        rd_valid <= 0;
                        rd_idx   <= fetch_data[IDX_RD_h-1: IDX_RD_l];


                        jumpExtendMode <= fetch_data[13];
                        isJalR         <= 0;
                        isJal          <= 0;
                        isEq           <= (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b000);
                        isNEq          <= (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b001);
                        isLt           <= (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b100) | (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b110);
                        isGe           <= (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b101) | (fetch_data[FUNCT3_h-1: FUNCT3_l] == 3'b111);

                    end else if (op[OP_L_h-1:OP_L_l] == 3'b001) begin
                        /////////////// do jalr decode
                        isLsUopUse   <= 0;
                        isAluUopUse  <= 0;
                        isJmpUopUse  <= 1;
                        isLdPcUopUse <= 0;

                        r1_valid <= 0;
                        r1_idx   <= fetch_data[IDX_R1_h-1: IDX_R1_l];

                        r2_valid <= 1;
                        r2_idx   <= 0;
                        r2_val   <= {{20{fetch_data[IMM_I_0_12_h-1]}}, fetch_data[IMM_I_0_12_h-1: IMM_I_0_12_l]};
                        

                        r3_valid <= 0;
                        r3_idx   <= 0;

                        rd_valid <= 0;
                        rd_idx   <= fetch_data[IDX_RD_h-1: IDX_RD_l];


                        isJalR         <= 1;
                        isJal          <= 0;
                        jumpExtendMode <= 0;
                        isEq           <= 0;
                        isNEq          <= 0;
                        isLt           <= 0;
                        isGe           <= 0;


                    end else begin 
                        /////////////// do jal decoder
                                                /////////////// do jalr decode
                        isLsUopUse   <= 0;
                        isAluUopUse  <= 0;
                        isJmpUopUse  <= 1;
                        isLdPcUopUse <= 0;

                        r1_valid <= 1;
                        r1_idx   <= 0;
                        r1_val   <= 0;

                        r2_valid <= 1;
                        r2_idx   <= 0;
                        r2_val   <=    {    12'b0,
                                            fetch_data[IMM_J_20_h   -1 :    IMM_J_20_l],
                                            fetch_data[IMM_J_12_20_h-1 : IMM_J_12_20_l],
                                            fetch_data[IMM_J_11_h   -1 : IMM_J_11_l   ],
                                            fetch_data[IMM_J_1_11_h -1 : IMM_J_1_11_l ],
                                            1'b0
                                       };
                        

                        r3_valid <= 0;
                        r3_idx   <= 0;

                        rd_valid <= 0;
                        rd_idx   <= fetch_data[IDX_RD_h-1: IDX_RD_l];


                        isJalR         <= 0;
                        isJal          <= 1;
                        jumpExtendMode <= 0;
                        isEq           <= 0;
                        isNEq          <= 0;
                        isLt           <= 0;
                        isGe           <= 0;

                    end

                end else begin
                    isLsUopUse   <= 0;
                    isAluUopUse  <= 0;
                    isJmpUopUse  <= 0;
                    isLdPcUopUse <= 0;

                end

            end else begin
                isLsUopUse   <= 0;
                isAluUopUse  <= 0;
                isJmpUopUse  <= 0;
                isLdPcUopUse <= 0;
            end
        end
    
    end

    //////// control register in case not decoding
    always @(posedge clk) begin

        if (r1_write_en)begin
            r1_valid <= r1_write_valid;
            r1_val   <= r1_write_val;
        end

        if (r2_write_en)begin
            r2_valid <= r2_write_valid;
            r2_val   <= r2_write_val;

        end
    
    end

endmodule