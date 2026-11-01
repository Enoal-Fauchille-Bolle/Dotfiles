# Programs that never read .zshrc, such as the graphical session and what it starts,
# find node through the mise shims. A plain PATH entry on purpose: `mise activate
# --shims` from here, where Homebrew is not on PATH yet, would put the Homebrew bin
# dir ahead of the Debian tools (see .zshrc).
path=("$HOME/.local/share/mise/shims" $path)
