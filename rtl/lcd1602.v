module lcd1602(
    input wire clk,
    input wire rst_n,

    //显存
    input wire we,
    input wire [4:0] addr,
    input wire [7:0] din,
    output wire [7:0] dout,
    
    //lcd1602控制
    inout wire [7:0] DB,
    output reg RS,
    output reg RW,
    output reg EN
);

reg [7:0] dram [31:0];//显存

//显存读写
reg [4:0] addr_r;
always @ (posedge clk) begin
    if (we) begin
        dram[addr] <= din;
    end
end
always @ (posedge clk) begin
    if (~we) begin
        addr_r <= addr;
    end
end
assign dout = dram[addr_r];

//写入状态机控制
reg wr_en;//写入使能，高电平有效
reg wr_rs;//命令/cmd数据选择，高电平数据，低电平指令
reg wr_rd;//写入完成，高电平有效
reg [7:0] wr_cmd;//待写入数据

//DB连线
reg DBo_en;//高电平输出使能
reg [7:0] DBo;//DB输出寄存器
reg BF;//DB[7]输入，仅用于判别是否繁忙，0代表可写
assign DB = DBo_en ? DBo : 8'hz;

//写操作状态机
reg [2:0] state, state_n;
localparam idle=3'h0;//空闲状态
localparam bf_w=3'h1;//读取BF状态，设置rsrw
localparam bf_e=3'h2;//读取BF状态，EN拉高
localparam bf_r=3'h3;//读取BF状态，EN拉低
localparam cm_w=3'h4;//写入信息，设置rsrw
localparam cm_e=3'h5;//写入信息，EN拉高
localparam cm_r=3'h6;//写入信息，EN拉低
localparam wend=3'h7;//结束
//状态转移
always @(posedge clk) begin
    if (!rst_n) begin
        state <= idle;
        BF <= 0;
    end
    else begin
        state <= state_n;
        BF <= DB[7];
    end
end
//下一状态
always @(*) begin
    if (!rst_n) begin
        state_n = idle;
    end
    else begin
        case (state)
            idle:begin
                if (wr_en) begin
                    state_n = bf_w;
                end
                else begin
                    state_n = idle;
                end
            end
            bf_w:begin
                state_n = bf_e;
            end
            bf_e:begin
                state_n = bf_r;
            end
            bf_r:begin
                if (BF) begin
                    state_n = bf_w;
                end
                else begin
                    state_n = cm_w;
                end
            end
            cm_w:begin
                state_n = cm_e;
            end
            cm_e:begin
                state_n = cm_r;
            end
            cm_r:begin
                state_n = wend;
            end
            wend:begin
                state_n = idle;
            end
            default:begin
                state_n = idle;
            end
        endcase
    end
end

//输出
always @(*) begin
    if(!rst_n)begin
        DBo_en = 0;
        DBo = 0;
        RS = 0;
        RW = 0;
        EN = 0;
        wr_rd = 0;
    end
    else begin
        case (state)
            idle:begin
                DBo_en = 0;
                DBo = 0;
                RS = 0;
                RW = 0;
                EN = 0;
                wr_rd = 0;
            end
            bf_w:begin//读取BF状态，设置rsrw
                DBo_en = 0;//从lcd1602读取
                DBo = 0;
                RS = 0;//指令
                RW = 1;//读取
                EN = 0;
                wr_rd = 0;
            end
            bf_e:begin
                DBo_en = 0;//从lcd1602读取
                DBo = 0;
                RS = 0;//指令
                RW = 1;//读取
                EN = 1;
                wr_rd = 0;
            end
            bf_r:begin
                DBo_en = 0;//从lcd1602读取
                DBo = 0;
                RS = 0;//指令
                RW = 1;//读取
                EN = 0;
                wr_rd = 0;
            end
            cm_w:begin
                DBo_en = 1;//向lcd1602写入
                DBo = wr_cmd;
                RS = wr_rs;
                RW = 0;
                EN = 0;
                wr_rd = 0;
            end
            cm_e:begin
                DBo_en = 1;//向lcd1602写入
                DBo = wr_cmd;
                RS = wr_rs;
                RW = 0;
                EN = 1;
                wr_rd = 0;
            end
            cm_r:begin
                DBo_en = 1;//向lcd1602写入
                DBo = wr_cmd;
                RS = wr_rs;
                RW = 0;
                EN = 0;
                wr_rd = 0;
            end
            wend:begin
                DBo_en = 0;
                DBo = 0;
                RS = 0;
                RW = 0;
                EN = 0;
                wr_rd = 1;
            end
            default:begin
                DBo_en = 0;
                DBo = 0;
                RS = 0;
                RW = 0;
                EN = 0;
                wr_rd = 0;
            end
        endcase
    end
end

endmodule 