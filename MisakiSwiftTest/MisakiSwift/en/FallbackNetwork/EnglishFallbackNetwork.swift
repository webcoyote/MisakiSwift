import Foundation
import MLX

class EnglishFallbackNetwork {
  private let configuration: BARTConfig?
  private let modelWeights: [String: MLXArray]
  
  private let british: Bool
    
  init(british: Bool) {
    configuration = EnglishFallbackNetwork.loadConfig(british: british)!
    modelWeights = EnglishFallbackNetwork.loadWeights(british: british)!
    
    self.british = british
  }
  
  func callAsFunction(_ word: MToken) -> (phoneme: String, rating: Int) {
    return ("[Dunno]", 4)
  }
  
  private static func loadConfig(british: Bool) -> BARTConfig? {
    let fileName = "\(british ? "gb" : "us")_bart_config"
    guard let url = Bundle(for: EnglishFallbackNetwork.self).url(forResource: fileName, withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let config = try? JSONDecoder().decode(BARTConfig.self, from: data) else {
        return nil
    }
    return config
  }
  
  private static func loadWeights(british: Bool) -> [String: MLXArray]? {
    let fileName = "\(british ? "gb" : "us")_bart"
    let filePath = Bundle(for: EnglishFallbackNetwork.self).path(forResource: fileName, ofType: "safetensors")!
    guard let weights = try? MLX.loadArrays(url: URL(fileURLWithPath: filePath)) else {
      return nil
    }
    
    return weights
  }
}
