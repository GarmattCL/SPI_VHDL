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

    -- Parameter für den Clock Divider
    constant CLOCK_FREQ    : integer := 27000000;  -- 27 MHz
    constant sclk_sig_FREQ    : integer := 100000;        -- SCLK blinkt bei 8MHz
    constant MAX_COUNT     : unsigned(23 downto 0) := to_unsigned(CLOCK_FREQ / (2 * sclk_sig_FREQ), 24); -- 13,500,000

    ---------------------------------------------

    -- SPI States
    type state_type is (IDLE, LAUNCH, TRANSFER, STOP);
    signal state    : state_type := IDLE;

    -- SPI Stuff
    constant bit_length   : integer := 40;
    signal bit_cnt         : integer range 0 to bit_length := 0;
    signal launch_cnt   : integer range 0 to 10:= 0;
    signal shift_reg    : STD_LOGIC_VECTOR(bit_length-1 downto 0) := (others => '0');
    signal data_mosi    : STD_LOGIC_VECTOR(bit_length-1 downto 0) := "0000001101000001001100000000000000000000";
    signal data_miso    : STD_LOGIC_VECTOR(bit_length-1 downto 0) := (others => '0');
    signal cs_sig       : STD_LOGIC := '1';
    signal mosi_sig     : STD_LOGIC := '0';

    ---------------------------------------------

    -- ESC States
    type esc_state_type is (INIT, PREOP, BOOT, SAFEOP, OP);
    signal esc_state    :   esc_state_type := INIT;

    -- ESC Stuff

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
                        launch_cnt <= 0;
                        state           <= LAUNCH;
                    end if;
                
                --------------------------------------------
                when LAUNCH =>

                    
                    STATUS_LED    <= '1';           --LED off
                    cs_sig      <= '0';             --Slave aktivieren
                    --mosi_sig    <= data_mosi(39);   --Sende MSB
                    data_miso <= (others => '0');   --Reset MISO
                    --data_miso(0) <= MISO;           --MISO MSB einlesen
                    
                    launch_cnt <= launch_cnt+1;
                    bit_cnt <= 0;                   --Bit Counter nullen
                    
                    if(launch_cnt = 2) then
                        state   <= TRANSFER;            --State Change
                    end if;
                
                --------------------------------------------
                when TRANSFER =>
                    
                    STATUS_LED    <= '0';           --on
                    cs_sig        <= '0';           --Slave aktiv
                    if bit_cnt < bit_length then
                        mosi_sig    <= data_mosi(bit_length-1-bit_cnt);   --MOSI Ausgabe
                        data_miso(bit_length-bit_cnt) <= MISO;          --MISO Einlesen
                        bit_cnt <= bit_cnt+1;                   --Bit Counter inkrementieren
                        if bit_cnt > bit_length-1 then
                            cs_sig  <= '0';                     --ggf. Slave deaktivieren
                        end if;
                    else
                        data_miso(0) <= MISO;                   --MISO LSB Einlesen
                        cs_sig  <= '1';                         --Slave deaktivieren
                        state   <= STOP;                        --State Change
                    end if;
                
                ---------------------------------------------
                when STOP =>
                    
                    STATUS_LED    <= '1';       --off
                    -- data_mosi <= data_miso;     --Testing: Daten im Kreis schicken
                    cs_sig  <= '1';             --Slave deaktivieren
                    state <= IDLE;              --State Change    
                
                ---------------------------------------------   
                when others =>
                    
                    STATUS_LED    <= '1';   --off
                    state <= IDLE;          --State Change
                end case;
            end if;

            
            
            -- Speichern des vorherigen Zustands von sclk_sig
            prev_sclk_sig <= sclk_sig;

            -- SPI Output Steuerung
            CS      <= cs_sig;
            MOSI    <= mosi_sig;
            
            

        end if;
        if (state = STOP) or (state = IDLE) or (state = LAUNCH) or (bit_cnt = 0) then
            SCLK    <= '1';
        else
            SCLK    <= not sclk_sig;
        end if;

-- ESC State Machine
        case esc_state is
            ---------------------------------------------
            when INIT =>
            -- INIT -> PREOP
                -- start mailbox
            -- INIT -> OP (ALARM)
                -- invalid state change
                -- escstate = INIT;
            ---------------------------------------------
            when PREOP =>
            -- PREOP -> INIT
                -- stop mailbox
                -- escstate = INIT;
            -- PREOP -> OP
                -- invalid state change
                --escstate = PREOP;
            ---------------------------------------------
            when BOOT =>
            -- BOOT -> BOOT
                -- start mailbox boot
            -- BOOT -> INIT
                -- stop mailbox
                -- escstate = INIT;
            -- BOOT -> OP
                -- invalid state change
                -- escstate = BOOT;
            ---------------------------------------------
            when SAFEOP =>
            -- SAFEOP -> INIT
                -- stop input
                -- stop mailbox
                -- escstate = INIT;
            -- SAFEOP -> SAFEOP
                -- bissele Komplex nochmal anschauen
            -- SAFEOP -> PREOP
                -- stop input
                -- escstate = PREOP;
            -- SAFEOP -> BOOT
                -- invalid state change
                -- escstate = SAFEOP;
            -- SAFEOP -> OP
                -- start output
                -- escstate = OP;
            ---------------------------------------------
            when OP =>
            -- OP -> OP
                -- BREAK
            -- OP -> INIT
                -- stop output
                -- stop input
                -- stop mailbox
                -- escstate = INIT;
            -- OP -> PREOP
                -- stop output
                -- stop input
                --escstate = PREOP;
            -- OP -> BOOT
                -- invalid state change
                -- stop output 
                -- escstate = SAFEOP;
            -- OP -> SAFEOP
                -- stop output
                -- escstate = SAFEOP;
            ---------------------------------------------
            when others => 
            -- unknown state
        end case;
    end process;
end Behavioral;
