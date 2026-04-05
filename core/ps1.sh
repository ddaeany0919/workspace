GOPATH=$HOME/go

# Reset
Color_Off='\[\e[0m\]' # Text Reset

# Colors will work nice when used with "Solarized" palette.
# Nothing new here
Normal='\[\e[00m\]'     # Normal
Red='\[\e[0;31m\]'      # Red
BRed='\[\e[01;31m\]'    # Red
Green='\[\e[0;32m\]'    # Green
BGreen='\[\e[01;32m\]'  # Green
Yellow='\[\e[0;33m\]'   # Yellow
BYellow='\[\e[01;33m\]' # Yellow
Blue='\[\e[0;34m\]'     # Blue
BBlue='\[\e[1;34m\]'    # Blue
Purple='\[\e[0;35m\]'   # Purple
BPurple='\[\e[1;35m\]'  # Purple
White='\[\e[0;37m\]'    # White
BWhite='\[\e[1;37m\]'   # White

function make_prompt {
    local EXIT="$?"          # MUST come first
    # Use built-in printf for date if bash 4.2+ (assumed)
    local NOW
    printf -v NOW '%(%s)T' -1

    PS1="\e[00m\n" # begin with a newline

    # virtual env
    if [[ -n "${VIRTUAL_ENV}" ]]; then
        PS1+="(${VIRTUAL_ENV##*/}) "
    fi

    if (( EXIT != 0 )); then
        PS1+="\e[0;41m✘ ${EXIT} ${Color_Off}" # red x with error status
    else
        PS1+="${Green}✔${Color_Off}" # green tick
    fi

    if [[ -n "${WORKSPACE_PROJECT}" ]]; then
        PS1+=" \e[3m${WORKSPACE_PROJECT}\e[0m"
    fi

    PS1+="\e[0;00;93m \t" # time (H:M:S), using PS1 escape code \t

    #local PSCHAR="┕▶"
    local PSCHAR="▶"

    # when running on server
    if [[ -n "${SSH_CLIENT}" ]]; then
        if (( EUID == 0 )); then
            PS1+=" ${Green}\u${Color_Off}@${Blue}\h${Color_Off}" # root: red hostname
            PSCHAR="\e[1;31m#\e[0m"
        else
            PS1+=" ${Green}\u${Color_Off}@${Blue}\h${Color_Off}" # non-root: green hostname
        fi

        if [[ -n "${WORKSPACE_PROJECT}" ]]; then
            PS1+="(${WORKSPACE_PROJECT}):${Yellow}\w${Color_Off}" # working directory
            set_tabtitle "${WORKSPACE_PROJECT}"
        else
            PS1+=":${Yellow}\w${Color_Off}" # working directory
            set_tabtitle "${USER}"
        fi
    else
        PS1+=" ${Blue}\u${Color_Off}"      # non-root: green hostname
        PS1+=" in ${Yellow}\w${Color_Off}" # working directory
        if [[ -n "${WORKSPACE_PROJECT}" ]]; then
            set_tabtitle "${WORKSPACE_PROJECT}"
        else
            set_tabtitle "${USER}"
        fi
    fi

  GIT_PS1_SHOWDIRTYSTATE=false     # * unstaged, + staged
  GIT_PS1_SHOWSTASHSTATE=false     # $ stashed
  GIT_PS1_SHOWUNTRACKEDFILES=false # % untracked
  GIT_PS1_SHOWCOLORHINTS=false
  # < behind, > ahead, <> diverged, = same as upstream
  #GIT_PS1_SHOWUPSTREAM="auto"
  # git with 2 arguments *sets* PS1 (and uses color coding)
  # __git_ps1 "${PS1}\e[0;000m" "\e[0;000m"

    # try to append svn
    # PS1+=`prompt_svn_stats`

    #PS1+=" \e[0;100;93m${TIMER_SHOW}" # runtime of last command
    PS1+="\e[0m\n${PSCHAR} " # prompt in new line
    #PS1+="\e[K\e[0m\n${PSCHAR} " # prompt in new line
}

# function _update_powerline_ps1() {
#     PS1="$($GOPATH/bin/powerline-go -error $?)"
# }

TRUELINE_USER_SHORTEN_HOSTNAME=true
TRUELINE_USER_ALWAYS_SHOW_HOSTNAME=true
# for trueline
declare -a TRUELINE_SEGMENTS=(
    'user,black,white,bold'
    'workspace,black,purple,bold'
    'working_dir,mono,cursor_grey,normal'
    'git,grey,special_grey,normal'
    'newline,black,orange,bold'
)
_trueline_has_workspace() {
    printf "%s" "${WORKSPACE_PROJECT}"
}
_trueline_workspace_segment() {
    local workspace_name="$(_trueline_has_workspace)"
    if [[ -n "$workspace_name" ]]; then
        local fg_color="$1"
        local bg_color="$2"
        local font_style="$3"
        local segment="$(_trueline_separator)"

        # segment+="$(_trueline_content "$fg_color" "$bg_color" "$font_style" " ${TRUELINE_SYMBOLS[aws_profile]} $profile_aws ")"
        segment+="$(_trueline_content "$fg_color" "$bg_color" "$font_style" " $workspace_name")"
        PS1+="$segment"
        _trueline_record_colors "$fg_color" "$bg_color" "$font_style"
    fi
}
# source $WORKSPACE_ROOT/bin/trueline/trueline.sh
set_tabtitle ${USER}
#if [ "$TERM" != "linux" ] && [ -f "$GOPATH/bin/powerline-go" ]; then
#  #PROMPT_COMMAND="_update_powerline_ps1; $PROMPT_COMMAND"
#  PS1="${BPurple}\A ${Green}\u${Color_Off}@${Blue}\h${Color_Off}:[${Yellow}\w${Color_Off}]${Purple}\n$ ${Normal}"
#elif [[ -n $SSH_CLIENT ]]; then
#  PROMPT_COMMAND=make_prompt
#else

if [[ -n $SSH_CLIENT ]]; then
    # PROMPT_COMMAND=make_prompt
    source $WORKSPACE_ROOT/bin/trueline/trueline.sh
elif [ ! -z ${WORKSPACE_PROJECT} ]; then
    PROMPT_COMMAND=make_prompt
else
    PS1="${BPurple}\A ${Green}\u${Color_Off}@${Blue}\h${Color_Off}:[${Yellow}\w${Color_Off}]${Purple}\n$ ${Normal}"
fi

#fi
