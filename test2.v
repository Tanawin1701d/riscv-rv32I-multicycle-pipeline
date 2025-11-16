module tb;

reg clk;
parameter CLK_PEROID = 10;

wire  opt;
reg   ipt;

md m()

initial begin
    clk = 0;
    forever #(CLK_PEROID/2) clk = ~clk; /// 10 ns period
end

initial begin
        #(CLK_PEROID/2);
    for (cycle = 0; cycle < 100; cycle++)begin
        ipt = 1;
        #CLK_PEROID/2;
        $display("----------------------- end cycle %d -----------------------\n", cycle);


    end

    $finish;




end


endmodule

module md(output reg ns,input wire ps);


always@(ps)begin

ns = ps + 1;

end



endmodule;