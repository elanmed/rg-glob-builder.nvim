.PHONY: dev test test-file docs lint deploy clean

dev:
	mkdir -p ~/.local/share/nvim/site/pack/dev/start/rg-pattern-builder.nvim
	stow -d .. -t ~/.local/share/nvim/site/pack/dev/start/rg-pattern-builder.nvim rg-pattern-builder.nvim

clean:
	rm -rf ~/.local/share/nvim/site/pack/dev

test:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

docs: 
	./deps/ts-vimdoc.nvim/scripts/docgen.sh README.md doc/rg-pattern-builder.txt rg-pattern-builder

lint: 
	# https://luals.github.io/#install
	lua-language-server --check=./lua --checklevel=error

deploy: test lint docs
