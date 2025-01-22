library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.ALL;

entity ultrasonic is
    port(
        CLK : in std_logic;
        TRIG : out std_logic;
        led : out std_logic;
        distance_out : out std_logic_vector(7 downto 0); -- Distance as a 16-bit value
        ECHO : in std_logic
        
    );
end ultrasonic;

architecture Behavioral of ultrasonic is

    constant high_period: integer := 1_000;  -- 10 microseconds
    constant low_period: integer := 200;    -- 2 microseconds
    constant delay_period: integer := 6_000_000;  -- 60 ms delay
    constant timeout: integer := 3_000_000;

    signal trig_counter: integer := 0;
    signal echo_counter: integer := 0;
    signal distance: integer := 0;
    signal high_low : std_logic := '0';  -- 1 is high, 0 is low
    signal prev_echo : std_logic := '0';
    signal delay_counter: integer := 0;
    type state is (delay_state, trig_state, echo_state);
    signal state_t0: state := delay_state;
    type echo_output_state is (low,high,reset_echo);
    signal state_t1: echo_output_state:= low;

begin

    -- Unified State Machine Process
      state_machine: process(clk)
    begin
        if rising_edge(clk) then
            case state_t0 is
                when delay_state =>
                    if delay_counter < delay_period then
                        delay_counter <= delay_counter + 1;
                    else
                        delay_counter <= 0;
                        state_t0 <= trig_state;
                    end if;

                when trig_state =>-- echo trigden h?zl? ise bu konuya bak
                    if high_low = '0' and trig_counter < low_period then
                        trig_counter <= trig_counter + 1;
                    elsif high_low = '0' and trig_counter >= low_period then
                        trig_counter <= 0;
                        high_low <= '1';
                    elsif high_low = '1' and trig_counter < high_period then
                        trig_counter <= trig_counter + 1;
                    elsif high_low = '1' and trig_counter >= high_period then
                        trig_counter <= 0;
                        high_low <= '0';
                        state_t0 <= echo_state;
                   else
                        trig_counter <= 0;
                        high_low <= '0';
                      
                        
                    end if;

                when echo_state => 
                    case state_t1 is
                        when low=> 
                            if (echo='0' and echo_counter <timeout) then 
                                echo_counter<=echo_counter+1;
                                
                            elsif(echo='0' and echo_counter>=timeout) then
                                echo_counter<=0;
                                state_t0<=delay_state;
                                
                            elsif(echo='1' and echo_counter<timeout) then
                                state_t1<=high;
                                echo_counter<=0;
                            else
                                state_t1<=reset_echo;
                                
                            end if;
                         when high =>
                              if( echo='1' and echo_counter<timeout) then
                                echo_counter<=echo_counter+1;
                              elsif(echo='1' and echo_counter>=timeout) then
                                    state_t1<=reset_echo;
                                    
                              elsif(echo='0' and echo_counter<timeout) then
                                    distance<=echo_counter;
                                    state_t1<=reset_echo;
                              else 
                                state_t1<=reset_echo;
                              end if;
                              when reset_echo=> 
                                echo_counter<= 0;
                                state_t0<= delay_state;
                                state_t1<=low;
                                end case;
                  
            end case;
        end if;
    end process;

    -- LED Control Process
    process(clk)
    begin
        if rising_edge(clk) then
            if distance > 100000 then
                led <= '1';
            else
                led <= '0';
            end if;
        end if;
    end process;

    -- Assign TRIG signal
    TRIG <= high_low;
    distance_out <= std_logic_vector(to_unsigned(distance/4096, 8)); -- Convert distance to std_logic_vector


end Behavioral;
