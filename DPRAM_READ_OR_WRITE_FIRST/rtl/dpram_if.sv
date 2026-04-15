//xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx INTERACE xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

interface dpram_if #(WIDTH,
					ADDR_BUS)(input bit clk);

	logic rst; 
	logic we;
	logic re;
	logic [ADDR_BUS-1:0] wr_adr;
	logic [ADDR_BUS-1:0] rd_adr;
	logic [WIDTH-1:0] din;
	logic [WIDTH-1:0]dout;

	clocking wr_drv_cb@(posedge clk);
		output rst; 
		output we;
		output wr_adr;
		output din;
	endclocking

	clocking wr_mon_cb@(posedge clk);
		input rst; 
		input we;
		input wr_adr;
		input din;
	endclocking

	clocking rd_drv_cb@(posedge clk);
		input rst; //! Only be observed so input. 
		output re;
		output rd_adr;
		input dout;
	endclocking

	clocking rd_mon_cb@(posedge clk);
		default input #0;
		input rst; 
		input re;
		input rd_adr;
		input dout;
	endclocking

	modport WR_DRV_MD(clocking wr_drv_cb);
	modport WR_MON_MD(clocking wr_drv_cb);
	modport RD_MON_MD(clocking wr_drv_cb);
	modport RD_DRV_MD(clocking wr_drv_cb);

endinterface 