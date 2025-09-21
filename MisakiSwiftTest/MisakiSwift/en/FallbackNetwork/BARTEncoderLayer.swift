import Foundation
import MLX
import MLXNN

nonisolated class BARTEncoderLayer: Module {
    let selfAttn: MultiHeadAttention
    let selfAttnNorm: LayerNorm
    let ffn: FeedForward
    let ffnNorm: LayerNorm
    let dropout: Dropout
    
    init(dModel: Int, numHeads: Int, dFF: Int, dropoutRate: Float = 0.1) {
        self.selfAttn = MultiHeadAttention(dModel: dModel, numHeads: numHeads)
        self.selfAttnNorm = LayerNorm(dimensions: dModel)
        self.ffn = FeedForward(dModel: dModel, dFF: dFF, dropoutRate: dropoutRate)
        self.ffnNorm = LayerNorm(dimensions: dModel)
        self.dropout = Dropout(p: dropoutRate)
        super.init()
    }
    
    func callAsFunction(_ x: MLXArray, mask: MLXArray? = nil) -> MLXArray {
        // Self-attention with residual
        var attnOutput = selfAttn(x, mask: mask)
        attnOutput = dropout(attnOutput)
        var output = selfAttnNorm(x + attnOutput)
        
        // Feed-forward with residual
        let ffnOutput = ffn(output)
        output = ffnNorm(output + dropout(ffnOutput))
        
        return output
    }
}
