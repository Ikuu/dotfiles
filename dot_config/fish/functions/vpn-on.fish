function vpn-on --wraps='sudo wg-quick up cachy-NL-494' --wraps='protonvpn connect --country ' --description 'alias vpn-on protonvpn connect --country '
    protonvpn connect --country  $argv
end
