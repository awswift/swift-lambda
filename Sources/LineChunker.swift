class LineChunker {
    private var chunk: String
    private var callback: (_: String) -> ()
    
    init(callback: @escaping (_: String) -> ()) {
        self.chunk = ""
        self.callback = callback
    }
    
    func append(_ string: String) {
        chunk.append(string)
        
        while let newlineRange = chunk.rangeOfCharacter(from: .newlines) {
            let line = chunk.substring(to: newlineRange.lowerBound)
            callback(line)
            chunk = chunk.substring(from: newlineRange.upperBound)
        }
    }
    
    func remainder() -> String? {
        defer { chunk = "" }
        
        if chunk.characters.count > 0 {
            return chunk
        } else {
            return nil
        }
    }
}
