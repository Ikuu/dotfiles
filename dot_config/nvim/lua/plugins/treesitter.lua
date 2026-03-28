return {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    build = ":TSUpdate",

    config = function()
	local configs = require("nvim-treesitter.configs")
	configs.setup({
	    highlight = { enable = true },
	    indent = { enable = true },
	    ensure_installed = {
		"lua",
		"tsx",
		"html",
	    },
	    auto_install = false,
	})
    end
}
