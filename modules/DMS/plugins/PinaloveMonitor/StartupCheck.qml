import QtQuick
import qs.Common

QtObject {
    function check(done) {
        Proc.runCommand("pinaloveMonitor.depCheck", ["sh", "-c", "command -v curl"], (stdout, exitCode) => {
            if (exitCode === 0) {
                done(null)
            } else {
                done({
                    "title": I18n.tr("curl is required"),
                    "details": I18n.tr("Install 'curl' (e.g. sudo pacman -S curl) and re-enable this plugin.")
                })
            }
        })
    }
}
