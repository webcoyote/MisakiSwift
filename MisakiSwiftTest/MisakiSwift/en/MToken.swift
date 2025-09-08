import Foundation

// Converted from dictionary to explicit structure
struct Underscore {
    let is_head: Bool
    let alias: String?
    let stress: Double?
    let currency: String?
    let num_flags: String
    let prespace: Bool
    let rating: Int?

    init(is_head: Bool = true,
         alias: String? = nil,
         stress: Double? = nil,
         currency: String? = nil,
         num_flags: String = "",
         prespace: Bool = false,
         rating: Int? = nil) {
        self.is_head = is_head
        self.alias = alias
        self.stress = stress
        self.currency = currency
        self.num_flags = num_flags
        self.prespace = prespace
        self.rating = rating
    }
}

// Single token
public struct MToken {
    let text: String
    let tag: String?
    var whitespace: String
    let phonemes: String?
    let start_ts: Double?
    let end_ts: Double?
    let `_`: Underscore

    init(text: String,
         tag: String? = nil,
         whitespace: String,
         phonemes: String? = nil,
         start_ts: Double? = nil,
         end_ts: Double? = nil,
         underscore: Underscore = Underscore()) {
        self.text = text
        self.tag = tag
        self.whitespace = whitespace
        self.phonemes = phonemes
        self.start_ts = start_ts
        self.end_ts = end_ts
        self.`_` = underscore
    }        
}
