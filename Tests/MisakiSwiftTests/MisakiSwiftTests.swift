import Testing
@testable import MisakiSwift

@Test func test_exampleString_British() async throws {
  let englishG2P = EnglishG2P(british: true)
  
  let text = "[Misaki](/misˈɑki/) is a G2P engine designed for [Kokoro](/kˈOkəɹO/) models."
  let expectedOutput = "misˈɑki ɪz ɐ ʤˈiːtəpˈiː ˈɛnʤɪn dɪzˈInd fɔː kˈOkəɹO mˈɒdᵊlz."
    
  #expect(englishG2P.phonemize(text: text).0 == expectedOutput)
}

@Test func test_exampleString_American() async throws {
  let englishG2P = EnglishG2P(british: false)
  
  let text = "[Misaki](/misˈɑki/) is a G2P engine designed for [Kokoro](/kˈOkəɹO/) models."
  let expectedOutput = "misˈɑki ɪz ɐ ʤˈitəpˈi ˈɛnʤən dəzˈInd fɔɹ kˈOkəɹO mˈɑdᵊlz."
    
  #expect(englishG2P.phonemize(text: text).0 == expectedOutput)
}
