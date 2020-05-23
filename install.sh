#!/bin/bash

REPO_URL="https://raw.githubusercontent.com/amscad/go-vim-install/master"
DEPS_URL="$REPO_URL/deps"
RESR_URL="$REPO_URL/resources"

install_go() {
    curl -s "$1" | sudo tar -C /usr/local -xzvf -
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
    exit 0
}

install_vim() {
    packages=$(curl -s "$DEPS_URL/ubuntu_packages")
    plugins=$(curl -s "$DEPS_URL/vim_plugins")

    # Backup
    cp -f ~/.vimrc ~/.vimrc.old.$(date +%s)

    # Install packages
    sudo apt-get install -y ${packages[@]}

    # Plugin manager bootstrap
    mkdir -p ~/.vim/{autoload,bundle,colors,scripts}
    wget -P ~/.vim/autoload "https://tpo.pe/pathogen.vim"
    wget -P ~/.vim/colors "$RESR_URL/molokai.vim"

    # Clone necessary stuff
    for plugin in ${plugins[@]} ; do
        echo "INSTALLING plugin $plugin"
        git clone "https://${plugin}.git" ~/.vim/bundle/${plugin##*/}
    done

    # Closetag script and snippets
    curl -sL -o ~/.vim/scripts/closetag.vim "http://vim.sourceforge.net/scripts/download_script.php?src_id=4318"
    wget -P ~/.vim/bundle/vim-go/gosnippets/UltiSnips "$RESR_URL/go.snippets"

    # YCM compilation
    cd ~/.vim/bundle/YouCompleteMe && {
        git submodule update --init --recursive
        bash install.sh
    } && cd -

    # Powerline
    pip install --user powerline-status

    # Fonts
    mkdir -p ~/.{fonts,config/fontconfig/conf.d}
    wget -P ~/.fonts "http://jorrel.googlepages.com/Monaco_Linux.ttf"
    wget -P ~/.fonts "https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf"
    wget -P ~/.config/fontconfig/conf.d "https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf"
    fc-cache -vf ~/.fonts

    # Instant markdown
    sudo npm -g install instant-markdown-d

    # Vimrc
    wget -P ~ "$RESR_URL/.vimrc"

    # Path
    echo "export PATH=\$PATH:$(readlink -f ~/.local/bin)" >> ~/.profile
    exit 0
}


install_ws() {
    packages=$(curl -s "$RAW_URL/go_packages")

    # Prepare workspace path
    mkdir -p $1
    echo "export GOPATH=$1"             >> ~/.profile
    echo "export PATH=\$PATH:$1/bin"    >> ~/.profile
    . ~/.profile

    # Download dependencies
    cd ${GOPATH}
    for package in ${packages[@]} ; do
        go get ${package}
    done

    cd -
    exit 0
}

# Main
case $1 in
"-go")    install_go  $2;;
"-vim")   install_vim $2;;
"-work")  install_ws  $2;;
esac

echo "Usage : $0 OPTION"
echo "      OPTION {  "
echo "          -go TARBALL_URL : go installation"
echo "          -vim            : vim installation"
echo "          -work PATH      : workspace setup"
echo "      }"
exit 1
