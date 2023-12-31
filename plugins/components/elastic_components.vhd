
library ieee;
use ieee.std_logic_1164.all;
package customTypes is

    type data_array is array(natural range <>) of std_logic_vector;

end package;

-----------------------------------------------------------------  andN
------------------------------------------------------------------------
-- size-generic AND gate used in the size-generic lazy fork and join
------------------------------------------------------------------------
LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use work.customTypes.all;

ENTITY andN IS
GENERIC (n : INTEGER := 4);
PORT (  x : IN std_logic_vector(N-1 downto 0);
        res : OUT STD_LOGIC);
END andN;

ARCHITECTURE vanilla OF andn IS
    SIGNAL dummy : std_logic_vector(n-1 downto 0);
BEGIN
    dummy <= (OTHERS => '1');
    res <= '1' WHEN x = dummy ELSE '0';
END vanilla;

-----------------------------------------------------------------  nandN
------------------------------------------------------------------------
-- size-generic AND gate used in the size-generic lazy fork and join
------------------------------------------------------------------------
LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use work.customTypes.all;

ENTITY nandN IS
GENERIC (n : INTEGER := 4);
PORT (  x : IN std_logic_vector(N-1 downto 0);
        res : OUT STD_LOGIC);
END nandN;

ARCHITECTURE arch OF nandn IS
    SIGNAL dummy : std_logic_vector(n-1 downto 0);
    SIGNAL andRes: STD_LOGIC;
BEGIN
    dummy <= (OTHERS => '1');
    andRes <= '1' WHEN x = dummy ELSE '0';
    res <= not andRes;
END arch;

-----------------------------------------------------------------  orN
------------------------------------------------------------------------
-- size-generic OR gate used in the size-generic eager fork and join
------------------------------------------------------------------------
LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use work.customTypes.all;

ENTITY orN IS
GENERIC (n : INTEGER := 4);
PORT (  x : IN std_logic_vector(N-1 downto 0);
        res : OUT STD_LOGIC);
END orN;

ARCHITECTURE vanilla OF orN IS
    SIGNAL dummy : std_logic_vector(n-1 downto 0);
BEGIN
    dummy <= (OTHERS => '0');
    res <= '0' WHEN x = dummy ELSE '1';
END vanilla;

-----------------------------------------------------------------  norN
------------------------------------------------------------------------
-- size-generic OR gate used in the size-generic eager fork and join
------------------------------------------------------------------------
LIBRARY IEEE;
USE ieee.std_logic_1164.all;
use work.customTypes.all;

ENTITY norN IS
GENERIC (n : INTEGER := 4);
PORT (  x : IN std_logic_vector(N-1 downto 0);
        res : OUT STD_LOGIC);
END norN;

ARCHITECTURE arch OF norN IS
    SIGNAL dummy : std_logic_vector(n-1 downto 0);
    SIGNAL orRes: STD_LOGIC;
BEGIN
    dummy <= (OTHERS => '0');
    orRes <= '0' WHEN x = dummy ELSE '1';
    res <= not orRes;
END arch;

--------------------------------------------------------------  join
---------------------------------------------------------------------
--------------------------------------------------------------  join
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity join is generic (SIZE : integer);
port (
    pValidArray     : in std_logic_vector(SIZE-1 downto 0);
    nReady          : in std_logic;
    valid           : out std_logic;
    readyArray      : out std_logic_vector(SIZE-1 downto 0));
end join;

architecture arch of join is
signal allPValid : std_logic;
    
begin
    
    allPValidAndGate : entity work.andN generic map(SIZE)
            port map(   pValidArray,
                        allPValid);
    
    valid <= allPValid;
    
    process (pValidArray, nReady)
        variable  singlePValid : std_logic_vector(SIZE-1 downto 0);
        begin        
        for i in 0 to SIZE-1 loop
            singlePValid(i) := '1';
            --new if
            if(pValidArray(i) = '1') then
                for j in 0 to SIZE-1 loop
                    if (i /= j) then
                        singlePValid(i) := (singlePValid(i) and pValidArray(j));
                    end if;
                end loop;
            else
               singlePValid(i) := '1';
            end if;  
        end loop;
        for i in 0 to SIZE-1 loop
            readyArray(i) <=  (singlePValid(i) and nReady);
        end loop;
    end process;

end arch;

-------------------------------------------- TEHB: AYA's tagged version 05/08/2023
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity TEHB_tagged is 
    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        TAG_SIZE: integer   -- AYA: 05/08/2023: added this
    );
port (
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);

        tagInArray : in data_array (INPUTS-1 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

        tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this 

        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end TEHB_tagged;

architecture arch of TEHB_tagged is
    signal full_reg, reg_en, mux_sel : std_logic;
    signal data_reg: std_logic_vector(DATA_SIZE_IN + TAG_SIZE-1 downto 0);
   -- signal tag_reg: std_logic_vector(TAG_SIZE-1 downto 0);

    signal tagged_data_in : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE-1 downto 0); -- AYA: 04/10/2023
    signal tagged_data_out : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);  -- 04/10/2023 

begin

    -- AYA: 04/10/2023
    tagged_data_in(0) <= tagInArray(0) & dataInArray(0);  --04/10/2023
    dataOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN -1 downto 0);  --04/10/2023
    tagOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN + TAG_SIZE -1 downto DATA_SIZE_IN);  --04/10/2023
    
    process(clk, rst) is

          begin
           if (rst = '1') then
                full_reg <= '0';
              
            elsif (rising_edge(clk)) then
                full_reg <= validArray(0) and not nReadyArray(0);                    
            
            end if;
    end process; 

    process(clk, rst) is

          begin
           if (rst = '1') then
                data_reg <= (others => '0');
                --tag_reg <= (others => '0');
            elsif (rising_edge(clk)) then
                if (reg_en) then
                    data_reg<= tagged_data_in(0); --dataInArray(0);   -- 03/10/2023
                    --tag_reg <= tagInArray(0);
                end if;                  
            
            end if;
    end process;

    process (mux_sel, data_reg, tagged_data_in) is --, dataInArray, tagInArray) is -- tag_reg,
        begin
            if (mux_sel = '1') then
                tagged_data_out(0) <= data_reg; --03/10/2023
                --dataOutArray(0) <= data_reg;
                --tagOutArray(0) <= tag_reg;
            else
                tagged_data_out(0) <= tagged_data_in(0); --03/10/2023
                --dataOutArray(0) <= dataInArray(0);
                --tagOutArray(0) <= tagInArray(0);
            end if;
    end process;

    -- AYA: new : 03/10/2023
    --process(pValidArray, full_reg, tagInArray, tag_reg) is
    --begin
    --    if(pValidArray(0) or full_reg) then
    --        if(full_reg) then
    --           tagOutArray(0) <= tag_reg;
    --        else
    --           tagOutArray(0) <= tagInArray(0); 
    --        end if;
    --    end if;
    --end process;


    validArray(0) <= pValidArray(0) or full_reg;    
    readyArray(0) <= not full_reg;
    reg_en <= readyArray(0) and pValidArray(0) and not nReadyArray(0);
    mux_sel <= full_reg;

    -- AAY: 03/10/2023: ended up doing it that simply since valid here does not got through any clk cycles
   --tagOutArray(0) <= tagInArray(0); -- AYA: 05/08/2023: added this


end arch;

--------------------------------------------------------------  TEHB
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity TEHB is 
    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer
    );
port (
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end TEHB;

architecture arch of TEHB is
    signal full_reg, reg_en, mux_sel : std_logic;
    signal data_reg: std_logic_vector(DATA_SIZE_IN-1 downto 0);
begin
    
    process(clk, rst) is

          begin
           if (rst = '1') then
                full_reg <= '0';
              
            elsif (rising_edge(clk)) then
                full_reg <= validArray(0) and not nReadyArray(0);                    
            
            end if;
    end process; 

    process(clk, rst) is

          begin
           if (rst = '1') then
                data_reg <= (others => '0');
              
            elsif (rising_edge(clk)) then
                if (reg_en) then
                    data_reg<= dataInArray(0);  
                end if;                  
            
            end if;
    end process;

    process (mux_sel, data_reg, dataInArray) is
        begin
            if (mux_sel = '1') then
                dataOutArray(0) <= data_reg;
            else
                dataOutArray(0) <= dataInArray(0);
            end if;


    end process;


    validArray(0) <= pValidArray(0) or full_reg;    
    readyArray(0) <= not full_reg;
    reg_en <= readyArray(0) and pValidArray(0) and not nReadyArray(0);
    mux_sel <= full_reg;


end arch;

---------------------------------------------  OEHB AYA's tagged version 05/08/2023
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity OEHB_tagged is 
    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        TAG_SIZE: integer   -- AYA: 05/08/2023: added this
    );
port (
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);

        tagInArray : in data_array (INPUTS-1 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

        tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this 

        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end OEHB_tagged;

architecture arch of OEHB_tagged is
    signal full_reg, reg_en, mux_sel : std_logic;

    signal data_reg: std_logic_vector(DATA_SIZE_IN+TAG_SIZE-1 downto 0);

    signal tagged_data_in : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE-1 downto 0); -- AYA: 04/10/2023
    signal tagged_data_out : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);  -- 04/10/2023 

begin

    -- AYA: 04/10/2023
    tagged_data_in(0) <= tagInArray(0) & dataInArray(0);  --04/10/2023
    dataOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN -1 downto 0);  --04/10/2023
    tagOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN + TAG_SIZE -1 downto DATA_SIZE_IN);  --04/10/2023
    
    process(clk, rst) is

          begin
           if (rst = '1') then
                validArray(0) <= '0';
              
            elsif (rising_edge(clk)) then
                validArray(0) <=  pValidArray(0) or not readyArray(0);                   
            
            end if;
    end process; 

    process(clk, rst) is

          begin
           if (rst = '1') then
                data_reg <= (others => '0');
            elsif (rising_edge(clk)) then
                if (reg_en) then
                    data_reg<= tagged_data_in(0); 
                end if;                  
            
            end if;
    end process;


    readyArray(0) <= not validArray(0) or nReadyArray(0);
    reg_en <= readyArray(0) and pValidArray(0);

    tagOutArray(0) <= data_reg;

    --dataOutArray(0) <= data_reg;

    -- tagOutArray(0) <= tagInArray(0); -- AYA: 05/08/2023: added this
    --tagOutArray(0) <= tag_reg; -- AYA: 08/08/2023

end arch;

--------------------------------------------------------------  OEHB
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity OEHB is 
    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer
    );
port (
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end OEHB;

architecture arch of OEHB is
    signal full_reg, reg_en, mux_sel : std_logic;
    signal data_reg: std_logic_vector(DATA_SIZE_IN-1 downto 0);
begin
    
    process(clk, rst) is

          begin
           if (rst = '1') then
                validArray(0) <= '0';
              
            elsif (rising_edge(clk)) then
                validArray(0) <=  pValidArray(0) or not readyArray(0);                   
            
            end if;
    end process; 

    process(clk, rst) is

          begin
           if (rst = '1') then
                data_reg <= (others => '0');
              
            elsif (rising_edge(clk)) then
                if (reg_en) then
                    data_reg<= dataInArray(0);  
                end if;                  
            
            end if;
    end process;


    readyArray(0) <= not validArray(0) or nReadyArray(0);
    reg_en <= readyArray(0) and pValidArray(0);
    dataOutArray(0) <= data_reg;

end arch;

---------------------------------------------- EB AYA's tagged version 05/08/2023
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity elasticBuffer_tagged is
Generic (
  INPUTS :integer; OUTPUTS :integer; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer;
  TAG_SIZE: integer   -- AYA: 05/08/2023: added this 
);
port(
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);

    tagInArray : in data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

    tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    ReadyArray : out std_logic_vector(0 downto 0);
    ValidArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0));
end elasticBuffer_tagged;
------------------------------------------------------------------------ 
-- elastic buffer 
------------------------------------------------------------------------ 
architecture arch of elasticBuffer_tagged is
    
    signal tehb1_valid, tehb1_ready : STD_LOGIC;
    signal oehb1_valid, oehb1_ready : STD_LOGIC;


    signal tehb1_dataOut, oehb1_dataOut : std_logic_vector(DATA_SIZE_IN + TAG_SIZE-1 downto 0);

   -- signal tehb1_tagOut, oehb1_tagOut : std_logic_vector(TAG_SIZE-1 downto 0);  -- AYA: 08/08/2023

    signal tagged_data_in : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE-1 downto 0); -- AYA: 04/10/2023
    signal tagged_data_out : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);  -- 04/10/2023 

begin

    -- AYA: 04/10/2023
    tagged_data_in(0) <= tagInArray(0) & dataInArray(0);  --04/10/2023
    dataOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN -1 downto 0);  --04/10/2023
    tagOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN + TAG_SIZE -1 downto DATA_SIZE_IN);  --04/10/2023

tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN + TAG_SIZE, DATA_SIZE_IN + TAG_SIZE)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => pValidArray(0), -- real or speculatef condition (determined by merge1)
            nReadyArray(0) => oehb1_ready,    
            validArray(0) => tehb1_valid, 
        --outputs
            readyArray(0) => tehb1_ready,   
            dataInArray(0) => tagged_data_in(0),
            dataOutArray(0) => tehb1_dataOut
        );

oehb1: entity work.OEHB(arch) generic map (1, 1, DATA_SIZE_IN + TAG_SIZE, DATA_SIZE_IN + TAG_SIZE)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb1_valid, -- real or speculatef condition (determined by merge1)
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => oehb1_valid, 
        --outputs
            readyArray(0) => oehb1_ready,   
            dataInArray(0) =>tehb1_dataOut,
            dataOutArray(0) => oehb1_dataOut
        );

    tagged_data_out(0) <= oehb1_dataOut;

-- dataOutArray(0) <= oehb1_dataOut;

ValidArray(0) <= oehb1_valid;
ReadyArray(0) <= tehb1_ready;

-- tagOutArray(0) <= tagInArray(0); -- AYA: 05/08/2023: added this

-- tagOutArray(0) <= oehb1_tagOut; -- AYA: 08/08/2023

end arch;

--------------------------------------------------------------  EB
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity elasticBuffer is
Generic (
  INPUTS :integer; OUTPUTS :integer; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer 
);
port(
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    ReadyArray : out std_logic_vector(0 downto 0);
    ValidArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0));
end elasticBuffer;
------------------------------------------------------------------------ 
-- elastic buffer 
------------------------------------------------------------------------ 
architecture arch of elasticBuffer is
    
    signal tehb1_valid, tehb1_ready : STD_LOGIC;
    signal oehb1_valid, oehb1_ready : STD_LOGIC;
    signal tehb1_dataOut, oehb1_dataOut : std_logic_vector(DATA_SIZE_IN-1 downto 0);

    
begin

tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => pValidArray(0), -- real or speculatef condition (determined by merge1)
            nReadyArray(0) => oehb1_ready,    
            validArray(0) => tehb1_valid, 
        --outputs
            readyArray(0) => tehb1_ready,   
            dataInArray(0) => dataInArray(0),
            dataOutArray(0) => tehb1_dataOut
        );

oehb1: entity work.OEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb1_valid, -- real or speculatef condition (determined by merge1)
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => oehb1_valid, 
        --outputs
            readyArray(0) => oehb1_ready,   
            dataInArray(0) =>tehb1_dataOut,
            dataOutArray(0) => oehb1_dataOut
        );

dataOutArray(0) <= oehb1_dataOut;
ValidArray(0) <= oehb1_valid;
ReadyArray(0) <= tehb1_ready;
    
end arch;

------------------------------ Aya's --------------------------------------------
-------------------------------------------------------------- 
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity buffer_bx_op is  
Generic (
  INPUTS :integer; OUTPUTS :integer; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer 
);
port(
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    ReadyArray : out std_logic_vector(0 downto 0);
    ValidArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0));
end buffer_bx_op;
------------------------------------------------------------------------ 
-- buffer_bx_op 
------------------------------------------------------------------------ 
architecture arch of buffer_bx_op is
    
    signal tehb1_valid, tehb1_ready : STD_LOGIC;
    signal oehb1_valid, oehb1_ready : STD_LOGIC;
    signal tehb1_dataOut, oehb1_dataOut : std_logic_vector(DATA_SIZE_IN-1 downto 0);

    
begin

--tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        --port map (
        --inputspValidArray
            --clk => clk, 
            --rst => rst, 
            --pValidArray(0)  => pValidArray(0), -- real or speculatef condition (determined by merge1)
            --nReadyArray(0) => oehb1_ready,    
            --validArray(0) => tehb1_valid, 
        --outputs
            --readyArray(0) => tehb1_ready,   
            --dataInArray(0) => dataInArray(0),
            --dataOutArray(0) => tehb1_dataOut
        --);

--oehb1: entity work.OEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        --port map (
        --inputspValidArray
            --clk => clk, 
            --rst => rst, 
            --pValidArray(0)  => tehb1_valid, -- real or speculatef condition (determined by merge1)
            --nReadyArray(0) => nReadyArray(0),    
            --validArray(0) => oehb1_valid, 
        --outputs
            --readyArray(0) => oehb1_ready,   
            --dataInArray(0) =>tehb1_dataOut,
            --dataOutArray(0) => oehb1_dataOut
        --);

dataOutArray(0) <= dataInArray(0);--oehb1_dataOut; 
ValidArray(0) <= pValidArray(0);--oehb1_valid; 
ReadyArray(0) <= nReadyArray(0);--tehb1_ready; 
    
end arch;

--------------------------------------------------------------  join_bx_op (wrapper for join, temporary)
---------------------------------------------------------------------
Library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity join_bx_op is
Generic (
  INPUTS: integer; OUTPUTS: integer; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer
);
port (
  clk, rst : in std_logic; 
  dataInArray : in data_array (1 downto 0)(DATA_SIZE_IN-1 downto 0); 
  dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);      
  pValidArray : in std_logic_vector(1 downto 0);
  nReadyArray : in std_logic_vector(0 downto 0);
  validArray : out std_logic_vector(0 downto 0);
  readyArray : out std_logic_vector(1 downto 0));
end entity;

architecture arch of join_bx_op is

signal join_valid : STD_LOGIC;

begin 

    join_write_temp:   entity work.join(arch) generic map(INPUTS)
            port map( pValidArray,  --pValidArray
                      nReadyArray(0),     --nready                    
                      join_valid,         --valid          
                      readyArray);   --readyarray 

    validArray(0) <= join_valid;

end architecture;
------------------------------ End of Aya's --------------------------------------


-------------------------------------------------------------- NEW AYA end
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;

entity AYA_end_node is 
    generic(
        INPUTS        : integer;
        MEM_INPUTS    : integer;
        STORE_COUNT   : integer;  -- AYA: 25/07/2023: added this to distinguish between the case of having no stores and having only 1 store
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer
    );

port (
    clk, rst : in std_logic;  
    dataInArray : in data_array (INPUTS - 1  downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    ReadyArray : out std_logic_vector(INPUTS - 1  downto 0);
    ValidArray : out std_logic_vector(0  downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(INPUTS - 1 downto 0);
    eReadyArray : out std_logic_vector(MEM_INPUTS - 1 downto 0);
    eValidArray : in std_logic_vector(MEM_INPUTS - 1 downto 0) := (others => '0'));
end AYA_end_node;

architecture arch of AYA_end_node is
    signal allPValid : std_logic;
    signal nReady: STD_LOGIC;
    signal valid: std_logic;
    signal mem_valid: std_logic;
    signal joinValid:std_logic;
    signal joinReady   : std_logic_vector(1 downto 0);

    -- Aya testing stuff
    signal tehb_test_valid: std_logic;
    signal tehb_test_ready: std_logic;
    signal tehb_test_out: data_array(0 downto 0)(0 downto 0);

    signal tehb_test_data_in: data_array(0 downto 0)(0 downto 0);

begin
   
    -- process for the return data
    -- there may be multiple return points, check if any is valid and output its data
    process(pValidArray, dataInArray)
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;

    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        for I in INPUTS - 1 downto 0 loop
            if (pValidArray(I) = '1') then
                tmp_data_out  := unsigned(dataInArray(I));
                tmp_valid_out := pValidArray(I);
            end if;
        end loop;
    dataOutArray(0)  <= std_logic_vector(resize(tmp_data_out, DATA_SIZE_OUT));
    valid <= tmp_valid_out;
    end process;

    -- join for return data and memory--we exit only in case the first process gets
    -- a single valid and if the AND of all memories is set
    j : entity work.join(arch) generic map(2)
            port map(   (valid, eValidArray(0)),
                        nReadyArray(0),
                        joinValid,
                        joinReady);

   
    -- valid to successor (set by join)
    validArray(0) <= joinValid when STORE_COUNT > 0 else valid;

    -- join sends ready to predecessors
    -- not needed for eReady (because memory never reads it)
    process(joinReady)
    begin
        for I in 0 to INPUTS - 1 loop
            readyArray(I) <= joinReady(1); --joinReady(1);  -- AYa: I do not understand why it was set to that of index 1 because it should correspond to the ready of the data input which is at index 0.. 
        end loop;
    end process;

    -- AYA: 02/08/2023: added the following extra process to assign something to the eready because it is IMP when it is connected through a Branch or a Phi, for instance, as opposed to being directly connected from ST or from the MC as before...
    process(joinReady)
    begin
        for I in 0 to MEM_INPUTS - 1 loop
          eReadyArray(I) <= joinReady(1); --joinReady(1);
        end loop;
    end process;

end arch;


-------------------------------------------------------------- Original  end
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;

entity end_node is 
    generic(
        INPUTS        : integer;
        MEM_INPUTS    : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer
    );

port (
    clk, rst : in std_logic;  
    dataInArray : in data_array (INPUTS - 1  downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    ReadyArray : out std_logic_vector(INPUTS - 1  downto 0);
    ValidArray : out std_logic_vector(0  downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(INPUTS - 1 downto 0);
    eReadyArray : out std_logic_vector(MEM_INPUTS - 1 downto 0);
    eValidArray : in std_logic_vector(MEM_INPUTS - 1  downto 0) := (others => '0'));
end end_node;

architecture arch of end_node is
    signal allPValid : std_logic;
    signal nReady: STD_LOGIC;
    signal valid: std_logic;
    signal mem_valid: std_logic;
    signal joinValid:std_logic;
    signal joinReady   : std_logic_vector(1 downto 0);

begin
   
    -- process for the return data
    -- there may be multiple return points, check if any is valid and output its data
    process(pValidArray, dataInArray)
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;

    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        for I in INPUTS - 1 downto 0 loop
            if (pValidArray(I) = '1') then
                tmp_data_out  := unsigned(dataInArray(I));
                tmp_valid_out := pValidArray(I);
            end if;
        end loop;
    dataOutArray(0)  <= std_logic_vector(resize(tmp_data_out, DATA_SIZE_OUT));
    valid <= tmp_valid_out;
    end process;

    -- check if all mem controllers are done (and of all valids from memory)
    mem_and: entity work.andN(vanilla) generic map (MEM_INPUTS)
            port map (eValidArray, mem_valid);

    -- join for return data and memory--we exit only in case the first process gets
    -- a single valid and if the AND of all memories is set
    j : entity work.join(arch) generic map(2)
            port map(   (valid, mem_valid),
                        nReadyArray(0),
                        joinValid,
                        joinReady);

   
    -- valid to successor (set by join)
    validArray(0) <= joinValid;

    -- join sends ready to predecessors
    -- not needed for eReady (because memory never reads it)
    process(joinReady)
    begin
        for I in 0 to INPUTS - 1 loop
            readyArray(I) <= joinReady(1);
        end loop;
    end process;

end arch;

-------------------------------------------------------------  branch
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity branchSimple is port(
    condition,
    pValid : in std_logic;
    nReadyArray : in std_logic_vector(1 downto 0);  -- (branch1, branch0)
    validArray : out std_logic_vector(1 downto 0);
    ready : out std_logic);
end branchSimple;

---------------------------------------------------------------------
-- simple architecture
---------------------------------------------------------------------
architecture arch of branchSimple is
begin
    
    -- only one branch can announce ready, according to condition
    validArray(1) <= (not condition) and pValid;        
    validArray(0) <= condition and pValid;

    ready <= (nReadyArray(1) and not condition)
             or (nReadyArray(0) and condition);  

end arch;

---------------------------- AYA's Aligner_Branch 01/10/2023
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity aligner_branch is generic( OUTPUTS_NUM : integer; DATA_SIZE_IN : integer; DATA_SIZE_OUT : integer;
    TAG_SIZE: integer   -- AYA: 05/08/2023: added this
    );
port(
    clk, rst : in std_logic;
    pValidArray         : in std_logic_vector(1 downto 0);

    tag_condition: in data_array (0 downto 0)(TAG_SIZE - 1 downto 0);  -- in the vhdl writer, this condition will receive tag only as its data
    dataInArray          : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);

    dataOutArray            : out data_array (OUTPUTS_NUM-1 downto 0)(DATA_SIZE_OUT-1 downto 0);
    nReadyArray     : in std_logic_vector(OUTPUTS_NUM-1 downto 0);  -- (branch1, branch0)
    validArray      : out std_logic_vector(OUTPUTS_NUM-1 downto 0); -- (branch1, branch0)
    readyArray      : out std_logic_vector(1 downto 0));    -- (data, condition)
end aligner_branch;


architecture arch of aligner_branch is 
    signal temp_ready: std_logic_vector(OUTPUTS_NUM-1 downto 0);
    signal joinValid, branchReady   : std_logic;
begin

    j : entity work.join(arch) generic map(2)
            port map(   (pValidArray(1), pValidArray(0)),
                        branchReady,
                        joinValid,
                        readyArray);

    -----------------------------------------------
   process(joinValid, nReadyArray, tag_condition)
   begin
        for I in 0 to OUTPUTS_NUM - 1 loop
            if(unsigned(tag_condition(0)) = to_unsigned(I,tag_condition(0)'length) and joinValid = '1') then
                validArray(I) <= '1';
                temp_ready(I) <= nReadyArray(I);
            else
                validArray(I) <= '0';
                temp_ready(I) <= '0';
            end if;
        end loop;
    end process;

    branchReady <= or(temp_ready);
    -----------------------------------------------
    process(dataInArray)
    begin
        for I in 0 to OUTPUTS_NUM - 1 loop
            dataOutArray(I) <= dataInArray(0);
        end loop;  
    end process;    

end arch;

---------------------------- AYA's tagged version 05/08/2023
library ieee;
use ieee.std_logic_1164.all;
USE work.customTypes.all;

entity branch_tagged is generic( INPUTS:integer; SIZE : integer; DATA_SIZE_IN : integer;DATA_SIZE_OUT : integer;
    TAG_SIZE: integer   -- AYA: 05/08/2023: added this
    );
port(
    clk, rst : in std_logic;
    pValidArray         : in std_logic_vector(1 downto 0);
    condition: in data_array (0 downto 0)(0 downto 0);
    dataInArray          : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);

    tagInArray : in data_array (1 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this
    tagOutArray : out data_array (SIZE-1 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this 

    dataOutArray            : out data_array (SIZE-1 downto 0)(DATA_SIZE_OUT-1 downto 0);
    nReadyArray     : in std_logic_vector(1 downto 0);  -- (branch1, branch0)
    validArray      : out std_logic_vector(1 downto 0); -- (branch1, branch0)
    readyArray      : out std_logic_vector(1 downto 0));    -- (data, condition)
end branch_tagged;


architecture arch of branch_tagged is 
    signal joinValid, branchReady   : std_logic;
    --signal dataOut0, dataOut1 : std_logic_vector(31 downto 0);
begin

    j : entity work.join(arch) generic map(2)
            port map(   (pValidArray(1), pValidArray(0)),
                        branchReady,
                        joinValid,
                        readyArray);

    br : entity work.branchSimple(arch)
            port map(   condition(0)(0),
                        joinValid,
                        nReadyArray,
                        validArray,
                        branchReady);

    process(dataInArray, tagInArray)
    begin
        for I in 0 to SIZE - 1 loop
            dataOutArray(I) <= dataInArray(0);
            tagOutArray(I) <= tagInArray(0); -- AYA: 05/08/2023: added this to propagate the tag from the data (not the codnition as of 30/09/2023)
        end loop;  
    end process; 

    -- AYA: note that the convention of branches input in the valid array is that .at(0) is the data input and .at(1) is the cond input
   

end arch;


library ieee;
use ieee.std_logic_1164.all;
USE work.customTypes.all;

entity branch is generic( INPUTS:integer; SIZE : integer; DATA_SIZE_IN : integer;DATA_SIZE_OUT : integer);
port(
    clk, rst : in std_logic;
    pValidArray         : in std_logic_vector(1 downto 0);
    condition: in data_array (0 downto 0)(0 downto 0);
    dataInArray          : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray            : out data_array (SIZE-1 downto 0)(DATA_SIZE_OUT-1 downto 0);
    nReadyArray     : in std_logic_vector(1 downto 0);  -- (branch1, branch0)
    validArray      : out std_logic_vector(1 downto 0); -- (branch1, branch0)
    readyArray      : out std_logic_vector(1 downto 0));    -- (data, condition)
end branch;


architecture arch of branch is 
    signal joinValid, branchReady   : std_logic;
    --signal dataOut0, dataOut1 : std_logic_vector(31 downto 0);
begin

    j : entity work.join(arch) generic map(2)
            port map(   (pValidArray(1), pValidArray(0)),
                        branchReady,
                        joinValid,
                        readyArray);

    br : entity work.branchSimple(arch)
            port map(   condition(0)(0),
                        joinValid,
                        nReadyArray,
                        validArray,
                        branchReady);

    process(dataInArray)
    begin
        for I in 0 to SIZE - 1 loop
            dataOutArray(I) <= dataInArray(0);
        end loop;  
    end process; 

end arch;


-----------------------------------------------------------  gian_branch_tag
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
USE work.customTypes.all;
use ieee.numeric_std.all;

entity gian_branch_tag is generic(
    INPUTS        : integer; --supports only two inputs and one condition (so put 3)
    SIZE          : integer;
    DATA_SIZE_IN  : integer;
    DATA_SIZE_OUT : integer;
    COND_SIZE     : integer;
    THRD_NUM      : integer;
    TAG_SIZE      : integer
);
port(
    clk, rst      : in  std_logic;
    dataInArray   : in  data_array(0 downto 0)(DATA_SIZE_IN - 1 downto 0);
    dataOutArray  : out data_array(1 downto 0)(DATA_SIZE_OUT - 1 downto 0);
    pValidArray   : in  std_logic_vector(1 downto 0);
    nReadyArray      : in  std_logic_vector(1 downto 0);
    validArray      : out std_logic_vector(1 downto 0);
    readyArray : out std_logic_vector(1 downto 0);
    condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0);   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
    tag_pValidArray : in std_logic_vector(1 downto 0);
    tag_readyArray : out std_logic_vector(1 downto 0);
    tag_nReadyArray : in std_logic_vector(1 downto 0);
    tag_validArray : out std_logic_vector(1 downto 0);
    tag_dataInArray : in data_array(1 downto 0)(TAG_SIZE - 1 downto 0); 
    tag_dataOutArray : out data_array(1 downto 0)(TAG_SIZE - 1 downto 0)
);
end gian_branch_tag;

architecture arch of gian_branch_tag is

signal cond_buff : data_array(THRD_NUM-1 downto 0)(COND_SIZE - 1 downto 0);
signal tag_cond_buff : data_array(THRD_NUM-1 downto 0)(TAG_SIZE - 1 downto 0);
signal in_buff : data_array(THRD_NUM - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
signal tag_in_buff : data_array(THRD_NUM - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);

signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid_0, tehb_pvalid_1 : std_logic;
signal tehb_tag_pvalid_0, tehb_tag_pvalid_1 : std_logic;

signal tehb_ready_1, tehb_ready_0 : std_logic;
signal tehb_tag_ready_1, tehb_tag_ready_0 : std_logic;

signal tmp_data_out : std_logic_vector(DATA_SIZE_OUT - 1 downto 0);
signal tmp_tag_data_out : std_logic_vector(TAG_SIZE - 1 downto 0);


begin

    process(clk, rst)
    variable index_cond : integer := 0;
    variable index_tag_cond : integer := 0;
    variable index_in : integer := 0 ;
    variable index_tag_in : integer := 0;
    variable found_match : integer := 0;
    variable index_match : integer := 0;
    begin
        if(rst = '1') then
            index_cond := 0;
            index_tag_cond := 0;
            index_in := 0;
            index_tag_in := 0;
            cond_buff <= (others => (others => '0'));
            in_buff <= (others => (others => '0'));
            tag_cond_buff <= (others => (others => '0'));
            tag_in_buff <= (others => (others => '0'));
            found_match := 0;
            index_match := 0;
            tehb_pvalid_0 <= '0';
            tehb_pvalid_1 <= '0';
            tehb_tag_pvalid_0 <= '0';
            tehb_tag_pvalid_1 <= '0';
            readyArray <= (others => '0');
            tag_readyArray <= (others => '0');
        elsif rising_edge(clk) then
            --default
            found_match := 0;
            index_match := 0;
            tehb_pvalid_0 <= '0';
            tehb_pvalid_1 <= '0';
            tehb_tag_pvalid_0 <= '0';
            tehb_tag_pvalid_1 <= '0';
            --search for match
            for I in 0 to THRD_NUM - 1 loop
                if(found_match = 0) then
                    index_match := I;
                end if;
                if(to_integer(unsigned(tag_in_buff(I))) /= 0 and to_integer(unsigned(tag_cond_buff(0))) /= 0 and index_cond > 0 and index_match < index_in and to_integer(unsigned(tag_in_buff(I))) = to_integer(unsigned(tag_cond_buff(0))) and found_match = 0) then
                    found_match := 1;
                end if;
            end loop;
            --output
            if(found_match = 1) then
                tmp_data_out <= in_buff(index_match);
                if(to_integer(unsigned(cond_buff(0))) = 0) then  --
                    if(nReadyArray(0) = '1' and tag_nReadyArray(0) = '1') then
                        tehb_pvalid_0 <= '1';
                        tmp_tag_data_out <= tag_cond_buff(0);
                        tehb_tag_pvalid_0 <= '1';
                    end if;
                else
                    if(nReadyArray(1) = '1' and tag_nReadyArray(1) = '1') then
                        tehb_pvalid_1 <= '1';
                        tmp_tag_data_out <= tag_cond_buff(0);
                        tehb_tag_pvalid_1 <= '1';
                    end if;
                end if;
                if((to_integer(unsigned(cond_buff(0))) = 0 and nReadyArray(0) = '1' and tag_nReadyArray(0) = '1') or (to_integer(unsigned(cond_buff(0))) = 1 and nReadyArray(1) = '1' and tag_nReadyArray(1) = '1')) then
                    for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                        cond_buff(I) <= cond_buff(I+1);
                        tag_cond_buff(I) <= tag_cond_buff(I+1);
                    end loop;
                    in_buff(THRD_NUM - 1) <= (others => '0');
                    for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                        if(I >= index_match) then
                            tag_in_buff(I) <= tag_in_buff(I+1);
                            in_buff(I) <= in_buff(I+1);
                        end if;
                    end loop;
                    index_in := index_in - 1;
                    index_cond := index_cond - 1;
                    index_tag_in := index_tag_in - 1;
                    index_tag_cond := index_tag_cond - 1;
                end if;
            end if;
            --dataIn_0_buff
            if(pValidArray(0) = '1' and index_in < THRD_NUM and readyArray(0) = '1') then  
                in_buff(index_in) <= dataInArray(0);
                index_in := index_in + 1;
            end if;
            --tag_in0_buff for normal mux
            if(tag_pValidArray(0) = '1' and index_tag_in < THRD_NUM and tag_readyArray(0) = '1') then  
                tag_in_buff(index_tag_in) <= tag_dataInArray(0);
                index_tag_in := index_tag_in + 1;
            end if;
            --cond_buff
            if(pValidArray(1) = '1' and index_cond < THRD_NUM and readyArray(1) = '1') then  
                cond_buff(index_cond) <= condition(0);
                index_cond := index_cond + 1;
            end if;
            --tag_cond_buff
            if(tag_pValidArray(1) = '1' and index_tag_cond < THRD_NUM and tag_readyArray(1) = '1') then  
                tag_cond_buff(index_tag_cond) <= tag_dataInArray(1);
                index_tag_cond := index_tag_cond + 1;
            end if;
            --ready
            if(index_in = THRD_NUM) then
                readyArray(0) <= '0';
            else
                readyArray(0) <= '1';
            end if;
            if(index_tag_in = THRD_NUM) then
                tag_readyArray(0) <= '0';
            else
                tag_readyArray(0) <= '1';
            end if;
            if(index_cond = THRD_NUM) then
                readyArray(1) <= '0';
            else
                readyArray(1) <= '1';
            end if;
            if(index_tag_cond = THRD_NUM) then
                tag_readyArray(1) <= '0';
            else
                tag_readyArray(1) <= '1';
            end if;
        end if;
    end process;

    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid_1, 
            nReadyArray(0) => nReadyArray(1),    
            validArray(0) => validArray(1), 
        --outputs
            readyArray(0) => tehb_ready_1,   
            dataInArray(0) => tmp_data_out,
            dataOutArray(0) => dataOutArray(1)
        );

    tehb0: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid_0, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready_0,   
            dataInArray(0) => tmp_data_out,
            dataOutArray(0) => dataOutArray(0)
    );

    tehb_tag0: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_tag_pvalid_0, 
            nReadyArray(0) => tag_nReadyArray(0),    
            validArray(0) => tag_validArray(0), 
        --outputs
            readyArray(0) => tehb_tag_ready_0,   
            dataInArray(0) => tmp_tag_data_out,
            dataOutArray(0) => tag_dataOutArray(0)
    );

    tehb_tag1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_tag_pvalid_1, 
            nReadyArray(0) => tag_nReadyArray(1),    
            validArray(0) => tag_validArray(1), 
        --outputs
            readyArray(0) => tehb_tag_ready_1,   
            dataInArray(0) => tmp_tag_data_out,
            dataOutArray(0) => tag_dataOutArray(1)
    );




end arch;

-----------------------------------------------  eagerFork_RegisterBLock
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity eagerFork_RegisterBLock is
port(   clk, reset, 
        p_valid, n_stop, 
        p_valid_and_fork_stop : in std_logic;
        valid,  block_stop : out std_logic);
end eagerFork_RegisterBLock;

architecture arch of eagerFork_RegisterBLock is
    signal reg_value, reg_in, block_stop_internal : std_logic;
begin
    
    block_stop_internal <= n_stop and reg_value;
    
    block_stop <= block_stop_internal;
    
    reg_in <= block_stop_internal or (not p_valid_and_fork_stop);
    
    valid <= reg_value and p_valid; 
    
    reg : process(clk, reset, reg_in)
    begin
        if(reset='1') then
            reg_value <= '1'; --contains a "stop" signal - must be 1 at reset
        else
            if(rising_edge(clk))then
                reg_value <= reg_in;
            end if;
        end if;
    end process reg;
    
end arch;


------------------------------------------------  fork: AYA's tagged version 05/08/2023
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity fork_tagged is generic( INPUTS: integer; SIZE : integer; DATA_SIZE_IN : Integer; DATA_SIZE_OUT : Integer;
    TAG_SIZE: integer   -- AYA: 05/08/2023: added this
);
port(   clk, rst    : in std_logic; -- the eager implementation uses registers
        dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);

        tagInArray : in data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

        tagOutArray : out data_array (SIZE-1 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

        pValidArray : in std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(0 downto 0);
        dataOutArray : out data_array (SIZE-1 downto 0)(DATA_SIZE_OUT-1 downto 0); 
        nReadyArray : in std_logic_vector(SIZE-1 downto 0);
        validArray  : out std_logic_vector(SIZE-1 downto 0)
        );
        
end fork_tagged;


------------------------------------------------------------------------
-- generic eager implementation
------------------------------------------------------------------------
architecture arch of fork_tagged is
-- wrapper signals (internals use "stop" signals instead of "ready" signals)
    signal forkStop : std_logic;
    signal nStopArray : std_logic_vector(SIZE-1 downto 0);
-- internal combinatorial signals
    signal blockStopArray : std_logic_vector(SIZE-1 downto 0);
    signal anyBlockStop : std_logic;
    signal pValidAndForkStop : std_logic;
begin
    
    --can't adapt the signals directly in port map
    wrapper : process(forkStop, nReadyArray)
    begin
        readyArray(0) <= not forkStop;
        for i in 0 to SIZE-1 loop
            nStopArray(i) <= not nReadyArray(i);
        end loop;
    end process;
    
    genericOr : entity work.orN generic map (SIZE)
        port map(blockStopArray, anyBlockStop);
        
    -- internal combinatorial signals
    forkStop <= anyBlockStop; 
    pValidAndForkStop <= pValidArray(0) and forkStop;
    
    --generate blocks
    generateBlocks : for i in SIZE-1 downto 0 generate
        regblock : entity work.eagerFork_RegisterBLock(arch)
                port map(   clk, rst,
                            pValidArray(0), nStopArray(i),
                            pValidAndForkStop,
                            validArray(i), blockStopArray(i));
    end generate;

    process(dataInArray, tagInArray)
    begin
        for I in 0 to SIZE - 1 loop
            dataOutArray(I) <= dataInArray(0);
            tagOutArray(I) <= tagInArray(0); -- AYA: 05/08/2023: added this
        end loop;  
    end process;   

end arch;

-------------------------------------------------------------------  fork
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity fork is generic( INPUTS: integer; SIZE : integer; DATA_SIZE_IN : Integer; DATA_SIZE_OUT : Integer);
port(   clk, rst    : in std_logic; -- the eager implementation uses registers
        dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
        pValidArray : in std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(0 downto 0);
        dataOutArray : out data_array (SIZE-1 downto 0)(DATA_SIZE_OUT-1 downto 0); 
        nReadyArray : in std_logic_vector(SIZE-1 downto 0);
        validArray  : out std_logic_vector(SIZE-1 downto 0)
        );
        
end fork;


------------------------------------------------------------------------
-- generic eager implementation
------------------------------------------------------------------------
architecture arch of fork is
-- wrapper signals (internals use "stop" signals instead of "ready" signals)
    signal forkStop : std_logic;
    signal nStopArray : std_logic_vector(SIZE-1 downto 0);
-- internal combinatorial signals
    signal blockStopArray : std_logic_vector(SIZE-1 downto 0);
    signal anyBlockStop : std_logic;
    signal pValidAndForkStop : std_logic;
begin
    
    --can't adapt the signals directly in port map
    wrapper : process(forkStop, nReadyArray)
    begin
        readyArray(0) <= not forkStop;
        for i in 0 to SIZE-1 loop
            nStopArray(i) <= not nReadyArray(i);
        end loop;
    end process;
    
    genericOr : entity work.orN generic map (SIZE)
        port map(blockStopArray, anyBlockStop);
        
    -- internal combinatorial signals
    forkStop <= anyBlockStop; 
    pValidAndForkStop <= pValidArray(0) and forkStop;
    
    --generate blocks
    generateBlocks : for i in SIZE-1 downto 0 generate
        regblock : entity work.eagerFork_RegisterBLock(arch)
                port map(   clk, rst,
                            pValidArray(0), nStopArray(i),
                            pValidAndForkStop,
                            validArray(i), blockStopArray(i));
    end generate;

    process(dataInArray)
    begin
        for I in 0 to SIZE - 1 loop
            dataOutArray(I) <= dataInArray(0);
        end loop;  
    end process;   

end arch;

-------------------------------------------------------------------  fork
------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;

entity lazyfork is generic( INPUTS: integer; SIZE : integer; DATA_SIZE_IN : Integer; DATA_SIZE_OUT : Integer);
port(   clk, rst    : in std_logic; -- the eager implementation uses registers
        dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
        pValidArray : in std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(0 downto 0);
        dataOutArray : out data_array (SIZE-1 downto 0)(DATA_SIZE_OUT-1 downto 0); 
        nReadyArray : in std_logic_vector(SIZE-1 downto 0);
        validArray  : out std_logic_vector(SIZE-1 downto 0)
        );
        
end lazyfork;

architecture arch of lazyfork is
    signal allnReady : std_logic;
begin

genericAnd : entity work.andn generic map (SIZE)
    port map(nReadyArray, allnReady);
 
valids : process(pValidArray, nReadyArray, allnReady)
    begin
    for i in 0 to SIZE-1 loop
        validArray(i) <= pValidArray(0) and allnReady;
    end loop;
    end process;
 
readyArray(0) <= allnReady;

process(dataInArray)
    begin
        for I in 0 to SIZE - 1 loop
            dataOutArray(I) <= dataInArray(0);
        end loop;  
    end process;    

end arch;

--------------------------------------------------------------  merge
---------------------------------------------------------------------
---- AYA: IMP: 12/10/2023: MAKE SURE THAT YOU ONLY USE THIS FOR IF-THEN-ELSE NOT LOOP!!!
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;

entity merge_tagged is

    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        TAG_SIZE : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0);

        tagInArray : in data_array (INPUTS - 1 downto 0)(TAG_SIZE-1 downto 0); 
        tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0)); 

end merge_tagged;

architecture arch of merge_tagged is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

signal tagged_data_in : data_array(1 downto 0)(DATA_SIZE_IN + TAG_SIZE-1 downto 0); -- AYA: 04/10/2023
signal tagged_data_out : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);  -- 04/10/2023 

begin

    -- AYA: 04/10/2023
    tagged_data_in(0) <= tagInArray(0) & dataInArray(0);  --04/10/2023
    tagged_data_in(1) <= tagInArray(1) & dataInArray(1);  --04/10/2023

    dataOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN -1 downto 0);  --04/10/2023
    tagOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN + TAG_SIZE -1 downto DATA_SIZE_IN);  --04/10/2023

    process(pValidArray, tagged_data_in)
        variable tmp_data_out  : unsigned(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(tagged_data_in(0));
        tmp_valid_out := '0';
        for I in INPUTS - 1 downto 0 loop
            if (pValidArray(I) = '1') then
                tmp_data_out  := unsigned(tagged_data_in(I));
                tmp_valid_out := pValidArray(I);
            end if;
        end loop;

        tehb_data_in  <= std_logic_vector(resize(tmp_data_out, DATA_SIZE_OUT + TAG_SIZE));
        tehb_pvalid <= tmp_valid_out;

    end process;

    process(tehb_ready)
    begin
        for I in 0 to INPUTS - 1 loop
            readyArray(I) <= tehb_ready;
        end loop;
    end process;

    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN+ TAG_SIZE, DATA_SIZE_IN + TAG_SIZE)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => tagged_data_out(0)
        );
end arch;

--------------------------------------------------------------  merge
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;

entity OLD_merge is

    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end OLD_merge;

architecture arch of OLD_merge is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

begin

    process(pValidArray, dataInArray)
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        for I in INPUTS - 1 downto 0 loop
            if (pValidArray(I) = '1') then
                tmp_data_out  := unsigned(dataInArray(I));
                tmp_valid_out := pValidArray(I);
            end if;
        end loop;

        tehb_data_in  <= std_logic_vector(resize(tmp_data_out, DATA_SIZE_OUT));
        tehb_pvalid <= tmp_valid_out;

    end process;

    process(tehb_ready)
    begin
        for I in 0 to INPUTS - 1 loop
            readyArray(I) <= tehb_ready;
        end loop;
    end process;

    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );
end arch;


----------------- 28/09/2023: AYa's TAGGED implementation of a new INIT (still in-order but does not produce a leftover token)
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;

entity INIT_merge_tagged is

    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        TAG_SIZE : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);   -- TODO: change 1 input to be of 0-bits!!
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);

        tagInArray : in data_array (INPUTS - 1 downto 0)(TAG_SIZE-1 downto 0); 
        tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0); 

        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end INIT_merge_tagged;

architecture arch of INIT_merge_tagged is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

type state_type is (INIT, ITER);
signal state : state_type;

signal tagged_data_in : data_array(1 downto 0)(DATA_SIZE_IN + TAG_SIZE-1 downto 0); -- AYA: 04/10/2023
signal tagged_data_out : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);  -- 04/10/2023 

begin

    -- AYA: 04/10/2023
    tagged_data_in(0) <= tagInArray(0) & dataInArray(0);  --04/10/2023
    tagged_data_in(1) <= tagInArray(1) & dataInArray(1);  --04/10/2023

    dataOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN -1 downto 0);  --04/10/2023
    tagOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN + TAG_SIZE -1 downto DATA_SIZE_IN);  --04/10/2023

-----------------------------------------------------------------
    state_proc : process (clk, rst)
    begin
        if(rst = '1') then
            state <= INIT;
        elsif rising_edge(clk) then
            -- AYA: transition to ITER if there is a valid token at in0 and you are ready to output it 
                -- IMP note: I replaced nReadyArray with tehb_ready because the earlier is wrong timing wise and it appeared in loops of depth 3
            if(state = INIT and pValidArray(0) = '1' and tehb_ready = '1') then
                state <= ITER;
            elsif(state = ITER and pValidArray(1) = '1' and unsigned(dataInArray(1)) = 0) then
            -- AYA: transition back to INIT state if there is a valid token of value 0 at the in1 input
                    -- We do not care of nReady here because we destroy the token internally instead of outputting it!
                state <= INIT;   
            end if;
        end if;
    end process;

    data_valid_proc: process(state, pValidArray, dataInArray, tagged_data_in) 
        variable tmp_data_out  : unsigned(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(tagged_data_in(0)); --unsigned(dataInArray(0));
        tmp_valid_out := '0';
        case state is
            when INIT =>
                if(pValidArray(0) = '1') then 
                    tmp_data_out  :=  unsigned(tagged_data_in(0)); --to_unsigned(0, DATA_SIZE_IN); --unsigned(dataInArray(0));
                    tmp_valid_out := '1';
                end if;

            when ITER =>
                if (pValidArray(1) = '1' and unsigned(dataInArray(1)) = 1) then
                    tmp_data_out  := unsigned(tagged_data_in(1));
                    tmp_valid_out := '1';
                end if;                         
        end case;
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT + TAG_SIZE));
        tehb_pvalid  <= tmp_valid_out;
    end process;
-----------------------------------------------------------------
    ready_proc: process(state, tehb_ready, pValidArray)
    begin
        case state is 
            when INIT =>
                readyArray(0) <= tehb_ready; 
                readyArray(1) <= not pValidArray(1);
            when ITER => 
                -- AYA: not sure if I should add something extra when the output is = 0 because 
                    -- in this case ready should be 1 regardless of tehb_ready simply because we do not output anything
                        -- What I'm hoping for is that as soon as the state changes it becomes 1 again naturally
                readyArray(1) <= tehb_ready;
                readyArray(0) <= not pValidArray(0);
        end case;
    end process;

    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN + TAG_SIZE, DATA_SIZE_IN + TAG_SIZE)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => tagged_data_out(0)
        );
end arch;


----------------- 03/09/2023: AYa's implementation of a new INIT (still in-order but does not produce a leftover token)
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;

entity merge is

    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);   -- TODO: change 1 input to be of 0-bits!!
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end merge;

architecture arch of merge is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

type state_type is (INIT, ITER);
signal state : state_type;

begin
-----------------------------------------------------------------
    state_proc : process (clk, rst)
    begin
        if(rst = '1') then
            state <= INIT;
        elsif rising_edge(clk) then
            -- AYA: transition to ITER if there is a valid token at in0 and you are ready to output it 
                -- IMP note: I replaced nReadyArray with tehb_ready because the earlier is wrong timing wise and it appeared in loops of depth 3
            if(state = INIT and pValidArray(0) = '1' and tehb_ready = '1') then
                state <= ITER;
            elsif(state = ITER and pValidArray(1) = '1' and unsigned(dataInArray(1)) = 0) then
            -- AYA: transition back to INIT state if there is a valid token of value 0 at the in1 input
                    -- We do not care of nReady here because we destroy the token internally instead of outputting it!
                state <= INIT;   
            end if;
        end if;
    end process;

    data_valid_proc: process(state, dataInArray, pValidArray) 
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        case state is
            when INIT =>
                if(pValidArray(0) = '1') then 
                    tmp_data_out  := to_unsigned(0, DATA_SIZE_IN); --unsigned(dataInArray(0));
                    tmp_valid_out := '1';
                end if;

            when ITER =>
                if (pValidArray(1) = '1' and unsigned(dataInArray(1)) = 1) then
                    tmp_data_out  := unsigned(dataInArray(1));
                    tmp_valid_out := '1';
                end if;                         
        end case;
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid  <= tmp_valid_out;
    end process;
-----------------------------------------------------------------
    ready_proc: process(state, tehb_ready, pValidArray)
    begin
        case state is 
            when INIT =>
                readyArray(0) <= tehb_ready; 
                readyArray(1) <= not pValidArray(1);
            when ITER => 
                -- AYA: not sure if I should add something extra when the output is = 0 because 
                    -- in this case ready should be 1 regardless of tehb_ready simply because we do not output anything
                        -- What I'm hoping for is that as soon as the state changes it becomes 1 again naturally
                readyArray(1) <= tehb_ready;
                readyArray(0) <= not pValidArray(0);
        end case;
    end process;

    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );
end arch;

---------------------------------------

----------------- 07/09/2023: AYa's implementation of a new OOO INIT
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;

entity OOO_INIT_merge is

    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end OOO_INIT_merge;

architecture arch of OOO_INIT_merge is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

type state_type is (INIT, ITER);
signal state : state_type;

begin
    state_proc : process (clk, rst)
    begin
        if(rst = '1') then
            state <= INIT;
        elsif rising_edge(clk) then
            if(state = INIT and tehb_ready = '1' and pValidArray(1) = '1') then --(pValidArray(0) = '1' or pValidArray(1) = '1')) then
                state <= ITER; -- Move to ITER as soon as there is a valid token at COND
            elsif(state = ITER and tehb_ready = '1' and pValidArray(0) = '1') then -- and pValidArray(1) = '0' ) then 
                state <= INIT;  -- Move back to INIT if COND does not have any valid token and START has a valid token
            end if;
        end if;
    end process;

    data_valid_proc: process(state, dataInArray, pValidArray) 
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        case state is
            when INIT =>
                if(pValidArray(0) = '1') then 
                    tmp_data_out  := to_unsigned(0, DATA_SIZE_IN); --unsigned(dataInArray(0));
                    tmp_valid_out := '1';
                end if;

            when ITER =>
                if (pValidArray(1) = '1' and unsigned(dataInArray(1)) = 1) then
                    tmp_data_out  := unsigned(dataInArray(1));
                    tmp_valid_out := '1';
                end if;                     
        end case;
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid  <= tmp_valid_out;
    end process;
-----------------------------------------------------------------
   ready_proc: process(state, tehb_ready, pValidArray)
    begin
        case state is 
            when INIT =>
                readyArray(0) <= tehb_ready; 
                readyArray(1) <= not pValidArray(1);
            when ITER => 
                -- AYA: not sure if I should add something extra when the output is = 0 because 
                    -- in this case ready should be 1 regardless of tehb_ready simply because we do not output anything
                        -- What I'm hoping for is that as soon as the state changes it becomes 1 again naturally
                readyArray(1) <= tehb_ready;
                readyArray(0) <= not pValidArray(0);
        end case;
    end process;

    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );
end arch;

---------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;

entity OLD_merge_notehb is

    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end OLD_merge_notehb;

architecture arch of OLD_merge_notehb is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

begin

    process(pValidArray, dataInArray)
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        for I in INPUTS - 1 downto 0 loop
            if (pValidArray(I) = '1') then
                tmp_data_out  := unsigned(dataInArray(I));
                tmp_valid_out := pValidArray(I);
            end if;
        end loop;

        tehb_data_in  <= std_logic_vector(resize(tmp_data_out, DATA_SIZE_OUT));
        tehb_pvalid <= tmp_valid_out;

    end process;

    process(tehb_ready)
    begin
        for I in 0 to INPUTS - 1 loop
            readyArray(I) <= tehb_ready;
        end loop;
    end process;

    tehb_ready <= nReadyArray(0);
    validArray(0) <= tehb_pvalid;
    dataOutArray(0) <= tehb_data_in;

end arch;

-------------------------------------------------------------

--------- AYA's tweak because the ready calculation was wrong when the two inputs are valid in one cycle 26/09/2023 

library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;

entity merge_notehb is

    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end merge_notehb;

architecture arch of merge_notehb is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

begin

    process(pValidArray, dataInArray)
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(1));
        tmp_valid_out := '0';

        if (pValidArray(0) = '1') then
            tmp_data_out  := unsigned(dataInArray(0));
            tmp_valid_out := '1';

            readyArray(0) <= tehb_ready;
            readyArray(1) <= not pValidArray(1);

        elsif(pValidArray(1) = '1') then
            tmp_data_out  := unsigned(dataInArray(1));
            tmp_valid_out := '1';

            readyArray(0) <= not pValidArray(0);
            readyArray(1) <= tehb_ready;
        else
            readyArray(0) <= '1';
            readyArray(1) <= '1';
        end if;

        --for I in INPUTS - 1 downto 0 loop
        --    if (pValidArray(I) = '1') then
        --        tmp_data_out  := unsigned(dataInArray(I));
        --        tmp_valid_out := pValidArray(I);
        --    end if;
        --end loop;

        tehb_data_in  <= std_logic_vector(resize(tmp_data_out, DATA_SIZE_OUT));
        tehb_pvalid <= tmp_valid_out;

    end process;

    --process(tehb_ready)
    --begin
    --    for I in 0 to INPUTS - 1 loop
    --        readyArray(I) <= tehb_ready;
    --    end loop;
    --end process;

    tehb_ready <= nReadyArray(0);
    validArray(0) <= tehb_pvalid;
    dataOutArray(0) <= tehb_data_in;

end arch;

----------------------------------------------------------------------

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 use work.customTypes.all;
entity start_node_new is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer
  );
 
  Port ( 
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    readyArray : out std_logic_vector(0 downto 0);
    validArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0)
  );
end start_node_new;



architecture arch of start_node_new is 

signal set: STD_LOGIC;
signal start_internal:std_logic;
signal startBuff_readyArray : STD_LOGIC_VECTOR(0 downto 0);
signal startBuff_validArray : STD_LOGIC_VECTOR(0 downto 0);
signal startBuff_dataOutArray: data_array(0 downto 0)(DATA_SIZE_IN-1 downto 0);

begin
 
  --process(clk, rst)
  ----  begin

  --      if (rst=  '1')  then
  --      start_internal <= '0';
  --          set <= '0';

   --     elsif rising_edge(clk) then
   --         if (pValidArray(0) = '1' and set = '0') then
   --             start_internal<= '1';
   --             set <= '1';
   --         else 
   --             start_internal <= '0';
   --         end if;
   --     end if;
        
      
   -- end process;

startBuff: entity work.elasticBuffer(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
port map (
--inputs
    clk => clk,  --clk
    rst => rst,  --rst
    dataInArray(0) => dataInArray(0),  ----dataInArray
    pValidArray(0) => pValidArray(0),   --pValidArray
    nReadyArray(0) => nReadyArray(0),  --nReadyArray
--outputs
    dataOutArray => startBuff_dataOutArray,    ----dataOutArray
    readyArray => startBuff_readyArray,  --readyArray
    validArray => startBuff_validArray   --validArray
);

validArray(0) <= startBuff_validArray(0);
dataOutArray(0) <= startBuff_dataOutArray(0);
readyArray(0) <= startBuff_readyArray(0);

end arch;
--------------------------------------------------------------  aya_start
---------------------------------------------------------------------
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 use work.customTypes.all;
entity aya_start_node is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer
  );
 
  Port ( 
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    readyArray : out std_logic_vector(0 downto 0);
    validArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0)
  );
end aya_start_node;



architecture arch of aya_start_node is 
    signal valid_internal:std_logic;
begin
    process(clk, rst)
    begin

        if (rst=  '1')  then
            valid_internal <= '0';

        else --if rising_edge(clk) then
            valid_internal <= pValidArray(0);
        end if;
        
      
    end process;

validArray(0) <= valid_internal;
dataOutArray <= dataInArray;
readyArray <= nReadyArray;

end arch;

--------------------------------------------------------------  new_start
---------------------------------------------------------------------

library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 use work.customTypes.all;
entity start_node is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer
  );
 
  Port ( 
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    readyArray : out std_logic_vector(0 downto 0);
    validArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0)
  );
end start_node;


architecture arch of start_node is 

signal set: STD_LOGIC;
signal start_internal:std_logic;
signal startBuff_readyArray : STD_LOGIC_VECTOR(0 downto 0);
signal startBuff_validArray : STD_LOGIC_VECTOR(0 downto 0);
signal startBuff_dataOutArray: data_array(0 downto 0)(DATA_SIZE_IN-1 downto 0);

begin
 
start_internal <= pValidArray(0);

startBuff: entity work.elasticBuffer(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
port map (
--inputs
    clk => clk,  --clk
    rst => rst,  --rst
    dataInArray(0) => dataInArray(0),  ----dataInArray
    pValidArray(0) => start_internal,   --pValidArray
    nReadyArray(0) => nReadyArray(0),  --nReadyArray
--outputs
    dataOutArray => startBuff_dataOutArray,    ----dataOutArray
    readyArray => startBuff_readyArray,  --readyArray
    validArray => startBuff_validArray   --validArray
);

validArray(0) <= startBuff_validArray(0);
dataOutArray(0) <= startBuff_dataOutArray(0);
readyArray(0) <= startBuff_readyArray(0);

end arch;

--------------------------------------------------------------  sink
---------------------------------------------------------------------
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 use work.customTypes.all;
entity sink is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer
  );
 
  Port ( 
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    readyArray : out std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0)
  );
end sink;



architecture arch of sink is 

begin
 
readyArray(0) <= '1';

end arch;

-----------------------------------------------  source: AYA's tagged version 05/08/2023
----------------------------------------------------------------------
-- Aya: NOte that it does not output a meaningful tag. It is just for compatibility. 
-- IMagine a SOurce connected to a constant that feeds a colored component. For correctness, the tag ports needs to be there although in components,
        -- I do not look at the tag coming from a constant
--------------------------------------------------------------
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 use work.customTypes.all;
entity source_tagged is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer;
    TAG_SIZE: integer   -- AYA: 05/08/2023: added this
  );
 
  Port ( 
    clk, rst : in std_logic;  
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    validArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);

    tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0) -- AYA: 05/08/2023: added this 
  );
end source_tagged;



architecture arch of source_tagged is 

begin
 
validArray(0) <= '1';

end arch;

--------------------------------------------------------------  source
----------------------------------------------------------------------
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 use work.customTypes.all;
entity source is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer
  );
 
  Port ( 
    clk, rst : in std_logic;  
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    validArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0)
  );
end source;



architecture arch of source is 

begin
 
validArray(0) <= '1';

end arch;

--------------------------------------------------------------  fifo: AYA's tagged version: 05/08/2023
--------------------------------------------------------------------
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 use work.customTypes.all;
entity NOT_USED_elasticFifoInner_tagged is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer; FIFO_DEPTH : integer;
     TAG_SIZE: integer   -- AYA: 05/08/2023: added this
  );
 
  Port ( 
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);

    tagInArray : in data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    readyArray : out std_logic_vector(0 downto 0);
    validArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0);

    tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0) -- AYA: 05/08/2023: added this 
  );
end NOT_USED_elasticFifoInner_tagged;
 
architecture arch of NOT_USED_elasticFifoInner_tagged is

    signal ReadEn   : std_logic := '0';
    signal WriteEn  : std_logic := '0';
    signal Tail : natural range 0 to FIFO_DEPTH - 1;
    signal Head : natural range 0 to FIFO_DEPTH - 1;
    signal Empty    : std_logic;
    signal Full : std_logic;
    signal Bypass: std_logic;
    signal fifo_valid: std_logic;
    type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of STD_LOGIC_VECTOR (DATA_SIZE_IN-1 downto 0);
    signal Memory : FIFO_Memory;

    type tag_FIFO_Memory is array (0 to FIFO_DEPTH - 1) of STD_LOGIC_VECTOR (TAG_SIZE-1 downto 0);
    signal tag_Memory : tag_FIFO_Memory;


begin

    -- ready if there is space in the fifo
    readyArray(0) <= not Full or nReadyArray(0);

    -- read if next can accept and there is sth in fifo to read
    ReadEn <= (nReadyArray(0) and not Empty);

    validArray(0) <= not Empty;
    
    dataOutArray(0) <=  Memory(Head);

    tagOutArray(0) <= tag_Memory(Head);  -- 08/08/2023

    WriteEn <= pValidArray(0) and ( not Full or nReadyArray(0));

    -- valid 
    process(clk)
        begin
           if (rst = '1' ) then
              fifo_valid <= '0';
            elsif (rising_edge(clk)) then
                if (ReadEn ='1')  then
                    fifo_valid <= '1';
                elsif (nReadyArray(0) = '1') then
                    fifo_valid <= '0';
                end if;
             
            end if;
    end process;

    fifo_proc : process (CLK)
   
     begin        
        if rising_edge(CLK) then
          if RST = '1' then
           
          else
            
            if (WriteEn = '1' ) then
                -- Write Data to Memory
                Memory(Tail) <= dataInArray(0);
                
                tag_Memory(Tail) <= tagInArray(0);   -- 08/08/2023

            end if;
            
          end if;
        end if;
    end process;


 
-------------------------------------------
-- process for updating tail
TailUpdate_proc : process (CLK)
   
      begin
        if rising_edge(CLK) then
          
            if RST = '1' then
               Tail <= 0;
            else
          
                if (WriteEn = '1') then

                    Tail  <= (Tail + 1) mod FIFO_DEPTH;
                              
                end if;
               
            end if;
        end if;
    end process; 

-------------------------------------------
-- process for updating head
HeadUpdate_proc : process (CLK)
   
  begin
  if rising_edge(CLK) then
  
    if RST = '1' then
       Head <= 0;
    else
  
        if (ReadEn = '1') then

            Head  <= (Head + 1) mod FIFO_DEPTH;
                      
        end if;
       
    end if;
  end if;
end process; 

-------------------------------------------
-- process for updating full
FullUpdate_proc : process (CLK)
   
  begin
  if rising_edge(CLK) then
  
    if RST = '1' then
       Full <= '0';
    else
  
        -- if only filling but not emptying
        if (WriteEn = '1') and (ReadEn = '0') then

            -- if new tail index will reach head index
            if ((Tail +1) mod FIFO_DEPTH = Head) then

                Full  <= '1';

            end if;
        -- if only emptying but not filling
        elsif (WriteEn = '0') and (ReadEn = '1') then
                Full <= '0';
        -- otherwise, nothing is happening or simultaneous read and write
                      
        end if;
       
    end if;
  end if;
end process;
  
 -------------------------------------------
-- process for updating empty
EmptyUpdate_proc : process (CLK)
   
  begin
  if rising_edge(CLK) then
  
    if RST = '1' then
       Empty <= '1';
    else
        -- if only emptying but not filling
        if (WriteEn = '0') and (ReadEn = '1') then

            -- if new head index will reach tail index
            if ((Head +1) mod FIFO_DEPTH = Tail) then

                Empty  <= '1';

            end if;
        -- if only filling but not emptying
        elsif (WriteEn = '1') and (ReadEn = '0') then
                Empty <= '0';
       -- otherwise, nothing is happening or simultaneous read and write
                      
        end if;
       
    end if;
  end if;
end process;
end architecture;


--------------------------------------------------------------  fifo
--------------------------------------------------------------------
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 use work.customTypes.all;
entity elasticFifoInner is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer; FIFO_DEPTH : integer
  );
 
  Port ( 
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    readyArray : out std_logic_vector(0 downto 0);
    validArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0)
  );
end elasticFifoInner;
 
architecture arch of elasticFifoInner is

    signal ReadEn   : std_logic := '0';
    signal WriteEn  : std_logic := '0';
    signal Tail : natural range 0 to FIFO_DEPTH - 1;
    signal Head : natural range 0 to FIFO_DEPTH - 1;
    signal Empty    : std_logic;
    signal Full : std_logic;
    signal Bypass: std_logic;
    signal fifo_valid: std_logic;
    type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of STD_LOGIC_VECTOR (DATA_SIZE_IN-1 downto 0);
    signal Memory : FIFO_Memory;


begin

    -- ready if there is space in the fifo
    readyArray(0) <= not Full or nReadyArray(0);

    -- read if next can accept and there is sth in fifo to read
    ReadEn <= (nReadyArray(0) and not Empty);

    validArray(0) <= not Empty;
    
    dataOutArray(0) <=  Memory(Head);

    WriteEn <= pValidArray(0) and ( not Full or nReadyArray(0));

    -- valid 
    process(clk)
        begin
           if (rst = '1' ) then
              fifo_valid <= '0';
            elsif (rising_edge(clk)) then
                if (ReadEn ='1')  then
                    fifo_valid <= '1';
                elsif (nReadyArray(0) = '1') then
                    fifo_valid <= '0';
                end if;
             
            end if;
    end process;

    fifo_proc : process (CLK)
   
     begin        
        if rising_edge(CLK) then
          if RST = '1' then
           
          else
            
            if (WriteEn = '1' ) then
                -- Write Data to Memory
                Memory(Tail) <= dataInArray(0);
                
            end if;
            
          end if;
        end if;
    end process;

    -------------------------------------------
-- process for updating tail
TailUpdate_proc : process (CLK)
   
      begin
        if rising_edge(CLK) then
          
            if RST = '1' then
               Tail <= 0;
               
            else
          
                if (WriteEn = '1') then

                    Tail  <= (Tail + 1) mod FIFO_DEPTH;
                              
                end if;
               
            end if;
        end if;
    end process; 

-------------------------------------------
-- process for updating head
HeadUpdate_proc : process (CLK)
   
  begin
  if rising_edge(CLK) then
  
    if RST = '1' then
       Head <= 0;
    else
  
        if (ReadEn = '1') then

            Head  <= (Head + 1) mod FIFO_DEPTH;
                      
        end if;
       
    end if;
  end if;
end process; 

-------------------------------------------
-- process for updating full
FullUpdate_proc : process (CLK)
   
  begin
  if rising_edge(CLK) then
  
    if RST = '1' then
       Full <= '0';
    else
  
        -- if only filling but not emptying
        if (WriteEn = '1') and (ReadEn = '0') then

            -- if new tail index will reach head index
            if ((Tail +1) mod FIFO_DEPTH = Head) then

                Full  <= '1';

            end if;
        -- if only emptying but not filling
        elsif (WriteEn = '0') and (ReadEn = '1') then
                Full <= '0';
        -- otherwise, nothing is happening or simultaneous read and write
                      
        end if;
       
    end if;
  end if;
end process;
  
 -------------------------------------------
-- process for updating empty
EmptyUpdate_proc : process (CLK)
   
  begin
  if rising_edge(CLK) then
  
    if RST = '1' then
       Empty <= '1'; 
    else
        -- if only emptying but not filling
        if (WriteEn = '0') and (ReadEn = '1') then

            -- if new head index will reach tail index
            if ((Head +1) mod FIFO_DEPTH = Tail) then

                Empty  <= '1';

            end if;
        -- if only filling but not emptying
        elsif (WriteEn = '1') and (ReadEn = '0') then
                Empty <= '0';
       -- otherwise, nothing is happening or simultaneous read and write
                      
        end if;
       
    end if;
  end if;
end process;
end architecture;
----------------------------------------------------------------------



--------------------------------------------------- AYa: 18/09/2023: new fifo that has some initialized values upon reset!
--------------------------------------------------------------------
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
 use work.customTypes.all;
entity init_elasticFifoInner is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer; FIFO_DEPTH : integer
  );
 
  Port ( 
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    readyArray : out std_logic_vector(0 downto 0);
    validArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0)
  );
end init_elasticFifoInner;
 
architecture arch of init_elasticFifoInner is

    signal ReadEn   : std_logic := '0';
    signal WriteEn  : std_logic := '0';
    signal Tail : natural range 0 to FIFO_DEPTH - 1;
    signal Head : natural range 0 to FIFO_DEPTH - 1;
    signal Empty    : std_logic;
    signal Full : std_logic;
    signal Bypass: std_logic;
    signal fifo_valid: std_logic;
    type FIFO_Memory is array (0 to FIFO_DEPTH - 1) of STD_LOGIC_VECTOR (DATA_SIZE_IN-1 downto 0);
    signal Memory : FIFO_Memory;


begin

    -- ready if there is space in the fifo
    readyArray(0) <= not Full or nReadyArray(0);

    -- read if next can accept and there is sth in fifo to read
    ReadEn <= (nReadyArray(0) and not Empty);

    validArray(0) <= not Empty;
    
    dataOutArray(0) <=  Memory(Head);

    WriteEn <= pValidArray(0) and ( not Full or nReadyArray(0));

    fifo_proc : process (CLK)
   
     begin        
        if rising_edge(CLK) then
          if RST = '1' then
            -- AYA: 18/09/2023: I want to initialize the Memory with data upon reset
            for I in 0 to FIFO_DEPTH - 1 loop
                Memory(I) <= std_logic_vector(to_unsigned(I, Memory(I)'length));  -- I set the initialization to the index of each element, but it can be anything else up to us..
            end loop;
          else
            
            if (WriteEn = '1' ) then
                -- Write Data to Memory
                Memory(Tail) <= dataInArray(0);
                
            end if;
            
          end if;
        end if;
    end process;
 
-------------------------------------------
-- process for updating tail
TailUpdate_proc : process (CLK)
   
      begin
        if rising_edge(CLK) then
          
            if RST = '1' then
               --Tail <= 0;
               -- AYA: 18/09/2023: initializing the fifo with some elements filling the entire of it 
               Tail <= FIFO_DEPTH - 1;
            else
          
                if (WriteEn = '1') then

                    Tail  <= (Tail + 1) mod FIFO_DEPTH;
                              
                end if;
               
            end if;
        end if;
    end process; 

-------------------------------------------
-- process for updating head
HeadUpdate_proc : process (CLK)
   
  begin
  if rising_edge(CLK) then
  
    if RST = '1' then
       Head <= 0;
    else
  
        if (ReadEn = '1') then

            Head  <= (Head + 1) mod FIFO_DEPTH;
                      
        end if;
       
    end if;
  end if;
end process; 

-------------------------------------------
-- process for updating full
FullUpdate_proc : process (CLK)
   
  begin
  if rising_edge(CLK) then
  
    if RST = '1' then
       --Full <= '0';
       Full <= '1';  -- initializing to full
    else
  
        -- if only filling but not emptying
        if (WriteEn = '1') and (ReadEn = '0') then

            -- if new tail index will reach head index
            if ((Tail +1) mod FIFO_DEPTH = Head) then

                Full  <= '1';

            end if;
        -- if only emptying but not filling
        elsif (WriteEn = '0') and (ReadEn = '1') then
                Full <= '0';
        -- otherwise, nothing is happening or simultaneous read and write
                      
        end if;
       
    end if;
  end if;
end process;
  
 -------------------------------------------
-- process for updating empty
EmptyUpdate_proc : process (CLK)
   
  begin
  if rising_edge(CLK) then
  
    if RST = '1' then
       --Empty <= '1'; 
       Empty <= '0';  -- initializing to full
    else
        -- if only emptying but not filling
        if (WriteEn = '0') and (ReadEn = '1') then

            -- if new head index will reach tail index
            if ((Head +1) mod FIFO_DEPTH = Tail) then

                Empty  <= '1';

            end if;
        -- if only filling but not emptying
        elsif (WriteEn = '1') and (ReadEn = '0') then
                Empty <= '0';
       -- otherwise, nothing is happening or simultaneous read and write
                      
        end if;
       
    end if;
  end if;
end process;
end architecture;
----------------------------------------------------------------------


--------------------- AYA's tagged version 05/08/2023
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity nontranspFifo_tagged is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer; FIFO_DEPTH : integer;
    TAG_SIZE: integer   -- AYA: 05/08/2023: added this
  );
 
port(
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);

    tagInArray : in data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

    tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    ReadyArray : out std_logic_vector(0 downto 0);
    ValidArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0));
end nontranspFifo_tagged;

architecture arch of nontranspFifo_tagged is
    
    signal tehb_valid, tehb_ready : STD_LOGIC;
    signal fifo_valid, fifo_ready : STD_LOGIC;
    signal tehb_dataOut, fifo_dataOut : std_logic_vector(DATA_SIZE_IN + TAG_SIZE -1 downto 0);

    --signal tehb_tagOut, fifo_tagOut : std_logic_vector(TAG_SIZE-1 downto 0);  -- 08/08/2023

    signal tagged_data_in : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE-1 downto 0); -- AYA: 04/10/2023
    signal tagged_data_out : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);  -- 04/10/2023 

begin

    -- AYA: 04/10/2023
    tagged_data_in(0) <= tagInArray(0) & dataInArray(0);  --04/10/2023
    dataOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN -1 downto 0);  --04/10/2023
    tagOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN + TAG_SIZE -1 downto DATA_SIZE_IN);  --04/10/2023


tehb: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN + TAG_SIZE, DATA_SIZE_IN + TAG_SIZE)
        port map (
        --inputs
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => pValidArray(0), 
            nReadyArray(0) => fifo_ready,    
            validArray(0) => tehb_valid, 
        --outputs
            readyArray(0) => tehb_ready,
            dataInArray(0) => tagged_data_in(0),   
            dataOutArray(0) => tehb_dataOut
        );

fifo: entity work.elasticFifoInner(arch) generic map (1, 1, DATA_SIZE_IN + TAG_SIZE, DATA_SIZE_IN + TAG_SIZE, FIFO_DEPTH)
        port map (
        --inputs
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_valid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => fifo_valid, 
        --outputs
            readyArray(0) => fifo_ready,   
            dataInArray(0) =>tehb_dataOut,
            dataOutArray(0) => fifo_dataOut
        );

--dataOutArray(0) <= fifo_dataOut;
tagged_data_out(0) <= fifo_dataOut;  -- 03/10/2023
ValidArray(0) <= fifo_valid;
ReadyArray(0) <= tehb_ready;

-- tagOutArray(0) <= tagInArray(0); -- AYA: 05/08/2023: added this
--tagOutArray(0) <= fifo_tagOut; -- AYA: 08/08/2023
    
end arch;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity nontranspFifo is

  Generic (
    INPUT_COUNT:integer; OUTPUT_COUNT:integer; DATA_SIZE_IN:integer; DATA_SIZE_OUT:integer; FIFO_DEPTH : integer
  );
 
port(
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    ReadyArray : out std_logic_vector(0 downto 0);
    ValidArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0));
end nontranspFifo;

architecture arch of nontranspFifo is
    
    signal tehb_valid, tehb_ready : STD_LOGIC;
    signal fifo_valid, fifo_ready : STD_LOGIC;
    signal tehb_dataOut, fifo_dataOut : std_logic_vector(DATA_SIZE_IN-1 downto 0);
  
begin

tehb: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputs
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => pValidArray(0), 
            nReadyArray(0) => fifo_ready,    
            validArray(0) => tehb_valid, 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => dataInArray(0),
            dataOutArray(0) => tehb_dataOut
        );

fifo: entity work.elasticFifoInner(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN, FIFO_DEPTH)
        port map (
        --inputs
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_valid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => fifo_valid, 
        --outputs
            readyArray(0) => fifo_ready,   
            dataInArray(0) =>tehb_dataOut,
            dataOutArray(0) => fifo_dataOut
        );

dataOutArray(0) <= fifo_dataOut;
ValidArray(0) <= fifo_valid;
ReadyArray(0) <= tehb_ready;
    
end arch;

--------------------- AYA's tagged version 05/08/2023
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity transpFIFO_tagged is 
    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        FIFO_DEPTH : integer;
        TAG_SIZE: integer   -- AYA: 05/08/2023: added this 
    );
port (
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);

        tagInArray : in data_array (INPUTS-1 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

        tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end transpFIFO_tagged;

architecture arch of transpFIFO_tagged is
    signal mux_sel : std_logic;
    signal fifo_valid, fifo_ready : STD_LOGIC;
    signal fifo_pvalid, fifo_nready : STD_LOGIC;
    --signal fifo_in, fifo_out: std_logic_vector(DATA_SIZE_IN-1 downto 0);
    signal fifo_in, fifo_out: std_logic_vector(DATA_SIZE_IN + TAG_SIZE -1 downto 0);  -- 03/10/2023: replacing the above

    --signal tag_fifo_in, tag_fifo_out: std_logic_vector(TAG_SIZE-1 downto 0);  -- 08/08/2023

    signal tagged_data_in : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE-1 downto 0); -- AYA: 04/10/2023
    signal tagged_data_out : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);  -- 04/10/2023 

begin

    -- AYA: 04/10/2023
    tagged_data_in(0) <= tagInArray(0) & dataInArray(0);  --04/10/2023
    dataOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN -1 downto 0);  --04/10/2023
    tagOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN + TAG_SIZE -1 downto DATA_SIZE_IN);  --04/10/2023

    process (mux_sel, fifo_out, tagged_data_in) is -- dataInArray) is --, tag_fifo_out, tagInArray) is
        begin
            if (mux_sel = '1') then
                tagged_data_out(0) <= fifo_out;
                --tagOutArray(0) <= tag_fifo_out;   -- 08/08/2023
            else
                tagged_data_out(0) <= tagged_data_in(0);
                --tagOutArray(0) <= tagInArray(0);   -- 08/08/2023
            end if;
    end process;

    --process(pValidArray, fifo_valid) is --, tagInArray) is
    --begin
    --    if (pValidArray(0) or fifo_valid) then
    --        tagOutArray(0) <= tagInArray(0);
    --    end if;
    --end process;

    validArray(0) <= pValidArray(0) or fifo_valid;    --fifo_valid is 0 only if fifo is empty
    readyArray(0) <= fifo_ready or nReadyArray(0);
    fifo_pvalid <= pValidArray(0) and (not nReadyArray(0) or fifo_valid); --store in FIFO if next is not ready or FIFO is already outputting something
    mux_sel <= fifo_valid;

    fifo_nready <= nReadyArray(0);
    fifo_in <= tagged_data_in(0); --dataInArray(0);

    --tag_fifo_in <= tagInArray(0);   -- 08/08/2023

    fifo: entity work.elasticFifoInner(arch) generic map (1, 1, DATA_SIZE_IN + TAG_SIZE, DATA_SIZE_IN + TAG_SIZE, FIFO_DEPTH)
        port map (
        --inputs
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => fifo_pvalid, 
            nReadyArray(0) => fifo_nready,    
            validArray(0) => fifo_valid, 
        --outputs
            readyArray(0) => fifo_ready,   
            dataInArray(0) =>fifo_in,
            dataOutArray(0) => fifo_out
        );

    -- tagOutArray(0) <= tagInArray(0); -- AYA: 05/08/2023: added this

end arch;

--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity transpFIFO is 
    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        FIFO_DEPTH : integer
    );
port (
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end transpFIFO;

architecture arch of transpFIFO is
    signal mux_sel : std_logic;
    signal fifo_valid, fifo_ready : STD_LOGIC;
    signal fifo_pvalid, fifo_nready : STD_LOGIC;
    signal fifo_in, fifo_out: std_logic_vector(DATA_SIZE_IN-1 downto 0);
begin
    

    process (mux_sel, fifo_out, dataInArray) is
        begin
            if (mux_sel = '1') then
                dataOutArray(0) <= fifo_out;
            else
                dataOutArray(0) <= dataInArray(0);
            end if;
    end process;

    validArray(0) <= pValidArray(0) or fifo_valid;    --fifo_valid is 0 only if fifo is empty
    readyArray(0) <= fifo_ready or nReadyArray(0);
    fifo_pvalid <= pValidArray(0) and (not nReadyArray(0) or fifo_valid); --store in FIFO if next is not ready or FIFO is already outputting something
    mux_sel <= fifo_valid;

    fifo_nready <= nReadyArray(0);
    fifo_in <= dataInArray(0);

    fifo: entity work.elasticFifoInner(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN, FIFO_DEPTH)
        port map (
        --inputs
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => fifo_pvalid, 
            nReadyArray(0) => fifo_nready,    
            validArray(0) => fifo_valid, 
        --outputs
            readyArray(0) => fifo_ready,   
            dataInArray(0) =>fifo_in,
            dataOutArray(0) => fifo_out
        );

end arch;

------------------------------------ AYA: 18/09/2023: Initialized fifo to carry the free pool of tags between the TAGGER and UNTAGGER
--------------------------------------------------
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity free_tags_fifo is 
    generic(
        INPUTS        : integer;
        OUTPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        FIFO_DEPTH : integer
    );
port (
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS - 1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS - 1 downto 0));
end free_tags_fifo;

architecture arch of free_tags_fifo is
    signal mux_sel : std_logic;
    signal fifo_valid, fifo_ready : STD_LOGIC;
    signal fifo_pvalid, fifo_nready : STD_LOGIC;
    signal fifo_in, fifo_out: std_logic_vector(DATA_SIZE_IN-1 downto 0);
begin
    

    process (mux_sel, fifo_out, dataInArray) is
        begin
            if (mux_sel = '1') then
                dataOutArray(0) <= fifo_out;
            else
                dataOutArray(0) <= dataInArray(0);
            end if;
    end process;

    validArray(0) <= pValidArray(0) or fifo_valid;    --fifo_valid is 0 only if fifo is empty
    readyArray(0) <= fifo_ready or nReadyArray(0);
    fifo_pvalid <= pValidArray(0) and (not nReadyArray(0) or fifo_valid); --store in FIFO if next is not ready or FIFO is already outputting something
    mux_sel <= fifo_valid;

    fifo_nready <= nReadyArray(0);
    fifo_in <= dataInArray(0);

    fifo: entity work.init_elasticFifoInner(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN, FIFO_DEPTH)
        port map (
        --inputs
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => fifo_pvalid, 
            nReadyArray(0) => fifo_nready,    
            validArray(0) => fifo_valid, 
        --outputs
            readyArray(0) => fifo_ready,   
            dataInArray(0) =>fifo_in,
            dataOutArray(0) => fifo_out
        );

end arch;

------------------------------------------------
---------------------------------------------

--------------------------------------------------------------  read port
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.customTypes.all;


entity load_op is generic( INPUTS : Integer;  OUTPUTS : Integer; ADDRESS_SIZE : Integer;  DATA_SIZE : Integer);
port (
    rst: in std_logic;
    clk: in std_logic;

    --- interface to previous
    pValidArray : in std_logic_vector(0 downto 0);--read requests
    readyArray : out std_logic_vector(0 downto 0); -- ready to process read
    dataInArray: in data_array (0 downto 0)(ADDRESS_SIZE -1 downto 0);

    ---interface to next
    nReadyArray : in std_logic_vector(0 downto 0); -- next component can accept data -- error if i put ARBITER_SIZE here??
    validArray : out std_logic_vector(0 downto 0); --sending data to next component
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE-1 downto 0); -- data to next components

    ---interface to memory
    read_enable: out std_logic;
    read_address: out std_logic_vector(ADDRESS_SIZE -1 downto 0);
    data_from_memory: in std_logic_vector(31 downto 0));

end entity;

architecture arch of load_op is 
signal temp, tempen:std_logic;
signal q0,q1 , enable_internal: std_logic;
signal read_address_internal: data_array(0 downto 0)(ADDRESS_SIZE -1 downto 0);
signal valid_temp: std_logic_vector(0 downto 0);
begin

        read_enable <= valid_temp(0) and nReadyArray(0);
        enable_internal <= valid_temp(0) and nReadyArray(0);
        dataOutArray(0) <= data_from_memory;


buff_n0: entity work.elasticBuffer(arch) generic map (1, 1, ADDRESS_SIZE, ADDRESS_SIZE)
        port map (
        --inputs
            clk => clk,  --clk
            rst => rst,    --reset
            dataInArray(0) => dataInArray(0),   --d_in
            pValidArray(0)=> pValidArray(0),  --p_valid
            nReadyArray(0) => nReadyArray(0), --n_ready
        --outputs
            dataOutArray => read_address_internal, --d_out
            readyArray => readyArray, --ready
            validArray  => valid_temp  --valid
        );

read_address <= read_address_internal(0);

    process(clk, rst) is

        begin

            if (rst = '1') then

                validArray(0)  <= '0';
                  
            elsif (rising_edge(clk)) then
                if (enable_internal= '1') then
                    validArray(0)   <= '1';
                            
                else
                    if (nReadyArray(0) = '1') then
                        validArray(0)  <= '0';
                    end if;
                end if;
                               
            end if;
    end process; 

end architecture;


-- AYA: tagged version: 05/08/2023 -------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity Const_tagged is
Generic (
  SIZE :integer; INPUTS :integer; DATA_SIZE_IN: integer;DATA_SIZE_OUT: integer;
  TAG_SIZE: integer   -- AYA: 05/08/2023: added this 
);
port(
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);

    tagInArray : in data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);

    tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this  

    ReadyArray : out std_logic_vector(0 downto 0);
    ValidArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0));
end Const_tagged;

architecture arch of Const_tagged is
begin
dataOutArray <= dataInArray;
validArray <= pValidArray;
readyArray <= nReadyArray; 

  tagOutArray(0) <= tagInArray(0); -- AYA: 05/08/2023: added this

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE work.customTypes.all;

entity Const is
Generic (
  SIZE :integer; INPUTS :integer; DATA_SIZE_IN: integer;DATA_SIZE_OUT: integer 
);
port(
    clk, rst : in std_logic;  
    dataInArray : in data_array (0 downto 0)(DATA_SIZE_IN-1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);
    ReadyArray : out std_logic_vector(0 downto 0);
    ValidArray : out std_logic_vector(0 downto 0);
    nReadyArray : in std_logic_vector(0 downto 0);
    pValidArray : in std_logic_vector(0 downto 0));
end Const;

architecture arch of Const is
begin
dataOutArray <= dataInArray;
validArray <= pValidArray;
readyArray <= nReadyArray; 
end architecture;

---------------------------------------------------------------------
---------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity write_memory_single_inside is generic( ADDRESS_SIZE : Integer;  DATA_SIZE : Integer);
port (
    clk: in std_logic;

    --- interface to previous
    dataValid: in std_logic; --write requests
    ready: out std_logic; -- ready
    -- need join for address and data! add somewhere
    input_addr: in std_logic_vector(ADDRESS_SIZE -1 downto 0);
    --addrValid: in std_logic;
    data : in std_logic_vector(DATA_SIZE-1 downto 0); -- data from previous that want to write

    ---interface to next
    nReady: in std_logic; -- next component can continue after write
    valid: out std_logic; --sending write confirmation to next component

    ---interface to memory
    write_enable: out std_logic;
    enable: out std_logic;
    write_address: out std_logic_vector(ADDRESS_SIZE -1 downto 0);
    data_to_memory: out std_logic_vector(DATA_SIZE-1 downto 0));

end entity;


architecture arch of write_memory_single_inside is

    begin

       process(clk) is

          begin
              
             if (rising_edge(clk)) then
              
                    write_address <= input_addr;
                              
                    data_to_memory <= data;
                    valid <= dataValid;
                    write_enable <= dataValid and nReady;
                    enable <= dataValid and nReady;
             end if;



    end process; 

ready <= nReady;

 end architecture;



 ---------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.customTypes.all;


entity store_op is generic(  INPUTS: integer; OUTPUTS: integer; ADDRESS_SIZE : Integer;  DATA_SIZE : Integer);
port (
    clk, rst: in std_logic;


    input_addr: in std_logic_vector(ADDRESS_SIZE -1 downto 0);
    dataInArray : in data_array (0 downto 0)(DATA_SIZE -1 downto 0);

    --- interface to previous
    pValidArray : IN std_logic_vector(1 downto 0);
    readyArray : OUT std_logic_vector(1 downto 0);

    ---interface to next
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE -1 downto 0);
    nReadyArray: in std_logic_vector(0 downto 0);
    validArray: out std_logic_vector(0 downto 0); 

    ---interface to memory
    write_enable: out std_logic;
    enable: out std_logic;
    write_address: out std_logic_vector(ADDRESS_SIZE -1 downto 0);
    data_to_memory: out std_logic_vector(DATA_SIZE -1 downto 0));

end entity;


architecture arch of store_op is
    signal single_ready: std_logic;
    signal join_valid: std_logic;
   
    begin

    join_write:   entity work.join(arch) generic map(2)
            port map(   pValidArray,  --pValidArray
                        single_ready,                  --nready                    
                        join_valid,                    --valid          
                        ReadyArray);   --readyarray 


    Write: entity work.write_memory_single_inside (arch) generic map (ADDRESS_SIZE, DATA_SIZE)
        port map( clk, 
              join_valid,    --pvalid
              single_ready,                  --ready
              input_addr,                       --addr0
              dataInArray(0),             --data0
              nReadyArray(0),  --nready
              validArray(0),                  --valid
              write_enable,                  --write enable
              enable,                  --enable
              write_address,             --write address
              data_to_memory);                  --data to memory


 end architecture;

----------------------------------------------------------------
-----------------------------Inj--------------------------------
------- Aya's Elastic Reg that has 1 data input and 1 cond input serving as Reg_en that when raised to 1 passes the data at the input to inside the Reg!

library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity Inj is
    generic(
        INPUTS        : integer;
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray      : in  std_logic_vector(0 downto 0);
        validArray      : out std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)   
        
    );
end Inj;

architecture arch of Inj is

signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);  
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

type mem is array (DATA_SIZE_IN - 1 downto 0) of std_logic;
signal regs : mem;

begin
    process(dataInArray, pValidArray, nReadyArray, condition, tehb_ready)
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;

    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        for I in INPUTS - 2 downto 0 loop
            -- if (the condition refers the Ith data input, condition is valid, and the Ith input is valid), assign input data to output and set the output valid high
            if (unsigned(condition(0)) = to_unsigned(I,condition(0)'length) and pValidArray(0) = '1' and pValidArray(I+1) = '1') then
                tmp_data_out  := unsigned(dataInArray(I));
                tmp_valid_out := '1';
            end if;
            -- set the readyOutArray
            if ((unsigned(condition(0)) = to_unsigned(I,condition(0)'length) and pValidArray(0) = '1' and tehb_ready = '1' and pValidArray(I+1) = '1') or pValidArray(I+1) = '0') then
                readyArray(I+1) <= '1';
            else
                readyArray(I+1) <= '0';
            end if;
        end loop;
        -- set the condtionReady
        if (pValidArray(0) = '0' or (tmp_valid_out = '1' and tehb_ready = '1')) then
            readyArray(0) <= '1';
        else
            readyArray(0) <= '0';
        end if;
        --Assign dataout and validout
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid     <= tmp_valid_out;
    end process;


    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );
end arch;


--------------------------------------------------------------------------------------------
-----------------------------Aya's Special MUX at the loop headers--------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity LoopMux_aya is
    generic(
        INPUTS        : integer;
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray      : in  std_logic_vector(0 downto 0);
        validArray      : out std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
        
    );
end LoopMux_aya;

architecture arch of LoopMux_aya is

signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

----- AYA's variables
type state_type is (INIT, ITER);
signal state, nextstate : state_type;

begin
    ------------ AYA: 20/02/2023:  Adding 2 states 
    process(clk, rst)
    begin
        if (rst = '1') then
            state <= INIT;
        elsif (rising_edge(clk)) then
            state <= nextstate;
        end if;
    end process;
    ------------------------------------------------- END of Aya's modifications

    process(state, dataInArray, pValidArray, nReadyArray, condition, tehb_ready) 
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        
        nextstate <= state;

        case state is
            when INIT =>
                -- Keep waiting for a valid token at the in0 of the MUX and do not look at the condition!!
                if(pValidArray(1) = '1') then
                    tmp_data_out  := unsigned(dataInArray(0));
                    tmp_valid_out := '1';
                    nextstate <= ITER;
                else
                    nextstate <= INIT;
                end if;

                -- My philosophy for in0 is that I consume it in this state, so its readiness is determined both by its validity and by the readiness of the tehb internal buffering
                if ((tehb_ready = '1' and pValidArray(1) = '1') or pValidArray(1) = '0') then
                    readyArray(1) <= '1';
                else
                    readyArray(1) <= '0';
                end if;
                -- My philosophy for in1 is that I never look at it in this state, so its ready will be guided by the validity of its output (i.e., if it has a valid token, lower ready because you still did not consume what you have and if it has no valid token, raise ready to allow for receiving a valid token which will be needed in the next state)
                if (pValidArray(2) = '0') then
                    readyArray(2) <= '1';
                else
                    readyArray(2) <= '0';
                end if;

                -- My philosophy here is that in this state, I do not look at the condition input, its ready will be guided by the validity of its output (i.e., if it has a valid token, lower ready because you still did not consume what you have and if it has no valid token, raise ready to allow for receiving a valid token which will be needed in the next state)
                if(pValidArray(0) = '0' or (tmp_valid_out = '1' and tehb_ready = '1')) then
                    readyArray(0) <= '1';
                else
                    readyArray(0) <= '0';
                end if;


                ------------------------------------------- THe following commented code worked for INIT, but discarded the last "leftover" token
                -- Must wait for a valid token at the condition
                    -- first, we hope the condition is 1 to take from the in1 of the MUX
                --if (unsigned(condition(0)) = 0 and pValidArray(0) = '1' and pValidArray(1) = '1') then
                --    tmp_data_out  := unsigned(dataInArray(0));
                --    tmp_valid_out := '1';
                --    nextstate <= ITER;

                    -- second, if the condition is 0, do not look at the in0 of the MUX at all and do not send anything to the output and move to INIT state!
                --elsif (unsigned(condition(0)) = 1 and pValidArray(0) = '1' and pValidArray(2) = '1') then
                --    tmp_data_out  := unsigned(dataInArray(1));
                --    tmp_valid_out := '1';
                --    nextstate <= INIT;
                --end if;

                -- set the readyOutArray
                --if ((unsigned(condition(0)) = 0 and pValidArray(0) = '1' and tehb_ready = '1' and pValidArray(1) = '1') or pValidArray(1) = '0') then
                --    readyArray(1) <= '1';
                --else
                --    readyArray(1) <= '0';
                --end if;

                --if ((unsigned(condition(0)) = 1 and pValidArray(0) = '1' and tehb_ready = '1' and pValidArray(2) = '1') or pValidArray(2) = '0') then
                --    readyArray(2) <= '1';
                --else
                --    readyArray(2) <= '0';
                --end if;

                -- set the condtionReady
                -- AYAAAA: 22/02/2023: Apparently this is the problem with the simulation of passing multiple instances of execution because the output was never valid and pValid is 1 so the ready was never raised to '1'!!
                        -- Because the problem I have there is that the condition becomes never ready again!!!
                            -- YESSS! IT was the problem! AND I FIXED IT by adding the last OR!!
                --if (pValidArray(0) = '0' or (tmp_valid_out = '1' and tehb_ready = '1') or (unsigned(condition(0)) = 1 and pValidArray(0) = '1' and tmp_valid_out = '0')) then
                --    readyArray(0) <= '1';
                --else
                --    readyArray(0) <= '0';
                --end if;
                ----------------------------------------------------------------------

            when ITER =>
                -- Must wait for a valid token at the condition
                    -- first, we hope the condition is 1 to take from the in1 of the MUX
                if (unsigned(condition(0)) = 1 and pValidArray(0) = '1' and pValidArray(2) = '1') then
                    tmp_data_out  := unsigned(dataInArray(1));
                    tmp_valid_out := '1';
                    nextstate <= ITER;

                    -- second, if the condition is 0, do not look at the in0 of the MUX at all and do not send anything to the output and move to INIT state!
                elsif (unsigned(condition(0)) = 0 and pValidArray(0) = '1') then
                    nextstate <= INIT;
                end if;


                -- My philosophy for in0 is that I never look at it in this state, so its ready will be guided by the validity of its output (i.e., if it has a valid token, lower ready because you still did not consume what you have and if it has no valid token, raise ready to allow for receiving a valid token which will be needed in the next state)......
                if (pValidArray(1) = '0') then -- and (pValidArray(0) = '0' or (pValidArray(0) = '1' and unsigned(condition(0)) = 0))) then
                    readyArray(1) <= '1';
                else
                    readyArray(1) <= '0';
                end if;

                -- My philosophy for in1 is that I pass it to the output depending on the value of the condition, so I need to check the value and valdidity of the condition, the readiness of the tehb (to make sure that this token will be consumed), OR based on the validity of the token......
                if ((unsigned(condition(0)) = 1 and pValidArray(0) = '1' and tehb_ready = '1' and pValidArray(2) = '1') or pValidArray(2) = '0') then
                    readyArray(2) <= '1';
                else
                    readyArray(2) <= '0';
                end if;

                 -- My philosophy for the condition is that based on its value we either decide to produce an output token or not. If its value is 1, produce an output so readiness should be a funciton of the readiness of tehb. If its value is 0, we do not output anything so we do not care of the value of tehb
                if(pValidArray(0) = '0' or (unsigned(condition(0)) = 1 and pValidArray(0) = '1' and tmp_valid_out = '1' and tehb_ready = '1')) then
                    readyArray(0) <= '1';
                else
                    readyArray(0) <= '0';
                end if;
                         
        end case;


        --Assign dataout and validout
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid     <= tmp_valid_out;
    end process;


    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );
end arch;


----------------------------------------------------------------
--------------------------------------------------------gian_mux
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity curr_gian_mux is
    generic(
        INPUTS        : integer; --supports only two inputs and one condition (so put 3)
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer;
        THRD_NUM       : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray      : in  std_logic_vector(0 downto 0);
        validArray      : out std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
        
    );
end curr_gian_mux;

architecture arch of curr_gian_mux is
signal dataIn_0_buff : data_array(THRD_NUM - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
signal dataIn_1_buff : data_array(THRD_NUM - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

begin

horrible_mono_process: process(clk, rst)
variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
variable tmp_valid_out : std_logic;
variable count : integer;
variable accept_in0 : integer := 1;
variable accept_in1 : integer := 0;
variable index_0_buff : integer := 0;
variable index_1_buff : integer := 0;
variable index_cond_buff : integer := 0;
begin
    if(rst = '1') then
        dataIn_0_buff <= (others => (others => '0'));
        index_0_buff := 0;
        dataIn_1_buff <= (others => (others => '0'));
        index_1_buff := 0;
        index_cond_buff := 0;
        count := 0;
        tmp_valid_out := '0';
        tmp_data_out  := unsigned(dataInArray(0));
        readyArray <= (others => '0');
    elsif rising_edge(clk) then
        --output
        tmp_valid_out := '0';
        tmp_data_out  := unsigned(dataInArray(0));
        if(nReadyArray(0) = '1') then
            if(index_0_buff > 0 and accept_in0 = 1) then --there is something stored in the in_0_buffer
                tmp_data_out := unsigned(dataIn_0_buff(0));
                tmp_valid_out := '1';
                index_0_buff := index_0_buff - 1;
                count := count + 1;
                if(count = THRD_NUM) then
                    count := 0;
                    accept_in0 := 0;
                    accept_in1 := 1;
                end if;
                for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                    dataIn_0_buff(I) <= dataIn_0_buff(I+1);
                end loop;
                dataIn_0_buff(THRD_NUM - 1) <= (others => '0');
            elsif (index_1_buff > 0 and index_cond_buff > 0 and accept_in1 = 1) then
                tmp_data_out := unsigned(dataIn_1_buff(0));
                tmp_valid_out := '1';
                index_1_buff := index_1_buff - 1;
                index_cond_buff := index_cond_buff - 1;
                for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                    dataIn_1_buff(I) <= dataIn_1_buff(I+1);
                end loop;
                dataIn_1_buff(THRD_NUM - 1) <= (others => '0');
            end if;
        end if;
        --dataIn_0_buff
        if(pValidArray(1) = '1' and index_0_buff < THRD_NUM and readyArray(1) = '1') then  
            dataIn_0_buff(index_0_buff) <= dataInArray(0);
            index_0_buff := index_0_buff + 1;
        end if;
        --dataIn_1_buff
        if(pValidArray(2) = '1' and index_1_buff < THRD_NUM) then  
            dataIn_1_buff(index_1_buff) <= dataInArray(1);
            index_1_buff := index_1_buff + 1;
        end if;
        --cond_buff
        if(pValidArray(0) = '1' and index_cond_buff < THRD_NUM) then
            if(to_integer(unsigned(condition(0))) = 0) then
                count := count + 1;
            else
                index_cond_buff := index_cond_buff + 1;
            end if;
            if(count = THRD_NUM) then
                count := 0;
                accept_in0 := 1;
                accept_in1 := 0;
            end if;
        end if;
    end if;
    --tehb inputs
    tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
    tehb_pvalid  <= tmp_valid_out;
    --ready
    if(index_0_buff = THRD_NUM) then
        readyArray <= "101";
    else
        readyArray <= "111";
    end if;
end process;


tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );

end architecture;

----------------------------------------------------------------
-----------------------------AYA's: 01/10/2023: Aligner_mux --------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity aligner_mux is
    generic(
        INPUTS        : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        TAG_SIZE: integer   
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);

        tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0); 

        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray      : in  std_logic_vector(0 downto 0);
        validArray      : out std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(INPUTS -1 downto 0);
        tag_condition     : in  data_array(0 downto 0)(TAG_SIZE - 1 downto 0)  
        
    );
end aligner_mux;

architecture arch of aligner_mux is

signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

begin

    process(dataInArray, pValidArray, nReadyArray, tag_condition, tehb_ready)  
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
 
        for I in INPUTS - 2 downto 0 loop
            --if (the condition refers the Ith data input, condition is valid, and the Ith input is valid), assign input data to output and set the output valid high
            if (unsigned(tag_condition(0)) = to_unsigned(I,tag_condition(0)'length) and pValidArray(0) = '1' and pValidArray(I+1) = '1') then
                tmp_data_out  := unsigned(dataInArray(I));
                tmp_valid_out := '1';
            end if;
            -- set the readyOutArray
            if ((unsigned(tag_condition(0)) = to_unsigned(I,tag_condition(0)'length) and pValidArray(0) = '1' and tehb_ready = '1' and pValidArray(I+1) = '1') or pValidArray(I+1) = '0') then
                readyArray(I+1) <= '1';
            else
                readyArray(I+1) <= '0';
            end if;
        end loop;

        -- set the condtionReady
        if (pValidArray(0) = '0' or (tmp_valid_out = '1' and tehb_ready = '1')) then
            readyArray(0) <= '1';
        else
            readyArray(0) <= '0';
        end if;

        --Assign dataout and validout
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid     <= tmp_valid_out;
    end process;

    tagOutArray(0) <= tag_condition(0);

    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );

end arch;


----------------------------------------------------------------
-----------------------------Orig_MUX-- AYA's tagged version 05/08/2023 --------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity mux_tagged is
    generic(
        INPUTS        : integer;
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer;
        TAG_SIZE: integer   -- AYA: 05/08/2023: added this);
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);

        tagInArray : in data_array (INPUTS -1 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: has the 3 inputs following the convention of pvalid 

        tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray      : in  std_logic_vector(0 downto 0);
        validArray      : out std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
        
    );
end mux_tagged;

architecture arch of mux_tagged is

signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

signal tehb_tag_in  : std_logic_vector(TAG_SIZE - 1 downto 0);


begin

    process(dataInArray, pValidArray, nReadyArray, condition, tehb_ready)  
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
 
        for I in INPUTS - 2 downto 0 loop
            --if (the condition refers the Ith data input, condition is valid, and the Ith input is valid), assign input data to output and set the output valid high
            if (unsigned(condition(0)) = to_unsigned(I,condition(0)'length) and pValidArray(0) = '1' and pValidArray(I+1) = '1') then
                tmp_data_out  := unsigned(dataInArray(I));
                tmp_valid_out := '1';
            end if;
            -- set the readyOutArray
            if ((unsigned(condition(0)) = to_unsigned(I,condition(0)'length) and pValidArray(0) = '1' and tehb_ready = '1' and pValidArray(I+1) = '1') or pValidArray(I+1) = '0') then
                readyArray(I+1) <= '1';
            else
                readyArray(I+1) <= '0';
            end if;
        end loop;

        -- set the condtionReady
        if (pValidArray(0) = '0' or (tmp_valid_out = '1' and tehb_ready = '1')) then
            readyArray(0) <= '1';
        else
            readyArray(0) <= '0';
        end if;


        --Assign dataout and validout
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid     <= tmp_valid_out;
    end process;

    -- 08/08/2023: made the TEHB tagged
    tehb_tag_in <= tagInArray(0);

    tehb1: entity work.TEHB_tagged(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN, TAG_SIZE)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            tagInArray(0) => tehb_tag_in,
            dataOutArray(0) => dataOutArray(0),
            tagOutArray(0) => tagOutArray(0)
        );

   -- tagOutArray(0) <= tagInArray(0); -- AYA: 05/08/2023: added this.. I propagate the tag to the output from the condition input 

end arch;

----------------------------------------------------------------
-----------------------------Orig_MUX--------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity mux is
    generic(
        INPUTS        : integer;
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray      : in  std_logic_vector(0 downto 0);
        validArray      : out std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
        
    );
end mux;

architecture arch of mux is

signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;

begin


    process(dataInArray, pValidArray, nReadyArray, condition, tehb_ready)  
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
 
        for I in INPUTS - 2 downto 0 loop
            --if (the condition refers the Ith data input, condition is valid, and the Ith input is valid), assign input data to output and set the output valid high
            if (unsigned(condition(0)) = to_unsigned(I,condition(0)'length) and pValidArray(0) = '1' and pValidArray(I+1) = '1') then
                tmp_data_out  := unsigned(dataInArray(I));
                tmp_valid_out := '1';
            end if;
            -- set the readyOutArray
            if ((unsigned(condition(0)) = to_unsigned(I,condition(0)'length) and pValidArray(0) = '1' and tehb_ready = '1' and pValidArray(I+1) = '1') or pValidArray(I+1) = '0') then
                readyArray(I+1) <= '1';
            else
                readyArray(I+1) <= '0';
            end if;
        end loop;

        -- set the condtionReady
        if (pValidArray(0) = '0' or (tmp_valid_out = '1' and tehb_ready = '1')) then
            readyArray(0) <= '1';
        else
            readyArray(0) <= '0';
        end if;


        --Assign dataout and validout
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid     <= tmp_valid_out;
    end process;


    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );
end arch;

-----------------------------------------------------------------------gian_mux_fifo1
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity LoopMuxFIFO is
    generic(
        INPUTS        : integer; --supports only two inputs and one condition (so put 3)
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer;
        THRD_NUM      : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
        
    );
end LoopMuxFIFO;
architecture arch of LoopMuxFIFO is
    signal tehb_pvalid, tehb_ready : std_logic;
    signal tehb_data_in : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
    signal fifo_0_valid, fifo_1_valid, fifo_0_nReady, fifo_1_nReady, fifo_0_ready, fifo_1_ready : std_logic;
    signal fifo_0_dataOut, fifo_1_dataOut : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
    signal state : std_logic;

    constant zero : std_logic_vector(COND_SIZE-1 downto 0) := (others => '0');
    constant one : std_logic_vector(COND_SIZE-1 downto 0) := (COND_SIZE-1 downto 1 => '0', others => '1');

    begin

    readyArray(1) <= fifo_0_ready;
    readyArray(2) <= '1';

    fifo_0_nReady <= (not state) and tehb_ready;
    fifo_1_nready <= state and tehb_ready;

    with state select tehb_pvalid <=
        fifo_0_valid when '0',
        fifo_1_valid when others;

    with state select tehb_data_in <=
        fifo_0_dataOut when '0',
        fifo_1_dataOut when others;

    fifo_0: entity work.transpFIFO(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN, THRD_NUM)
    port map (
    --inputspValidArray
        clk => clk, 
        rst => rst, 
        pValidArray(0)  => pValidArray(1), 
        nReadyArray(0) => fifo_0_nReady,    
        validArray(0) => fifo_0_valid, 
    --outputs
        readyArray(0) => fifo_0_ready,   
        dataInArray(0) => dataInArray(0),
        dataOutArray(0) => fifo_0_dataOut
    );

    fifo_1: entity work.transpFIFO(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN, THRD_NUM)
    port map (
    --inputspValidArray
        clk => clk, 
        rst => rst, 
        pValidArray(0)  => pValidArray(2), 
        nReadyArray(0) => fifo_1_nReady,    
        validArray(0) => fifo_1_valid, 
    --outputs
        readyArray(0) => fifo_1_ready,   
        dataInArray(0) => dataInArray(1),
        dataOutArray(0) => fifo_1_dataOut
    );

    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );

    count_state_process : process(clk, rst)
    variable count_in0 : integer := 0;
    variable count_0_cond : integer := 0;
    variable count_1_cond : integer := 0;
    variable count_in1 : integer := 0;
    begin
        if(rst = '1') then
            state <= '0';
            count_in0 := 0;
            count_0_cond := 0;
            count_1_cond := 0;
            count_in1 := 0;
        elsif rising_edge(clk) then
            if(state = '0' and tehb_ready = '1' and fifo_0_valid = '1') then --count the tokens output from in0
                count_in0 := count_in0 + 1;
            end if;
            if(state = '1' and tehb_ready = '1' and fifo_1_valid = '1') then --count the tokens output from in1
                count_in1 := count_in1 + 1;
            end if;
            if(pValidArray(0) = '1' and condition(0) = zero and readyArray(0) = '1') then  --count the 0-condition received 
                count_0_cond := count_0_cond + 1;
            end if;
            if(pValidArray(0) = '1' and condition(0) = one and readyArray(0) = '1') then --count the 1-condition received
                count_1_cond := count_1_cond + 1;
            end if;
            if(count_0_cond = count_in0 and count_in1 < count_1_cond) then
                readyArray(0) <= '0';
            else
                readyArray(0) <= '1';
            end if;
            if(state = '0' and (count_in0 = THRD_NUM or (count_in0 > 0 and fifo_0_valid = '0'))) then --transition to state 1
                state <= '1';
            end if;
            if(state = '1' and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_1_cond := 0;
                count_in1 := 0;
                count_in0 := 0;
                count_0_cond := 0;
                state <= '0';
            end if;
        end if;
    end process;

end;

---------------------------------------------------------------------
---------------------------------------------gian_mux_no_fifo
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity LoopMux is
    generic(
        INPUTS        : integer; --supports only two inputs and one condition (so put 3)
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer;
        THRD_NUM      : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
    );
end LoopMux;

architecture arch of LoopMux is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;
signal count_in0    : unsigned(31 downto 0);
signal count_in1    : unsigned(31 downto 0); 
signal count_0_cond : unsigned(31 downto 0);
signal count_1_cond : unsigned(31 downto 0);
type state_type is (INIT, ITER);
signal state : state_type;
constant zero : std_logic_vector(COND_SIZE-1 downto 0) := (others => '0');


begin

    process(state, dataInArray, pValidArray, nReadyArray, condition, tehb_ready, count_in0) 
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        case state is
            when INIT =>
                if(pValidArray(1) = '1' and not((count_in0 = THRD_NUM or (count_in0 > 0 and pValidArray(1) = '0')))) then
                    tmp_data_out  := unsigned(dataInArray(0));
                    tmp_valid_out := '1';
                end if;
                --if ((tehb_ready = '1' and pValidArray(1) = '1') or pValidArray(1) = '0') then
                --    readyArray(1) <= '1';
                --else
                --    readyArray(1) <= '0';
                --end if;

                --Due to synch, do not use pvalid!
                if (tehb_ready = '1' and not((count_in0 = THRD_NUM or (count_in0 > 0 and pValidArray(1) = '0')))) then
                   readyArray(1) <= '1';
                else
                   readyArray(1) <= '0';
                end if;
                if (pValidArray(2) = '0') then
                    readyArray(2) <= '1';
                else
                    readyArray(2) <= '0';
                end if;

            when ITER =>
                if (pValidArray(2) = '1') then
                    tmp_data_out  := unsigned(dataInArray(1));
                    tmp_valid_out := '1';
                end if;
                
                --Due to synch, do not use pvalid!
                readyArray(1) <= '0';

                if ((tehb_ready = '1' and pValidArray(2) = '1') or pValidArray(2) = '0') then
                    readyArray(2) <= '1';
                else
                    readyArray(2) <= '0';
                end if;
                         
        end case;
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid  <= tmp_valid_out;
    end process;


    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );


    count_in0_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_in0 <= (others => '0');
        elsif rising_edge(clk) then
            if(state = INIT and tehb_ready = '1' and tehb_pvalid = '1') then --count the tokens output from in0
                count_in0 <= count_in0 + 1;
            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_in0 <= (others => '0');
            end if;
        end if;
    end process;

    count_in1_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_in1 <= (others => '0');
        elsif rising_edge(clk) then
            if(state = ITER and tehb_ready = '1' and tehb_pvalid = '1') then --count the tokens output from in1
                count_in1 <= count_in1 + 1;
            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_in1 <= (others => '0');
            end if;
        end if;
    end process;

    count_0_cond_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_0_cond <= (others => '0');
        elsif rising_edge(clk) then
            if(pValidArray(0) = '1' and condition(0) = zero and readyArray(0) = '1') then  --count the 0-condition received 
                count_0_cond <= count_0_cond + 1;
            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_0_cond <= (others => '0');
            end if;
        end if;
    end process;

    count_1_cond_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_1_cond <= (others => '0');
        elsif rising_edge(clk) then
            if(pValidArray(0) = '1' and to_integer(unsigned(condition(0))) = 1 and readyArray(0) = '1') then --count the 1-condition received
            count_1_cond <= count_1_cond + 1;
            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_1_cond <= (others => '0');
            end if;
        end if;
    end process;

    state_proc : process (clk, rst)
    begin
        if(rst = '1') then
            state <= INIT;
        elsif rising_edge(clk) then
            if(state = INIT and (count_in0 = THRD_NUM or (count_in0 > 0 and pValidArray(1) = '0'))) then --transition to state 1
                state <= ITER;
            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                state <= INIT;
            end if;
        end if;
    end process;

    ready_0_proc : process(count_0_cond, count_in0, count_in1, count_1_cond, state)
    begin
        if((count_0_cond = count_in0 and count_in1 < count_1_cond) or (count_0_cond = count_in0 and count_in1 = count_1_cond and state = ITER)) then
            readyArray(0) <= '0';
        else
            readyArray(0) <= '1';
        end if;
    end process;

end;



-------------------------------------------------------------------------------
-----------------------------------------------------------------------gian_mux_no_fifo
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity Aya_messed_up_LoopMux is
    generic(
        INPUTS        : integer; --supports only two inputs and one condition (so put 3)
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer;
        THRD_NUM      : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
    );
end Aya_messed_up_LoopMux;
architecture arch of Aya_messed_up_LoopMux is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;
signal count_in0    : unsigned(31 downto 0);  
signal count_in1    : unsigned(31 downto 0); 
signal count_0_cond : unsigned(31 downto 0);
signal count_1_cond : unsigned(31 downto 0);
type state_type is (INIT, ITER);
signal state : state_type;
constant zero : std_logic_vector(COND_SIZE-1 downto 0) := (others => '0');


begin

    state_proc : process (clk, rst)
    begin
        if(rst = '1') then
            state <= INIT;
        elsif rising_edge(clk) then
            -- AYA: transition to ITER if you have completed N or if you do not currently have a valid input at in0!!
            if(state = INIT and (count_in0 = THRD_NUM or (count_in0 > 0 and pValidArray(1) = '0'))) then 
                state <= ITER;
            end if;
           
            -- AYA: 14/08/2023: go back to INIT there is a valid in0 token and you have not yet reached N OR if you are done
            if((state = ITER) and 
                    ( (count_in0 = count_0_cond and count_in1 = count_1_cond) or (pValidArray(1) = '1' and not(count_in0 = THRD_NUM)) ) 
                ) then
                state <= INIT;
            end if;
        end if;
    end process;

    process(state, dataInArray, pValidArray) 
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        case state is
            when INIT =>
                if(pValidArray(1) = '1') then 
                    tmp_data_out  := unsigned(dataInArray(0));
                    tmp_valid_out := '1';
                end if;

            when ITER =>
                if (pValidArray(2) = '1') then
                    tmp_data_out  := unsigned(dataInArray(1));
                    tmp_valid_out := '1';
                end if;
                -- remember, we no longer match a condition token with in1, we use the condition only for counting
                         
        end case;
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid  <= tmp_valid_out;
    end process;

    count_in0_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_in0 <= (others => '0');
        elsif rising_edge(clk) then
            -- AYA: must check the valid and ready to make sure to count ONLY when the token is outputted and accepted: count the tokens output from in0
            if(state = INIT and tehb_ready = '1' and tehb_pvalid = '1') then 
                count_in0 <= count_in0 + 1;
            end if;
            -- AYA: reset it when in the ITER state but make sure that you are in ITER because you are done and the count of conds matched the inputs
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then 
                count_in0 <= (others => '0');
            end if;
        end if;
    end process;

    count_in1_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_in1 <= (others => '0');
        elsif rising_edge(clk) then
            -- AYA: must check the valid and ready to make sure to count ONLY when the token is outputted and accepted: count the tokens output from in1
            if(state = ITER and tehb_ready = '1' and tehb_pvalid = '1') then 
                count_in1 <= count_in1 + 1;
            end if;
            -- AYA: reset it when you are done and the count of conds matched the inputs and this usually happens in the ITER state
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then 
                count_in1 <= (others => '0');
            end if;
        end if;
    end process;

    count_0_cond_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_0_cond <= (others => '0');
        elsif rising_edge(clk) then
            -- AYA: check valid and ready to make sure that the token is outputted and accepted
            if(pValidArray(0) = '1' and condition(0) = zero and readyArray(0) = '1') then  --count the 0-condition received 
                count_0_cond <= count_0_cond + 1;
            end if;
            -- AYA: reset it when you are done and the count of conds matched the inputs and this usually happens in the ITER state
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_0_cond <= (others => '0');
            end if;
        end if;
    end process;

    count_1_cond_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_1_cond <= (others => '0');
        elsif rising_edge(clk) then
            -- AYA: check valid and ready to make sure that the token is outputted and accepted
            if(pValidArray(0) = '1' and to_integer(unsigned(condition(0))) = 1 and readyArray(0) = '1') then --count the 1-condition received
                count_1_cond <= count_1_cond + 1;
            end if;
            -- AYA: reset it when you are done and the count of conds matched the inputs and this usually happens in the ITER state
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_1_cond <= (others => '0');
            end if;
        end if;
    end process;

    ready_cond_proc : process(count_0_cond, count_in0, count_in1, count_1_cond, state)
    begin
    -- AYA: You are not ready if you have completed the false cond of in0 and have exceeded the true cond count of the received in1
            -- OR if you have completed the counts, but have still not transitioned to the INIT state from the ITER state
            -- DO WE REALLY NEED WHAT COMES AFTER THE OR??? I WILL TRY TO COMMENT IT OUT???
       -- if((count_0_cond = count_in0 and count_in1 < count_1_cond) or (count_0_cond = count_in0 and count_in1 = count_1_cond and state = ITER)) then
        -- AYA: 14/08/2023:
        if((count_0_cond = count_in0 and count_in1 < count_1_cond) or (count_0_cond = count_in0 and count_in1 = count_1_cond and state = ITER)) then
            readyArray(0) <= '0';
        else
            readyArray(0) <= '1';
        end if;
    end process;

    ready_in0_proc : process(state, tehb_ready, pValidArray)--count_in0, pValidArray, tehb_ready)
    begin
        --if (tehb_ready = '1' and not((count_in0 = THRD_NUM or (count_in0 > 0 and pValidArray(1) = '0')))) then 
        if( (state = INIT and tehb_ready = '1')) then -- or pValidArray(1) = '0') then 
            readyArray(1) <= '1';
        else
            readyArray(1) <= '0';
        end if;
    end process;

    ready_in1_proc : process(state, pValidArray, tehb_ready)
    begin
        if( (state = ITER and tehb_ready = '1' and pValidArray(2) = '1') or pValidArray(2) = '0') then 
            readyArray(2) <= '1';
        else
            readyArray(2) <= '0';
        end if;
    end process;

    tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );

end;

-------------------------------------------------------------------------------
-----------------------------------------------------------------------gian_mux_no_fifo  AYA'S TAGGED VERSION OF IT
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity LoopMux_tagged is
    generic(
        INPUTS        : integer; --supports only two inputs and one condition (so put 3)
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer;
        THRD_NUM      : integer;
        TAG_BITSIZE   : integer  -- AYA: 03/08/2023
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);

        tagInArray : in data_array (0 downto 0)(TAG_BITSIZE - 1 downto 0); -- AYA: 08/08/2023: added this: associated only with the dataInArray of in1!

        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);

        tagOutArray : out data_array (0 downto 0)(TAG_BITSIZE - 1 downto 0); -- AYA: 08/08/2023: added this

        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0);   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
        tag_order_data : out std_logic_vector(TAG_BITSIZE - 1 downto 0); -- AYA: 03/08/2023
        tag_order_valid : out std_logic_vector(0 downto 0);
        tag_order_nReady : in std_logic_vector(0 downto 0)
    );
end LoopMux_tagged;
architecture arch of LoopMux_tagged is
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);

signal tehb_tag_in : std_logic_vector(TAG_BITSIZE - 1 downto 0);

signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;
signal count_in0    : unsigned(TAG_BITSIZE downto 0); --AYA: it is not TAG_BITSIZE -1 since the count can reach THRD_NUM so it has to have enough bits
signal count_in1    : unsigned(31 downto 0); 
signal count_0_cond : unsigned(TAG_BITSIZE downto 0);
signal count_1_cond : unsigned(31 downto 0);
type state_type is (INIT, ITER);
signal state : state_type;
constant zero : std_logic_vector(COND_SIZE-1 downto 0) := (others => '0');


begin

    process(state, dataInArray, pValidArray, nReadyArray, condition, tehb_ready, count_in0) 
        variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
        variable tmp_valid_out : std_logic;
        variable tmp_valid_tag : std_logic;
    begin
        tmp_data_out  := unsigned(dataInArray(0));
        tmp_valid_out := '0';
        tmp_valid_tag := '0';  -- AYA: 03/08/2023
        case state is
            when INIT =>
                if(pValidArray(1) = '1' and not((count_in0 = THRD_NUM or (count_in0 > 0 and pValidArray(1) = '0')))) then  
                    tmp_data_out  := unsigned(dataInArray(0));
                    tmp_valid_out := '1';
                    tmp_valid_tag := '1';
                end if;

                --Due to synch, do not use pvalid!
                if (tehb_ready = '1' and not((count_in0 = THRD_NUM or (count_in0 > 0 and pValidArray(1) = '0')))
                    and tag_order_nReady(0) = '1') then -- AYA: 03/08/2023: added the extra and to affect the in0 readiness if the tag output is not ready to receive!
                   readyArray(1) <= '1';
                else
                   readyArray(1) <= '0';
                end if;
                if (pValidArray(2) = '0') then
                    readyArray(2) <= '1';
                else
                    readyArray(2) <= '0';
                end if;

            when ITER =>
                if (pValidArray(2) = '1') then -- remember, we no longer match a condition token with in1, we use the condition only for counting purposes for states transitions
                    tmp_data_out  := unsigned(dataInArray(1));
                    tmp_valid_out := '1';
                end if;
                
                --Due to synch, do not use pvalid!
                readyArray(1) <= '0';   -- blindly not ready to accept anything from in0 in this state

                if ((tehb_ready = '1' and pValidArray(2) = '1') or pValidArray(2) = '0') then
                    readyArray(2) <= '1';
                else
                    readyArray(2) <= '0';
                end if;
                         
        end case;
        tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
        tehb_pvalid  <= tmp_valid_out;
        tag_order_valid(0) <= tmp_valid_tag;   -- AYA: valid only when in0 outputs a token 
    end process;


     -- 08/08/2023: calculating the tagOutArray (tag associated with every data outputted from the LoopMux)
    tag_out_proc : process(state, count_in0, tagInArray)
    --variable tmp_tag_out  : unsigned(TAG_BITSIZE - 1 downto 0);
    begin
        case state is
            when INIT =>
                --tmp_tag_out := count_in0(TAG_BITSIZE - 1 downto 0);  
                tehb_tag_in <= std_logic_vector(count_in0(TAG_BITSIZE - 1 downto 0));
            when ITER =>
                --tmp_tag_out :=  to_unsigned((to_integer(count_in1) mod THRD_NUM), tmp_tag_out'length); 
                tehb_tag_in <= tagInArray(0);
        end case;
        --tagOutArray(0) <= std_logic_vector(tmp_tag_out);
    end process;

    -- AYA: 09/08/2023: changed it to tagged
    tehb1: entity work.TEHB_tagged(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN, TAG_BITSIZE)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            tagInArray(0) => tehb_tag_in,
            dataOutArray(0) => dataOutArray(0),
            tagOutArray(0) => tagOutArray(0)
        );

    count_in0_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_in0 <= (others => '0');
        elsif rising_edge(clk) then
            if(state = INIT and tehb_ready = '1' and tehb_pvalid = '1') then --count the tokens output from in0
                count_in0 <= count_in0 + 1;

            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_in0 <= (others => '0');
            end if;
        end if;
    end process;

    -- AYA: I suspect that the new output tag will be = to count_in0..
    tag_order_data <= std_logic_vector(count_in0(TAG_BITSIZE - 1 downto 0));  

    count_in1_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_in1 <= (others => '0');
        elsif rising_edge(clk) then
            if(state = ITER and tehb_ready = '1' and tehb_pvalid = '1') then --count the tokens output from in1
                count_in1 <= count_in1 + 1;
            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_in1 <= (others => '0');
            end if;
        end if;
    end process;

    count_0_cond_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_0_cond <= (others => '0');
        elsif rising_edge(clk) then
            if(pValidArray(0) = '1' and condition(0) = zero and readyArray(0) = '1') then  --count the 0-condition received 
                count_0_cond <= count_0_cond + 1;
            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_0_cond <= (others => '0');
            end if;
        end if;
    end process;

    count_1_cond_proc : process (clk, rst)
    begin
        if(rst = '1') then
            count_1_cond <= (others => '0');
        elsif rising_edge(clk) then
            if(pValidArray(0) = '1' and to_integer(unsigned(condition(0))) = 1 and readyArray(0) = '1') then --count the 1-condition received
            count_1_cond <= count_1_cond + 1;
            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                count_1_cond <= (others => '0');
            end if;
        end if;
    end process;

    state_proc : process (clk, rst)
    begin
        if(rst = '1') then
            state <= INIT;
        elsif rising_edge(clk) then
            if(state = INIT and (count_in0 = THRD_NUM or (count_in0 > 0 and pValidArray(1) = '0'))) then --transition to state 1
                state <= ITER;
            end if;
            if(state = ITER and count_in0 = count_0_cond and count_in1 = count_1_cond) then --transition to state 0
                state <= INIT;
            end if;
        end if;
    end process;

    ready_0_proc : process(count_0_cond, count_in0, count_in1, count_1_cond, state)
    begin
        if((count_0_cond = count_in0 and count_in1 < count_1_cond) or (count_0_cond = count_in0 and count_in1 = count_1_cond and state = ITER)) then
            readyArray(0) <= '0';
        else
            readyArray(0) <= '1';
        end if;
    end process;

end;

-------------------------------------------------------------------------------
-----------------------------------------------------------------------AYa's simplified reorder_buffer: 28/09/2023
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity ROB is
    generic(
        BUFF_SIZE : integer;  -- the size of the internal buffer (should be = to the number of threads running in parallel)
        DATA_SIZE : integer;
        TAG_SIZE : integer    -- number of bits of the tag (will be log(number of threads) = log(BUFF_SIZE) )
    );
    port(
        clk, rst      : in  std_logic;

        dataInArray   : in  data_array(0 downto 0)(DATA_SIZE - 1 downto 0);  -- 2 input ports
        tagIn         : in std_logic_vector(TAG_SIZE - 1 downto 0);   

        target_tagIn  : in std_logic_vector(TAG_SIZE - 1 downto 0);  -- Separated it from dataInArray because it has a different dimension

        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE - 1 downto 0);  -- 1 output port

        pValidArray   : in  std_logic_vector(1 downto 0);  -- My convention is pValid(0) is for target_tagIn and pValid(1) is for dataInArray
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(1 downto 0) -- My convention is readyArray(0) is for target_tagIn and readyArray(1) is for dataInArray
    );
end ROB;

architecture arch of ROB is


   -- type ROB_Memory is array (0 to BUFF_SIZE - 1) of STD_LOGIC_VECTOR (TAG_SIZE-1 downto 0);
   -- signal Memory : FIFO_Memory;


begin
    dataOutArray(0) <= dataInArray(0);
    validArray(0) <= pValidArray(0);
    readyArray(0) <= nReadyArray(0);
    readyArray(1) <= nReadyArray(0);
   
   
end;

-----------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-----------------------------------------------------------------------AYa's simplified reorder_buffer: 03/08/2023
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity OLD_ROB is
    generic(
        BUFF_SIZE : integer;  -- the size of the internal buffer (should be = to the number of threads running in parallel)
        DATA_SIZE : integer;
        TAG_SIZE : integer    -- number of bits of the tag (will be log(number of threads) = log(BUFF_SIZE) )
    );
    port(
        clk, rst      : in  std_logic;

        dataInArray   : in  data_array(0 downto 0)(DATA_SIZE - 1 downto 0);  -- 2 input ports
        tagIn         : in std_logic_vector(TAG_SIZE - 1 downto 0);   

        target_tagIn  : in std_logic_vector(TAG_SIZE - 1 downto 0);  -- Separated it from dataInArray because it has a different dimension

        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE - 1 downto 0);  -- 1 output port

        pValidArray   : in  std_logic_vector(1 downto 0);  -- My convention is pValid(0) is for target_tagIn and pValid(1) is for dataInArray
        nReadyArray   : in  std_logic_vector(0 downto 0);
        validArray    : out std_logic_vector(0 downto 0);
        readyArray    : out std_logic_vector(1 downto 0) -- My convention is readyArray(0) is for target_tagIn and readyArray(1) is for dataInArray
    );
end OLD_ROB;

architecture arch of OLD_ROB is
    type BUFF_Data_Memory is array (0 to BUFF_SIZE) of STD_LOGIC_VECTOR (DATA_SIZE - 1 downto 0);
    signal internal_data : BUFF_Data_Memory;

    type BUFF_Tag_Memory is array (0 to BUFF_SIZE) of STD_LOGIC_VECTOR (TAG_SIZE - 1 downto 0);
    signal internal_tag : BUFF_Tag_Memory;

    signal internal_valid : STD_LOGIC_VECTOR (BUFF_SIZE downto 0);   

    signal occup_buff_size : unsigned(TAG_SIZE - 1 downto 0);   -- represents the number of valid entries inside the internal buffer   

    signal available_index : unsigned(TAG_SIZE - 1 downto 0);  -- represents the index of an empty slot that we can write to new incoming data
    signal new_available_index : unsigned(TAG_SIZE - 1 downto 0);  -- holds the index of a slot that has been emptied by passing it to the output

    signal found : STD_LOGIC;
    signal found_idx : unsigned(TAG_SIZE - 1 downto 0);

begin

    ----------------------------------------------------
    -- This process increments/decrements the occup_buff_size and calculates an index available for storing new incoming data
    -- The calculation of available_index can not simply = occup_buff_size since when we can remove an entry at any index and decrement occup_buff_size, so there is no guarantee that the new occup_buff_size does not have already a valid entry that we should not overwrite
    ----------------------------------------------------
    update_occup_buff : process (clk, rst)
        variable internal_counter  : unsigned(TAG_SIZE - 1 downto 0);
        variable next_available_index  : unsigned(TAG_SIZE - 1 downto 0);
    begin
        if(rst = '1') then
            internal_counter := (others => '0');
            next_available_index := (others => '0');
        elsif rising_edge(clk) then
            if(pValidArray(1) = '1' and not (occup_buff_size = BUFF_SIZE) ) then  -- so, if the buffer size is full, no input will be accepted
                internal_counter := internal_counter + 1;
            end if;

            -- the above condition suggests that occup_buff_size can not go beyond BUFF_SIZE, but it can be BUFF_SIZE
                -- SO, for an extra margin, I specify the size of my internal memory to be BUFF_SIZE + 1 (i.e., can have an index as BUFF_SIZE)
            if(internal_valid(to_integer(internal_counter)) = '0') then  -- if the slot is available, store the future data in it
                next_available_index := internal_counter;
            else  -- if the slot is not available, then my assumption is that we must have outputted from the buffer, so check new_available_index
                next_available_index := new_available_index;
            end if;

            if(validArray(0) = '1' and internal_counter > 0) then  -- if we successfully passed a token to the output, 
                internal_counter := internal_counter - 1;
            end if;
        end if;
        occup_buff_size <= internal_counter;
        available_index <= next_available_index;
    end process; 

    update_internal_mem : process(pValidArray, occup_buff_size) 
    begin
        internal_data(to_integer(available_index)) <= dataInArray(0); 
        internal_tag(to_integer(available_index)) <= tagIn;
        if(pValidArray(1) = '1' and not (occup_buff_size = BUFF_SIZE) ) then  -- so, if the buffer size is full, no input will be accepted
            internal_valid(to_integer(available_index)) <= '1';
        else
            internal_valid(to_integer(available_index)) <= '0';
        end if;
    end process;

    ----------------------------------------------------
    -- TODOOOO check if I should base the condition on something else other than validArray(0) = '1'!!!!!!!
    -- I'm hoping that it will work this way since the way I calculate validArray(0) has to do with the current in0 so they should be synchronized
    ----------------------------------------------------
    ready_0_proc : process(validArray, nReadyArray)  
    begin
        -- if there is no valid token at in0, make it always ready to receive OR if there is a valid output and the next is ready to accept, this means that the output must have accepted in0
        if( (validArray(0) = '1' and nReadyArray(0) = '1') or pValidArray(0) = '0') then   
            readyArray(1) <= '1';
        else
            readyArray(1) <= '0';
        end if;
    end process;

    ready_1_proc : process(occup_buff_size)
    begin
        -- regardless of whether there is a valid token at in1 or not, we should not be ready to accept if the buffer size is full!!
        if(occup_buff_size = BUFF_SIZE) then  
            readyArray(1) <= '0';
        else
            readyArray(1) <= '1';
        end if;
    end process;

    ----------------------------------------------------
    -- Suppose temporarily that in0 represents the index of the internal buffer that we would like to wait for until it is valid then pass to the output
        -- IN the future, this process should be extended to have a searching mechanism
            -- Specifically, instead of indexing directly from dataInArray we should index from another signal that should come from the search process
    
    -- Not sure if I should have nReadyArray in the condiiton as I currently have it or not..
    ----------------------------------------------------
    output_proc : process (found, found_idx, nReadyArray)  
    begin
        dataOutArray(0) <= internal_data(to_integer(unsigned(found_idx))); 
        -- tagOut <= internal_tag(to_integer(unsigned(found_idx)));

        if(found = '1' and nReadyArray(0) = '1') then
            validArray(0) <= internal_valid(to_integer(unsigned(found_idx)));   -- depends on whether there is a valid input in this slot 
            internal_valid(to_integer(unsigned(found_idx))) <= '0';  -- this slot should be emptied 
            new_available_index <= unsigned(found_idx);
        else
            validArray(0) <= '0';
            internal_valid(to_integer(unsigned(found_idx))) <= internal_valid(to_integer(unsigned(found_idx)));
            new_available_index <= new_available_index;
        end if;
    end process;

    searching_process : process (target_tagIn, pValidArray)
    begin
       for I in 0 to BUFF_SIZE loop
            if(internal_valid(I) = '1' and pValidArray(0) = '1' and internal_tag(I) =  target_tagIn) then
                found <= '1';
                found_idx <= to_unsigned(I, found_idx'length);
            else
                found <= '1';
                found_idx <= (others => '0');
            end if;
        end loop;
    end process;
end;

-----------------------------------------------------------------------------------------------------------------------------------
 -- TODO: think of the case if the occup_buff_size is empty and per chance the tokens at pValidArray(0) and pValidArray(1) are matched
            -- the token should be passed to the output immediately without being held for any number of cycles!! 
            -- the same applies if the buffer size is FULL, but the new incoming pValidArray(1) token is matched with pValidArray(0), it should be passed immediately not held back!!


-- Question that I have no answer to and I'm not sure if it is a problem at all or not:
        -- If there is a valid input and I considered to either be passed to the output immediately or stored internally, what guarantees that in the next cycle it will no longer be valid... My answer is that it is the responsibility of the previous component to either produce a new token or make valid = 0 provided that my ROB is setting its corresponding ready to 1! But, if my ROB is setting its ready to 0, the previous component is responsible for holding the token.. NOW, TODOOOOO, it is the responsibility of the ROB to not store the input token if it is setting its ready to 0 (i.e., make sure that there is a connection between accepting a new token and setting ready!!)

-- Shall I make it gradual in the sense that I separate the mechanism of searching from that of emptying a slot and passing it to the output??
    -- 1st consider the 2nd input as the idx to pass to the output instead of thinking of it as the value to search for.
    -- 2nd extend the previous point to search for the value instead of assuming a specific index..

    -- The problem is that now I just realized that I need to propagate the tag through every single component for them to provide it to the ROBs.
            -- But, this is orthogonal to the design of this module..
-----------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------gian_mux
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity gian_mux is
    generic(
        INPUTS        : integer; --supports only two inputs and one condition (so put 3)
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer;
        THRD_NUM       : integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray      : in  std_logic_vector(0 downto 0);
        validArray      : out std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0)   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
        
    );
end gian_mux;

architecture arch of gian_mux is
signal dataIn_0_buff : data_array(THRD_NUM - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
signal dataIn_1_buff : data_array(THRD_NUM - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_pvalid : std_logic;
signal tehb_ready : std_logic;


begin

horrible_mono_process: process(clk, rst)
variable index_0_buff : integer := 0;
variable index_1_buff : integer := 0;
variable count : integer := 0;
variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
variable tmp_valid_out : std_logic;
variable only_in1 : integer := 0;
variable through_0 : integer := 0;
variable through_1 : integer := 0;
begin
    if(rst = '1') then
        dataIn_0_buff <= (others => (others => '0'));
        index_0_buff := 0;
        dataIn_1_buff <= (others => (others => '0'));
        index_1_buff := 0;
        count := 0;
        through_0 := 0;
        through_1 := 0;
        only_in1 := 0;
        tmp_valid_out := '0';
        tmp_data_out  := unsigned(dataInArray(0));
        readyArray <= (others => '0');
    elsif rising_edge(clk) then
        --default
        tmp_valid_out := '0';
        tmp_data_out  := unsigned(dataInArray(0));
        through_0 := 0;
        through_1 := 0;
        if(nReadyArray(0) = '1') then
            if((index_0_buff > 0 or(pValidArray(1) = '1' and index_0_buff = 0)) and only_in1 = 0) then 
                if(pValidArray(1) = '1' and index_0_buff = 0) then -- pass it through
                    tmp_data_out := unsigned(dataInArray(0));
                    through_0 := 1;
                else
                    tmp_data_out := unsigned(dataIn_0_buff(0));
                    index_0_buff := index_0_buff - 1;
                    for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                    dataIn_0_buff(I) <= dataIn_0_buff(I+1);
                    end loop;
                    dataIn_0_buff(THRD_NUM - 1) <= (others => '0');
                end if;
                tmp_valid_out := '1';
                count := count + 1;
            elsif (index_1_buff > 0 or (pValidArray(2) = '1' and index_1_buff = 0)) then
                if(pValidArray(2) = '1' and index_1_buff = 0) then --pass it through
                    tmp_data_out := unsigned(dataInArray(1));
                    through_1 := 1;
                else
                    tmp_data_out := unsigned(dataIn_1_buff(0));
                    index_1_buff := index_1_buff - 1;
                    for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                        dataIn_1_buff(I) <= dataIn_1_buff(I+1);
                    end loop;
                    dataIn_1_buff(THRD_NUM - 1) <= (others => '0');
                end if;                
                tmp_valid_out := '1';         
            end if;
        end if;
        --dataIn_0_buff
        if(pValidArray(1) = '1' and index_0_buff < THRD_NUM and readyArray(1) = '1' and through_0 = 0) then  
            dataIn_0_buff(index_0_buff) <= dataInArray(0);
            index_0_buff := index_0_buff + 1;
        end if;
        --dataIn_1_buff
        if(pValidArray(2) = '1' and index_1_buff < THRD_NUM and through_1 = 0) then  
            dataIn_1_buff(index_1_buff) <= dataInArray(1);
            index_1_buff := index_1_buff + 1;
        end if;
        --cond decrementation
        if(pValidArray(0) = '1' and to_integer(unsigned(condition(0))) = 0) then 
            count := count - 1;
            if(count = 0 and index_1_buff = 0 and pValidArray(2) = '0') then --nothing left in in1 (nor arriving in in1) and count 0-conditions received
                only_in1 := 0;
            end if;
        end if;
        --ready
        readyArray(2) <= '1';
        readyArray(0) <= '1';
        if(index_0_buff = THRD_NUM) then
            readyArray(1) <= '0';
        else
            readyArray(1) <= '1';
        end if;
        --only_in1
        if((index_0_buff = 0 and count > 0 and pValidArray(1) = '0') or count = THRD_NUM) then --you have sent out at least something from in0 but now there is nothing in in0
            only_in1 := 1;
        end if;
    end if;
    --tehb inputs
    tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
    tehb_pvalid  <= tmp_valid_out;
end process;

tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );

end architecture;

----------------------------------------------------------------

-----------------------------------------------------------------------gian_mux_tag
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity gian_mux_tag is
    generic(
        INPUTS        : integer; --supports only two inputs and one condition (so put 3)
        OUTPUTS       : integer;
        DATA_SIZE_IN  : integer;
        DATA_SIZE_OUT : integer;
        COND_SIZE     : integer;
        THRD_NUM      : integer;
        TAG_SIZE      : integer;
        TAG_INPUTS: integer
    );
    port(
        clk, rst      : in  std_logic;
        dataInArray   : in  data_array(INPUTS - 2 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        pValidArray   : in  std_logic_vector(INPUTS -1 downto 0);
        nReadyArray      : in  std_logic_vector(0 downto 0);
        validArray      : out std_logic_vector(0 downto 0);
        readyArray : out std_logic_vector(INPUTS -1 downto 0);
        condition     : in  data_array(0 downto 0)(COND_SIZE - 1 downto 0);   ----(integer(ceil(log2(real(INPUTS)))) - 1 downto 0);
        tag_pValidArray : in std_logic_vector(TAG_INPUTS - 1 downto 0);
        tag_readyArray : out std_logic_vector(TAG_INPUTS - 1 downto 0);
        tag_nReadyArray : in std_logic_vector(0 downto 0);
        tag_validArray : out std_logic_vector(0 downto 0);
        tag_dataInArray : in data_array(TAG_INPUTS - 1 downto 0)(TAG_SIZE - 1 downto 0); --(condition, in0, in1, ...) or (condition, in1, ...)
        tag_dataOutArray : out data_array(0 downto 0)(TAG_SIZE - 1 downto 0)
    );
end gian_mux_tag;

architecture arch of gian_mux_tag is
signal dataIn_0_buff : data_array(THRD_NUM - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
signal dataIn_1_buff : data_array(THRD_NUM - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
signal cond_buff : data_array(THRD_NUM - 1 downto 0)(COND_SIZE - 1 downto 0);
signal tag_cond_buff : data_array(THRD_NUM - 1 downto 0)(TAG_SIZE - 1 downto 0);
signal tag_in0_buff : data_array(THRD_NUM - 1 downto 0)(TAG_SIZE - 1 downto 0);
signal tag_in1_buff : data_array(THRD_NUM - 1 downto 0)(TAG_SIZE - 1 downto 0);
signal tehb_data_in  : std_logic_vector(DATA_SIZE_IN - 1 downto 0);
signal tehb_tag_data_in  : std_logic_vector(TAG_SIZE - 1 downto 0);
signal tehb_pvalid, tehb_tag_pvalid : std_logic;
signal tehb_ready, tehb_tag_ready : std_logic;  
begin

horrible_mono_process: process(clk, rst)

variable index_0_buff : integer := 0;
variable index_1_buff : integer := 0;
variable index_cond_buff : integer := 0;
variable tag_in0_index : integer := 0;
variable tag_in1_index : integer := 0;
variable tag_cond_index : integer := 0;
variable count : integer := 0;
variable count_tag : integer := 0;
variable tmp_data_out  : unsigned(DATA_SIZE_IN - 1 downto 0);
variable tmp_valid_out : std_logic;
variable only_in1 : integer := 0;
variable any_output : integer := 0;
variable ind_match_in0 : integer := 0;
variable ind_match_in1 : integer := 0;
variable found_match_in0 : integer := 0;
variable found_match_in1 : integer := 0;
variable count_in1_out : integer := 0;
variable count_cond1 : integer := 0;
begin
    if(rst = '1') then
        dataIn_0_buff <= (others => (others => '0'));
        index_0_buff := 0;
        dataIn_1_buff <= (others => (others => '0'));
        index_1_buff := 0;
        cond_buff <= (others => (others => '0'));
        index_cond_buff := 0;
        tag_in0_buff <= (others => (others => '0'));
        tag_in0_index := 0;
        tag_in1_buff <= (others => (others => '0'));
        tag_in1_index := 0;
        tag_cond_buff <= (others => (others => '0'));
        tag_cond_index := 0;
        count := 0;
        only_in1 := 0;
        tmp_valid_out := '0';
        tmp_data_out  := unsigned(dataInArray(0));
        readyArray <= (others => '0');
        tag_readyArray <= (others => '0');
        count_in1_out := 0;
        count_cond1 := 0;
    elsif rising_edge(clk) then
        --default
        tmp_valid_out := '0';
        tehb_tag_pvalid <= '0';
        tmp_data_out  := unsigned(dataInArray(0));
        ind_match_in0 := 0;
        ind_match_in1 := 0;
        found_match_in0 := 0;
        found_match_in1 := 0;
        --search for mathces
        if(TAG_INPUTS > 2) then --normal mux
            for I in 0 to THRD_NUM - 1 loop
                if(found_match_in0 = 0) then
                    ind_match_in0 := I;
                end if;
                if(to_integer(unsigned(tag_in0_buff(0))) /= 0 and to_integer(unsigned(tag_cond_buff(I))) /= 0 and index_0_buff > 0 and ind_match_in0 < index_cond_buff and to_integer(unsigned(tag_in0_buff(0))) = to_integer(unsigned(tag_cond_buff(I))) and found_match_in0 = 0) then
                    found_match_in0 := 1;
                end if;
            end loop;                    
        end if;
        for I in 0 to THRD_NUM - 1 loop
            if(found_match_in1 = 0) then
                ind_match_in1 := I;
            end if;
            if(to_integer(unsigned(tag_in1_buff(0))) /= 0 and to_integer(unsigned(tag_cond_buff(I))) /= 0 and index_1_buff > 0 and ind_match_in1 < index_cond_buff and to_integer(unsigned(tag_in1_buff(0))) = to_integer(unsigned(tag_cond_buff(I))) and found_match_in1 = 0) then
                found_match_in1 := 1;
            end if;
        end loop;
        --output
        if(nReadyArray(0) = '1' and tag_nReadyArray(0) = '1') then
            if((index_0_buff > 0 and TAG_INPUTS = 2 and only_in1 = 0) or (TAG_INPUTS > 2 and found_match_in0 = 1)) then 
                tmp_data_out := unsigned(dataIn_0_buff(0));
                tmp_valid_out := '1';
                tehb_tag_pvalid <= '1';
                index_0_buff := index_0_buff - 1;
                for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                    dataIn_0_buff(I) <= dataIn_0_buff(I+1);
                    tag_in0_buff(I) <= tag_in0_buff(I+1);
                end loop;
                dataIn_0_buff(THRD_NUM - 1) <= (others => '0');
                if(TAG_INPUTS = 2) then --if it is a loop mux
                    count_tag := count_tag + 1;
                    count := count + 1;
                    tehb_tag_data_in <= std_logic_vector(to_unsigned(count_tag, tehb_tag_data_in'length));
                else
                    tehb_tag_data_in <= tag_in0_buff(0);
                    index_cond_buff := index_cond_buff - 1;
                    tag_in0_index := tag_in0_index - 1;
                    tag_cond_index := tag_cond_index - 1;
                    for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                        if(I >= ind_match_in0) then
                            tag_cond_buff(I) <= tag_cond_buff(I+1);
                            cond_buff(I) <= cond_buff(I+1);
                            tag_cond_buff(I+1) <= (others => '0');
                        end if;
                    end loop;
                    tag_cond_buff(THRD_NUM - 1) <= (others => '0');
                    cond_buff(THRD_NUM - 1) <= (others => '0');
                end if;       
            elsif (found_match_in1 = 1) then
                tmp_data_out := unsigned(dataIn_1_buff(0));
                for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                    dataIn_1_buff(I) <= dataIn_1_buff(I+1);
                    tag_in1_buff(I) <= tag_in1_buff(I+1);
                end loop;
                dataIn_1_buff(THRD_NUM - 1) <= (others => '0');
                tmp_valid_out := '1';
                tehb_tag_pvalid <= '1';
                tehb_tag_data_in <= tag_in1_buff(0);
                index_1_buff := index_1_buff - 1;
                index_cond_buff := index_cond_buff - 1;
                tag_in1_index := tag_in1_index - 1;
                tag_cond_index := tag_cond_index - 1;
                if(TAG_INPUTS = 2) then
                    count_in1_out := count_in1_out + 1;
                end if;
                for I in 0 to THRD_NUM - 2 loop --make the data slides in the buffer
                    if(I >= ind_match_in1) then
                        tag_cond_buff(I) <= tag_cond_buff(I+1);
                        cond_buff(I) <= cond_buff(I+1);
                        tag_cond_buff(I+1) <= (others => '0');
                    end if;
                end loop;
                tag_cond_buff(THRD_NUM - 1) <= (others => '0');
                cond_buff(THRD_NUM - 1) <= (others => '0');
            end if;
        end if;
        --dataIn_0_buff
        if(pValidArray(1) = '1' and index_0_buff < THRD_NUM and readyArray(1) = '1') then  
            dataIn_0_buff(index_0_buff) <= dataInArray(0);
            index_0_buff := index_0_buff + 1;
        end if;
        --tag_in0_buff for normal mux
        if(TAG_INPUTS > 2 and tag_pValidArray(1) = '1' and tag_in0_index < THRD_NUM and tag_readyArray(1) = '1') then  
            tag_in0_buff(tag_in0_index) <= tag_dataInArray(1);
            tag_in0_index := tag_in0_index + 1;
        end if;
        --dataIn_1_buff
        if(pValidArray(2) = '1' and index_1_buff < THRD_NUM) then
            if((TAG_INPUTS > 2 and readyArray(2) = '1') or TAG_INPUTS = 2) then 
                dataIn_1_buff(index_1_buff) <= dataInArray(1);
                index_1_buff := index_1_buff + 1;
            end if;
        end if;
        --tag_in1_buff
        if(((TAG_INPUTS = 2 and tag_pValidArray(1) = '1') or (TAG_INPUTS > 2 and tag_pValidArray(2) = '1' and tag_readyArray(TAG_INPUTS-1) = '1')) and tag_in1_index < THRD_NUM) then  
            if(TAG_INPUTS = 2) then --loop mux
                tag_in1_buff(tag_in1_index) <= tag_dataInArray(1);
            else
                tag_in1_buff(tag_in1_index) <= tag_dataInArray(2);
            end if;
            tag_in1_index := tag_in1_index + 1;
        end if;
        --cond_buff
        if(pValidArray(0) = '1' and index_cond_buff < THRD_NUM) then
            if((TAG_INPUTS > 2 and readyArray(0) = '1') or TAG_INPUTS = 2) then
                cond_buff(index_cond_buff) <= condition(0);
                index_cond_buff := index_cond_buff + 1;
            end if;
        end if;
        --tag_cond_buff
        if(tag_pValidArray(0) = '1' and tag_cond_index < THRD_NUM) then
            if((TAG_INPUTS > 2 and tag_readyArray(0) = '1') or TAG_INPUTS = 2) then
                tag_cond_buff(tag_cond_index) <= tag_dataInArray(0);
                tag_cond_index := tag_cond_index + 1;
            end if;
        end if;
        --decrementation only for loop mux
        if(TAG_INPUTS = 2) then
            if(pValidArray(0) = '1' and to_integer(unsigned(condition(0))) = 0)  then
                count := count - 1;
            elsif(pValidArray(0) = '1' and to_integer(unsigned(condition(0))) = 1) then
                count_cond1 := count_cond1 + 1;
            end if;
            if(count = 0 and count_in1_out = count_cond1) then
                only_in1 := 0;
                count_cond1 := 0;
                count_in1_out := 0;
                index_cond_buff := 0;
                tag_cond_index := 0; --blindly ignore stored 0 conditions and their tags 
            end if;
        end if;
        --ready for loopMux (only in0)
        if(TAG_INPUTS = 2) then
            --ready
            readyArray(2) <= '1';
            readyArray(0) <= '1';
            if(index_0_buff = THRD_NUM) then
                readyArray(1) <= '0';
            else
                readyArray(1) <= '1';
            end if;
            tag_readyArray <=  (others => '1');
        else    --ready for normal mux
            if(index_cond_buff = THRD_NUM) then
                readyArray(0) <= '0';
            else
                readyArray(0) <= '1';
            end if;
            if(tag_cond_index = THRD_NUM) then
                tag_readyArray(0) <= '0';
            else
                tag_readyArray(0) <= '1';
            end if;
            if(index_0_buff = THRD_NUM) then
                readyArray(1) <= '0';
            else
                readyArray(1) <= '1';
            end if;
            if(tag_in0_index = THRD_NUM) then
                tag_readyArray(1) <= '0';
            else
                tag_readyArray(1) <= '1';
            end if;
            if(index_1_buff = THRD_NUM) then
                readyArray(2) <= '0';
            else
                readyArray(2) <= '1';
            end if;
            if(tag_in1_index = THRD_NUM) then
                tag_readyArray(TAG_INPUTS - 1) <= '0'; --used TAG_INPUTS - 1 instead of 2 only for vsim
            else
                tag_readyArray(TAG_INPUTS - 1) <= '1';
            end if;
        end if;
        --only_in1
        if(((index_0_buff = 0 and count > 0) or count = THRD_NUM) and TAG_INPUTS = 2) then --you have sent out at least something from in0 but now there is nothing in in0
            only_in1 := 1;
        end if;
    end if;
    --tehb inputs
    tehb_data_in <= std_logic_vector(resize(tmp_data_out,DATA_SIZE_OUT));
    tehb_pvalid  <= tmp_valid_out;
end process;

tehb1: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => tehb_pvalid, 
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => tehb_ready,   
            dataInArray(0) => tehb_data_in,
            dataOutArray(0) => dataOutArray(0)
        );

tehb1_tag: entity work.TEHB(arch) generic map (1, 1, DATA_SIZE_IN, DATA_SIZE_IN)
port map (
--inputspValidArray
    clk => clk, 
    rst => rst, 
    pValidArray(0)  => tehb_tag_pvalid, 
    nReadyArray(0) => tag_nReadyArray(0),    
    validArray(0) => tag_validArray(0), 
--outputs
    readyArray(0) => tehb_tag_ready,   
    dataInArray(0) => tehb_tag_data_in,
    dataOutArray(0) => tag_dataOutArray(0)
);

end architecture;

--------------------------- AYA New TAGGER 17/09/2023-- it bypasses whatever data inputted to it but adds to it the extra tag signal
-------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity tagger is generic(
    SIZE : integer ; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer; TOTAL_TAG_SIZE: integer; TAG_SIZE: integer; TAG_OFFSET: integer
);
port(
        clk, rst      : in  std_logic;
        pValidArray : in std_logic_vector(SIZE downto 0); -- doesnot have a -1 because it includes the pValid of the freeTag_data input too

        nReadyArray : in std_logic_vector(SIZE - 1 downto 0);
        validArray : out std_logic_vector(SIZE - 1 downto 0);

        readyArray : out std_logic_vector(SIZE downto 0); -- doesnot have a -1 because it includes the pValid of the freeTag_data input too

        dataInArray   : in  data_array(SIZE - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(SIZE - 1 downto 0)(DATA_SIZE_OUT - 1 downto 0);

        freeTag_data : in std_logic_vector(TAG_SIZE-1 downto 0);
       -- freeTag_valid : in std_logic;
       -- freeTag_ready : out std_logic;

        tagOutArray : out data_array (SIZE - 1 downto 0)(TOTAL_TAG_SIZE-1 downto 0) -- AYA: the tag associated with each output 
        );
end tagger;

architecture arch of tagger is

signal join_valid : std_logic;
signal join_nReady : std_logic;
constant all_one : std_logic_vector(SIZE-1 downto 0) := (others => '1');

constant tag_idx_lower : integer := TAG_SIZE * TAG_OFFSET; --unsigned(TOTAL_TAG_SIZE - 1 downto 0);
constant tag_idx_upper : integer := tag_idx_lower + TAG_SIZE - 1; --unsigned(TOTAL_TAG_SIZE - 1 downto 0);

signal join_readyArray : std_logic_vector(SIZE downto 0);

signal fork_ready: STD_LOGIC_VECTOR (0 downto 0);
signal fork_useless_out : data_array(SIZE - 1 downto 0)(0 downto 0);

begin

    --tag_idx_lower <= TAG_SIZE * TAG_OFFSET;
    --tag_idx_upper <= tag_idx_lower + TAG_SIZE - 1;
    
    j : entity work.join(arch) generic map(SIZE + 1)
                port map(   pValidArray,
                            join_nReady, --nReadyArray(0),
                            join_valid,
                            readyArray);

    dataOutArray <= dataInArray;

    tagging_process : process (freeTag_data)
    begin
      for I in 0 to SIZE - 1 loop
        tagOutArray(I)(tag_idx_upper downto tag_idx_lower) <= freeTag_data;
      end loop;
    end process;

    --process(join_valid)
    --begin
    --    if(join_valid = '1') then --and nReadyArray = all_one) then
    --        validArray <= (others => '1');
    --    else
    --        validArray <= (others => '0');
    --    end if;
    --end process;

    join_nReady <= fork_ready(0); --and nReadyArray;

    f : entity work.fork(arch) generic map(1, SIZE, 1, 1)
            port map (
        --inputs
            clk => clk,  --clk
            rst => rst,  --rst
            pValidArray(0) => join_valid,
            dataInArray (0) => "1",
            nReadyArray => nReadyArray, 
        --outputs
            dataOutArray => fork_useless_out,
            readyArray => fork_ready,  
            validArray => validArray    
            );

end architecture;
-------------------------------------------------------------------

------------------------------------ AYA: 18/09/2023: UNTAGGER
--------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.customTypes.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

entity un_tagger is generic(
    SIZE : integer ; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer; TOTAL_TAG_SIZE: integer; TAG_SIZE: integer; TAG_OFFSET: integer
);
port(
        clk, rst      : in  std_logic;
        pValidArray : in std_logic_vector(SIZE - 1 downto 0);

        nReadyArray : in std_logic_vector(SIZE downto 0);  -- this signal and the one after include the extra output of the UNTAGGER that carries the freed up tag
        validArray : out std_logic_vector(SIZE downto 0);

        readyArray : out std_logic_vector(SIZE - 1 downto 0);

        dataInArray   : in  data_array(SIZE - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(SIZE - 1 downto 0)(DATA_SIZE_OUT - 1 downto 0);

        freeTag_data : out std_logic_vector(TAG_SIZE-1 downto 0);
       -- freeTag_valid : in std_logic;
       -- freeTag_ready : out std_logic;

        tagInArray : in data_array (SIZE - 1 downto 0)(TOTAL_TAG_SIZE-1 downto 0) -- AYA: the tag associated with each output 
        );
end un_tagger;

architecture arch of un_tagger is

signal join_valid : std_logic;
signal join_nReady : std_logic;
constant all_one : std_logic_vector(SIZE-1 downto 0) := (others => '1');

signal join_readyArray : std_logic_vector(SIZE downto 0);

constant tag_idx_lower : integer := TAG_SIZE * TAG_OFFSET; --unsigned(TOTAL_TAG_SIZE - 1 downto 0);
constant tag_idx_upper : integer := tag_idx_lower + TAG_SIZE - 1; --unsigned(TOTAL_TAG_SIZE - 1 downto 0);

begin

    --tag_idx_lower <= TAG_SIZE * TAG_OFFSET;
    --tag_idx_upper <= tag_idx_lower + TAG_SIZE - 1;

    
    j : entity work.join(arch) generic map(SIZE)
                port map(   pValidArray,
                            join_nReady, --nReadyArray(0),
                            join_valid,
                            readyArray);

    dataOutArray <= dataInArray;

    freeTag_data <= tagInArray(0)(tag_idx_upper downto tag_idx_lower);  -- take the tag of any of the inputs; they are all guaranteed to be the same

    -- I think it is wrong to calculate valid using nReady so I removed it
    process(join_valid)
    begin
        if(join_valid = '1') then --and nReadyArray = all_one) then
            validArray <= (others => '1');
        else
            validArray <= (others => '0');
        end if;
    end process;

    process (nReadyArray)
        variable check : std_logic := '1';
    begin
        check := '1';
        for I in 0 to SIZE loop
            check := check and nReadyArray(I);
        end loop;
        if(check = '1') then
            join_nReady <= '1';
        else 
            join_nReady <= '0';
        end if;
    end process;

end architecture;

--------------------------------------------------------------
--------------------------------------------------------------


----------------------------------------------------------------synh for loopmux
library ieee;
use ieee.std_logic_1164.all;
USE work.customTypes.all;
entity synch is generic(
SIZE : integer ; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer
);
port(
        pValidArray : in std_logic_vector(SIZE - 1 downto 0);
        nReadyArray : in std_logic_vector(SIZE - 1 downto 0);
        validArray : out std_logic_vector(SIZE - 1 downto 0);
        readyArray : out std_logic_vector(SIZE - 1 downto 0);
        dataInArray   : in  data_array(SIZE - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(SIZE - 1 downto 0)(DATA_SIZE_OUT - 1 downto 0)
        );
end synch;

architecture arch of synch is

signal join_valid : std_logic;
signal join_nReady : std_logic;
constant all_one : std_logic_vector(SIZE-1 downto 0) := (others => '1');
begin
    
    j : entity work.join(arch) generic map(SIZE)
                port map(   pValidArray,
                            join_nReady,
                            join_valid,
                            readyArray);

    dataOutArray <= dataInArray;

    process(join_valid, nReadyArray)
    begin
        if(join_valid = '1' and nReadyArray = all_one) then
            validArray <= (others => '1');
        else
            validArray <= (others => '0');
        end if;
    end process;

    process (nReadyArray)
    variable check : std_logic := '1';
    begin
        check := '1';
        for I in 0 to SIZE - 1 loop
            check := check and nReadyArray(I);
        end loop;
        if(check = '1') then
            join_nReady <= '1';
        else 
            join_nReady <= '0';
        end if;
    end process;

end architecture;
----------------------------------------------------------------

----------------------------------------------------old_synch
library ieee;
use ieee.std_logic_1164.all;
USE work.customTypes.all;
entity old_synch is generic(
SIZE : integer ; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer
);
port(
        pValidArray : in std_logic_vector(SIZE - 1 downto 0);
        nReadyArray : in std_logic_vector(SIZE - 1 downto 0);
        validArray : out std_logic_vector(SIZE - 1 downto 0);
        readyArray : out std_logic_vector(SIZE - 1 downto 0);
        dataInArray   : in  data_array(SIZE - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(SIZE - 1 downto 0)(DATA_SIZE_OUT - 1 downto 0)
        );
end old_synch;

architecture arch of old_synch is

signal join_valid : std_logic;
signal join_nReady : std_logic;
constant all_one : std_logic_vector(SIZE-1 downto 0) := (others => '1');
begin
    
    j : entity work.join(arch) generic map(SIZE)
                port map(   pValidArray,
                            join_nReady,
                            join_valid,
                            readyArray);

    dataOutArray <= dataInArray;

    process(join_valid, readyArray)
    begin
        if(join_valid = '1' and readyArray = all_one) then
            validArray <= (others => '1');
        else
            validArray <= (others => '0');
        end if;
    end process;

    process (nReadyArray)
    variable check : std_logic := '1';
    begin
        check := '1';
        for I in 0 to SIZE - 1 loop
            check := check and nReadyArray(I);
        end loop;
        if(check = '1') then
            join_nReady <= '1';
        else 
            join_nReady <= '0';
        end if;
    end process;

end architecture;

---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
USE work.customTypes.all;
entity OLD_cntrlMerge is generic(
INPUTS : integer ; OUTPUTS : integer; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer; COND_SIZE:integer
);
port(
      clk, rst : in std_logic;    
        pValidArray : in std_logic_vector(1 downto 0);
        nReadyArray : in std_logic_vector(1 downto 0);
        validArray : out std_logic_vector(1 downto 0);
        readyArray : out std_logic_vector(1 downto 0);
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        condition: out data_array(0 downto 0)(0 downto 0));
end OLD_cntrlMerge;
architecture arch of OLD_cntrlMerge is

signal phi_C1_readyArray : STD_LOGIC_VECTOR (1 downto 0);
signal phi_C1_validArray : STD_LOGIC_VECTOR (0 downto 0);
signal phi_C1_dataOutArray : data_array(0 downto 0)(0 downto 0);

signal fork_C1_readyArray : STD_LOGIC_VECTOR (0 downto 0);
signal fork_C1_dataOutArray : data_array(1 downto 0)(0 downto 0);
signal fork_C1_validArray : STD_LOGIC_VECTOR (1 downto 0);

signal oehb1_valid, oehb1_ready, index : STD_LOGIC;
signal oehb1_dataOut : std_logic_vector(DATA_SIZE_IN-1 downto 0);

begin


readyArray <= phi_C1_readyArray;

phi_C1: entity work.merge_notehb(arch) generic map (2, 1, 1, 1)
port map (
--inputs
    clk => clk,  --clk
    rst => rst,  --rst
    pValidArray => pValidArray,    --pValidArray
    dataInArray (0) => "1",
    dataInArray (1) => "1",
    nReadyArray(0) => oehb1_ready,--outputs
    dataOutArray => phi_C1_dataOutArray,
    readyArray => phi_C1_readyArray,    --readyArray
    validArray => phi_C1_validArray --validArray
);


process(pValidArray)
begin
        if (pValidArray(0) = '1') then
            index <= '0';
        else
            index <= '1';
        end if;
end process;

oehb1: entity work.TEHB(arch) generic map (1, 1, 1, 1)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => phi_C1_validArray(0), 
            nReadyArray(0) => fork_C1_readyArray(0),    
            validArray(0) => oehb1_valid, 
        --outputs
            readyArray(0) => oehb1_ready,   
            dataInArray(0)(0) => index,
            dataOutArray(0) => oehb1_dataOut
        );

fork_C1: entity work.fork(arch) generic map (1, 2, 1, 1)
port map (
--inputs
    clk => clk,  --clk
    rst => rst,  --rst
    pValidArray(0) => oehb1_valid, --pValidArray
    dataInArray (0) => "1",
    nReadyArray => nReadyArray, --nReadyArray
--outputs
    dataOutArray => fork_C1_dataOutArray,
    readyArray => fork_C1_readyArray,   --readyArray
    validArray => fork_C1_validArray    --validArray
);


validArray <= fork_C1_validArray;
condition(0) <= oehb1_dataOut;

end arch;

-------------------------------------------------------------------------
-------------------------------------------------------------- AYA's Tagged CMerge 
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
USE work.customTypes.all;
entity cntrlMerge_tagged is generic(
INPUTS : integer ; OUTPUTS : integer; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer; COND_SIZE:integer; TAG_SIZE:integer
);
port(
      clk, rst : in std_logic;    
        pValidArray : in std_logic_vector(1 downto 0);
        nReadyArray : in std_logic_vector(1 downto 0);
        validArray : out std_logic_vector(1 downto 0);
        readyArray : out std_logic_vector(1 downto 0);
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        condition: out data_array(0 downto 0)(0 downto 0);

        tagInArray : in data_array(INPUTS - 1 downto 0)(TAG_SIZE-1 downto 0);
        tagOutArray : out data_array (1 downto 0)(TAG_SIZE-1 downto 0));

end cntrlMerge_tagged;

architecture arch of cntrlMerge_tagged is

signal phi_C1_readyArray : STD_LOGIC_VECTOR (1 downto 0);
signal phi_C1_validArray : STD_LOGIC_VECTOR (0 downto 0);
--signal phi_C1_dataOutArray : data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);

signal fork_C1_readyArray : STD_LOGIC_VECTOR (0 downto 0);
signal fork_C1_dataOutArray : data_array(1 downto 0)(0 downto 0);
signal fork_C1_validArray : STD_LOGIC_VECTOR (1 downto 0);

signal oehb1_valid, oehb1_ready, index : STD_LOGIC;
signal oehb1_dataOut : std_logic_vector(0 downto 0); --(DATA_SIZE_IN-1 downto 0); AYA: 16/09/2023: changed it because it no longer matches the DATA_SIZE_IN which can be > 1

--signal tagOut_internal : data_array (1 downto 0)(TAG_SIZE-1 downto 0); 

signal tagged_data_in : data_array(1 downto 0)(DATA_SIZE_IN + TAG_SIZE-1 downto 0); -- AYA: 04/10/2023
signal tagged_data_out : data_array(0 downto 0)(DATA_SIZE_IN + TAG_SIZE - 1 downto 0);  -- 04/10/2023 

begin

    -- AYA: 04/10/2023
    tagged_data_in(0) <= tagInArray(0) & dataInArray(0);  --04/10/2023
    tagged_data_in(1) <= tagInArray(1) & dataInArray(1);  --04/10/2023

    dataOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN -1 downto 0);  --04/10/2023
    tagOutArray(0) <= tagged_data_out(0)(DATA_SIZE_IN + TAG_SIZE -1 downto DATA_SIZE_IN);  --04/10/2023
    tagOutArray(1) <= tagged_data_out(0)(DATA_SIZE_IN + TAG_SIZE -1 downto DATA_SIZE_IN);  --04/10/2023

    readyArray <= phi_C1_readyArray;

phi_C1: entity work.merge_notehb(arch) generic map (2, 1, DATA_SIZE_IN + TAG_SIZE, DATA_SIZE_OUT + TAG_SIZE)
port map (
--inputs
    clk => clk,  --clk
    rst => rst,  --rst
    pValidArray => pValidArray,    --pValidArray
    dataInArray (0) => tagged_data_in(0), --dataInArray(0), -- AYA changed this 16/09/2023
    dataInArray (1) => tagged_data_in(1), --dataInArray(1), -- AYA changed this 16/09/2023
    nReadyArray(0) => oehb1_ready,--outputs
    dataOutArray => tagged_data_out, --dataOutArray, --phi_C1_dataOutArray,  -- AYA changed this 16/09/2023
    readyArray => phi_C1_readyArray,    --readyArray
    validArray => phi_C1_validArray --validArray
);


process(pValidArray)--, tagOut_internal)
begin
        if (pValidArray(0) = '1') then
            index <= '0';
--            tagOutArray(0) <= tagOut_internal(0);
--            tagOutArray(1) <= tagOut_internal(0);
        else
            index <= '1';
--            tagOutArray(0) <= tagOut_internal(1);
--            tagOutArray(1) <= tagOut_internal(1);
        end if;
end process;

oehb1: entity work.TEHB(arch) generic map (1, 1, 1, 1)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => phi_C1_validArray(0), 
            nReadyArray(0) => fork_C1_readyArray(0),    
            validArray(0) => oehb1_valid, 
        --outputs
            readyArray(0) => oehb1_ready,   
            dataInArray(0)(0) => index,
            dataOutArray(0) => oehb1_dataOut
        );

fork_C1: entity work.fork(arch) generic map (1, 2, 1, 1)
port map (
--inputs
    clk => clk,  --clk
    rst => rst,  --rst
    pValidArray(0) => oehb1_valid, --pValidArray
    dataInArray (0) => "1",
    nReadyArray => nReadyArray, --nReadyArray
--outputs
    dataOutArray => fork_C1_dataOutArray,
    readyArray => fork_C1_readyArray,   --readyArray
    validArray => fork_C1_validArray   --validArray
);


validArray <= fork_C1_validArray;
condition(0) <= oehb1_dataOut;

end arch;

---------------------------------------------------------------------
--------------------------------------------------------------- AYA's CMerge that supports data inputs and outputs of any size
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
USE work.customTypes.all;
entity cntrlMerge is generic(
INPUTS : integer ; OUTPUTS : integer; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer; COND_SIZE:integer
);
port(
      clk, rst : in std_logic;    
        pValidArray : in std_logic_vector(1 downto 0);
        nReadyArray : in std_logic_vector(1 downto 0);
        validArray : out std_logic_vector(1 downto 0);
        readyArray : out std_logic_vector(1 downto 0);
        dataInArray   : in  data_array(INPUTS - 1 downto 0)(DATA_SIZE_IN - 1 downto 0);
        dataOutArray  : out data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);
        condition: out data_array(0 downto 0)(0 downto 0));
end cntrlMerge;
architecture arch of cntrlMerge is

signal phi_C1_readyArray : STD_LOGIC_VECTOR (1 downto 0);
signal phi_C1_validArray : STD_LOGIC_VECTOR (0 downto 0);
--signal phi_C1_dataOutArray : data_array(0 downto 0)(DATA_SIZE_OUT - 1 downto 0);

signal fork_C1_readyArray : STD_LOGIC_VECTOR (0 downto 0);
signal fork_C1_dataOutArray : data_array(1 downto 0)(0 downto 0);
signal fork_C1_validArray : STD_LOGIC_VECTOR (1 downto 0);

signal oehb1_valid, oehb1_ready, index : STD_LOGIC;
signal oehb1_dataOut : std_logic_vector(0 downto 0); --(DATA_SIZE_IN-1 downto 0); AYA: 16/09/2023: changed it because it no longer matches the DATA_SIZE_IN which can be > 1

begin


readyArray <= phi_C1_readyArray;

phi_C1: entity work.merge_notehb(arch) generic map (2, 1, DATA_SIZE_IN, DATA_SIZE_OUT)
port map (
--inputs
    clk => clk,  --clk
    rst => rst,  --rst
    pValidArray => pValidArray,    --pValidArray
    dataInArray (0) => dataInArray(0), -- AYA changed this 16/09/2023
    dataInArray (1) => dataInArray(1), -- AYA changed this 16/09/2023
    nReadyArray(0) => oehb1_ready,--outputs
    dataOutArray => dataOutArray, --phi_C1_dataOutArray,  -- AYA changed this 16/09/2023
    readyArray => phi_C1_readyArray,    --readyArray
    validArray => phi_C1_validArray --validArray
);


process(pValidArray)
begin
        if (pValidArray(0) = '1') then
            index <= '0';
        else
            index <= '1';
        end if;
end process;

oehb1: entity work.TEHB(arch) generic map (1, 1, 1, 1)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => phi_C1_validArray(0), 
            nReadyArray(0) => fork_C1_readyArray(0),    
            validArray(0) => oehb1_valid, 
        --outputs
            readyArray(0) => oehb1_ready,   
            dataInArray(0)(0) => index,
            dataOutArray(0) => oehb1_dataOut
        );

fork_C1: entity work.fork(arch) generic map (1, 2, 1, 1)
port map (
--inputs
    clk => clk,  --clk
    rst => rst,  --rst
    pValidArray(0) => oehb1_valid, --pValidArray
    dataInArray (0) => "1",
    nReadyArray => nReadyArray, --nReadyArray
--outputs
    dataOutArray => fork_C1_dataOutArray,
    readyArray => fork_C1_readyArray,   --readyArray
    validArray => fork_C1_validArray    --validArray
);


validArray <= fork_C1_validArray;
condition(0) <= oehb1_dataOut;

end arch;

--------------------------------------------------------------  read port
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.customTypes.all;


entity lsq_load_op is generic( INPUTS : Integer;  OUTPUTS : Integer; ADDRESS_SIZE : Integer;  DATA_SIZE : Integer);
port (
    rst: in std_logic;
    clk: in std_logic;

    --- interface to previous
    pValidArray : in std_logic_vector(INPUTS - 1 downto 0);
    readyArray : out std_logic_vector(INPUTS - 1 downto 0);
    dataInArray: in data_array (0 downto 0)(DATA_SIZE -1 downto 0);
    input_addr: in std_logic_vector(ADDRESS_SIZE -1 downto 0);

    ---interface to next
    nReadyArray : in std_logic_vector(OUTPUTS - 1 downto 0); 
    validArray : out std_logic_vector(OUTPUTS - 1 downto 0);
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE-1 downto 0);
    output_addr: out std_logic_vector(ADDRESS_SIZE -1 downto 0)
    );

end entity;

architecture arch of lsq_load_op is 

begin

    output_addr <= input_addr; -- address request goes to LSQ
    validArray(1) <= pValidArray(1);
    readyArray(1) <= nReadyArray(1);


    dataOutArray(0) <= dataInArray(0); -- data from LSQ to load output
    validArray(0) <= pValidArray(0);
    readyArray(0) <= nReadyArray(0);
        
end architecture;


--------------------------------------------------------------  store port
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.customTypes.all;


entity lsq_store_op is generic( INPUTS : Integer;  OUTPUTS : Integer; ADDRESS_SIZE : Integer;  DATA_SIZE : Integer);
port (
    rst: in std_logic;
    clk: in std_logic;

    input_addr: in std_logic_vector(ADDRESS_SIZE -1 downto 0);
    dataInArray : in data_array (0 downto 0)(DATA_SIZE -1 downto 0);

    --- interface to previous
    pValidArray : IN std_logic_vector(1 downto 0);
    readyArray : OUT std_logic_vector(1 downto 0);

    ---interface to next
    dataOutArray : out data_array (0 downto 0)(DATA_SIZE -1 downto 0);
    output_addr: out std_logic_vector(ADDRESS_SIZE -1 downto 0);
    nReadyArray: in std_logic_vector(OUTPUTS-1 downto 0);
    validArray: out std_logic_vector(OUTPUTS-1 downto 0)
    );

end entity;

architecture arch of lsq_store_op is 

begin

    dataOutArray(0) <= dataInArray(0); -- data to LSQ
    validArray(0) <= pValidArray(0);
    readyArray(0) <= nReadyArray(0);

    output_addr <= input_addr; -- address to LSQ
    validArray(1) <= pValidArray(1);
    readyArray(1) <= nReadyArray(1);
        
end architecture;



