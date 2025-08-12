set -l seen '__fish_seen_subcommand_from'
set -l has_opt '__fish_contains_opt'
set -l commands help install shell toggle workspace-action scheme variant screenshot record clipboard clipboard-delete emoji-picker wallpaper pip
set -l not_seen "not $seen $commands"

# Disable file completions
complete -c caelestia -f

# Subcommands
complete -c caelestia -n $not_seen -a 'help' -d 'Show help'
complete -c caelestia -n $not_seen -a 'install' -d 'Install a module'
complete -c caelestia -n $not_seen -a 'shell' -d 'Start the shell or message it'
complete -c caelestia -n $not_seen -a 'toggle' -d 'Toggle a special workspace'
complete -c caelestia -n $not_seen -a 'workspace-action' -d 'Exec a dispatcher in the current group'
complete -c caelestia -n $not_seen -a 'scheme' -d 'Switch the current colour scheme'
complete -c caelestia -n $not_seen -a 'variant' -d 'Switch the current scheme variant'
complete -c caelestia -n $not_seen -a 'screenshot' -d 'Take a screenshot'
complete -c caelestia -n $not_seen -a 'record' -d 'Take a screen recording'
complete -c caelestia -n $not_seen -a 'clipboard' -d 'Open clipboard history'
complete -c caelestia -n $not_seen -a 'clipboard-delete' -d 'Delete from clipboard history'
complete -c caelestia -n $not_seen -a 'emoji-picker' -d 'Open the emoji picker'
complete -c caelestia -n $not_seen -a 'wallpaper' -d 'Change the wallpaper'
complete -c caelestia -n $not_seen -a 'pip' -d 'Picture in picture utilities'

# Install
set -l commands all btop discord firefox fish foot fuzzel hypr safeeyes scripts shell slurp spicetify gtk qt vscode
complete -c caelestia -n "$seen install && not $seen $commands" -a "$commands"

# Shell
set -l commands help mpris drawers wallpaper notifs
set -l not_seen "$seen shell && not $seen $commands"
complete -c caelestia -n $not_seen -a 'help' -d 'Show IPC commands'
complete -c caelestia -n $not_seen -a 'mpris' -d 'Mpris control'
complete -c caelestia -n $not_seen -a 'drawers' -d 'Toggle drawers'
complete -c caelestia -n $not_seen -a 'wallpaper' -d 'Wallpaper control'
complete -c caelestia -n $not_seen -a 'notifs' -d 'Notification control'

set -l commands getActive play pause playPause stop next previous list
set -l not_seen "$seen shell && $seen mpris && not $seen $commands"
complete -c caelestia -n $not_seen -a 'play' -d 'Play media'
complete -c caelestia -n $not_seen -a 'pause' -d 'Pause media'
complete -c caelestia -n $not_seen -a 'playPause' -d 'Play/pause media'
complete -c caelestia -n $not_seen -a 'next' -d 'Skip to next song'
complete -c caelestia -n $not_seen -a 'previous' -d 'Go to previous song'
complete -c caelestia -n $not_seen -a 'stop' -d 'Stop media'
complete -c caelestia -n $not_seen -a 'list' -d 'List media players'
complete -c caelestia -n $not_seen -a 'getActive' -d 'Get a property from the active MPRIS player'

set -l commands trackTitle trackArtist trackAlbum position length identity
set -l not_seen "$seen shell && $seen mpris && $seen getActive && not $seen $commands"
complete -c caelestia -n $not_seen -a 'trackTitle' -d 'Track title'
complete -c caelestia -n $not_seen -a 'trackArtist' -d 'Track artist'
complete -c caelestia -n $not_seen -a 'trackAlbum' -d 'Track album'
complete -c caelestia -n $not_seen -a 'position' -d 'Track position'
complete -c caelestia -n $not_seen -a 'length' -d 'Track length'
complete -c caelestia -n $not_seen -a 'identity' -d 'Player identity'

set -l commands list toggle
set -l not_seen "$seen shell && $seen drawers && not $seen $commands"
complete -c caelestia -n $not_seen -a 'list' -d 'List togglable drawers'
complete -c caelestia -n $not_seen -a 'toggle' -d 'Toggle a drawer'

set -l commands (caelestia shell drawers list)
complete -c caelestia -n "$seen shell && $seen drawers && $seen toggle && not $seen $commands" -a "$commands" -d 'drawer'

set -l commands list get set
set -l not_seen "$seen shell && $seen wallpaper && not $seen $commands"
complete -c caelestia -n $not_seen -a 'list' -d 'List wallpapers'
complete -c caelestia -n $not_seen -a 'get' -d 'Get current wallpaper path'
complete -c caelestia -n $not_seen -a 'set' -d 'Change wallpaper'
complete -c caelestia -n "$seen shell && $seen wallpaper && $seen set" -F

complete -c caelestia -n "$seen shell && $seen notifs && not $seen clear" -a 'clear' -d 'Clear popup notifications'

# Toggles
set -l commands communication music specialws sysmon todo
complete -c caelestia -n "$seen toggle && not $seen drawers && not $seen $commands" -a "$commands" -d 'toggle'

# Workspace action
set -l commands workspace workspacegroup movetoworkspace movetoworkspacegroup
complete -c caelestia -n "$seen workspace-action && not $seen $commands" -a "$commands" -d 'action'

# Scheme
set -q XDG_DATA_HOME && set -l data_dir $XDG_DATA_HOME || set -l data_dir $HOME/.local/share
set -l scheme_dir $data_dir/caelestia/scripts/data/schemes
set -l schemes (basename -a (find $scheme_dir/ -mindepth 1 -maxdepth 1 -type d))
set -l commands 'print' $schemes
complete -c caelestia -n "$seen scheme && not $seen $commands" -a 'print' -d 'Generate and print a colour scheme for an image'
complete -c caelestia -n "$seen scheme && not $seen $commands" -a "$schemes" -d 'scheme'
for scheme in $schemes
    set -l flavours (basename -a (find $scheme_dir/$scheme/ -mindepth 1 -maxdepth 1 -type d) 2> /dev/null)
    set -l modes (basename -s .txt (find $scheme_dir/$scheme/ -mindepth 1 -maxdepth 1 -type f) 2> /dev/null)
    if test -n "$modes"
        complete -c caelestia -n "$seen scheme && $seen $scheme && not $seen $modes" -a "$modes" -d 'mode'
    else
        complete -c caelestia -n "$seen scheme && $seen $scheme && not $seen $flavours" -a "$flavours" -d 'flavour'
        for flavour in $flavours
            set -l modes (basename -s .txt (find $scheme_dir/$scheme/$flavour/ -mindepth 1 -maxdepth 1 -type f))
            complete -c caelestia -n "$seen scheme && $seen $scheme && $seen $flavour && not $seen $modes" -a "$modes" -d 'mode'
        end
    end
end

# Variant
set -l commands vibrant tonalspot expressive fidelity fruitsalad rainbow neutral content monochrome
complete -c caelestia -n "$seen variant && not $seen $commands" -a "$commands" -d 'variant'

# Record
set -l not_seen "$seen record && not $has_opt -s h help"
complete -c caelestia -n "$not_seen && not $has_opt -s s sound && not $has_opt -s r region && not $has_opt -s c compression && not $has_opt -s H hwaccel" \
    -s 'h' -l 'help' -d 'Show help'
complete -c caelestia -n "$not_seen && not $has_opt -s s sound" -s 's' -l 'sound' -d 'Capture sound'
complete -c caelestia -n "$not_seen && not $has_opt -s r region" -s 'r' -l 'region' -d 'Capture region'
complete -c caelestia -n "$not_seen && not $has_opt -s c compression" -s 'c' -l 'compression' -d 'Compression level of file' -r
complete -c caelestia -n "$not_seen && not $has_opt -s H hwaccel" -s 'H' -l 'hwaccel' -d 'Use hardware acceleration'

# Wallpaper
set -l not_seen "$seen wallpaper && not $has_opt -s h help && not $has_opt -s f file && not $has_opt -s d directory"
complete -c caelestia -n $not_seen -s 'h' -l 'help' -d 'Show help'
complete -c caelestia -n $not_seen -s 'f' -l 'file' -d 'The file to switch to' -r
complete -c caelestia -n $not_seen -s 'd' -l 'directory' -d 'The directory to select from' -r

complete -c caelestia -n "$seen wallpaper && $has_opt -s f file" -F
complete -c caelestia -n "$seen wallpaper && $has_opt -s d directory" -F

set -l not_seen "$seen wallpaper && $has_opt -s d directory && not $has_opt -s F no-filter && not $has_opt -s t threshold"
complete -c caelestia -n $not_seen -s 'F' -l 'no-filter' -d 'Do not filter by size'
complete -c caelestia -n $not_seen -s 't' -l 'threshold' -d 'The threshold to filter by' -r

# Pip
set -l not_seen "$seen pip && not $has_opt -s h help && not $has_opt -s d daemon"
complete -c caelestia -n $not_seen -s 'h' -l 'help' -d 'Show help'
complete -c caelestia -n $not_seen -s 'd' -l 'daemon' -d 'Start in daemon mode'
