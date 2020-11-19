#!/bin/bash

[ -n "$SSH_TTY" ] && {
    export SHELL="$HOME/.bash-ssh" && chmod +x "$SHELL"
    [ "${BASH_SOURCE[0]}" == "${0}" ] && exec /bin/bash --rcfile "$SHELL" "$@"
}

[ -z "$PS1" ] && return

[ -f /etc/skel/.bashrc ] && . <(grep -v "^HIST.*SIZE=" /etc/skel/.bashrc)

HISTCONTROL=ignoredups
HISTSIZE=$((1024 * 1024))
HISTFILESIZE=$HISTSIZE
HISTTIMEFORMAT='%t%F %T%t'
[[ "$PROMPT_COMMAND" == *bash_eternal_history* ]] || export PROMPT_COMMAND+="${PROMPT_COMMAND:+ ;} history -a ; "'echo -e $USER\\t$HOSTNAME\\t$PWD\\t"$(history 1)" >> ~/.bash_eternal_history'
touch ~/.bash_eternal_history && chmod 0600 ~/.bash_eternal_history

alias c=cat
alias h='history $((LINES - 1))'
alias l="ls -aFC"
alias ll="ls -aFl"
alias m=less
alias cp="cp -i"
alias mv="mv -i"

bak() { cp $1 $1.$(date +%%F_%T); }
doh() { curl -s -H 'accept: application/dns+json' "https://dns.google.com/resolve?name=$1" | jq; }
sshb() { command ssh -t "$@" "bash --rcfile <(echo $(base64 <~/.bashrc|tr -d '\n')|base64 -d|tee \$HOME/.bash-ssh) -i"; }

#umask 0002
export EDITOR=vim

[ -d "$HOME/bin" ] && [[ ":$PATH:" != *":$HOME/bin:"* ]] && PATH="$HOME/bin:$PATH"

type -f rbenv >/dev/null 2>&1 && eval "$(rbenv init -)"
type -f pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"

[ -f ~/.ssh/id_rsa ] && [ -f ~/.ssh/id_rsa.pub ] && {
    export SSH_AUTH_SOCK=$(find /tmp/ssh-*/agent.* -user $LOGNAME 2>/dev/null | head -n1)
    [ -z "$SSH_AUTH_SOCK" ] && . <(ssh-agent)
    ssh-add -L | grep -q "$(cut -f1,2 -d' ' ~/.ssh/id_rsa.pub)" || ssh-add
}
[ -r ~/.byobu/prompt ] && . ~/.byobu/prompt

export DOCKER_HOST=unix:///var/run/docker.sock
