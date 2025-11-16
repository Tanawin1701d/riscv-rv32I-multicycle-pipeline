`timescale 1ns/1ns

module core(
    input wire clk,
    input wire rst,
    input wire startSig
);


parameter XLEN              = 32;
parameter MEM_ADDR_SIZE     = 32;
parameter REG_IDX           = 5;
parameter UOP_WIDTH         = 7;
parameter AMT_REG           = 32;
parameter READ_ADDR_SIZE    = 32;
parameter AMT_READER        = 2;
parameter AMT_ROW           = 4096; 
parameter ROW_WIDTH         = 32;
parameter MEM_BIT_SIZE      = 28 -2; //// for 256 megabyte align to 32 bit width
parameter MEM_START_BIT     = 2;



reg[MEM_ADDR_SIZE-1: 0]  pc;
wire                     misPredict;
wire[MEM_ADDR_SIZE-1: 0] restartPc;

/** register file block*/
reg [XLEN-1: 0] regFile [AMT_REG-1: 0];


/** pipeline wire*/
wire jumpStartPip = 1;
wire pip_fetch_ready_to_rcv;
wire pip_fetch_ready_to_send;
wire pip_decoder_ready_to_rcv;
wire pip_decoder_ready_to_send;
wire pip_execute_ready_to_rcv;
wire pip_execute_ready_to_send;
wire pip_writeBack_ready_to_rcv;
wire pip_writeBack_ready_to_send;
wire dummyStopPip = 1;


/** memory read wire*/
wire[XLEN-1:          0] mem_readData1;
wire[MEM_ADDR_SIZE-1: 0] mem_readAddr1;
wire                     mem_readEn1;
wire                     mem_readFin1;

wire[XLEN-1:          0] mem_readData2;
wire[MEM_ADDR_SIZE-1: 0] mem_readAddr2;
wire                     mem_readEn2;
wire                     mem_readFin2;

wire[XLEN-1:          0] mem_writeData1;
wire[MEM_ADDR_SIZE-1: 0] mem_writeAddr1;
wire                     mem_writeEn1;

wire[XLEN-1:          0] mem_readPool;
assign mem_readData2 = mem_readPool;
assign mem_readData1 = mem_readPool;

/** fetch to decode wire*/

wire[XLEN-1:          0] fetch_data;
wire[XLEN-1:          0] fetch_cur_pc;
wire[XLEN-1:          0] fetch_nxt_pc;

/** decode to execute wire*/

wire                r1_valid;
wire[REG_IDX-1 : 0] r1_idx;
wire[XLEN-1 : 0]    r1_val;

wire                r2_valid;
wire[REG_IDX-1 : 0] r2_idx;
wire[XLEN-1 : 0]    r2_val;

wire                r3_valid;
wire[REG_IDX-1 : 0] r3_idx;
wire[XLEN-1 : 0]    r3_val;

wire                rd_valid;
wire[REG_IDX-1 : 0] rd_idx;
wire[XLEN-1 : 0]    rd_val;

wire                isLsUopUse;
wire                isMemLoad;
wire[1:0]           ldsize;
wire                ldextendMode;


wire                isAluUopUse;
wire                isAdd;
wire                isSub;
wire                isXor;
wire                isOr;
wire                isAnd;
wire                isCmpLessThanSign;
wire                isCmpLessThanUSign;
wire                isShiftLeftLogical;
wire                isShiftRightLogical;
wire                isShiftRightArith;


wire                isJmpUopUse;
wire                isJalR;
wire                isJal;
wire                jumpExtendMode;
wire                isEq;
wire                isNEq;
wire                isLt;
wire                isGe;

wire                isLdPcUopUse;
wire                isNeedPc;

wire[READ_ADDR_SIZE-1: 0] pcFromDec;
wire[READ_ADDR_SIZE-1: 0] nextPcFromDec;

/** execute back to decode */
wire                r1_write_valid;
wire[XLEN-1:0]      r1_write_val;
wire                r1_write_en;

wire                r2_write_valid;
wire[XLEN-1:0]      r2_write_val;
wire                r2_write_en;

/**execute regfile reader*/
wire[XLEN-1   : 0]  regFileReadData1;
wire[REG_IDX-1: 0]  regFileReadIdx1;

wire[XLEN-1   : 0]  regFileReadData2;
wire[REG_IDX-1: 0]  regFileReadIdx2;


assign regFileReadData1 = regFile[regFileReadIdx1];
assign regFileReadData2 = regFile[regFileReadIdx2];

/**execute to write back*/
wire                wb_valid;   ///// act as wire
wire[REG_IDX-1 : 0] wb_idx;     ///// act as wire
wire[XLEN-1 : 0]    wb_val;     ///// act as wire 
wire                wb_en_valid;      ///// act as wire valid to valid and idx
wire                wb_en_idx;
wire                wb_en_data;      ///// act as wire valid to valid and idx

/** write back back to execute */
wire[REG_IDX-1: 0]  bp_idx;
wire[XLEN-1   : 0]  bp_val;

/** write back to regfile*/
wire[REG_IDX-1: 0] regFilelWriteIdx;
wire[XLEN-1   : 0] regFileWriteVal;
wire               regFileWriteEn;


always@(posedge clk)begin

        if ( (!rst) && regFileWriteEn) begin
            regFile[regFilelWriteIdx] <= regFileWriteVal;
        end

end


always@(posedge clk)begin

    if (rst | startSig)begin
        pc <= 0;
    end else if (misPredict)begin
        pc <= restartPc;
    end else if (mem_readFin1)begin
        pc <= pc +4;
    end

end



/*** fetch block */

fetch #(.XLEN(XLEN), .READ_ADDR_SIZE(READ_ADDR_SIZE)) fetchBlock(
.mem_read_data       (mem_readData1), 
.readFin             (mem_readFin1), 
.reqPc               (pc),
.beforePipReadyToSend(jumpStartPip), 
.nextPipReadyToRcv   (pip_decoder_ready_to_rcv),
.rst                 (rst), 
.startSig            (startSig),
.interrupt_start     (misPredict),
.clk                 (clk),

.mem_readEn       (mem_readEn1),
.mem_read_addr    (mem_readAddr1),
.fetch_data       (fetch_data),
.fetch_cur_pc     (fetch_cur_pc),
.fetch_nxt_pc     (fetch_nxt_pc),
.curPipReadyToRcv (pip_fetch_ready_to_rcv),
.curPipReadyToSend(pip_fetch_ready_to_send)
);


decoder #(

    .XLEN(XLEN), .REG_IDX(REG_IDX),
    .UOP_WIDTH(UOP_WIDTH) , .AMT_REG(AMT_REG),
    .READ_ADDR_SIZE(READ_ADDR_SIZE))  decoderBlock(
        
        .fetch_data          (fetch_data),
        .fetch_cur_pc        (fetch_cur_pc),
        .fetch_nxt_pc        (fetch_nxt_pc),
        .beforePipReadyToSend(pip_fetch_ready_to_send),
        .nextPipReadyToRcv   (pip_execute_ready_to_rcv),
        .rst                 (rst),
        .startSig            (startSig),
        .interrupt_start     (misPredict),
        .clk                 (clk),

        .r1_write_valid      (r1_write_valid),
        .r1_write_val        (r1_write_val),
        .r1_write_en         (r1_write_en),

        .r2_write_valid      (r2_write_valid),
        .r2_write_val        (r2_write_val),
        .r2_write_en         (r2_write_en),

        .curPipReadyToRcv    (pip_decoder_ready_to_rcv),
        .curPipReadyToSend   (pip_decoder_ready_to_send),
        .r1_valid            (r1_valid),
        .r1_idx              (r1_idx),
        .r1_val              (r1_val),

        .r2_valid            (r2_valid),
        .r2_idx              (r2_idx),
        .r2_val              (r2_val),

        .r3_valid            (r3_valid),
        .r3_idx              (r3_idx),
        .r3_val              (r3_val),

        .rd_valid            (rd_valid),
        .rd_idx              (rd_idx),
        .rd_val              (rd_val),

        .isLsUopUse          (isLsUopUse),
        .isMemLoad           (isMemLoad),
        .ldsize              (ldsize),
        .ldextendMode        (ldextendMode),

        .isAluUopUse         (isAluUopUse),
        .isAdd               (isAdd),
        .isSub               (isSub),
        .isXor               (isXor),
        .isOr                (isOr),
        .isAnd               (isAnd),
        .isCmpLessThanSign   (isCmpLessThanSign),
        .isCmpLessThanUSign  (isCmpLessThanUSign),
        .isShiftLeftLogical  (isShiftLeftLogical),
        .isShiftRightLogical (isShiftRightLogical),
        .isShiftRightArith   (isShiftRightArith),



        .isJmpUopUse   (isJmpUopUse),
        .isJalR        (isJalR),
        .isJal         (isJal),
        .jumpExtendMode(jumpExtendMode),
        .isEq          (isEq),
        .isNEq         (isNEq),
        .isLt          (isLt),
        .isGe          (isGe),

        .isLdPcUopUse(isLdPcUopUse),
        .isNeedPc    (isNeedPc),

        .pc     (pcFromDec),
        .nextPc(nextPcFromDec)

    );


execute #(.XLEN(XLEN), .REG_IDX(REG_IDX),
    .UOP_WIDTH(UOP_WIDTH) , .AMT_REG(AMT_REG),
    .READ_ADDR_SIZE(READ_ADDR_SIZE)) execBlock (

        .beforePipReadyToSend(pip_decoder_ready_to_send),
        .nextPipReadyToRcv   (pip_writeBack_ready_to_rcv),
        .startSig            (startSig),
        .rst                 (rst),
        .clk                 (clk),
    
        .r1_valid(r1_valid),
        .r1_idx  (r1_idx),
        .r1_val  (r1_val),

        .r2_valid(r2_valid),
        .r2_idx  (r2_idx),
        .r2_val  (r2_val),

        .r3_valid(r3_valid),
        .r3_idx  (r3_idx),
        .r3_val  (r3_val),

        .rd_valid(rd_valid),
        .rd_idx  (rd_idx),
        .rd_val  (rd_val),

        .isLsUopUse(isLsUopUse),
        .isMemLoad(isMemLoad),
        .ldsize(ldsize),
        .ldextendMode(ldextendMode),


        .isAluUopUse(isAluUopUse),
        .isAdd(isAdd),
        .isSub(isSub),
        .isXor(isXor),
        .isOr(isOr),
        .isAnd(isAnd),
        .isCmpLessThanSign(isCmpLessThanSign),
        .isCmpLessThanUSign(isCmpLessThanUSign),
        .isShiftLeftLogical(isShiftLeftLogical),
        .isShiftRightLogical(isShiftRightLogical),
        .isShiftRightArith(isShiftRightArith),


        .isJmpUopUse   (isJmpUopUse),
        .isJalR        (isJalR),
        .isJal         (isJal),
        .jumpExtendMode(jumpExtendMode),
        .isEq          (isEq),
        .isNEq         (isNEq),
        .isLt          (isLt),
        .isGe          (isGe),

        .isLdPcUopUse(isLdPcUopUse),
        .isNeedPc(isNeedPc),

        .pc(pcFromDec),
        .nextPc(nextPcFromDec),

        .mem_readFin(mem_readFin2),
        .mem_radData(mem_readData2),

        .bp_idx(bp_idx),
        .bp_val(bp_val),

        .regFile1_readData(regFileReadData1),
        .regFile2_readData(regFileReadData2),

        .wb_cur_val(regFileWriteVal),
        
        .wb_valid   (wb_valid  ), 
        .wb_idx     (wb_idx    ),   
        .wb_val     (wb_val    ),     
        .wb_en_valid(wb_en_valid),      ///// act as wire valid to valid and idx
        .wb_en_idx  (wb_en_idx),
        .wb_en_data (wb_en_data),      ///// act as wire valid to valid and idx


        .misPredict(misPredict),
        .reqPc     (restartPc ),

        .mem_readEn   (mem_readEn2   ),
        .mem_readAddr (mem_readAddr2 ),
        .mem_writeEn  (mem_writeEn1  ),
        .mem_writeAddr(mem_writeAddr1),
        .mem_writeData(mem_writeData1),

        .regFile1_readIdx(regFileReadIdx1),
        .regFile2_readIdx(regFileReadIdx2),


        .r1_write_valid(r1_write_valid), //// act as wire
        .r1_write_val  (r1_write_val  ),   ///// act as wire 
        .r1_write_en   (r1_write_en   ),    ///// act as wire

        .r2_write_valid(r2_write_valid) ,
        .r2_write_val  (r2_write_val  ) ,
        .r2_write_en   (r2_write_en   ) ,

        .curPipReadyToRcv (pip_execute_ready_to_rcv),
        .curPipReadyToSend(pip_execute_ready_to_send)
    );


    writeBack #(
        .XLEN(XLEN), .REG_IDX(REG_IDX),
        .AMT_REG(AMT_REG)) writeBackBlock (
            .beforePipReadyToSend(pip_execute_ready_to_send),
            .nextPipReadyToRcv   (dummyStopPip),
            .rst                 (rst),
            .startSig            (startSig),
            .clk                 (clk),


            .wb_valid  (wb_valid),
            .wb_idx    (wb_idx),
            .wb_val    (wb_val),
            .wb_en_valid(wb_en_valid),
            .wb_en_idx (wb_en_idx),
            .wb_en_data(wb_en_data),


            .curPipReadyToRcv (pip_writeBack_ready_to_rcv),
            .curPipReadyToSend(pip_writeBack_ready_to_send),

            .bp_idx(bp_idx),
            .bp_val(bp_val),

            .regFileWriteIdx(regFilelWriteIdx),
            .regFileWriteVal(regFileWriteVal),
            .regFileWriteEn (regFileWriteEn)

        );

    storageMgmt #(
        .READ_ADDR_SIZE(MEM_BIT_SIZE), .ROW_WIDTH(ROW_WIDTH),
        .AMT_READER(AMT_READER)
    ) storageMgmtBlock (
        .readAddrs({mem_readAddr2[MEM_START_BIT + MEM_BIT_SIZE -1:MEM_START_BIT], 
                    mem_readAddr1[MEM_START_BIT + MEM_BIT_SIZE -1:MEM_START_BIT]}),
        .readEns0(mem_readEn1),
        .readEns1(mem_readEn2),
        
        .writeAddr(mem_writeAddr1[MEM_START_BIT + MEM_BIT_SIZE -1:MEM_START_BIT]),
        .writeData(mem_writeData1),
        .writeEn(mem_writeEn1),
        .rst(rst),
        .startSig(startSig),
        .clk(clk),

        .readfin0(mem_readFin1),
        .readfin1(mem_readFin2),

        .poolReadData(mem_readPool)
    );

endmodule






// module fetch #(
//     parameter XLEN = 32,
//     parameter READ_ADDR_SIZE = 32
// )(
//     input wire[XLEN-1: 0]           mem_read_data,
//     input wire                      readFin,
//     input wire[READ_ADDR_SIZE-1: 0] reqPc,
//     input wire                      beforePipReadyToSend,
//     input wire                      nextPipReadyToRcv,
//     input wire                      rst,
//     input wire                      startSig,
//     input wire                      interrupt_start,
//     input wire                      clk,
    
    
//     output wire                      mem_readEn,
//     output wire[READ_ADDR_SIZE-1: 0] mem_read_addr,
//     output reg [XLEN          -1: 0] fetch_data,
//     output reg [READ_ADDR_SIZE-1: 0] fetch_cur_pc,
//     output reg [READ_ADDR_SIZE-1: 0] fetch_nxt_pc,
//     output wire                      curPipReadyToRcv,
//     output wire                      curPipReadyToSend
    
// );
// endmodule

// module decoder #(
//     parameter XLEN      = 32, parameter REG_IDX = 5,
//     parameter UOP_WIDTH = 7 , parameter AMT_REG = 32,
//     parameter READ_ADDR_SIZE = 32
// )(

// input wire [XLEN          -1: 0] fetch_data,
// input wire [READ_ADDR_SIZE-1: 0] fetch_cur_pc,
// input wire [READ_ADDR_SIZE-1: 0] fetch_nxt_pc,
// input wire                       beforePipReadyToSend,
// input wire                       nextPipReadyToRcv,
// input wire                       rst,
// input wire                       startSig,
// input wire                       interrupt_start,
// input wire                       clk,

// input wire                       r1_write_valid,
// input wire [XLEN          -1: 0] r1_write_val,
// input wire                       r1_write_en,

// input wire                       r2_write_valid,
// input wire [XLEN          -1: 0] r2_write_val,
// input wire                       r2_write_en,



// output wire               curPipReadyToRcv,
// output wire               curPipReadyToSend,

// output reg                r1_valid,
// output reg[REG_IDX-1 : 0] r1_idx,
// output reg[XLEN-1 : 0]    r1_val,

// output reg                r2_valid,
// output reg[REG_IDX-1 : 0] r2_idx,
// output reg[XLEN-1 : 0]    r2_val,

// output reg                r3_valid,
// output reg[REG_IDX-1 : 0] r3_idx,
// output reg[XLEN-1 : 0]    r3_val,

// output reg                rd_valid,
// output reg[REG_IDX-1 : 0] rd_idx,
// output reg[XLEN-1 : 0]    rd_val,

// output reg                isLsUopUse,
// output reg                isMemLoad,
// output reg[1:0]           ldsize,
// output reg                ldextendMode,


// output reg                isAluUopUse,
// output reg                isAdd,
// output reg                isSub,
// output reg                isXor,
// output reg                isOr,
// output reg                isAnd,
// output reg                isCmpLessThanSign,
// output reg                isCmpLessThanUSign,
// output reg                isShiftLeftLogical,
// output reg                isShiftRightLogical,
// output reg                isShiftRightArith,


// output reg                isJmpUopUse,
// output reg                isJalR,
// output reg                isJal,
// output reg                jumpExtendMode,
// output reg                isEq,
// output reg                isNEq,
// output reg                isLt,
// output reg                isGe,

// output reg                isLdPcUopUse,
// output reg                isNeedPc,

// output reg                pc,
// output reg                nextPc

// );
// endmodule

// module execute #(
//     parameter XLEN      = 32, parameter REG_IDX = 5,
//     parameter UOP_WIDTH = 7 , parameter AMT_REG = 32,
//     parameter READ_ADDR_SIZE = 32
// ) (

// input wire                 beforePipReadyToSend,
// input wire                 nextPipReadyToRcv,
// input wire                 startSig,
// input wire                 rst,
// input wire                 clk,
    
// input wire                 r1_valid,
// input wire[REG_IDX-1 : 0]  r1_idx,
// input wire[XLEN-1 : 0]     r1_val,

// input wire                 r2_valid,
// input wire[REG_IDX-1 : 0]  r2_idx,
// input wire[XLEN-1 : 0]     r2_val,

// input wire                 r3_valid,
// input wire[REG_IDX-1 : 0]  r3_idx,
// input wire[XLEN-1 : 0]     r3_val,

// input wire                 rd_valid,
// input wire[REG_IDX-1 : 0]  rd_idx,
// input wire[XLEN-1 : 0]     rd_val,

// input wire                 isLsUopUse,
// input wire                 isMemLoad,
// input wire[1:0]            ldsize,
// input wire                 ldextendMode,


// input wire                 isAluUopUse,
// input wire                 isAdd,
// input wire                 isSub,
// input wire                 isXor,
// input wire                 isOr,
// input wire                 isAnd,
// input wire                 isCmpLessThanSign,
// input wire                 isCmpLessThanUSign,
// input wire                 isShiftLeftLogical,
// input wire                 isShiftRightLogical,
// input wire                 isShiftRightArith,


// input wire                 isJmpUopUse,
// input wire                 isJalR,
// input wire                 isJal,
// input wire                 jumpExtendMode,
// input wire                 isEq,
// input wire                 isNEq,
// input wire                 isLt,
// input wire                 isGe,

// input wire                 isLdPcUopUse,
// input wire                 isNeedPc,

// input wire                 pc,
// input wire                 nextPc,

// input wire                 mem_readFin,
// input wire[XLEN-1: 0]      mem_radData,

// input wire[REG_IDX-1 : 0] bp_idx,
// input wire[XLEN-1 : 0]    bp_val,

// input  wire[XLEN-1 : 0]    regFile1_readData,
// input  wire[XLEN-1 : 0]    regFile2_readData,

// input  wire[XLEN-1 : 0]    wb_cur_val,



// output reg                wb_valid,   ///// act as wire
// output reg[REG_IDX-1 : 0] wb_idx,     ///// act as wire
// output reg[XLEN-1 : 0]    wb_val,     ///// act as wire 
// output reg                wb_en_valid,      ///// act as wire valid to valid and idx
// output reg                wb_en_idx,
// output reg                wb_en_data,      ///// act as wire valid to valid and idx


// output wire                      misPredict,
// output wire[READ_ADDR_SIZE-1: 0] reqPc,

// output reg                      mem_readEn,
// output reg[READ_ADDR_SIZE-1: 0] mem_readAddr,
// output reg                      mem_writeEn,
// output reg[READ_ADDR_SIZE-1: 0] mem_writeAddr,
// output reg[XLEN          -1: 0] mem_writeData,

// output reg[REG_IDX-1: 0]    regFile1_readIdx,
// output reg[REG_IDX-1: 0]    regFile2_readIdx,


// output reg                 r1_write_valid, //// act as wire
// output reg[XLEN-1 : 0]     r1_write_val,   ///// act as wire 
// output reg                 r1_write_en,    ///// act as wire

// output reg                 r2_write_valid,
// output reg[XLEN-1 : 0]     r2_write_val,
// output reg                 r2_write_en,

// output wire                curPipReadyToRcv,
// output wire                curPipReadyToSend

// );
// endmodule

// module writeBack #(
//     parameter XLEN = 32, parameter REG_IDX = 5,
//     parameter AMT_REG = 32
// )(
// input wire beforePipReadyToSend,
// input wire nextPipReadyToRcv,
// input wire rst,
// input wire startSig,
// input wire clk,

// input wire                wb_valid,
// input wire[REG_IDX-1: 0]  wb_idx,
// input wire[XLEN-1   : 0]  wb_val,
// input wire                wb_en_valid,
// input wire                wb_en_idx,
// input wire                wb_en_data,

// output wire curPipReadyToRcv,
// output wire curPipReadyToSend,

// output wire[REG_IDX-1: 0] bp_idx,
// output wire[XLEN-1:    0] bp_val,

// output wire[REG_IDX-1: 0] regFileWriteIdx,
// output wire[XLEN-1   : 0] regFileWriteVal,
// output wire               regFileWriteEn
// );
// endmodule

// module storageMgmt #( ////////////// multiread single write
//     parameter READ_ADDR_SIZE = 28, parameter ROW_WIDTH = 32,
//     parameter AMT_READER = 2 //// writer fix to one 
// ) (
// input wire[READ_ADDR_SIZE*AMT_READER-1: 0] readAddrs,
// input wire[AMT_READER-1:                0] readEns,

// input wire[READ_ADDR_SIZE-1:            0] writeAddr,
// input wire[ROW_WIDTH-1:                 0] writeData,
// input wire                                 writeEn,
// input wire                                 rst,
// input wire                                 startSig,
// input wire                                 clk,


// output reg[AMT_READER-1:                0] readfin,
// output reg[ROW_WIDTH-1 :0]                poolReadData

// );

// endmodule