import Foundation

let systemLang = Locale.current.language.languageCode?.identifier ?? "en"

let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
let userAgent = "Snak/\(appVersion) (https://github.com/0x7375/snak; ayko@0xaa.me)"

extension Dictionary where Key == String {
    func preferredLanguage() -> Value? {
        return self[systemLang] ?? self["en"]
    }
}

struct WikimediaEndpoint {
    var host: String = "www.wikidata.org"
    var path: String = "/w/api.php"
    var queryItems: [URLQueryItem] = []

    var url: URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = queryItems

        return components.url
    }

    func fetch<T: Decodable>() async throws -> T {
        guard let url = self.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding error: \(url.absoluteString)")
            print(error)

            throw error
        }
    }
}
