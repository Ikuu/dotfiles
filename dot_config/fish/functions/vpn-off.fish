function vpn-off --wraps='sudo wg-quick down cachy-NL-494' --wraps='protonvpn disconnect' --description 'alias vpn-off protonvpn disconnect'
    protonvpn disconnect $argv
end
