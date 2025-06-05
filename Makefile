nvim_path ?= nvim
PANVIMDOC_PATH ?= $(or $(PANVIMDOC),deps/panvimdoc)

test: 
	./scripts/test

doc:
	@echo Generating Docs...
	@pandoc \
		--metadata="project:continue" \
		--metadata="vimversion:NVIM v0.10.0" \
		--metadata="titledatepattern:%Y %B %d" \
		--metadata="toc:true" \
		--metadata="incrementheadinglevelby:0" \
		--metadata="treesitter:true" \
		--metadata="dedupsubheadings:true" \
		--metadata="ignorerawblocks:true" \
		--metadata="docmapping:false" \
		--metadata="docmappingproject:true" \
		--shift-heading-level-by -1 \
		--lua-filter $(PANVIMDOC_PATH)/scripts/include-files.lua \
		--lua-filter $(PANVIMDOC_PATH)/scripts/skip-blocks.lua \
		-t $(PANVIMDOC_PATH)/scripts/panvimdoc.lua \
		doc/continue.md \
		-o doc/continue.txt

deps:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/kdheepak/panvimdoc deps/panvimdoc
