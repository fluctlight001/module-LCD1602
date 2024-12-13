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

//刷屏FSM
reg flash, flash_n;
localparam init_38=6'd0;//复位后第一个状态
localparam init_01=6'd1;
localparam init_0c=6'd2;
localparam init_06=6'd3;//初始化完成，进入atfh_l1
localparam atfh_l1=6'd4;//设置第一行
localparam atfh_0=6'd5;
localparam atfh_1=6'd6;
localparam atfh_2=6'd7;
localparam atfh_3=6'd8;
localparam atfh_4=6'd9;
localparam atfh_5=6'd10;
localparam atfh_6=6'd11;
localparam atfh_7=6'd12;
localparam atfh_8=6'd13;
localparam atfh_9=6'd14;
localparam atfh_10=6'd15;
localparam atfh_11=6'd16;
localparam atfh_12=6'd17;
localparam atfh_13=6'd18;
localparam atfh_14=6'd19;
localparam atfh_15=6'd20;
localparam atfh_l2=6'd21;//设置第2行
localparam atfh_16=6'd22;
localparam atfh_17=6'd23;
localparam atfh_18=6'd24;
localparam atfh_19=6'd25;
localparam atfh_20=6'd26;
localparam atfh_21=6'd27;
localparam atfh_22=6'd28;
localparam atfh_23=6'd29;
localparam atfh_24=6'd30;
localparam atfh_25=6'd31;
localparam atfh_26=6'd32;
localparam atfh_27=6'd33;
localparam atfh_28=6'd34;
localparam atfh_29=6'd35;
localparam atfh_30=6'd36;
localparam atfh_31=6'd37;

//状态转移
always @(posedge clk) begin
    if (!rst_n) begin
        flash <= init_38;
    end
    else begin
        flash <= flash_n;
    end
end
always @(*) begin
    if (!rst_n) begin
        flash_n = init_38;
    end
    else begin
        case(flash)
            init_38:flash_n = wr_rd ? init_01 : init_38;
            init_01:flash_n = wr_rd ? init_0c : init_01;
            init_0c:flash_n = wr_rd ? init_06 : init_0c;
            init_06:flash_n = wr_rd ? atfh_l1 : init_06;
            atfh_l1:flash_n = wr_rd ? atfh_0  : atfh_l1;
            atfh_0 :flash_n = wr_rd ? atfh_1  : atfh_0 ;
            atfh_1 :flash_n = wr_rd ? atfh_2  : atfh_1 ;
            atfh_2 :flash_n = wr_rd ? atfh_3  : atfh_2 ;
            atfh_3 :flash_n = wr_rd ? atfh_4  : atfh_3 ;
            atfh_4 :flash_n = wr_rd ? atfh_5  : atfh_4 ;
            atfh_5 :flash_n = wr_rd ? atfh_6  : atfh_5 ;
            atfh_6 :flash_n = wr_rd ? atfh_7  : atfh_6 ;
            atfh_7 :flash_n = wr_rd ? atfh_8  : atfh_7 ;
            atfh_8 :flash_n = wr_rd ? atfh_9  : atfh_8 ;
            atfh_9 :flash_n = wr_rd ? atfh_10 : atfh_9 ;
            atfh_10:flash_n = wr_rd ? atfh_11 : atfh_10;
            atfh_11:flash_n = wr_rd ? atfh_12 : atfh_11;
            atfh_12:flash_n = wr_rd ? atfh_13 : atfh_12;
            atfh_13:flash_n = wr_rd ? atfh_14 : atfh_13;
            atfh_14:flash_n = wr_rd ? atfh_15 : atfh_14;
            atfh_15:flash_n = wr_rd ? atfh_l2 : atfh_15;
            atfh_l2:flash_n = wr_rd ? atfh_16 : atfh_l2;
            atfh_16:flash_n = wr_rd ? atfh_17 : atfh_16;
            atfh_17:flash_n = wr_rd ? atfh_18 : atfh_17;
            atfh_18:flash_n = wr_rd ? atfh_19 : atfh_18;
            atfh_19:flash_n = wr_rd ? atfh_20 : atfh_19;
            atfh_20:flash_n = wr_rd ? atfh_21 : atfh_20;
            atfh_21:flash_n = wr_rd ? atfh_22 : atfh_21;
            atfh_22:flash_n = wr_rd ? atfh_23 : atfh_22;
            atfh_23:flash_n = wr_rd ? atfh_24 : atfh_23;
            atfh_24:flash_n = wr_rd ? atfh_25 : atfh_24;
            atfh_25:flash_n = wr_rd ? atfh_26 : atfh_25;
            atfh_26:flash_n = wr_rd ? atfh_27 : atfh_26;
            atfh_27:flash_n = wr_rd ? atfh_28 : atfh_27;
            atfh_28:flash_n = wr_rd ? atfh_29 : atfh_28;
            atfh_29:flash_n = wr_rd ? atfh_30 : atfh_29;
            atfh_30:flash_n = wr_rd ? atfh_31 : atfh_30;
            atfh_31:flash_n = wr_rd ? atfh_l1 : atfh_31;
            default:flash_n = init_38;
        endcase
    end
end

//输出
always @(*) begin
    if (!rst_n) begin
        wr_cmd = 0;
        wr_rs = 0;
        wr_en = 0;
    end
    else begin
        case(flash)
            init_38:begin
                wr_cmd = 8'h38;
                wr_rs = 0;
                wr_en = 1;
            end
            init_01:begin
                wr_cmd = 8'h01;
                wr_rs = 0;
                wr_en = 1;
            end
            init_0c:begin
                wr_cmd = 8'h0c;
                wr_rs = 0;
                wr_en = 1;
            end
            init_06:begin
                wr_cmd = 8'h06;
                wr_rs = 0;
                wr_en = 1;
            end
            atfh_l1:begin
                wr_cmd = 8'h80;
                wr_rs = 0;
                wr_en = 1;
            end
            atfh_0:begin
                wr_cmd = dram[0];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_1:begin
                wr_cmd = dram[1];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_2:begin
                wr_cmd = dram[2];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_3:begin
                wr_cmd = dram[3];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_4:begin
                wr_cmd = dram[4];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_5:begin
                wr_cmd = dram[5];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_6:begin
                wr_cmd = dram[6];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_7:begin
                wr_cmd = dram[7];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_8:begin
                wr_cmd = dram[8];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_9:begin
                wr_cmd = dram[9];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_10:begin
                wr_cmd = dram[10];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_11:begin
                wr_cmd = dram[11];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_12:begin
                wr_cmd = dram[12];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_13:begin
                wr_cmd = dram[13];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_14:begin
                wr_cmd = dram[14];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_15:begin
                wr_cmd = dram[15];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_l2:begin
                wr_cmd = 8'hc0;
                wr_rs = 0;
                wr_en = 1;
            end
            atfh_16:begin
                wr_cmd = dram[16];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_17:begin
                wr_cmd = dram[17];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_18:begin
                wr_cmd = dram[18];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_19:begin
                wr_cmd = dram[19];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_20:begin
                wr_cmd = dram[20];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_21:begin
                wr_cmd = dram[21];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_22:begin
                wr_cmd = dram[22];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_23:begin
                wr_cmd = dram[23];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_24:begin
                wr_cmd = dram[24];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_25:begin
                wr_cmd = dram[25];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_26:begin
                wr_cmd = dram[26];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_27:begin
                wr_cmd = dram[27];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_28:begin
                wr_cmd = dram[28];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_29:begin
                wr_cmd = dram[29];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_30:begin
                wr_cmd = dram[30];
                wr_rs = 1;
                wr_en = 1;
            end
            atfh_31:begin
                wr_cmd = dram[31];
                wr_rs = 1;
                wr_en = 1;
            end
            default:begin
                wr_cmd = 0;
                wr_rs = 0;
                wr_en = 0;
            end
        endcase
    end
end
endmodule 