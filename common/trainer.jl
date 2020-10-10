abstract type AbstractTrainer end

mutable struct Trainer <: AbstractTrainer
    model
    optimizer
    loss_list
    eval_interval
    current_epoch
    function Trainer(model, optimizer)
        self = new()
        self.model = model
        self.optimizer = optimizer
        self.loss_list = []
        self.eval_interval = nothing
        self.current_epoch = 0
        return self
    end
end

function fit!(trainer::Trainer, x, t; max_epoch=10, batch_size=32, max_grad=nothing, eval_interval=20)
    data_size = size(x, 1)
    max_iters = data_size ÷ batch_size
    trainer.eval_interval = eval_interval

    @time train!(trainer, data_size, batch_size, max_epoch, max_iters, x, t)
end

function train!(trainer::Trainer, data_size, batch_size, max_epoch, max_iters, train_x, train_t)
    total_loss = 0
    loss_count = 0
    
    for epoch = 1:max_epoch
        # シャッフルしたミニバッチの生成
        indices = rand(1:data_size, batch_size) # 1～data_sizeの範囲の一意な数値を要素に持つ要素数data_sizeのVectorを返す
        batch_x = train_x[indices, :]
        batch_t = train_t[indices, :]
        
        for iter = 1:max_iters
            total_loss, loss_count = iteration!(trainer, iter, max_iters, total_loss, loss_count, batch_x, batch_t)
        end

        trainer.current_epoch += 1
    end
end

function iteration!(trainer::Trainer, iter, max_iters, total_loss, loss_count, batch_x, batch_t)
    # 損失を計算
    loss = forward!(trainer.model, batch_x, batch_t) # BaseModel(TwoLayersNet)内に定義
    # 勾配を求める
    backward!(trainer.model) # BaseModel(TwoLayersNet)内に定義
    # パラメータを更新
    update!(trainer.optimizer, trainer.model.params, trainer.model.grads) # Optimizer内に定義
    # 損失履歴を追加
    push!(trainer.loss_list, loss)
    total_loss += loss
    loss_count += 1
    # 定期的に学習経過を出力
    if iter % trainer.eval_interval == 0
        avg_loss = total_loss / loss_count
        println("| epoch $(trainer.current_epoch) | iter $(iter) / $(max_iters) | loss $(round(avg_loss, digits=2))")
        push!(trainer.loss_list, avg_loss)
        total_loss, loss_count = 0, 0
    end
    return total_loss, loss_count
end

function remove_duplicate(params, grads)
    #= パラメータ配列の重複する重みを一つに集約し，
    その重みに対応する勾配を加算する =#
    _params, _grads = params[:, :], grads[:, :]

    while true
        find_fig = false
        L = length(_params)

        for i = 1:L
            for j = (i + 1):(L + 1)
                # 重みを共有する場合
                if _params[i, :] == _params[j, :]
                    grads[i, :] .+= grads[j, :]
                    find_fig = true
                    pop!(params[j, :])
                    pop!(grads[j, :])
                elseif (ndims(params[i, :]) == 2) && (ndims(params[j, :]) == 2) && \
                    (size(params[i, :]') == size(params[j, :])) && (params[i, :]' == params[j, :])
                    grads[i, :] .+= grads[j, :]'
                    find_fig = true
                    pop!(params[j, :])
                    pop!(grads[j, :])
                end
                if find_fig == true break end
            end
            if find_fig == true break end
        end
    end
    return params, grads
end