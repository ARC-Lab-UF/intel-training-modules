	component mult_float is
		port (
			a      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- a
			areset : in  std_logic                     := 'X';             -- reset
			b      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- b
			clk    : in  std_logic                     := 'X';             -- clk
			en     : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- en
			q      : out std_logic_vector(31 downto 0)                     -- q
		);
	end component mult_float;

	u0 : component mult_float
		port map (
			a      => CONNECTED_TO_a,      --      a.a
			areset => CONNECTED_TO_areset, -- areset.reset
			b      => CONNECTED_TO_b,      --      b.b
			clk    => CONNECTED_TO_clk,    --    clk.clk
			en     => CONNECTED_TO_en,     --     en.en
			q      => CONNECTED_TO_q       --      q.q
		);

