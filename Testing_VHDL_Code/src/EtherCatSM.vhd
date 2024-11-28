library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity EtherCAT_StateMachine is
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
end EtherCAT_StateMachine;

architecture Behavioral of EtherCAT_StateMachine is

    type ethercat_state_type is (EC_INIT, EC_PREOP, EC_SAFEOP, EC_OP, EC_ERROR);
    signal ec_state : ethercat_state_type := EC_INIT;

begin
    process(clk, reset)
    begin
        if reset = '0' then
            ec_state <= EC_INIT;
            spi_ready <= '0';
            spi_launch <= '0';
            spi_command <= (others => '0');
            spi_address <= (others => '0');
            spi_data_out <= (others => '0');
        elsif rising_edge(clk) then
            case ec_state is
                when EC_INIT =>
                    spi_command <= "00000011"; -- Read command
                    spi_address <= "0000000001100100"; -- Example address
                    spi_data_out <= "00000000000000000000000000000000"; -- Example data
                    spi_launch <= '1'; -- Trigger SPI
                    ec_state <= EC_PREOP;

                when EC_PREOP =>
                    spi_launch <= '0'; -- Stop SPI trigger
                    ec_state <= EC_SAFEOP;

                when EC_SAFEOP =>
                    -- Add further logic here
                    ec_state <= EC_OP;

                when EC_OP =>
                    -- Add operational logic
                    ec_state <= EC_ERROR;

                when EC_ERROR =>
                    spi_launch <= '0';
                    ec_state <= EC_INIT;

                when others =>
                    ec_state <= EC_INIT;
            end case;
        end if;
    end process;

    -- Status-LED: ON in OP mode
    status_led <= '1' when ec_state = EC_OP else '0';
end Behavioral;
