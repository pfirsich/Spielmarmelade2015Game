do
    local currentState = {}

    function setState(state, ...)
        local fromState = currentState[#currentState]
        if fromState and fromState.leave then fromState.leave(state) end
        currentState[#currentState] = state
        if state.enter then state.enter(fromState, ...) end
    end

    function pushState(state, ...)
        local fromState = currentState[#currentState]
        if fromState and fromState.leave then fromState.leave(state) end
        currentState[#currentState+1] = state
        if state.enter then state.enter(fromState, ...) end
    end

    function popState(...)
        if #currentState >= 1 then
            error("Cannot pop state (stack empty).")
        else
            local fromState = currentState[#currentState]
            if fromState and fromState.leave then fromState.leave(currentState[#currentState-1]) end
            currentState[#currentState] = nil
            if currentState[#currentState].enter then currentState[#currentState].enter(fromState, ...) end
        end
    end

    function getState()
        return currentState[#currentState]
    end
end
