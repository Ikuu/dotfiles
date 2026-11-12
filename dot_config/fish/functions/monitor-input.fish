function monitor-input --description 'Switch or show the Alienware AW3423DWF input source via DDC/CI'
    # Inputs advertised by the monitor (VCP 0x60). 0x13 is a Dell-specific code
    # that ddcutil doesn't name.
    set -l names dp1 second hdmi
    set -l codes 0f 13 11
    set -l ddc ddcutil --model AW3423DWF --skip-ddc-checks

    set -l target $argv[1]
    switch "$target"
        case '' status
            set -l cur (string lower ($ddc --terse getvcp 60 | string match -r 'x([0-9a-fA-F]+)$')[2])
            set -l i (contains -i -- $cur $codes)
            and echo "Current input: $names[$i] (0x$cur)"
            or echo "Current input: 0x$cur"
            return
        case toggle
            set -l cur (string lower ($ddc --terse getvcp 60 | string match -r 'x([0-9a-fA-F]+)$')[2])
            test "$cur" = 0f; and set target second; or set target dp1
        case -h --help
            echo "usage: monitor-input [status|toggle|"(string join '|' $names)"]"
            return
    end

    set -l i (contains -i -- $target $names)
    or begin
        echo "monitor-input: unknown input '$target' (expected: "(string join ', ' $names)")" >&2
        return 1
    end

    # --noverify: once the monitor switches away, reading the value back often
    # fails, which made the old aliases print spurious errors.
    $ddc --noverify setvcp 60 0x$codes[$i]
    and echo "Switched to $names[$i] (0x$codes[$i])"
end
