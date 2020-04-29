module delay
  #(
    parameter int 		cycles,
    parameter int 		width,
    parameter logic [width-1:0] init_val = 0    
    )
   (
    input 		     clk,
    input 		     rst = 0,
    input 		     en = 1,
    input [width-1:0] 	     data_in,
    output logic [width-1:0] data_out
    );

   logic [width:0] 	     regs[cycles];
   
   
   always_ff @(posedge clk or posedge rst)
     begin
	if (rst) begin
	   for (int i=0; i < cycles; i++) begin
	      regs[i] <= init_val;		 
	   end	   
	end
	else begin
	   if (en) begin
	      regs[0] <= data_in;
	      for (int i=0; i < cycles-1; i++) begin
		 regs[i+1] <= regs[i];		 
	      end	      
	   end
	end
     end

   assign data_out = regs[cycles-1];
      
endmodule
