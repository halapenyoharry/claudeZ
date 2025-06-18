import Foundation
import Cocoa

struct MCPServer: Codable {
    let command: String
    let args: [String]?
    let env: [String: String]?
    let description: String?
}

struct MCPConfig: Codable {
    var mcpServers: [String: MCPServer]
}

class MCPManager {
    static let shared = MCPManager()
    
    private let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/Claude/claude_desktop_config.json")
    
    func loadConfig() -> MCPConfig? {
        guard FileManager.default.fileExists(atPath: configPath.path) else {
            print("MCP config file not found at: \(configPath.path)")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: configPath)
            return try JSONDecoder().decode(MCPConfig.self, from: data)
        } catch {
            print("Error loading MCP config: \(error)")
            return nil
        }
    }
    
    func saveConfig(_ config: MCPConfig) -> Bool {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            try data.write(to: configPath)
            return true
        } catch {
            print("Error saving MCP config: \(error)")
            return false
        }
    }
    
    func backupConfig() {
        let backupPath = configPath.appendingPathExtension("backup.\(Date().timeIntervalSince1970)")
        do {
            try FileManager.default.copyItem(at: configPath, to: backupPath)
            print("Config backed up to: \(backupPath.path)")
        } catch {
            print("Error backing up config: \(error)")
        }
    }
    
    func openInTextEdit() {
        NSWorkspace.shared.open([configPath], withApplicationAt: URL(fileURLWithPath: "/System/Applications/TextEdit.app"), configuration: NSWorkspace.OpenConfiguration())
    }
    
    func toggleServer(named serverName: String, enabled: Bool) -> Bool {
        guard var config = loadConfig() else { return false }
        
        if enabled {
            // Remove underscore prefix if disabling
            if serverName.hasPrefix("_") {
                let newName = String(serverName.dropFirst())
                if let server = config.mcpServers[serverName] {
                    config.mcpServers[newName] = server
                    config.mcpServers.removeValue(forKey: serverName)
                }
            }
        } else {
            // Add underscore prefix if enabling
            if !serverName.hasPrefix("_") {
                let newName = "_" + serverName
                if let server = config.mcpServers[serverName] {
                    config.mcpServers[newName] = server
                    config.mcpServers.removeValue(forKey: serverName)
                }
            }
        }
        
        return saveConfig(config)
    }
    
    func isServerEnabled(_ serverName: String) -> Bool {
        return !serverName.hasPrefix("_")
    }
}