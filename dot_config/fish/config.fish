source /usr/share/cachyos-fish-config/cachyos-config.fish
source ~/.config/fzf/config.fzf

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
end
#

fzf --fish | source
starship init fish | source
zoxide init --cmd cd fish | source
