 elseif parent ~= game then
        while true do
            if parent and parent.Parent == game then
                if SafeGetService(parent.ClassName) then
                    if lower(parent.ClassName) == "workspace" then
                        return `workspace{out}`
                    else
                        return 'game:GetService("' .. parent.ClassName .. '")' .. out
                    end
                else
                    if parent.Name:match("[%a_]+[%w_]*") then
                        return "game." .. parent.Name .. out
                    else
                        return 'game:FindFirstChild(' .. formatstr(parent.Name) .. ')' .. out
                    end
                end
            elseif not parent.Parent then
                getnilrequired = true
                return 'getNil(' .. formatstr(parent.Name) .. ', "' .. parent.ClassName .. '")' .. out
            else
                if parent.Name:match("[%a_]+[%w_]*") ~= parent.Name then
                    out = ':WaitForChild(' .. formatstr(parent.Name) .. ')' .. out
                else
                    out = ':WaitForChild("' .. parent.Name .. '")'..out
                end
            end
            if i:IsDescendantOf(Players.LocalPlayer) then
                return 'game:GetService("Players").LocalPlayer'..out
            end
            parent = parent.Parent
            task.wait()
        end
    else
        return "game"
    end
end

--- Gets the player an instance is descended from
function getplayer(instance)
    for _, v in next, Players:GetPlayers() do
        if v.Character and (instance:IsDescendantOf(v.Character) or instance == v.Character) then
            return v
        end
    end
end

--- value-to-path (in table)
function v2p(x, t, path, prev)
    if not path then
        path = ""
    end
    if not prev then
        prev = {}
    end
    if rawequal(x, t) then
        return true, ""
    end
    for i, v in next, t do
        if rawequal(v, x) then
            if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                return true, (path .. "." .. i)
            else
                return true, (path .. "[" .. v2s(i) .. "]")
            end
        end
        if type(v) == "table" then
            local duplicate = false
            for _, y in next, prev do
                if rawequal(y, v) then
                    duplicate = true
                end
            end
            if not duplicate then
                table.insert(prev, t)
                local found
                found, p = v2p(x, v, path, prev)
                if found then
                    if type(i) == "string" and i:match("^[%a_]+[%w_]*$") then
                        return true, "." .. i .. p
                    else
                        return true, "[" .. v2s(i) .. "]" .. p
                    end
                end
            end
        end
    end
    return false, ""
end

--- format s: string, byte encrypt (for weird symbols)
function formatstr(s, indentation)
    if not indentation then
        indentation = 0
    end
    local handled, reachedMax = handlespecials(s, indentation)
    return '"' .. handled .. '"' .. (reachedMax and " --[[ MAXIMUM STRING SIZE REACHED, CHANGE 'getgenv().SimpleSpyMaxStringSize' TO ADJUST MAXIMUM SIZE ]]" or "")
end

--- Adds \'s to the text as a replacement to whitespace chars and other things because string.format can't yayeet

local function isFinished(coroutines: table)
    for _, v in next, coroutines do
        if status(v) == "running" then
            return false
        end
    end
    return true
end

local specialstrings = {
    ["\n"] = function(thread,index)
        resume(thread,index,"\\n")
    end,
    ["\t"] = function(thread,index)
        resume(thread,index,"\\t")
    end,
    ["\\"] = function(thread,index)
        resume(thread,index,"\\\\")
    end,
    ['"'] = function(thread,index)
        resume(thread,index,"\\\"")
    end
}

function handlespecials(s, indentation)
    local i = 0
    local n = 1
    local coroutines = {}
    local coroutineFunc = function(i, r)
        s = s:sub(0, i - 1) .. r .. s:sub(i + 1, -1)
    end
    local timeout = 0
    repeat
        i += 1
        if timeout >= 10 then
            task.wait()
            timeout = 0
        end
        local char = s:sub(i, i)

        if byte(char) then
            timeout += 1
            local c = create(coroutineFunc)
            table.insert(coroutines, c)
            local specialfunc = specialstrings[char]

            if specialfunc then
                specialfunc(c,i)
                i += 1
            elseif byte(char) > 126 or byte(char) < 32 then
                resume(c, i, "\\" .. byte(char))
                -- s = s:sub(0, i - 1) .. "\\" .. byte(char) .. s:sub(i + 1, -1)
                i += #rawtostring(byte(char))
            end
            if i >= n * 100 then
                local extra = string.format('" ..\n%s"', string.rep(" ", indentation + indent))
                s = s:sub(0, i) .. extra .. s:sub(i + 1, -1)
                i += #extra
                n += 1
            end
        end
    until char == "" or i > (getgenv().SimpleSpyMaxStringSize or 10000)
    while not isFinished(coroutines) do
        RunService.Heartbeat:Wait()
    end
    clear(coroutines)
    if i > (getgenv().SimpleSpyMaxStringSize or 10000) then
        s = string.sub(s, 0, getgenv().SimpleSpyMaxStringSize or 10000)
        return s, true
    end
    return s, false
end

--- finds script from 'src' from getinfo, returns nil if not found
--- @param src string
function getScriptFromSrc(src)
    local realPath
    local runningTest
    --- @type number
    local s, e
    local match = false
    if src:sub(1, 1) == "=" then
        realPath = game
        s = 2
    else
        runningTest = src:sub(2, e and e - 1 or -1)
        for _, v in next, getnilinstances() do
            if v.Name == runningTest then
                realPath = v
                break
            end
        end
        s = #runningTest + 1
    end
    if realPath then
        e = src:sub(s, -1):find("%.")
        local i = 0
        repeat
            i += 1
            if not e then
                runningTest = src:sub(s, -1)
                local test = realPath.FindFirstChild(realPath, runningTest)
                if test then
                    realPath = test
                end
                match = true
            else
                runningTest = src:sub(s, e)
                local test = realPath.FindFirstChild(realPath, runningTest)
                local yeOld = e
                if test then
                    realPath = test
                    s = e + 2
                    e = src:sub(e + 2, -1):find("%.")
                    e = e and e + yeOld or e
                else
                    e = src:sub(e + 2, -1):find("%.")
                    e = e and e + yeOld or e
                end
            end
        until match or i >= 50
    end
    return realPath
end

--- schedules the provided function (and calls it with any args after)

function schedule(f, ...)
    table.insert(scheduled, {f, ...})
end

--- yields the current thread until the scheduler gives the ok
function scheduleWait()
    local thread = running()
    schedule(function()
        resume(thread)
    end)
    yield()
end

--- the big (well tbh small now) boi task scheduler himself, handles p much anything as quicc as possible
local function taskscheduler()
    if not toggle then
        scheduled = {}
        return
    end
    if #scheduled > SIMPLESPYCONFIG_MaxRemotes + 100 then
        table.remove(scheduled, #scheduled)
    end
    if #scheduled > 0 then
        local currentf = scheduled[1]
        table.remove(scheduled, 1)
        if type(currentf) == "table" and type(currentf[1]) == "function" then
            pcall(unpack(currentf))
        end
    end
end

local function tablecheck(tabletocheck,instance,id)
    return tabletocheck[id] or tabletocheck[instance.Name]
end

function remoteHandler(data)
    if configs.autoblock then
        local id = data.id

        if excluding[id] then
            return
        end
        if not history[id] then
            history[id] = {badOccurances = 0, lastCall = tick()}
        end
        if tick() - history[id].lastCall < 1 then
            history[id].badOccurances += 1
            return
        else
            history[id].badOccurances = 0
        end
        if history[id].badOccurances > 3 then
            excluding[id] = true
            return
        end
        history[id].lastCall = tick()
    end

    if (data.remote:IsA("RemoteEvent") or data.remote:IsA("UnreliableRemoteEvent")) and lower(data.method) == "fireserver" then
        newRemote("event", data)
    elseif data.remote:IsA("RemoteFunction") and lower(data.method) == "invokeserver" then
        newRemote("function", data)
    end
end

local newindex = function(method,originalfunction,...)
    if typeof(...) == 'Instance' then
        local remote = cloneref(...)

        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") or remote:IsA("UnreliableRemoteEvent") then
            if not configs.logcheckcaller and checkcaller() then return originalfunction(...) end
            local id = ThreadGetDebugId(remote)
            local blockcheck = tablecheck(blocklist,remote,id)
            local args = {select(2,...)}

            if not tablecheck(blacklist,remote,id) and not IsCyclicTable(args) then
                local data = {
                    method = method,
                    remote = remote,
                    args = deepclone(args),
                    infofunc = infofunc,
                    callingscript = callingscript,
                    metamethod = "__index",
                    blockcheck = blockcheck,
                    id = id,
                    returnvalue = {}
                }
                args = nil

                if configs.funcEnabled then
                    data.infofunc = info(2,"f")
                    local calling = getcallingscript()
                    data.callingscript = calling and cloneref(calling) or nil
                end

                schedule(remoteHandler,data)

                --[[if configs.logreturnvalues and remote:IsA("RemoteFunction") then
                    local thread = running()
                    local returnargs = {...}
                    local returndata

                    spawn(function()
                        setnamecallmethod(method)
                        returndata = originalnamecall(unpack(returnargs))
                        data.returnvalue.data = returndata
                        if ThreadIsNotDead(thread) then
                            resume(thread)
                        end
                     end)
                    yield()
                    if not blockcheck then
                        return returndata
                    end
                end]]
                end
            if blockcheck then return end
        end
    end
    return originalfunction(...)
end

local newnamecall = newcclosure(function(...)
    local method = getnamecallmethod()

    if method and (method == "FireServer" or method == "fireServer" or method == "InvokeServer" or method == "invokeServer") then
        if typeof(...) == 'Instance' then
            local remote = cloneref(...)

            if IsA(remote,"RemoteEvent") or IsA(remote,"RemoteFunction") or IsA(remote,"UnreliableRemoteEvent") then    
                if not configs.logcheckcaller and checkcaller() then return originalnamecall(...) end
                local id = ThreadGetDebugId(remote)
                local blockcheck = tablecheck(blocklist,remote,id)
                local args = {select(2,...)}

                if not tablecheck(blacklist,remote,id) and not IsCyclicTable(args) then
                    local data = {
                        method = method,
                        remote = remote,
                        args = deepclone(args),
                        infofunc = infofunc,
                        callingscript = callingscript,
                        metamethod = "__namecall",
                        blockcheck = blockcheck,
                        id = id,
                        returnvalue = {}
                    }
                    args = nil

                    if configs.funcEnabled then
                        data.infofunc = info(2,"f")
                        local calling = getcallingscript()
                        data.callingscript = calling and cloneref(calling) or nil
                    end

                    schedule(remoteHandler,data)
                    
                    --[[if configs.logreturnvalues and remote.IsA(remote,"RemoteFunction") then
                        local thread = running()
                        local returnargs = {...}
                        local returndata

                        spawn(function()
                            setnamecallmethod(method)
                            returndata = originalnamecall(unpack(returnargs))
                            data.returnvalue.data = returndata
                            if ThreadIsNotDead(thread) then
                                resume(thread)
                            end
                        end)
                        yield()
                        if not blockcheck then
                            return returndata
                        end
                    end]]
                end
                if blockcheck then return end
            end
        end
    end
    return originalnamecall(...)
end)

local newFireServer = newcclosure(function(...)
    return newindex("FireServer",originalEvent,...)
end)

local newUnreliableFireServer = newcclosure(function(...)
    return newindex("FireServer",originalUnreliableEvent,...)
end)

local newInvokeServer = newcclosure(function(...)
    return newindex("InvokeServer",originalFunction,...)
end)

local function disablehooks()
    if synv3 then
        unhook(getrawmetatable(game).__namecall,originalnamecall)
        unhook(Instance.new("RemoteEvent").FireServer, originalEvent)
        unhook(Instance.new("RemoteFunction").InvokeServer, originalFunction)
        unhook(Instance.new("UnreliableRemoteEvent").FireServer, originalUnreliableEvent)
        restorefunction(originalnamecall)
        restorefunction(originalEvent)
        restorefunction(originalFunction)
    else
        if hookmetamethod then
            hookmetamethod(game,"__namecall",originalnamecall)
        else
            hookfunction(getrawmetatable(game).__namecall,originalnamecall)
        end
        hookfunction(Instance.new("RemoteEvent").FireServer, originalEvent)
        hookfunction(Instance.new("RemoteFunction").InvokeServer, originalFunction)
        hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, originalUnreliableEvent)
    end
end

--- Toggles on and off the remote spy
function toggleSpy()
    if not toggle then
        local oldnamecall
        if synv3 then
            oldnamecall = hook(getrawmetatable(game).__namecall,clonefunction(newnamecall))
            originalEvent = hook(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
            originalFunction = hook(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
            originalUnreliableEvent = hook(Instance.new("UnreliableRemoteEvent").FireServer, clonefunction(newUnreliableFireServer))
        else
            if hookmetamethod then
                oldnamecall = hookmetamethod(game, "__namecall", clonefunction(newnamecall))
            else
                oldnamecall = hookfunction(getrawmetatable(game).__namecall,clonefunction(newnamecall))
            end
            originalEvent = hookfunction(Instance.new("RemoteEvent").FireServer, clonefunction(newFireServer))
            originalFunction = hookfunction(Instance.new("RemoteFunction").InvokeServer, clonefunction(newInvokeServer))
            originalUnreliableEvent = hookfunction(Instance.new("UnreliableRemoteEvent").FireServer, clonefunction(newUnreliableFireServer))
        end
        originalnamecall = originalnamecall or function(...)
            return oldnamecall(...)
        end
    else
        disablehooks()
    end
end

--- Toggles between the two remotespy methods (hookfunction currently = disabled)
function toggleSpyMethod()
    toggleSpy()
    toggle = not toggle
end

--- Shuts down the remote spy
local function shutdown()
    if schedulerconnect then
        schedulerconnect:Disconnect()
    end
    for _, connection in next, connections do
        connection:Disconnect()
    end
    for i,v in next, running_threads do
        if ThreadIsNotDead(v) then
            close(v)
        end
    end
    clear(running_threads)
    clear(connections)
    clear(logs)
    clear(remoteLogs)
    disablehooks()
    SimpleSpy3:Destroy()
    Storage:Destroy()
    UserInputService.MouseIconEnabled = true
    getgenv().SimpleSpyExecuted = false
end

-- main
if not getgenv().SimpleSpyExecuted then
    local succeeded,err = pcall(function()
        if not RunService:IsClient() then
            error("SimpleSpy cannot run on the server!")
        end
        getgenv().SimpleSpyShutdown = shutdown
        onToggleButtonClick()
        if not hookmetamethod then
            ErrorPrompt("Simple Spy V3 will not function to it's fullest capablity due to your executor not supporting hookmetamethod.",true)
        end
        codebox = Highlight.new(CodeBox)
        logthread(spawn(function()
            local suc,err = pcall(game.HttpGet,game,"https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/SimpleSpyV3/update.txt")
            codebox:setRaw((suc and err) or "")
        end))
        getgenv().SimpleSpy = SimpleSpy
        getgenv().getNil = function(name,class)
            for _,v in next, getnilinstances() do
                if v.ClassName == class and v.Name == name then
                    return v;
                end
            end
        end
        Background.MouseEnter:Connect(function(...)
            mouseInGui = true
            mouseEntered()
        end)
        Background.MouseLeave:Connect(function(...)
            mouseInGui = false
            mouseEntered()
        end)
        TextLabel:GetPropertyChangedSignal("Text"):Connect(scaleToolTip)
        -- TopBar.InputBegan:Connect(onBarInput)
        MinimizeButton.MouseButton1Click:Connect(toggleMinimize)
        MaximizeButton.MouseButton1Click:Connect(toggleSideTray)
        Simple.MouseButton1Click:Connect(onToggleButtonClick)
        CloseButton.MouseEnter:Connect(onXButtonHover)
        CloseButton.MouseLeave:Connect(onXButtonUnhover)
        Simple.MouseEnter:Connect(onToggleButtonHover)
        Simple.MouseLeave:Connect(onToggleButtonUnhover)
        CloseButton.MouseButton1Click:Connect(shutdown)
        table.insert(connections, UserInputService.InputBegan:Connect(backgroundUserInput))
        connectResize()
        SimpleSpy3.Enabled = true
        logthread(spawn(function()
            delay(1,onToggleButtonUnhover)
        end))
        schedulerconnect = RunService.Heartbeat:Connect(taskscheduler)
        bringBackOnResize()
        SimpleSpy3.Parent = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(SimpleSpy3)) or CoreGui
        logthread(spawn(function()
            local lp = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() or Players.LocalPlayer
            generation = {
                [OldDebugId(lp)] = 'game:GetService("Players").LocalPlayer',
                [OldDebugId(lp:GetMouse())] = 'game:GetService("Players").LocalPlayer:GetMouse',
                [OldDebugId(game)] = "game",
                [OldDebugId(workspace)] = "workspace"
            }
        end))
    end)
    if succeeded then
        getgenv().SimpleSpyExecuted = true
    else
        shutdown()
        ErrorPrompt("An error has occured:\n"..rawtostring(err))
        return
    end
else
    SimpleSpy3:Destroy()
    return
end

function SimpleSpy:newButton(name, description, onClick)
    return newButton(name, description, onClick)
end

----- ADD ONS ----- (easily add or remove additonal functionality to the RemoteSpy!)
--[[
    Some helpful things:
        - add your function in here, and create buttons for them through the 'newButton' function
        - the first argument provided is the TextButton the player clicks to run the function
        - generated scripts are generated when the namecall is initially fired and saved in remoteFrame objects
        - blacklisted remotes will be ignored directly in namecall (less lag)
        - the properties of a 'remoteFrame' object:
            {
                Name: (string) The name of the Remote
                GenScript: (string) The generated script that appears in the codebox (generated when namecall fired)
                Source: (Instance (LocalScript)) The script that fired/invoked the remote
                Remote: (Instance (RemoteEvent) | Instance (RemoteFunction)) The remote that was fired/invoked
                Log: (Instance (TextButton)) The button being used for the remote (same as 'selected.Log')
            }
        - globals list: (contact @exx#9394 for more information or if you have suggestions for more to be added)
            - closed: (boolean) whether or not the GUI is currently minimized
            - logs: (table[remoteFrame]) full of remoteFrame objects (properties listed above)
            - selected: (remoteFrame) the currently selected remoteFrame (properties listed above)
            - blacklist: (string[] | Instance[] (RemoteEvent) | Instance[] (RemoteFunction)) an array of blacklisted names and remotes
            - codebox: (Instance (TextBox)) the textbox that holds all the code- cleared often
]]
-- Copies the contents of the codebox
newButton(
    "Copy Code",
    function() return "Click to copy code" end,
    function()
        setclipboard(codebox:getString())
        TextLabel.Text = "Copied successfully!"
    end
)

--- Copies the source script (that fired the remote)
newButton(
    "Copy Remote",
    function() return "Click to copy the path of the remote" end,
    function()
        if selected and selected.Remote then
            setclipboard(v2s(selected.Remote))
            TextLabel.Text = "Copied!"
        end
    end
)
            
         -- Function to handle the actual execution logic
local function executeCode()
    local Remote = selected and selected.Remote
    if Remote then
        TextLabel.Text = "Executing..."
        xpcall(function()
            local returnvalue
            if Remote:IsA("RemoteEvent") or Remote:IsA("UnreliableRemoteEvent") then
                returnvalue = Remote:FireServer(unpack(selected.args))
            elseif Remote:IsA("RemoteFunction") then
                returnvalue = Remote:InvokeServer(unpack(selected.args))
            end
            TextLabel.Text = ("Executed successfully!\n%s"):format(v2s(returnvalue))
        end, function(err)
            TextLabel.Text = ("Execution error!\n%s"):format(err)
        end)
        return
    end
    TextLabel.Text = "Source not found"
end

-- Function to update the button's appearance
local function updateRunCodeButton(buttonFrame)
    local ColorBar = buttonFrame:FindFirstChild("ColorBar")
    if ColorBar then
        if isAutoRunning then
            -- Green for activated
            ColorBar.BackgroundColor3 = Color3.fromRGB(68, 206, 91)
        else
            -- White/Default for disabled
            ColorBar.BackgroundColor3 = Color3.new(1, 1, 1)
        end
    end
end

-- Executes the contents of the codebox through loadstring
newButton(
    "Run Code",
    function()
        return isAutoRunning and "Click to DISABLE auto-run (0.1s interval)" or "Click to EXECUTE once or DOUBLE-CLICK to ENABLE auto-run (0.1s interval)"
    end,
    function(buttonFrame)
        logthread(running()) -- Re-add the thread logging which was in the newButton call
        
        if isAutoRunning then
            -- Disable auto-run
            if autoRunConnection then
                autoRunConnection:Disconnect()
                autoRunConnection = nil
            end
            isAutoRunning = false
            TextLabel.Text = "Auto-run DISABLED"
        else
            -- Check for double-click to enable auto-run
            local lastClickTime = buttonFrame.__LastClickTime or 0
            buttonFrame.__LastClickTime = tick()

            if (tick() - lastClickTime) < 0.3 then -- If the second click is within 0.3s
                -- Enable auto-run
                isAutoRunning = true
                -- The original script has a 'taskscheduler' running on Heartbeat
                -- We'll use a standard connection here to run every frame (approx 60 FPS or about 0.016s)
                -- Running every 0.1 seconds requires a slightly different approach or a counter.
                
                -- To strictly enforce 0.1s, we will use a counter on Heartbeat
                local counter = 0
                autoRunConnection = RunService.Heartbeat:Connect(function(deltaTime)
                    counter = counter + deltaTime
                    if counter >= 0.1 then
                        executeCode()
                        counter = 0
                    end
                end)
                TextLabel.Text = "Auto-run ACTIVATED (approx. 0.1s interval)"
            else
                -- Single click: Execute once
                executeCode()
            end
        end

        updateRunCodeButton(buttonFrame)
    end
)
   
            -- Executes the contents of the codebox through loadstring
newButton("Run Code", function() return "Click to execute code" end, function() local Remote = selected and selected.Remote if Remote then TextLabel.Text = "Executing..." xpcall(function() local returnvalue if Remote:IsA("RemoteEvent") or Remote:IsA("UnreliableRemoteEvent") then returnvalue = Remote:FireServer(unpack(selected.args)) elseif Remote:IsA("RemoteFunction") then returnvalue = Remote:InvokeServer(unpack(selected.args)) end TextLabel.Text = ("Executed successfully!\n%s"):format(v2s(returnvalue)) end,function(err) TextLabel.Text = ("Execution error!\n%s"):format(err) end) return end TextLabel.Text = "Source not found" end )


--- Gets the calling script (not super reliable but w/e)
newButton(
    "Get Script",
    function() return "Click to copy calling script to clipboard\nWARNING: Not super reliable, nil == could not find" end,
    function()
        if selected then
            if not selected.Source then
                selected.Source = rawget(getfenv(selected.Function),"script")
            end
            setclipboard(v2s(selected.Source))
            TextLabel.Text = "Done!"
        end
    end
)

--- Decompiles the script that fired the remote and puts it in the code box
newButton("Function Info",function() return "Click to view calling function information" end,
function()
    local func = selected and selected.Function
    if func then
        local typeoffunc = typeof(func)

        if typeoffunc ~= 'string' then
            codebox:setRaw("--[[Generating Function Info please wait]]")
            RunService.Heartbeat:Wait()
            local lclosure = islclosure(func)
            local SourceScript = rawget(getfenv(func),"script")
            local CallingScript = selected.Source or nil
            local info = {}
            
            info = {
                info = getinfo(func),
                constants = lclosure and deepclone(getconstants(func)) or "N/A --Lua Closure expected got C Closure",
                upvalues = deepclone(getupvalues(func)),
                script = {
                    SourceScript = SourceScript or 'nil',
                    CallingScript = CallingScript or 'nil'
                }
            }
                    
            if configs.advancedinfo then
                local Remote = selected.Remote

                info["advancedinfo"] = {
                    Metamethod = selected.metamethod,
                    DebugId = {
                        SourceScriptDebugId = SourceScript and typeof(SourceScript) == "Instance" and OldDebugId(SourceScript) or "N/A",
                        CallingScriptDebugId = CallingScript and typeof(SourceScript) == "Instance" and OldDebugId(CallingScript) or "N/A",
                        RemoteDebugId = OldDebugId(Remote)
                    },
                    Protos = lclosure and getprotos(func) or "N/A --Lua Closure expected got C Closure"
                }

                if Remote:IsA("RemoteFunction") then
                    info["advancedinfo"]["OnClientInvoke"] = getcallbackmember and (getcallbackmember(Remote,"OnClientInvoke") or "N/A") or "N/A --Missing function getcallbackmember"
                elseif getconnections then
                    info["advancedinfo"]["OnClientEvents"] = {}

                    for i,v in next, getconnections(Remote.OnClientEvent) do
                        info["advancedinfo"]["OnClientEvents"][i] = {
                            Function = v.Function or "N/A",
                            State = v.State or "N/A"
                        }
                    end
                end
            end
            codebox:setRaw("--[[Converting table to string please wait]]")
            selected.Function = v2v({functionInfo = info})
        end
        codebox:setRaw("-- Calling function info\n-- Generated by the SimpleSpy V3 serializer\n\n"..selected.Function)
        TextLabel.Text = "Done! Function info generated by the SimpleSpy V3 Serializer."
    else
        TextLabel.Text = "Error! Selected function was not found."
    end
end)

--- Clears the Remote logs
newButton(
    "Clr Logs",
    function() return "Click to clear logs" end,
    function()
        TextLabel.Text = "Clearing..."
        clear(logs)
        for i,v in next, LogList:GetChildren() do
            if not v:IsA("UIListLayout") then
                v:Destroy()
            end
        end
        codebox:setRaw("")
        selected = nil
        TextLabel.Text = "Logs cleared!"
    end
)

--- Excludes the selected.Log Remote from the RemoteSpy
newButton(
    "Exclude (i)",
    function() return "Click to exclude this Remote.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable." end,
    function()
        if selected then
            blacklist[OldDebugId(selected.Remote)] = true
            TextLabel.Text = "Excluded!"
        end
    end
)

--- Excludes all Remotes that share the same name as the selected.Log remote from the RemoteSpy
newButton(
    "Exclude (n)",
    function() return "Click to exclude all remotes with this name.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable." end,
    function()
        if selected then
            blacklist[selected.Name] = true
            TextLabel.Text = "Excluded!"
        end
    end
)

--- clears blacklist
newButton("Clr Blacklist",
function() return "Click to clear the blacklist.\nExcluding a remote makes SimpleSpy ignore it, but it will continue to be usable." end,
function()
    blacklist = {}
    TextLabel.Text = "Blacklist cleared!"
end)

--- Prevents the selected.Log Remote from firing the server (still logged)
newButton(
    "Block (i)",
    function() return "Click to stop this remote from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server." end,
    function()
        if selected then
            blocklist[OldDebugId(selected.Remote)] = true
            TextLabel.Text = "Excluded!"
        end
    end
)

--- Prevents all remotes from firing that share the same name as the selected.Log remote from the RemoteSpy (still logged)
newButton("Block (n)",function()
    return "Click to stop remotes with this name from firing.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server." end,
    function()
        if selected then
            blocklist[selected.Name] = true
            TextLabel.Text = "Excluded!"
        end
    end
)

--- clears blacklist
newButton(
    "Clr Blocklist",
    function() return "Click to stop blocking remotes.\nBlocking a remote won't remove it from SimpleSpy logs, but it will not continue to fire the server." end,
    function()
        blocklist = {}
        TextLabel.Text = "Blocklist cleared!"
    end
)

--- Attempts to decompile the source script
newButton("Decompile",
    function()
        return "Decompile source script"
    end,function()
        if decompile then
            if selected and selected.Source then
                local Source = selected.Source
                if not DecompiledScripts[Source] then
                    codebox:setRaw("--[[Decompiling]]")

                    xpcall(function()
                        local decompiledsource = decompile(Source):gsub("-- Decompiled with the Synapse X Luau decompiler.","")
                        local Sourcev2s = v2s(Source)
                        if (decompiledsource):find("script") and Sourcev2s then
                            DecompiledScripts[Source] = ("local script = %s\n%s"):format(Sourcev2s,decompiledsource)
                        end
                    end,function(err)
                        return codebox:setRaw(("--[[\nAn error has occured\n%s\n]]"):format(err))
                    end)
                end
                codebox:setRaw(DecompiledScripts[Source] or "--No Source Found")
                TextLabel.Text = "Done!"
            else
                TextLabel.Text = "Source not found!"
            end
        else
            TextLabel.Text = "Missing function (decompile)"
        end
    end
)

    --[[newButton(
        "returnvalue",
        function() return "Get a Remote's return data" end,
        function()
            if selected then
                local Remote = selected.Remote
                if Remote and Remote:IsA("RemoteFunction") then
                    if selected.returnvalue and selected.returnvalue.data then
                        return codebox:setRaw(v2s(selected.returnvalue.data))
                    end
                    return codebox:setRaw("No data was returned")
                else
                    codebox:setRaw("RemoteFunction expected got "..(Remote and Remote.ClassName))
                end
            end
        end
    )]]

newButton(
    "Disable Info",
    function() return string.format("[%s] Toggle function info (because it can cause lag in some games)", configs.funcEnabled and "ENABLED" or "DISABLED") end,
    function()
        configs.funcEnabled = not configs.funcEnabled
        TextLabel.Text = string.format("[%s] Toggle function info (because it can cause lag in some games)", configs.funcEnabled and "ENABLED" or "DISABLED")
    end
)

newButton(
    "Autoblock",
    function() return string.format("[%s] [BETA] Intelligently detects and excludes spammy remote calls from logs", configs.autoblock and "ENABLED" or "DISABLED") end,
    function()
        configs.autoblock = not configs.autoblock
        TextLabel.Text = string.format("[%s] [BETA] Intelligently detects and excludes spammy remote calls from logs", configs.autoblock and "ENABLED" or "DISABLED")
        history = {}
        excluding = {}
    end
)

newButton("Logcheckcaller",function()
    return ("[%s] Log remotes fired by the client"):format(configs.logcheckcaller and "ENABLED" or "DISABLED")
end,
function()
    configs.logcheckcaller = not configs.logcheckcaller
    TextLabel.Text = ("[%s] Log remotes fired by the client"):format(configs.logcheckcaller and "ENABLED" or "DISABLED")
end)

--[[newButton("Log returnvalues",function()
    return ("[BETA] [%s] Log RemoteFunction's return values"):format(configs.logcheckcaller and "ENABLED" or "DISABLED")
end,
function()
    configs.logreturnvalues = not configs.logreturnvalues
    TextLabel.Text = ("[BETA] [%s] Log RemoteFunction's return values"):format(configs.logreturnvalues and "ENABLED" or "DISABLED")
end)]]

newButton("Advanced Info",function()
    return ("[%s] Display more remoteinfo"):format(configs.advancedinfo and "ENABLED" or "DISABLED")
end,
function()
    configs.advancedinfo = not configs.advancedinfo
    TextLabel.Text = ("[%s] Display more remoteinfo"):format(configs.advancedinfo and "ENABLED" or "DISABLED")
end)

newButton("Join Discord",function()
    return "Joins The Simple Spy Discord"
end,
function()
    setclipboard("https://discord.com/invite/AWS6ez9")
    TextLabel.Text = "Copied invite to your clipboard"
    if request then
        request({Url = 'http://127.0.0.1:6463/rpc?v=1',Method = 'POST',Headers = {['Content-Type'] = 'application/json', Origin = 'https://discord.com'},Body = http:JSONEncode({cmd = 'INVITE_BROWSER',nonce = http:GenerateGUID(false),args = {code = 'AWS6ez9'}})})
    end
end)

if configs.supersecretdevtoggle then
    newButton("Load SSV2.2",function()
        return "Load's Simple Spy V2.2"
    end,
    function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"))()
    end)
    newButton("Load SSV3",function()
        return "Load's Simple Spy V3"
    end,
    function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpySource.lua"))()
    end)
    local SuperSecretFolder = Create("Folder",{Parent = SimpleSpy3})
    newButton("SUPER SECRET BUTTON",function()
        return "You dont need a discription you already know what it does"
    end,
    function()
        SuperSecretFolder:ClearAllChildren()
        local random = listfiles("Music")
        local NotSound = Create("Sound",{Parent = SuperSecretFolder,Looped = false,Volume = math.random(1,5),SoundId = getsynasset(random[math.random(1,#random)])})
        NotSound:Play()
    end)
end

if table.find({
    Enum.Platform.IOS, Enum.Platform.Android
}, UserInputService:GetPlatform()) then
    Background.Draggable = true
    local QuickCapture = Instance.new("TextButton")
    local UICorner = Instance.new("UICorner")
    QuickCapture.Parent = SimpleSpy3
    QuickCapture.BackgroundColor3 = Color3.fromRGB(37, 36, 38)
    QuickCapture.BackgroundTransparency = 0.14
    QuickCapture.Position = UDim2.new(0.529, 0, 0, 0)
    QuickCapture.Size = UDim2.new(0, 32, 0, 33)
    QuickCapture.Font = Enum.Font.SourceSansBold
    QuickCapture.Text = "Spy"
    QuickCapture.TextColor3 = Background.Visible and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(252, 51, 51)
    QuickCapture.TextSize = 16
    QuickCapture.TextWrapped = true
    QuickCapture.ZIndex = 10
    QuickCapture.Draggable = true
    UICorner.CornerRadius = UDim.new(0.5, 0)
    UICorner.Parent = QuickCapture
    QuickCapture.MouseButton1Click:Connect(function()
        Background.Visible = not Background.Visible
        QuickCapture.TextColor3 = Background.Visible and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(252, 51, 51)
    end)
			end
