import Foundation
import Observation

/// Výsledok kalkulačky zobrazený v spúšťači.
struct CalculationResult: Equatable, Sendable {
    /// Výsledok na zobrazenie („576“, „8,05 mi“, „108,12 USD“).
    let display: String
    /// Čo sa skopíruje (bez oddeľovačov tisícov).
    let copyValue: String
    /// Popis pod výsledkom („128 × 4,5“, „Kurz ECB z 10. 10. 2026“).
    let detail: String
}

/// Kalkulačka: matematika, prevody jednotiek a mien.
@MainActor @Observable
final class Calculator {
    private(set) var rates: CurrencyRates?
    @ObservationIgnored private var ratesTask: Task<Void, Never>?

    init() {
        refreshRatesIfNeeded()
    }

    func evaluate(_ input: String) -> CalculationResult? {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2, text.contains(where: \.isNumber) || text.lowercased().contains("pi") else { return nil }
        if let conversion = convert(text) { return conversion }
        return calculate(text)
    }

    // MARK: - Matematika

    private func calculate(_ input: String) -> CalculationResult? {
        // „100x20“, „100 x 20“, „(2+3)x4“: x medzi číslami/zátvorkami je násobenie.
        let text = input.replacingOccurrences(
            of: #"(?<=[\d)])\s*[xX]\s*(?=[\d(])"#, with: "×", options: .regularExpression)
        // Samotné číslo (alebo dátum/názov súboru) nie je výpočet.
        let operators = CharacterSet(charactersIn: "+-*/×÷^%()")
        let hasFunction = ExpressionParser.functions.keys.contains { text.lowercased().contains($0 + "(") }
            || text.lowercased().contains("pi")
        guard text.unicodeScalars.contains(where: operators.contains) || hasFunction else { return nil }
        var parser = ExpressionParser(text)
        guard let value = try? parser.parse(), value.isFinite else { return nil }
        return CalculationResult(
            display: Self.format(value, maxFraction: 6), copyValue: Self.format(value, grouping: false, maxFraction: 10), detail: text)
    }

    // MARK: - Prevody

    /// „5 km v míľach“, „100 eur to usd“, „30 c na f“.
    private func convert(_ text: String) -> CalculationResult? {
        let pattern = #"^\s*([-+]?[\d\s]*[\d][.,]?\d*)\s*([^\d\s][^\s]*(?:\s[^\s]+)?)\s+(?:v|vo|na|do|to|in|=|->|→)\s+(.+?)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
            let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
            let numberRange = Range(match.range(at: 1), in: text),
            let fromRange = Range(match.range(at: 2), in: text),
            let toRange = Range(match.range(at: 3), in: text),
            let amount = Self.parseNumber(String(text[numberRange]))
        else { return nil }
        let from = String(text[fromRange]), to = String(text[toRange])

        if let fromCode = CurrencyRates.code(for: from), let toCode = CurrencyRates.code(for: to) {
            guard let rates, let value = rates.convert(amount, from: fromCode, to: toCode) else {
                refreshRatesIfNeeded()
                return nil
            }
            return CalculationResult(
                display: "\(Self.format(value, maxFraction: 2)) \(toCode)",
                copyValue: Self.format(value, grouping: false, maxFraction: 2),
                detail: "\(Self.format(amount)) \(fromCode) · kurz ECB z \(rates.date)")
        }

        guard let fromUnit = UnitCatalog.unit(for: from), let toUnit = UnitCatalog.unit(for: to),
            type(of: fromUnit.dimension) == type(of: toUnit.dimension)
        else { return nil }
        let value = Measurement(value: amount, unit: fromUnit.dimension).converted(to: toUnit.dimension).value
        return CalculationResult(
            display: "\(Self.format(value, maxFraction: 4)) \(toUnit.symbol)",
            copyValue: Self.format(value, grouping: false, maxFraction: 4),
            detail: "\(Self.format(amount)) \(fromUnit.symbol)")
    }

    // MARK: - Kurzy mien

    func refreshRatesIfNeeded() {
        guard ratesTask == nil, rates.map({ Date().timeIntervalSince($0.fetchedAt) > 12 * 3600 }) ?? true else { return }
        ratesTask = Task {
            if let fetched = try? await CurrencyRates.fetch() { rates = fetched }
            ratesTask = nil
        }
    }

    // MARK: - Čísla

    static func parseNumber(_ text: String) -> Double? {
        let cleaned = text.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")
        return Double(cleaned)
    }

    static func format(_ value: Double, grouping: Bool = true, maxFraction: Int = 10) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "sk_SK")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = grouping
        formatter.maximumFractionDigits = abs(value) >= 1e15 ? 0 : maxFraction
        if abs(value) >= 1e15 || (abs(value) < 1e-9 && value != 0) {
            formatter.numberStyle = .scientific
            formatter.maximumFractionDigits = 6
        }
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

// MARK: - Parser výrazov

/// Jednoduchý parser matematických výrazov (bez NSExpression, ktoré pri chybe padá).
struct ExpressionParser {
    static let functions: [String: (Double) -> Double] = [
        "sqrt": { $0.squareRoot() }, "odm": { $0.squareRoot() },
        "sin": sin, "cos": cos, "tan": tan, "ln": log, "log": log10, "abs": abs,
        "round": { $0.rounded() }, "floor": floor, "ceil": ceil,
    ]

    enum ParseError: Error { case invalid }

    private let chars: [Character]
    private var index = 0

    init(_ text: String) {
        chars = Array(text.lowercased().replacingOccurrences(of: "×", with: "*").replacingOccurrences(of: "÷", with: "/"))
    }

    mutating func parse() throws -> Double {
        let value = try expression()
        skipSpaces()
        guard index == chars.count else { throw ParseError.invalid }
        return value
    }

    // výraz = člen (('+'|'-') člen)*
    private mutating func expression() throws -> Double {
        var value = try term()
        while true {
            skipSpaces()
            guard let c = peek(), c == "+" || c == "-" else { return value }
            index += 1
            let rhs = try term()
            // „200 + 10%“ = 220 (percento z ľavej strany).
            if lastWasPercent {
                value = c == "+" ? value * (1 + rhs) : value * (1 - rhs)
                lastWasPercent = false
            } else {
                value = c == "+" ? value + rhs : value - rhs
            }
        }
    }

    private var lastWasPercent = false

    // člen = mocnina (('*'|'/') mocnina)*
    private mutating func term() throws -> Double {
        var value = try power()
        while true {
            skipSpaces()
            guard let c = peek(), c == "*" || c == "/" else { return value }
            index += 1
            let rhs = try power()
            lastWasPercent = false
            value = c == "*" ? value * rhs : value / rhs
        }
    }

    // mocnina = unárny ('^' mocnina)?
    private mutating func power() throws -> Double {
        let base = try unary()
        skipSpaces()
        if peek() == "^" {
            index += 1
            return pow(base, try power())
        }
        return base
    }

    private mutating func unary() throws -> Double {
        skipSpaces()
        if peek() == "-" { index += 1; return -(try unary()) }
        if peek() == "+" { index += 1; return try unary() }
        var value = try primary()
        skipSpaces()
        lastWasPercent = false
        if peek() == "%" {
            index += 1
            value /= 100
            lastWasPercent = true
        }
        return value
    }

    private mutating func primary() throws -> Double {
        skipSpaces()
        guard let c = peek() else { throw ParseError.invalid }
        if c == "(" {
            index += 1
            let value = try expression()
            skipSpaces()
            guard peek() == ")" else { throw ParseError.invalid }
            index += 1
            return value
        }
        if c.isNumber || c == "." || c == "," { return try number() }
        if c.isLetter {
            var name = ""
            while let l = peek(), l.isLetter { name.append(l); index += 1 }
            if name == "pi" || name == "π" { return .pi }
            if name == "e" { return M_E }
            guard let function = Self.functions[name] else { throw ParseError.invalid }
            skipSpaces()
            guard peek() == "(" else { throw ParseError.invalid }
            return function(try primary())
        }
        throw ParseError.invalid
    }

    private mutating func number() throws -> Double {
        var text = ""
        var separators = 0
        while let c = peek(), c.isNumber || c == "." || c == "," {
            if c == "." || c == "," { separators += 1; text.append(".") } else { text.append(c) }
            index += 1
        }
        guard separators <= 1, let value = Double(text) else { throw ParseError.invalid }
        return value
    }

    private func peek() -> Character? { index < chars.count ? chars[index] : nil }
    private mutating func skipSpaces() { while peek() == " " { index += 1 } }
}

// MARK: - Jednotky

enum UnitCatalog {
    struct Entry {
        let dimension: Dimension
        let symbol: String
    }

    /// Prípony a slovenské/anglické názvy (bez diakritiky). Dlhšie názvy sa porovnávajú aj podľa začiatku („mil“ → míľach).
    private static let entries: [(names: [String], entry: Entry)] = [
        (["m", "meter", "metre", "metrov", "metroch"], Entry(dimension: UnitLength.meters, symbol: "m")),
        (["km", "kilometer", "kilometrov", "kilometroch"], Entry(dimension: UnitLength.kilometers, symbol: "km")),
        (["cm", "centimeter"], Entry(dimension: UnitLength.centimeters, symbol: "cm")),
        (["mm", "milimeter"], Entry(dimension: UnitLength.millimeters, symbol: "mm")),
        (["mi", "mile", "miles", "mila", "mil", "milach", "mile"], Entry(dimension: UnitLength.miles, symbol: "mi")),
        (["ft", "feet", "foot", "stopa", "stop", "stopach"], Entry(dimension: UnitLength.feet, symbol: "ft")),
        (["in", "inch", "inches", "palec", "palcov", "palcoch"], Entry(dimension: UnitLength.inches, symbol: "in")),
        (["yd", "yard", "yards", "yardov"], Entry(dimension: UnitLength.yards, symbol: "yd")),
        (["kg", "kilogram", "kil", "kila"], Entry(dimension: UnitMass.kilograms, symbol: "kg")),
        (["g", "gram", "gramov"], Entry(dimension: UnitMass.grams, symbol: "g")),
        (["mg", "miligram"], Entry(dimension: UnitMass.milligrams, symbol: "mg")),
        (["t", "tona", "ton", "tonach"], Entry(dimension: UnitMass.metricTons, symbol: "t")),
        (["lb", "lbs", "pound", "pounds", "libra", "libier", "librach"], Entry(dimension: UnitMass.pounds, symbol: "lb")),
        (["oz", "ounce", "ounces", "unca", "unci"], Entry(dimension: UnitMass.ounces, symbol: "oz")),
        (["c", "°c", "celsius", "stupnov", "stupne"], Entry(dimension: UnitTemperature.celsius, symbol: "°C")),
        (["f", "°f", "fahrenheit", "fahrenheita"], Entry(dimension: UnitTemperature.fahrenheit, symbol: "°F")),
        (["k", "kelvin", "kelvinov"], Entry(dimension: UnitTemperature.kelvin, symbol: "K")),
        (["l", "liter", "litrov", "litroch"], Entry(dimension: UnitVolume.liters, symbol: "l")),
        (["ml", "mililiter"], Entry(dimension: UnitVolume.milliliters, symbol: "ml")),
        (["gal", "gallon", "galon", "galonov"], Entry(dimension: UnitVolume.gallons, symbol: "gal")),
        (["km/h", "kmh"], Entry(dimension: UnitSpeed.kilometersPerHour, symbol: "km/h")),
        (["mph"], Entry(dimension: UnitSpeed.milesPerHour, symbol: "mph")),
        (["m/s"], Entry(dimension: UnitSpeed.metersPerSecond, symbol: "m/s")),
        (["kn", "knot", "uzol", "uzlov"], Entry(dimension: UnitSpeed.knots, symbol: "kn")),
        (["m2", "m²"], Entry(dimension: UnitArea.squareMeters, symbol: "m²")),
        (["km2", "km²"], Entry(dimension: UnitArea.squareKilometers, symbol: "km²")),
        (["ha", "hektar", "hektarov"], Entry(dimension: UnitArea.hectares, symbol: "ha")),
        (["acre", "acres", "aker"], Entry(dimension: UnitArea.acres, symbol: "ac")),
        (["b", "byte", "bajt", "bajtov"], Entry(dimension: UnitInformationStorage.bytes, symbol: "B")),
        (["kb"], Entry(dimension: UnitInformationStorage.kilobytes, symbol: "kB")),
        (["mb"], Entry(dimension: UnitInformationStorage.megabytes, symbol: "MB")),
        (["gb"], Entry(dimension: UnitInformationStorage.gigabytes, symbol: "GB")),
        (["tb"], Entry(dimension: UnitInformationStorage.terabytes, symbol: "TB")),
        (["s", "sec", "sekunda", "sekund", "sekundach"], Entry(dimension: UnitDuration.seconds, symbol: "s")),
        (["min", "minuta", "minut", "minutach"], Entry(dimension: UnitDuration.minutes, symbol: "min")),
        (["h", "hod", "hodina", "hodin", "hodinach", "hour", "hours"], Entry(dimension: UnitDuration.hours, symbol: "h")),
        (["kcal"], Entry(dimension: UnitEnergy.kilocalories, symbol: "kcal")),
        (["kj"], Entry(dimension: UnitEnergy.kilojoules, symbol: "kJ")),
        (["kwh"], Entry(dimension: UnitEnergy.kilowattHours, symbol: "kWh")),
    ]

    static func unit(for text: String) -> Entry? {
        let name = IndexedFile.normalize(text.trimmingCharacters(in: .whitespaces))
        if let exact = entries.first(where: { $0.names.contains(name) }) { return exact.entry }
        // Ohnuté tvary: „míľach“ → „mil“, „kilometroch“ → „kilometer“.
        return entries.first { item in item.names.contains { $0.count >= 3 && name.hasPrefix($0) } }?.entry
    }
}

// MARK: - Meny

struct CurrencyRates: Sendable {
    /// Kurz voči EUR (1 EUR = x jednotiek meny).
    let perEuro: [String: Double]
    let date: String
    let fetchedAt: Date

    private static let aliases: [String: String] = [
        "€": "EUR", "eur": "EUR", "euro": "EUR", "eura": "EUR", "eur.": "EUR",
        "$": "USD", "usd": "USD", "dolar": "USD", "dolarov": "USD", "dolare": "USD", "dolaroch": "USD",
        "kc": "CZK", "czk": "CZK", "korun": "CZK", "koruny": "CZK", "korunach": "CZK",
        "£": "GBP", "gbp": "GBP", "¥": "JPY", "zl": "PLN", "forint": "HUF", "forintov": "HUF", "frank": "CHF", "frankov": "CHF",
    ]

    static func code(for text: String) -> String? {
        let name = IndexedFile.normalize(text.trimmingCharacters(in: .whitespaces))
        if let code = aliases[name] { return code }
        let upper = name.uppercased()
        return upper.count == 3 && upper.allSatisfy(\.isLetter) && knownCodes.contains(upper) ? upper : nil
    }

    /// Meny, ktoré publikuje ECB.
    static let knownCodes: Set<String> = [
        "EUR", "USD", "JPY", "BGN", "CZK", "DKK", "GBP", "HUF", "PLN", "RON", "SEK", "CHF", "ISK", "NOK", "TRY",
        "AUD", "BRL", "CAD", "CNY", "HKD", "IDR", "ILS", "INR", "KRW", "MXN", "MYR", "NZD", "PHP", "SGD", "THB", "ZAR",
    ]

    func convert(_ amount: Double, from: String, to: String) -> Double? {
        let fromRate = from == "EUR" ? 1 : perEuro[from]
        let toRate = to == "EUR" ? 1 : perEuro[to]
        guard let fromRate, let toRate else { return nil }
        return amount / fromRate * toRate
    }

    /// Denné referenčné kurzy Európskej centrálnej banky (verejné, bez kľúča).
    static func fetch() async throws -> CurrencyRates {
        let url = URL(string: "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let xml = String(decoding: data, as: UTF8.self)
        let rateRegex = try NSRegularExpression(pattern: #"currency='([A-Z]{3})'\s+rate='([\d.]+)'"#)
        var rates: [String: Double] = [:]
        for match in rateRegex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml)) {
            if let c = Range(match.range(at: 1), in: xml), let r = Range(match.range(at: 2), in: xml), let value = Double(xml[r]) {
                rates[String(xml[c])] = value
            }
        }
        guard !rates.isEmpty else { throw URLError(.cannotParseResponse) }
        var date = ""
        if let timeMatch = try NSRegularExpression(pattern: #"time='(\d{4})-(\d{2})-(\d{2})'"#)
            .firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
            let y = Range(timeMatch.range(at: 1), in: xml), let m = Range(timeMatch.range(at: 2), in: xml),
            let d = Range(timeMatch.range(at: 3), in: xml)
        {
            date = "\(Int(xml[d]) ?? 0). \(Int(xml[m]) ?? 0). \(xml[y])"
        }
        return CurrencyRates(perEuro: rates, date: date, fetchedAt: Date())
    }
}
