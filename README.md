# chezmoi dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## What this repo manages

- shell startup files for `bash` and `zsh`
- `mise` tool versions
- OS/environment-specific package lists
- external themes and shell plugins

## Supported choices

The repo prompts for two template variables in `.chezmoi.toml.tmpl`:

- `distro`: `omarchy`, `macos`, or `kali`
- `chezmoi_env`: `dev` or `security`

Those values control package selection, shell setup, and which files are ignored on each host.

## Main configuration files

- `.chezmoi.toml.tmpl` — repo-level template data
- `.chezmoiexternal.toml.tmpl` — remote files and archives
- `.chezmoidata/packages.yaml` — package groups by OS and environment
- `dot_config/mise/config.toml.tmpl` — tool versions and optional installs
- `dot_zshrc.tmpl` / `dot_bashrc.tmpl` — shell startup files

## Working on the repo

- Preview changes with `chezmoi diff`
- Apply changes with `chezmoi apply`
- Validate templates with `./validate-dotfiles.sh`

## Bootstrap flow

1. Install `chezmoi`
2. Clone or initialize this repo on a new machine
3. Run `chezmoi diff` to preview the generated state
4. Run `chezmoi apply` when the result looks right

## Notes

- The repo is intended for macOS and Linux hosts.
- The package sets are split by OS, then by environment.
- Most tool versions are managed through `mise`.
