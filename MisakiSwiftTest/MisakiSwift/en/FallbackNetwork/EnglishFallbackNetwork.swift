import Foundation

class EnglishFallbackNetwork {
  private let configuration: BARTConfig?
  private let british: Bool
    
  init(british: Bool) {
    do {
      configuration = try EnglishFallbackNetwork.loadConfig(british: british)!
    } catch(let ex) {
      configuration = nil
      print("Exception \(ex.localizedDescription)")
    }
    self.british = british
  }
  
  func callAsFunction(_ word: MToken) -> (phoneme: String, rating: Int) {
    return ("[Dunno]", 4)
  }
  
  private static func loadConfig(british: Bool) throws -> BARTConfig? {
    let filename = "\(british ? "gb" : "us")_bart_config"
    guard let url = Bundle(for: EnglishFallbackNetwork.self).url(forResource: filename, withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
        return nil
    }
    
    let config = try JSONDecoder().decode(BARTConfig.self, from: data)
    return config
  }
}
