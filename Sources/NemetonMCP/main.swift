import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// MCP stdio-Server für Nemeton.
/// Liest JSON-RPC 2.0 Requests von stdin, leitet sie an den lokalen HTTP-Server weiter,
/// und schreibt die Responses nach stdout.

let serverURL = "http://127.0.0.1:\(ProcessInfo.processInfo.environment["NEMETON_PORT"] ?? "22100")"
let authToken = ProcessInfo.processInfo.environment["NEMETON_TOKEN"]

func main() {
    func log(_ msg: String) {
        FileHandle.standardError.write("[\(ISO8601DateFormatter().string(from: Date()))] \(msg)\n".data(using: .utf8)!)
    }

    log("NemetonMCP gestartet (Server: \(serverURL), Token: \(authToken != nil ? "gesetzt" : "–"))")

    while let line = readLine(strippingNewline: true) {
        guard !line.isEmpty else { continue }

        // JSON-RPC Request validieren
        guard let requestData = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: requestData) as? [String: Any],
              json["jsonrpc"] as? String == "2.0" else {
            let error = jsonRpcError(id: nil, code: -32700, message: "Parse error")
            writeLine(error)
            continue
        }

        let id = json["id"]
        let method = json["method"] as? String ?? ""

        log("← \(method)")

        // Notifications (kein id) — nur ACK, keine Antwort
        if id == nil || (id is NSNull) {
            // Für initialized-Notification nichts senden
            continue
        }

        // An lokalen Nemeton-Server weiterleiten
        let semaphore = DispatchSemaphore(value: 0)
        var responseData: Data?

        var urlRequest = URLRequest(url: URL(string: "\(serverURL)/mcp")!)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = requestData
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 120
        if let authToken {
            urlRequest.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error {
                log("HTTP-Fehler: \(error.localizedDescription)")
                responseData = jsonRpcError(id: id, code: -32603, message: error.localizedDescription)
            } else if let data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                responseData = data
            } else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                log("HTTP \(statusCode)")
                responseData = jsonRpcError(id: id, code: -32603, message: "HTTP \(statusCode)")
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        if let data = responseData {
            log("→ response (\(data.count) bytes)")
            writeLine(data)
        }
    }

    log("NemetonMCP beendet")
}

// MARK: - Helpers

func writeLine(_ data: Data) {
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write("\n".data(using: .utf8)!)
}

func jsonRpcError(id: Any?, code: Int, message: String) -> Data {
    var response: [String: Any] = [
        "jsonrpc": "2.0",
        "error": ["code": code, "message": message]
    ]
    if let id { response["id"] = id }
    return (try? JSONSerialization.data(withJSONObject: response)) ?? Data()
}

main()
