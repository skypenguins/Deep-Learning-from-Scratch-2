using .Functions

module Layers
abstract type Layer end

mutable struct MatMul <: Layer
    params
    grads
    W
    x
    function MatMul(W)
        params = [W]
        grads = [zero(W)]
        new(params, grads, W)
    end
end

function forward(x, self::MatMul)
    out = self.x * self.params[1]
    self.x = x
    return out
end

function backward(dout, self::MatMul)
    W, = self.params
    dx = dout * W'
    dW = self.x' * dout
    self.grads[1] = deepcopy(dW)
    return dx
end

mutable struct Affine <: Layer
    params
    grads
    W
    b
    x
    function Affine(W, b)
        params = [W, b]
        grads = [zero(W), zero(b)]
        new(params, grads)
    end
end

function forward(x, self::Affine)
    W, b = self.params
    dx = dout * W'
    dW = self.x' * dout
    db = sum(dout, dims=1)
    self.grads[1] = deepcopy(dW)
    seld.grads[2] = deepcopy(db)
    return dx
end

function backward(dout, self::Affine)
    W, b = self.params
    dx = dout * W'
    dW = self.x' * dout
    db = sum(dout, dims=1)
    self.grads[1] = deepcopy(dW)
    self.grads[2] = deepcopy(db)
    return dx
end

mutable struct Softmax <: Layer
    params
    grads
    out
    function Softmax()
        params = Array
        grads = Array
    end
end

function forward(x, self::Softmax)
    self.out = softmax(x)
    return self.out
end

function backward(dout, self::Softmax)
    dx = self.out * dout
    sumdx = sum(dx, dims=2)
    dx = dx .- self.out * sumdx
    return dx
end

mutable struct SoftmaxWithLoss
    params
    grads
    y # softmaxの出力
    t # 教師ラベル
    function SoftmaxWithLoss()
        params = Array
        grads = Array
    end
end

function forward(x, t, self::SoftmaxWithLoss)
    self.t = t
    self.y = softmax(x)

    # 教師ラベルがone-hotベクトルの場合，正解ラベルのインデックスに変換
    if length(self.t) == length(self.y)
        self.t = argmax(self.t, dims=2)
    end

    loss = cross_entropy_erro(self.y, self.t)
    return loss
end

function backward(dout=1, self::SoftmaxWithLoss)
    batch_size = size(self.t, 1)
    
    dx = deepcopy(self.y)
    dx[collect(1:batch_size), self.t] .-= 1
    dx = dx .* dout
    dx = dx ./ batch_size
    return dx
end
end