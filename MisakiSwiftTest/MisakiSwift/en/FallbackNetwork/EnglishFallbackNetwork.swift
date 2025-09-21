class EnglishFallbackNetwork {
  private let british: Bool
    
  init(british: Bool) {
    self.british = british
  }
  
  func callAsFunction(_ word: MToken) -> (phoneme: String, rating: Int) {
    return ("[Dunno]", 4)
  }
}
