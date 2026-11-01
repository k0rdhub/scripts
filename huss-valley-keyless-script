RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Input.Value, function(dt)
    local now = os.clock()
    local ok, err
    if now - lastControllerTick >= controllerInterval then
        local controllerDt = math.max(dt, now - lastControllerTick)
        lastControllerTick = now
        ok, err = pcall(runnerStep, now, controllerDt)
        if not ok then
            setDebugError("Runner: " .. tostring(err))
        end

        ok, err = pcall(catcherStep, now, controllerDt)
        if not ok then
            setDebugError("Catcher: " .. tostring(err))
        end
    end

    if now - runtime.utilityTick >= UTILITY_INTERVAL then
        runtime.utilityTick = now
        ok, err = pcall(utilityStep, now)
        if not ok then
            setDebugError("Utility: " .. tostring(err))
        end
    end

    if runtime.debugEnabled and now - (runtime.debugPanelAt or -math.huge) >= 0.1 then
        runtime.debugPanelAt = now
        local debugOk, debugErr = pcall(updateDebugPanel, now)
        if not debugOk then
            setDebugError("DebugPanel: " .. tostring(debugErr))
        end
    end
end)

-- NOTE: `script` is nil when running through an executor (loadstring), which caused
-- "attempt to index nil with 'Destroying'". Cleanup is now a plain function that is
-- called from the Settings > Unload button, on window close, and on re-execute.
Hub.cleanup = function()
    if Hub.cleaned then
        return
    end
    Hub.cleaned = true

    -- stop every feature that polls SETTINGS flags
    for key, value in pairs(SETTINGS) do
        if type(value) == "boolean" then
            SETTINGS[key] = false
        end
    end

    pcall(cancelRevive)
    pcall(function() RunService:UnbindFromRenderStep(RENDER_NAME) end)
    pcall(function() RunService:UnbindFromRenderStep(SPEED_RENDER_NAME) end)
    pcall(restoreNativeWalkSpeed)
    pcall(cleanupVisuals)

    if Hub.idleConn then
        pcall(function() Hub.idleConn:Disconnect() end)
        Hub.idleConn = nil
    end

    runtime.mapCache = nil
    runtime.mapCacheAt = -math.huge
    runtime.runnerPlanAt = -math.huge
    runtime.runnerPlanDirection = Vector3.zero
    runtime.runnerPlanGoal = Vector3.zero
    runtime.wheelLastButton = nil
    runtime.wheelStatus = "disabled"
    runtime.wheelSpinning = false
    runtime.wheelNextAttemptAt = -math.huge
    runtime.journeyStatus = "disabled"
    runtime.journeyClaimedButtons = {}
    runtime.journeyLoaded = false
    runtime.journeySeasonId = nil
    runtime.journeyClaimInFlight = false
    runtime.journeyTier = 1
    runtime.journeyPremium = false
    runtime.journeyClaims = {}
    runtime.mapVoteStatus = "disabled"
    runtime.mapVoteOptions = {}
    runtime.mapVoteOpen = false
    runtime.safeCheckAt = -math.huge
    runtime.safeCheckPosition = nil
    edgeRayCache.map = nil
    edgeRayCache.field = nil
    edgeRayCache.params = nil
    edgeRayCache.invisWall = nil
    edgeRayCache.wallParams = nil

    pcall(function()
        if runtime.debugGui then
            runtime.debugGui:Destroy()
        end
    end)

    if Hub.genv.K0rdHubUnload == Hub.cleanup then
        Hub.genv.K0rdHubUnload = nil
    end
    if Hub.genv.HussValleyUnload == Hub.cleanup then
        Hub.genv.HussValleyUnload = nil
    end

    pcall(function() Window:Destroy() end)
end

Hub.genv.K0rdHubUnload = Hub.cleanup
Hub.genv.HussValleyUnload = Hub.cleanup
pcall(function()
    Window:OnDestroy(function()
        Hub.cleanup()
    end)
end)

-- Always open on the Runner tab right after execution
function Hub.selectRunnerTab()
    if Hub.cleaned then
        return
    end
    pcall(function() RunnerTab:Select() end)
    pcall(function() Window:SelectTab(1) end)
end
Hub.selectRunnerTab()
task.delay(0.5, Hub.selectRunnerTab)
task.delay(1.5, Hub.selectRunnerTab)
