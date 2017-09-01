#!/bin/bash
# https://www.percona.com/doc/percona-xtrabackup/2.4/installation.html
#日期转为天数
function date2days {
    echo "$*" | awk '{
        z=int((14-$2)/12); y=$1+4800-z; m=$2+12*z-3;
        j=int((153*m+2)/5)+$3+y*365+int(y/4)-int(y/100)+int(y/400)-2472633;
        print j
    }'
}

#说明：脚本执行策略为每天执行一次，执行前需要先建立config文件，并在config文件
#中添加
#backup_full=
#backup_pre_name=
#即可，注意路径。
#备份策略，每七天一个循环，第一天为全备份，第二天至第六天为增量备份。
#后续会增加已备份文件压缩转移定期删除部分 
#backup_full=back_01-09-2017
#backup_pre_name=/opt/backup/back_01-09-2017

#######################
db_user="xtrabackup"
db_passwd="mysQlbackup"
db_defaults_file="/etc/mysql/mysql.conf.d/mysqld.cnf"
db_socket="/var/run/mysqld/mysqld.sock"
db_backup="/opt/backup/"
db_backup_fulldir="/opt/backup/full/"
db_backup_incrementaldir="/opt/backup/incremental/"
db_backup_gzfull="/opt/backup/gzip/"
db_backup_tarfull="/opt/backup/tar.gzdb/"
rm_num=7

#用于压缩并转移源文件
move_and_tar (){
if [ $# != 1 ]; then
        echo "参数不正确"
        exit 0
fi

time_rm=`date -d "$1 days ago" +"back_%d-%m-%Y"`

if [ $1 -eq 7 ]; then
        if [ -d ${db_backup_fulldir}${time_rm} ]; then
                su - root -c  "tar -czPvf ${db_backup_tarfull}${time_rm}_full.tar.gz ${db_backup_fulldir}${time_rm}"
                su - root -c  "rm -rf ${db_backup_fulldir}${time_rm}"
                echo "压缩目录rm $db_backup_fulldir${time_rm}" >>/opt/backup/config/tar.log
        fi
fi

if [ $1 -gt 0 -a $1 -lt 7 ]; then
        if [ -d $db_backup_incrementaldir${time_rm} ]; then
                su - root -c  "tar -czPvf ${db_backup_tarfull}${time_rm}_increment.tar.gz ${db_backup_incrementaldir}${time_rm}"
                su - root -c  "rm -rf ${db_backup_incrementaldir}${time_rm}"
                echo "压缩目录rm $db_backup_incrementaldir${time_rm}" >>/opt/backup/config/tar.log
        fi
fi
}

#得到当前时间和配置文件
time="$(date +"back_%d-%m-%Y")"
source /opt/backup/config/config

#计算今天到上次全备份相隔天数
_Day=$(date2days `echo ${backup_full:5:10}|awk 'BEGIN{FS="-"}{print $3,$2,$1}'`)
Day=$(date2days `date +"%Y %m %d"`)
echo $_Day
echo $Day
let result=$Day-$_Day
echo "相差$result天"

if [ -z ${backup_full} ] || [ $result -ge 7  ] ; then
#todo
echo '全备份'
backup_full=${time}
innobackupex --defaults-file=$db_defaults_file --no-timestamp --user=${db_user} --password=${db_passwd} --no-lock  --socket=$db_socket ${db_backup_fulldir}${backup_full}/
    
if [ $? -eq 0 ]; then
        echo "${time} 备份成功!!!" >> /opt/backup/config/results.log
    else
        echo "${time} 备份失败???" >> /opt/backup/config/results.log
    fi

#更新配置文件
echo "backup_full=${backup_full}" >/opt/backup/config/config
echo "backup_pre_name=full/${backup_full}" >>/opt/backup/config/config

#自动删除两周以前的备份文件
while [ ${rm_num} -lt 8 -a ${rm_num} -gt 0 ]
do
move_and_tar ${rm_num}
rm_num=`expr ${rm_num} - 1`
done

echo '全备份'
else
#todo
echo '增量备份'

innobackupex  --defaults-file=$db_defaults_file --socket=$db_socket --no-timestamp --user=${db_user} --password=${db_passwd} --no-lock  --incremental ${db_backup_incrementaldir}${time}/ --incremental-basedir=${db_backup}${backup_pre_name}

if [ $? -eq 0 ]; then
                echo "${time} 增量备份成功!!!" >> /opt/backup/config/results.log
        else
                echo "${time} 增量备份失败???" >> /opt/backup/config/results.log
        fi


#更新配置文件
echo "backup_full=${backup_full}" >/opt/backup/config/config
echo "backup_pre_name=incremental/${time}" >>/opt/backup/config/config
echo '增量备份'
fi