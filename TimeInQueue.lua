if not TimeInQueue then
	TimeInQueue = {}
end

local oldOnMouseoverScenarioQueue
local GetGameTime, FormatClock, Tooltips, GetString = GetGameTime, TimeUtils.FormatClock, Tooltips, GetString

-- local functions
local function SetScenario(selectedId)
	TimeInQueue.Scenarios[selectedId] = { Time = GetGameTime() }
end

local function ResetScenarios()
	TimeInQueue.Scenarios = {}
end

-- global functions
function TimeInQueue.OnInitialize()
	oldOnMouseoverScenarioQueue = EA_Window_OverheadMap.OnMouseoverScenarioQueue
	EA_Window_OverheadMap.OnMouseoverScenarioQueue = TimeInQueue.OnMouseoverScenarioQueue
	RegisterEventHandler(SystemData.Events.SCENARIO_INSTANCE_CANCEL, "TimeInQueue.ScenarioInstanceCancel")
	RegisterEventHandler(SystemData.Events.INTERACT_LEAVE_SCENARIO_QUEUE, "TimeInQueue.InteractLeaveScenarioQueue")
	RegisterEventHandler(SystemData.Events.SCENARIO_INSTANCE_JOIN_NOW, "TimeInQueue.ScenarioInstanceJoinNow")
	RegisterEventHandler(SystemData.Events.INTERACT_GROUP_JOIN_SCENARIO_QUEUE, "TimeInQueue.InteractGroupJoinScenarioQueue")
	RegisterEventHandler(SystemData.Events.INTERACT_JOIN_SCENARIO_QUEUE, "TimeInQueue.InteractJoinScenarioQueue")
	if not TimeInQueue.Scenarios then
		TimeInQueue.Scenarios = {}
	end
end

function TimeInQueue.Shutdown()
	EA_Window_OverheadMap.OnMouseoverScenarioQueue = oldOnMouseoverScenarioQueue
	UnRegisterEventHandler(SystemData.Events.SCENARIO_INSTANCE_CANCEL, "TimeInQueue.ScenarioInstanceCancel")
	UnRegisterEventHandler(SystemData.Events.INTERACT_LEAVE_SCENARIO_QUEUE, "TimeInQueue.InteractLeaveScenarioQueue")
	UnRegisterEventHandler(SystemData.Events.SCENARIO_INSTANCE_JOIN_NOW, "TimeInQueue.ScenarioInstanceJoinNow")
	UnRegisterEventHandler(SystemData.Events.INTERACT_GROUP_JOIN_SCENARIO_QUEUE, "TimeInQueue.InteractGroupJoinScenarioQueue")
	UnRegisterEventHandler(SystemData.Events.INTERACT_JOIN_SCENARIO_QUEUE, "TimeInQueue.InteractJoinScenarioQueue")
end

function TimeInQueue.OnUpdate(elapsedTime)
	local queueData = GetScenarioQueueData()
	if (queueData == nil) then
		TimeInQueue.Scenarios = {}
		return
	end
	local queueCount = queueData.totalQueuedScenarios
	for index = 1, queueCount do
		if TimeInQueue.Scenarios[queueData[index].id] == nil then
			TimeInQueue.Scenarios[queueData[index].id] = { Time = GetGameTime() }
		end
	end	
end

function TimeInQueue.InteractJoinScenarioQueue()
	SetScenario(GameData.ScenarioQueueData.selectedId)
end

function TimeInQueue.InteractLeaveScenarioQueue()	
	if TimeInQueue.Scenarios[GameData.ScenarioQueueData.selectedId] ~= nil then
		TimeInQueue.Scenarios[GameData.ScenarioQueueData.selectedId].Time = 0
	end
end

function TimeInQueue.ScenarioInstanceCancel()	
	ResetScenarios()
end

function TimeInQueue.ScenarioInstanceJoinNow()	
	ResetScenarios()
end

function TimeInQueue.InteractGroupJoinScenarioQueue()	
	-- nothing yet
end

function TimeInQueue.OnMouseoverScenarioQueue()
	Tooltips.CreateTextOnlyTooltip(SystemData.ActiveWindow.name, nil) 
	Tooltips.SetUpdateCallback(TimeInQueue.GetScenarioQueueData)
end

function TimeInQueue.GetScenarioQueueData()
	local queueData = GetScenarioQueueData()
	local row = 1
	local column = 1
	if (queueData ~= nil) then
		Tooltips.SetTooltipText(row, column, GetString(StringTables.Default.LABEL_SCENARIO_QUEUE_CURRENT_QUEUE))
		local queueCount = queueData.totalQueuedScenarios
		for index = 1, queueCount do
			local timeDiff = GetGameTime() - TimeInQueue.Scenarios[queueData[index].id].Time
			local ltime, _, _ = FormatClock(timeDiff);
			local queueName = EA_Window_OverheadMap.GetQueueName(queueData[index].type, queueData[index].id)..L" ("..towstring(ltime)..L")"
			Tooltips.SetTooltipText(index+1, column, queueName) 
			Tooltips.SetTooltipColor(index+1, column, 255, 255, 255)
		end		
		Tooltips.SetTooltipText(queueCount+2, column, GetString(StringTables.Default.TEXT_SCENARIO_QUEUE_MORE))
		Tooltips.SetTooltipText(queueCount+3, column, GetString(StringTables.Default.TEXT_SCENARIO_QUEUE_LESS))		
		Tooltips.SetTooltipColor(row, column, 255, 204, 102)
		Tooltips.SetTooltipColor(queueCount+2, column, 175, 175, 175)
		Tooltips.SetTooltipColor(queueCount+3, column, 175, 175, 175)
	else
		if (GameData.ScenarioQueueData[1].id == 0) then
			Tooltips.SetTooltipText(row, column, GetString(StringTables.Default.LABEL_SCENARIO_QUEUE_NONE_AVAILABLE))
		else
			Tooltips.SetTooltipText(row, column, GetString(StringTables.Default.LABEL_SCENARIO_QUEUE))
		end
	end	
	Tooltips.Finalize()
	Tooltips.AnchorTooltip(Tooltips.ANCHOR_WINDOW_LEFT)
end

