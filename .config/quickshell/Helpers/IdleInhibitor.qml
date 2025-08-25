import Quickshell.Io

Process {
    id: idleRoot
    
    // Example: systemd-inhibit to prevent idle/sleep
    command: ["systemd-inhibit", "--what=idle:sleep", "--who=noctalia", "--why=User requested", "sleep", "infinity"]
    
    // Keep process running in background
    property bool isRunning: running
    
    onStarted: {
        console.log("[IdleInhibitor] Process started - idle inhibited")
    }
    
    onExited: function(exitCode, exitStatus) {
        console.log("[IdleInhibitor] Process finished:", exitCode)
    }

    // Control functions
    function start() {
        if (!running) {
            console.log("[IdleInhibitor] Starting idle inhibitor...")
            running = true
        }
    }
    
    function stop() {
        if (running) {
            // Force stop the process by setting running to false
            running = false
            console.log("[IdleInhibitor] Stopping idle inhibitor...")
        }
    }
    
    function toggle() {
        if (running) {
            stop()
        } else {
            start()
        }
    }
}
