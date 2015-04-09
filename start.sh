#!/bin/bash
default_machine()
{
    cat Makefile  | grep "^[^#]*RECIPE" | head -n 1 | cut -d'=' -f 2
}
usage()
{
    echo "Usage $0 [options]"
    echo "Starts a VM after building it with kameleon if needed"
    echo "Options:"
    echo "-R            Restore the backup vm using make restore"
    echo "-p            Update dir from host to vm (push), default dir $dir"
    echo "-P            Update dir from vm to host (pull), default dir $dir"
    echo "-r recipe     Choose the recipe to start, default $(default_machine)"
    echo "-d dir        Set the dir to push/pull, default $dir"
    echo "-n            Do not start the VM"
    echo "-h            Display this help and exit"
}
push_pull()
{

    echo "Can't use -p and -P at the same time"
    usage
    exit 1
}

dir=$HOME/Work/Moca
push=false
pull=false
restore=false
startVM=true

while getopts "r:d:pPhRn" opt
do
    case $opt in
        R)
            restore=true
            ;;
        P)
            pull=true
            if $push
            then
                push_pull
            fi
            ;;
        p)
            push=true
            if $pull
            then
                push_pull
            fi
            ;;
        r)
            machine="RECIPE=$OPTARG"
            ;;
        h)
            echo "HELP"
            usage
            exit 0
            ;;
        d)
            dir="$OPTARG"
            ;;
        n)
            startVM=false
            ;;
        *)
            echo "Invalid argument $opt"
            usage
            exit 2
            ;;
    esac
done

$restore && make $machine restore
if $pull || $push
then
    make $machine mount
    if $push
    then
        dest="./mnt$dir"
        src="$dir"
        rm -rvf $dest
    else
        src="./mnt$dir"
        dest="$dir"
    fi
    mkdir -p $dest
    cp -rv $src/* $dest/
    cp -rv $src/.git* $dest/
    make $machine umount
fi
if $startVM
then
    make $machine
fi
