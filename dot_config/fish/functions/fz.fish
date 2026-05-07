function fz --wraps='xdg-open "$(fzf)"' --description 'alias fz=xdg-open "$(fzf)"'
    xdg-open "$(fzf)" $argv
end
