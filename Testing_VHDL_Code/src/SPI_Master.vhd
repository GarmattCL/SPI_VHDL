library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Master is
    Port (
        clk         : in  STD_LOGIC;
        SCLK        : out STD_LOGIC;    -- SCLK Output
        MOSI        : out STD_LOGIC;    -- MOSI Output
        MISO        : in  STD_LOGIC;    -- MISO Input
        CS          : out STD_LOGIC;    -- Chip Select Output
        launch_pin  : in  STD_LOGIC;    -- Start Signal
        spi_ready   : out STD_LOGIC;    -- 1 wenn SPI nicht in verwendung
        command     : in  STD_LOGIC_VECTOR(7 downto 0); -- SPI Command
        address     : in  STD_LOGIC_VECTOR(15 downto 0); -- SPI Address
        data_out    : in  STD_LOGIC_VECTOR(31 downto 0); -- SPI Data
        STATUS_LED  : out STD_LOGIC;     -- Statusanzeige
        data_length : in integer;
        TEST_OUT    : out STD_LOGIC
    );
end SPI_Master;

architecture Behavioral of SPI_Master is
    -- Konstanten
    constant CMD_LENGTH    : integer := 8;  -- Befehlslänge
    constant ADDR_LENGTH   : integer := 16; -- Adresslänge
    constant CLOCK_FREQ    : integer := 27000000; -- 27 MHz
    constant sclk_sig_FREQ : integer := 100000;   -- Ziel-Frequenz für SCLK (z.B. 100 kHz)
    constant MAX_COUNT      : unsigned(23 downto 0) := to_unsigned(CLOCK_FREQ / (2 * sclk_sig_FREQ), 24);

    signal counter     : unsigned(23 downto 0) := (others => '0');
    signal sclk_sig    : STD_LOGIC := '1'; -- Geteilter Takt
    signal cs_sig      : STD_LOGIC := '1'; -- CS auf HIGH
    signal mosi_sig    : STD_LOGIC := '0';
    signal bit_cnt     : integer range 0 to 63 := 0;
    signal spi_ready_sig    : STD_LOGIC := '1';
    signal stop_counter : integer := 0;
    signal data_in      : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal test_sig     : STD_LOGIC := '0';

    type state_type is (IDLE, SETUP, SEND_COMMAND, SEND_ADDRESS, TRANSFER_DATA, STOP);
    signal state : state_type := IDLE;

begin
    -- SPI-Taktsteuerung
    process(clk, launch_pin)
    begin
        if launch_pin = '0' then
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
    process(sclk_sig, launch_pin)
    begin
        if falling_edge(sclk_sig) then
            case state is
---------------------------------------------------------------------
                when IDLE =>
                    
                    if launch_pin = '1' then
                        spi_ready_sig <= '0';
                        bit_cnt <= 0;
                        state <= SETUP;
                    else
                        spi_ready_sig <= '1';
                    end if;
---------------------------------------------------------------------
                when SETUP =>
                    spi_ready_sig <= '0';
                    cs_sig <= '0';
                    state <= SEND_COMMAND;
---------------------------------------------------------------------
                when SEND_COMMAND =>
                    spi_ready_sig <= '0';
                    if bit_cnt < CMD_LENGTH-1 then
                        mosi_sig <= command(CMD_LENGTH-1-bit_cnt);
                        bit_cnt <= bit_cnt + 1;
                    else
                        mosi_sig <= command(CMD_LENGTH-1-bit_cnt);
                        bit_cnt <= 0;
                        state <= SEND_ADDRESS;
                    end if;
---------------------------------------------------------------------
                when SEND_ADDRESS =>
                    spi_ready_sig <= '0';
                    if bit_cnt < ADDR_LENGTH-1 then
                        mosi_sig <= address(ADDR_LENGTH-1-bit_cnt);
                        bit_cnt <= bit_cnt + 1;
                    else
                        mosi_sig <= address(ADDR_LENGTH-1-bit_cnt);
                        bit_cnt <= 0;
                        state <= TRANSFER_DATA;
                    end if;
---------------------------------------------------------------------
                when TRANSFER_DATA =>
                    spi_ready_sig <= '0';
                    if bit_cnt < data_length-1 then
                        mosi_sig <= data_out(data_length-1 - bit_cnt);
                        data_in(data_length-bit_cnt) <= MISO;
                        bit_cnt <= bit_cnt + 1;
                    else
                        mosi_sig <= data_out(data_length-1 - bit_cnt);
                        data_in(data_length-bit_cnt) <= MISO;
                        state <= STOP;
                    end if;
---------------------------------------------------------------------
                when STOP =>
                    cs_sig <= '1';
                    
                    if stop_counter < data_length then
                        test_sig <= data_in(data_length-stop_counter);
                    end if;

                    if stop_counter > 100 then
                        spi_ready_sig <= '1';
                        state <= IDLE;
                        stop_counter <= 0;
                    else
                        stop_counter <= stop_counter + 1;
                    end if;
---------------------------------------------------------------------
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    -- SPI-Signale setzen
    SCLK        <= not sclk_sig when cs_sig = '0' else '1';
    MOSI        <= mosi_sig;
    CS          <= cs_sig; 
    STATUS_LED  <= not spi_ready_sig; -- LED an, wenn SPI ready
    spi_ready   <= spi_ready_sig;
    TEST_OUT    <= test_sig;
end Behavioral;
