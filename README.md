# open-tig

Open Tig in the project's root directory with `alt-shift-t`.

Open Tig on current file with `ctrl-shift-h`.

Open Tig blame on current file with `ctrl-shift-b`.

Based on package atom-terminal.

Keybindings: `alt-shift-t`, `ctrl-shift-h`, `ctrl-shift-b`

Install: `apm install open-tig`

Config:
```coffeescript
"open-tig":
    # only necessary if standard config doesn't find terminal app
    app: "/path/to/your/favorite/terminal"
    tig: "/path/to/tig"
    args: "--useThisOptionWhenLaunchingTig"
```
