#!/usr/bin/env fish

set -l homedir (eval echo ~$USER)
set -l root (dirname (realpath (status filename)))

# put cangjie fish script to user dir

set -l target_script "$homedir/.config/fish/conf.d/cangjie.fish"

if test -L $target_script
    unlink $target_script
end
ln -s "$root/fish/cangjie.fish" $target_script

