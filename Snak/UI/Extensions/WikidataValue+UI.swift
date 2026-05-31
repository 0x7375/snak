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
            let cleanStr = date.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            let year = Int(cleanStr.prefix(4)) ?? 0

            // century
            if precision == 7 {
                let fmt = NumberFormatter()
                fmt.numberStyle = .ordinal
                let ordinal = fmt.string(from: NSNumber(value: (year / 100) + 1)) ?? ""
                return "\(ordinal) century"
            }

            let displayFmt = DateFormatter()

            if precision == 11 {
                displayFmt.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
            } else if precision == 10 {
                displayFmt.setLocalizedDateFormatFromTemplate("MMMM yyyy")
            } else {
                displayFmt.setLocalizedDateFormatFromTemplate("yyyy")
            }

            let beforeCommonArea = String(localized: "BCE")
            guard !isBCE, let parsedDate = ISO8601DateFormatter().date(from: cleanStr) else {
                return isBCE ? "\(year) \(beforeCommonArea)" : cleanStr
            }

            let result = displayFmt.string(from: parsedDate)
            return isBCE ? "\(result) \(beforeCommonArea)" : result

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
