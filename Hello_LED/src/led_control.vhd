library ieee;
use ieee.std_logic_1164.all;

entity led_control is
    port (
        clk : in std_logic;  -- Eingangs-Takt
        led : out std_logic  -- Ausgangssignal zur LED
    );
end led_control;

architecture behavior of led_control is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            led <= '1';  -- Schalte die LED ein
        end if;
    end process;
end behavior;
