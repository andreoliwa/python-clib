# -*- sh -*- vim:set ft=sh ai et sw=4 sts=4:
# A mix from other themes

function _git_stash_count(){
	# Check if it's a Git dir
	[ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1
	[[ $? -ne 0 ]] && return

	# Show stash count
	local stash_count=$(git stash list| wc -l)
	[[ ${stash_count} -eq 0 ]] && return
	echo " %{$fg[red]%}(stash: ${stash_count})%{$reset_color%}"
}

# risto.zsh-theme
PROMPT='%{$fg[cyan]%}$(virtualenv_prompt_info)%{$fg[green]%}%n@%m %{$fg_bold[blue]%}%~ $(git_prompt_info)$(_git_stash_count) %{$reset_color%}
%(!.#.$) '

# murilasso.zsh-theme
local return_code="%(?..%{$fg[red]%}%? ↵ %{$reset_color%})"
RPROMPT="${return_code} [%*]"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX=" %{$reset_color%}"

# murilasso.zsh-theme
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔%{$reset_color%}"
