library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SPI_Master is
    Port (
        clk     : in  STD_LOGIC;   -- System Clock (27 MHz)
        reset   : in STD_LOGIC; 
        SCLK     : out STD_LOGIC;    -- SCLK Output
        MOSI    : out STD_LOGIC;
        MISO    : in STD_LOGIC;
        CS         : out STD_LOGIC;
        launch_pin  : in STD_LOGIC;
        STATUS_LED    : out STD_LOGIC
    );
end SPI_Master;

architecture Behavioral of SPI_Master is

    -- Signal für die interne Zählung (Clock Divider)
    signal counter : unsigned(23 downto 0) := (others => '0'); -- 24 Bit für bis zu ~167 Millionen
    signal sclk_sig : STD_LOGIC := '1';  -- Geteilter Takt
    signal prev_sclk_sig : STD_LOGIC := '1';  -- Vorheriger Wert von sclk_sig

    -- Parameter für den Clock Divider (z.B. blinkt SCLK bei 1 Hz, wenn sys_clk = 27 MHz)
    constant CLOCK_FREQ    : integer := 27000000;  -- 27 MHz
    constant sclk_sig_FREQ    : integer := 100;        -- SCLK blinkt bei 100 Hz
    constant MAX_COUNT     : unsigned(23 downto 0) := to_unsigned(CLOCK_FREQ / (2 * sclk_sig_FREQ), 24); -- 13,500,000

    -- States
    type state_type is (IDLE, LAUNCH, TRANSFER, STOP);
    signal state    : state_type := IDLE;

    -- SPI Stuff
    signal bit_cnt         : integer range 0 to 7 := 0;
    signal shift_reg    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal data_mosi    : STD_LOGIC_VECTOR(7 downto 0) := "00000101";
    signal data_miso    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal cs_sig       : STD_LOGIC := '1';
    signal mosi_sig     : STD_LOGIC := '0';

begin
  

  -- Taktteiler-Prozess (Erzeugt einen langsamen Takt)
    process(clk, reset)

    begin        
        if reset = '0' then
            counter     <= (others => '0');
            sclk_sig    <= '1';
            --- state          <= TRANSFER;
            CS               <= '1';
            MOSI        <= '0';
            prev_sclk_sig <= '1'; -- Initialisieren
            bit_cnt     <= 0;
            shift_reg   <= (others => '0');
            --data_mosi   <= (others => '0');
        
        elsif rising_edge(clk) then
            if counter >= MAX_COUNT then
                counter     <= (others => '0');
                sclk_sig    <= not sclk_sig; -- Toggle den geteilten Takt
            
            else
                counter <= counter + 1;
            end if;

-- Flankenerkennung
            if (prev_sclk_sig = '0' and sclk_sig = '1') then -- Steigende Flanke von sclk_sig erkannt

-- SPI State Machine
            case state is
                -------------------------------------------
                when IDLE =>
                    STATUS_LED    <= '1'; --off
                    if launch_pin  = '0' then
                        cs_sig    <= '1'; -- Slave deaktivieren
                        --shift_reg       <= data_mosi;
                        bit_cnt         <= 0;
                        state           <= LAUNCH;
                    end if;
                --SLCK geht nicht
                
                --------------------------------------------
                when LAUNCH =>
                    
                    STATUS_LED    <= '1'; --off
                    cs_sig      <= '0';
                    mosi_sig    <= data_mosi(7); --Sende MSB
                    bit_cnt <= 0;
                    data_miso <= (others => '0');
                    data_miso(0) <= MISO;
                    state   <= TRANSFER;
                --SCLK geht nicht
                --------------------------------------------
                when TRANSFER =>
                    STATUS_LED    <= '0'; --on
                    cs_sig        <= '0';
                    if bit_cnt < 7 then
                        mosi_sig    <= data_mosi(6-bit_cnt);
                        --shift_reg   <= shift_reg(6 downto 0) & miso; -- letztes bit empfangen
                        --data_miso   <= shift_reg(6-bit_cnt); -- empfangene daten Speichern
                        data_miso(7-bit_cnt) <= MISO;

                        bit_cnt <= bit_cnt+1;
                        if bit_cnt > 6 then
                            cs_sig  <= '1';
                        end if;
                    else
                        data_miso(0) <= MISO;
                        cs_sig  <= '1';
                        state   <= STOP;
                    end if;
                
                ---------------------------------------------
                when STOP =>
                    STATUS_LED    <= '1'; --off
                    data_mosi <= data_miso;
                    cs_sig  <= '1'; -- Slave deaktivieren
                    state <= IDLE;
                
                ---------------------------------------------
                when others =>
                    STATUS_LED    <= '1'; --off
                    state <= IDLE;
                end case;
            end if;

            -- Speichern des vorherigen Zustands von sclk_sig
            prev_sclk_sig <= sclk_sig;

            -- SCLK blinkt basierend auf sclk_sig
            SCLK    <= sclk_sig;
            CS      <= cs_sig;
            MOSI    <= mosi_sig;
        end if;
    end process;
end Behavioral;
