# Development Tools

Simple way to install a bunch of development tools as isolated bundles.

The following tools are installed and configured as git submodules:

- https://github.com/syndbg/goenv
- https://github.com/pyenv/pyenv
- https://github.com/nvm-sh/nvm
- https://github.com/rbenv/rbenv
- https://github.com/rbenv/ruby-build

The rest of the tools are built from their GitHub repositories or downloaded from the corresponding released binaries using a shell script.

## Usage

```shell
git clone git@github.com/albertompe/dev-tools.git ${HOME}/dev-tools
cd {HOME}/dev-tools
make install
source ${HOME}/dev-tools/dev-profile
```
