-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Application bindings
-- Note: some of these keys may overlap with Omarchy preinstalled defaults.
-- If bindings fire twice, set omarchy_preinstalled_bindings = false in hyprland.lua.
o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new')
o.bind("SUPER + RETURN", "Terminal", 'uwsm-app -- xdg-terminal-exec --working-directory="$(omarchy-cmd-terminal-cwd)"')
o.bind("SUPER + SHIFT + RETURN", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + F", "File manager", { launch = "nautilus --new-window" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", 'uwsm-app -- nautilus --new-window "$(omarchy-cmd-terminal-cwd)"')
o.bind("SUPER + SHIFT + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + M", "Music", "omarchy-launch-or-focus spotify")
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", "omarchy-launch-or-focus-tui cliamp")
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + SHIFT + T", "Activity", "omarchy-launch-tui btop")
o.bind("SUPER + SHIFT + D", "Docker", "omarchy-launch-tui lazydocker")
o.bind("SUPER + SHIFT + G", "Signal", 'omarchy-launch-or-focus signal "uwsm-app -- signal-desktop"')
o.bind("SUPER + SHIFT + O", "Obsidian", 'omarchy-launch-or-focus "^obsidian$" "uwsm-app -- obsidian"')
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "1password" })

-- If your web app url contains #, use %23 to avoid comment parsing issues
o.bind("SUPER + SHIFT + A", "ChatGPT", 'omarchy-launch-webapp "https://chatgpt.com"')

-- Overwrite existing bindings, like putting Omarchy Menu on Super + Space
-- hl.unbind("SUPER + SPACE")
o.bind("SUPER + CTRL + SPACE", "Omarchy menu", "omarchy-menu")
