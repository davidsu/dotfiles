# to use this "vimrc"

1. you'll need nvim: `brew install neovim`
2. install python3: `brew install python3`
3. enable python3 for nvim: `pip3 install neovim`
4. enable neovim rubygem ( I'll go ahead and suggest sudo here but you'll make yourself a favor on learning how to do this without sudo): `sudo gem install neovim`
5. you'll need [vimplug](https://github.com/junegunn/vim-plug): 

    ```
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ```

6. you'll need to symlink the config directory: `ln -s ~/.dotfiles/config ~/.config` - or from wherever you've downloaded these dotfiles to
7. open nvim and run `:PlugInstall<cr>` -- Note: you'll get a ton of errors on the first time you open nvim. Ignore them, `:PlugInstall<cr>` and restart nvim
8. run`:CocInstall coc-tsserver` so that typescript will play nice
9. install mysql - needed for [mysql_mru.vim](https://github.com/sudavid4/mysql-mru.vim)  `brew install mysql`
10. download and install a font compatible with nerdtree devicons:[nerd-fonts](https://github.com/ryanoasis/nerd-fonts#combinations). Once you've done that go to Iterm -> preferences -> profiles -> text -> change font -> choose "Droid Sans Mono for Powerline Nerd Font Complete.otf"
    ```
    cd ~/Library/Fonts && curl -fLo "Droid Sans Mono for Powerline Nerd Font Complete.otf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/DroidSansMono/complete/Droid%20Sans%20Mono%20Nerd%20Font%20Complete.otf
    ```
11. run `:UpdateRemotePlugins` inside vim
12. run `:CheckHealth` inside vim
