-- Library decleration
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity TB_SPI_MASTER is
    generic (
        CLK_FREQ    :   integer := 100_000_000;
        BAUDRATE    :   integer := 115_200;
        DATA_LIMIT  :   integer := 8  
    );
end entity TB_SPI_MASTER;

architecture rtl of TB_SPI_MASTER is

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

    signal  CLK     :    std_logic  := '0';
    signal  RESET   :    std_logic  := '0';
    signal  MEN     :    std_logic  := '0';
    signal  MISO    :    std_logic  := '0';
    signal  MIN     :    std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0) := (others => '0');
    signal  SCK     :    std_logic  := '0';
    signal  SS      :    std_logic  := '0';
    signal  MOSI    :    std_logic  := '0';
    signal  MOUT    :    std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0) := (others => '0');
    signal  MREADY  :    std_logic  := '0';
    signal  MDONE   :    std_logic  := '0';

    signal clock_period  :   time    := 10 ns;

begin

    -- Component instantiation
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
    STIMULI_GEN:    process
        variable odd_even   : integer := 0;
        variable temp       : std_logic_vector (1 downto 0) := "00";
        variable pass_count : integer := 0;
        variable fail_count : integer := 0;
    begin
        -- Start of the simulation
        wait for (clock_period * 25);
        -- First stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "1010101000";
        wait for (clock_period);
        MEN <= '1';
        for i in 7 downto 0 loop
            odd_even := (i mod 2);
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';

        -- Comparison
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        if(MIN = MOUT) then
            assert true
                report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MIN /= MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;

        -- Second stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "0101010100";
        wait for (clock_period);
        MEN <= '1';        
        for i in 7 downto 0 loop
            odd_even := (i mod 2);
            if (odd_even = 1) then
                odd_even := 0;
            else
                odd_even := 1;
            end if;
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';

        -- Comparison
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        if(MIN = MOUT) then
            assert true
                report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MIN /= MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;

        wait for (clock_period * 10);

        -- Third stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "1010101010";
        wait for (clock_period);
        MEN <= '1';
        for i in 7 downto 0 loop
            odd_even := (i mod 2);
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';

        -- Comparison
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        if(MIN = MOUT) then
            assert true
                report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MIN /= MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;

        -- Fourth stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "0101010110";
        wait for (clock_period);
        MEN <= '1';
        for i in 7 downto 0 loop
            odd_even := (i mod 2);
            if (odd_even = 1) then
                odd_even := 0;
            else
                odd_even := 1;
            end if;
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';

        -- Comparison
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        if(MIN = MOUT) then
            assert true
                report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MIN /= MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;

        -- Fifth stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "1010101001";
        wait for (clock_period);
        MEN <= '1';
        wait for (4.315 us);
        for i in 7 downto 0 loop
            odd_even := (i mod 2);
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';

        -- Comparison
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        if(MIN = MOUT) then
            assert true
                report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MIN /= MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;

        -- Sixth stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "0101010101";
        wait for (clock_period);
        MEN <= '1';
        wait for (4.315 us);
        for i in 7 downto 0 loop
            odd_even := (i mod 2);
            if (odd_even = 1) then
                odd_even := 0;
            else
                odd_even := 1;
            end if;
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';

        -- Comparison
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        if(MIN = MOUT) then
            assert true
                report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MIN /= MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;

        -- Seventh stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "1010101011";
        wait for (clock_period);
        MEN <= '1';
        wait for (4.315 us);
        for i in 7 downto 0 loop
            odd_even := (i mod 2);
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';

        -- Comparison
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        if(MIN = MOUT) then
            assert true
                report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MIN /= MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;

        -- Eighteeth stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "0101010111";
        wait for (clock_period);
        MEN <= '1';
        wait for (4.315 us);
        for i in 7 downto 0 loop
            odd_even := (i mod 2);
            if (odd_even = 1) then
                odd_even := 0;
            else
                odd_even := 1;
            end if;
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';

        -- Comparison
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        if(MIN = MOUT) then
            assert true
                report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MIN /= MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;

        -- RESET stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "0101010100";
        wait for (clock_period);
        MEN <= '1';
        for i in 5 downto 0 loop
            odd_even := (i mod 2);
            if (odd_even = 1) then
                odd_even := 0;
            else
                odd_even := 1;
            end if;
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';
        RESET <= '1';
        wait for (clock_period);
        report "RESET CONDITION";
        report "---------------";
        if (MREADY = '0' and MDONE = '0' and SS = '1' and MOSI = '1') then
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
        wait for (8.63 us);
        RESET <= '0';

        -- Ninth stimuli
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        MIN <= "0101010100";
        wait for (clock_period);
        MEN <= '1';
        for i in 7 downto 0 loop
            odd_even := (i mod 2);
            if (odd_even = 1) then
                odd_even := 0;
            else
                odd_even := 1;
            end if;
            temp     := std_logic_vector(to_unsigned(odd_even, temp'length));
            MISO <= temp (0);
            wait for (8.63 us);
        end loop;
        MEN <= '0';

        -- Comparison
        if(MREADY /= '1') then
            wait until (MREADY = '1');
        end if;
        if(MIN = MOUT) then
            assert true
                report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            report "[PASS] MIN = MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT);
            pass_count := pass_count + 1;
        else
            assert false
                report "[FAIL] MIN /= MOUT!  MIN = " & to_bstring(MIN) & " and MOUT = " & to_bstring(MOUT)
                severity WARNING;
            fail_count := fail_count + 1;
        end if;

        wait for (clock_period * 25);

        report "SIMULATION RESULTS";
        report "---------------------------------------------------";
        report "PASS count = " & integer'image(pass_count);
        report "FAIL count = " & integer'image(fail_count);
        report "---------------------------------------------------";

        assert false
            report "Simulation done"
            severity failure; 
        
    end process;
    

end architecture;