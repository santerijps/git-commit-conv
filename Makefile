cc		= tcc
out		= bin/git-commit-conv
flags	= -o $(out) -cc $(cc) -show-timings

build: bin src/main.v
	v $(flags) src/main.v

bin:
	mkdir bin
