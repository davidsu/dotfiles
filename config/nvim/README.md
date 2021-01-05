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
9. ----
10. run `:UpdateRemotePlugins` inside vim
11. run `:CheckHealth` inside vim
