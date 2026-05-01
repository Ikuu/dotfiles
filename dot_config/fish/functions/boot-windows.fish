function boot-windows --wraps='sudo efibootmgr -n 0000 && reboot' --description 'alias boot-windows sudo efibootmgr -n 0000 && reboot'
    sudo efibootmgr -n 0000 && reboot $argv
end
