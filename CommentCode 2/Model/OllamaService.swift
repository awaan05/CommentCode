//
//  OllamaService.swift
//  CommentCode
//

import Foundation

struct OllamaChunk: Decodable {
    let response: String
    let done: Bool?
}

class OllamaService {
    static func sendRequest(for code: String, prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "http://localhost:11434/api/generate") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let jsonBody: [String: Any] = [
            "model": "llama3.2",
            "prompt": "\(prompt)\n\n\(code)",
            //"stream": false       // chatgpt suggested to make it 'false' from 'true'
        ]                                   // *Need to know how this is working
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            completion(.failure(error))
            return
        }

        let session = URLSession(configuration: .default)
        var fullResponse = ""

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }

            if let raw = String(data: data, encoding: .utf8) {
                let lines = raw.split(separator: "\n")
                for line in lines {
                    if let jsonLine = line.data(using: .utf8),
                       let chunk = try? JSONDecoder().decode(OllamaChunk.self, from: jsonLine) {
                        fullResponse += chunk.response // Directly use chunk.response
                    }
                }

                // Check if the stream is done
                if let lastLine = lines.last,
                   let lastJson = lastLine.data(using: .utf8),
                   let lastChunk = try? JSONDecoder().decode(OllamaChunk.self, from: lastJson),
                   lastChunk.done == true {
                    DispatchQueue.main.async {
                        completion(.success(fullResponse))
                    }
                }
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"])))
            }
        }

        task.resume()
    }
}
