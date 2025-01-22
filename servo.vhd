library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

entity ServoControl is
    Port (
        clk          : in  STD_LOGIC;  -- Input clock (assume 50 MHz)
        reset        : in  STD_LOGIC;  -- Reset signal
        angle_number : out STD_LOGIC_VECTOR(7 downto 0);
        servo_signal : out STD_LOGIC   -- Output PWM signal for the servo
    );
end ServoControl;

architecture Behavioral of ServoControl is
    -- Constants
    constant pwm_period    : integer := 2_000_000; -- 20 ms (in nanoseconds)
    constant pulse_min     : integer := 100_000;  -- 1 ms (in nanoseconds) for 0 degrees
    constant pulse_max     : integer := 300_000;  -- 2 ms (in nanoseconds) for 180 degrees
 --   constant step_delay    : integer := 1_000_000; -- 500 ms delay between steps (adjust for slower motion)
    constant angle_step    : integer := 1;        -- Incremental angle step (fine control)
    constant max_angle     : integer := 180;      -- Maximum angle (0 to 180 degrees)
    constant step_increment: integer:=1111;
    
    
    -- Signals
    signal pwm_counter     : integer := 0;       -- Counter for the PWM period
    signal pulse_width     : integer := pulse_min; -- Current pulse width
    signal angle           : integer := 0;       -- Current servo angle
    signal sweep_direction : std_logic := '0';   -- '1' for backward, '0' for forward
   -- signal delay_counter   : integer := 0;      -- Counter for step delay,
    
    
begin

    -- Process to generate PWM signal
    PWM_Generator : process(clk, reset)
    begin
        if reset = '1' then
            pwm_counter <= 0;
            servo_signal <= '0';
            
        elsif rising_edge(clk) then
           if(pwm_counter < pulse_width) then
              servo_signal<= '1';
              pwm_counter<= pwm_counter + 1;
           elsif(pwm_counter>= pulse_width and pwm_counter < pwm_period) then
            servo_signal<= '0';
            pwm_counter<= pwm_counter + 1;
            elsif( pwm_counter >= pwm_period) then
            pwm_counter <= 0 ;
            end if; 
        end if;
    end process PWM_Generator;




    -- Process to update the pulse width based on angle
    Angle_Updater : process(clk, reset)
    begin
        if reset = '1' then
            angle <= 0;
            sweep_direction <= '0';
            pulse_width <= pulse_min;
--            delay_counter <= 0;
        elsif rising_edge(clk) then
--            if delay_counter < (step_delay) then
--                delay_counter <= delay_counter + 1; -- Increment delay counter
--            else
--                delay_counter <= 0; -- Reset delay counter
--                -- Update =angle and pulse width after delay
             if(pwm_counter=pwm_period-1) then
                if sweep_direction = '0' then
                    angle <= angle + angle_step;
                    if angle >= max_angle-1 then
                        sweep_direction <= '1'; -- Change direction
                        pulse_width <= pulse_max;
                    end if;
                    pulse_width <= pulse_width + step_increment;
                else
                    angle <= angle - angle_step;
                    if angle <= 1 then
                        sweep_direction <= '0'; -- Change direction
                        pulse_width <= pulse_min;
                    end if;
                    pulse_width <= pulse_width - step_increment;
                end if;
                -- Map angle to pulse width
                
               
             end if;
            end if;
--        end if;
    end process Angle_Updater;
    angle_number<=std_logic_vector(to_unsigned(angle, 8));

end Behavioral;
