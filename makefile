all: format test
.PHONY: test
test:
	julia --project=. -e 'using Pkg;Pkg.test()'
format:
	julia -e 'using JuliaFormatter;format(".")'
