local function enable_transparency()
vim.api.nvim_set_hl(0, "Normal", { bg = "none"})
end
return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("gruvbox").setup({
        contrast = "", -- options: "hard", "soft", or "" (default medium)
      })
      vim.o.background = "dark" -- set to "light" for light mode
      vim.cmd.colorscheme("gruvbox")
    end,

  },
  {
      "nvim-lualine/lualine.nvim",
      dependencies = {
	  "nvim-tree/nvim-web-devicons",
	},
	opts = {
	    theme = "gruvbox",
	}
  },
}

