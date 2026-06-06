import Foundation

extension StringProtocol {
    var smartCase: String {
        guard let first = self.first else { return String(self) }

        let firstWord = self.prefix(while: { !$0.isWhitespace })

        if firstWord.contains(where: { $0.isUppercase }) {
            return String(self)
        }

        return first.uppercased() + String(self.dropFirst())
    }
}
