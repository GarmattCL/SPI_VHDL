library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_Level is
    Port (
        reset       : in  STD_LOGIC;       -- Reset-Signal
        button      : in  STD_LOGIC;       -- Button-Eingang
        SCLK        : out STD_LOGIC;       -- SPI Clock
        MOSI        : out STD_LOGIC;       -- SPI MOSI
        MISO        : in  STD_LOGIC;       -- SPI MISO
        CS          : out STD_LOGIC;       -- SPI Chip Select
        STATUS_LED  : out STD_LOGIC        -- Status-LED
    );
end Top_Level;

architecture Behavioral of Top_Level is

    -- Interne Signale
    signal osc_clk         : STD_LOGIC;                       -- Interner Takt
    signal button_debounced : STD_LOGIC;                      -- Entprelltes Button-Signal
    signal spi_ready       : STD_LOGIC;                       -- SPI Ready Signal
    signal spi_launch      : STD_LOGIC;                       -- SPI Start-Signal
    signal spi_command     : STD_LOGIC_VECTOR(7 downto 0);    -- SPI Command
    signal spi_address     : STD_LOGIC_VECTOR(15 downto 0);   -- SPI Address
    signal spi_data_out    : STD_LOGIC_VECTOR(31 downto 0);   -- SPI Data

    -- Oszillator-Komponente
    component Gowin_OSC is
        port (
            oscout : out STD_LOGIC
        );
    end component;

    -- Button-Debouncer-Komponente
    component Button_Debouncer is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            button_in   : in  STD_LOGIC;
            button_out  : out STD_LOGIC
        );
    end component;

    -- SPI Master-Komponente
    component SPI_Master is
        Port (
            reset       : in  STD_LOGIC;
            clk         : in  STD_LOGIC;
            SCLK        : out STD_LOGIC;
            MOSI        : out STD_LOGIC;
            MISO        : in  STD_LOGIC;
            CS          : out STD_LOGIC;
            launch_pin  : in  STD_LOGIC;
            command     : in  STD_LOGIC_VECTOR(7 downto 0);
            address     : in  STD_LOGIC_VECTOR(15 downto 0);
            data_out    : in  STD_LOGIC_VECTOR(31 downto 0);
            STATUS_LED  : out STD_LOGIC
        );
    end component;

    -- EtherCAT State Machine-Komponente
    component EtherCAT_StateMachine is
        Port (
            reset        : in  STD_LOGIC;
            clk          : in  STD_LOGIC;
            status_led   : out STD_LOGIC;
            spi_ready    : out STD_LOGIC;
            spi_command  : out STD_LOGIC_VECTOR(7 downto 0);
            spi_address  : out STD_LOGIC_VECTOR(15 downto 0);
            spi_data_out : out STD_LOGIC_VECTOR(31 downto 0);
            spi_launch   : out STD_LOGIC
        );
    end component;

begin

    -- Instanzierung des internen Oszillators
    oscillator: Gowin_OSC
        port map (
            oscout => osc_clk
        );

    -- Instanzierung des Button-Debouncers
    button_debouncer_inst: entity work.Button_Debouncer
        port map (
            clk         => osc_clk,
            reset       => reset,
            button_in   => button,
            button_out  => button_debounced
        );

    -- Instanzierung des SPI Masters
    spi_master_inst: entity work.SPI_Master
        port map (
            reset       => reset,
            clk         => osc_clk,
            SCLK        => SCLK,
            MOSI        => MOSI,
            MISO        => MISO,
            CS          => CS,
            launch_pin  => not button_debounced,  -- Button triggert die SPI-Kommunikation
            command     => spi_command,
            address     => spi_address,
            data_out    => spi_data_out,
            STATUS_LED  => open
        );

    -- Instanzierung der EtherCAT State Machine
    ethercat_sm_inst: entity work.EtherCAT_StateMachine
        port map (
            reset        => reset,
            clk          => osc_clk,
            status_led   => STATUS_LED,
            spi_ready    => spi_ready,
            spi_command  => spi_command,
            spi_address  => spi_address,
            spi_data_out => spi_data_out,
            spi_launch   => spi_launch
        );

end Behavioral;
