homeLocation=`pwd`
adapterLocation="${homeLocation}/adapters/bitmovinPlayerAdapter/"
coreLocation="${homeLocation}/core/"

# param 1: root directory of the library which should be packaged
# param 2: name of the resulting zip file
packageLibrary () {
    libLocation=$1
    libName=$2
    cd $libLocation
    zip -r $libName ./
    mv "${libName}.zip" ${homeLocation}
}

packageLibrary "$adapterLocation" "adapter"
packageLibrary "$coreLocation" "core"
