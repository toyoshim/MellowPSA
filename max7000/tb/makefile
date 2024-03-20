test_all: test_reset test_reg test_cgen test_move test_copy

clean:
	rm *.vcd a.out

test_reset:
	iverilog ../PSA.v PSA_reset.v && ./a.out

test_reg:
	iverilog ../PSA.v PSA_reg.v && ./a.out

test_cgen:
	iverilog ../PSA.v PSA_cgen.v && ./a.out

test_move:
	iverilog ../PSA.v PSA_move.v && ./a.out

test_copy:
	iverilog ../PSA.v PSA_copy.v && ./a.out
