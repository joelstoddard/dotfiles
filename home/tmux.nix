# tmux, ported from .config/tmux/tmux.conf. TPM is replaced by Nix-managed
# plugins (pkgs.tmuxPlugins), so there is no clone-on-first-run step.
{ config, pkgs, ... }:

let
  palette = config.dotfiles.palette;
in
{
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    historyLimit = 10000;
    escapeTime = 10;
    focusEvents = true;
    terminal = "screen-256color";
    sensibleOnTop = false;

    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank
      tmux-sessionx
      {
        plugin = resurrect;
        extraConfig = "set -g @resurrect-capture-pane-contents 'on'";
      }
      {
        plugin = continuum; # keep last so it saves the fully-configured session
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '1'
        '';
      }
    ];

    extraConfig = ''
      # General Options
      set -sg terminal-overrides ",*:RGB"
      unbind -T copy-mode-vi MouseDragEnd1Pane
      bind -T copy-mode-vi WheelUpPane   send-keys -X -N 2 scroll-up
      bind -T copy-mode-vi WheelDownPane send-keys -X -N 2 scroll-down
      set -g renumber-windows on
      set -g repeat-time 1000
      set-option -g status-position top

      # Theme
      set -g pane-border-style "fg=black,bright,nobold"
      set -g pane-active-border-style "fg=black,bright"
      set -g status-style "bg=default,fg=black,bright"
      set -g message-style "bg=black,bright,fg=white,bright,nobold"
      set -g message-command-style "bg=black,bright,fg=white,bright,nobold"
      set -g status-left ""
      set -g status-right ""
      set -g status-justify "right"
      set -g status-left-style "fg=white,dim,nobold"
      set -g status-right-style "fg=white,dim,nobold"
      set -g window-status-format "●"
      set -g window-status-style "fg=white,dim,nobold"
      set -g window-status-current-format "●"
      set -g window-status-current-style "#{?window_zoomed_flag,fg=${palette.accent.orange}#,nobold,fg=white#,nobold}"
      set -g window-status-bell-style "fg=red,nobold"

      # Keybindings
      unbind r
      bind R source-file ~/.config/tmux/tmux.conf \; display-message "󰑓 Config reloaded"
      bind Up select-pane -U
      bind Left select-pane -L
      bind Down select-pane -D
      bind Right select-pane -R
      unbind %
      unbind '"'
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
      bind x kill-window
      bind -n C-Tab next-window
      bind -n C-S-Tab previous-window
      bind r command-prompt "rename-session %%"
      bind -n M-1 select-window -t :1
      bind -n M-2 select-window -t :2
      bind -n M-3 select-window -t :3
      bind -n M-4 select-window -t :4
      bind -n M-5 select-window -t :5
      bind -n M-6 select-window -t :6
      bind -n M-7 select-window -t :7
      bind -n M-8 select-window -t :8
      bind -n M-9 select-window -t :9
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection
      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5
      bind -r h resize-pane -L 5
      bind -r m resize-pane -Z
      bind f resize-pane -Z
      bind q detach-client
      bind e choose-window -Z
    '';
  };
}
