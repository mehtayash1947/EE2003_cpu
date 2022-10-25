module cpu(input clk, input reset, output [31:0] iaddr, input [31:0] idata, output [31:0] daddr, input [31:0] drdata, output [31:0] dwdata, output [3:0] dwe);

	reg [31:0] iaddr;
	reg [31:0] daddr;
	reg [31:0] dwdata;
	reg [3:0]  dwe;
	reg [31:0] rf[0:31];
	reg [5:0] rf_addr;

	//ALU inputs and output
	reg signed [31:0] op1, op2, res;

	
	reg branch = 0;

	//Copies of registers for repeated assignments
	
	reg signed [31:0] rf_z[0:31]; 
	reg [31:0] iaddr_z;     


	




	integer i;
	
	
    always @(posedge clk) 
    
    begin
        if(reset) 
        begin
            iaddr <= 0;
            daddr <= 0;
            dwdata <= 0;
            dwe <= 0;
            for(i=0; i<32; i=i+1) 
            begin
                rf[i] <= 0;
                rf_z[i] <= 0;
            end
            iaddr_z <= 0;
            branch <= 0;
        end 
        
        else 
        begin 
            if(branch == 1) 
            begin
     			iaddr <= iaddr_z;
     		end
     		else 
     		begin
     			iaddr <= iaddr_z + 4;
     		end
     				
     		daddr <= 0;
            rf_z[0] <= 0; 
            
            for(i=1; i<32; i=i+1) 
            begin 
                rf[i] <= rf_z[i];
            end
            
        end
        
    end
    
    
    
	
	always @(*) 
	begin

    	branch = 0; 	
        dwdata = 0;
        dwe = 0;
        daddr = 0;
   
    	iaddr_z = iaddr;
        for(i=0; i<32; i=i+1) 
        begin 
            rf_z[i] = rf[i];
        end
        
        
        if(idata[1:0] == 'b11) 
        begin
        	// Load operation
        	if(idata[6:2] == 'b00000) 
        	begin
        		rf_addr = idata[11:7];
  				daddr = rf_z[idata[19:15]] + {{20{idata[31]}},idata[31:20]};      		
        		
				case(idata[14:12])
				
					'b000: rf_z[rf_addr] = {{24{drdata[7]}},drdata[7:0]};
					'b001: rf_z[rf_addr] = {{16{drdata[15]}},drdata[15:0]};
					'b010: rf_z[rf_addr] = drdata[31:0];
					'b100: rf_z[rf_addr] = {{24{1'b0}},drdata[7:0]};
					'b101: rf_z[rf_addr] = {{16{1'b0}},drdata[15:0]};
				
				endcase

		    end
		    
		    
			// Store operation
			if (idata[6:2] === 'b01000) 
			begin
				daddr = rf_z[idata[19:15]] + {{20{idata[31]}},idata[31:25],idata[11:7]};
				rf_addr = idata[24:20];
				rf_z[0] = 0; 
				dwe = 'b0001 << daddr[1:0];
				dwdata[8*daddr[1:0] + 7] = rf_z[rf_addr][7:0];
				if(idata[14:12] == 'b010)
				begin
					dwe = 'b1111;
					dwdata = rf_z[rf_addr];
				
				end
				
				case({idata[14:12], daddr[1:0]})
				
					'b00100: 
					begin
						dwe = 'b0011;
						dwdata[15:0] = rf_z[rf_addr][15:0];
					end
					
					'b00110:
					begin
						dwe = 'b1100;
						dwdata[15:0] = rf_z[rf_addr][15:0];
					end
					
				
				endcase
			
			end
			else
			    dwe = 0;
			
			//Load Upper Immediate
			if(idata[6:2] == 'b01101) 
			begin 
				rf_addr = idata[11:7];
		        rf_z[rf_addr] = {idata[31:12],{12{1'b0}}};
		        dwe = 0;
		    end
		    
		    //Add Upper Immediate to PC
		    if(idata[6:2] == 'b00101) 
		    begin 
				rf_addr = idata[11:7];
		        rf_z[rf_addr] = iaddr_z + {idata[31:12],{12{1'b0}}};
		        dwe = 0;
		    end
		    
        	//ALU immediate operations
        	if(idata[6:2] =='b00100) 
        	begin
        		op1 = rf_z[idata[19:15]];
				rf_addr = idata[11:7];
				op2 = {{20{idata[31]}},idata[31:20]};
				case(idata[14:12])
				
					'b000: res = op1 + op2;
					'b010: res = (op1 < op2) ? {{31{1'b0}},1'b1} : {32{1'b0}};
					'b011: res = (op1 < $unsigned(op2)) ? {{31{1'b0}},1'b1} : {32{1'b0}};
					'b100: res = op1 ^ op2;
					'b110: res = op1 | op2;
					'b111: res = op1 & op2;
					'b001: res = op1 << op2;
					'b101:
					begin
						if(idata[30])
							res = op1 >>> op2;
						else
							res = op1 >> op2;
					
					end
				
				endcase
				
				rf_z[rf_addr] = res;	
				dwe = 0;
				
			
			end
        	
        	//ALU default operations
        	if(idata[6:2] =='b01100) begin
        		op1 = rf_z[idata[19:15]];
				rf_addr = idata[11:7];
				op2 = rf_z[idata[24:20]];
				if({idata[14:12], idata[30]} == 'b0000)
				begin
					res = op1 + op2;
				end
				if({idata[14:12], idata[30]} == 'b0000)
				begin
					res = op1 - op2;
				end
				
				case(idata[14:12])
				
					'b010: res = (op1 < op2) ? {{31{1'b0}},1'b1} : {32{1'b0}};
					'b011: res = (op1 < $unsigned(op2)) ? {{31{1'b0}},1'b1} : {32{1'b0}};
					'b100: res = op1 ^ op2;
					'b110: res = op1 | op2;
					'b111: res = op1 & $unsigned(op2);
					'b001: res = op1 << op2;
					'b101:
					begin
						if(idata[30])
							res = op1 >>> op2[4:0];
						else
							res = op1 >> op2[4:0];
					
					end
				
				endcase
				
					
				rf_z[rf_addr] = res;	
				dwe = 0;
        	end
        	
        	//Jump and Link
     		if(idata[6:2] == 'b11011) begin
     			rf_z[idata[11:7]] = iaddr_z + 4;
     			rf_z[0] = 0; 
     			iaddr_z = iaddr + {{12{idata[31]}},idata[19:12],idata[20],idata[30:21],1'b0};
     			branch = 1;
     			dwe = 0;
     		end 	
     		
     	
     		if(idata[6:2] == 'b11001) begin
     			rf_z[idata[11:7]] = iaddr_z + 4;
     			rf_z[0] = 0; 
     			iaddr_z = (rf_z[idata[19:15]] + {{20{idata[31]}},idata[31:20]})&~1;
     			branch = 1;
     			dwe = 0;
     		end
     		
     		//BEQ
     		if(idata[6:2] == 'b11000 && idata[14:12] == 'b000) begin
     			if(rf_z[idata[24:20]] == rf_z[idata[19:15]]) begin
     				iaddr_z = iaddr_z + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
     				branch = 1;
     			end
     			dwe = 0;
     		end
     		
     		
     		//BNE
     		if(idata[6:2] == 'b11000 && idata[14:12] == 'b001) begin
     			if(rf_z[idata[24:20]] != rf_z[idata[19:15]]) begin
     				iaddr_z = iaddr_z + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
     				branch = 1;
     			end
     			dwe = 0;
     		end
     		
     		//BLT
     		if(idata[6:2] == 'b11000 && idata[14:12] == 'b100) begin
     			if((rf_z[idata[19:15]]) < (rf_z[idata[24:20]])) begin
     				iaddr_z = iaddr_z + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
     				branch = 1;
     			end
     			dwe = 0;
     		end
     		
     		
     		//BGE
     		if(idata[6:2] == 'b11000 && idata[14:12] == 'b101) begin
     			if((rf_z[idata[19:15]]) >= (rf_z[idata[24:20]])) begin
     				iaddr_z = iaddr_z + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
     				branch = 1;
     			end
     			dwe = 0;
     		end
     		
     		//BLTU
     		if(idata[6:2] == 'b11000 && idata[14:12] == 'b110) begin
     			if(rf_z[idata[19:15]] < rf_z[idata[24:20]]) begin
     				iaddr_z = iaddr_z + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
     				branch = 1;
     			end
     			dwe = 0;
     		end
     		
     		//BGEU
     		if(idata[6:2] == 'b11000 && idata[14:12] == 'b111) begin
     			if(rf_z[idata[19:15]] >= rf_z[idata[24:20]]) begin
     				iaddr_z = iaddr_z + {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
     				branch = 1;
     			end
     			dwe = 0;
     		end
        end
    end




endmodule

