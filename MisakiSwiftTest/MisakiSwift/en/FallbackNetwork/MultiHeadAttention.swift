import Foundation
import MLX
import MLXNN

nonisolated class MultiHeadAttention: Module {
    let numHeads: Int
    let dModel: Int
    let headDim: Int
    
    let qProj: Linear
    let kProj: Linear
    let vProj: Linear
    let outProj: Linear
    
    init(dModel: Int, numHeads: Int) {
        self.dModel = dModel
        self.numHeads = numHeads
        self.headDim = dModel / numHeads
        
        self.qProj = Linear(dModel, dModel)
        self.kProj = Linear(dModel, dModel)
        self.vProj = Linear(dModel, dModel)
        self.outProj = Linear(dModel, dModel)
        
        super.init()
    }
    
    func callAsFunction(_ query: MLXArray, key: MLXArray? = nil, value: MLXArray? = nil, mask: MLXArray? = nil) -> MLXArray {
        let key = key ?? query
        let value = value ?? query
        
        let batchSize = query.shape[0]
        let seqLen = query.shape[1]
        
        // Project and reshape
        let q = qProj(query).reshaped([batchSize, seqLen, numHeads, headDim]).transposed(1, 2)
        let k = kProj(key).reshaped([batchSize, -1, numHeads, headDim]).transposed(1, 2)
        let v = vProj(value).reshaped([batchSize, -1, numHeads, headDim]).transposed(1, 2)
        
        // Scaled dot-product attention
        let scale = Float(1.0 / sqrt(Double(headDim)))
        var scores = matmul(q, k.transposed(2, 3)) * scale
        
        if let mask = mask {
            scores = scores + mask
        }
        
        let attnWeights = softmax(scores, axis: -1)
        let attnOutput = matmul(attnWeights, v)
        
        // Reshape and project
        let output = attnOutput.transposed(1, 2).reshaped([batchSize, seqLen, dModel])
        return outProj(output)
    }
}
