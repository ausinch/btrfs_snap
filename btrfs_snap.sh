#!/bin/bash
#  Script by Chris for our server.
#  Snaps the various subvols 
# ID 654 gen 81916 top level 5 path BACKUP/clonezilla
# ID 655 gen 103692 top level 5 path BACKUP/PCs
# ID 656 gen 57101 top level 5 path BACKUP/images
# ID 657 gen 103840 top level 5 path DATA
#
# Versions
# 0.1 20210214 base version
# 0.2 20210228 added old snaps clean up
# 0.3 20210402 added status for Nagios check_backup
# 0.4 20210604 updated help file, add errors function

#  r!date Fri  4 Jun 19:00:04 CEST 2021
short_version="0.4"
version="20210604"
base_dir="/home/.snapshots/"
status_file="/usr/local/backup/status/btrfs"

######  Functions   ######
help () {
    echo "Usage: $0 function location
    You must specify what to snapshot and where it will go.
    functions: server|PC|clear|list|errors
    location: hourly|daily|weekly|monthly|yearly
    clear does not need another param, it removes old snaps

Example:
    $0 PC daily         will initate a snapshot on /home/BACKUP/PCs/ labelled daily 
    $0 server weekly    will initate a snapshot on the server /etc/ and /home/DATA/
    $0 list monthly     will show all monthly snapshots.
    $0 errors           list all disk drives error counts

    "
}

check_exists () {
    if [ ! -d "$to_loc" ];then
        mkdir -p "$to_loc"
        echo "$to_loc created"
    fi
}

list_snaps (){
    if [ $location ]; then
        btrfs subv list /home/ |grep $location | sort
    else 
        btrfs subv list /home/|less
    fi
}

snap_errors(){
    btrfs device stats -c /home/
}

clear_snaps () {  #Remove old snapshots
    hourly_retention=30       # days retention
    daily_retention=90        # 3 months
    weekly_retention=180      # 6 months
    monthly_retention=720     # 2 years
    yearly_retention=1825     # 5 years
    #1_day=86400               # seconds in a day
    today_epoch="$(date +%s)"
    # loop through all snaps and delete if too old
    list1="$(ls $base_dir)"
    #echo "list1 is:"$list1
    for look_in in $list1; do
        list2="$(ls $base_dir$look_in)"
        #echo "  list2 is:"$list2
        for time_dir in $list2; do
            list3="$(ls $base_dir$look_in/$time_dir)"
            #echo "      $base_dir$look_in/$time_dir"
            #echo "          list3 is:"$list3
            # get epoch of these dirs
            for snap_dir in $list3;do
                snap_epoch="$(date --date="${snap_dir:0:10}" +%s)"  # get the epoch of the snap from the dir names first 10 characters
                snap_days_old=$(expr $today_epoch - $snap_epoch )   # seconds between now and snap date
                snap_days_old=$(expr $snap_days_old / 86400)        # convert to days old (seconds / 60 / 60 / 24)
                #  get the retention days for this snap (daily, weekly etc)
                temp1=$"$time_dir"_retention
                retention="${!temp1}"
                if [ $snap_days_old -gt $retention ];then
                    echo "looking at $base_dir$look_in/$time_dir/$snap_dir. It is $snap_days_old days old. Retention is $retention.  DELETEING THIS ONE  **"
                    btrfs subvolume delete $base_dir$look_in/$time_dir/$snap_dir
                fi
            done
        done
    done

}

######  Functions End  ######

#  test function
func=$1
if [ $func ]; then
    if [ "$func" == "server" ] || [ "$func" == "PC" ] || [ "$func" == "clear" ] || [ "$func" == "list" ]|| [ "$func" == "errors" ]; then
        echo "Function: $func"
    else
        echo "$func is not a valid function"
        help
        exit 1
    fi
else
    echo "missing function"
    help
    exit 1
fi

#  test location
location=$2
if [ "$func" == "list" ];then
    list_snaps
    exit 0
fi

if [ "$func" == "errors" ];then
    snap_errors
    exit 0
fi

if [ $location ]; then
    if [ "$location" == "hourly" ] || [ "$location" == "daily" ] || [ "$location" == "weekly" ] || [ "$location" == "monthly" ] || [ "$location" == "yearly" ] || [ "$func" == "clear" ]; then
        echo "Location: $location"
    else
        echo "$location is not a valid location"
        help
        exit 1
    fi
else
    if [ "$func" != "clear" ]; then
        echo "missing location"
        help
        exit 1
    fi

fi
func="${func,,}"  # convert to all lower case
if [ "$func" == "clear" ];then
    clear_snaps
    exit 0
fi
if [ "$func" == "pc" ] || [ "$func" == "pcs" ];then 
    func="PCs"
    from_loc="/home/BACKUP/PCs"
    to_loc="/home/.snapshots/PCs/$location"
    check_exists
fi
if [ "$func" == "server" ] || [ "$func" == "servers" ];then 
    func="server"
    from_loc="/home/DATA"
    to_loc="/home/.snapshots/server/$location"
    check_exists
fi
btrfs subv snapshot $from_loc $to_loc/$(date +%Y-%m-%d-%H%m)
if [ "$?" == "0" ];then
    echo "Snapshot $from_loc $to_loc succeeded."
    logger "$0 $func $location succeeded."
    echo "Success $(date)" > $status_file
else
    echo "Snapshot $from_loc $to_loc Error = $?"
    logger "$0 $func $location Error = $?"
    echo "Fail error: $? $(date)" > $status_file
fi

echo "End."
