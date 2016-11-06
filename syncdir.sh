#!/bin/bash
VERSION=0.1
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

UNISON_OPT="-times"

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


OLDIFS="$IFS"
IFS="
"
while [ $# -gt 0 ]; do
    ARG="$1"
    shift
    ARG_FILE="$(basename "$ARG")"
    if [ "${ARG_FILE/*.syncdir/syncdir}" = "syncdir" ]; then
        # execute sync if argument is a *.syncdir file
        (
            cd "$(dirname $ARG)"
            source "$ARG_FILE"              # set RDIR from config file
            export LOCAL_DIR="$(pwd -P)"
            echo "INFO: sync $LOCAL_DIR <=> $RDIR"
            if [ ! -d "$(basename "$RDIR")" ]; then
                (
                for f in $(grep -l -E -a "Archive for root .*$LOCAL_DIR/$(basename "$RDIR")[, $]" $HOME/Library/Application\ Support/Unison/*); do
                    echo "INFO: remove old sync data about $RDIR"
                    rm -f "$f"
                done
                )
            fi
            IFS=$OLDIFS

            if [ "${SYNCDIR_UI:-0}" -eq 0 ]; then
                # wait for exit in textmode
                unison -ui text -batch $UNISON_OPT "$RDIR" "$(pwd -P)/$(basename "$RDIR")" 
            else
                # run grapical UI in parallel
                unison -auto $UNISON_OPT "$RDIR" "$(pwd -P)/$(basename "$RDIR")" &
            fi
        )
    else
        # write configuration file to $LOCAL_DIR
        RDIR="$ARG"
        if [ -d "$RDIR" ]; then
            # get absolute path
            RDIR=$(cd "$RDIR" && pwd -P)
        fi

        LOCAL_CFG="syncdir_${RDIR//[\/\\ ]/_}.syncdir"
        cat >"$LOCAL_DIR/$LOCAL_CFG" <<EOF
export RDIR="$RDIR"
EOF
        echo "INFO: created config $LOCAL_DIR/$LOCAL_CFG"
    fi
done
