# btrfs_snap
Create, remove and list your snapshots.  Works with crontab.

##  What is does  tl;dr
The script btrfs_snap.sh is given parameters to create hourly|daily|weekly|monthly|yearly snapshots.\
Location of the snaps are set in string `base_dir="/home/.snapshots/"` in the script.\
There are 2 target directories to snap; the data share /home/DATA (Users shared files) and PCs /home/BACKUP/PCs\
These can be easily changed to suit you.

## Usage
Usage: /usr/local/sbin/btrfs_snap.sh function location                                                                       
You must specify what to snapshot and where it will go.                                                                  
functions: server|PC|clear|list|errors
location: hourly|daily|weekly|monthly|yearly
clear does not need another param, it removes old snaps

Example:
/usr/local/sbin/btrfs_snap.sh PC daily         will initate a snapshot on /home/BACKUP/PCs/ labelled daily
/usr/local/sbin/btrfs_snap.sh server weekly    will initate a snapshot on the server /etc/ and /home/DATA/
/usr/local/sbin/btrfs_snap.sh list monthly     will show all monthly snapshots.
/usr/local/sbin/btrfs_snap.sh errors           list all disk drives error counts

##  Clear
`btrfs_snap.sh clear`
 will remove all old snaps.  Retention times are defined in the `clear_snaps ()` function in the script.

##  PC snaps
This snaps the copy of PC data files.\
PC data files is an rsync of the users PCs.

##  Monitoring
The script will update a file `status_file="/usr/local/backup/status/btrfs"` for Nagios monitoring.\
Disable is not needed (line 160).\
It will also use logger to inject the status of snaps into the logs.

# crontab

\#  Server snapshots\
\#  Hourly\
0 8,10,12,14,16,18,20 * * * /usr/local/backup/btrfs_snap.sh server hourly\
\#  Daily\
30 23 * * * /usr/local/backup/btrfs_snap.sh server daily\
31 23 * * * /usr/local/backup/btrfs_snap.sh PC daily\
\#  Weekly\
35 23 * * 7 /usr/local/backup/btrfs_snap.sh server weekly\
36 23 * * 7 /usr/local/backup/btrfs_snap.sh PC weekly\
37 23 * * 7 /usr/local/backup/btrfs_snap.sh clear\
38 23 * * 7 btrfs scrub start /home/\
\#  Monthly\
40 23 1 * * /usr/local/backup/btrfs_snap.sh server monthly\
41 23 1 * * /usr/local/backup/btrfs_snap.sh PC monthly\
\#  Yearly\
40 23 31 12 * /usr/local/backup/btrfs_snap.sh server yearly\
41 23 31 12 * /usr/local/backup/btrfs_snap.sh PC yearly\


