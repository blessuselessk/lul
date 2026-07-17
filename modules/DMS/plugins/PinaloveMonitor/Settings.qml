import QtCore
import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: settingsRoot
    pluginId: "pinaloveMonitor"

    property string sessionStatus: "Checking..."
    property string pluginPath: ""
    readonly property string dataPath: StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
                                           .toString().replace("file://", "") + "/pinaloveMonitor"

    Component.onCompleted: {
        pluginPath = pluginService?.getPluginPath() ?? ""
        checkSessionStatus()
    }

    function checkSessionStatus() {
        Proc.runCommand("pinaloveMonitorSettings.checkSession", [
            "sh", "-c",
            "if [ -f '" + dataPath + "/session.bearer' ]; then echo 'JWT token present'; " +
            "elif [ -f '" + dataPath + "/session.cookie' ]; then echo 'Cookie file present'; " +
            "else echo 'Not authenticated'; fi"
        ], (stdout, exitCode) => {
            sessionStatus = stdout.trim() || "Not authenticated"
        })
    }

    // --- Target User ---
    StyledText {
        text: "Target User"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.colorOnSurface
        font.bold: true
    }

    StringSetting {
        settingKey: "targetUsername"
        label: "Pinalove Username"
        description: "Username as it appears in their profile URL (pinalove.com/username)"
        placeholder: "e.g. Maria123"
        defaultValue: ""
    }

    // --- Authentication ---
    StyledText {
        text: "Authentication"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.colorOnSurface
        font.bold: true
        topPadding: Theme.spacingMedium
    }

    StyledText {
        text: "Session: " + sessionStatus
        font.pixelSize: Theme.fontSizeSmall
        color: sessionStatus.includes("Not auth") ? Theme.colorError : Theme.colorSuccess
    }

    StyledText {
        text: "Run the auth script in a terminal to log in. It will email you a one-time code and save the session automatically."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.colorOnSurfaceSecondary
        wrapMode: Text.WordWrap
        width: parent?.width ?? 400
    }

    DankButton {
        text: "Open Terminal & Authenticate"
        onClicked: {
            let script = settingsRoot.pluginPath + "/pinalove-auth.sh"
            Quickshell.execDetached(["sh", "-c",
                "for t in foot kitty alacritty wezterm xterm; do " +
                "  if command -v $t >/dev/null 2>&1; then " +
                "    $t -e sh -c '" + script + "; echo; read -rp \"Press Enter to close\" _' & " +
                "    break; " +
                "  fi; " +
                "done"
            ])
            refreshStatusTimer.start()
        }
    }

    Timer {
        id: refreshStatusTimer
        interval: 30000
        repeat: false
        onTriggered: settingsRoot.checkSessionStatus()
    }

    DankButton {
        text: "Refresh Status"
        onClicked: settingsRoot.checkSessionStatus()
    }

    // --- Polling ---
    StyledText {
        text: "Polling"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.colorOnSurface
        font.bold: true
        topPadding: Theme.spacingMedium
    }

    SliderSetting {
        settingKey: "pollIntervalSecs"
        label: "Check Interval"
        description: "How often to check if the user is online (seconds)"
        defaultValue: 300
        minimum: 60
        maximum: 1800
        unit: "s"
    }

    // --- Notifications ---
    StyledText {
        text: "Notifications"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.colorOnSurface
        font.bold: true
        topPadding: Theme.spacingMedium
    }

    ToggleSetting {
        settingKey: "notifyOnline"
        label: "Notify when online"
        description: "Send a notification when the user comes online"
        defaultValue: true
    }

    ToggleSetting {
        settingKey: "notifyOffline"
        label: "Notify when offline"
        description: "Send a notification when the user goes offline"
        defaultValue: false
    }

    // --- Advanced ---
    StyledText {
        text: "Advanced"
        font.pixelSize: Theme.fontSizeMedium
        color: Theme.colorOnSurface
        font.bold: true
        topPadding: Theme.spacingMedium
    }

    StyledText {
        text: "If notifications don't trigger, find the correct HTML pattern by running:\ncurl -sL -b " + settingsRoot.dataPath + "/session.cookie https://www.pinalove.com/USERNAME | grep -i 'online'"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.colorOnSurfaceSecondary
        wrapMode: Text.WordWrap
        width: parent?.width ?? 400
    }

    StringSetting {
        settingKey: "onlinePattern"
        label: "Online HTML Pattern"
        description: "grep -i pattern to match in profile HTML indicating online status"
        placeholder: "is-online\\|online-now\\|currently online"
        defaultValue: "is-online\\|online-now\\|status.*online\\|currently online"
    }
}
