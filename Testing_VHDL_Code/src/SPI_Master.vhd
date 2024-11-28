library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Master is
    Port (
        reset       : in  STD_LOGIC;
        clk         : in  STD_LOGIC;
        SCLK        : out STD_LOGIC;    -- SCLK Output
        MOSI        : out STD_LOGIC;    -- MOSI Output
        MISO        : in  STD_LOGIC;    -- MISO Input
        CS          : out STD_LOGIC;    -- Chip Select Output
        launch_pin  : in  STD_LOGIC;    -- Start Signal
        command     : in  STD_LOGIC_VECTOR(7 downto 0); -- SPI Command
        address     : in  STD_LOGIC_VECTOR(15 downto 0); -- SPI Address
        data_out    : in  STD_LOGIC_VECTOR(31 downto 0); -- SPI Data
        STATUS_LED  : out STD_LOGIC     -- Statusanzeige
    );
end SPI_Master;

architecture Behavioral of SPI_Master is
    -- Konstanten
    constant CMD_LENGTH    : integer := 8;  -- Befehlslänge
    constant ADDR_LENGTH   : integer := 16; -- Adresslänge
    constant DATA_LENGTH   : integer := 32; -- Datenlänge
    constant CLOCK_FREQ    : integer := 27000000; -- 27 MHz
    constant sclk_sig_FREQ : integer := 100000;   -- Ziel-Frequenz für SCLK (z.B. 100 kHz)
    constant MAX_COUNT      : unsigned(23 downto 0) := to_unsigned(CLOCK_FREQ / (2 * sclk_sig_FREQ), 24);

    signal counter     : unsigned(23 downto 0) := (others => '0');
    signal sclk_sig    : STD_LOGIC := '1'; -- Geteilter Takt
    signal cs_sig      : STD_LOGIC := '1'; -- CS auf HIGH
    signal mosi_sig    : STD_LOGIC := '0';
    signal bit_cnt     : integer range 0 to 63 := 0;

    type state_type is (IDLE, SETUP, SEND_COMMAND, SEND_ADDRESS, TRANSFER_DATA, STOP);
    signal state : state_type := IDLE;

begin
    -- SPI-Taktsteuerung
    process(clk, reset)
    begin
        if reset = '0' then
            counter <= (others => '0');
            sclk_sig <= '1';
        elsif rising_edge(clk) then
            if counter >= MAX_COUNT then -- Anpassen für SCLK-Frequenz
                counter <= (others => '0');
                sclk_sig <= not sclk_sig;
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
            cs_sig <= '1';
            mosi_sig <= '0';
            bit_cnt <= 0;
        elsif falling_edge(sclk_sig) then
            case state is
                when IDLE =>
                    if launch_pin = '1' then
                        bit_cnt <= 0;
                        state <= SETUP;
                    end if;

                when SETUP =>
                    cs_sig <= '0';
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
                    if bit_cnt < DATA_LENGTH then
                        mosi_sig <= data_out(DATA_LENGTH-1 - bit_cnt);
                        bit_cnt <= bit_cnt + 1;
                    else
                        state <= STOP;
                    end if;

                when STOP =>
                    cs_sig <= '1';
                    state <= IDLE;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    -- SPI-Signale setzen
    SCLK <= not sclk_sig when cs_sig = '0' else '1';
    MOSI <= mosi_sig;
    CS <= cs_sig;
    STATUS_LED <= not cs_sig; -- LED an, wenn CS aktiv
end Behavioral;
