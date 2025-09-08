import Foundation
import NaturalLanguage

extension Range where Bound: Comparable {
    func contains(_ other: Range<Bound>) -> Bool {
        return self.lowerBound <= other.lowerBound && self.upperBound >= other.upperBound
    }
}

// Main G2P pipeline for English text
final public class EnglishG2P {
  private let british: Bool
  private let tagger: NLTagger
  private let lexicon: Lexicon
  private let fallback: EnglishFallbackNetwork
  private let unk: String
  
  struct PreprocessFeature {
    enum Value {
      case int(Int)
      case double(Double)
      case string(String)
    }
    
    let value: Value
    let tokenRange: Range<String.Index>
  }

  public init(british: Bool = false, unk: String = "❓") {
    self.british = british
    self.tagger = NLTagger(tagSchemes: [.lexicalClass])
    self.lexicon = Lexicon(british: british)
    self.fallback = EnglishFallbackNetwork(british: british)
    self.unk = unk
  }

    /*
    public func tokenize(_ text: String, _ tokens: [String], _ features: [Int: Any]) -> [MToken] {
        tokenizer.string = text
        
        var mutableTokens: [MToken] = []
        let range = text.startIndex..<text.endIndex

        tokenizer.enumerateTokens(in: range) { tokenRange, _ in
            tokens.append(String(text[tokenRange]))
            return true
        }
                    
        if features.isEmpty { return mutableTokens }
        
        // Placeholder: simplistic alignment by index
        for (k, v) in features {
            guard k < mutableTokens.count else { continue }
            switch v {
            case let val as Int:
                mutableTokens[k].`_`.stress = Double(val)
            case let val as Double:
                mutableTokens[k].`_`.stress = val
            case let val as String:
                if val.hasPrefix("/") {
                    mutableTokens[k].`_`.is_head = true
                    mutableTokens[k].phonemes = String(val.dropFirst())
                    mutableTokens[k].`_`.rating = 5
                } else if val.hasPrefix("#") {
                    mutableTokens[k].`_`.num_flags = String(val.dropFirst())
                }
            default:
                break
            }
        }
        
        return mutableTokens
    }

    public func foldLeft(_ tokens: [MToken]) -> [MToken] {
        var result: [MToken] = []
        for tk in tokens {
            if let last = result.last, !tk.`_`.is_head {
                _ = result.popLast()
                let merged = mergeTokens([last, tk], unk: self.unk)
                result.append(merged)
            } else {
                result.append(tk)
            }
        }
        return result
    }

    public static func subtokenize(_ word: String) -> [String] {
        return [word]
    }

    public static func retokenize(_ tokens: [MToken]) -> [Any] {
        var words: [Any] = []
        var currency: String? = nil
        for (i, token) in tokens.enumerated() {
            let needsSplit = (token.`_`.alias == nil && token.phonemes == nil)
            var tks: [MToken]
            if needsSplit {
                let parts = subtokenize(token.text)
                tks = parts.map { part in
                    var t = token
                    t.text = part
                    t.whitespace = ""
                    t.`_`.is_head = true
                    t.`_`.prespace = false
                    return t
                }
            } else { tks = [token] }
            if var last = tks.last { last.whitespace = token.whitespace; tks[tks.count - 1] = last }
            for j in 0..<tks.count {
                var tk = tks[j]
                if tk.`_`.alias != nil || tk.phonemes != nil {
                } else if tk.tag == "$", CURRENCIES[tk.text] != nil {
                    currency = tk.text
                    tk.phonemes = ""
                    tk.`_`.rating = 4
                } else if tk.tag == ":", (tk.text == "-" || tk.text == "–") {
                    tk.phonemes = "—"
                    tk.`_`.rating = 3
                } else if let tag = tk.tag, PUNCT_TAGS.contains(tag), !tk.text.allSatisfy({ isAsciiLetter($0) }) {
                    tk.phonemes = PUNCT_TAG_PHONEMES[tk.tag ?? ""] ?? String(tk.text.filter { PUNCTS.contains($0) })
                    tk.`_`.rating = 4
                } else if currency != nil {
                    if tk.tag != "CD" { currency = nil }
                    else if j + 1 == tks.count && (i + 1 == tokens.count || tokens[i + 1].tag != "CD") {
                        tk.`_`.currency = currency
                    }
                } else if j > 0 && j < tks.count - 1 && tk.text == "2" {
                    let prev = tks[j - 1].text
                    let next = tks[j + 1].text
                    if (prev.last.map { String($0) } ?? "" + (next.first.map { String($0) } ?? "")).allSatisfy({ isAsciiLetter($0.first!) }) {
                        tk.`_`.alias = "to"
                    }
                }
                if tk.`_`.alias != nil || tk.phonemes != nil {
                    words.append(tk)
                } else if let last = words.last as? [MToken], last.last?.whitespace.isEmpty == true {
                    var arr = last
                    tk.`_`.is_head = false
                    arr.append(tk)
                    _ = words.popLast()
                    words.append(arr)
                } else {
                    if tk.whitespace.isEmpty { words.append([tk]) } else { words.append(tk) }
                }
            }
        }
        return words.map { item in
            if let arr = item as? [MToken], arr.count == 1 { return arr[0] }
            return item
        }
    }

    public static func tokenContext(_ ctx: TokenContext, ps: String?, token: MToken) -> TokenContext {
        var vowel = ctx.future_vowel
        if let ps = ps {
            for c in ps {
                if NON_QUOTE_PUNCTS.contains(c) { vowel = nil; break }
                if VOWELS.contains(c) { vowel = true; break }
                if CONSONANTS.contains(c) { vowel = false; break }
            }
        }
        let future_to = (token.text == "to" || token.text == "To") || (token.text == "TO" && (token.tag == "TO" || token.tag == "IN"))
        return TokenContext(future_vowel: vowel, future_to: future_to)
    }

    public static func resolveTokens(_ tokens: inout [MToken]) {
        let text = tokens.dropLast().map { $0.text + $0.whitespace }.joined() + (tokens.last?.text ?? "")
        let prespace = text.contains(" ") || text.contains("/") || Set(text.compactMap { c -> Int? in
            if SUBTOKEN_JUNKS.contains(c) { return nil }
            if String(c).range(of: "[A-Za-z]", options: .regularExpression) != nil { return 0 }
            if String(c).range(of: "[0-9]", options: .regularExpression) != nil { return 1 }
            return 2
        }).count > 1
        for i in 0..<tokens.count {
            if tokens[i].phonemes == nil {
                if i == tokens.count - 1, let last = tokens[i].text.last, NON_QUOTE_PUNCTS.contains(last) {
                    tokens[i].phonemes = tokens[i].text
                    tokens[i].`_`.rating = 3
                } else if tokens[i].text.allSatisfy({ SUBTOKEN_JUNKS.contains($0) }) {
                    tokens[i].phonemes = ""
                    tokens[i].`_`.rating = 3
                }
            } else if i > 0 {
                tokens[i].`_`.prespace = prespace
            }
        }
        if prespace { return }
        var indices: [(Bool, Int, Int)] = []
        for (i, tk) in tokens.enumerated() {
            if let ps = tk.phonemes, !ps.isEmpty { indices.append((ps.contains(PRIMARY_STRESS), stressWeight(ps), i)) }
        }
        if indices.count == 2, tokens[indices[0].2].text.count == 1 {
            let i = indices[1].2
            tokens[i].phonemes = applyStress(tokens[i].phonemes, stress: -0.5)
            return
        } else if indices.count < 2 || indices.map({ $0.0 ? 1 : 0 }).reduce(0, +) <= (indices.count + 1) / 2 {
            return
        }
        indices.sort { ($0.0 ? 1 : 0, $0.1) < ($1.0 ? 1 : 0, $1.1) }
        let cut = indices.prefix(indices.count / 2)
        for x in cut {
            let i = x.2
            tokens[i].phonemes = applyStress(tokens[i].phonemes, stress: -0.5)
        }
    }
    */
    
  // Text pre-processing tuple for easing the tokenization
  typealias PreprocessTuple = (text: String, tokens: [String], features: [PreprocessFeature])
    
  /// Preprocesses the string in case there are some parts where the pronounciation or stress is pre-dictated using Markdown-like link format, e.g.
  /// "[Misaki](/misˈɑki/) is a G2P engine designed for [Kokoro](/kˈOkəɹO/) models."
  private func preprocess(text: String) -> PreprocessTuple {
    // Matches the pattern of form [link text](url) and captures the two parts
    let linkRegex = try! NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^\)]*)\)"#, options: [])

    var result = ""
    var tokens: [String] = []
    var features: [PreprocessFeature] = []

    let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
    var lastEnd = input.startIndex
    let ns = input as NSString
    let fullRange = NSRange(location: 0, length: ns.length)
 
    linkRegex.enumerateMatches(in: input, options: [], range: fullRange) { match, _, _ in
      guard let m = match else { return }

      let range = m.range
      let start = input.index(input.startIndex, offsetBy: range.location)
      let end = input.index(start, offsetBy: range.length)

      result += String(input[lastEnd..<start])
      tokens.append(contentsOf: String(input[lastEnd..<start]).split(separator: " ").map(String.init))

      let grapheme = ns.substring(with: m.range(at: 1))
      let phoneme = ns.substring(with: m.range(at: 2))
      
      let tokenStartIndex = result.endIndex
      result += grapheme
      let tokenRange = tokenStartIndex..<result.endIndex

      if let intValue = Int(phoneme) {
        features.append(PreprocessFeature(value: .int(intValue), tokenRange: tokenRange))
      } else if ["0.5", "+0.5"].contains(phoneme) {
        features.append(PreprocessFeature(value: .double(0.5), tokenRange: tokenRange))
      } else if phoneme == "-0.5" {
        features.append(PreprocessFeature(value: .double(-0.5), tokenRange: tokenRange))
      } else if phoneme.count > 1 && phoneme.first == "/" && phoneme.last == "/" {
        features.append(PreprocessFeature(value: .string(String(phoneme.dropLast())), tokenRange: tokenRange))
      } else if phoneme.count > 1 && phoneme.first == "#" && phoneme.last == "#" {
        features.append(PreprocessFeature(value: .string(String(phoneme.dropLast())), tokenRange: tokenRange))
      }

      tokens.append(grapheme)
      lastEnd = end
    }
    
    if lastEnd < input.endIndex {
      result += String(input[lastEnd...])
      tokens.append(contentsOf: String(input[lastEnd...]).split(separator: " ").map(String.init))
    }
    
    return (text: result, tokens: tokens, features: features)
  }
    
  private func tokenize(preprocessedText: PreprocessTuple) -> [MToken] {
    var mutableTokens: [MToken] = []
    
    // Tokenize and perform part-of-speech tagging
    tagger.string = preprocessedText.text
    tagger.setLanguage(.english, range: preprocessedText.text.startIndex..<preprocessedText.text.endIndex)
    let options: NLTagger.Options = []
    tagger.enumerateTags(
      in: preprocessedText.text.startIndex..<preprocessedText.text.endIndex,
      unit: .word,
      scheme: .lexicalClass,
      options: options) { tag, tokenRange in
      if let tag = tag {
        let word = String(preprocessedText.text[tokenRange])
        if tag == .whitespace, let lastToken = mutableTokens.last {
          lastToken.whitespace = word
        } else {
          mutableTokens.append(MToken(text: word, tokenRange: tokenRange, tag: tag, whitespace: ""))
        }
      }
        
      return true
    }
                            
    // Simplistic alignment by index to add stress and pre-phonemization features to tokens
    // TO_DO: Doesn't match the capability of spacy.training.Alignment.from_strings()
    for feature in preprocessedText.features {
      for token in mutableTokens {
        if token.tokenRange.contains(feature.tokenRange) || feature.tokenRange.contains(token.tokenRange) {
          switch feature.value {
            case .int(let int):
              token.`_`.stress = Double(int)
            case .double(let double):
              token.`_`.stress = double
            case .string(let string):
              if string.hasPrefix("/") {
                token.`_`.is_head = true
                token.phonemes = String(string.dropFirst())
                token.`_`.rating = 5
              } else if string.hasPrefix("#") {
                token.`_`.num_flags = String(string.dropFirst())
              }
          }
        }
      }
    }

    return mutableTokens
  }

  // Turns the text into phonemes that can then be fed to text-to-speech (TTS) engine for converting to audio
  public func phonemize(text: String, performPreprocess: Bool = true) -> (String, [MToken]) {
    let pre: PreprocessTuple
    if performPreprocess {
        pre = self.preprocess(text: text)
    } else {
        pre = (text: text, tokens: [], features: [])
    }

    let tokens = tokenize(preprocessedText: pre)
        
        /*var tokens = tokenize(pre.0, pre.1, pre.2)
        tokens = foldLeft(tokens)
        var words = G2P.retokenize(tokens)
        var ctx = TokenContext()
        for i in stride(from: words.count - 1, through: 0, by: -1) {
            if var w = words[i] as? MToken {
                if w.phonemes == nil {
                    let out = lexicon.transcribe(w, ctx: ctx)
                    w.phonemes = out.0
                    w.`_`.rating = out.1
                }
                if w.phonemes == nil, let fb = fallback {
                    let out = fb.call(w)
                    w.phonemes = out.0
                    w.`_`.rating = out.1
                }
                ctx = G2P.tokenContext(ctx, ps: w.phonemes, token: w)
                words[i] = w
            } else if var arr = words[i] as? [MToken] {
                var left = 0
                var right = arr.count
                var shouldFallback = false
                while left < right {
                    let hasFixed = arr[left..<right].contains { $0.`_`.alias != nil || $0.phonemes != nil }
                    let tk: MToken? = hasFixed ? nil : mergeTokens(Array(arr[left..<right]), unk: self.unk)
                    let res: (String?, Int?) = (tk == nil) ? (nil, nil) : lexicon.transcribe(tk!, ctx: ctx)
                    if let ps = res.0 {
                        arr[left].phonemes = ps
                        arr[left].`_`.rating = res.1
                        if left + 1 < right {
                            for j in (left + 1)..<right {
                                arr[j].phonemes = ""
                                arr[j].`_`.rating = res.1
                            }
                        }
                        ctx = G2P.tokenContext(ctx, ps: ps, token: tk!)
                        right = left
                        left = 0
                    } else if left + 1 < right {
                        left += 1
                    } else {
                        right -= 1
                        var last = arr[right]
                        if last.phonemes == nil {
                            if last.text.allSatisfy({ SUBTOKEN_JUNKS.contains($0) }) {
                                last.phonemes = ""
                                last.`_`.rating = 3
                            } else if fallback != nil {
                                shouldFallback = true
                                break
                            }
                        }
                        left = 0
                        arr[right] = last
                    }
                }
                if shouldFallback {
                    let tk = mergeTokens(arr, unk: self.unk)
                    var first = arr[0]
                    let out = fallback!.call(tk)
                    first.phonemes = out.0
                    first.`_`.rating = out.1
                    arr[0] = first
                    if arr.count > 1 {
                        for j in 1..<arr.count { arr[j].phonemes = ""; arr[j].`_`.rating = out.1 }
                    }
                } else {
                    G2P.resolveTokens(&arr)
                }
                words[i] = arr
            }
        }
        var finalTokens: [MToken] = words.map { item in
            if let arr = item as? [MToken] { return mergeTokens(arr, unk: self.unk) }
            return item as! MToken
        }
        if version != "2.0" {
            for i in 0..<finalTokens.count {
                if var ps = finalTokens[i].phonemes, !ps.isEmpty {
                    ps = ps.replacingOccurrences(of: "ɾ", with: "T").replacingOccurrences(of: "ʔ", with: "t")
                    finalTokens[i].phonemes = ps
                }
            }
        }
        let result = finalTokens.map { ( $0.phonemes ?? self.unk ) + $0.whitespace }.joined()
        return (result, finalTokens) */
    return ("", [])
  }
}
