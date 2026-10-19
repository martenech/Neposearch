import Foundation

/// Claude Code CLI prihlásené predplatným (Pro/Max) – bez API kľúča.
/// CLI beží headless, bez nástrojov, nastavení a MCP, v prázdnom dočasnom priečinku.
struct ClaudeCodeModel: LanguageModel {
    static let models = ["haiku", "sonnet", "opus"]

    let model: String

    let maxInputCharacters = 150_000

    struct Status: Sendable {
        var installed: Bool
        var signedIn: Bool
    }

    static var executable: String? {
        let home = NSHomeDirectory()
        let candidates = [
            "/opt/homebrew/bin/claude", "/usr/local/bin/claude", "\(home)/.local/bin/claude",
            "\(home)/.claude/local/claude", "\(home)/.npm-global/bin/claude", "\(home)/.bun/bin/claude",
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// GUI aplikácie dostanú minimálny PATH; CLI môže potrebovať node a pod.
    private static var environment: [String: String] {
        let home = NSHomeDirectory()
        let extra = ["/opt/homebrew/bin", "/usr/local/bin", "\(home)/.local/bin", "\(home)/.npm-global/bin", "\(home)/.bun/bin"]
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = (extra + [env["PATH"] ?? "/usr/bin:/bin"]).joined(separator: ":")
        return env
    }

    static func status() async -> Status {
        guard let exe = executable else { return Status(installed: false, signedIn: false) }
        let result = try? await run(exe, ["auth", "status", "--json"], input: nil)
        let object = result.flatMap { try? JSONSerialization.jsonObject(with: $0.stdout) as? [String: Any] }
        return Status(installed: true, signedIn: object?["loggedIn"] as? Bool ?? false)
    }

    func generateJSON(system: String, prompt: String, schema: [String: Any]) async throws -> Data {
        guard let exe = Self.executable else {
            throw AIError("Claude Code nie je nainštalovaný (brew install --cask claude-code).")
        }
        let schemaJSON = String(decoding: try JSONSerialization.data(withJSONObject: schema), as: UTF8.self)
        let args = [
            "-p", "--output-format", "json", "--model", model,
            "--tools", "", "--no-session-persistence", "--setting-sources", "", "--strict-mcp-config",
            "--system-prompt", system, "--json-schema", schemaJSON,
        ]
        let result = try await Self.run(exe, args, input: Data(prompt.utf8))
        return try Self.parse(result)
    }

    private static func parse(_ result: ProcessResult) throws -> Data {
        let stderr = String(decoding: result.stderr, as: UTF8.self)
        guard let object = try? JSONSerialization.jsonObject(with: result.stdout) as? [String: Any] else {
            let text = (String(decoding: result.stdout, as: UTF8.self) + "\n" + stderr).trimmingCharacters(in: .whitespacesAndNewlines)
            if text.lowercased().contains("not logged in") || text.lowercased().contains("/login") {
                throw AIError("Claude Code nie je prihlásený. Spusti v termináli: claude auth login")
            }
            throw AIError(text.isEmpty ? "Claude Code skončil s kódom \(result.status)." : String(text.suffix(300)))
        }
        if object["is_error"] as? Bool == true {
            throw AIError((object["result"] as? String) ?? "Claude Code hlási chybu.")
        }
        if let structured = object["structured_output"], JSONSerialization.isValidJSONObject(structured) {
            return try JSONSerialization.data(withJSONObject: structured)
        }
        if let text = object["result"] as? String, (try? JSONSerialization.jsonObject(with: Data(text.utf8))) != nil {
            return Data(text.utf8)
        }
        throw AIError("Claude Code nevrátil odpoveď v očakávanom formáte.")
    }

    // MARK: - Spúšťanie procesu

    struct ProcessResult: Sendable {
        var stdout: Data
        var stderr: Data
        var status: Int32
    }

    private static func run(_ exe: String, _ arguments: [String], input: Data?) async throws -> ProcessResult {
        let workDir = FileManager.default.temporaryDirectory.appendingPathComponent("neposearch-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workDir) }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: exe)
                process.arguments = arguments
                process.environment = environment
                process.currentDirectoryURL = workDir
                let stdin = Pipe(), stdout = Pipe(), stderr = Pipe()
                process.standardInput = stdin
                process.standardOutput = stdout
                process.standardError = stderr
                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                // Vstup píšeme a výstupy čítame súbežne, aby sa proces nezasekol na plnom pipe.
                DispatchQueue.global(qos: .utility).async {
                    if let input { stdin.fileHandleForWriting.write(input) }
                    try? stdin.fileHandleForWriting.close()
                }
                var errData = Data()
                let errDone = DispatchSemaphore(value: 0)
                DispatchQueue.global(qos: .utility).async {
                    errData = stderr.fileHandleForReading.readDataToEndOfFile()
                    errDone.signal()
                }
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                errDone.wait()
                process.waitUntilExit()
                continuation.resume(returning: ProcessResult(stdout: outData, stderr: errData, status: process.terminationStatus))
            }
        }
    }
}
