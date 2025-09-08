import Foundation
import NaturalLanguage

// Converted from dictionary to explicit structure
class Underscore {
    var is_head: Bool
    var alias: String?
    var stress: Double?
    var currency: String?
    var num_flags: String
    var prespace: Bool
    var rating: Int?

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
public class MToken {
  let text: String
  let tokenRange: Range<String.Index>
  let tag: NLTag?
  var whitespace: String
  var phonemes: String?
  let start_ts: Double?
  let end_ts: Double?
  var `_`: Underscore

  init(
    text: String,
    tokenRange: Range<String.Index>,
    tag: NLTag? = nil,
    whitespace: String,
    phonemes: String? = nil,
    start_ts: Double? = nil,
    end_ts: Double? = nil,
    underscore: Underscore = Underscore()) {
    self.text = text
    self.tokenRange = tokenRange
    self.tag = tag
    self.whitespace = whitespace
    self.phonemes = phonemes
    self.start_ts = start_ts
    self.end_ts = end_ts
    self.`_` = underscore
  }
}
