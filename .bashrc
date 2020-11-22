#!/bin/bash

[ -n "$SSH_TTY" ] && {
    export SHELL="$HOME/.bash-ssh" && chmod +x "$SHELL"
    [ "${BASH_SOURCE[0]}" == "${0}" ] && exec bash --rcfile "$SHELL" "$@"
    ln -nsf /dev/tcp/127.0.0.1/$history_port ~/.bash-ssh.history
}

[ -z "$PS1" ] && return

[ -r /etc/skel/.bashrc ] && . <(grep -v "^HIST.*SIZE=" /etc/skel/.bashrc)

[ -z "$SSH_TTY" ] && {
    history_port=26574
    netstat -lnt|grep -q ":${history_port}\b" || {
        touch ~/.bash_eternal_history && chmod 0600 ~/.bash_eternal_history
        nc -kl 127.0.0.1 "$history_port" >>~/.bash_eternal_history &
    }
}

HISTSIZE=$((1024 * 1024))
HISTFILESIZE=$HISTSIZE
HISTTIMEFORMAT='%t%F %T%t'

update_eternal_history() {
    local old_umask=$(umask)
    local history_line="${USER}\t${HOSTNAME}\t${PWD}\t$(history 1)"
    history -a
    [ -n "$SSH_TTY" ] && echo -e "$history_line" >$(readlink ~/.bash-ssh.history) 2>/dev/null && return
    umask 077
    echo -e "$history_line" >> ~/.bash_eternal_history
    umask $old_umask
}

[[ "$PROMPT_COMMAND" == *update_eternal_history* ]] || export PROMPT_COMMAND="update_eternal_history;$PROMPT_COMMAND"

alias c=cat
alias h='history $((LINES - 1))'
alias l="ls -aFC"
alias ll="ls -aFl"
alias m=less
alias cp="cp -i"
alias mv="mv -i"

bak() { cp $1 $1.$(date +%%F_%T); }
doh() { curl -s -H 'accept: application/dns+json' "https://dns.google.com/resolve?name=$1" | jq; }
sshb() {
    local bashrc=$(base64 -w0 <~/.bashrc)
    local ssh="ssh -S ~/.ssh/control-socket-$(tr -cd '[:alnum:]' < /dev/urandom|head -c8)"
    $ssh -fNM "$@"
    local history_remote_port="$($ssh -O forward -R 0:127.0.0.1:$history_port placeholder)"
    $ssh "$@" -t "history_port=$history_remote_port bash --rcfile <(echo $bashrc|base64 -d|tee ~/.bash-ssh) -i"
    $ssh placeholder -O exit >/dev/null 2>&1
}

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
