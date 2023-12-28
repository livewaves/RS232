library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity RS232_TX is
    PORT(
     Clock      : IN    std_logic;
     Data_In    : IN    unsigned(7 downto 0);
     Send       : IN    std_logic;
     Busy       : OUT   std_logic;
     Serial_Out : OUT   std_logic
    );
end RS232_TX;

architecture Behavioral of RS232_TX is

    signal      Send_Int        :   std_logic       :='0';
    signal      Send_Prev       :   std_logic       :='0';
    signal      Serial_Out_Int  :   std_logic       :='0';
    signal      Busy_Int        :   std_logic       :='0';
    signal      Data_In_Int     :   unsigned(7 downto 0)    :=(others=>'0');
    
    -- Baud Rate is 9600 -->> bit width is 104.16 us
    -- Clock source is 100 MHz --> each period is 10 ns
    -- 104.16 us / 10 ns = 10417
    signal      Bit_Width_Count :   unsigned(13 downto 0)   :=(others=>'0');
    signal      Data_Bit_Count  :   unsigned(3 downto 0)    :=(others=>'0');
    constant    Baud_Rate_9600  :   unsigned(13 downto 0)   :=to_unsigned(10417, 14);
    
    signal      Parity          :   std_logic               :='0';
    signal      Packet_Generate :   std_logic               :='0';
    signal      Send_Packet     :   std_logic               :='0';
    signal      Full_Packet     :   unsigned(11 downto 0)   :=(others=>'0');
    

begin

    Serial_Out  <= Serial_Out_Int;
    Busy        <= Busy_Int;
    
    process(Clock)
    begin
    if rising_edge(Clock) then
        Send_Int            <=  Send;
        Send_Prev           <=  Send_Int;
        Data_In_Int         <=  Data_In;
        Packet_Generate     <= '0';
        Serial_Out_Int      <= '1';

        Bit_Width_Count     <= Bit_Width_Count + 1;
        if (Bit_Width_Count = Baud_Rate_9600) then
            Bit_Width_Count     <=      (others=>'0');
            Data_Bit_Count		<=		Data_Bit_Count + 1;
        end if;

    --state 1: Receiving rise edge of Send Port
    if(Send_Int='1' and Send_Prev='0' and Busy_Int='0') then
        Busy_Int            <= '1';
        Packet_Generate     <= '1';
        Parity              <= Data_In_Int(0) xor Data_In_Int(1) xor Data_In_Int(2) xor Data_In_Int(3) xor
                                Data_In_Int(4) xor Data_In_Int(5) xor Data_In_Int(6) xor Data_In_Int(7);                               
    end if;
    
    --state 2: Build Packet
    if (Packet_Generate = '1') then
        Full_Packet         <=  '1'&'1'&Parity&Data_In_Int&'0';
        Data_Bit_Count      <= (others=>'0');
        Bit_Width_Count     <= (others=>'0');
        Send_Packet         <= '1';
    end if;
    
    --state 3: Send the built Packet
    if (Send_Packet='1' ) then
        Serial_Out_Int      <= Full_Packet(to_integer(Data_Bit_Count));
    end if;  
    
    --state 4: clean up AFTER finishing bit width count for STOP bit
    if (Data_Bit_Count=to_unsigned(11, 4)) then
        Busy_Int            <= '0';
        Send_Packet         <= '0';
    end if;  
    
    end if;
    end process;
end Behavioral;
