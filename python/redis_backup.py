#encoding:utf-8

#!/usr/bin/env python

import os
import tarfile
import time

backupFrom="/usr/local/var/db/redis"
backupTo="/usr/local/var/db/redisbak"

redisFileSuffix=(".rdb", ".aof")

sourceRedisFile={}
sourceRedisFilePath={}
targetBackupFolder={}

#设置日志级别，以小时为单位还是以天为单位
#0:don't create folder
#1:create folder every hour
#2:create folder every day
folderCut = 2

def now_time():
    return time.strftime("%Y%m%d%H%M", time.localtime(time.time()))


def mkdir(dirpath):
    if(os.path.exists(dirpath)):
        return 
    os.mkdir(dirpath)

def cutFolder(type):
    if type == 0:
        return 
    elif type == 1:
        return time.strftime("%Y%m%d", time.localtime(time.time()))    
    elif type == 2:
        return time.strftime("%Y%m%d%H", time.localtime(time.time()))    

#压缩文件
def compressFile(localPath, targetPath, filename):
    localfullPath = os.path.join(localPath, filename)
    targetfullPath = os.path.join(targetPath, filename + now_time() + ".tar.gz")
    tar = tarfile.open(targetfullPath, "w:gz")
    tar.add(localfullPath)
    tar.close()
    print ("compress file: %s ====> %s" % (localfullPath, targetfullPath))

def genRedisBackupFolder():
    mkdir(backupTo)
    for i in range(0, len(sourceRedisFile)):
        targetName = sourceRedisFile[i].split(".")[0]
        mkdir(os.path.join(backupTo, targetName))
        targetFolder = os.path.join(os.path.join(backupTo, targetName), cutFolder(folderCut))
        mkdir(targetFolder)
        targetBackupFolder[i] = targetFolder


#找出所要压缩的文件及其所在的目录
def findRedisFile():
    index = 0
    for parent, dirnames, filenames in os.walk(backupFrom):
        for filename in filenames:
            for suffix in redisFileSuffix:
                if suffix in filename:
                    sourceRedisFile[index] = filename
                    sourceRedisFilePath[index] = parent
                    index = index + 1

#对redis的每个服务进行压缩
def compressRedisFiles():
    if not (len(sourceRedisFilePath) == len(targetBackupFolder) and
            len(targetBackupFolder) == len(sourceRedisFile)):
        print "error occured in function compressRedisFiles()!"

    for i in range(0, len(sourceRedisFile)):
        compressFile(sourceRedisFilePath[i], targetBackupFolder[i], sourceRedisFile[i])

if __name__ == "__main__":
    print "================================begin backup redis file=================================="
    findRedisFile()
    genRedisBackupFolder()
    compressRedisFiles()
    print "=======================================finished=========================================="
