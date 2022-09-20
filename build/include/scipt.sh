SERVICE="1.27.0-pika"
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
    ver3=$(sed -n -e 's/.*<version>\(.*\)<\/version>.*/\1/p' ../../sdks/csharp/sdk/AgonesSDK.nuspec)
    if [ "$SERVICE" != "$ver3" ]; then
        echo "Version is incorrect in AgonesSDK"
    fi

    #  Update the package version in the [sdks/unity/package.json][unity] package file's Version field to {version} if a full release, {version}-rc if release candidate
     echo "See u again for editing json file"

    # Run make gen-install
    make gen-instal

    # If full release, then increment the base_version in [build/Makefile][build-makefile]
    sed -i -e "s/\(base_version = \).*/\1$SERVICE/" ../Makefile

    
fi

echo $SERVICE | awk 'BEGIN{ FS="."; } { $2+=1; print $2 }'

#sed -i -e "s/\(version:  = \).*/\1$SERVICE/" ../../sdks/unity/package.json
echo done


#sed -i -e "s/\(base_version = \).*/\1$SERVICE/" ../Makefile

