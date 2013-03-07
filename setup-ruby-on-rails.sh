#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Automated Ruby on Rails setup.

Original comments from Berkeley's SaaS Course setup script:
# this script configures a VirtualBox VM to work with following book versions:
# 0.8.0, 0.8.1
# run as default user with . configure_image.sh
# you'll need to provide root password ('password') once at startup
# please note this script is fragile, as public download urls may change

-h  Help"
	exit $1
}

while getopts "h" OPTION
do
	case $OPTION in
		h)	usage 1 ;;
		?)	usage 1 ;;
	esac
done

install_some_basic_programs() {
	#sudo apt-get update
	# sudo apt-get upgrade -y

	sudo apt-get install -y sqlite3 libsqlite3-dev libssl-dev openssl zlib1g zlib1g-dev zlibc libxslt-dev libxml2-dev git default-jre g++ build-essential
	sudo apt-get install -y texinfo compizconfig-settings-manager chromium-browser libreadline6-dev
	sudo apt-get install -y ruby rubygems
}

install_ruby() {
	cd
	wget http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.2-p290.tar.gz
	tar -zxvf ruby-1.9.2-p290.tar.gz
	cd ruby-1.9.2-p290
	./configure
	make
	sudo make install
	cd ..
	rm -rf ruby-1.9.2-p290/ ruby-1.9.2-p290.tar.gz
}

install_rubygems() {
	cd
	wget http://production.cf.rubygems.org/rubygems/rubygems-1.8.10.tgz
	tar -zxvf rubygems-1.8.10.tgz
	cd rubygems-1.8.10
	sudo ruby setup.rb
	cd ..
	rm -rf rubygems-1.8.10/ rubygems-1.8.10.tgz
}

install_a_bunch_of_gems() {
	cd
	sudo gem install rails --verbose # -v 3.1.0
	sudo gem install rspec-rails --verbose # -v 2.6.1
	sudo gem install cucumber --verbose # -v 1.0.6
	sudo gem install nokogiri --verbose # -v 1.5.0
	sudo gem install capybara --verbose # -v 1.1.1
	sudo gem install rcov --verbose # -v 0.9.10
	sudo gem install haml --verbose # -v 3.1.3
	sudo gem install sqlite3 --verbose # -v 1.3.4
	sudo gem install uglifier --verbose # -v 1.0.3
	sudo gem install heroku --verbose # -v 2.8.0
	sudo gem install execjs --verbose
	sudo gem install therubyracer --verbose
	sudo gem install flog --verbose
	sudo gem install flay --verbose
	sudo gem install reek --verbose
	sudo gem install rails_best_practices --verbose
	# sudo gem install churn --verbose
	# sudo gem install chronic --verbose # -v 0.3.0
	# sudo gem install metric_fu --verbose
	sudo gem install bundler --verbose
	sudo gem install haml --verbose
	sudo gem install simplecov --verbose
	sudo gem install factory_girl --verbose
	sudo gem install ruby-tmdb --verbose
	sudo gem install taps --verbose
	sudo gem install thinking-sphinx --verbose
	sudo gem install ruby-debug19 --verbose
}

install_additional_rails_related_applications() {
	cd
	sudo apt-get install -y sphinxsearch postgresql postgresql-server-dev-9.1
}

# # install aptana
# cd
# wget http://download.aptana.com/studio3/standalone/3.0.7/linux/Aptana_Studio_3_Setup_Linux_x86_3.0.7.zip
# unzip Aptana_Studio_3_Setup_Linux_x86_3.0.7.zip
# rm Aptana_Studio_3_Setup_Linux_x86_3.0.7.zip
# cd ~/Desktop
# ln -s ~/Aptana\ Studio\ 3/AptanaStudio3 AptanaStudio3

install_vim_and_rails_vim() {
	# http://biodegradablegeek.com/2007/12/using-vim-as-a-complete-ruby-on-rails-ide/
	cd
	sudo apt-get install -y vim
	echo "filetype on  \" Automatically detect file types." >> .vimrc
	echo "set nocompatible  \" no vi compatibility." >> .vimrc
	echo "" >> .vimrc
	echo "\" Add recently accessed projects menu (project plugin)" >> .vimrc
	echo "set viminfo^=\!" >> .vimrc
	echo "" >> .vimrc
	echo "\" Minibuffer Explorer Settings" >> .vimrc
	echo "let g:miniBufExplMapWindowNavVim = 1" >> .vimrc
	echo "let g:miniBufExplMapWindowNavArrows = 1" >> .vimrc
	echo "let g:miniBufExplMapCTabSwitchBufs = 1" >> .vimrc
	echo "let g:miniBufExplModSelTarget = 1" >> .vimrc
	echo "" >> .vimrc
	echo "\" alt+n or alt+p to navigate between entries in QuickFix" >> .vimrc
	echo "map <silent> <m-p> :cp <cr>" >> .vimrc
	echo "map <silent> <m-n> :cn <cr>" >> .vimrc
	echo "" >> .vimrc
	echo "\" Change which file opens after executing :Rails command" >> .vimrc
	echo "let g:rails_default_file='config/database.yml'" >> .vimrc
	echo "" >> .vimrc
	echo "syntax enable" >> .vimrc
	echo "" >> .vimrc
	echo "set cf  \" Enable error files & error jumping." >> .vimrc
	echo "set clipboard+=unnamed  \" Yanks go on clipboard instead." >> .vimrc
	echo "set history=256  \" Number of things to remember in history." >> .vimrc
	echo "set autowrite  \" Writes on make/shell commands" >> .vimrc
	echo "set ruler  \" Ruler on" >> .vimrc
	echo "set nu  \" Line numbers on" >> .vimrc
	echo "set nowrap  \" Line wrapping off" >> .vimrc
	echo "set timeoutlen=250  \" Time to wait after ESC (default causes an annoying delay)" >> .vimrc
	echo "\" colorscheme vividchalk  \" Uncomment this to set a default theme" >> .vimrc
	echo "" >> .vimrc
	echo "\" Formatting" >> .vimrc
	echo "set ts=2  \" Tabs are 2 spaces" >> .vimrc
	echo "set bs=2  \" Backspace over everything in insert mode" >> .vimrc
	echo "set shiftwidth=2  \" Tabs under smart indent" >> .vimrc
	echo "set nocp incsearch" >> .vimrc
	echo "set cinoptions=:0,p0,t0" >> .vimrc
	echo "set cinwords=if,else,while,do,for,switch,case" >> .vimrc
	echo "set formatoptions=tcqr" >> .vimrc
	echo "set cindent" >> .vimrc
	echo "set autoindent" >> .vimrc
	echo "set smarttab" >> .vimrc
	echo "set expandtab" >> .vimrc
	echo "" >> .vimrc
	echo "\" Visual" >> .vimrc
	echo "set showmatch  \" Show matching brackets." >> .vimrc
	echo "set mat=5  \" Bracket blinking." >> .vimrc
	echo "set list" >> .vimrc
	echo "\" Show $ at end of line and trailing space as ~" >> .vimrc
	echo "set lcs=tab:\ \ ,eol:$,trail:~,extends:>,precedes:<" >> .vimrc
	echo "set novisualbell  \" No blinking ." >> .vimrc
	echo "set noerrorbells  \" No noise." >> .vimrc
	echo "set laststatus=2  \" Always show status line." >> .vimrc
	echo "" >> .vimrc
	echo "\" gvim specific" >> .vimrc
	echo "set mousehide  \" Hide mouse after chars typed" >> .vimrc
	echo "set mouse=a  \" Mouse in all modesc" >> .vimrc
	mkdir .vim
	cd .vim
	wget http://www.vim.org/scripts/download_script.php?src_id=16429
	mv d* rails.zip
	unzip rails.zip
	rm -rf rails.zip
	# to allow :help rails, start up vim and type :helptags ~/.vim/doc
}

install_emacs_and_plugins() {
	# http://appsintheopen.com/articles/1-setting-up-emacs-for-rails-development/part/7-emacs-ruby-foo
	cd
	sudo apt-get install -y emacs
	wget https://github.com/downloads/magit/magit/magit-1.1.1.tar.gz
	tar -zxvf magit-1.1.1.tar.gz
	cd magit-1.1.1/
	make
	sudo make install
	echo "(require 'magit)" >> .emacs
	cd
	rm -rf magit-1.1.1/ magit-1.1.1.tar.gz
	cd /usr/share/emacs
	sudo mkdir includes
	cd includes
	sudo wget http://svn.ruby-lang.org/cgi-bin/viewvc.cgi/trunk/misc/ruby-mode.el
	sudo wget http://svn.ruby-lang.org/cgi-bin/viewvc.cgi/trunk/misc/ruby-electric.el
	cd
	echo "" >> .emacs
	echo "; directory to put various el files into" >> .emacs
	echo "; (add-to-list 'load-path \"/usr/share/emacs/includes\")" >> .emacs
	echo "" >> .emacs
	echo "(global-font-lock-mode 1)" >> .emacs
	echo "(setq font-lock-maximum-decoration t)" >> .emacs
	echo "" >> .emacs
	echo "; loads ruby mode when a .rb file is opened." >> .emacs
	echo "(autoload 'ruby-mode \"ruby-mode\" \"Major mode for editing ruby scripts.\" t)" >> .emacs
	echo "(setq auto-mode-alist  (cons '(\".rb$\" . ruby-mode) auto-mode-alist))" >> .emacs
	echo "(setq auto-mode-alist  (cons '(\".rhtml$\" . html-mode) auto-mode-alist))" >> .emacs
	echo "" >> .emacs
	echo "(add-hook 'ruby-mode-hook" >> .emacs
	echo "          (lambda()" >> .emacs
	echo "            (add-hook 'local-write-file-hooks" >> .emacs
	echo "                      '(lambda()" >> .emacs
	echo "                         (save-excursion" >> .emacs
	echo "                           (untabify (point-min) (point-max))" >> .emacs
	echo "                           (delete-trailing-whitespace)" >> .emacs
	echo "                           )))" >> .emacs
	echo "            (set (make-local-variable 'indent-tabs-mode) 'nil)" >> .emacs
	echo "            (set (make-local-variable 'tab-width) 2)" >> .emacs
	echo "            (imenu-add-to-menubar \"IMENU\")" >> .emacs
	echo "            (define-key ruby-mode-map \"\C-m\" 'newline-and-indent)" >> .emacs
	echo "            (require 'ruby-electric)" >> .emacs
	echo "            (ruby-electric-mode t)" >> .emacs
	echo "            ))" >> .emacs
}

rails_hack_to_add_therubyracer() {
	# rails hack to add therubyracer to the default gemfile
	cd /usr/local/lib/ruby/gems/1.9.1/gems/railties-3.1.0/lib/rails
	sudo chmod 777 generators/
	cd generators/
	sudo chmod 777 app_base.rb
	# this adds gem 'therubyracer' to the default gem file, by it after gem 'uglifier'
	sed '/gem '"'uglifier'"'/ a\            gem '"'therubyracer'"'' app_base.rb > app_base2.rb
	mv app_base2.rb app_base.rb
	sudo chmod 644 app_base.rb
	cd ..
	sudo chmod 755 generators
	cd ~/Documents
}

# turn off update popups
#cd
#gconftool -s --type bool /apps/update-notifier/auto_launch false
#gconftool -s --type bool /apps/update-notifier/no_show_notifications true

install_some_basic_programs
install_additional_rails_related_applications
install_a_bunch_of_gems
exit
