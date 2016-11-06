
Usage of Sync Dir Manager
==============================================================================

    usage 1: $(basename $0) <directory> [<dirN>] ...

Create config files with extension *.syncdir in $LOCAL_DIR for each
directory given in the arguments. The files can be moved into other
locations before syncing is executed (see usage 2).

    usage 2: $(basename $0) <syncdir-file> [<syncdir-fileN>] ...

Execute the synchronization between the 2 directories A and B, where:  
  A: was writen in the syncdir-file (by the usage 1, which created this file)
  B: the same directory but below the directory where the syncdir file is

Footer
======
SyncDirManager Copyright (C) 2016 Michael Augustin
Feel free to contact me via mail ```maugustin (at) gmx (dot) net```

This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions.
