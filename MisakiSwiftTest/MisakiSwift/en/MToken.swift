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

  init(
    is_head: Bool = true,
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
  
  func debugPrint() {
    print("  is_head: \(is_head)")
    print("  alias: \(alias ?? "nil")")
    print("  stress: \(stress ?? 0.0)")
    print("  currency: \(currency ?? "nil")")
    print("  num_flags: \(num_flags)")
    print("  prespace: \(prespace)")
    print("  rating: \(rating ?? 0)")
  }
}

// Single token
public class MToken {
  var text: String
  var tokenRange: Range<String.Index>
  var tag: NLTag?
  var whitespace: String
  var phonemes: String?
  var start_ts: Double?
  var end_ts: Double?
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
  
  func debugPrint() {
    print("MTOKEN")
    print("text: \(text)")
    print("tokenRange: \(tokenRange)")
    print("tag: \(String(describing: tag))")
    print("whitespace: \(whitespace)")
    print("phonemes: \(phonemes ?? "not defined")")
    print("start_ts: \(start_ts ?? 0)")
    print("end_ts: \(end_ts ?? 0)")
    print("Underscore: ")
    `_`.debugPrint()
    print("=========")
  }
}
