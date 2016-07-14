-- Dual ram with independent read and write ports
-- used as a ping pong buffer. Async read.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_dualp is
    generic(
        PP_BUF_ADDR_WIDTH : natural := 6
    );
	port
	(
        clk     : in std_logic;
        lock : in std_logic;
        rd_sel : in std_logic;
        rd_addr : in std_logic_vector(PP_BUF_ADDR_WIDTH - 1 downto 0);
        rd_data : out std_logic_vector(7 downto 0);
        wr : in std_logic;
        wr_addr : in std_logic_vector(PP_BUF_ADDR_WIDTH - 1 downto 0);
        wr_data : in std_logic_vector(7 downto 0)
	);
end entity;

architecture beh of ram_dualp is
    type mem_type is array ( (2**PP_BUF_ADDR_WIDTH) - 1 downto 0 ) of std_logic_vector(7 downto 0);
    signal buf0, buf1 : mem_type;
    signal buf0_rd_data : std_logic_vector(7 downto 0);
    signal buf1_rd_data : std_logic_vector(7 downto 0);
    signal buf0_wr_data : std_logic_vector(7 downto 0);
    signal buf1_wr_data : std_logic_vector(7 downto 0);
begin
    mux_wr : process(lock, wr_data, buf0_rd_data, buf1_rd_data)
    begin
      if(lock = '0') then
        buf0_wr_data <= wr_data;
        buf1_wr_data <= buf1(to_integer(unsigned(wr_addr)));
      else
        buf0_wr_data <= buf0(to_integer(unsigned(wr_addr)));
        buf1_wr_data <= wr_data;
      end if;
    end process;

    mux_rd : process(rd_sel, rd_addr, buf0_rd_data, buf1_rd_data)
    begin
        if(rd_sel = '1') then
            rd_data <= buf1_rd_data;
        else
            rd_data <= buf0_rd_data;
        end if;
    end process mux_rd;

    update_buf0 : process(clk, wr_addr, wr, rd_addr, buf0_wr_data)
    begin
        if(rising_edge(clk)) then
            if(wr = '1') then
                buf0(to_integer(unsigned(wr_addr))) <= buf0_wr_data;
            end if;
        end if;
        buf0_rd_data <= buf0(to_integer(unsigned(rd_addr)));
    end process update_buf0;

    update_buf1 : process(clk, wr_data, wr_addr, wr, rd_addr, buf1_wr_data)
    begin
        if(rising_edge(clk)) then
            if(wr = '1') then
                buf1(to_integer(unsigned(wr_addr))) <= buf1_wr_data;
            end if;
        end if;
        buf1_rd_data <= buf1(to_integer(unsigned(rd_addr)));
    end process update_buf1;
end beh;
