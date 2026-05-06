source /usr/share/cachyos-fish-config/cachyos-config.fish
source ~/.config/fzf/config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
end
#

starship init fish | source
zoxide init --cmd cd fish | source
