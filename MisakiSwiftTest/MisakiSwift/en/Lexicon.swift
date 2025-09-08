import Foundation

// Lexicon
final class Lexicon {
    let british: Bool
    let cap_stresses: (Double, Double) = (0.5, 2.0)

    // gold and silver dictionaries
    let golds: [String: String]
    let silvers: [String: String]

    init(british: Bool) {
        self.british = british
        // Placeholder resource loading
        self.golds = DataResourcesUtil.loadGold(british: british)
        self.silvers = DataResourcesUtil.loadSilver(british: british)
    }
    /*
    private func getNNP(_ word: String) -> (String?, Int?) {
        let pieces: [String?] = word.compactMap { ch in
            let s = String(ch).uppercased()
            if let v = golds[s] as? String { return v } else { return nil }
        }
        if pieces.contains(where: { $0 == nil }) { return (nil, nil) }
        let joined = applyStress(pieces.joined(), stress: 0)
        if let joined = joined {
            let parts = joined.split(separator: SECONDARY_STRESS)
            let ps = parts.joined(separator: String(PRIMARY_STRESS))
            return (ps, 3)
        }
        return (nil, nil)
    }

    private func getSpecialCase(_ word: String, tag: String?, stress: Double?, ctx: TokenContext) -> (String?, Int?) {
        if tag == "ADD", let target = ADD_SYMBOLS[word] {
            return lookup(target, tag: nil, stress: -0.5, ctx: ctx)
        } else if let sym = SYMBOLS[word] {
            return lookup(sym, tag: nil, stress: nil, ctx: ctx)
        } else if word.trimmingCharacters(in: CharacterSet(charactersIn: ".")).contains(".") {
            let parts = word.split(separator: ".")
            if parts.map({ $0.count }).max() ?? 0 < 3 {
                return getNNP(word)
            }
        } else if word == "a" || word == "A" {
            if tag == "DT" { return ("ɐ", 4) }
            return ("ˈA", 4)
        } else if ["am", "Am", "AM"].contains(word) {
            if let t = tag, t.hasPrefix("NN") { return getNNP(word) }
            if ctx.future_vowel == nil || word != "am" || (stress != nil && stress! > 0) {
                if let v = golds["am"] as? String { return (v, 4) }
            }
            return ("ɐm", 4)
        } else if ["an", "An", "AN"].contains(word) {
            if word == "AN", let t = tag, t.hasPrefix("NN") { return getNNP(word) }
            return ("ɐn", 4)
        } else if word == "I", tag == "PRP" {
            return (String(SECONDARY_STRESS) + "I", 4)
        } else if ["by", "By", "BY"].contains(word), Lexicon.getParentTag(tag) == "ADV" {
            return ("bˈI", 4)
        } else if ["to", "To"].contains(word) || (word == "TO" && (tag == "TO" || tag == "IN")) {
            let chosen: String
            if ctx.future_vowel == nil { chosen = (golds["to"] as? String) ?? "to" }
            else if ctx.future_vowel == false { chosen = "tə" }
            else { chosen = "tʊ" }
            return (chosen, 4)
        } else if ["in", "In"].contains(word) || (word == "IN" && tag != "NNP") {
            let s = (ctx.future_vowel == nil || tag != "IN") ? String(PRIMARY_STRESS) : ""
            return (s + "ɪn", 4)
        } else if ["the", "The"].contains(word) || (word == "THE" && tag == "DT") {
            return (ctx.future_vowel == true ? "ði" : "ðə", 4)
        } else if tag == "IN", word.range(of: "(?i)vs\\.?$", options: .regularExpression) != nil {
            return lookup("versus", tag: nil, stress: nil, ctx: ctx)
        } else if ["used", "Used", "USED"].contains(word) {
            if (tag == "VBD" || tag == "JJ") && ctx.future_to {
                if let m = golds["used"] as? [String: String?], let v = m["VBD"] as? String { return (v, 4) }
            }
            if let m = golds["used"] as? [String: String?], let v = m["DEFAULT"] as? String { return (v, 4) }
        }
        return (nil, nil)
    }

    public static func getParentTag(_ tag: String?) -> String? {
        guard let tag = tag else { return tag }
        if tag.hasPrefix("VB") { return "VERB" }
        if tag.hasPrefix("NN") { return "NOUN" }
        if tag.hasPrefix("ADV") || tag.hasPrefix("RB") { return "ADV" }
        if tag.hasPrefix("ADJ") || tag.hasPrefix("JJ") { return "ADJ" }
        return tag
    }

    private func isKnown(_ word: String, tag: String?) -> Bool {
        if golds[word] != nil || SYMBOLS[word] != nil || silvers[word] != nil { return true }
        if !word.allSatisfy({ ch in
            if let v = ch.unicodeScalars.first?.value { return LEXICON_ORDS.contains(Int(v)) }
            return false
        }) { return false }
        if word.count == 1 { return true }
        if word == word.uppercased(), golds[word.lowercased()] != nil { return true }
        let idx = word.index(after: word.startIndex)
        return word[idx...].uppercased() == word[idx...]
    }

    private func lookup(_ w: String, tag: String?, stress: Double?, ctx: TokenContext?) -> (String?, Int?) {
        var word = w
        var isNNP: Bool? = nil
        if word == word.uppercased(), golds[word] == nil {
            word = word.lowercased()
            isNNP = (tag == "NNP")
        }
        var ps: Any? = golds[word]
        var rating = 4
        if ps == nil, isNNP != true { ps = silvers[word]; rating = 3 }
        if let dict = ps as? [String: String?] {
            var t = tag
            if let ctx = ctx, ctx.future_vowel == nil, dict["None"] != nil { t = "None" }
            else if dict[t ?? ""] == nil { t = Lexicon.getParentTag(t) }
            ps = dict[t ?? "DEFAULT"] ?? dict["DEFAULT"] ?? nil
        }
        if ps == nil || (isNNP == true && !(ps as? String ?? "").contains(PRIMARY_STRESS)) {
            let nn = getNNP(word)
            if nn.0 != nil { return nn }
        }
        let applied = applyStress(ps as? String, stress: stress)
        return (applied, rating)
    }

    private func pluralizeS(_ stem: String?) -> String? {
        guard let stem = stem, !stem.isEmpty else { return nil }
        if let last = stem.last, "ptkfθ".contains(last) { return stem + "s" }
        if let last = stem.last, "szʃʒʧʤ".contains(last) { return stem + (british ? "ɪ" : "ᵻ") + "z" }
        return stem + "z"
    }

    private func stem_s(_ word: String, tag: String?, stress: Double?, ctx: TokenContext?) -> (String?, Int?) {
        guard word.count >= 3, word.hasSuffix("s") else { return (nil, nil) }
        var stem: String?
        if !word.hasSuffix("ss"), isKnown(String(word.dropLast()), tag: tag) { stem = String(word.dropLast()) }
        else if (word.hasSuffix("'s") || (word.count > 4 && word.hasSuffix("es") && !word.hasSuffix("ies"))), isKnown(String(word.dropLast(2)), tag: tag) { stem = String(word.dropLast(2)) }
        else if word.count > 4 && word.hasSuffix("ies"), isKnown(String(word.dropLast(3)) + "y", tag: tag) { stem = String(word.dropLast(3)) + "y" }
        guard let s = stem else { return (nil, nil) }
        let looked = lookup(s, tag: tag, stress: stress, ctx: ctx)
        return (pluralizeS(looked.0), looked.1)
    }

    private func pastEd(_ stem: String?) -> String? {
        guard let stem = stem, !stem.isEmpty else { return nil }
        if let last = stem.last, "pkfθʃsʧ".contains(last) { return stem + "t" }
        if stem.hasSuffix("d") { return stem + (british ? "ɪ" : "ᵻ") + "d" }
        if !stem.hasSuffix("t") { return stem + "d" }
        if british || stem.count < 2 { return stem + "ɪd" }
        if let penult = stem.dropLast().last, US_TAUS.contains(penult) { return String(stem.dropLast()) + "ɾᵻd" }
        return stem + "ᵻd"
    }

    private func stem_ed(_ word: String, tag: String?, stress: Double?, ctx: TokenContext?) -> (String?, Int?) {
        guard word.count >= 4, word.hasSuffix("d") else { return (nil, nil) }
        var stem: String?
        if !word.hasSuffix("dd"), isKnown(String(word.dropLast()), tag: tag) { stem = String(word.dropLast()) }
        else if word.count > 4 && word.hasSuffix("ed") && !word.hasSuffix("eed"), isKnown(String(word.dropLast(2)), tag: tag) { stem = String(word.dropLast(2)) }
        guard let s = stem else { return (nil, nil) }
        let looked = lookup(s, tag: tag, stress: stress, ctx: ctx)
        return (pastEd(looked.0), looked.1)
    }

    private func progIng(_ stem: String?) -> String? {
        guard let stem = stem, !stem.isEmpty else { return nil }
        if british {
            if let last = stem.last, "əː".contains(last) { return nil }
        } else {
            if stem.count > 1, stem.hasSuffix("t"), let penult = stem.dropLast().last, US_TAUS.contains(penult) {
                return String(stem.dropLast()) + "ɾɪŋ"
            }
        }
        return stem + "ɪŋ"
    }

    private func stem_ing(_ word: String, tag: String?, stress: Double?, ctx: TokenContext?) -> (String?, Int?) {
        guard word.count >= 5, word.hasSuffix("ing") else { return (nil, nil) }
        var stem: String?
        if word.count > 5, isKnown(String(word.dropLast(3)), tag: tag) { stem = String(word.dropLast(3)) }
        else if isKnown(String(word.dropLast(3)) + "e", tag: tag) { stem = String(word.dropLast(3)) + "e" }
        else if word.count > 5, word.range(of: #"([bcdgklmnprstvxz])\1ing$|cking$"#, options: .regularExpression) != nil, isKnown(String(word.dropLast(4)), tag: tag) {
            stem = String(word.dropLast(4))
        }
        guard let s = stem else { return (nil, nil) }
        let looked = lookup(s, tag: tag, stress: stress, ctx: ctx)
        return (progIng(looked.0), looked.1)
    }

    private func getWord(_ word: String, tag: String?, stress: Double?, ctx: TokenContext) -> (String?, Int?) {
        let sc = getSpecialCase(word, tag: tag, stress: stress, ctx: ctx)
        if sc.0 != nil { return sc }
        var candidate = word
        let wl = word.lowercased()
        if word.count > 1,
           word.replacingOccurrences(of: "'", with: "").allSatisfy({ isAsciiLetter($0) }),
           word != word.lowercased(),
           (tag != "NNP" || word.count > 7),
           golds[word] == nil, silvers[word] == nil,
           (word == word.uppercased() || word.dropFirst().lowercased() == word.dropFirst()),
           (golds[wl] != nil || silvers[wl] != nil || [stem_s, stem_ed, stem_ing].contains(where: { fn in fn(wl, tag, stress, ctx).0 != nil })) {
            candidate = wl
        }
        if isKnown(candidate, tag: tag) { return lookup(candidate, tag: tag, stress: stress, ctx: ctx) }
        else if candidate.hasSuffix("s'"), isKnown(String(candidate.dropLast(2)) + "'s", tag: tag) { return lookup(String(candidate.dropLast(2)) + "'s", tag: tag, stress: stress, ctx: ctx) }
        else if candidate.hasSuffix("'"), isKnown(String(candidate.dropLast()), tag: tag) { return lookup(String(candidate.dropLast()), tag: tag, stress: stress, ctx: ctx) }
        let s = stem_s(candidate, tag: tag, stress: stress, ctx: ctx); if s.0 != nil { return s }
        let e = stem_ed(candidate, tag: tag, stress: stress, ctx: ctx); if e.0 != nil { return e }
        let ing = stem_ing(candidate, tag: tag, stress: (stress == nil ? 0.5 : stress), ctx: ctx); if ing.0 != nil { return ing }
        return (nil, nil)
    }

    private static func isCurrency(_ word: String) -> Bool {
        if !word.contains(".") { return true }
        if word.filter({ $0 == "." }).count > 1 { return false }
        if let cents = word.split(separator: ".").last { return cents.count < 3 || Set(cents) == Set(["0"]) }
        return false
    }

    private func getNumber(_ input: String, currency: String?, is_head: Bool, num_flags: String) -> (String?, Int?) {
        var word = input
        var suffix: String? = nil
        if let m = word.range(of: "[a-z']+$", options: .regularExpression) {
            suffix = String(word[m])
            word.removeSubrange(m)
        }
        var result: [(String, Int)] = []
        func appendLookup(_ w: String, s: Double?) {
            let looked = lookup(w, tag: nil, stress: s, ctx: nil)
            if let p = looked.0, let r = looked.1 { result.append((p, r)) }
        }
        if word.hasPrefix("-") {
            appendLookup("minus", s: nil)
            word.removeFirst()
        }
        func extend_num(_ num: String, first: Bool = true, escape: Bool = false) {
            let splits: [String]
            if escape { splits = num.split(whereSeparator: { !$0.isLetter }).map(String.init) }
            else { if let val = Int(num) { splits = num2words(val, to: nil).split(separator: " ").map(String.init) } else { splits = [num] } }
            for (i, w) in splits.enumerated() {
                if w != "and" || num_flags.contains("&") {
                    if first && i == 0 && splits.count > 1 && w == "one" && num_flags.contains("a") {
                        result.append(("ə", 4))
                    } else {
                        let s = (w == "point") ? -2.0 : nil
                        appendLookup(w, s: s)
                    }
                } else if w == "and" && num_flags.contains("n") && !result.isEmpty {
                    let last = result.removeLast()
                    result.append((last.0 + "ən", last.1))
                }
            }
        }
        if isPlainDigits(word), let sf = suffix, ORDINALS.contains(sf) {
            if let n = Int(word) { extend_num(num2words(n, to: "ordinal"), escape: true) }
        } else if result.isEmpty, word.count == 4, currency == nil, isPlainDigits(word) {
            if let n = Int(word) { extend_num(num2words(n, to: "year"), escape: true) }
        } else if !is_head && !word.contains(".") {
            let num = word.replacingOccurrences(of: ",", with: "")
            if num.first == "0" || num.count > 3 {
                for n in num { extend_num(String(n), first: false) }
            } else if num.count == 3 && !num.hasSuffix("00") {
                extend_num(String(num.first!))
                if num[num.index(num.startIndex, offsetBy: 1)] == "0" {
                    result.append(lookup("O", tag: nil, stress: -2, ctx: nil) as! (String, Int))
                    extend_num(String(num.last!), first: false)
                } else {
                    extend_num(String(num.suffix(2)), first: false)
                }
            } else {
                extend_num(num)
            }
        } else if word.filter({ $0 == "." }).count > 1 || !is_head {
            var first = true
            for num in word.replacingOccurrences(of: ",", with: "").split(separator: ".").map(String.init) {
                if num.isEmpty { }
                else if num.first == "0" || (num.count != 2 && num.dropFirst().contains(where: { $0 != "0" })) {
                    for n in num { extend_num(String(n), first: false) }
                } else {
                    extend_num(num, first: first)
                }
                first = false
            }
        } else if let curr = currency, CURRENCIES[curr] != nil, Lexicon.isCurrency(word) {
            var pairs: [(Int, String)] = []
            let units = CURRENCIES[curr]!
            let parts = word.replacingOccurrences(of: ",", with: "").split(separator: ".")
            let a = parts.indices.contains(0) ? Int(parts[0]) ?? 0 : 0
            let b = parts.indices.contains(1) ? Int(parts[1]) ?? 0 : 0
            pairs = [(a, units.0), (b, units.1)].filter { _ in true }
            if pairs.count > 1 {
                if pairs[1].0 == 0 { pairs = Array(pairs.prefix(1)) }
                else if pairs[0].0 == 0 { pairs = Array(pairs.suffix(1)) }
            }
            for (i, (num, unit)) in pairs.enumerated() {
                if i > 0 { appendLookup("and", s: nil) }
                extend_num(String(num), first: i == 0)
                if abs(num) != 1 && unit != "pence" {
                    if let s = stem_s(unit + "s", tag: nil, stress: nil, ctx: nil).0 { result.append((s, 4)) }
                } else {
                    appendLookup(unit, s: nil)
                }
            }
        } else {
            if isPlainDigits(word) {
                if let n = Int(word) { word = num2words(n, to: "cardinal") }
            } else if !word.contains(".") {
                let num = word.replacingOccurrences(of: ",", with: "")
                if let n = Int(num) { word = num2words(n, to: (suffix != nil && ORDINALS.contains(suffix!) ? "ordinal" : "cardinal")) }
            } else {
                let num = word.replacingOccurrences(of: ",", with: "")
                if num.first == "." {
                    let tail = num.dropFirst().compactMap { Int(String($0)) }.map { num2words($0, to: nil) }.joined(separator: " ")
                    word = "point " + tail
                } else {
                    if let d = Double(num) { word = num2words(d) }
                }
            }
            extend_num(word, escape: true)
        }
        if result.isEmpty { return (nil, nil) }
        var text = result.map { $0.0 }.joined(separator: " ")
        let rating = result.map { $0.1 }.min() ?? 4
        if let s = suffix, s == "s" || s == "'s" { text = pluralizeS(text) ?? text }
        else if let s = suffix, s == "ed" || s == "'d" { text = pastEd(text) ?? text }
        else if suffix == "ing" { text = progIng(text) ?? text }
        return (text, rating)
    }

    private func appendCurrency(_ ps: String?, currency: String?) -> String? {
        guard let ps = ps else { return nil }
        guard let currency = currency else { return ps }
        if let pair = CURRENCIES[currency] {
            if let plural = stem_s(pair.0 + "s", tag: nil, stress: nil, ctx: nil).0 {
                return ps + " " + plural
            }
        }
        return ps
    }

    public func transcribe(_ tk: MToken, ctx: TokenContext) -> (String?, Int?) {
        var word = (tk.text)
        if let alias = tk.`_`.alias { word = alias }
        word = word.replacingOccurrences(of: String(UnicodeScalar(8216)!), with: "'")
            .replacingOccurrences(of: String(UnicodeScalar(8217)!), with: "'")
        word = word.precomposedStringWithCompatibilityMapping()
        word = String(word.map { Character(unicodeNumericIfNeeded($0)) })
        let stress: Double? = (word == word.lowercased() ? nil : (word == word.uppercased() ? cap_stresses.1 : cap_stresses.0))
        var res = getWord(word, tag: tk.tag, stress: stress, ctx: ctx)
        if let ps = res.0 {
            return (applyStress(appendCurrency(ps, currency: tk.`_`.currency), stress: tk.`_`.stress), res.1)
        } else if Lexicon.isNumber(word: word, is_head: tk.`_`.is_head) {
            let num = getNumber(word, currency: tk.`_`.currency, is_head: tk.`_`.is_head, num_flags: tk.`_`.num_flags)
            return (applyStress(num.0, stress: tk.`_`.stress), num.1)
        } else if !word.unicodeScalars.allSatisfy({ LEXICON_ORDS.contains(Int($0.value)) }) {
            return (nil, nil)
        }
        return (nil, nil)
    }

    private static func isNumber(word: String, is_head: Bool) -> Bool {
        if word.allSatisfy({ !String($0).range(of: "^[0-9]$", options: .regularExpression, range: nil, locale: nil).map { _ in true }! }) { return false }
        let suffixes: [String] = ["ing", "'d", "ed", "'s"] + Array(ORDINALS) + ["s"]
        var core = word
        for s in suffixes {
            if core.hasSuffix(s) { core = String(core.dropLast(s.count)); break }
        }
        return core.enumerated().allSatisfy { (i, c) in
            return String(c).range(of: "^[0-9]$", options: .regularExpression) != nil || c == "," || c == "." || (is_head && i == 0 && c == "-")
        }
    }
    */
}
