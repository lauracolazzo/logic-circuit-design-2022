----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Engineer: Laura Colazzo
-- 
-- Design Name: project_reti_logiche
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: Progetto Prova Finale Reti Logiche
-- Target Devices: xc7a200tfbg484-1
----------------------------------------------------------------------------------

--CONVOLUTORE---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity convolutore is
port (
        i_clk :         in std_logic;
        i_rst :         in std_logic;
        i_start :       in std_logic;
        conv_en :       in std_logic;
        conv_in :       in std_logic;
        conv_out :      out std_logic_vector(1 downto 0));
end convolutore;

architecture Behavioral of convolutore is
type C is (C0, C1, C2, C3);
signal cur_state: C;
signal next_state: C;
begin
  
  process(i_clk,i_rst,i_start,conv_en)
    begin
    if (i_rst = '1' or i_start = '0') then
        cur_state <= C0;
    elsif (i_clk'event and i_clk = '1' and conv_en = '1') then
        cur_state <= next_state;
    end if;
    end process;
    
    --convolutore: funzione di uscita e funzione stato prossimo 
    process(conv_in,cur_state)
    begin 
    next_state <= cur_state;
    case cur_state is
        when C0 => if (conv_in = '0') then
                        next_state <= C0;
                        conv_out <= "00";
                   elsif (conv_in = '1') then
                        next_state <= C2;
                        conv_out <= "11";
                   end if;
                   
         when C1 => if (conv_in = '0') then
                        next_state <= C0;
                        conv_out <= "11";
                   elsif (conv_in = '1') then
                        next_state <= C2;
                        conv_out <= "00";
                   end if;
                   
         when C2 => if (conv_in = '0') then
                        next_state <= C1;
                        conv_out <= "01";
                   elsif (conv_in = '1') then
                        next_state <= C3;
                        conv_out <= "10";
                   end if;
                   
        when C3 => if (conv_in = '0') then
                        next_state <= C1;
                        conv_out <= "10";
                   elsif (conv_in = '1') then
                        next_state <= C3;
                        conv_out <= "01";
                   end if;          
    end case;
    end process;                    
end Behavioral;
----------------------------------------------------------------------------------

--DATAPATH-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity datapath is
    port(
            i_clk:          in std_logic;
            i_start:        in std_logic;
            i_rst:          in std_logic;
            i_data:         in std_logic_vector(7 downto 0);
            conv_en:        in std_logic;
            words_num_load: in std_logic;
            words_num_sel:  in std_logic;
            shifter1_load:  in std_logic;
            shifter2_load:  in std_logic;
            read_addr_load: in std_logic;
            read_addr_sel:  in std_logic;
            write_addr_load:in std_logic;
            write_addr_sel: in std_logic;
            o_data_sel:     in std_logic;
            o_addr_sel:     in std_logic;
            o_end:          out std_logic;
            o_data:         out std_logic_vector(7 downto 0);
            o_address:      out std_logic_vector(15 downto 0)
    );
end entity;

architecture Behavioral of datapath is
component convolutore is
port (
        i_clk :         in std_logic;
        i_rst :         in std_logic;
        i_start :       in std_logic;
        conv_en:        in std_logic;
        conv_in :       in std_logic;
        conv_out :      out std_logic_vector(1 downto 0));
end component;

signal conv_out: std_logic_vector(1 downto 0); 
signal words_num_out: std_logic_vector(7 downto 0);
signal shifter1_tmp: std_logic_vector(7 downto 0);
signal shifter1_out: std_logic;
signal shifter2_tmp: std_logic_vector(15 downto 0);
signal shifter2_out: std_logic_vector(15 downto 0);
signal read_addr_out: std_logic_vector(15 downto 0);
signal write_addr_out: std_logic_vector(15 downto 0);
signal words_num_mux_out: std_logic_vector(7 downto 0);
signal read_addr_mux_out: std_logic_vector(15 downto 0);
signal write_addr_mux_out: std_logic_vector(15 downto 0);
signal sub_out: std_logic_vector(7 downto 0);
signal sum1_out: std_logic_vector(15 downto 0);
signal sum2_out: std_logic_vector(15 downto 0);

begin
CONVOLUTORE0: convolutore port map(
    i_clk,
    i_rst,
    i_start,
    conv_en,
    shifter1_out,
    conv_out
);

--words_num_reg: salva il numero di parole da leggere
process(i_clk, i_rst, i_start)
begin
    if (i_rst = '1' or i_start = '0') then 
        words_num_out <= "11111111";
    elsif (i_clk'event and i_clk = '1') then
        if (words_num_load = '1') then
            words_num_out <= words_num_mux_out;
        end if;
    end if;
end process;


--shifter1_reg: shifta la parola di memoria salavata di un bit alla volta verso sx
process(i_clk, i_rst, i_start)
begin
    if (i_rst  = '1' or i_start = '0') then
        shifter1_tmp <= "00000000";
        shifter1_out <= '0';
    elsif (i_clk'event and i_clk = '1') then
        if (shifter1_load  = '1') then
            shifter1_tmp <= i_data;
        elsif (shifter1_load  = '0') then
            shifter1_out <= shifter1_tmp(7);
            shifter1_tmp <= shifter1_tmp(6 downto 0) & '0';
        end if;
    end if;
end process;

--shifter2_reg: salva i 2 bit che arrivano in ingresso, shiftando di due posizioni a sx ad ogni nuovo ingresso
process(i_clk, i_rst, i_start)
begin
    if (i_rst  = '1' or i_start = '0') then
        shifter2_out <= "0000000000000000";
    elsif (i_clk'event and i_clk = '1') then
        if (shifter2_load  = '1') then
          shifter2_out(15 downto 2) <= shifter2_out(13 downto 0);
          shifter2_out(1 downto 0) <= conv_out;
        end if;
    end if;
end process;

--read_addr_reg: salva il prossimo indirizzo di lettura da memoria
process(i_clk, i_rst, i_start)
begin
    if (i_rst = '1' or i_start = '0') then 
        read_addr_out <= "0000000000000000";
    elsif (i_clk'event and i_clk = '1') then
        if (read_addr_load = '1') then
            read_addr_out <= read_addr_mux_out;
        end if;
    end if;
end process;

--write_addr_reg: salva il prossimo indirizzo di scrittura da memoria
process(i_clk, i_rst, i_start)
begin
    if (i_rst = '1' or i_start = '0') then 
        write_addr_out <= "0000000000000000";
    elsif (i_clk'event and i_clk = '1') then
        if (write_addr_load = '1') then
            write_addr_out <= write_addr_mux_out;
        end if;
    end if;
end process;

--words_num_mux
with words_num_sel select
   words_num_mux_out <= i_data when '0',
                sub_out  when '1',
                "XXXXXXXX" when others;
                
--read_addr_mux
with read_addr_sel select
    read_addr_mux_out <= "0000000000000000" when '0',
                sum1_out  when '1',
                "XXXXXXXXXXXXXXXX" when others;
                
--write_addr_mux
with write_addr_sel select
    write_addr_mux_out <= "0000001111101000" when '0', --1000 in decimale
                sum2_out  when '1',
                "XXXXXXXXXXXXXXXX" when others; 
                
--o_addr_mux: seleziona il contenuto di o_address
with o_addr_sel select
    o_address <= read_addr_out when '0',
write_addr_out  when '1',
                 "XXXXXXXXXXXXXXXX" when others;
                 
--o_data_mux: seleziona la parola da scrivere in memoria
with o_data_sel select
    o_data <= shifter2_out(15 downto 8) when '0',
              shifter2_out(7 downto 0) when '1',
              "XXXXXXXX" when others;
              
--sub: decrementa il numero di parole da leggere 
sub_out <= words_num_out - "00000001";   

--sum1: incrementa l'indirizzo di lettura
sum1_out <= read_addr_out + "00000001"; 

--sum2: incrementa l'indirizzo di scrittura
sum2_out <= write_addr_out + "00000001";  

--comparatore: stabilisce se il numero di parole da leggere è nullo
o_end <= '1' when (words_num_out = "00000000") else '0';                                                                         
  
end Behavioral;
----------------------------------------------------------------------------------

--PROJECT RETI LOGICHE------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity project_reti_logiche is
    port (
        i_clk :         in std_logic;
        i_rst :         in std_logic;
        i_start :       in std_logic;
        i_data :        in std_logic_vector(7 downto 0);
        o_address :     out std_logic_vector(15 downto 0);
        o_done :        out std_logic;
        o_en :          out std_logic;
        o_we :          out std_logic;
        o_data :        out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
component datapath is
     port (
         i_clk:          in std_logic;
         i_start:        in std_logic;
         i_rst:          in std_logic;
         i_data:         in std_logic_vector(7 downto 0);
         conv_en:        in std_logic;
         words_num_load: in std_logic;
         words_num_sel:  in std_logic;
         shifter1_load:  in std_logic;
         shifter2_load:  in std_logic;
         read_addr_load: in std_logic;
         read_addr_sel:  in std_logic;
         write_addr_load:in std_logic;
         write_addr_sel: in std_logic;
         o_data_sel:     in std_logic;
         o_addr_sel:     in std_logic;
         o_end:          out std_logic;
         o_data:         out std_logic_vector(7 downto 0);
         o_address:      out std_logic_vector(15 downto 0)
    );
end component;

signal words_num_load: std_logic;
signal words_num_sel: std_logic;
signal shifter1_load: std_logic;
signal shifter2_load: std_logic;
signal read_addr_load: std_logic;
signal read_addr_sel: std_logic;
signal write_addr_load: std_logic;
signal write_addr_sel: std_logic;
signal o_data_sel: std_logic;
signal o_addr_sel: std_logic;
signal conv_en: std_logic;
signal o_end: std_logic;

type S is (S0,S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15,S16,S17,S18,S19);
signal cur_state, next_state: S;
begin
DATAPATH0: datapath port map(
    i_clk,
    i_start,
    i_rst,
    i_data,
    conv_en,
    words_num_load,
    words_num_sel,
    shifter1_load,
    shifter2_load,
    read_addr_load,
    read_addr_sel,
    write_addr_load,
    write_addr_sel,
    o_data_sel,
    o_addr_sel,
    o_end,
    o_data,
    o_address);

process(i_clk, i_rst, i_start)
begin
    if(i_rst = '1' or i_start = '0') then
        cur_state <= S0;
     elsif( i_clk'event and i_clk = '1') then
        cur_state <= next_state;
     end if;
end process;

--funzione stato prossimo
process(cur_state,i_start,o_end)
begin
next_state <= cur_state;
case cur_state is

    when S0 =>
        if (i_start = '1') then
            next_state <= S1;
        elsif (i_start = '0') then
            next_state <= S0;
        end if;
        
    when S1 =>
        next_state <= S2;
    
    when S2 =>
         next_state <= S3;
         
    when S3 =>
         next_state <= S4;     
        
    when S4 =>
       if (o_end = '1') then
            next_state <= S19;
       elsif (o_end = '0') then
            next_state <= S5;
       end if;
        
    when S5 =>
        next_state <= S6;
        
    when S6 =>
        next_state <= S7;    
        
    when S7 =>
        next_state <= S8;    
        
    when S8 =>
        next_state <= S9;
        
    when S9 =>
        next_state <= S10;
    
    when S10 =>
        next_state <= S11;    
        
    when S11 =>
        next_state <= S12;
    
    when S12 =>
        next_state <= S13;  
        
    when S13 =>
        next_state <= S14;  
            
   when S14 =>
        next_state <= S15;
        
   when S15 =>
        next_state <= S16;
        
   when S16 =>
        next_state <= S17;          
        
   when S17 =>
        next_state <= S18;
   
   when S18 =>
        if (o_end = '1') then
            next_state <= S19;
        elsif (o_end = '0') then
            next_state <= S6;
        end if;        
        
   when S19 =>
        next_state <= S0;                        
                
end case;                         
end process;

--funzione  d'uscita
process(cur_state)
begin
words_num_load <= '0';
words_num_sel<= '0';
shifter1_load <= '0';
shifter2_load <= '0';
read_addr_load <= '0';
read_addr_sel <= '0';
write_addr_load <= '0';
write_addr_sel <= '0';
o_data_sel <= '0';
o_addr_sel <= '0';
o_en <= '0';
o_we <= '0';
o_done <= '0';
conv_en <= '1';

case cur_state is
    when S0 =>

    when S1 =>
        read_addr_sel <= '0';
        read_addr_load <= '1';
        write_addr_sel <= '0';
        write_addr_load <= '1';
        
    when S2 =>
        read_addr_sel <= '1';
        read_addr_load <= '1';
        o_en <= '1';
        o_addr_sel <= '0';

    when S3 =>
        words_num_sel <= '0';
        words_num_load <= '1';
        
    when S4 =>
        
    when S5 =>
        o_en <= '1';
        o_addr_sel <= '0'; 
        
   when S6 =>
        shifter1_load <= '1';
        conv_en <= '0';    
        
   when S7 =>
        conv_en <= '0';
        
   when S8 =>
        shifter2_load <= '1';
        
   when S9 =>
        shifter2_load <= '1';
       
   when S10 =>
        shifter2_load <= '1';         
        
   when S11 =>
        shifter2_load <= '1';
        
   when S12 =>
        shifter2_load <= '1';
        
   when S13 =>
        shifter2_load <= '1';
        
    when S14 =>
        shifter2_load <= '1';
          
   when S15 =>
        shifter2_load <= '1';
    
   when S16 =>
        o_data_sel <= '0';
        o_addr_sel <= '1';
        o_en <= '1';
        o_we <= '1';
        write_addr_sel <= '1';
        write_addr_load <= '1';   
        conv_en <= '0';
       
   when S17 =>
        o_data_sel <= '1';
        o_addr_sel <= '1';
        o_en <= '1';
        o_we <= '1';
        write_addr_sel <= '1';
        write_addr_load <= '1';
        read_addr_sel <= '1';
        read_addr_load <= '1';
        words_num_sel <= '1';
        words_num_load <= '1';
        conv_en <= '0';
        
   when S18 =>
        o_addr_sel <= '0';
        o_en <= '1';
        conv_en <= '0';
        
   when S19 =>
        o_done <= '1';
                                          
end case;
end process; 
end Behavioral;
----------------------------------------------------------------------------------
