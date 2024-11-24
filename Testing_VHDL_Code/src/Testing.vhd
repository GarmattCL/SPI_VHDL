library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Master is
    Port (
        reset       : in  STD_LOGIC; 
        SCLK        : out STD_LOGIC;    -- SCLK Output
        MOSI        : out STD_LOGIC;    -- MOSI Output
        MISO        : in  STD_LOGIC;    -- MISO Input
        CS          : out STD_LOGIC;    -- Chip Select Output
        launch_pin  : in  STD_LOGIC;    -- Start Signal
        STATUS_LED  : out STD_LOGIC     -- Statusanzeige
    );
end SPI_Master;

architecture Behavioral of SPI_Master is

    -- Oszillator-Komponente
    component Gowin_OSC is
        port (
            oscout: out STD_LOGIC
        );
    end component;

    -- Parameter
    constant CLOCK_FREQ    : integer := 27000000; -- 27 MHz
    constant sclk_sig_FREQ : integer := 100000;   -- Ziel-Frequenz für SCLK (z.B. 100 kHz)
    constant MAX_COUNT     : unsigned(23 downto 0) := to_unsigned(CLOCK_FREQ / (2 * sclk_sig_FREQ), 24);
    constant CMD_LENGTH    : integer := 8;       -- Länge des Kommandos (8 Bit)
    constant ADDR_LENGTH   : integer := 16;      -- Länge der Adresse (16 Bit)
    constant DATA_LENGTH   : integer := 32;      -- Maximale Datenlänge (32 Bit)

    -- Signale
    signal osc_clk     : STD_LOGIC; -- Interner Oszillator-Takt
    signal counter     : unsigned(23 downto 0) := (others => '0'); -- Clock Divider
    signal sclk_sig    : STD_LOGIC := '1'; -- Geteilter Takt (CPOL = 1)
    signal prev_sclk_sig : STD_LOGIC := '1'; -- Vorheriger SCLK-Wert für Flankenerkennung

    -- SPI-Signale
    signal bit_cnt     : integer range 0 to CMD_LENGTH + ADDR_LENGTH + DATA_LENGTH := 0;
    signal command     : STD_LOGIC_VECTOR(CMD_LENGTH-1 downto 0) := (others => '0');
    signal address     : STD_LOGIC_VECTOR(ADDR_LENGTH-1 downto 0) := (others => '0');
    signal data_out    : STD_LOGIC_VECTOR(DATA_LENGTH-1 downto 0) := (others => '0');
    signal data_in     : STD_LOGIC_VECTOR(DATA_LENGTH-1 downto 0) := (others => '0');
    signal cs_sig      : STD_LOGIC := '1'; -- Standard auf HIGH
    signal mosi_sig    : STD_LOGIC := '0';

    -- SPI State Machine
    type state_type is (IDLE, SETUP, SEND_COMMAND, SEND_ADDRESS, TRANSFER_DATA, STOP);
    signal state : state_type := IDLE;

begin

    -- Instanzierung des Oszillators
    oscillator: Gowin_OSC
        port map (
            oscout => osc_clk -- Verbindung zum internen Takt
        );

    -- Taktteiler für SCLK
    process(osc_clk, reset)
    begin
        if reset = '0' then
            counter <= (others => '0');
            sclk_sig <= '1'; -- CPOL = 1
        elsif rising_edge(osc_clk) then
            if counter >= MAX_COUNT then
                counter <= (others => '0');
                sclk_sig <= not sclk_sig; -- SCLK toggelt
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    -- SPI-Prozess gesteuert durch SCLK
    process(sclk_sig, reset)
    begin
        if reset = '0' then
            state <= IDLE;
            cs_sig <= '1'; -- CS deaktivieren
            mosi_sig <= '0';
            bit_cnt <= 0;
        elsif falling_edge(sclk_sig) then -- Auf FALLENDE Flanke reagieren
            case state is
                when IDLE =>
                    if launch_pin = '0' then
                        command <= "00000011"; -- Schreib-/Lesebefehl
                        address <= "0000000001100100"; -- Beispieladresse
                        data_out <= "00000000000000000000000000000000"; -- Beispiel-Daten
                        bit_cnt <= 0;
                        state <= SETUP;
                    end if;

                when SETUP =>
                    cs_sig <= '0'; -- CS aktivieren
                    state <= SEND_COMMAND;

                when SEND_COMMAND =>
                    if bit_cnt < CMD_LENGTH then
                        mosi_sig <= command(CMD_LENGTH-1-bit_cnt);
                        bit_cnt <= bit_cnt + 1;
                    else
                        bit_cnt <= 0;
                        state <= SEND_ADDRESS;
                    end if;

                when SEND_ADDRESS =>
                    if bit_cnt < ADDR_LENGTH then
                        mosi_sig <= address(ADDR_LENGTH-2-bit_cnt);
                        bit_cnt <= bit_cnt + 1;
                    else
                        bit_cnt <= 0;
                        state <= TRANSFER_DATA;
                    end if;

                when TRANSFER_DATA =>
                    if bit_cnt < DATA_LENGTH - 3 then
                        mosi_sig <= data_out(DATA_LENGTH-0-bit_cnt);
                        data_in(DATA_LENGTH-0-bit_cnt) <= MISO;
                        bit_cnt <= bit_cnt + 1;
                    else
                        state <= STOP;
                    end if;

                when STOP =>
                    cs_sig <= '1'; -- CS deaktivieren
                    state <= IDLE;
                    

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    -- SPI-Ausgabe-Signale setzen
    SCLK <= '1' when cs_sig = '1' else not sclk_sig;
    MOSI <= mosi_sig;
    CS <= cs_sig;

end Behavioral;