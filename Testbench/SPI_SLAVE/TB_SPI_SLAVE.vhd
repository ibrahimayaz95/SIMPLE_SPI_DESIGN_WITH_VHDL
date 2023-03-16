-- Library declaration
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity TB_SPI_SLAVE is
    generic (
        CLK_FREQ    :   integer := 100_000_000;
        BAUDRATE    :   integer := 115_200;
        DATA_LIMIT  :   integer := 8  
    );
end entity TB_SPI_SLAVE;

architecture rtl of TB_SPI_SLAVE is

    component SPI_SLAVE is
        generic (
            CLK_FREQ    :   integer := 100_000_000;
            BAUDRATE    :   integer := 115_200;
            DATA_LIMIT  :   integer := 8  
        );
        port (
            -- Input ports
            CLK     :   in  std_logic;
            RESET   :   in  std_logic;
            MOSI    :   in  std_logic;
            SS      :   in std_logic;
            SCK     :   in std_logic;
            SLIN    :   in  std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0);
            -- Output Ports
            MISO    :   out std_logic;
            SLOUT   :   out std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0);
            SLREADY :   out std_logic;
            SLDONE  :   out std_logic
        );
    end component;

    component SPI_MASTER is
        generic (
            CLK_FREQ    :   integer := 100_000_000;
            BAUDRATE    :   integer := 115_200;
            DATA_LIMIT  :   integer := 8  
        );
        port (
            -- Input ports
            CLK     :   in  std_logic;
            RESET   :   in  std_logic;
            MEN     :   in  std_logic;
            MISO    :   in  std_logic;
            MIN     :   in  std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0);
            -- Output Ports
            SCK     :   out std_logic;
            SS      :   out std_logic;
            MOSI    :   out std_logic;
            MOUT    :   out std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0);
            MREADY  :   out std_logic;
            MDONE   :   out std_logic
        );
    end component;

    -- Slave signals with both versions
    signal CLK         :   std_logic    := '0';
    signal RESET       :   std_logic    := '0';
    signal MOSI        :   std_logic    := '0';
    signal SS          :   std_logic    := '0';
    signal SCK         :   std_logic    := '0';
    signal SLIN        :   std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0)   := (others => '0');
    signal MISO        :   std_logic    := '0';
    signal SLOUT       :   std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0)   := (others => '0');
    signal SLREADY     :   std_logic    := '0';
    signal SLDONE      :   std_logic    := '0';

    -- Master signals
    signal  MEN     :    std_logic  := '0';
    signal  MIN     :    std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0) := (others => '0');
    signal  MOUT    :    std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0) := (others => '0');
    signal  MREADY  :    std_logic  := '0';
    signal  MDONE   :    std_logic  := '0';

    signal clock_period   :   time       := 10 ns;

begin

    -- Component instantiation
    INST_SPI_SLAVE: SPI_SLAVE
        generic map(
            CLK_FREQ    =>   CLK_FREQ  ,
            BAUDRATE    =>   BAUDRATE  ,
            DATA_LIMIT  =>   DATA_LIMIT 
        )
        port map(
            CLK     =>   CLK        ,
            RESET   =>   RESET      ,
            MOSI    =>   MOSI       ,
            SS      =>   SS         ,
            SCK     =>   SCK        ,
            SLIN    =>   SLIN       ,
            MISO    =>   MISO       ,
            SLOUT   =>   SLOUT      ,
            SLREADY =>   SLREADY    ,
            SLDONE  =>   SLDONE
    );

    INST_SPI_MASTER: SPI_MASTER
        generic map(
            CLK_FREQ    =>   CLK_FREQ  ,
            BAUDRATE    =>   BAUDRATE  ,
            DATA_LIMIT  =>   DATA_LIMIT
        )
        port map(
            CLK     =>   CLK   ,
            RESET   =>   RESET ,
            MEN     =>   MEN   ,
            MISO    =>   MISO  ,
            MIN     =>   MIN   ,
            SCK     =>   SCK   ,
            SS      =>   SS    ,
            MOSI    =>   MOSI  ,
            MOUT    =>   MOUT  ,
            MREADY  =>   MREADY,
            MDONE   =>   MDONE 
        );
    
    -- Clock generation 
    CLK_GEN:    process
    begin
        CLK <= '0';
        wait for (clock_period / 2);
        CLK <= '1';
        wait for (clock_period / 2);
    end process;

    -- Stimuli generation
    STIMULI:    process
        variable pass_count : integer := 0;
        variable fail_count : integer := 0;
        variable test_count : integer := 0;
    begin
        -- Start of the simulation
        wait for (clock_period * 25);

        -- First stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1111001100";
        SLIN     <= "1111001100";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if(MOUT = SLOUT) then
            assert true
                report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Second stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1010111100";
        SLIN     <= "1010111100";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if(MOUT = SLOUT) then
            assert true
                report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Third stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1011010010";
        SLIN     <= "1011010010";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if(MOUT = SLOUT) then
            assert true
                report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Fourth stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1111001110";
        SLIN     <= "1111001110";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if(MOUT = SLOUT) then
            assert true
                report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- RESET stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1111001110";
        SLIN     <= "1111001110";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 4 us);
        MEN   <= '0';
        RESET <= '1';
        wait for (clock_period);
        -- Comparison
        report "RESET CONDITION";
        report "---------------";
        if (MREADY = '0' and MDONE = '0' and SS = '1' and MOSI = '1' and SLREADY = '0' and SLDONE = '0' and MISO = '0') then
            report "[RESET PASSED]";
            pass_count := pass_count + 1;
        else
            report "[RESET FAILED]";
            fail_count := fail_count + 1;
        end if;
        report "MREADY = " & std_logic'image(MREADY);
        report "MDONE = " & std_logic'image(MDONE);
        report "SS = " & std_logic'image(SS);
        report "MOSI = " & std_logic'image(MOSI);
        report "SLREADY = " & std_logic'image(SLREADY);
        report "SLDONE = " & std_logic'image(SLDONE);
        report "MISO = " & std_logic'image(MISO);
        wait for (8.63 us);
        RESET <= '0';
        test_count := test_count + 1;

        -- Fifth stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1000001101";
        SLIN     <= "1000001101";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if(MOUT = SLOUT) then
            assert true
                report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Sixth stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1010001101";
        SLIN     <= "1010001101";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if(MOUT = SLOUT) then
            assert true
                report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Seventh stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1011101011";
        SLIN     <= "1011101011";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if(MOUT = SLOUT) then
            assert true
                report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Eighth stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1110001111";
        SLIN     <= "1110001111";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if(MOUT = SLOUT) then
            assert true
                report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            report "[PASS] MOUT = SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLOUT = " & to_bstring(SLOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Ninth stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1011010100";
        SLIN     <= "0110110100";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if((MOUT = SLIN) and (SLOUT = MIN)) then
            assert true
                report "[PASS] MOUT = SLIN!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN) & " AND SLOUT = MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN)
                severity WARNING;
            report "[PASS]";
            report "MOUT = SLIN!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN);
            report "SLOUT = MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN) & " AND SLOUT /= MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Tenth stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "0100111010";
        SLIN     <= "1101110010";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if((MOUT = SLIN) and (SLOUT = MIN)) then
            assert true
                report "[PASS] MOUT = SLIN!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN) & " AND SLOUT = MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN)
                severity WARNING;
            report "[PASS]";
            report "MOUT = SLIN!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN);
            report "SLOUT = MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN) & " AND SLOUT /= MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Eleventh stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1000100101";
        SLIN     <= "0001101101";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if((MOUT = SLIN) and (SLOUT = MIN)) then
            assert true
                report "[PASS] MOUT = SLIN!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN) & " AND SLOUT = MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN)
                severity WARNING;
            report "[PASS]";
            report "MOUT = SLIN!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN);
            report "SLOUT = MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN) & " AND SLOUT /= MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        -- Twelfth stimuli
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        MIN      <= "1110010011";
        SLIN     <= "1011000011";
        wait for (clock_period);
        MEN <= '1';
        wait for (8.63 * 8 us);
        MEN <= '0';

        -- Comparison
        if(SLREADY /= '1' and MREADY /= '1') then
            wait until (SLREADY = '1' and MREADY = '1');
        end if;
        if((MOUT = SLIN) and (SLOUT = MIN)) then
            assert true
                report "[PASS] MOUT = SLIN!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN) & " AND SLOUT = MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN)
                severity WARNING;
            report "[PASS]";
            report "MOUT = SLIN!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN);
            report "SLOUT = MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MOUT /= SLOUT!  MOUT = " & to_bstring(MOUT) & " and SLIN = " & to_bstring(SLIN) & " AND SLOUT /= MIN!  MOUT = " & to_bstring(SLOUT) & " and MIN = " & to_bstring(MIN)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;
        test_count := test_count + 1;

        wait for (clock_period * 25);

        report "SIMULATION RESULTS";
        report "---------------------------------------------------";
        if (pass_count = test_count) then
            report "TESTS ARE PASSED!";
            report "TEST count = " & integer'image(test_count);
            report "PASS count = " & integer'image(pass_count);
        else
            report "TESTS ARE FAILED!";
            report "TEST count = " & integer'image(test_count);
            report "FAIL count = " & integer'image(fail_count);
        end if;
        report "---------------------------------------------------";

        assert false
            report "Simulation done"
            severity failure;

    end process;

end architecture;