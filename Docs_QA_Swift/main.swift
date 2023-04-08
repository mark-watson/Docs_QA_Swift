//
//  main.swift
//  Docs_QA_Swift
//
//  Created by Mark Watson on 4/7/23.
//

import Foundation
import NaturalLanguage

// String utilities:

extension String {
    func removeCharacters(from forbiddenChars: CharacterSet) -> String {
        let passed = self.unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }

    func removeCharacters(from: String) -> String {
        return removeCharacters(from: CharacterSet(charactersIn: from))
    }
    func plainText() -> String {
        return self.removeCharacters(from: "\"`()%$#@[]{}<>").replacingOccurrences(of: "\n", with: " ")
    }
}

//print("env:", ProcessInfo.processInfo.environment)
let openai_key = ProcessInfo.processInfo.environment["OPENAI_KEY"]!

let openAiHost = "https://api.openai.com/v1/embeddings"

func openAiHelper(body: String)  -> String {
    var ret = ""
    var content = "{}"
    let requestUrl = URL(string: openAiHost)!
    var request = URLRequest(url: requestUrl)
    request.httpMethod = "POST"
    request.httpBody = body.data(using: String.Encoding.utf8);
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer " + openai_key, forHTTPHeaderField: "Authorization")
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("-->> Error accessing OpenAI servers: \(error)")
            return
        }
        if let data = data, let s = String(data: data, encoding: .utf8) {
            content = s
            //print("** s=", s)
            CFRunLoopStop(CFRunLoopGetMain())
        }
    }
    task.resume()
    CFRunLoopRun()
    let c = String(content)
    let i1 = c.range(of: "\"embedding\":")
    if let r1 = i1 {
        let i2 = c.range(of: "]")
        if let r2 = i2 {
            ret = String(String(String(c[r1.lowerBound..<r2.lowerBound]).dropFirst(15)).dropLast(2))
        }
    }
    return ret
}

public func embeddings(someText: String) -> [Float] {
    let body: String = "{\"input\": \"" + someText + "\", \"model\": \"text-embedding-ada-002\" }"
    return readList(openAiHelper(body: body))
}

func dotProduct(_ list1: [Float], _ list2: [Float]) -> Float {
    if list1.count != list2.count {
        //fatalError("Lists must have the same length.")
        print("WARNING: Lists must have the same length: \(list1.count) != \(list2.count)")
        return 0.0
    }
    
    var result: Float = 0
    
    for i in 0..<list1.count {
        result += list1[i] * list2[i]
    }
    
    return result
}

func readList(_ input: String) -> [Float] {
    //print("* input:", input)
    return input.split(separator: ",\n").compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
}

let emb1 = embeddings(someText: "John bought a new car")
//print("** emb1 = ", emb1)

let emb2 = embeddings(someText: "Sally drove to the store")
//print("** emb2 = ", emb2)

let emb3 = embeddings(someText: "The dog saw a cat")
//print("** emb3 = ", emb3)

let dotProductResult1 = dotProduct(emb1, emb2)
print(dotProductResult1)

let dotProductResult2 = dotProduct(emb1, emb3)
print(dotProductResult2)

var embeddingsStore: Array<[Float]> = Array()
var chunks: Array<String> = Array()

func addEmbedding(_ embedding: [Float]) {
    embeddingsStore.append(embedding)
    //print("Added embedding: count=\(embeddingsStore.count)  \(embedding)")
}

func addChunk(_ chunk: String) {
    chunks.append(chunk)
}

let fileManager = FileManager.default
let currentDirectoryURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let dataDirectoryURL = currentDirectoryURL.appendingPathComponent("data")

do {
    let directoryContents = try fileManager.contentsOfDirectory(at: dataDirectoryURL, includingPropertiesForKeys: nil)
    let txtFiles = directoryContents.filter { $0.pathExtension == "txt" }
    for txtFile in txtFiles {
        let content = try String(contentsOf: txtFile)
        //print(content)
        let chnks = segmentTextIntoChunks(text: content.plainText(), max_chunk_size: 100)
        //print("\n\nchunks:\n", chnks)
        for chunk in chnks {
            let embedding = embeddings(someText: chunk)
            if embedding.count > 0 {
                addEmbedding(embedding)
                addChunk(chunk)
            }
        }
    }
} catch {

}
       
func segmentTextIntoSentences(text: String) -> [String] {
    let tokenizer = NLTokenizer(unit: .sentence)
    tokenizer.string = text
    let sentences = tokenizer.tokens(for: text.startIndex..<text.endIndex).map { token -> String in
        return String(text[token.lowerBound..<token.upperBound])
    }
    return sentences
}

let text = "Hello there! How are you doing today? It's a nice day outside."
let sentences = segmentTextIntoSentences(text: text)
//print(sentences)

func segmentTextIntoChunks(text: String, max_chunk_size: Int) -> [String] {
    let sentences = segmentTextIntoSentences(text: text)
    var chunks: Array<String> = Array()
    var currentChunk = ""
    var currentChunkSize = 0
    for sentence in sentences {
        if currentChunkSize + sentence.count < max_chunk_size {
            currentChunk += sentence
            currentChunkSize += sentence.count
        } else {
            chunks.append(currentChunk)
            currentChunk = sentence
            currentChunkSize = sentence.count
        }
    }
    return chunks
}

//  For OpenAI QA API:

let openAiQaHost = "https://api.openai.com/v1/chat/completions"

func openAiQaHelper(body: String)  -> String {
    var ret = ""
    var content = "{}"
    let requestUrl = URL(string: openAiQaHost)!
    var request = URLRequest(url: requestUrl)
    request.httpMethod = "POST"
    request.httpBody = body.data(using: String.Encoding.utf8);
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer " + openai_key, forHTTPHeaderField: "Authorization")
    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
        if let error = error {
            print("-->> Error accessing OpenAI servers: \(error)")
            return
        }
        if let data = data, let s = String(data: data, encoding: .utf8) {
            content = s
            CFRunLoopStop(CFRunLoopGetMain())
        }
    }
    task.resume()
    CFRunLoopRun()
    let c = String(content)
    print("DEBUG response c:", c)
    let i1 = c.range(of: "\"content\":")
    if let r1 = i1 {
        let i2 = c.range(of: "\"}")
        if let r2 = i2 {
            ret = String(String(String(c[r1.lowerBound..<r2.lowerBound]).dropFirst(11)))
        }
    }
    return ret
}

func questionAnswering(context: String, question: String) -> String {
    let body = "{ \"model\": \"gpt-3.5-turbo\", \"messages\": [ {\"role\": \"system\", \"content\": \"" +
      context + "\"}, {\"role\": \"user\", \"content\": \"" + question + "\"}]}"

    //print("DEBUG body:", body)
    
    let answer = openAiQaHelper(body: body)
    if let i1 = answer.range(of: "\"content\":") {
        return String(answer[answer.startIndex..<i1.lowerBound])
        //return String(answer.prefix(i1.lowerBound))
    }
    return answer
}

//  Top level query interface:

func query(_ query: String) -> String {
    let queryEmbedding = embeddings(someText: query)
    var contextText = ""
    for i in 0..<embeddingsStore.count {
        let dotProductResult = dotProduct(queryEmbedding, embeddingsStore[i])
        if dotProductResult > 0.8 {
            contextText.append(chunks[i])
            contextText.append(" ")
        }
    }
    //print("\n\n+++++++ contextText = \(contextText)\n\n")
    let answer = questionAnswering(context: contextText, question: query)
    print("* * query: ", query)
    print("* * answer:", answer)
    return answer

}

query("What is the history of chemistry?")
query("What is the definition of sports?")
query("What is the microeconomics?")


