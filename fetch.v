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

    reg[3-1: 0] pipState;
    parameter idleState      = 3'b000;
    parameter waitBefState   = 3'b001;
    parameter sendingState   = 3'b010;
    parameter waitSendState  = 3'b100;

    assign mem_readEn        = nextPipReadyToRcv && sendingState;
    assign mem_read_addr     = reqPc;
    assign curPipReadyToRcv  =  (pipState == waitBefState)             | (curPipReadyToSend & nextPipReadyToRcv);
    assign curPipReadyToSend = ((pipState == sendingState) & readFin)  | (pipState == waitSendState);
    


    always @(posedge clk) begin

        if (sendingState && readFin)begin
            fetch_data <= mem_read_data;
            fetch_cur_pc <= reqPc;
            fetch_nxt_pc <= reqPc + 4;
        end

    end

    /**state**/

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
                if (readFin) begin
                        if (nextPipReadyToRcv) begin
                            if (beforePipReadyToSend) begin
                                pipState <= sendingState; ///// next loop
                            end else begin
                                pipState <= waitBefState;
                            end
                        end else begin
                            pipState <= waitSendState;
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

endmodule