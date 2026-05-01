function firmware --wraps='sudo systemctl reboot --firmware-setup' --description 'alias firmware sudo systemctl reboot --firmware-setup'
    sudo systemctl reboot --firmware-setup $argv
end
