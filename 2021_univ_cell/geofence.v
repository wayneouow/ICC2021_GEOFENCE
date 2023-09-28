module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;

output valid;
output is_inside;


reg valid;
reg is_inside;

reg [9:0] target_X, target_Y;
reg [9:0] f_X [0:5];
reg [9:0] f_Y [0:5];

reg [2:0] port_cnt;
reg [1:0] state; 	//0 -> read
					//1 -> sort
					//2 -> estimate
reg [2:0] idx_A;
reg [2:0] idx_B;

wire [2:0]next;
assign next = (port_cnt==5)? 0 : port_cnt +1;


wire signed [21:0]cross_product_F0;
assign cross_product_F0 =((f_X[idx_A]-f_X[0])*(f_Y[idx_B]-f_Y[0]))-((f_Y[idx_A]-f_Y[0])*(f_X[idx_B]-f_X[0]));

wire signed [21:0]cross_product_target;
assign cross_product_target =((f_X[port_cnt]-target_X)*(f_Y[next]-f_Y[port_cnt]))-((f_X[next]-f_X[port_cnt])*(f_Y[port_cnt]-target_Y));

//save X, Y
integer i;
always@(posedge reset or posedge clk)begin
	if(reset || valid)begin
		target_X <= 10'd0;
		target_Y <= 10'd0;
		for(i=0 ; i < 6 ; i = i+1) begin
			f_X[i] <= 10'd0;
			f_Y[i] <= 10'd0;
		end
	end	
	
	else if(port_cnt==0 && X && state == 2'd0)begin
		target_X <= X;
		target_Y <= Y;
	end
	else if(port_cnt<=6 && X && state == 2'd0)begin
		f_X[port_cnt-1] <= X;
		f_Y[port_cnt-1] <= Y;
	end
end


//port_cnt
always@(posedge reset or posedge clk)begin
	if(reset)
		port_cnt <= 3'd0;
	else if(valid)
		port_cnt <= 3'd0;
	else if(state == 2'd0)
		port_cnt <= (port_cnt<3'd6)? port_cnt + 1 : 3'd0;

	else if(state == 2'd2)
		port_cnt <= (port_cnt<3'd5)? port_cnt + 1 : 3'd0;

end

//state
always@(posedge reset or posedge clk)begin
	if(reset)
		state <= 2'd0;
	else if(valid)
		state <= 2'd0;
	else if(port_cnt == 3'd6 && state == 2'd0)
		state <= 2'd1;
	else if(idx_A == 3'd5 && state == 2'd1)
		state <= 2'd2;

	
end

always@(posedge reset or posedge clk)begin

	if(state == 2'd0)begin
		idx_A <= 3'd1;
		idx_B <= 3'd2;
	end
	
	else if(state == 2'd1)begin

		if(cross_product_F0>=0 && idx_B<=3'd5)begin
		
			if(idx_B == 3'd5)begin
				idx_A <= idx_A + 1;
				idx_B <= idx_A + 2;
			end
			else 
				idx_B <= idx_B + 1;
		end
		
		
		else if(cross_product_F0<0 && idx_B<=3'd5)begin
		
			f_X[idx_A] <= f_X[idx_B];
			f_Y[idx_A] <= f_Y[idx_B];
			
			for(i=idx_A+1 ; i<=idx_B ; i= i+1)begin
				f_X[i]<=f_X[i-1];
				f_Y[i]<=f_Y[i-1];
			end
			if(idx_B == 3'd5)begin
				idx_A <= idx_A + 1;
				idx_B <= idx_A + 2;
			end
			else 
				idx_B <= idx_A+1;
		end	
	end
end

always@(posedge reset or posedge clk)begin
	if(reset)
		is_inside <= 1'b0;
	else if(state == 2'd0)
		is_inside <= 1'b0;
		
	else if(state == 3'd2 && cross_product_target<=0)
		is_inside <= 1'b0;
	else if(state == 3'd2 && port_cnt == 3'd5)
		is_inside <= 1'b1;
end

always@(posedge reset or posedge clk)begin
	if(reset)
		valid <= 1'b0;
	else if(valid)
		valid <= 1'b0;
	else if(state == 3'd2 && cross_product_target<=0)
		valid <= 1'b1;
	else if(state == 3'd2 && port_cnt == 3'd5)
		valid <= 1'b1;

	else 
		valid <= 1'b0;	
end

endmodule

