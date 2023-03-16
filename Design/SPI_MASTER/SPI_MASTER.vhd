---------------------------------------------------------------------------------------
-- Engineer: IBRAHIM AYAZ                                                            --
-- Create Date: 15.03.2023 14:30:00                                                  --
-- Design Name: SPI_MASTER.vhd                                                       --
--                                                                                   --
-- Description: SPI Master component design for the SPI communication protocol.      --
--                                                                                   --
-- Output: The output data is a serialized SPI data to the slave component.          --
---------------------------------------------------------------------------------------

-- Library declaration
library IEEE;
use IEEE.std_logic_1164.all;

entity SPI_MASTER is
    generic (
        CLK_FREQ    :   integer := 100_000_000;                                     --! Clock frequency
        BAUDRATE    :   integer := 115_200;                                         --! SPI baudrate
        DATA_LIMIT  :   integer := 8                                                --! Selected SPI data bit width
    );
    port (
        -- Input ports
        CLK     :   in  std_logic;                                                  --! Clock port                                                  
        RESET   :   in  std_logic;                                                  --! Reset port
        MEN     :   in  std_logic;                                                  --! Master enable port. (Should be asserted high for at least 2 system clock cycles!)
        MISO    :   in  std_logic;                                                  --! Master in Slave Out port
        MIN     :   in  std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0);         --! Parallel data input port 
        -- Output Ports
        SCK     :   out std_logic;                                                  --! Generated SPI clock port
        SS      :   out std_logic;                                                  --! Slave Select port
        MOSI    :   out std_logic;                                                  --! Master out Slave in port
        MOUT    :   out std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0);         --! Parallel data output port
        MREADY  :   out std_logic;                                                  --! Master ready port
        MDONE   :   out std_logic                                                   --! Master done port
    );
end entity SPI_MASTER;

architecture rtl of SPI_MASTER is

    -- State type definition
    type state_type is (S_IDLE, S_TRANSCEIVE, S_STOP);                                                      --! Type for the states
    -- State signals    
    signal PS, NS      :   state_type   := S_IDLE;                                                          --! Present and Next State signal's declaration

    signal SPI_HALF_PERIOD  :    integer     := ((CLK_FREQ) / (BAUDRATE * 2));                              --! SPI clock counter limit

    -- Register signals
    signal CPOL_REG    :    std_logic   := '0';                                                             --! Clock polarity control signal
    signal CPHA_REG    :    std_logic   := '0';                                                             --! Clock phase control signal
    signal SCK_REG     :    std_logic   := '0';                                                             --! Register for the SPI clock
    signal SS_REG      :    std_logic   := '1';                                                             --! Register for the Slave select
    signal MOSI_REG    :    std_logic_vector ((DATA_LIMIT - 1) downto 0)         := (others => '0');        --! Shift register for the MOSI
    signal MOSI_TEMP   :    std_logic_vector ((DATA_LIMIT - 1) downto 0)         := (others => '0');        --! Register for the input data
    signal MISO_REG    :    std_logic_vector ((DATA_LIMIT - 1) downto 0)         := (others => '0');        --! Shift register for the MISO
    signal MOUT_REG    :    std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0)   := (others => '0');        --! Register for the output data
    
    -- Counter signals
    signal SCK_COUNTER :    integer     := 0;                                                               --! Counter signal for the SPI clock 
    signal DATA_COUNTER:    integer     := 0;                                                               --! Counter signal for the transceive state
    signal SCK_EN      :    std_logic   := '0';                                                             --! SPI clock counter enable signal
    signal SCK_DONE    :    std_logic   := '0';                                                             --! SPI clock counter done signal

begin

    -- Input assignments
    CPHA_REG  <= MIN (0);
    CPOL_REG  <= MIN (1);
    MOSI_TEMP <= MIN (((DATA_LIMIT + 2) - 1) downto 2);

    -- SPI clock generator
    GEN_SCK:    process (CLK)
    begin
        if (rising_edge(CLK)) then
            if (SCK_EN = '1') then
                if (SCK_COUNTER = (SPI_HALF_PERIOD - 1)) then
                    SCK_REG     <= not (SCK_REG);
                    SCK_COUNTER <= 0;
                    SCK_DONE    <= '1';
                else
                    SCK_COUNTER <= SCK_COUNTER + 1;
                    SCK_DONE    <= '0';
                end if;
            else
                SCK_REG     <= CPOL_REG;
                SCK_COUNTER <= 0;
                SCK_DONE    <= '0';
            end if;
        end if;
    end process;

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
    MAIN:   process (RESET, PS, MEN, SCK_DONE)
    begin
        case (PS) is

            when (S_IDLE) =>
                if(RESET = '1') then
                    NS           <= S_IDLE;
                    MREADY       <= '0';
                    MDONE        <= '0';
                    SS_REG       <= '1';
                    MOSI         <= '1';
                    SCK_EN       <= '0';
                    DATA_COUNTER <= 0;
                    MISO_REG     <= (others => '0');
                    MOSI_REG     <= (others => '0');
                elsif (MEN = '1') then
                    NS       <= S_TRANSCEIVE;
                    MREADY   <= '0';
                    SS_REG   <= '0';
                    SCK_EN   <= '1';
                    MOSI_REG <= MOSI_TEMP;
                else
                    NS           <= S_IDLE;
                    MREADY       <= '1';
                    MDONE        <= '0';
                    SS_REG       <= '1';
                    MOSI         <= '1';
                    SCK_EN       <= '0';
                    DATA_COUNTER <= 0;
                    MOSI_REG     <= (others => '0');
                    MISO_REG     <= (others => '0');
                end if;

            when (S_TRANSCEIVE) =>
                if(CPHA_REG = '0') then
                    if (DATA_COUNTER = ((DATA_LIMIT * 2) - 1)) then
                        if(SCK_DONE = '1') then
                            NS           <= S_STOP;
                            MOSI         <= '1';
                        end if;
                    else
                        MOSI <= MOSI_REG (0);
                        if(SCK_DONE = '1') then
                            if ((DATA_COUNTER rem 2) = 0) then
                                MISO_REG ((DATA_LIMIT - 1)) <= MISO;
                                DATA_COUNTER                <= DATA_COUNTER + 1;
                            else        
                                MOSI_REG     <= MOSI_REG (0) & MOSI_REG ((DATA_LIMIT - 1) downto 1);                        
                                MISO_REG     <= MISO_REG (0) & MISO_REG ((DATA_LIMIT - 1) downto 1);                        
                                DATA_COUNTER <= DATA_COUNTER + 1;
                            end if;                         
                        end if;
                    end if;
                elsif (CPHA_REG = '1') then
                    if (DATA_COUNTER = (DATA_LIMIT * 2)) then
                        NS <= S_STOP;
                    else
                        if (DATA_COUNTER = 0) then
                            MOSI <= '1';
                            if(SCK_DONE = '1') then
                                DATA_COUNTER <= DATA_COUNTER + 1;
                            end if;
                        else
                            MOSI <= MOSI_REG (0);
                            if(SCK_DONE = '1') then
                                if ((DATA_COUNTER rem 2) /= 0) then
                                    MISO_REG ((DATA_LIMIT - 1)) <= MISO;
                                    DATA_COUNTER                <= DATA_COUNTER + 1;
                                else       
                                    MOSI_REG     <= MOSI_REG (0) & MOSI_REG ((DATA_LIMIT - 1) downto 1);                        
                                    MISO_REG     <= MISO_REG (0) & MISO_REG ((DATA_LIMIT - 1) downto 1);                        
                                    DATA_COUNTER <= DATA_COUNTER + 1;
                                end if;                         
                            end if;
                        end if;
                    end if;
                else
                    NS <= S_IDLE;
                end if;

            when (S_STOP) =>
                    MOUT_REG     <= (MISO_REG) & (CPOL_REG) & (CPHA_REG);
                if(SCK_DONE = '1') then
                    NS           <= S_IDLE;
                    SS_REG       <= '1';
                    MDONE        <= '1';
                    SCK_EN       <= '0';
                    DATA_COUNTER <= 0;
                end if;

            when others =>
                NS           <= S_IDLE;
                MREADY       <= '0';
                MDONE        <= '0';
                SS_REG       <= '1';
                MOSI         <= '1';
                SCK_EN       <= '0';
                DATA_COUNTER <= 0;
                MISO_REG     <= (others => '0');
                MOSI_REG     <= (others => '0');

        end case;
    end process;

    -- Output assignments
    SCK  <= SCK_REG;
    SS   <= SS_REG;
    MOUT <= (MOUT_REG) when (RESET = '0') else
            (others => '0');

end architecture;