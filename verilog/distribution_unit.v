//distribution logic unit

module distribution_unit(
		input clk,
		input DUCtrl,
		input[31:0] rs1,
		input[255:0] DU_input,
		output reg[255:0] DU_result,
		output reg du_clk_stall,
		
		//new
		input [7:0] byte_in,
		output reg readssr_req,
		output reg byte_received_ack,
		input byte_ready
	);
	
	parameter IDLE = 0;
	parameter REQ_READSSR = 1;
	parameter READ_BYTE = 2;
	parameter ACK_BYTE_RECEIVED = 3;
	parameter INCREMENT_INDEX = 4;
	parameter CREATE_DISTRIBUTION = 5;
	parameter DATA_OUT = 6;
	
	integer index = 0;
	
	integer state = 0;
	
	reg[7:0] buffer[0:39];
	
	//internal registers
	reg[255:0] dist_buffer;
	
	//state machine
	always @(posedge clk) begin
		case (state)
			IDLE: begin
				index <= 0;
				readssr_req <= 1'b0;
				byte_received_ack <= 1'b0;
				du_clk_stall <= 1'b0;
				if(DUCtrl) begin
					du_clk_stall <= 1'b1;
					state <= REQ_READSSR;
				end
			end
			
			REQ_READSSR: begin
				//connect to SPI module, retrive data
				//dist_buffer <= distribution;
				readssr_req <= 1'b1;
				if(byte_ready) begin
					state <= READ_BYTE;
				end
			end
			
			READ_BYTE: begin
				//a byte is read here
				buffer[index] <= byte_in;
				state <= ACK_BYTE_RECEIVED;
			end
			
			ACK_BYTE_RECEIVED: begin
				byte_received_ack <= 1'b1;
				// ack and wait for deassertion
				if(!byte_ready) begin
					byte_received_ack <= 1'b0;
					state <= INCREMENT_INDEX;
				end
			end
			
			INCREMENT_INDEX: begin
				byte_received_ack <= 1'b0;
				index <= index + 1;
				if(index == 39) begin //40 bytes
					readssr_req <= 1'b0;
					state <= CREATE_DISTRIBUTION;
				end else begin
					state <= REQ_READSSR;
				end
			end
			
			CREATE_DISTRIBUTION: begin
				readssr_req <= 1'b0;
				//dist_buffer <= {buffer[0], buffer[1], buffer[2], buffer[3], buffer[4], buffer[5], buffer[6], buffer[7], buffer[8][7:0], buffer[9], buffer[10][7:0], buffer[11], buffer[12][7:0], buffer[13], buffer[14][7:0], buffer[15], buffer[16][7:0], buffer[17], buffer[18][7:0], buffer[19], buffer[20][7:0], buffer[21], buffer[22][7:0], buffer[23], buffer[24][7:0], buffer[25], buffer[26][7:0], buffer[27], buffer[28][7:0], buffer[29], buffer[30][7:0], buffer[31], buffer[32][7:0], buffer[33], buffer[34][7:0], buffer[35], buffer[36][7:0], buffer[37], buffer[38][7:0], buffer[39]};
				dist_buffer <= {8'b0, buffer[1], 240'b0};
				state <= DATA_OUT;
			end
			
			DATA_OUT: begin
				DU_result <= dist_buffer;
				du_clk_stall <= 1'b0;
				readssr_req <= 1'b0;
				state <= IDLE;
			end
			
			default: begin
				//Illegal state, return to IDLE
				state <= IDLE;
			end
		endcase
	end
	
endmodule

