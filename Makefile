nvim_path ?= nvim

test: 
	./scripts/test

doc:  
	$(nvim_execs) --headless --noplugin -u ./tests/minit.lua -c "lua require('mini.doc').generate()" -c "qa!"
