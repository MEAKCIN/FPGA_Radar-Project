library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_GPIO_demo is
end tb_GPIO_demo;

architecture Behavioral of tb_GPIO_demo is

    -- Component Declaration for the Unit Under Test (UUT)
    component GPIO_demo
        Port ( clk : in STD_LOGIC;
               led : out STD_LOGIC;
               TRIG : out STD_LOGIC;
               ECHO : in STD_LOGIC;
               reset : in STD_LOGIC;
               servo_signal : out STD_LOGIC;
               UART_TXD : out STD_LOGIC);
    end component;

    -- Inputs
    signal clk : STD_LOGIC := '0';
    signal reset : STD_LOGIC := '1';
    signal ECHO : STD_LOGIC := '0';

    -- Outputs
    signal led : STD_LOGIC;
    signal TRIG : STD_LOGIC;
    signal servo_signal : STD_LOGIC;
    signal UART_TXD : STD_LOGIC;

    -- Clock period definitions
    constant clk_period : time := 10 ns; -- 100 MHz clock

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: GPIO_demo port map (
        clk => clk,
        led => led,
        TRIG => TRIG,
        ECHO => ECHO,
        reset => reset,
        servo_signal => servo_signal,
        UART_TXD => UART_TXD
    );

    -- Clock generation process
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Reset generation process
    reset_process: process
    begin
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait;
    end process;

    -- ECHO pulse generation process
    echo_process: process
        constant TRIG_DELAY : time := 10 us; -- Time to wait after TRIG
        constant DISTANCE_CM : integer := 10; -- Simulated distance in cm
        variable echo_pulse_time : time := DISTANCE_CM * 58 us; -- 58µs per cm
    begin
        loop
            -- Wait for trigger pulse
            wait until rising_edge(TRIG);
            -- Wait for trigger to finish (10µs typical for HC-SR04)
            wait until falling_edge(TRIG);
            -- Simulate sound wave propagation time
            wait for TRIG_DELAY;
            -- Generate ECHO pulse proportional to distance
            ECHO <= '1';
            wait for echo_pulse_time;
            ECHO <= '0';
        end loop;
    end process;

end Behavioral;