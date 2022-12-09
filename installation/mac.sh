#!/bin/bash
#I hope this works!!!
#I hope this works!!!
#I hope this works!!!
function echoStep() {
	echo '###################################       '$1'       ###################################'
}
function sudoGemDependencies() {
	echoStep sudoGemDependencies
	sudo gem install neovim
	sudo gem install rouge
}

function cloneDotFiles() {
	echoStep cloneDotFiles
	if [ ! -d "$HOME/.dotfiles" ]; then
		git clone https://github.com/davidsu/dotfiles.git "${HOME}/.dotfiles"
	fi
}

function installZshDependencies() {
	echoStep installZshDependencies
	if [ ! -d "$HOME/.zgen" ]; then
		git clone https://github.com/tarjoilija/zgen.git "${HOME}/.zgen"
	fi

	if [ ! -d "$HOME/zsh-defer" ]; then
		git clone https://github.com/romkatv/zsh-defer.git ~/zsh-defer
	fi
}

function installBrewWithDependencies() {
	echoStep installBrewWithDependencies
	if ! command -v brew &> /dev/null; then
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	fi

	brew install \
		git \
		fnm \
		the_silver_searcher \
		ripgrep \
		zsh \
		coreutils \
		wget \
		entr \
		yarn \
		fasd \
		python3 

	brew install --cask karabiner-elements

	if ! command -v fzf &> /dev/null; then
		brew install fzf
		#why am I installing through fzf after installing with homebrew??? Doesn't seem to make much sense really
		$(brew --prefix)/opt/fzf/install
	fi
}

function installNeovimNightly() {
	echoStep installNeovimNightly
	if [[ ! -d $HOME/developer ]]; then
		mkdir $HOME/developer
	fi
	if [[ ! -d $HOME/developer/neovim ]]; then
		git clone --depth 1 --branch nightly https://github.com/neovim/neovim.git
		cd $HOME/developer/neovim
		brew install ninja libtool automake cmake pkg-config gettext
		make CMAKE_BUILD_TYPE=Release
		make install
	fi
}

function installYarnDependencies() {
	echoStep installYarnDependencies
	yarn global add \
		yarn-completions \
		tldr \
		pm2 \
		ndb \
		neovim \
		typescript
}


function symlinks() {
	echoStep symlinks
	cd $HOME/.dotfiles
	for i in `git ls-files | grep symlink`; do 
		ln -sf $HOME/$i $HOME/.`sed -e "s#.symlink##" <<< $i`; 
	done
	ln -fs ~/.dotfiles/config/ ~/.config
	cd $HOME
}

function finishDotfileInstall() {
	cd ~/.dotfiles
	git submodule update --init --recursive
	npm i
	cd ~/.dotfiles/js
	yarn
	yarn build
}

sudoGemDependencies
cloneDotFiles
installBrewWithDependencies
installNeovimNightly
installYarnDependencies
installZshDependencies
symlinks

pip3 install neovim
curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash

cd ~/Library/Fonts && curl -fLo "Droid Sans Mono for Powerline Nerd Font Complete.otf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf

chsh -s /bin/zsh
#install nvim's plugins and quit
#could do headless but what if it fails to download something... is it stuck??
#besides, nice to see things happening 
nvim -c 'au User PackerComplete quit' -c 'lua require("packer").install()'
zsh
