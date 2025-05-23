nvim_exec := env_var_or_default("NVIM_PATH", "nvim")

test: 
  ./scripts/test
doc:  
  {{nvim_exec}} --headless --noplugin -u ./tests/minit.lua -c "lua require('mini.doc').generate()" -c "qa!"
