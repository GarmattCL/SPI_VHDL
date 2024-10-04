library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity LED_Blink is
    Port (
        clk     : in  STD_LOGIC;   -- System Clock (27 MHz)
        reset   : in  STD_LOGIC;   -- Reset Signal
        LED     : out STD_LOGIC    -- LED Output
    );
end LED_Blink;

architecture Behavioral of LED_Blink is

    -- Signal für die interne Zählung (Clock Divider)
    signal counter : unsigned(23 downto 0) := (others => '0'); -- 24 Bit für bis zu ~167 Millionen
    signal clk_div : STD_LOGIC := '1';  -- Geteilter Takt

    -- Parameter für den Clock Divider (z.B. blinkt LED bei 1 Hz, wenn sys_clk = 27 MHz)
    constant CLOCK_FREQ    : integer := 27000000;  -- 27 MHz
    constant BLINK_FREQ    : integer := 1;        -- LED blinkt bei 10 Hz
    constant MAX_COUNT     : unsigned(23 downto 0) := to_unsigned(CLOCK_FREQ / (2 * BLINK_FREQ), 24); -- 13,500,000

begin

    -- Taktteiler-Prozess (Erzeugt einen langsamen Takt)
    process(clk, reset)
    begin
        if reset = '0' then
            counter <= (others => '0');
            clk_div <= '1';
        elsif rising_edge(clk) then
            if counter >= MAX_COUNT then
                counter <= (others => '0');
                clk_div <= not clk_div; -- Toggle den geteilten Takt
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- LED blinkt basierend auf clk_div
    LED <= clk_div;

end Behavioral;
