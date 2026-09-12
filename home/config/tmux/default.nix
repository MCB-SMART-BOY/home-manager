{ ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;
    historyLimit = 100000;
    baseIndex = 1;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    escapeTime = 0;
    terminal = "tmux-256color";
    extraConfig = ''
      set -g renumber-windows on
      set -g status-interval 5
      set -g set-clipboard on
      set -ga terminal-overrides ",xterm-256color:Tc"

      set -g status-style "bg=#0f172a,fg=#e2e8f0"
      set -g status-left "#[fg=#7dd3fc,bold] #S "
      set -g status-right "#[fg=#34d399] %Y-%m-%d %H:%M "
      set -g pane-border-style "fg=#253248"
      set -g pane-active-border-style "fg=#7dd3fc"

      bind | split-window -h
      bind - split-window -v
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"
    '';
  };
}
