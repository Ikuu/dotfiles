function cusage --description 'Show Claude Code usage with colour and progress bars'
    # Raw mode: cusage --raw (or any extra args) shows the original output
    if set -q argv[1]
        if test "$argv[1]" = --raw
            claude -p "/usage"
        else
            claude -p "/usage" $argv
        end
        return
    end

    set -l out (claude -p "/usage" </dev/null 2>&1)
    or begin
        printf '%s\n' $out
        return 1
    end

    set -l bold (set_color --bold)
    set -l dim (set_color brblack)
    set -l cyan (set_color cyan)
    set -l normal (set_color normal)
    set -l width 24

    echo
    echo "  $bold$cyan Claude usage$normal"
    echo

    for line in $out
        # Usage limit lines: "Current session: 70% used · resets Nov 13, 6:10pm (Europe/London)"
        if set -l m (string match -r '^Current (.+): (\d+)% used · resets (.+?)( \(.*\))?$' -- $line)
            set -l label $m[2]
            set -l pct $m[3]
            set -l reset $m[4]
            set label (string replace -r '^week \((.+)\)$' 'Week · $1' -- $label)
            set label (string replace -r '^session$' 'Session' -- $label)

            set -l filled (math "round($pct * $width / 100)")
            set -l empty (math "$width - $filled")

            # Gradient bar: each cell is coloured by its position along the
            # bar, green at 0% → yellow at 50% → red at 100%
            set -l bar ''
            set -l colour (__cusage_gradient 0)
            for i in (seq 1 $filled)
                set colour (__cusage_gradient (math "($i - 0.5) / $width"))
                set bar "$bar"(set_color $colour)'█'
            end
            set bar "$bar$dim$(string repeat -n $empty '░')$normal"

            # Percentage takes the colour of the bar's leading edge
            set colour (__cusage_gradient (math "$pct / 100"))

            printf '  %-20s %s %s%4s%%%s  %sresets %s%s\n' \
                $label "$bar" \
                (set_color --bold $colour) $pct $normal \
                $dim $reset $normal
            continue
        end

        # Section header
        if string match -q "What's contributing*" -- $line
            echo
            echo "  $bold$line$normal"
            continue
        end

        # Period lines: "Last 24h · 416 requests · 13 sessions"
        if set -l m (string match -r '^(Last \S+) · (.+)$' -- $line)
            echo
            echo "  $cyan$bold$m[2]$normal  $dim$m[3]$normal"
            continue
        end

        # Tip lines: "  75%  Start fresh when you switch tasks · run /clear"
        if set -l m (string match -r '^\s+(\d+%)\s+(.+?)(?: · (.+))?$' -- $line)
            set -l hint ''
            test -n "$m[4]"; and set hint "  $dim→ $m[4]$normal"
            printf '    %s%5s%s  %s%s\n' (set_color yellow) $m[2] $normal $m[3] "$hint"
            continue
        end

        # Top skills
        if set -l m (string match -r '^\s+Top skills: (.+)$' -- $line)
            echo "    $dim""Top skills:$normal $m[2]"
            continue
        end

        # Skip the subscription banner and blank lines; dim anything else
        string match -q 'You are currently using*' -- $line; and continue
        test -z "$line"; and continue
        echo "  $dim$line$normal"
    end
    echo
end

# Map 0..1 to a hex colour: green (#4ade80) → yellow (#facc15) → red (#ef4444)
function __cusage_gradient
    set -l t (math "min(1, max(0, $argv[1]))")
    set -l r; set -l g; set -l b
    if test $t -lt 0.5
        set -l u (math "$t * 2")
        set r (math "round(74 + (250 - 74) * $u)")
        set g (math "round(222 + (204 - 222) * $u)")
        set b (math "round(128 + (21 - 128) * $u)")
    else
        set -l u (math "($t - 0.5) * 2")
        set r (math "round(250 + (239 - 250) * $u)")
        set g (math "round(204 + (68 - 204) * $u)")
        set b (math "round(21 + (68 - 21) * $u)")
    end
    printf '%02x%02x%02x\n' $r $g $b
end
