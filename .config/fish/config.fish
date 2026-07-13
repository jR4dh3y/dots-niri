## Run fastfetch as welcome message
function fish_greeting
    #fastfetch
end

# Format man pages
set -x MANROFFOPT "-c"
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Set settings for https://github.com/franciscolourenco/done
set -U __done_min_cmd_duration 10000
set -U __done_notification_urgency_level low

## Environment setup
# Apply .profile: use this to put fish compatible .profile stuff in
if test -f ~/.fish_profile
  source ~/.fish_profile
end

# Add ~/.local/bin to PATH
if test -d ~/.local/bin
    if not contains -- ~/.local/bin $PATH
        set -p PATH ~/.local/bin
    end
end

# Add Go-installed CLIs to PATH
if test -d ~/go/bin
    fish_add_path --prepend ~/go/bin
end

# Add depot_tools to PATH
if test -d ~/Applications/depot_tools
    if not contains -- ~/Applications/depot_tools $PATH
        set -p PATH ~/Applications/depot_tools
    end
end


## Functions
# Functions needed for !! and !$ https://github.com/oh-my-fish/plugin-bang-bang
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function mkcd
    mkdir -p $argv; and cd $argv
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

if [ "$fish_key_bindings" = fish_vi_key_bindings ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end

# Fish command history
function history
    builtin history --show-time='%F %T '
end

function backup --argument filename
    cp $filename $filename.bak
end

# Copy DIR1 DIR2
function copy
    set count (count $argv | tr -d \n)
    if test "$count" = 2; and test -d "$argv[1]"
        set from (echo $argv[1] | trim-right /)
        set to (echo $argv[2])
        command cp -r $from $to
    else
        command cp $argv
    end
end

## Useful aliases
# Replace ls with eza
alias ls='eza -al --color=always --group-directories-first --icons' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'  # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'  # long format
alias lt='eza -aT --color=always --group-directories-first --icons' # tree listing
alias l.="eza -a | grep -e '^\.'"                                     # show only dotfiles

# Common use
alias grubup="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias hw='hwinfo --short'                                   # Hardware Info
alias big="expac -H M '%m\t%n' | sort -h | nl"              # Sort installed packages according to size in MB
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'          # List amount of -git packages
alias update='sudo pacman -Syu'

# Get fastest mirrors
alias mirror="sudo cachyos-rate-mirrors"

# Help people new to Arch
alias tb='nc termbin.com 9999'
alias please='sudo'
# Cleanup orphaned packages
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'

# Get the error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# Recent installed packages
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

# random shits
alias oc='opencode .'

alias pico "sshpass -p '0410' ssh pico@192.168.1.2"

function mount-ext-drive
    printf '0410\n' | sudo -S mkdir -p /mnt/ext-drive
    and printf '0410\n' | sudo -S ntfs-3g /dev/sdb1 /mnt/ext-drive
end


# Violet Circuit prompt, matching ~/.config/nushell/config.nu.
function __forge_color
    set -l hex (string replace -a '#' '' -- $argv[1])

    if test (count $argv) -gt 1; and test "$argv[2]" = b
        set_color --bold $hex
    else
        set_color $hex
    end
end

function __forge_path
    set -l raw $PWD

    if test "$PWD" = "$HOME"
        set raw "~"
    else if string match -q "$HOME/*" -- $PWD
        set raw "~/"(string sub -s (math (string length -- $HOME) + 2) -- $PWD)
    end

    set -l parts (string split / -- $raw)

    if test (string length -- $raw) -gt 42; and test (count $parts) -gt 3
        if string match -q '/*' -- $raw
            printf '/…/%s/%s' $parts[-2] $parts[-1]
        else
            printf '%s/…/%s/%s' $parts[1] $parts[-2] $parts[-1]
        end
    else
        printf '%s' $raw
    end
end

function __forge_git_status
    command git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null
    or return 1

    set -l branch (command git branch --show-current 2>/dev/null | string trim)
    test -n "$branch"
    or return 1

    set -l staged 0
    set -l unstaged 0
    set -l untracked 0

    for line in (command git status --porcelain=v1 2>/dev/null)
        test -n "$line"
        or continue

        if string match -q '??*' -- $line
            set untracked (math $untracked + 1)
            continue
        end

        if test (string sub -s 1 -l 1 -- $line) != " "
            set staged (math $staged + 1)
        end

        if test (string sub -s 2 -l 1 -- $line) != " "
            set unstaged (math $unstaged + 1)
        end
    end

    set -l ahead 0
    set -l behind 0
    set -l upstream (command git rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null)
    set -l counts (string split -n -r '\s+' -- $upstream)

    if test (count $counts) -ge 2
        set behind $counts[1]
        set ahead $counts[2]
    end

    printf '%s\n%s\n%s\n%s\n%s\n%s\n' $branch $staged $unstaged $untracked $ahead $behind
end

function __forge_git_prompt_segment
    set -l git_status (__forge_git_status)
    or return

    if test (count $git_status) -lt 6
        return
    end

    set -l branch $git_status[1]
    set -l staged $git_status[2]
    set -l unstaged $git_status[3]
    set -l untracked $git_status[4]
    set -l ahead $git_status[5]
    set -l behind $git_status[6]

    set -l muted (__forge_color 9c96ad)
    set -l violet (__forge_color c59edc b)
    set -l lime (__forge_color c3fb5b b)
    set -l warning (__forge_color ffb86c b)
    set -l red (__forge_color ff6e79 b)
    set -l worktree

    if test $staged -eq 0; and test $unstaged -eq 0; and test $untracked -eq 0
        set worktree "$lime✓"
    else
        set -l worktree_parts

        if test $staged -gt 0
            set worktree_parts $worktree_parts "$lime+$staged"
        end

        if test $unstaged -gt 0
            set worktree_parts $worktree_parts "$warning~$unstaged"
        end

        if test $untracked -gt 0
            set worktree_parts $worktree_parts "$red?$untracked"
        end

        set worktree (string join "$muted " -- $worktree_parts)
    end

    set -l remote_parts

    if test $ahead -gt 0
        set remote_parts $remote_parts "$lime↑$ahead"
    end

    if test $behind -gt 0
        set remote_parts $remote_parts "$red↓$behind"
    end

    set -l remote (string join "$muted " -- $remote_parts)
    set -l remote_segment

    if test -n "$remote"
        set remote_segment " $remote"
    end

    printf '%s%s%s[%s%s%s]' $violet $branch $muted $worktree $remote_segment $muted
end

function __forge_duration_segment
    if not set -q CMD_DURATION
        return
    end

    if not string match -qr '^[0-9]+$' -- $CMD_DURATION
        return
    end

    if test $CMD_DURATION -ge 5000
        printf '%ss' (math $CMD_DURATION / 1000)
    end
end

function __forge_context_segment
    if set -q SSH_CONNECTION; and test -n "$SSH_CONNECTION"
        printf 'ssh'
    end
end

function __forge_right_prompt_text --argument-names last_status
    set -l reset (set_color normal)
    set -l muted (__forge_color 9c96ad)
    set -l lilac (__forge_color e6dfef)
    set -l warning (__forge_color ffb86c b)
    set -l red (__forge_color ff6e79 b)
    set -l parts

    set -l context (__forge_context_segment)
    if test -n "$context"
        set parts $parts "$lilac$context"
    end

    set -l git_segment (__forge_git_prompt_segment)
    if test -n "$git_segment"
        set parts $parts "$git_segment"
    end

    if test $last_status -ne 0
        set parts $parts "$red""exit $last_status"
    end

    set -l duration (__forge_duration_segment)
    if test -n "$duration"
        set parts $parts "$warning$duration"
    end

    set parts $parts "$muted"(date +%H:%M)

    printf '%s%s' (string join "$muted · " -- $parts) $reset
end

function fish_prompt
    set -g __forge_last_status $status

    set -l reset (set_color normal)
    set -l violet (__forge_color c59edc b)
    set -l lime (__forge_color c3fb5b b)
    set -l muted (__forge_color 9c96ad)
    set -l status_color $lime

    if test $__forge_last_status -ne 0
        set status_color (__forge_color ff6e79 b)
    end

    set -l first_line "$muted┌ $violet"(__forge_path)"$reset"
    set -l right_prompt (__forge_right_prompt_text $__forge_last_status)
    set -l columns 80

    if set -q COLUMNS; and string match -qr '^[0-9]+$' -- $COLUMNS; and test $COLUMNS -gt 0
        set columns $COLUMNS
    else
        set -l tput_columns (command tput cols 2>/dev/null)
        if string match -qr '^[0-9]+$' -- $tput_columns; and test $tput_columns -gt 0
            set columns $tput_columns
        end
    end

    set -l left_width (string length --visible -- $first_line)
    set -l right_width (string length --visible -- $right_prompt)
    set -l gap (math $columns - $left_width - $right_width)

    if test $gap -gt 1
        printf '%s%s%s\n' $first_line (string repeat -n $gap ' ') $right_prompt
    else
        printf '%s\n' $first_line
    end

    printf '%s└ %s❯%s ' $muted $status_color $reset
end

function fish_right_prompt
end

function fish_mode_prompt
end

# >>> grok installer >>>
fish_add_path $HOME/.grok/bin
# <<< grok installer <<<
