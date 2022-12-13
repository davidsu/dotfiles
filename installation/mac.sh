#!/bin/bash
#I hope this works!!!
#I hope this works!!!
#I hope this works!!!
function echoStep() {
	echo '\033[38;5;2m###################################       '$1'       ###################################\033[0m'
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
		git clone https://github.com/romkatv/zsh-defer.git $HOME/zsh-defer
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
		neovim \
		python3 

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
		pm2 \
		neovim \
		typescript
}

function installPipDependencies() {
	echoStep installPipDependencies
	pip3 install neovim
}

function installDocker() {
	echoStep installDocker
	curl 'https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=dd-smartbutton&utm_location=module' -o $HOME/Downloads/Docker.dmg
	open $HOME/Downloads/Docker.dmg
}

function installKarabinerElements() {
	echoStep installKarabinerElements
	curl 'https://github.com/pqrs-org/Karabiner-Elements/releases/download/v14.10.0/Karabiner-Elements-14.10.0.dmg' -o $HOME/Downloads/Karabiner-Elements.dmg
	open $HOME/Downloads/Karabiner-Elements.dmg
}

function installFlyCut() {
	echoStep installFlyCut
	curl -L 'https://github.com/TermiT/Flycut/releases/download/1.9.6/Flycut.1.9.6.zip' > $HOME/Downloads/flycut.zip
	sudo unzip $HOME/Downloads/flycut.zip -d /Applications
}

function installGCP() {
	echoStep installGCP
	if [[ ! -d $HOME/developer ]]; then
		mkdir $HOME/developer
	fi
	curl 'https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-411.0.0-darwin-arm.tar.gz?utm_source=cloud.google.com&utm_medium=referral' -o $HOME/developer/gcp.tar.gz
	tar -xvf $HOME/developer/gcp.tar.gz -C $HOME/developer
	source $HOME/developer/google-cloud-sdk/install.sh
}

function symlinks() {
	echoStep symlinks
	cd $HOME/.dotfiles
	for i in `git ls-files | grep symlink`; do 
		ln -sf $HOME/$i $HOME/.`sed -e "s#.symlink##" <<< $i`; 
	done
	ln -fs $HOME/.dotfiles/config/ $HOME/.config
	cd $HOME
}

function finishDotfileInstall() {
	echoStep finishDotfileInstall
	cd $HOME/.dotfiles
	git submodule update --init --recursive
	npm i
	cd $HOME/.dotfiles/js
	yarn
	yarn build
}

function finishNvimInstall() {
	echoStep finishNvimInstall
	git clone https://github.com/wbthomason/packer.nvim $HOME/.local/share/nvim/site/pack/packer/start/packer.nvim
	nvim -u $HOME/.dotfiles/installation/initNeovim.vim
}

function installProcedure() {
	installDocker
	installKarabinerElements
	installGCP
	sudoGemDependencies
	cloneDotFiles
	installBrewWithDependencies
	# installNeovimNightly
	installYarnDependencies
	installZshDependencies
	installPipDependencies
	symlinks
	finishDotfileInstall
	finishNvimInstall
	installFlyCut

	curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash

	cd $HOME/Library/Fonts && curl -fLo "Droid Sans Mono for Powerline Nerd Font Complete.otf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf

	chsh -s /bin/zsh
	zsh
}
if [[ -z $NO_GREEDY ]]; then
	installProcedure
fi
