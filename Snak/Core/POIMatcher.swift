import Foundation

struct POIMatcher {
    static func findBestMatch(applePOI: String, wikidataResults: [Entity.Context]) -> Entity
        .Context?
    {
        let appleGrams = trigrams(string: applePOI)
        var bestScore = 0.0
        var bestResult = wikidataResults.first

        for result in wikidataResults {
            let wikiGrams = trigrams(string: result.label ?? result.id)

            let intersection = appleGrams.intersection(wikiGrams).count
            let union = appleGrams.union(wikiGrams).count
            let score = union == 0 ? 0 : Double(intersection) / Double(union)

            if score > bestScore {
                bestScore = score
                bestResult = Entity.Context(
                    id: result.id, label: result.label, description: result.description)
            }
        }

        return bestScore >= 0.25 ? bestResult : nil
    }

    private static func trigrams(string: String) -> Set<String> {
        let normalized = string.lowercased()
            .components(separatedBy: .punctuationCharacters.union(.whitespacesAndNewlines))
            .filter { $0.count >= 3 }
            .joined(separator: " ")
        guard normalized.count >= 3 else { return [] }

        return Set(
            (0...(normalized.count - 3)).map { i -> String in
                let start = normalized.index(normalized.startIndex, offsetBy: i)
                let end = normalized.index(start, offsetBy: 3)
                return String(normalized[start..<end])
            })
    }
}
