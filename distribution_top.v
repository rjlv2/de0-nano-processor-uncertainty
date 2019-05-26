//top level

module top (clk48, led, byte_in, readssr_req, byte_received_ack, byte_ready, trigger);
	output [7:0]	led;
	input		clk48;
	
	input[7:0] byte_in; //[7:0] 
	output readssr_req;
	output byte_received_ack;
	input byte_ready;
	
	input trigger;
	
	reg start = 1'b0;

	wire		clk_proc;
	wire		clk_cache;
	wire		data_clk_stall;


	reg	clk24 = 0;
	reg	clk12 = 0;

	always @(posedge clk48) begin
		clk24 <= ~clk24;
	end
	always @(posedge clk24) begin
		clk12 <= ~clk12;
	end


	/*
	 *	Memory interface
	 */
	wire[31:0]	inst_in;
	wire[31:0]	inst_out;
	wire[31:0]	data_out;
	wire[31:0]	data_addr;
	wire[31:0]	data_WrData;
	wire		data_memwrite;
	wire		data_memread;
	wire[3:0]	data_sign_mask;
	
	//New
	wire[255:0] DataMem_DistOut_wire;
	wire[255:0] DataMem_DistIn_wire;
	wire DMemWrite_sig_wire;
	wire DMemRead_sig_wire;
	wire du_clk_stall;


	cpu processor(
		.clk(clk_proc),
		.inst_mem_in(inst_in),
		.inst_mem_out(inst_out),
		.data_mem_out(data_out),
		.data_mem_addr(data_addr),
		.data_mem_WrData(data_WrData),
		.data_mem_memwrite(data_memwrite),
		.data_mem_memread(data_memread),
		.data_mem_sign_mask(data_sign_mask),
		
		//New
		.DataMem_DistOut(DataMem_DistOut_wire),
		.DataMem_DistIn(DataMem_DistIn_wire),
		.DMemWrite_sig(DMemWrite_sig_wire),
		.DMemRead_sig(DMemRead_sig_wire),
		.du_clk_stall(du_clk_stall),
		.du_clk_in(clk_cache),
		
		.byte_in(byte_in), //[7:0] 
		.readssr_req(readssr_req),
		.byte_received_ack(byte_received_ack),
		.byte_ready(byte_ready)
	);

	instruction_memory inst_mem( 
		.addr(inst_in), 
		.out(inst_out)
	);

	data_mem data_mem_inst(
			.clk(clk_cache),
			.addr(data_addr),
			.write_data(data_WrData),
			.memwrite(data_memwrite), 
			.memread(data_memread), 
			.read_data(data_out),
			.sign_mask(data_sign_mask),
			.led(led),
			.clk_stall(data_clk_stall),
			
			//New interface signals
			.DMemRead(DMemRead_sig_wire),
			.DMemWrite(DMemWrite_sig_wire),
			.dist_in(DataMem_DistIn_wire),
			.dist_out(DataMem_DistOut_wire)
		);
	
	always @(posedge clk24) begin
		if(!trigger) begin
			start <= 1'b1;
		end
		if(inst_out == 32'h00000000) begin
			start <= 1'b0;
		end
	end

	assign clk_cache = start ? clk12 : 1'b0;
	assign clk_proc = (data_clk_stall | du_clk_stall) ? 1'b1 : clk_cache;
endmodule
