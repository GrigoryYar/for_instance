----------------------------------------------------------------
--
-- Project  : WiFi IEEE 802.11 a/b/g/n demodulator
-- Function : Space Streams splitter
-- Engineer : Grigory Polushkin
-- Created  : 07.06.2019
--
----------------------------------------------------------------

--`timescale 1ns / 100ps
--`default_nettype none

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity space_streams_splitter is 
    generic 
    (
        Z           : integer := 0;
        MODULATION  : natural := 1
    );
    port   
    (
        CLK         : in std_logic;
        
        DATA_SS1    : in std_logic_vector(2 downto 0);
        DATA_SS2    : in std_logic_vector(2 downto 0);
        DATA_DV     : in std_logic;
        
        DATA_OUT    : out std_logic_vector(2 downto 0);
        DATA_OUT_DV : out std_logic
    );
end space_streams_splitter;

architecture rtl of space_streams_splitter is
   
    constant DEPTH : natural := 2*52*MODULATION;

    type  ram_splitter is array (DEPTH - 1 downto 0) of std_logic_vector (2 downto 0);
    signal r_ram_splitter : ram_splitter;
    
    signal r_wr_addr2_start : std_logic_vector (9 downto 0) := (others => '0');
    
    signal r_inc_en         : std_logic_vector (1 downto 0) := (others => '0');
    signal r_inc_th         : std_logic_vector (1 downto 0) := (others => '0');
    signal r_inc_step       : std_logic_vector (2 downto 0) := (others => '0');
                            
    signal r_wr_addr_ss1    : std_logic_vector (9 downto 0) := (others => '0');
    signal r_wr_addr_ss2    : std_logic_vector (9 downto 0) := (others => '0');
                            
    signal r_rd_addr_cnt    : std_logic_vector (9 downto 0) := (others => '0');
    signal r_rd_addr        : std_logic_vector (9 downto 0) := (others => '0');
    signal r_data_out_dv    : std_logic := '0';

begin

    DATA_OUT <= r_ram_splitter( to_integer(unsigned(r_rd_addr)) );
    DATA_OUT_DV <= r_data_out_dv; 


    init:
    process( CLK )
    begin
        if ( CLK'event and CLK ='1') then
            case ( MODULATION ) is
                when 1|2 =>
                    r_wr_addr2_start <=  10d"1";
                    r_inc_th         <=   2d"0";
                    r_inc_step       <=   3d"2";                
                when 4 =>
                    r_wr_addr2_start <=  10d"2";
                    r_inc_th         <=   2d"1";
                    r_inc_step       <=   3d"3";                
                when 6 =>                  
                    r_wr_addr2_start <=  10d"3";
                    r_inc_th         <=   2d"2";
                    r_inc_step       <=   3d"4";
                when others =>            
                    r_wr_addr2_start <=  10d"1";
                    r_inc_th         <=   2d"0";
                    r_inc_step       <=   3d"0";                
            end case;

       end if;
    end process;

    write_pointers:
    process( CLK )
    begin
        if( CLK'event and CLK ='1' ) then
            if( DATA_DV = '0' ) then
                r_wr_addr_ss1 <= (others => '0');
                r_wr_addr_ss2 <= r_wr_addr2_start;
                r_inc_en <= 2d"0";
            else
                if( r_inc_en < r_inc_th ) then
                    r_inc_en <= r_inc_en + '1';
                else
                    r_inc_en <= 2d"0";
                end if;
            
                r_wr_addr_ss1 <= r_wr_addr_ss1 + r_inc_step when r_inc_en = r_inc_th
                                 else r_wr_addr_ss1 + 1;
                r_wr_addr_ss2 <= r_wr_addr_ss2 + r_inc_step when r_inc_en = r_inc_th
                                 else r_wr_addr_ss2 + 1;
                    
                r_ram_splitter( to_integer(unsigned(r_wr_addr_ss1)) ) <= DATA_SS1;
                r_ram_splitter( to_integer(unsigned(r_wr_addr_ss2)) ) <= DATA_SS2;
            end if;
        end if;
    end process;

    read_pointer:
    process( CLK )
    begin
        if( CLK'event and CLK ='1' ) then
        
            if( r_wr_addr_ss1 = 10d"8" ) then
                r_rd_addr_cnt <= std_logic_vector(to_unsigned(DEPTH-1, 10));
                r_rd_addr <= (others => '0');
                r_data_out_dv  <= '1';
            elsif ( r_rd_addr_cnt > 0 ) then
                r_rd_addr_cnt <= r_rd_addr_cnt - 1;
                r_rd_addr <= r_rd_addr + 1;
            else
                r_data_out_dv  <= '0';
            end if;
        
        end if;
    end process;
    
end rtl;