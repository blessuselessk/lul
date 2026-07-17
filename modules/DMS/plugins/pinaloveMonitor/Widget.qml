import QtCore
import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root
    property var popoutService: null

    property bool isOnline: false
    property string targetUsername: ""
    property string authStatus: "none"  // "none" | "cookie" | "jwt"

    readonly property bool isAuthed: authStatus === "cookie" || authStatus === "jwt"
    readonly property string authScript: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation)
        .toString().replace("file://", "") + "/DankMaterialShell/plugins/pinaloveMonitor/pinalove-auth.sh"

    PluginGlobalVar {
        varName: "status"
        defaultValue: null
        onValueChanged: {
            if (value) {
                root.isOnline = value.online ?? false
                root.targetUsername = value.username ?? ""
            }
        }
    }

    PluginGlobalVar {
        varName: "authStatus"
        defaultValue: "none"
        onValueChanged: {
            if (value) root.authStatus = value
        }
    }

    function launchAuth() {
        let script = root.authScript
        Quickshell.execDetached(["sh", "-c",
            "for t in foot kitty alacritty wezterm xterm; do " +
            "  if command -v $t >/dev/null 2>&1; then " +
            "    $t -e sh -c '" + script + "; echo; read -rp \"Press Enter to close\" _' & " +
            "    break; " +
            "  fi; " +
            "done"
        ])
    }

    pillClickAction: function(x, y, width, section, screen) {
        if (!root.isAuthed) root.launchAuth()
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingSmall
            leftPadding: Theme.spacingMedium
            rightPadding: Theme.spacingMedium
            topPadding: Theme.spacingSmall
            bottomPadding: Theme.spacingSmall
            visible: root.targetUsername !== ""

            Rectangle {
                width: 8
                height: 8
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: !root.isAuthed  ? Theme.colorWarning
                     : root.isOnline   ? Theme.colorSuccess
                                       : Theme.colorOnSurfaceSecondary

                Behavior on color { ColorAnimation { duration: 400 } }
            }

            StyledText {
                text: !root.isAuthed ? root.targetUsername + " ·  sign in"
                                     : root.targetUsername
                color: !root.isAuthed  ? Theme.colorWarning
                     : root.isOnline   ? Theme.colorOnSurface
                                       : Theme.colorOnSurfaceSecondary
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter

                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingSmall
            topPadding: Theme.spacingMedium
            bottomPadding: Theme.spacingMedium
            leftPadding: Theme.spacingSmall
            rightPadding: Theme.spacingSmall
            visible: root.targetUsername !== ""

            Rectangle {
                width: 8
                height: 8
                radius: 4
                anchors.horizontalCenter: parent.horizontalCenter
                color: !root.isAuthed  ? Theme.colorWarning
                     : root.isOnline   ? Theme.colorSuccess
                                       : Theme.colorOnSurfaceSecondary

                Behavior on color { ColorAnimation { duration: 400 } }
            }

            StyledText {
                text: root.targetUsername
                color: !root.isAuthed  ? Theme.colorWarning
                     : root.isOnline   ? Theme.colorOnSurface
                                       : Theme.colorOnSurfaceSecondary
                font.pixelSize: Theme.fontSizeSmall
                rotation: 90
                anchors.horizontalCenter: parent.horizontalCenter

                Behavior on color { ColorAnimation { duration: 400 } }
            }
        }
    }
}
