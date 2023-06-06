#!/bin/bash


# xcrun simctl get_app_container booted org.mozilla.ios.Fennec
# - returns Client.app path

SIM_NAME="iPhone-14-tabsArchive" 
SIM_DEVICE_TYPE="com.apple.CoreSimulator.SimDeviceType.iPhone-14"
SIM_RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-16-4"
URLS="../Client/Assets/topdomains.txt"
DELAY="3"
PATH_TEST_FIXTURES="."
CMD="xcrun simctl openurl Booted firefox://open-url?url"
BUILD_DIR="${PATH_TEST_FIXTURES}/tmp"
BUILD_PATH="${BUILD_DIR}/Build/Products/Fennec-iphonesimulator/Client.app"

TAB_COUNT=${1:-20}

function create_sim() {
    echo "CREATING DEVICE"
    SIM_DEVICE_ID=`xcrun simctl create ${SIM_NAME} ${SIM_DEVICE_TYPE} ${SIM_RUNTIME}`
    echo "SIM_DEVICE_ID: ${SIM_DEVICE_ID}"
}

function get_device_path () {
    SIM_DEVICE_ID="$(xcrun simctl list | grep Booted | awk -F '[()]' '{print $2}')";
    echo
    if [ -z "$SIM_DEVICE_ID" ]; then
	echo "-------------------------------"
	echo "ERROR"
	echo "-------------------------------"
	echo "No booted device found. Aborting!"
	exit 0
    fi

    SIM_DEVICE_PATH=~/Library/Developer/CoreSimulator/Devices/${SIM_DEVICE_ID}/data/Containers/Shared/AppGroup
    echo "SIM_DEVICE_PATH: ${SIM_DEVICE_PATH}"
}

function shutdown_sim() {
    echo "SHUTDOWN SIM"
    echo "SIM_DEVICE_ID: ${SIM_DEVICE_ID}"
    xcrun simctl shutdown ${SIM_DEVICE_ID} 
}

function shutdown_all_sim() {
   echo "SHUTDOWN ALL SIM" 
   xcrun simctl shutdown all
}

function destroy_sim() {
    echo "DESTROYING SIM"
    xcrun simctl delete ${SIM_DEVICE_ID} 
}

function boot_sim() {
    echo "BOOTING DEVICE"
    xcrun simctl boot ${SIM_DEVICE_ID}
}

function build_app() {
    echo "BUILD APP"
    xcodebuild -scheme Fennec_Enterprise_XCUITests -project ../Client.xcodeproj -sdk iphonesimulator -derivedDataPath ${BUILD_DIR} 
}

function install_app() {
    echo "INSTALLING APP"
    xcrun simctl install ${SIM_DEVICE_ID} ${BUILD_PATH}
}

function launch_app() {
    echo "LAUNCH APP"
    xcrun simctl launch ${SIM_DEVICE_ID} org.mozilla.ios.Fennec "FIREFOX_SKIP_INTRO"
    xcrun simctl openurl ${SIM_DEVICE_ID} "firefox://open-url?url=https://yahoo.ca"
    read -p "Please close the dialog on the iOS simulator and all opened tabs *now* 😀. (Press Enter to continue.)" input
}

function copy_archive() {
    PATH_PROFILE=$(find ${SIM_DEVICE_PATH} . -type d -name "profile.profile")
    CMD="cp ${PATH_PROFILE}/window-data/window-* ${PATH_TEST_FIXTURES}/tabsState${TAB_COUNT}.archive"
    echo "COPY ARCHIVE FILE TO test-fixtures"
    echo "${CMD}"
    eval ${CMD}
    
}

function kill_simulator() {
    echo "KILL SIMULATOR"
    CMD="rm ${PATH_PROFILE}/window-data/window-*"
    echo ${CMD}
    eval ${CMD}
}

function open_tabs() {
    # TODO: openurl has a user prompt that we can't silently dismiss
    # need to figure out how to open the app without this
    n=1
    count=0
    line_count=`wc -l < ${URLS}`
    while read url; do
	echo "OPEN TAB #${count}: ${url}"
	eval $(xcrun simctl openurl ${SIM_DEVICE_ID} "firefox://open-url?url=https://${url}")
	n=$((n+1))
        sleep ${DELAY} 
        # if we need to start from the beginning of file, then reset n
        if [ ${n} -eq ${line_count} ]; then
            n=0
        fi
        # there is already 1 tab at launch, so we need n-1 total
        if [ ${n} -ge ${TAB_COUNT} ]; then
            break
        fi
        count=$((count+1))
    done < ${URLS}
}

function open_tab_group() {
    # we want to be able to run the tabs on a sim instance, then kill it, reload
    # and run again
    # TODO: figure out how to kill the sim instance
    read -p "Enter tabsState.archive tab counts (separated by 'space'): Example: 10 20 30: " input

    for i in ${input[@]}
    do
    
       TAB_COUNT=${i}
       open_tabs
       copy_archive
       kill_simulator
       # tmp
       exit 
    done
}

# If we have other iOS simulators running, there may be weird behaviours.
shutdown_all_sim
create_sim
boot_sim
get_device_path
build_app
install_app
launch_app
# TODO: need to figure out how to do a silent openurl (without prompt)
# Workaround: Prompt the user to close the dialog before proceeding
open_tabs
copy_archive
shutdown_sim
destroy_sim
