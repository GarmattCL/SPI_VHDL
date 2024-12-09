library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity EtherCAT_StateMachine is
    Port (
        clk          : in  STD_LOGIC;
        status_led   : out STD_LOGIC;
        spi_ready    : in STD_LOGIC;
        spi_command  : out STD_LOGIC_VECTOR(7 downto 0);
        spi_address  : out STD_LOGIC_VECTOR(15 downto 0);
        spi_data_out : out STD_LOGIC_VECTOR(31 downto 0);
        spi_launch   : out STD_LOGIC;
        spi_data_length : out integer;
        spi_request     : in STD_LOGIC
    );
end EtherCAT_StateMachine;

architecture Behavioral of EtherCAT_StateMachine is
    signal spi_launch_sig   : STD_LOGIC := '0';
    signal counter          : integer := 0;
    

    type ethercat_state_type is (EC_TEST, EC_STATE_REQUEST);
    signal ec_state : ethercat_state_type := EC_TEST;

begin
    process(clk, spi_request, spi_ready)
    begin        
        if rising_edge(clk) then
            case ec_state is
---------------------------------------------------------------------
                when EC_TEST =>
                    spi_command <= "00000011"; -- Read command
                    spi_address <= "1000000001100100"; -- Example address
                    spi_data_out <="00000000000000000000000000000000"; --Example data
                    spi_data_length <= 32;
                    if (spi_request = '0') then
                        spi_launch_sig <= '1';
                        counter <= counter + 1;
                        if spi_ready = '1' and counter > 10000 then
                            ec_state <= EC_STATE_REQUEST;
                            counter <= 0;
                            spi_launch_sig <= '0';
                        end if;
                    else
                    spi_launch_sig <= '0';
                    end if;
---------------------------------------------------------------------
                when EC_STATE_REQUEST =>
                    -- Add operational logic
                    spi_command <= "00000011"; -- Read command
                    spi_address <= "1000000101000000"; -- Example address
                    spi_data_out <="00000000000000000000000000000000"; --Example data
                    spi_data_length <= 16;
                    if (spi_request = '0') then
                        spi_launch_sig <= '1';
                        counter <= counter + 1;
                        if spi_ready = '1' and counter > 10000 then
                            ec_state <= EC_TEST;
                            counter <= 0;
                            spi_launch_sig <= '0';
                        end if;
                    else
                    spi_launch_sig <= '0';
                    end if;
---------------------------------------------------------------------
                
---------------------------------------------------------------------
                when others =>
                    ec_state <= EC_TEST;
            end case;
        end if;
    end process;

    -- Status-LED: ON in OP mode
    status_led <= '1' when spi_request = '1' else '0';
    spi_launch <= spi_launch_sig;
end Behavioral;
