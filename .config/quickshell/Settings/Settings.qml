pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

Singleton {

    property string shellName: "pikabar"
    property string settingsDir: Quickshell.env("PIKABAR_SETTINGS_DIR") || (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/" + shellName + "/"
    property string settingsFile: Quickshell.env("PIKABAR_SETTINGS_FILE") || (settingsDir + "Settings.json")
    property string themeFile: Quickshell.env("PIKABAR_THEME_FILE") || (settingsDir + "Theme.json")
    property var settings: settingAdapter

    Item {
        Component.onCompleted: {
            // ensure settings dir
            Quickshell.execDetached(["mkdir", "-p", settingsDir]);
        }
    }

    FileView {
        id: settingFileView
        path: settingsFile
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        Component.onCompleted: function() {
            reload()
        }
        onLoaded: function() {
            Qt.callLater(function () {
                WallpaperManager.setCurrentWallpaper(settings.currentWallpaper, true);
            })
        }
        onLoadFailed: function(error) {
            settingAdapter = {}
            writeAdapter()
        }
        JsonAdapter {
            id: settingAdapter
            property string weatherCity: "London"
            property string profileImage: Quickshell.env("HOME") + "/.face"
            property bool useFahrenheit: false
            property string wallpaperFolder: "/usr/share/wallpapers/pika"
            property string currentWallpaper: "/usr/share/wallpapers/pika/duck_village_by_neytirix_dekbu6y.jpg"
            property string videoPath: "~/Videos/"
            property bool showActiveWindowIcon: true
            property bool showSystemInfoInBar: true
            property bool showCorners: true
            property bool showTaskbar: false
            property bool showMediaInBar: true
            property bool useSWWW: true
            property bool randomWallpaper: true
            property bool useWallpaperTheme: true
            property int wallpaperInterval: 300
            property string wallpaperResize: "crop"
            property int transitionFps: 60
            property string transitionType: "random"
            property real transitionDuration: 1.1
            property string visualizerType: "radial"
            property bool reverseDayMonth: false
            property bool use12HourClock: false
            property bool dimPanels: true
            property real fontSizeMultiplier: 1.0  // Font size multiplier (1.0 = normal, 1.2 = 20% larger, 0.8 = 20% smaller)
            property int taskbarIconSize: 24  // Taskbar icon button size in pixels (default: 32, smaller: 24, larger: 40)
            property var pinnedExecs: [] // Added for AppLauncher pinned apps
        }
    }

    Connections {
        target: settingAdapter
        function onRandomWallpaperChanged() { WallpaperManager.toggleRandomWallpaper() }
        function onWallpaperIntervalChanged() { WallpaperManager.restartRandomWallpaperTimer() }
        function onWallpaperFolderChanged() { WallpaperManager.loadWallpapers() }
    }
}