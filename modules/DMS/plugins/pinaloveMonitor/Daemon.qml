import QtCore
import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginComponent {
    id: root
    property var popoutService: null

    // Settings
    property string targetUsername: pluginData.targetUsername ?? ""
    property int pollIntervalSecs: pluginData.pollIntervalSecs ?? 300
    property string onlinePattern: pluginData.onlinePattern ?? "is-online\\|online-now\\|status.*online\\|currently online"
    property bool notifyOnline: pluginData.notifyOnline ?? true
    property bool notifyOffline: pluginData.notifyOffline ?? false

    // Runtime state
    property bool wasOnline: false
    property bool checking: false
    property bool authenticated: false
    property string sessionType: "cookie"
    property string bearerToken: ""
    readonly property string dataPath: StandardPaths.writableLocation(StandardPaths.GenericDataLocation)
        .toString().replace("file://", "") + "/pinaloveMonitor"

    Connections {
        target: pluginService
        function onPluginDataChanged(id) {
            if (id !== pluginId) return
            targetUsername = pluginData.targetUsername ?? ""
            pollIntervalSecs = pluginData.pollIntervalSecs ?? 300
            onlinePattern = pluginData.onlinePattern ?? "is-online\\|online-now\\|status.*online\\|currently online"
            notifyOnline = pluginData.notifyOnline ?? true
            notifyOffline = pluginData.notifyOffline ?? false
            pollTimer.interval = pollIntervalSecs * 1000
            // Re-publish username immediately when settings change
            pluginService.setGlobalVar("status", { "online": wasOnline, "username": targetUsername })
        }
    }

    // When not yet authenticated, poll every 10s so the widget updates
    // promptly after the user completes the auth flow in a terminal.
    Timer {
        id: authPollTimer
        interval: 10000
        running: !root.authenticated
        repeat: true
        triggeredOnStart: true
        onTriggered: root.loadAuthFiles()
    }

    // Re-read auth files every hour to catch session expiry.
    Timer {
        id: authRefreshTimer
        interval: 3600000
        running: root.authenticated
        repeat: true
        onTriggered: root.loadAuthFiles()
    }

    Timer {
        id: pollTimer
        interval: root.pollIntervalSecs * 1000
        running: root.targetUsername !== "" && root.authenticated
        repeat: true
        triggeredOnStart: false
        onTriggered: root.checkOnlineStatus()
    }

    function publishAuthStatus(status) {
        authenticated = (status !== "none")
        pluginService.setGlobalVar("authStatus", status)
    }

    function loadAuthFiles() {
        Proc.runCommand("pinaloveMonitor.readType", [
            "sh", "-c", "cat '" + dataPath + "/session.type' 2>/dev/null || echo none"
        ], (stdout, exitCode) => {
            let stype = stdout.trim()

            if (stype === "jwt") {
                Proc.runCommand("pinaloveMonitor.readBearer", [
                    "sh", "-c", "cat '" + dataPath + "/session.bearer' 2>/dev/null"
                ], (out, ec) => {
                    if (out.trim() !== "") {
                        sessionType = "jwt"
                        bearerToken = out.trim()
                        publishAuthStatus("jwt")
                    } else {
                        publishAuthStatus("none")
                    }
                })
            } else if (stype === "cookie") {
                Proc.runCommand("pinaloveMonitor.checkCookie", [
                    "sh", "-c", "test -f '" + dataPath + "/session.cookie' && echo ok"
                ], (out, ec) => {
                    if (out.trim() === "ok") {
                        sessionType = "cookie"
                        publishAuthStatus("cookie")
                    } else {
                        publishAuthStatus("none")
                    }
                })
            } else {
                publishAuthStatus("none")
            }
        })
    }

    function buildCurlArgs(profileUrl) {
        let base = [
            "curl", "-sL", "--max-time", "15",
            "-A", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
            "-H", "Accept: text/html,application/xhtml+xml",
            "-H", "Accept-Language: en-US,en;q=0.9"
        ]

        if (sessionType === "jwt" && bearerToken !== "") {
            let token = bearerToken.replace(/^Authorization:\s*/i, "")
            base = base.concat(["-H", token])
        } else {
            base = base.concat([
                "-b", dataPath + "/session.cookie",
                "-c", dataPath + "/session.cookie"
            ])
        }

        base.push(profileUrl)
        return base
    }

    function checkOnlineStatus() {
        if (checking || targetUsername === "") return
        checking = true

        let profileUrl = "https://www.pinalove.com/" + targetUsername
        let curlArgs = buildCurlArgs(profileUrl)

        Proc.runCommand("pinaloveMonitor.fetch", [
            "sh", "-c",
            curlArgs.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" ") +
            " | grep -i '" + onlinePattern + "' | head -3"
        ], (stdout, exitCode) => {
            checking = false
            let isOnline = (exitCode === 0 && stdout.trim() !== "")

            if (isOnline && !wasOnline) {
                wasOnline = true
                pluginService.savePluginState({ "wasOnline": true })
                pluginService.setGlobalVar("status", { "online": true, "username": targetUsername })
                if (notifyOnline) sendNotification(targetUsername + " is now online on Pinalove", "notifications_active")
            } else if (!isOnline && wasOnline) {
                wasOnline = false
                pluginService.savePluginState({ "wasOnline": false })
                pluginService.setGlobalVar("status", { "online": false, "username": targetUsername })
                if (notifyOffline) sendNotification(targetUsername + " went offline on Pinalove", "notifications_off")
            }
        })
    }

    function sendNotification(message, icon) {
        Quickshell.execDetached([
            "notify-send",
            "--icon", icon,
            "--urgency", "normal",
            "--app-name", "Pinalove Monitor",
            "Pinalove",
            message
        ])
    }

    Component.onCompleted: {
        let state = pluginService.loadPluginState()
        wasOnline = state?.wasOnline ?? false
        Proc.runCommand("pinaloveMonitor.mkDataDir", ["mkdir", "-p", dataPath], () => {})
        // Defer publishing status so pluginData has time to load
        Qt.callLater(() => {
            pluginService.setGlobalVar("status", { "online": wasOnline, "username": targetUsername })
            pluginService.setGlobalVar("authStatus", "none")
        })
    }
}
