library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RS232_RX is
    Port ( Clock        : in    STD_LOGIC;
           Data_Out     : out   unsigned(7 downto 0);
           Valid        : out   STD_LOGIC;
           Serial_In    : in    STD_LOGIC
           );
end RS232_RX;

architecture Behavioral of RS232_RX is

    signal      Data_Out_Int        :   unsigned(15 downto 0)    :=(others=>'0');
    signal      Valid_Int           :   std_logic               :='0';
    Signal      Serial_In_Int       :   std_logic               :='0';
    signal      Serial_In_Prev      :   std_logic               :='0';
    
    --Baud Rate is 9600 --> 104.16 us
    --Clock is 100 MHz --> 10 ns for each period
    -- 104.16 us/10ns = 10417
    constant    Baud_Rate_9600          :   unsigned(13 downto 0)    :=to_unsigned(5207, 14);
    constant    Half_Baud_Rate          :   unsigned(13 downto 0)    :=to_unsigned(2603,14);
    signal      Packet_Detection        :   std_logic                :='0';
    signal      find_bit_center_state   :   std_logic                :='0';
    signal      Parity                  :   std_logic                :='0';
    signal      Data_Bit_Count          :   unsigned(3 downto 0)     :=(others=>'0');
    signal      Bit_Width_Count         :   unsigned(13 downto 0)    :=(others=>'0');
    
    signal      Parity_check            :   std_logic                :='0';

begin
    Valid       <=  Valid_Int;
    Data_Out    <=  Data_Out_Int(7 downto 0);
    
    Process(Clock)
    begin
    if rising_edge(Clock) then
        Serial_In_Int       <=  Serial_In;
        Serial_In_Prev      <=  Serial_In_Int;
        Bit_Width_Count     <= Bit_Width_Count + 1;
        Valid_Int           <='0';
        
        if (Serial_In_Int='0' and Serial_In_Prev='1' and Packet_Detection='0') then
            Packet_Detection        <=  '1';
            find_bit_center_state   <=  '1';            
        end if;
        
        if (find_bit_center_state='1' and Bit_Width_Count=Half_Baud_Rate) then
            find_bit_center_state   <= '0';
            Bit_Width_Count         <=(others=>'0');
            Data_Bit_Count          <=(others=>'0');
            Parity                  <='0';
        end if;
        
        if (Bit_Width_Count=Baud_Rate_9600 ) then
            Bit_Width_Count                            <= (others=>'0');
            Data_Bit_Count      <= Data_Bit_Count + 1;
            Data_Out_Int(to_integer(Data_Bit_Count))    <= Serial_In_Int;
            Parity				<=		Parity xor Serial_In_Int;
            Parity_check        <= '1';
        end if;

        
        if (Data_Bit_Count=to_unsigned(9, 4) and packet_Detection='1') then
            Valid_Int           <=   not Parity;
            packet_Detection    <= '0';
        end if;

    end if;
    end process;
end Behavioral;
