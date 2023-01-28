import Foundation

class Files {
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func store(filename: String, contents: Data) -> Bool {
        let documentDirectory = getDocumentsDirectory()
        let filePath = documentDirectory.appending(path: filename)
        
        do {
            try contents.write(to: filePath, options: [.atomic])
            return true
        } catch {
            return false
        }
    }
    
    static func read(filename: String) -> Result<Data, Error> {
        let documentDirectory = getDocumentsDirectory()
        let filePath = documentDirectory.appending(path: filename)
        do {
            let contents = try Data(contentsOf: filePath)
            return Result.success(contents)
        } catch {
            return Result.failure(error)
        }
    }
}
