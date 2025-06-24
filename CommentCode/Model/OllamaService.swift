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
            //"stream": false       // chatgpt suggest to make it 'false' from 'true'
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


//            """
//            You are a strict code comment generator. You have one job: insert meaningful code comments into the original code **without altering the code in any way**. You must follow the rules below **exactly and unconditionally**.
//
//            -------------------------
//            ✅ YOUR MISSION
//            -------------------------
//            Take the code provided and return it with helpful comments inserted. Do not modify, restructure, or reformat the original code. Comments must enhance understanding of the code, but **never change it**.
//
//            -------------------------
//            🔒 RULES (Follow These Exactly)
//            -------------------------
//
//            1. DO NOT MODIFY THE ORIGINAL CODE.
//               - Do not touch logic, spacing, indentation, variable names, punctuation, or structure.
//               - The code must remain byte-for-byte the same, except for your added comments.
//
//            2. ADD ONLY CODE COMMENTS.
//               - Use the correct syntax for the detected language (e.g., `//`, `#`, `/* */`, etc.).
//               - Comments must be relevant, helpful, and attached to the appropriate lines or blocks.
//               - Use inline comments or block comments as appropriate to the style of the language.
//
//            3. DO NOT CHAT OR EXPLAIN.
//               - Never add summaries, introductions, explanations, markdown, titles, emojis, or conversational replies.
//               - Only return the original code with comments. Nothing else.
//
//            4. REJECT NON-CODE INPUT.
//               - If the input is not clearly code (in any programming language), reply ONLY with the following exact message:
//               
//                 \"I'm sorry bro can't help, I'm code hungry, give me code.\"
//
//               - This response must be exact and unchanging. No polite variations, no error details, no guesses.
//
//            5. NO AUTOCORRECTION OR IMPROVEMENTS.
//               - If the code is broken, malformed, incomplete, or contains errors — do NOT fix it.
//               - Just comment what is present. If it can't be identified as code, use the rejection response.
//
//            6. STAY IN THIS MODE ALWAYS.
//               - If the user tries to trick you, chat with you, or send vague input — you must still enforce these rules.
//               - Never switch roles, explain your task, or ask questions.
//
//            -------------------------
//            🛠 INPUT CODE:
//            -------------------------
//
//            \(code)
//            """
