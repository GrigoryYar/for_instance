////////////////////////////////////////////////////////////////
//
// Project  : WiFi IEEE 802.11 a/b/g/n demodulator
// Function : Space Streams splitter
// Engineer : Grigory Polushkin
// Created  : 07.06.2019
//
////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps
`default_nettype none

/*
space_streams_splitter
    #(
        .Z              ( 0 ),
        .MODULATION     ( 1 )  // 1 - bpsk, 2 - qpsk, 4 - qam16, 6 - qam64
    )
    space_streams_splitter_inst
    (
        .CLK            (   ), // in,  u[ 1], clock signal

        .DATA_SS1       (   ), // in,  u[ 3], space stream[1] data input
        .DATA_SS2       (   ), // in,  u[ 3], space stream[2] data input
        .DATA_DV        (   ), // in,  u[ 1], input valid
        
        .DATA_OUT       (   ), // out, u[ 3], splitter data out
        .DATA_OUT_DV    (   )  // out, u[ 1], out valid
    );
*/

module space_streams_splitter
#(
    parameter Z = 0,
    parameter MODULATION = 0
)
(
    input  wire         CLK,
    
    input  wire [2:0]   DATA_SS1,
    input  wire [2:0]   DATA_SS2,
    input  wire         DATA_DV,
    
    output wire [2:0]   DATA_OUT,
    output wire         DATA_OUT_DV
);

localparam DEPTH = 2*52*MODULATION;

reg [2:0] r_ram_splitter [ 0 : DEPTH-1 ];

reg [9:0] r_wr_addr2_start  = 10'h0;
reg [1:0] r_inc_en          = 2'h0;
reg [1:0] r_inc_th          = 2'h0;
reg [2:0] r_inc_step        = 3'h0;

reg [9:0] r_wr_addr_ss1     = 10'h0;
reg [9:0] r_wr_addr_ss2     = 10'h0;

reg [9:0] r_rd_addr_cnt     = 10'h0;
reg [9:0] r_rd_addr         = 10'h0;
reg       r_data_out_dv     =  1'b0;

assign DATA_OUT = r_ram_splitter[r_rd_addr];
assign DATA_OUT_DV = r_data_out_dv;

always @( posedge CLK )
begin
    case ( MODULATION )
        1,2:
            begin
                r_wr_addr2_start <= #Z 10'h1;
                r_inc_th         <= #Z  2'h0;
                r_inc_step       <= #Z  3'h2;                
            end
        4:  
            begin
                r_wr_addr2_start <= #Z 10'h2;
                r_inc_th         <= #Z  2'h1;
                r_inc_step       <= #Z  3'h3;                
            end
        6:  
            begin
                r_wr_addr2_start <= #Z 10'h3;
                r_inc_th         <= #Z  2'h2;
                r_inc_step       <= #Z  3'h4;
            end
        default: 
            begin
                r_wr_addr2_start <= #Z 10'h1;
                r_inc_th         <= #Z  2'h0;
                r_inc_step       <= #Z  3'h0;                
            end
    endcase
end
        
always @( posedge CLK )
begin
    if( !DATA_DV )
    begin
        r_wr_addr_ss1 <= #Z 10'h0;
        r_wr_addr_ss2 <= #Z r_wr_addr2_start;
        r_inc_en <= #Z 2'h0;
    end
    else 
    begin
        if( r_inc_en < r_inc_th )
            r_inc_en <= #Z r_inc_en + 1'b1;
        else
            r_inc_en <= #Z 2'h0;
            
        r_wr_addr_ss1 <= #Z (r_inc_en == r_inc_th ) ? r_wr_addr_ss1 + r_inc_step : r_wr_addr_ss1 + 10'h1;
        r_wr_addr_ss2 <= #Z (r_inc_en == r_inc_th ) ? r_wr_addr_ss2 + r_inc_step : r_wr_addr_ss2 + 10'h1;
            
	r_ram_splitter[r_wr_addr_ss1] <= #Z DATA_SS1;
	r_ram_splitter[r_wr_addr_ss2] <= #Z DATA_SS2;
    end
    
    if( r_wr_addr_ss1 == 10'h8 )
    begin
        r_rd_addr_cnt <= #Z DEPTH - 1;
        r_rd_addr <= #Z 10'h0;
        r_data_out_dv  <= #Z 1'b1;
    end
    else if( |r_rd_addr_cnt )
        begin
            r_rd_addr_cnt <= #Z r_rd_addr_cnt - 1'b1;
            r_rd_addr <= #Z r_rd_addr + 1'b1;
        end
        else
            r_data_out_dv  <= #Z 1'b0;
end


endmodule
