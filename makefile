SRC_DEPS=
test:
	julia --project=. 'using Pkg;Pkg.test()'
