#!/bin/bash
# Builds, installs and runs the OpenMW iOS app host.
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${0#"$PWD/"}"
DERIVED="$REPO/DerivedData"
LOG_DIR="$REPO/log"
PROJECT="$REPO/ios/OpenMW-iOS.xcodeproj"
DEFAULT_SIMULATOR="iPad Air 11-inch (M4)"
# Personal build values, defaults; ios/build.config overrides them (read_config)
APP_NAME=OpenMW
BUNDLE_ID=org.openmw.openmw
TEAM_ID=
APP_ICON=ios/OpenMW/AppIcon.png
REPO_SERVER=

usage() {
    cat <<EOF
Usage: $SCRIPT <command> [args] [options]
Target options: --simulator <name|UDID> | --device <name|UDID>  (default: $DEFAULT_SIMULATOR simulator)
Configuration: --release (optimized, stripped, dSYM) for build, install, run, ipa, upload. default: debug
Personal values (home-screen name, bundle ID, team, icon, repo server): ios/build.config, see ios/build.config.sample

  build   [simulator|device|both] [--unsigned]   build app (both: simulator + device of the configuration), increments build
                                    number once. default: simulator
  install [target]                  install current build on target (current: DerivedData/current-<platform>-
                                    <configuration> = CFBundleVersion of the slice's app). no current build -> exit 1
  run     [target] [--seconds <1-45>] [--label <name>] [-- <app args>]
          run installed app non-interactively (default: 45 s), logs + screenshot -> log/
          app not installed or installed build != current build -> exit 1
  ipa     [--unsigned]              current device build -> IPA in DerivedData/ipa. no current build -> exit 1
  upload  [--notes <text>|--notes-file <path>]
          ipa + release notes ("What's New") -> archive/ -> REPO_SERVER. no current device build -> exit 1
          --release: dSYM zip next to the IPA in archive/, not uploaded. debug: first notes line [DEBUG BUILD]
  documents zip                     game data payload (./Data -> Data/) -> DerivedData/ipa/Documents.zip
  documents install [target]        copy the payload into the installed app's Documents, no reinstall
                                    (app not installed -> abort; overwrites, deletes nothing)
  clean                             remove app build output (DerivedData)
EOF
}

die() { echo "error: $*" >&2; exit 1; }

# ios/build.config: KEY=value lines (keys as in ios/build.config.sample), read, never sourced. Empty or missing
# values keep the defaults.
read_config() {
    local file="$REPO/ios/build.config" line key
    [ -f "$file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in
            ''|'#'*) continue ;;
            *=*) ;;
            *) die "ios/build.config: not KEY=value: '$line'" ;;
        esac
        key=${line%%=*}
        case "$key" in
            APP_NAME|BUNDLE_ID|TEAM_ID|APP_ICON|REPO_SERVER) [ -z "${line#*=}" ] || printf -v "$key" '%s' "${line#*=}" ;;
            *) die "ios/build.config: unknown key '$key'" ;;
        esac
    done < "$file"
}

version() {
    local part v=()
    for part in MAJOR MINOR RELEASE; do
        v+=("$(sed -n "s/^set(OPENMW_VERSION_$part \([0-9]*\))$/\1/p" "$REPO/CMakeLists.txt")")
    done
    [ -n "${v[0]}" ] && [ -n "${v[1]}" ] && [ -n "${v[2]}" ] || die "cannot read OpenMW version from CMakeLists.txt"
    echo "${v[0]}.${v[1]}.${v[2]}"
}

# Once per invocation: increment ios/BUILD_NUMBER.
BUILD_NUMBER=
next_build_number() {
    [ -n "$BUILD_NUMBER" ] && return
    local file="$REPO/ios/BUILD_NUMBER"
    BUILD_NUMBER=$(( $(cat "$file" 2>/dev/null || echo 0) + 1 ))
    echo "$BUILD_NUMBER" > "$file"
}

# Builds the dependency xcframeworks if a slice for <target> or a dependency's license notices are missing
# (incremental).
ensure_deps() {  # <simulator|device>
    local slice=ios-arm64 name recipe missing=
    [ "$1" = simulator ] && slice=ios-arm64-simulator
    # the xcframeworks the app links (ios/project.yml)
    for name in $(sed -n 's|.*ios-deps/artifacts/\(.*\)\.xcframework$|\1|p' "$REPO/ios/project.yml"); do
        [ -d "$REPO/ios-deps/artifacts/$name.xcframework/$slice" ] || missing=1
    done
    # the notices the app bundles (build-deps.sh stage_licenses)
    for recipe in "$REPO"/ios-deps/recipes/*.sh; do
        [ -d "$REPO/ios-deps/artifacts/licenses/$(basename "$recipe" .sh)" ] || missing=1
    done
    [ -z "$missing" ] || "$REPO/ios-deps/build-deps.sh" build all "$1"
}

generate_project() {
    xcodegen generate --quiet --spec "$REPO/ios/project.yml" --project "$REPO/ios"
}

# APP_ICON (1024x1024 PNG, relative to the repo or absolute) -> DerivedData/AppIcon.xcassets, the app's asset catalog
# (ios/project.yml).
make_icon() {
    local icon=$APP_ICON catalog="$DERIVED/AppIcon.xcassets" info
    [ "${icon#/}" != "$icon" ] || icon="$REPO/$icon"
    info=$(sips -g format -g pixelWidth -g pixelHeight "$icon" 2>/dev/null \
        | awk '/format:/ {f = $2} /pixelWidth/ {w = $2} /pixelHeight/ {h = $2} END {print f, w "x" h}')
    [ "$info" = "png 1024x1024" ] || die "APP_ICON must be a 1024x1024 PNG: $APP_ICON"
    mkdir -p "$catalog/AppIcon.appiconset"
    [ -f "$catalog/Contents.json" ] || echo '{"info": {"author": "xcode", "version": 1}}' > "$catalog/Contents.json"
    [ -f "$catalog/AppIcon.appiconset/Contents.json" ] || echo '{"images": [{"filename": "AppIcon.png",' \
        '"idiom": "universal", "platform": "ios", "size": "1024x1024"}], "info": {"author": "xcode", "version": 1}}' \
        > "$catalog/AppIcon.appiconset/Contents.json"
    # copied only when changed: a new file date would recompile the asset catalog
    cmp -s "$icon" "$catalog/AppIcon.appiconset/AppIcon.png" || cp "$icon" "$catalog/AppIcon.appiconset/AppIcon.png"
}

# Builds OpenMW's static libraries (DerivedData/openmw/<configuration>-<sdk>/lib) and stages its resources with
# OpenMW's own CMake; configures when the build dir is new or the arguments changed. The app links and bundles the
# result.
build_openmw() {  # <iphoneos|iphonesimulator>
    local sdk=$1 target=simulator dir="$DERIVED/openmw/$CONFIG-$1" deps="$REPO/ios-deps/build" args stamp type=Debug
    [ "$sdk" = iphoneos ] && target=device
    # release: upstream's default build type (optimized)
    [ "$CONFIG" = Release ] && type=RelWithDebInfo
    # repository-relative paths in __FILE__ and lambda type names (no build paths in the app binary; the debug info
    # keeps absolute paths)
    local map="-fmacro-prefix-map=$REPO/="
    args=(-G Ninja --toolchain "$REPO/ios/openmw-toolchain.cmake" -DCMAKE_OSX_SYSROOT="$sdk"
        -DCMAKE_BUILD_TYPE=$type -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="$dir/lib"
        # debug info: debug type info only where it is defined; release without -g (static libraries reach the app's
        # dSYM as symbol table only)
        -DCMAKE_C_FLAGS_DEBUG="-g -fno-standalone-debug $map" -DCMAKE_CXX_FLAGS_DEBUG="-g -fno-standalone-debug $map"
        -DCMAKE_C_FLAGS_RELWITHDEBINFO="-O2 -DNDEBUG $map" -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-O2 -DNDEBUG $map"
        # the game only: no launcher, editor, wizard, tools
        -DBUILD_LAUNCHER=OFF -DBUILD_WIZARD=OFF -DBUILD_MWINIIMPORTER=OFF -DBUILD_OPENCS=OFF -DBUILD_ESSIMPORTER=OFF
        -DBUILD_BSATOOL=OFF -DBUILD_ESMTOOL=OFF -DBUILD_NIFTEST=OFF -DBUILD_NAVMESHTOOL=OFF -DBUILD_BULLETOBJECTTOOL=OFF
        -DOSG_STATIC=ON -DMYGUI_STATIC=ON -DOPENMW_USE_SYSTEM_RECASTNAVIGATION=ON
        # iOS has no OpenGL.framework (Mesa instead); OpenAL Soft, not the SDK's OpenAL.framework
        -DOPENGL_INCLUDE_DIR="$deps/mesa/$target/install/include" -DOPENGL_gl_LIBRARY="$deps/mesa/$target/lib/libMesa.a"
        -DOPENAL_INCLUDE_DIR="$deps/openal-soft/$target/install/include/AL"
        -DOPENAL_LIBRARY="$deps/openal-soft/$target/install/lib/libopenal.a"
        # Lua custom allocator check: try_run cannot run when cross-compiling; LuaJIT with GC64 supports it
        -DRUN_RESULT_VAR=0)
    # with the SDK path: CMake keeps the versioned SDK path in its cache and compiler checks, so an Xcode update needs
    # a fresh configure
    stamp=$(printf '%s\n' "$(xcrun --sdk "$sdk" --show-sdk-path)" "${args[@]}")
    if [ ! -f "$dir/build.ninja" ] || [ "$(cat "$dir/.configured" 2>/dev/null)" != "$stamp" ]; then
        echo "==> configure OpenMW ($sdk)"
        cmake --fresh -S "$REPO" -B "$dir" "${args[@]}"
        echo "$stamp" > "$dir/.configured"
    fi
    echo "==> build OpenMW ($sdk)"
    cmake --build "$dir" --target openmw -- --quiet
}

# xcodebuild <sdk> [extra args]
xcbuild() {
    local sdk=$1; shift
    make_icon
    ensure_deps "$([ "$sdk" = iphoneos ] && echo device || echo simulator)"
    build_openmw "$sdk"
    next_build_number
    generate_project
    echo "==> build $sdk $CONFIG (version $(version), build $BUILD_NUMBER) as \"$APP_NAME\" ($BUNDLE_ID)"
    local signing=(-allowProvisioningUpdates)
    if [ -n "$UNSIGNED" ]; then
        # Credential-free candidate build. Keep the capability file in source;
        # the eventual sideload signer must decide its provisioning entitlements.
        signing=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY= DEVELOPMENT_TEAM=)
    fi
    xcodebuild -project "$PROJECT" -scheme OpenMW -configuration "$CONFIG" -sdk "$sdk" \
        -derivedDataPath "$DERIVED" -quiet "${signing[@]}" \
        MARKETING_VERSION="$(version)" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
        OPENMW_BUILD_DIR="$DERIVED/openmw/$CONFIG-$sdk" \
        APP_DISPLAY_NAME="$APP_NAME" PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" DEVELOPMENT_TEAM="$TEAM_ID" "$@"
}

app_path() {  # <simulator|device>
    local sdk=iphonesimulator
    [ "$1" = device ] && sdk=iphoneos
    echo "$DERIVED/Build/Products/$CONFIG-$sdk/OpenMW.app"
}

# Current build = the slice's (platform-configuration) stamp, written by a successful 'build', exists and its app in
# DerivedData has that CFBundleVersion; sets BUILD_NUMBER.
require_build() {  # <simulator|device>
    local slice="$1-$CONFIG" expected found
    expected=$(cat "$DERIVED/current-$slice" 2>/dev/null || true)
    found=$(plutil -extract CFBundleVersion raw "$(app_path "$1")/Info.plist" 2>/dev/null || true)
    [ -n "$expected" ] && [ "$found" = "$expected" ] || die "no current $slice build: stamp ${expected:-none}" \
        "(DerivedData/current-$slice), app ${found:-none}. run '$SCRIPT build $1${RELEASE:+ $RELEASE}'"
    BUILD_NUMBER=$expected
}

build() {  # <simulator|device|both>
    [ "$1" = both ] && { build simulator; build device; return; }
    rm -f "$DERIVED/current-$1-$CONFIG"
    # Release strips the executable in place: without a relink (no code change) Xcode's dSYM step would read the
    # stripped binary and write a dSYM without debug info
    [ "$CONFIG" = Release ] && rm -f "$(app_path "$1")/OpenMW"
    case "$1" in
        simulator) xcbuild iphonesimulator -destination "generic/platform=iOS Simulator" ;;
        device) xcbuild iphoneos -destination "generic/platform=iOS" ;;
    esac
    echo "$BUILD_NUMBER" > "$DERIVED/current-$1-$CONFIG"
}

# Target selection (--simulator / --device) -> KIND + TARGET (simulator UDID or device name/UDID).
KIND=simulator
TARGET=$DEFAULT_SIMULATOR
resolve_target() {
    [ "$KIND" = device ] && return
    local udid
    udid=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
want = sys.argv[1]
for runtime, devices in json.load(sys.stdin)["devices"].items():
    if "iOS" not in runtime:
        continue
    for d in devices:
        if want in (d["name"], d["udid"]):
            print(d["udid"]); sys.exit(0)
sys.exit(1)
' "$TARGET") || die "simulator '$TARGET' not found"
    TARGET=$udid
    xcrun simctl bootstatus "$TARGET" -b > /dev/null
}

install_app() {
    local app
    app=$(app_path "$KIND")
    echo "==> install $KIND $TARGET ($CONFIG build $BUILD_NUMBER)"
    if [ "$KIND" = simulator ]; then
        xcrun simctl install "$TARGET" "$app"
    else
        xcrun devicectl device install app --quiet --device "$TARGET" "$app"
    fi
}

# Sets INSTALLED = CFBundleVersion of the app installed on the target.
require_installed() {
    if [ "$KIND" = simulator ]; then
        INSTALLED=$(plutil -extract CFBundleVersion raw \
            "$(xcrun simctl get_app_container "$TARGET" "$BUNDLE_ID" 2>/dev/null)/Info.plist" 2>/dev/null)
    else
        INSTALLED=$(xcrun devicectl device info apps --quiet --device "$TARGET" --bundle-id "$BUNDLE_ID" -j - 2>/dev/null \
            | python3 -c 'import json, sys; print(json.load(sys.stdin)["result"]["apps"][0]["bundleVersion"])' 2>/dev/null)
    fi || die "app not installed on $KIND $TARGET. run '$SCRIPT install'"
}

screenshot() {  # <file>
    if [ "$KIND" = simulator ]; then
        xcrun simctl io "$TARGET" screenshot "$1" > /dev/null 2>&1
    else
        xcrun devicectl device capture screenshot --quiet --device "$TARGET" --destination "$1"
    fi || { echo "warning: screenshot failed" >&2; return 0; }
    local w h
    w=$(sips -g pixelWidth "$1" | awk '/pixelWidth/ {print $2}')
    h=$(sips -g pixelHeight "$1" | awk '/pixelHeight/ {print $2}')
    # portrait framebuffer -> rotate 90 degrees left
    [ "$h" -gt "$w" ] && sips -r 270 "$1" > /dev/null
    return 0
}

run_app() {  # <seconds> <label> [app args]
    local seconds=$1 label=$2; shift 2
    mkdir -p "$LOG_DIR"
    local console="$LOG_DIR/debugger.log" shot="$LOG_DIR/$label.png" marker="$LOG_DIR/.run-start" pid start
    start=$(date +%s)
    touch "$marker"
    rm -f "$shot"
    echo "==> run $KIND $TARGET for ${seconds}s"
    if [ "$KIND" = simulator ]; then
        xcrun simctl launch --console --terminate-running-process "$TARGET" "$BUNDLE_ID" "$@" > "$console" 2>&1 &
    else
        xcrun devicectl device process launch --console --terminate-existing --device "$TARGET" "$BUNDLE_ID" "$@" > "$console" 2>&1 &
    fi
    pid=$!
    local waited=0
    while [ $waited -lt "$seconds" ] && kill -0 $pid 2>/dev/null; do sleep 1; waited=$((waited + 1)); done
    if kill -0 $pid 2>/dev/null; then
        screenshot "$shot"
        if [ "$KIND" = simulator ]; then
            xcrun simctl terminate "$TARGET" "$BUNDLE_ID" 2>/dev/null || true
        else
            kill -INT $pid 2>/dev/null || true  # devicectl forwards the signal to the app
        fi
    else
        echo "warning: app exited after ${waited}s" >&2
    fi
    # devicectl --console does not always exit after the app has terminated
    waited=0
    while kill -0 $pid 2>/dev/null && [ $waited -lt 10 ]; do sleep 1; waited=$((waited + 1)); done
    kill -KILL $pid 2>/dev/null || true
    wait $pid 2>/dev/null || true
    if [ "$KIND" = simulator ]; then
        xcrun simctl spawn "$TARGET" log show --style compact --start "$(date -r "$start" '+%Y-%m-%d %H:%M:%S')" \
            --predicate 'process == "OpenMW"' > "$LOG_DIR/system.log" 2>&1 || true
    fi
    local report
    for report in $(find "$HOME/Library/Logs/DiagnosticReports" -name 'OpenMW*.ips' -newer "$marker" 2>/dev/null); do
        cp "$report" "$LOG_DIR/"
        echo "warning: crash report $(basename "$report") -> log/" >&2
    done
    echo "==> logs in log/ (debugger.log$([ -f "$shot" ] && echo ", $label.png"))"
}

# Packages the current device build as is (signed by 'build': Apple Development, team profile).
make_ipa() {  # [--unsigned]
    require_build device
    local out="$DERIVED/ipa" name=OpenMW.ipa
    [ "${1:-}" = --unsigned ] && name=OpenMW-unsigned.ipa
    rm -rf "$out/Payload" && mkdir -p "$out/Payload"
    cp -R "$(app_path device)" "$out/Payload/"
    if [ "${1:-}" = --unsigned ]; then
        if codesign -d "$out/Payload/OpenMW.app" >/dev/null 2>&1; then
            codesign --remove-signature "$out/Payload/OpenMW.app"
        fi
        rm -rf "$out/Payload/OpenMW.app/_CodeSignature" "$out/Payload/OpenMW.app/embedded.mobileprovision"
    fi
    (cd "$out" && rm -f "$name" && zip -qry "$name" Payload && rm -rf Payload)
    IPA="$out/$name"
    [ -f "$IPA" ] || die "IPA not created"
    echo "==> $IPA ($CONFIG build $BUILD_NUMBER)"
}

upload() {
    [ -n "$REPO_SERVER" ] || die "no repo server: set REPO_SERVER in ios/build.config"
    make_ipa
    # ponytail: APP_NAME as is in the file name; '/' would break the path, ';' or ',' curl -F (sanitize when needed)
    local name="$APP_NAME-$(version)-$BUILD_NUMBER" notes=() code dsym
    if [ "$CONFIG" = Debug ]; then
        # first notes line: the repo server cannot tell debug from release builds
        case "$NOTES_OPT" in
            --notes) NOTES="[DEBUG BUILD]"$'\n'"$NOTES" ;;
            --notes-file)
                { echo "[DEBUG BUILD]"; cat "$NOTES"; } > "$DERIVED/ipa/notes.txt"
                NOTES=$DERIVED/ipa/notes.txt ;;
            *) NOTES_OPT=--notes NOTES="[DEBUG BUILD]" ;;
        esac
    fi
    case "$NOTES_OPT" in
        --notes) notes=(--form-string "notes=$NOTES") ;;  # literal, no @/< parsing
        --notes-file) notes=(-F "notes=<$NOTES") ;;
    esac
    mkdir -p "$REPO/archive"
    cp "$IPA" "$REPO/archive/$name.ipa"
    if [ "$CONFIG" = Release ]; then
        # the dSYM stays next to the IPA, not uploaded
        dsym="$(app_path device).dSYM"
        [ -d "$dsym" ] || die "no dSYM: $dsym"
        rm -f "$REPO/archive/$name.dSYM.zip"
        (cd "$(dirname "$dsym")" && zip -qry "$REPO/archive/$name.dSYM.zip" "$(basename "$dsym")")
        echo "==> archive/$name.dSYM.zip"
    fi
    echo "==> upload archive/$name.ipa"
    code=$(cd "$REPO" && curl -sS -o /dev/null -w '%{http_code}' -F "file=@archive/$name.ipa" \
        "${notes[@]+"${notes[@]}"}" "$REPO_SERVER") || die "upload failed"
    [ "$code" -lt 400 ] || die "upload failed (HTTP $code)"
    echo "==> uploaded (HTTP $code)"
}

# Game data payload: ./Data -> Documents/Data (Morrowind.ini is not part of it: the user copies it to Config/ or Data/).
documents() {  # <zip|install>
    [ -d "$REPO/Data" ] || die "no payload: $REPO/Data missing"
    if [ "$1" = zip ]; then
        mkdir -p "$DERIVED/ipa"
        echo "==> DerivedData/ipa/Documents.zip"
        # -FS: incremental, the zip mirrors Data/
        (cd "$REPO" && zip -qr -FS "$DERIVED/ipa/Documents.zip" Data -x '*.DS_Store')
        return
    fi
    require_installed
    echo "==> copy Data -> Documents/Data ($KIND $TARGET)"
    if [ "$KIND" = simulator ]; then
        local container
        container=$(xcrun simctl get_app_container "$TARGET" "$BUNDLE_ID" data)
        mkdir -p "$container/Documents/Data"
        rsync -a --exclude .DS_Store "$REPO/Data/" "$container/Documents/Data/"
    else
        # copies only modified files
        xcrun devicectl device copy to --quiet --device "$TARGET" --domain-type appDataContainer \
            --domain-identifier "$BUNDLE_ID" --source "$REPO/Data" --destination Documents/Data
    fi
}

[ $# -eq 0 ] && { usage; exit 0; }
command=$1; shift
case "$command" in
    -h|--help) usage; exit 0 ;;
    build|install|run|ipa|upload|documents|clean) ;;
    *) usage >&2; exit 1 ;;
esac

# Common option parsing.
POSITIONAL=() APP_ARGS=() UNSIGNED= RELEASE= SECONDS_ARG=45 LABEL=screenshot NOTES_OPT= NOTES=
while [ $# -gt 0 ]; do
    case "$1" in
        --simulator) [ $# -ge 2 ] || die "--simulator needs <name|UDID>"; KIND=simulator; TARGET=$2; shift ;;
        --device) [ $# -ge 2 ] || die "--device needs <name|UDID>"; KIND=device; TARGET=$2; shift ;;
        --unsigned) UNSIGNED=--unsigned ;;
        --release) RELEASE=--release ;;
        --seconds) [ $# -ge 2 ] || die "--seconds needs a value"; SECONDS_ARG=$2; shift ;;
        --label) [ $# -ge 2 ] || die "--label needs a name"; LABEL=$2; shift ;;
        --notes|--notes-file)
            [ $# -ge 2 ] || die "$1 needs a value"
            [ -z "$NOTES_OPT" ] || die "--notes and --notes-file are mutually exclusive"
            NOTES_OPT=$1 NOTES=$2
            if [ "$1" = --notes-file ]; then
                [ -f "$2" ] || die "notes file '$2' not found"
                NOTES="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
            fi
            shift ;;
        --) shift; APP_ARGS=("$@"); break ;;
        -*) die "unknown option '$1'" ;;
        *) POSITIONAL+=("$1") ;;
    esac
    shift
done
# Xcode configuration, also selects the CMake build type of OpenMW's code (ios-deps: one build for both)
CONFIG=Debug
[ -n "$RELEASE" ] && CONFIG=Release
read_config

allow() {  # <allowed options...>: reject options not valid for this command
    local given=() opt
    [ "$KIND$TARGET" != "simulator$DEFAULT_SIMULATOR" ] && given+=(target)
    [ -n "$UNSIGNED" ] && given+=(--unsigned)
    [ -n "$RELEASE" ] && given+=(--release)
    [ "$SECONDS_ARG" != 45 ] && given+=(--seconds)
    [ "$LABEL" != screenshot ] && given+=(--label)
    [ ${#APP_ARGS[@]} -gt 0 ] && given+=(--)
    [ -n "$NOTES_OPT" ] && given+=(--notes)
    for opt in "${given[@]+"${given[@]}"}"; do
        [[ " $* " == *" $opt "* ]] || die "'$opt' is not valid for '$command'"
    done
}

case "$command" in
    build)
        allow --release --unsigned
        [ ${#POSITIONAL[@]} -le 1 ] || die "usage: $SCRIPT build [simulator|device|both]"
        target=${POSITIONAL[0]:-simulator}
        case "$target" in simulator|device|both) build "$target" ;; *) die "unknown target '$target'" ;; esac ;;
    install)
        allow target --release
        [ ${#POSITIONAL[@]} -eq 0 ] || die "unexpected argument '${POSITIONAL[0]}'"
        require_build "$KIND"
        resolve_target
        install_app ;;
    run)
        allow target --seconds --label -- --release
        [ ${#POSITIONAL[@]} -eq 0 ] || die "unexpected argument '${POSITIONAL[0]}'"
        [[ "$SECONDS_ARG" =~ ^[0-9]+$ ]] && [ "$SECONDS_ARG" -ge 1 ] && [ "$SECONDS_ARG" -le 45 ] \
            || die "--seconds must be 1-45"
        [[ "$LABEL" =~ ^[A-Za-z0-9._-]+$ ]] || die "--label must match [A-Za-z0-9._-]+"
        require_build "$KIND"
        resolve_target
        require_installed
        [ "$INSTALLED" = "$BUILD_NUMBER" ] || die "installed build $INSTALLED on $KIND $TARGET is not the current" \
            "build $BUILD_NUMBER. run '$SCRIPT install${RELEASE:+ $RELEASE}'"
        run_app "$SECONDS_ARG" "$LABEL" "${APP_ARGS[@]+"${APP_ARGS[@]}"}" ;;
    ipa)
        allow --unsigned --release
        [ ${#POSITIONAL[@]} -eq 0 ] || die "unexpected argument '${POSITIONAL[0]}'"
        make_ipa $UNSIGNED ;;
    upload)
        allow --notes --release
        [ ${#POSITIONAL[@]} -eq 0 ] || die "unexpected argument '${POSITIONAL[0]}'"
        upload ;;
    documents)
        [ ${#POSITIONAL[@]} -eq 1 ] || die "usage: $SCRIPT documents zip | documents install [target]"
        case "${POSITIONAL[0]}" in
            zip) allow; documents zip ;;
            install) allow target; resolve_target; documents install ;;
            *) die "usage: $SCRIPT documents zip | documents install [target]" ;;
        esac ;;
    clean)
        allow
        [ ${#POSITIONAL[@]} -eq 0 ] || die "unexpected argument '${POSITIONAL[0]}'"
        echo "==> clean"
        rm -rf "${DERIVED:?}" "$PROJECT" ;;
esac
