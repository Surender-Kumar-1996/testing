SERVICE="1.27.0"


increment_version() {
    local delimiter=.
    local array=($(echo "$1" | tr $delimiter '\n'))

    for index in ${!array[@]}; do
        if [ $index -eq $2 ]; then
        local value=array[$index]
        value=$((value+1))
        array[$index]=$value
        break
        fi
    done

    echo $(IFS=$delimiter ; echo "${array[*]}")
}

install_package(){
    REQUIRED_PKG="$1"
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
    echo Checking for $REQUIRED_PKG: $PKG_OK
    if [ "" = "$PKG_OK" ]; then
    echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
    sudo apt-get --yes install $REQUIRED_PKG 
    fi
}


release_candidate=${SERVICE: -2}
#echo $release_candidate
if [ "$release_candidate" == "rc" ]; then
    SERVICE+="-dev"
    echo $SERVICE
    ver1=$(grep -h "tag" ../../install/helm/agones/test.yaml | awk '{ print $2}')
    ver2=$(grep -h "version" ../../install/helm/agones/chart.yaml | awk '{ print $2}')

    #  Ensure the [helm tag value][values] is correct (should be {version} if a full release, {version}-rc if release candidate)
    #Ensure the [helm Chart version values][chart] are correct (should be {version} if a full release, {version}-rc if release candidate)
    if [[ "$SERVICE" != "$ver1" ]] && [[ "$SERVICE" != "$ver2" ]]; then
        echo "tag and version is incorrect"
        echo $ver1
        exit
    fi
    if [ "$SERVICE" != "$ver1" ]; then
        echo "tag is incorrect"
        exit
    fi
    if [ "$SERVICE" != "$ver2" ]; then
        echo "version is incorrect"
        exit
    fi

    # Update the package version in [sdks/nodejs/package.json][package.json] and [sdks/nodejs/package-lock.json][package-lock.json] by running npm version {version} if a full release or npm version {version}-rc if release candidate
    npm version $SERVICE

    #Ensure the [sdks/csharp/sdk/AgonesSDK.nuspec and sdks/csharp/sdk/csharp-sdk.csproj][csharp] versions are correct (should be {version} if a full release, {version}-rc if release candidate)
    ver3=$(sed -n -e 's/.*<version>\(.*\)<\/version>.*/\1/pI' ../../sdks/csharp/sdk/AgonesSDK.nuspec)
    if [ "$SERVICE" != "$ver3" ]; then
        echo "Version is incorrect in AgonesSDK"
    fi
    ver4=$(sed -n -e 's/.*<version>\(.*\)<\/version>.*/\1/pI' ../../sdks/csharp/sdk/csharp-sdk.csproj)
    if [ "$SERVICE" != "$ver4" ]; then
        echo "Version is incorrect in csharp-sdk"
    fi
    #  Update the package version in the [sdks/unity/package.json][unity] package file's Version field to {version} if a full release, {version}-rc if release candidate
     echo "See u again for editing json file"

    # Run make gen-install
    make gen-instal

    newVersion=$(increment_version $SERVICE 1)
    Version="$newVersion-dev"
    # If full release, then increment the base_version in [build/Makefile][build-makefile]
    sed -i -e "s/\(base_version = \).*/\1$Version/" ../Makefile

    
fi


#brew install jq

install_package jq


Version="$SERVICE-devi"
echo $Version

temp=$(jq '.version |= "[$Version]"' ../../sdks/unity/package.json)
temp=$(jq '.' <<< $temp)
echo $temp > ../../sdks/unity/package.json

#jq '.version' ../../sdks/unity/package.json

#sed -i -e "s/\(version:  = \).*/\1$SERVICE/" ../../sdks/unity/package.json
echo done

jq '.version' ../../sdks/unity/package.json

#sed -i -e "s/\(base_version = \).*/\1$SERVICE/" ../Makefile

