// swiftlint:disable cyclomatic_complexity
import Foundation

/// Maps backend NotificationEntity fields (component + severity + message) to
/// a human-readable title and description shown in logs and alerts.
enum NotificationInterpreter {
    struct Interpreted {
        let title: String
        let description: String?
    }

    static func interpret(component: String?, severity: String?, message: String?) -> Interpreted {
        let comp = component?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        let sev = severity ?? ""
        let msg = message?.trimmingCharacters(in: .whitespaces)

        let title = resolveTitle(component: comp, severity: sev, message: msg)
        let description = resolveDescription(component: comp, severity: sev, message: msg)

        return Interpreted(title: title, description: description)
    }

    // MARK: - Title

    private static func resolveTitle(component: String, severity: String, message _: String?) -> String {
        switch component {
        case "cpu":
            switch severity {
            case "Critical": return "CPU OVERLOAD"
            case "Warning": return "HIGH CPU USAGE"
            case "Healthy": return "CPU USAGE NORMAL"
            default: return "CPU EVENT"
            }
        case "memory", "ram":
            switch severity {
            case "Critical": return "MEMORY CRITICAL"
            case "Warning": return "HIGH MEMORY USAGE"
            case "Healthy": return "MEMORY USAGE NORMAL"
            default: return "MEMORY EVENT"
            }
        case "disk", "storage":
            switch severity {
            case "Critical": return "DISK SPACE CRITICAL"
            case "Warning": return "DISK SPACE LOW"
            case "Healthy": return "DISK SPACE NORMAL"
            default: return "DISK EVENT"
            }
        case "temperature", "temp":
            switch severity {
            case "Critical": return "CPU TEMPERATURE CRITICAL"
            case "Warning": return "CPU TEMPERATURE HIGH"
            case "Healthy": return "TEMPERATURE NORMAL"
            default: return "TEMPERATURE EVENT"
            }
        case "network", "net":
            switch severity {
            case "Critical": return "NETWORK FAILURE"
            case "Warning": return "NETWORK DEGRADED"
            case "Healthy": return "NETWORK RESTORED"
            default: return "NETWORK EVENT"
            }
        case "system", "machine", "agent":
            switch severity {
            case "Critical": return "MACHINE OFFLINE"
            case "Warning": return "MACHINE UNSTABLE"
            case "Healthy": return "MACHINE ONLINE"
            default: return "SYSTEM EVENT"
            }
        case "docker", "container":
            switch severity {
            case "Critical": return "CONTAINER FAILURE"
            case "Warning": return "CONTAINER WARNING"
            case "Healthy": return "CONTAINER HEALTHY"
            default: return "CONTAINER EVENT"
            }
        case "load":
            switch severity {
            case "Critical": return "EXTENDED LOAD"
            case "Warning": return "ELEVATED LOAD"
            case "Healthy": return "LOAD NORMAL"
            default: return "LOAD EVENT"
            }
        default:
            // Fall back to uppercased component name, or generic label
            if !component.isEmpty {
                return component.uppercased() + " ALERT"
            }
            switch severity {
            case "Critical": return "CRITICAL ALERT"
            case "Warning": return "WARNING"
            case "Healthy": return "RESOLVED"
            default: return "NOTIFICATION"
            }
        }
    }

    // MARK: - Description

    private static func resolveDescription(component: String, severity: String, message: String?) -> String? {
        // If the backend gave us a non-trivial message, use it as-is
        if let msg = message, !msg.isEmpty {
            return msg
        }

        // Generate a sensible fallback description
        switch component {
        case "cpu":
            switch severity {
            case "Critical": return "CPU usage has exceeded the critical threshold."
            case "Warning": return "CPU usage is running high."
            case "Healthy": return "CPU usage has returned to normal levels."
            default: return nil
            }
        case "memory", "ram":
            switch severity {
            case "Critical": return "Available memory is critically low."
            case "Warning": return "Memory usage is running high."
            case "Healthy": return "Memory usage has returned to normal."
            default: return nil
            }
        case "disk", "storage":
            switch severity {
            case "Critical": return "Disk space is critically low. Free up space immediately."
            case "Warning": return "Disk space is running low."
            case "Healthy": return "Disk space is back within acceptable limits."
            default: return nil
            }
        case "temperature", "temp":
            switch severity {
            case "Critical": return "CPU temperature has exceeded the critical threshold. Check cooling."
            case "Warning": return "CPU temperature is elevated."
            case "Healthy": return "CPU temperature is back to normal."
            default: return nil
            }
        case "network", "net":
            switch severity {
            case "Critical": return "Connection to the machine has been lost."
            case "Warning": return "Network performance is degraded."
            case "Healthy": return "Network connectivity has been restored."
            default: return nil
            }
        case "system", "machine", "agent":
            switch severity {
            case "Critical": return "Connection to the machine agent has ended."
            case "Warning": return "The machine is experiencing instability."
            case "Healthy": return "Machine agent is back online and reporting."
            default: return nil
            }
        case "docker", "container":
            switch severity {
            case "Critical": return "One or more containers have stopped unexpectedly."
            case "Warning": return "A container is reporting elevated resource usage."
            case "Healthy": return "All containers are running normally."
            default: return nil
            }
        case "load":
            switch severity {
            case "Critical": return "System load has been critically high for an extended period."
            case "Warning": return "System load is elevated above normal levels."
            case "Healthy": return "System load has returned to normal."
            default: return nil
            }
        default:
            return nil
        }
    }
}
