`timescale 1ns/1ns




module tb;

reg clk;
reg rst;
reg startSig;


parameter CLK_PEROID = 10;
parameter AMT_SIM_CLK = 300;
parameter REG_WIDTH       = 32;
integer cycle = 0;

integer PRINTROW_PERCYCLE = 10;
integer COLWIDTH          = 25;
integer AMT_REG           = 32;
integer AMOUNT_SWAP       = 5000;
integer MEM_BIT_SIZE      = 28;
integer MEM_BIT_SIZE_RD_32= 26;
integer file;
integer programFileIdx;
integer programReadStatus;
integer swapping = 0;

initial begin
    file = $fopen("output/WORKLOADARGS_slot.txt", "w");
    if (file == 0) begin
        $display("error: could not open file for writing.");
        $finish;
    end
end


integer fillMemIdx = 0;
//////////////// read data from program 
initial begin

    // for (fillMemIdx = 0; fillMemIdx < (2**MEM_BIT_SIZE_RD_32); fillMemIdx = fillMemIdx + 1) begin
    //     core_dut.storageMgmtBlock.mem[fillMemIdx] = 0;
    // end

    for (fillMemIdx = 0; fillMemIdx < 512; fillMemIdx = fillMemIdx + 1) begin
        core_dut.storageMgmtBlock.mem[fillMemIdx] = 0;
    end

    programFileIdx = $fopen("program/WORKLOADARGS/asm.out", "rb");
    programReadStatus = $fread(core_dut.storageMgmtBlock.mem, programFileIdx);
    if (programReadStatus == 0) begin
        $display("error: could not read programfile");
        $finish;
    end
    for (swapping = 0; swapping < AMOUNT_SWAP; swapping = swapping + 1) begin
        core_dut.storageMgmtBlock.mem[swapping] = {
            core_dut.storageMgmtBlock.mem[swapping][  8-1 :  0],
            core_dut.storageMgmtBlock.mem[swapping][ 16-1 :  8],
            core_dut.storageMgmtBlock.mem[swapping][ 24-1 : 16],
            core_dut.storageMgmtBlock.mem[swapping][ 32-1 : 24]
        };
    end

end


//////////////// clear register
integer regIdx = 0;
initial begin
    for (regIdx = 0; regIdx < AMT_REG; regIdx++)begin
        core_dut.regFile[regIdx] = 0;
    end
end

/////////////// test register





core core_dut (
    .clk(clk),
    .rst(rst),
    .startSig(startSig)
);


initial begin
    clk = 0;
    forever #(CLK_PEROID/2) clk = ~clk; /// 10 ns period
end


initial begin
    rst      = 1;
    startSig = 0;
    #CLK_PEROID;
    rst      = 0;
    startSig = 1;
    #CLK_PEROID;
    rst      = 0;
    startSig = 0;
end



initial begin
        #(CLK_PEROID/2);
    for (cycle = 0; cycle < AMT_SIM_CLK; cycle++)begin
        
        //fetchWriter;
        //decodeWriter;
        //execWriter;
        //writeBackWriter;
        //writeReg;
        $fwrite(file, "----------------------- end cycle %d -----------------------\n", cycle);
        //$display("----------------------- end cycle %d -----------------------\n", cycle);
        #CLK_PEROID;

    end
    checkReg;
    $fclose(file);
    $fclose(programFileIdx);
    $finish;




end


task fetchWriter;

    begin

        if (core_dut.fetchBlock.pipState == core_dut.fetchBlock.idleState)begin
            $fwrite(file, "fetch    : IDLE\n");
        end else if (core_dut.fetchBlock.pipState == core_dut.fetchBlock.waitBefState)begin
            $fwrite(file, "fetch    : WAIT_RECV\n");
        end else if (core_dut.fetchBlock.pipState == core_dut.fetchBlock.sendingState) begin
            if (core_dut.fetchBlock.readFin) begin
                $fwrite(file, "fetch    : GOT data (addr) 0x%h (data) 0x%h (pc) 0x%h\n", core_dut.fetchBlock.mem_read_addr, 
                                                                         core_dut.fetchBlock.mem_read_data, core_dut.fetchBlock.fetch_cur_pc);
            end else begin
                $fwrite(file, "fetch    : REQUESTING addr 0x%h \n", core_dut.fetchBlock.mem_read_addr);
            end
        end else if (core_dut.fetchBlock.pipState == core_dut.fetchBlock.waitSendState) begin
            $fwrite(file, "fetch    : WAIT_SEND\n");
        end else begin
            $fwrite(file, "fetch    : error\n");
        end

    end
endtask


task decodeWriter;

    begin


        if (core_dut.decoderBlock.pipState == core_dut.decoderBlock.idleState)begin
            $fwrite(file, "decode   : IDLE\n");
        end else if (core_dut.decoderBlock.pipState == core_dut.decoderBlock.waitBefState)begin
            $fwrite(file, "decode   : WAIT_RECV\n");
        end else if (core_dut.decoderBlock.pipState == core_dut.decoderBlock.sendingState) begin
            if (core_dut.decoderBlock.nextPipReadyToRcv) begin

                if          (core_dut.decoderBlock.op == 7'b00_000_11)begin
                    $fwrite(file, "decode   : LOAD\n");
                end else if (core_dut.decoderBlock.op == 7'b00_011_11) begin
                    $fwrite(file, "decode   : MISC_MEM should not be here\n");
                end else if (core_dut.decoderBlock.op == 7'b00_100_11) begin
                    $fwrite(file, "decode   : OP-IMM\n");
                end else if (core_dut.decoderBlock.op == 7'b00_101_11) begin
                    $fwrite(file, "decode   : AUIPC\n");
                end else if (core_dut.decoderBlock.op == 7'b01_000_11) begin
                    $fwrite(file, "decode   : STORE\n");
                end else if (core_dut.decoderBlock.op == 7'b01_100_11) begin
                    $fwrite(file, "decode   : OP\n");
                end else if (core_dut.decoderBlock.op == 7'b01_101_11) begin
                    $fwrite(file, "decode   : LUI\n");
                end else if (core_dut.decoderBlock.op == 7'b11_000_11) begin
                    $fwrite(file, "decode   : BRANCH\n");
                end else if (core_dut.decoderBlock.op == 7'b11_001_11) begin
                    $fwrite(file, "decode   : JALR\n");
                end else if (core_dut.decoderBlock.op == 7'b11_011_11) begin
                    $fwrite(file, "decode   : JAL\n");
                end else if (core_dut.decoderBlock.op == 7'b11_100_11) begin
                    $fwrite(file, "decode   : SYSTEM should not be here\n");
                end else begin
                    $fwrite(file, "decode   : ERROR op\n");
                end

            end else begin
                $fwrite(file, "decode   : wait EXECUTING BLOCKED \n");
            end
        end else if (core_dut.decoderBlock.pipState == core_dut.decoderBlock.waitSendState) begin
            $fwrite(file, "decode   : WAIT_SEND\n");
        end else begin
            $fwrite(file, "decode   : error\n");
        end

    end
endtask

task execWriter;

    begin

        if (core_dut.execBlock.pipState == core_dut.execBlock.idleState)begin
            $fwrite(file, "exec     : IDLE\n");
        end else if (core_dut.execBlock.pipState == core_dut.execBlock.waitBefState)begin
            $fwrite(file, "exec     : WAIT_RECV\n");
        end else if (core_dut.execBlock.pipState == core_dut.execBlock.regAccess) begin
            $fwrite(file, "exec     : reg access  regFIlePort2 readVal %d  valid %d\n", core_dut.execBlock.regFile2_readData, core_dut.execBlock.r2_valid);
        end else if (core_dut.execBlock.pipState == core_dut.execBlock.simpleExec) begin
            
                if (core_dut.execBlock.isAluUopUse) begin
                    
                    if (core_dut.execBlock.isAdd)               begin    $fwrite(file, "exec     : Add"              ); end
                    if (core_dut.execBlock.isSub)               begin    $fwrite(file, "exec     : Sub"              ); end
                    if (core_dut.execBlock.isXor)               begin    $fwrite(file, "exec     : Xor"              ); end
                    if (core_dut.execBlock.isOr)                begin    $fwrite(file, "exec     : Or "              ); end
                    if (core_dut.execBlock.isAnd)               begin    $fwrite(file, "exec     : And"              ); end
                    if (core_dut.execBlock.isCmpLessThanSign)   begin    $fwrite(file, "exec     : CmpLessThanSign"  ); end
                    if (core_dut.execBlock.isCmpLessThanUSign)  begin    $fwrite(file, "exec     : CmpLessThanUSign" ); end
                    if (core_dut.execBlock.isShiftLeftLogical)  begin    $fwrite(file, "exec     : ShiftLeftLogical" ); end
                    if (core_dut.execBlock.isShiftRightLogical) begin    $fwrite(file, "exec     : ShiftRightLogical"); end
                    if (core_dut.execBlock.isShiftRightArith)   begin    $fwrite(file, "exec     : ShiftRightArith"  ); end


                end else if (core_dut.execBlock.isJmpUopUse) begin

                    if      (core_dut.execBlock.isJalR)         begin    $fwrite(file, "exec     : JalR"             ); end
                    if      (core_dut.execBlock.isJal)          begin    $fwrite(file, "exec     : Jal"              ); end
                    if      (core_dut.execBlock.isEq)           begin    $fwrite(file, "exec     : Eq "              ); end
                    if      (core_dut.execBlock.isNEq)          begin    $fwrite(file, "exec     : NEq"              ); end
                    if      (core_dut.execBlock.isLt)           begin    $fwrite(file, "exec     : Lt"               ); end
                    if      (core_dut.execBlock.isGe)           begin    $fwrite(file, "exec     : Ge"               ); end
                    
                end else if (core_dut.execBlock.isLdPcUopUse) begin

                    if      (core_dut.execBlock.isLdPcUopUse & ~core_dut.execBlock.isNeedPc)   
                                                                begin $fwrite(file, "exec     : AUI"             ); end
                    if      (core_dut.execBlock.isLdPcUopUse &  core_dut.execBlock.isNeedPc)   
                                                                begin $fwrite(file, "exec     : AUIPC"           ); end

                end else if (core_dut.execBlock.isLsUopUse) begin
                    
                    if      (core_dut.execBlock.isMemLoad) begin
                            $fwrite(file, "exec     : LOAD"           );
                    end else begin
                            $fwrite(file, "exec     : STORE"           );
                    end
                    ///$fwrite(file, "(%d)", core_dut.execBlock.ldsize);
                    if (core_dut.execBlock.ldsize == 2'b00)begin  $fwrite(file, "8"); end else 
                    if (core_dut.execBlock.ldsize == 2'b01) begin $fwrite(file, "16");end else 
                    if (core_dut.execBlock.ldsize == 2'b10) begin $fwrite(file, "32");end else 
                    begin $fwrite(file, "ERROR"); end
                    

                end else begin
                    $fwrite(file, "exec     : unknown type");
                end

                $fwrite(file,"\n");

                $fwrite(file, "exec(dt) : |r1 v%d idx%d val%d|r2 v%d idx%d val%d\n",
                    core_dut.execBlock.r1_valid, core_dut.execBlock.r1_idx, core_dut.execBlock.r1_val,
                    core_dut.execBlock.r2_valid, core_dut.execBlock.r2_idx, core_dut.execBlock.r2_val
                );
                $fwrite(file, "exec(dt) : |r3 v%d idx%d val%d|rd v%d idx%d val%d|pc 0x%h|mispredict %d\n",
                    core_dut.execBlock.r3_valid, core_dut.execBlock.r3_idx, core_dut.execBlock.r3_val,
                    core_dut.execBlock.rd_valid, core_dut.execBlock.rd_idx, core_dut.execBlock.rd_val,
                    core_dut.execBlock.pc      , core_dut.execBlock.misPredict
                );
        end else if (core_dut.execBlock.pipState == core_dut.execBlock.shiftLeftReg |
                     core_dut.execBlock.pipState == core_dut.execBlock.shiftRightReg |
                     core_dut.execBlock.pipState == core_dut.execBlock.shiftRightArReg) begin
            $fwrite(file, "exec     : reg shifting\n");
        end else if (core_dut.execBlock.pipState == core_dut.execBlock.ldstReg) begin
            $fwrite(file, "exec     : loading storing read data (%d) (pool %d) (addr %d) (en %d) (readmaster %d) (readmem data %d)\n", core_dut.execBlock.mem_radData, 
                                                core_dut.mem_readPool, 
                                                core_dut.mem_readAddr2, 
                                                core_dut.mem_readEn2, 
                                                core_dut.storageMgmtBlock.readIdxMaster,
                                                core_dut.storageMgmtBlock.poolReadData
                                                );
        end else if (core_dut.execBlock.pipState == core_dut.execBlock.waitSendState) begin
            $fwrite(file, "exec     : WAIT_SEND\n");
        end else begin
            $fwrite(file, "exec     : error\n");
        end

    end
endtask

task writeBackWriter;

    begin

        if (core_dut.writeBackBlock.pipState == core_dut.writeBackBlock.idleState)begin
            $fwrite(file, "wb      : IDLE\n");
        end else if (core_dut.writeBackBlock.pipState == core_dut.writeBackBlock.waitBefState)begin
            $fwrite(file, "wb       : WAIT_RECV\n");
        end else if (core_dut.writeBackBlock.pipState == core_dut.writeBackBlock.sendingState) begin
            
            if (core_dut.writeBackBlock.regFileWriteEn) begin
                $fwrite(file, "wb       : write idx:%d val:%d\n", 
                        core_dut.writeBackBlock.regFileWriteIdx,
                        core_dut.writeBackBlock.regFileWriteVal
                );
            end else begin
                $fwrite(file, "wb       : write not write \n");
            end
            

        end else if (core_dut.writeBackBlock.pipState == core_dut.writeBackBlock.waitSendState) begin
            $fwrite(file, "wb       : WAIT_SEND\n");
        end else begin
            $fwrite(file, "wb       : error\n");
        end

    end
endtask


integer regIter = 0;
task writeReg;

    begin
    
        // $fwrite(file, "reg      :");
        // for (regIter = 0; regIter < 32; regIter = regIter + 1)begin
        //     $fwrite(file, " r%d = %d |", regIter, core_dut.regFile[regIter]);
        // end
        // $fwrite(file, "\n");

        $fwrite(file, "mem      : 257 = %d", core_dut.storageMgmtBlock.mem[257]);

    end

endtask





reg[1023       : 0] lineRead;
reg[REG_WIDTH-1: 0] readRegAssert;
reg                 assertResult = 1;
integer AssertFileIdx;
integer readResult;
integer testIdx = 0;

task checkReg;

    begin

        AssertFileIdx = $fopen("program/WORKLOADARGS/ast.out", "r");

        if (AssertFileIdx == 0) begin
            $display("failed to open read file.");
            $finish;
        end

        while (!$feof(AssertFileIdx)) begin
            readResult = $fgets(lineRead, AssertFileIdx);
            readResult = $sscanf(lineRead, "%d", readRegAssert);

            if (readRegAssert != core_dut.regFile[testIdx]) begin
                $display("regIdx %d expect %d got %d", testIdx, readRegAssert, core_dut.regFile[testIdx]);
                assertResult = 0;

            end

            testIdx = testIdx + 1;

        end

        if (assertResult == 0) begin
            $display("cpu error");
        end else begin
            $display("test pass");
        end

        $fclose(AssertFileIdx);

    end


endtask


endmodule


// module core(
//     input wire clk,
//     input wire rst,
//     input wire startSig
// );
// endmodule