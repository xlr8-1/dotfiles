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
-- Only keep entries here that behave differently from the Omarchy default for
-- the same key. If a binding launches the exact same app/action as the
-- default, don't rebind it at all -- the default already covers it, and
-- rebinding it anyway makes the action fire twice (e.g. two terminal windows
-- on SUPER+RETURN). Anything customized below still needs hl.unbind() first
-- so the default and the override don't both fire.

-- Attaches to (or creates) the persistent "Work" tmux session, instead of the
-- default's always-new unnamed session.
hl.unbind("SUPER + ALT + RETURN")
o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new')

o.bind("SUPER + SHIFT + T", "Activity", "omarchy-launch-tui btop")

-- Skips the default's install-if-missing fallback and window-focus check.
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Music", "omarchy-launch-or-focus spotify")

-- Runs lazydocker directly, bypassing the default's docker-group/pkexec gate.
-- Only do this if you're already in the docker group.
hl.unbind("SUPER + SHIFT + D")
o.bind("SUPER + SHIFT + D", "Docker", "omarchy-launch-tui lazydocker")

-- Skips the default's install-if-missing fallback.
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Signal", 'omarchy-launch-or-focus signal "uwsm-app -- signal-desktop"')

-- Skips the default's install-if-missing fallback.
hl.unbind("SUPER + SHIFT + SLASH")
o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "1password" })

-- Overwrite existing bindings, like putting Omarchy Menu on Super + Ctrl + Space
-- (default: Background switcher)
hl.unbind("SUPER + CTRL + SPACE")
o.bind("SUPER + CTRL + SPACE", "Omarchy menu", "omarchy-menu")
