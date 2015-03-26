# -*- sh -*- vim:set ft=sh ai et sw=4 sts=4:
# A mix from other themes

function _git_work_in_progress(){
	# Check if we are inside a git repo
	[ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1
	[[ $? -ne 0 ]] && return

	# Show stash count if any
	local stash_count="$(git stash list| wc -l | sed -E 's/ +//')"
	if [[ ${stash_count} -ne 0 ]]; then
		echo -n " %{$fg[magenta]%}(Stash: ${stash_count})"
	fi
	
	# Search for WIP commits in the last 10
	git log -n 10 | grep -q -c "\-\-wip\-\-" && echo -n " %{$fg[red]%}(WORK IN PROGRESS)"
}

# risto.zsh-theme
PROMPT='%{$fg[cyan]%}$(virtualenv_prompt_info)%{$fg[green]%}%n@%m %{$fg_bold[blue]%}%~ $(git_prompt_info)$(_git_work_in_progress) %{$reset_color%}
%(!.#.$) '

# murilasso.zsh-theme
local return_code="%(?..%{$fg[red]%}%? ↵ %{$reset_color%})"
RPROMPT="${return_code} [%*]"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX=" %{$reset_color%}"

# murilasso.zsh-theme
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}✗%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg[green]%}✔%{$reset_color%}"
