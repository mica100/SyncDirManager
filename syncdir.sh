#!/bin/bash
VERSION=0.2
#
# SyncDirManager (SDM) - synchronize directories
#
# Dependency on unison (https://www.cis.upenn.edu/~bcpierce/unison/)
#
# Copyright (C) 2016  Michael Augustin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#set -x
if ! type unison &>/dev/null; then
    if [ -x /usr/local/bin/unison ]; then
        export PATH=/usr/local/bin:$PATH
    else
        echo "Error: Tool unison not found"
        exit 1
    fi
fi

LOCAL_DIR="${LOCAL_DIR:-$HOME/SyncDirManager}"
mkdir -p "$LOCAL_DIR"

UNISON_OPT="-times -rsrc false -ignore \"Name .DS_Store\" -ignore \"Regex .*\\.syncdir\""

if [ $# -eq 0 ]; then
    cat <<EOF

Usage of Sync Dir Manager $(VERSION)
==============================================================================

    usage 1: $(basename $0) <directory> [<dirN>] ...

    Create config files with extension *.syncdir in $LOCAL_DIR for each 
    directory given in the arguments. The files can be moved into other
    locations before syncing is executed (see usage 2).

    usage 2: $(basename $0) <syncdir-file> [<syncdir-fileN>] ...

    Execute the synchronization between the 2 directories A and B, where:
      A: was writen in the syncdir-file (by the usage 1, which created this file)
      B: the same directory but below the directory where the syncdir file is

  SyncDirManager Copyright (C) 2016 Michael Augustin
  Feel free to contact me via mail <maugustin (at) gmx (dot) net>

  This program comes with ABSOLUTELY NO WARRANTY.
  This is free software, and you are welcome to redistribute it
  under certain conditions.
EOF
fi

# FUNCTIONS USED TO READ CONFIG FILE
function REMOTE 
{
    export CFG_RDIR="$1"
}

function INCLUDE 
{
    export CFG_INC="$CFG_INC '$1'"
}

function UNISON_CFG 
{
    export UNISON_OPT="$UNISON_OPT $*"
}

function INPLACE
{
    export INPLACE=1
}

function BATCH
{
    UNISON_CFG -batch 
}

function IGNORE
{
    UNISON_CFG "-ignore \"Name $1\""
}
function IGNORE_RE
{
    UNISON_CFG "-ignore \"Regex $1\""
}
function IGNORE_PATH
{
    UNISON_CFG "-ignore \"Path $1\""
}

function FAT
{
    UNISON_CFG "-fat"
}
function RUN 
{
    bash "$0" "$1"
}
# ENDOF FUNCTIONS USED IN CONFIG FILE

while [ $# -gt 0 ]; do
    ARG="$1"
    shift
    ARG_FILE="$(basename "$ARG")"
    if [ "${ARG_FILE/*.syncdir/syncdir}" = "syncdir" ]; then
        # execute sync if argument is a *.syncdir file
        (
            cd "$(dirname $ARG)"
            CFG_RDIR=
            CFG_INC=
            set -x
            source "$ARG_FILE"              # set RDIR from config file
            CFG_INC=$(echo "$CFG_INC" | sort | uniq)
            INC_OPT=$(eval "for i in $CFG_INC; do
                echo -n \"-path \\\"\$i\\\" \"
            done")
            export LOCAL_DIR="$(pwd -P)"
            echo "INFO: sync $LOCAL_DIR <=> $CFG_RDIR"
            echo "INFO: INCLUDES: $INC_OPT"
            echo "INFO: UNISON_OPT: $UNISON_OPT"
            if [ ! -d "$(basename "$CFG_RDIR")" ]; then
                (
                    IFS="
"
                for f in $(grep -l -E -a "Archive for root .*$LOCAL_DIR/$(basename "$CFG_RDIR")(,| |$)" -r $HOME/Library/Application\ Support/Unison); do
                    echo "INFO: remove old sync data about $CFG_RDIR"
                    rm -f "$f"
                done
                )
            fi
            #IFS="$OLDIFS"

            if [ ${INPLACE:-0} -eq 1 ]; then
                DEST=$(pwd -P)
            else
                DEST=$(pwd -P)/$(basename "$CFG_RDIR")
            fi

            #set -x

            if [ "${SYNCDIR_UI:-0}" -eq 0 ]; then
                # wait for exit in textmode
                eval unison -ui text -batch $UNISON_OPT $INC_OPT \"$DEST\" \"$CFG_RDIR\"
            else
                # run grapical UI in parallel
                eval unison -auto $UNISON_OPT $INC_OPT \"$DEST\" \"$CFG_RDIR\" &
            fi
            #set +x
        )
    else
        # write configuration file to $LOCAL_DIR
        RDIR="$ARG"
        INC="$(basename "$RDIR")"
        RDIR="$(dirname "$RDIR")"
        if [ -d "$RDIR" ]; then
            # get absolute path
            RDIR=$(cd "$RDIR" && pwd -P)
        fi

        LOCAL_CFG="syncdir_${RDIR//[\/\\ ]/_}.syncdir"
        if [ ! -f "$LOCAL_DIR/$LOCAL_CFG" -o "$INC" = "" ]; then
            cat >"$LOCAL_DIR/$LOCAL_CFG" <<EOF
# Sync Dir Manager - configuration file
VERSION=1
#
REMOTE "$RDIR"
# INPLACE                # do not sync in subdirectory
# FAT                    # sync a Windows FAT drive/directory
# IGNORE \.DS_store      # ignore files by this name
# IGNORE_RE .*Archive_.* # ignore files by this regexp
# IGNORE_PATH temp       # ignore files within this directory
# BATCH                  # run without user interaction
# INCLUDE <dir_or_file>  # sync only INCLUDED subdirs or files
EOF
        fi
        if [ "$INC" != "" ]; then
            # append INC parameter
            echo "INCLUDE \"$INC\"" >>"$LOCAL_DIR/$LOCAL_CFG"
        fi
        echo "INFO: created config $LOCAL_DIR/$LOCAL_CFG"
    fi
done
