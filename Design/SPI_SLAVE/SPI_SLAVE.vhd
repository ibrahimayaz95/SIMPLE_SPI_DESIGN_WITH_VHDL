---------------------------------------------------------------------------------------
-- Engineer: IBRAHIM AYAZ                                                            --
-- Create Date: 16.03.2023 12:00:00                                                  --
-- Design Name: SPI_SLAVE.vhd                                                        --
--                                                                                   --
-- Description: SPI Slave component design for the SPI communication protocol.       --
--                                                                                   --
-- Output: The output data is a serialized SPI data to the master component.         --
---------------------------------------------------------------------------------------

-- Library declaration
library IEEE;
use IEEE.std_logic_1164.all;

entity SPI_SLAVE is
    generic (
        CLK_FREQ    :   integer := 100_000_000;                                     --! Clock frequency
        BAUDRATE    :   integer := 115_200;                                         --! SPI baudrate
        DATA_LIMIT  :   integer := 8                                                --! Selected SPI data bit width
    );
    port (
        -- Input ports
        CLK     :   in  std_logic;                                                  --! Clock port
        RESET   :   in  std_logic;                                                  --! Reset port
        MOSI    :   in  std_logic;                                                  --! Master out Slave in port
        SS      :   in std_logic;                                                   --! Slave Select port
        SCK     :   in std_logic;                                                   --! Generated SPI clock port
        SLIN    :   in  std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0);         --! Parallel data input port
        -- Output Ports
        MISO    :   out std_logic;                                                  --! Master in Slave Out port
        SLOUT   :   out std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0);         --! Parallel data output port
        SLREADY :   out std_logic;                                                  --! Slave ready port
        SLDONE  :   out std_logic                                                   --! Slave done port
    );
end entity SPI_SLAVE;

architecture rtl of SPI_SLAVE is

    -- State type definition
    type state_type is (S_IDLE, S_TRANSCEIVE, S_STOP);                                                      --! Type for the states
    -- State signals    
    signal PS, NS      :   state_type   := S_IDLE;                                                          --! Present and Next State signal's declaration

    -- Register signals
    signal CPOL_REG    :    std_logic   := '0';                                                             --! Clock polarity control signal
    signal CPHA_REG    :    std_logic   := '0';                                                             --! Clock phase control signal
    signal SS_REG      :    std_logic   := '1';                                                             --! Register for the Slave select
    signal MOSI_REG    :    std_logic_vector ((DATA_LIMIT - 1) downto 0)         := (others => '0');        --! Shift register for the MOSI
    signal MISO_REG    :    std_logic_vector ((DATA_LIMIT - 1) downto 0)         := (others => '0');        --! Shift register for the MISO
    signal MISO_TEMP   :    std_logic_vector ((DATA_LIMIT - 1) downto 0)         := (others => '0');        --! Register for the input data
    signal SLOUT_REG    :   std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0)   := (others => '0');        --! Register for the output data
    
    -- Counter signal
    signal DATA_COUNTER:    integer     := 0;                                                               --! Counter signal                                                               

begin

    -- Input assignments
    CPHA_REG  <= SLIN (0);
    CPOL_REG  <= SLIN (1);
    MISO_TEMP <= SLIN (((DATA_LIMIT + 2) - 1) downto 2);
    SS_REG    <= SS;

    -- Synchronises the states of the Main process
    FSM_SYNC:   process (CLK, RESET)
    begin
        if (RESET = '1') then
            PS <= S_IDLE;
        elsif (rising_edge(CLK)) then
            PS <= NS;
        end if;
    end process;

    -- SPI data control logic
    MAIN:   process (RESET, SS_REG, PS, SCK, CLK)
    begin
        case (PS) is

            when (S_IDLE) =>
                if(RESET = '1') then
                    NS           <= S_IDLE;
                    SLREADY      <= '0';
                    SLDONE       <= '0';
                    MISO         <= '0';
                    DATA_COUNTER <= 0;
                    MOSI_REG     <= (others => '0');
                    MISO_REG     <= (others => '0');
                elsif (SS_REG = '0') then
                    NS       <= S_TRANSCEIVE;
                    SLREADY  <= '0';
                    MISO_REG <= MISO_TEMP;
                else
                    NS           <= S_IDLE;
                    SLREADY      <= '1';
                    SLDONE       <= '0';
                    MISO         <= '0';
                    DATA_COUNTER <= 0;
                    MOSI_REG     <= (others => '0');
                    MISO_REG     <= (others => '0');
                end if;

            when (S_TRANSCEIVE) =>
            if(CPHA_REG = '0') then
                if (CPOL_REG = '0') then
                    if (DATA_COUNTER = ((DATA_LIMIT * 2) - 1)) then
                        if (falling_edge(SCK)) then
                            NS <= S_STOP;
                        end if;
                    else
                        MISO <= MISO_REG (0);
                        if (rising_edge(SCK)) then
                            MOSI_REG ((DATA_LIMIT - 1)) <= MOSI;
                            DATA_COUNTER                <= DATA_COUNTER + 1;
                        elsif (falling_edge(SCK)) then
                            MOSI_REG     <= MOSI_REG (0) & MOSI_REG ((DATA_LIMIT - 1) downto 1);                        
                            MISO_REG     <= MISO_REG (0) & MISO_REG ((DATA_LIMIT - 1) downto 1);                        
                            DATA_COUNTER <= DATA_COUNTER + 1;
                        end if;
                    end if;
                elsif (CPOL_REG = '1') then
                    if (DATA_COUNTER = (DATA_LIMIT * 2) - 1) then
                        if (rising_edge(SCK)) then
                            NS <= S_STOP;
                        end if;
                    else
                        MISO <= MISO_REG (0);
                        if (falling_edge(SCK)) then
                            MOSI_REG ((DATA_LIMIT - 1)) <= MOSI;
                            DATA_COUNTER                <= DATA_COUNTER + 1;
                        elsif (rising_edge(SCK)) then
                            MOSI_REG     <= MOSI_REG (0) & MOSI_REG ((DATA_LIMIT - 1) downto 1);                        
                            MISO_REG     <= MISO_REG (0) & MISO_REG ((DATA_LIMIT - 1) downto 1);                        
                            DATA_COUNTER <= DATA_COUNTER + 1;
                        end if;
                    end if;
                else
                    NS <= S_IDLE;
                end if;
            elsif (CPHA_REG = '1') then
                if (CPOL_REG = '0') then
                    if (DATA_COUNTER = (DATA_LIMIT * 2)) then
                        NS <= S_STOP;
                    else
                        if (DATA_COUNTER = 0) then
                            if (rising_edge(SCK)) then
                                DATA_COUNTER <= DATA_COUNTER + 1;
                            end if;
                        else
                            MISO <= MISO_REG (0);
                            if(falling_edge(SCK)) then
                                MOSI_REG ((DATA_LIMIT - 1)) <= MOSI;
                                DATA_COUNTER                <= DATA_COUNTER + 1;
                            elsif (rising_edge(SCK)) then
                                MOSI_REG     <= MOSI_REG (0) & MOSI_REG ((DATA_LIMIT - 1) downto 1);                        
                                MISO_REG     <= MISO_REG (0) & MISO_REG ((DATA_LIMIT - 1) downto 1);                        
                                DATA_COUNTER <= DATA_COUNTER + 1;                        
                            end if;
                        end if;
                    end if;
                elsif (CPOL_REG = '1') then
                    if (DATA_COUNTER = (DATA_LIMIT * 2)) then
                        NS <= S_STOP;
                    else
                        if (DATA_COUNTER = 0) then
                            if (falling_edge(SCK)) then
                                DATA_COUNTER <= DATA_COUNTER + 1;
                            end if;
                        else
                            MISO <= MISO_REG (0);
                            if(rising_edge(SCK)) then
                                MOSI_REG ((DATA_LIMIT - 1)) <= MOSI;
                                DATA_COUNTER                <= DATA_COUNTER + 1;
                            elsif (falling_edge(SCK)) then
                                MOSI_REG     <= MOSI_REG (0) & MOSI_REG ((DATA_LIMIT - 1) downto 1);                        
                                MISO_REG     <= MISO_REG (0) & MISO_REG ((DATA_LIMIT - 1) downto 1);                        
                                DATA_COUNTER <= DATA_COUNTER + 1;                        
                            end if;
                        end if;
                    end if;
                else
                    NS <= S_IDLE;
                end if;
            else
                NS <= S_IDLE;
            end if;

            when (S_STOP) =>
                SLOUT_REG <= (MOSI_REG) & (CPOL_REG) & (CPHA_REG);
                if(SS_REG = '1') then
                    NS           <= S_IDLE;
                    SLDONE       <= '1';
                    DATA_COUNTER <= 0;
                end if;

            when others =>
                NS           <= S_IDLE;
                SLREADY      <= '1';
                SLDONE       <= '0';
                MISO         <= '0';
                DATA_COUNTER <= 0;
                MOSI_REG     <= (others => '0');
                MISO_REG     <= (others => '0');

        end case;
    end process;

    -- Output assignments
    SLOUT <= (SLOUT_REG) when (RESET = '0') else
            (others => '0');

end architecture;