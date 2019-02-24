homeLocation=`pwd`
adapterLocation="${homeLocation}/adapters/bitmovinPlayerAdapter/"
collectorLocation="${homeLocation}/collector/"
lftpPass='' # TODO: insert password here

# param 1: root directory of the library which should be packaged
# param 2: name of the resulting zip file
packageLibrary () {
    libLocation=$1
    libName=$2
    cd $libLocation
    zip -r $libName ./
    mv "${libName}.zip" ${homeLocation}
    cd $homeLocation
}

# param 2: name of the zip file to upload
uploadLibrary () {
    libName=$1
    lftp -u bitmovin-playerguys,${lftpPass} sftp://bitmovin.sftp.wpengine.com:2222 <<END_SCRIPT
set sftp:auto-confirm yes
cd /files/player
put ${libName}.zip
quit
END_SCRIPT
}

# param 1: root directory of the library which should be packaged
# param 2: name of the resulting zip file
packageAndUploadLibrary () {
    packageLibrary $1 $2
    uploadLibrary $2
}

packageAndUploadLibrary "$adapterLocation" "adapter"
packageAndUploadLibrary "$collectorLocation" "collector"
