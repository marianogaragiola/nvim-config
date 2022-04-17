vim.cmd [[
try
  colorscheme gruvbox
  " colorscheme darkplus
catch /^Vim\%((\a\+)\)\=:E185/
  colorscheme default
  set background=dark
endtry
]]
