import Foundation
import MLX
import MLXNN

nonisolated class FeedForward: Module {
    let linear1: Linear
    let linear2: Linear
    let dropout: Dropout
    
    init(dModel: Int, dFF: Int, dropoutRate: Float = 0.1) {
        self.linear1 = Linear(dModel, dFF)
        self.linear2 = Linear(dFF, dModel)
        self.dropout = Dropout(p: dropoutRate)
        super.init()
    }
    
    func callAsFunction(_ x: MLXArray) -> MLXArray {
        var output = linear1(x)
        output = gelu(output)
        output = dropout(output)
        output = linear2(output)
        return output
    }
}
