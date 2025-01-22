library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity GPIO_demo is
    Port (  clk : in STD_LOGIC;
            led : out STD_LOGIC;
            TRIG: out std_logic;
            ECHO: in std_logic;      
            reset        : in  STD_LOGIC;
            servo_signal : out STD_LOGIC ;   
            UART_TXD : out STD_LOGIC
    );
end GPIO_demo;

architecture Behavioral of GPIO_demo is

component UART_TX_CTRL
    Port(
        SEND : in std_logic;
        DATA : in std_logic_vector(7 downto 0);
        clk : in std_logic;          
        READY : out std_logic;
        UART_TX : out std_logic
    );
end component;

component ServoControl 
    Port (
        clk          : in  STD_LOGIC;  -- Input clock (assume 50 MHz)
        reset        : in  STD_LOGIC;  -- Reset signal
        angle_number : out STD_LOGIC_VECTOR(7 downto 0);
        servo_signal : out STD_LOGIC   -- Output PWM signal for the servo
    );
end component;


component ultrasonic
    port(
        clk : in std_logic;
        TRIG : out std_logic;
        led : out std_logic;
        ECHO : in std_logic;
        distance_out : out std_logic_vector(7 downto 0)
    );
end component;

type UART_STATE_TYPE is (LD_INIT, SEND_CHAR, WAIT_RDY);
type DATA_TYPE is (angle_indicator,ANGLE,far_indicator,FAR);

-- UART_TX_CTRL control signals
signal uartRdy : std_logic;
signal uartSend : std_logic := '0';
signal uartData : std_logic_vector (7 downto 0) := "00000001";
signal uartDataInt: integer := 1;
signal uartTX : std_logic;
--Ultrasonic sensor data
signal distance_signal : std_logic_vector(7 downto 0);

--Servo data
signal servo_sig:std_logic;
signal angle_number: std_logic_vector(7 downto 0):="00000000";


-- Current UART state signal
signal uartState : UART_STATE_TYPE := LD_INIT;
signal data_state: DATA_TYPE:=angle_indicator;


begin

ultrasonic_inst: ultrasonic
    port map(
        clk => clk,
        TRIG => TRIG,
        led => led, -- If LED output is unused
        ECHO => ECHO,
        distance_out => distance_signal
    );

-- UART State Machine
next_uartState_process: process(clk)
begin
    if rising_edge(clk) then
    case data_state is
     
     when angle_indicator=> 
        case uartState is
            when LD_INIT =>
                if uartRdy = '1' then
                    uartState <= SEND_CHAR;
                end if;
            when SEND_CHAR =>
                uartState <= WAIT_RDY;      -- Wait for transmission to complete
            when WAIT_RDY =>
                if uartRdy = '1' then
                    uartState <= LD_INIT;   -- Go back to initialization when READY
                    data_state<=angle;
                end if;
        end case;
        
        
        when angle=> 
        case uartState is
            when LD_INIT =>
                if uartRdy = '1' then
                    uartState <= SEND_CHAR;
                end if;
            when SEND_CHAR =>
                uartState <= WAIT_RDY;      -- Wait for transmission to complete
            when WAIT_RDY =>
                if uartRdy = '1' then
                    uartState <= LD_INIT;   -- Go back to initialization when READY
                    data_state<=far_indicator;
                end if;
        end case;
       
       
        when far_indicator=>
          case uartState is
            when LD_INIT =>
                if uartRdy = '1' then
                    uartState <= SEND_CHAR;
                end if;
            when SEND_CHAR =>
                uartState <= WAIT_RDY;      -- Wait for transmission to complete
            when WAIT_RDY =>
                if uartRdy = '1' then
                    uartState <= LD_INIT;   -- Go back to initialization when READY
                    data_state<= far;
                end if;
        end case;
        
        
          when far=>
          case uartState is
            when LD_INIT =>
                if uartRdy = '1' then
                    uartState <= SEND_CHAR;
                end if;
            when SEND_CHAR =>
                uartState <= WAIT_RDY;      -- Wait for transmission to complete
            when WAIT_RDY =>
                if uartRdy = '1' then
                    uartState <= LD_INIT;   -- Go back to initialization when READY
                    data_state<= angle_indicator;
                end if;
        end case;
        
        end case;
        
        
    end if; 
end process;

load_process: process(clk)
begin 
    if rising_edge(clk) then
        if data_state= angle_indicator then
                if uartState = LD_INIT then
                    uartSend <= '0';
                    uartData <= "00000000";
                elsif uartState = SEND_CHAR then
                    uartSend <= '1';
                    uartData <= "00000000";
                end if;
                
           elsif data_state= angle then
                if uartState = LD_INIT then
                    uartSend <= '0';
                    uartData <= angle_number;
                elsif uartState = SEND_CHAR then
                    uartSend <= '1';
                    uartData <= angle_number;
                end if;
          elsif data_state= far_indicator then
                if uartState = LD_INIT then
                    uartSend <= '0';
                    uartData <= "11111111";
                elsif uartState = SEND_CHAR then
                    uartSend <= '1';
                    uartData <= "11111111";
                end if;
                
           elsif data_state=far then
                if uartState = LD_INIT then
                    uartSend <= '0';
                    uartData <= distance_signal;
                elsif uartState = SEND_CHAR then
                    uartSend <= '1';
                    uartData <= distance_signal;
                end if;
           end if;
    end if;
end process;



-- Component Instantiation for UART_TX_CTRL
Inst_UART_TX_CTRL: UART_TX_CTRL port map(
    SEND => uartSend,
    DATA => uartData,
    clk => clk,
    READY => uartRdy,
    UART_TX => uartTX
);

Inst_Servo: ServoControl port map(
    clk=>clk,
    reset=>reset,
    angle_number=>angle_number,
    servo_signal=>servo_sig    
);

-- Assign UART_TX signal to top-level output
UART_TXD <= uartTX;
servo_signal<=servo_sig;

end Behavioral;

