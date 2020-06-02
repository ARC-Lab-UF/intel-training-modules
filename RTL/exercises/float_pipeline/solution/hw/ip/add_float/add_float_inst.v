	add_float u0 (
		.a      (_connected_to_a_),      //   input,  width = 32,      a.a
		.areset (_connected_to_areset_), //   input,   width = 1, areset.reset
		.b      (_connected_to_b_),      //   input,  width = 32,      b.b
		.clk    (_connected_to_clk_),    //   input,   width = 1,    clk.clk
		.en     (_connected_to_en_),     //   input,   width = 1,     en.en
		.q      (_connected_to_q_)       //  output,  width = 32,      q.q
	);

