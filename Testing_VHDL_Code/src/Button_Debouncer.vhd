library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Button_Debouncer is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        button_in   : in  STD_LOGIC;
        button_out  : out STD_LOGIC
    );
end Button_Debouncer;

architecture Behavioral of Button_Debouncer is
    signal counter       : unsigned(19 downto 0) := (others => '0'); -- 20-Bit Counter
    signal button_stable : STD_LOGIC := '0';
    signal button_last   : STD_LOGIC := '0';
begin

    process(clk, reset)
    begin
        if reset = '0' then
            counter <= (others => '0');
            button_stable <= '0';
            button_last <= '0';
        elsif rising_edge(clk) then
            if button_in /= button_last then
                counter <= (others => '0'); -- Reset Counter, wenn sich der Button ändert
            else
                if counter = "11111111111111111111" then -- Warten, bis stabil
                    button_stable <= button_in;
                else
                    counter <= counter + 1;
                end if;
            end if;
            button_last <= button_in;
        end if;
    end process;

    button_out <= button_stable;

end Behavioral;
