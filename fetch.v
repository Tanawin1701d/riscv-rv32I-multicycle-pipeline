`timescale 1ns/1ns

module fetch #(
    parameter XLEN = 32,
    parameter READ_ADDR_SIZE = 32
)(
    input wire[XLEN-1: 0]           mem_read_data,
    input wire                      readFin,
    input wire[READ_ADDR_SIZE-1: 0] reqPc,
    input wire                      beforePipReadyToSend,
    input wire                      nextPipReadyToRcv,
    input wire                      rst,
    input wire                      startSig,
    input wire                      interrupt_start,
    input wire                      clk,
    
    
    output wire                      mem_readEn,
    output wire[READ_ADDR_SIZE-1: 0] mem_read_addr,
    output reg [XLEN          -1: 0] fetch_data,
    output reg [READ_ADDR_SIZE-1: 0] fetch_cur_pc,
    output reg [READ_ADDR_SIZE-1: 0] fetch_nxt_pc,
    output wire                      curPipReadyToRcv,
    output wire                      curPipReadyToSend
    
);

    reg[2-1: 0] pipState;
    parameter idleState      = 2'b00;
    parameter waitBefState   = 2'b01;
    parameter sendingState   = 2'b10;

    assign mem_readEn        = nextPipReadyToRcv && (pipState == sendingState);
    assign mem_read_addr     = reqPc;
    assign curPipReadyToRcv  = (pipState == waitBefState) | (curPipReadyToSend & nextPipReadyToRcv);
    assign curPipReadyToSend = ((pipState == sendingState) & readFin) & (~interrupt_start);
    


    always @(posedge clk) begin

        if ((pipState == sendingState) && readFin)begin
            fetch_data <= mem_read_data;
            fetch_cur_pc <= reqPc;
            fetch_nxt_pc <= reqPc + 4;
        end

    end

    /**state**/

    always @(posedge clk)begin
        
        if (rst)begin
            pipState <= idleState;
        end else if (startSig | interrupt_start) begin // start system
            pipState <= waitBefState;
            if (beforePipReadyToSend)begin
               pipState <= sendingState; 
            end
        end else begin
            if ((pipState == waitBefState) & beforePipReadyToSend) begin
                pipState <= sendingState;
            end else if ((pipState == sendingState) &  nextPipReadyToRcv)begin 
                /// sending but how
                pipState <= beforePipReadyToSend ? sendingState : waitBefState;
            end
        end

    end


endmodule