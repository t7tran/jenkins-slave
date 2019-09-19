# Max length of PWD to display
MAX_PWD_LENGTH=20

# Displays last X characters of pwd
# copied from hawaii50 theme
function limited_pwd() {

    # Replace $HOME with ~ if possible 
    RELATIVE_PWD=${PWD/#$HOME/\~}

    local offset=$((${#RELATIVE_PWD}-$MAX_PWD_LENGTH))

    if [ $offset -gt "0" ]
    then
        local truncated_symbol="..."
        TRUNCATED_PWD=${RELATIVE_PWD:$offset:$MAX_PWD_LENGTH}
        echo -e "${truncated_symbol}/${TRUNCATED_PWD#*/}"
    else
        echo -e "${RELATIVE_PWD}"
    fi
}

export PS1='$(tput bold)$(tput setaf 6)$(limited_pwd)$(tput sgr0)$ '

alias ll='ls -al'
git config --global credential.helper 'cache --timeout=3600'
HISTIGNORE='[ \t][ \t]*:history*:*[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd]*:*[Pp][Aa][Ss][Ss][Ww][Dd]*:exit:\:*:*bash_history*:?:??:mv *:cd *:cp *:rm *:mkdir *:echo *:cat *:kdpf*:vi *:ll *:ls *'