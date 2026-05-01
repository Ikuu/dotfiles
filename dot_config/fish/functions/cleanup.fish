function cleanup --wraps='sudo pacman -Rns (pacman -Qtdq)' --wraps=./Scripts/Cleanup.sh --description 'alias cleanup=./Scripts/Cleanup.sh'
    ./Scripts/Cleanup.sh $argv
end
