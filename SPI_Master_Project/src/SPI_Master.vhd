library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Master is
    Port (
        clk         : in  STD_LOGIC;                       -- System Clock
        reset       : in  STD_LOGIC;                       -- System Reset
        launch_pin  : in  STD_LOGIC;                       -- Start Signal

        mosi        : out STD_LOGIC;                       -- Master Out Slave In
        miso        : in  STD_LOGIC;                       -- Master In Slave Out
        sclk        : out STD_LOGIC;                       -- Serial Clock
        cs          : out STD_LOGIC;                       -- Chip Select
        done        : out STD_LOGIC                        -- Übertragung abgeschlossen
    );
end SPI_Master;

architecture Behavioral of SPI_Master is
    type state_type is (IDLE, LAUNCH, TRANSFER, STOP);
    signal state      : state_type := IDLE;
    signal bit_cnt    : integer range 0 to 7 := 0;
    signal shift_reg  : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal clk_div    : integer := 0;
    constant CLK_DIV_MAX : integer := 50; -- Anpassen je nach Systemclock

    signal sclk_int     : STD_LOGIC := '0';               -- Internes Signal für SCLK
    signal data_in_int  : STD_LOGIC_VECTOR(7 downto 0) := "10101010"; -- Internes Daten-Sende-Signal
    signal data_out_int : STD_LOGIC_VECTOR(7 downto 0) := (others => '0'); -- Internes Daten-Empfangs-Signal
begin

    -- Zuweisung des internen sclk_int an den Ausgang sclk
    sclk <= sclk_int;

    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset-Zustände
            state       <= IDLE;
            sclk_int    <= '0';
            cs          <= '1';
            mosi        <= '0';
            bit_cnt     <= 0;
            shift_reg   <= (others => '0');
            done        <= '0';
            data_out_int<= (others => '0');
            clk_div     <= 0;
        elsif rising_edge(clk) then
            -- Clock Divider für SCLK
            if clk_div < CLK_DIV_MAX then
                clk_div <= clk_div + 1;
            else
                clk_div <= 0;
                sclk_int <= not sclk_int;
            end if;

            -- Zustandsmaschine
            case state is
                when IDLE =>
                    done <= '0';
                    if launch_pin = '1' then  -- Korrektur: launch_pin statt LAUNCH
                        cs <= '0'; -- Slave auswählen
                        shift_reg <= data_in_int; -- Laden der zu sendenden Daten
                        bit_cnt <= 0;
                        state <= LAUNCH;
                    end if;

                when LAUNCH =>
                    mosi <= shift_reg(7); -- Senden des MSB
                    state <= TRANSFER;

                when TRANSFER =>
                    -- Aktionen basierend auf der SCLK-Phase
                    if sclk_int = '1' then -- Aktionen bei steigender SCLK-Phase
                        if bit_cnt < 7 then
                            shift_reg <= shift_reg(6 downto 0) & miso; -- Daten empfangen
                            mosi <= shift_reg(6); -- Nächstes Bit senden
                            bit_cnt <= bit_cnt + 1;
                        else
                            shift_reg <= shift_reg(6 downto 0) & miso; -- Letztes Bit empfangen
                            data_out_int <= shift_reg; -- Empfangene Daten speichern
                            state <= STOP;
                        end if;
                    end if;

                when STOP =>
                    cs <= '1'; -- Slave freigeben
                    done <= '1';
                    state <= IDLE;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;
