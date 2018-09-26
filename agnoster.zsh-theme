# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
if [[ -z "$PRIMARY_FG" ]]; then
  PRIMARY_FG=black
fi

# Characters
SEGMENT_SEPARATOR="\ue0b0"
PLUSMINUS="\u00b1"
BRANCH="\ue0a0"
DETACHED="\u27a6"
CROSS="\u2718"
LIGHTNING="\u26a1"
GEAR="\u2699"

# Config
agnoster_theme_display_git_master_branch=0
agnoster_theme_display_timediff=1
agnoster_theme_color_dir_fg=${agnoster_theme_color_dir_fg:=$PRIMARY_FG}
agnoster_theme_color_dir_bg=${agnoster_theme_color_dir_bg:=blue}
agnoster_theme_color_status_bg=${agnoster_theme_color_status_bg:=white}
agnoster_theme_shrink_path=${agnoster_theme_shrink_path:=${+functions[shrink_path]}}

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    print -n "%{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%}"
  else
    print -n "%{$bg%}%{$fg%}"
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && print -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    print -n "%{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    print -n "%{%k%}"
  fi
  print -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`

  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CONNECTION" ]]; then
    prompt_segment $PRIMARY_FG default " %(!.%{%F{yellow}%}.)$user@%m "
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local color ref
  is_dirty() {
    test -n "$(git status --porcelain --ignore-submodules)"
  }
  ref="$vcs_info_msg_0_"
  if [[ -n "$ref" ]]; then
    if [[ $agnoster_theme_display_git_master_branch == 0 && "$ref" == "master" ]]; then
      ref=""
    else
      ref+=" "
    fi
    if is_dirty; then
      color=yellow
      ref+="$PLUSMINUS"
    else
      color=green
    fi
    if [[ "${ref/.../}" == "$ref" ]]; then
      ref="$BRANCH $ref"
    else
      ref="$DETACHED ${ref/.../}"
    fi
    prompt_segment $color $PRIMARY_FG
    print -n " $ref"
  fi
}

# Dir: current working directory
prompt_dir() {
  if [[ $agnoster_theme_shrink_path != 0 ]]; then
    prompt_segment $agnoster_theme_color_dir_bg $agnoster_theme_color_dir_fg " $(shrink_path -f) "
  else
    prompt_segment $agnoster_theme_color_dir_bg $agnoster_theme_color_dir_fg ' %~ '
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}$CROSS $RETVAL"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}$LIGHTNING"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}$GEAR"

  [[ -n "$symbols" ]] && prompt_segment $agnoster_theme_color_status_bg $PRIMARY_FG " $symbols "
}

# Display current virtual environment
prompt_virtualenv() {
  if [[ -n $VIRTUAL_ENV ]]; then
    color=cyan
    prompt_segment $color $PRIMARY_FG
    print -Pn " $(basename $VIRTUAL_ENV) "
  fi
}

# Display time diff
prompt_timediff() {
  local now elapsed
  if [[ $agnoster_theme_display_timediff != 0 && -n "$agnoster_theme_internal_time" ]]; then
    now=$(date +%s%N)
    elapsed=$(( ($now - $agnoster_theme_internal_time) / 1000000 ))

    print -n "%{%F{white}%}"
    if [[ $elapsed -lt 100 ]]; then
      printf "%.1fms" $(( $elapsed ))
    elif [[ $elapsed -lt 1000 ]]; then
      printf "%.0fms" $(( $elapsed ))
    elif [[ $elapsed -lt 10000 ]]; then
      printf "%.2fs" $(( $elapsed / 1000.0 ))
    elif [[ $elapsed -lt 60000 ]]; then
      printf "%.1fs" $(( $elapsed / 1000.0 ))
    else
      printf "%dm %02ds" $(( $elapsed / 60000 )) $(( $elapsed / 1000 % 60 ))
    fi
    print -n "%{%f%}"
  fi
}

## Main prompt
prompt_agnoster_main() {
  RETVAL=$?
  CURRENT_BG='NONE'
  prompt_context
  prompt_virtualenv
  prompt_dir
  prompt_git
  prompt_status
  prompt_end
}

## Right prompt
prompt_agnoster_right() {
  prompt_timediff
}

prompt_agnoster_precmd() {
  vcs_info
  RPROMPT=$(prompt_agnoster_right)
  PROMPT='%{%f%b%k%}$(prompt_agnoster_main) '
  unset agnoster_theme_internal_time
}

prompt_agnoster_preexec() {
  agnoster_theme_internal_time=$(date +%s%N)
}

prompt_agnoster_setup() {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info

  prompt_opts=(cr subst percent)

  add-zsh-hook precmd prompt_agnoster_precmd
  add-zsh-hook preexec prompt_agnoster_preexec

  zstyle ':vcs_info:*' enable git
  zstyle ':vcs_info:*' check-for-changes false
  zstyle ':vcs_info:git*' formats '%b'
  zstyle ':vcs_info:git*' actionformats '%b (%a)'
}

prompt_agnoster_setup "$@"
