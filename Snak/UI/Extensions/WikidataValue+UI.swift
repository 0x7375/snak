import Foundation

extension WikidataValue where Ref == Entity.Statement.Reference {
    var id: String? {
        if case .entity(let ref) = self {
            return ref.id
        }
        return nil
    }

    var isSearchable: Bool {
        switch self {
        case .math:
            return false
        default:
            return true
        }
    }

    var systemImage: String {
        switch self {
        case .entity:
            return "cube.transparent"
        case .string:
            return "text.alignleft"
        case .quantity:
            return "number"
        case .time:
            return "calendar"
        case .coordinate:
            return "mappin.and.ellipse"
        case .math:
            return "function"
        case .url:
            return "globe"
        case .externalID:
            return "barcode.viewfinder"
        }
    }

    var displayString: String {
        switch self {
        case .entity(let reference):
            return reference.label ?? reference.id

        case .string(let text), .math(let text), .url(let text), .externalID(let text):
            return text

        case .quantity(let amount, let unit):
            if let unit {
                let unitName = unit.label ?? unit.id
                return "\(amount.formatted()) \(unitName)"
            }
            return amount.formatted()

        case .time(let date, let precision):
            let isBCE = date.hasPrefix("-")
            let trimmedStr = date.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            let dateStr = String(trimmedStr.split(separator: "T").first ?? trimmedStr[...])
            let parts = dateStr.split(separator: "-").map(String.init)
            let yearInt = Int(parts[0]) ?? 0
            let bce = isBCE ? String(localized: " BCE") : ""

            let fmt = NumberFormatter()
            fmt.numberStyle = .ordinal
            switch precision {
            case .millennium:
                let ordinal = fmt.string(from: NSNumber(value: yearInt / 1000)) ?? ""
                let result = String(localized: "\(ordinal) millennium")
                return "\(result)\(bce)"
            case .century:
                let ordinal = fmt.string(from: NSNumber(value: (yearInt / 100) + 1)) ?? ""
                let result = String(localized: "\(ordinal) century")
                return "\(result)\(bce)"
            case .decade:
                let result = String(localized: "\(yearInt)s")
                return "\(result)\(bce)"
            default:
                break
            }

            let month = parts.count > 1 ? (parts[1] == "00" ? "01" : parts[1]) : "01"
            let day = parts.count > 2 ? (parts[2] == "00" ? "01" : parts[2]) : "01"
            let normalizedDate = "\(parts[0])-\(month)-\(day)"

            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

            guard !isBCE, let parsedDate = isoFormatter.date(from: normalizedDate) else {
                return "\(yearInt)\(bce)"
            }

            let displayFmt = DateFormatter()
            switch precision {
            case .day: displayFmt.setLocalizedDateFormatFromTemplate("d MMMM y")
            case .month: displayFmt.setLocalizedDateFormatFromTemplate("MMMM y")
            default: displayFmt.setLocalizedDateFormatFromTemplate("y")
            }

            let result = displayFmt.string(from: parsedDate)
            return "\(result)\(bce)"

        case .coordinate(let lat, let lon):
            func dms(from val: Double, axis: Axis) -> String {
                let absVal = abs(val)
                let degrees = Int(absVal)
                let totalMinutes = (absVal - Double(degrees)) * 60
                let minutes = Int(totalMinutes)
                let seconds = Int(((totalMinutes - Double(minutes)) * 60).rounded())

                let direction: String
                switch axis {
                case .latitude:
                    direction =
                        val >= 0
                        ? String(localized: "N", comment: "North abbreviated")
                        : String(localized: "S", comment: "South abbreviated")
                case .longitude:
                    direction =
                        val >= 0
                        ? String(localized: "E", comment: "East abbreviated")
                        : String(localized: "W", comment: "West abbreviated")
                }

                guard minutes > 0 || seconds > 0 else { return "\(degrees)°\(direction)" }
                guard seconds > 0 else { return "\(degrees)°\(minutes)'\(direction)" }
                return "\(degrees)°\(minutes)'\(seconds)\"\(direction)"
            }

            return "\(dms(from: lat, axis: .latitude)), \(dms(from: lon, axis: .longitude))"
        }
    }
    private enum Axis { case latitude, longitude }
}
