-----------------------------------------------------------------------
-- int mul wrapper  -- AYA's tagged version 05/08/2023
-----------------------------------------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity mul_op_tagged is
Generic (
 INPUTS: integer; OUTPUTS: integer; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer;
 TAG_SIZE: integer   -- AYA: 05/08/2023: added this
);
port (
  clk : IN STD_LOGIC;
  rst : IN STD_LOGIC;
  pValidArray : IN std_logic_vector(1 downto 0);
  nReadyArray : in std_logic_vector(0 downto 0);
  validArray : out std_logic_vector(0 downto 0);
  readyArray : OUT std_logic_vector(1 downto 0);
  dataInArray : in data_array (1 downto 0)(DATA_SIZE_IN-1 downto 0); 

  tagInArray : in data_array (1 downto 0)(TAG_SIZE-1 downto 0); -- AYA: 05/08/2023: added this

  dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0);

  tagOutArray : out data_array (0 downto 0)(TAG_SIZE-1 downto 0)); -- AYA: 05/08/2023: added this  

end entity;

architecture arch of mul_op_tagged is

signal join_valid : STD_LOGIC;

signal buff_valid, oehb_valid, oehb_ready : STD_LOGIC;
signal oehb_dataOut, oehb_datain : std_logic_vector(0 downto 0);

signal buff_tag : std_logic_vector(TAG_SIZE - 1 downto 0);

-- multiplier latency (4 or 8)
constant LATENCY : integer := 4;
--constant LATENCY : integer := 8;

begin 
join: entity work.join(arch) generic map(2)
port map( pValidArray,  
    oehb_ready,                        
    join_valid,                  
      readyArray);   

        -- instantiated multiplier (work.mul_4_stage or work.mul_8_stage)
multiply_unit:  entity work.mul_4_stage(behav) generic map (INPUTS, OUTPUTS, DATA_SIZE_IN, DATA_SIZE_OUT)
--multiply_unit:  entity work.mul_8_stage(behav) generic map (INPUTS, OUTPUTS, DATA_SIZE_IN, DATA_SIZE_OUT)
port map (
    clk => clk,
    ce => oehb_ready,
    a => dataInArray(0),
    b => dataInArray(1),
    p => dataOutArray(0));

buff: entity work.delay_buffer_tagged(arch) generic map(LATENCY-1, TAG_SIZE)
    port map(clk,
    rst,
    join_valid,
    tagInArray(0),
    oehb_ready,
    buff_valid,
    buff_tag);

--oehb: entity work.OEHB(arch) generic map (1, 1, 1, 1)
--        port map (
        --inputspValidArray
--            clk => clk, 
--            rst => rst, 
--            pValidArray(0)  => buff_valid, -- real or speculatef condition (determined by merge1)
--            nReadyArray(0) => nReadyArray(0),    
--            validArray(0) => validArray(0), 
        --outputs
--            readyArray(0) => oehb_ready,   
--            dataInArray(0) => oehb_datain,
--            dataOutArray(0) => oehb_dataOut
--        );

  -- tagOutArray(0) <= tagInArray(0); -- AYA: 05/08/2023: added this

  -- AYA: 08/08/2023: to make the tagOut pass through the same delays that the dataOut passes through, I thought of replacing oehb_datain and oehb_dataOut with the tagIn and tagOut.. I left the original OEHB commented out above for reference.. I do not need OEHB to be tagged because I will consider the tag to be the data, so no need for extra signals

oehb: entity work.OEHB(arch) generic map (1, 1, TAG_SIZE, TAG_SIZE)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => buff_valid, -- real or speculatef condition (determined by merge1)
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => oehb_ready,   
            dataInArray(0) => buff_tag,
            dataOutArray(0) => tagOutArray(0)
        );



end architecture;



-----------------------------------------------------------------------
-- int mul wrapper
-----------------------------------------------------------------------

Library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.customTypes.all;

entity mul_op is
Generic (
 INPUTS: integer; OUTPUTS: integer; DATA_SIZE_IN: integer; DATA_SIZE_OUT: integer
);
port (
  clk : IN STD_LOGIC;
  rst : IN STD_LOGIC;
  pValidArray : IN std_logic_vector(1 downto 0);
  nReadyArray : in std_logic_vector(0 downto 0);
  validArray : out std_logic_vector(0 downto 0);
  readyArray : OUT std_logic_vector(1 downto 0);
  dataInArray : in data_array (1 downto 0)(DATA_SIZE_IN-1 downto 0); 
  dataOutArray : out data_array (0 downto 0)(DATA_SIZE_OUT-1 downto 0));
end entity;

architecture arch of mul_op is

signal join_valid : STD_LOGIC;

signal buff_valid, oehb_valid, oehb_ready : STD_LOGIC;
signal oehb_dataOut, oehb_datain : std_logic_vector(0 downto 0);

-- multiplier latency (4 or 8)
constant LATENCY : integer := 4;
--constant LATENCY : integer := 8;

begin 
join: entity work.join(arch) generic map(2)
port map( pValidArray,  
oehb_ready,                        
join_valid,                  
  readyArray);   

        -- instantiated multiplier (work.mul_4_stage or work.mul_8_stage)
multiply_unit:  entity work.mul_4_stage(behav) generic map (INPUTS, OUTPUTS, DATA_SIZE_IN, DATA_SIZE_OUT)
--multiply_unit:  entity work.mul_8_stage(behav) generic map (INPUTS, OUTPUTS, DATA_SIZE_IN, DATA_SIZE_OUT)
port map (
clk => clk,
ce => oehb_ready,
a => dataInArray(0),
b => dataInArray(1),
p => dataOutArray(0));

buff: entity work.delay_buffer(arch) generic map(LATENCY-1)
port map(clk,
rst,
join_valid,
oehb_ready,
buff_valid);

oehb: entity work.OEHB(arch) generic map (1, 1, 1, 1)
        port map (
        --inputspValidArray
            clk => clk, 
            rst => rst, 
            pValidArray(0)  => buff_valid, -- real or speculatef condition (determined by merge1)
            nReadyArray(0) => nReadyArray(0),    
            validArray(0) => validArray(0), 
        --outputs
            readyArray(0) => oehb_ready,   
            dataInArray(0) => oehb_datain,
            dataOutArray(0) => oehb_dataOut
        );


end architecture;

