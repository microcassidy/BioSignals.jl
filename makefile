all: format test docs
.PHONY: test
.PHONY: docs
docs:
	julia --project=docs docs/make.jl
test:
	julia --project=. -e 'using Pkg;Pkg.test()'
.PHONY: format
format:
	julia -e 'using JuliaFormatter;format(".")'
