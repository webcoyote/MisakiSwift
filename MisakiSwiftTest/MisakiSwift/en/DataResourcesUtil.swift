import Foundation

final class DataResourcesUtil {

    private init() {}
    
    static func loadGold(british: Bool) -> [String: Any] {
        let filename = british ? "gb_gold" : "us_gold"
        
        guard let url = Bundle(for: DataResourcesUtil.self).url(forResource: filename, withExtension: "json") else {
            return [:]
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return [:]
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return [:]
        }
        
        return json
    }
    
    static func loadSilver(british: Bool) -> [String: Any] {
      let filename = british ? "gb_silver" : "us_silver"
      
      guard let url = Bundle(for: DataResourcesUtil.self).url(forResource: filename, withExtension: "json") else {
          return [:]
      }
      
      guard let data = try? Data(contentsOf: url) else {
          return [:]
      }
      
      guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
          return [:]
      }
      
      return json
    }
}
