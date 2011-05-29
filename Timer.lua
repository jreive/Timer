--[[

	Timer Action Plugin
	(C) Illusion Programming, 2011. (gensokyo.co.uk)
	
	Programmers:
		* Shadiku Izayoi <blackhawk.delta@gmail.com>
		
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
]]--

-- Define global table.
Timer = {Debug = false, Offset = 10000, Stored = {}};

-- Add timer code to all page.
for K, V in pairs(Application.GetPages()) do
	Debug.Print("Timer: Adding page script to '"..V.."'..\r\n");
	Application.SetPageScript(V, "On Timer", Application.GetPageScript(V, "On Timer").."\r\n\r\n-- Timer Action Plugin\r\nif (Timer.Stored[e_ID - Timer.Offset]) then\r\n\tTimer.Execute(e_ID - Timer.Offset);\r\nend\r\n\r\n");
end

function Timer.Execute(ID)
	-- Check function arguments.
	assert(type(ID) == "number", "Argument 1 must be of type number.");
	assert(type(Timer.Stored[ID]) == "table", "Timer does not exist!");
	
	-- Increment ticks.
	Debug.Print("Timer.Execute: Incrementing count for '"..Timer.Stored[ID].Name.."'.. ("..(Timer.Stored[ID].Ticks + 1).."/"..Timer.Stored[ID].Repetitions..")\r\n");
	Timer.Stored[ID].Ticks = (Timer.Stored[ID].Ticks + 1);
	
	-- Check if the timer has matched the max amount of repetitions.
	if (Timer.Stored[ID].Repetitions == Timer.Stored[ID].Ticks) then
		-- Execute for the final time.
		Debug.Print("Timer.Execute: Executing '"..Timer.Stored[ID].Name.."' function for the last time..\r\n");
		Timer.Stored[ID].Function(unpack(Timer.Stored[ID].Arguments or {}));
		
		-- Set state to paused.
		Debug.Print("Timer.Execute: Timer '"..Timer.Stored[ID].Name.."' exhausted repetitions. Pausing..\r\n");
		Timer.Stored[ID].Status = "paused";
		
		-- Stop internal page timer.
		return Page.StopTimer(ID + Timer.Offset);
	end
	
	-- Execute the function.
	Debug.Print("Timer.Execute: Executing '"..Timer.Stored[ID].Name.."' function..\r\n");
	return Timer.Stored[ID].Function(unpack(Timer.Stored[ID].Arguments or {}));
end

function Timer.CreateTimer(Name, Interval, Repetitions, Function, ...)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	assert(type(Interval) == "number", "Argument 2 must be of type number.");
	assert(type(Repetitions) == "number", "Argument 3 must be of type number.");
	assert(type(Function) == "function", "Argument 4 must be of type function.");
	
	-- Check timer existance.
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			return false, "Timer already exists.";
		end
	end
	
	-- Create timer.
	local ID = (Table.Count(Timer.Stored) + 1);
	Timer.Stored[ID] = {Name = Name, Status = "paused", Interval = Interval, Repetitions = Repetitions, Ticks = 0, Function = Function, Arguments = ...};
	Debug.Print("Timer.CreateTimer: Created new timer '"..Name.."' (Tick every "..Interval.."ms "..Repetitions.." times.)\r\n");
	
	-- Return success.
	return (type(Timer.Stored[ID]) == "table");
end

function Timer.DeleteTimer(Name)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	
	-- Check timer existance.
	local TimerFound = false;
	
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			TimerFound = K;
			break;
		end
	end
	
	-- If timer not found..
	if not (TimerFound) then
		return false, "Timer does not exist.";
	end
	
	-- Pause if running.
	if (Timer.Stored[TimerFound].Status == "active") then
		-- Stop internal timer.
		Debug.Print("Timer.DeleteTimer: Stopping timer '"..Name.."'.\r\n");
		Page.StopTimer(TimerFound + Timer.Offset);
	end
	
	-- Print text.
	Debug.Print("Timer.DeleteTimer: Removing timer '"..Name.."'.\r\n");
	
	-- Remove.
	Table.Remove(Timer.Stored, TimerFound);
	
	-- Return true.
	return true;
end

function Timer.StartTimer(Name)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	
	-- Check timer existance.
	local TimerFound = false;
	
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			TimerFound = K;
			break;
		end
	end
	
	-- If timer not found..
	if not (TimerFound) then
		return false, "Timer does not exist.";
	end
	
	-- Ensure timer is not exceeded ticks.
	if (Timer.Stored[TimerFound].Ticks == Timer.Stored[TimerFound].Repetitions) then
		return false, "Timer has exceeded maximum repetitions.";
	end
	
	-- Check state.
	if (Timer.Stored[TimerFound].Status == "paused") then
		-- Activate timer.
		Timer.Stored[TimerFound].Status = "active";
		
		-- Start page timer.
		Debug.Print("Timer.StartTimer: Starting timer '"..Timer.Stored[TimerFound].Name.."'..\r\n");
		Page.StartTimer(Timer.Stored[TimerFound].Interval, TimerFound + Timer.Offset);
		return true;
	elseif (Timer.Stored[TimerFound].Status == "active") then
		-- Timer is already running.
		return false, "Timer already started.";
	end
end

function Timer.SetInterval(Name, Interval)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	assert(type(Interval) == "number", "Argument 2 must be of type number.");
	
	-- Check timer existance.
	local TimerFound = false;
	
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			TimerFound = K;
			break;
		end
	end
	
	-- If timer not found..
	if not (TimerFound) then
		return false, "Timer does not exist.";
	end
	
	-- Ensure timer is not exceeded ticks.
	if (Timer.Stored[TimerFound].Ticks == Timer.Stored[TimerFound].Repetitions) then
		return false, "Timer has exceeded maximum repetitions.";
	end
	
	-- Set interval in table.
	Debug.Print("Timer.SetInterval: Setting new interval for '"..Timer.Stored[TimerFound].Name.."' to "..Interval.."ms..\r\n");
	Timer.Stored[TimerFound].Interval = Interval;
		
	-- Check state.
	if (Timer.Stored[TimerFound].Status == "active") then
		-- Stop timer and start it again.
		Debug.Print("Timer.SetInterval: Stopping internal timer for '"..Timer.Stored[TimerFound].Name.."'..\r\n");
		Page.StopTimer(TimerFound + Timer.Offset);
		Debug.Print("Timer.SetInterval: Starting internal timer for '"..Timer.Stored[TimerFound].Name.."'..\r\n");
		Page.StartTimer(Interval, Timer.Offset + TimerFound);
	end
	
	return true;
end

function Timer.SetMaxTicks(Name, MaxTicks)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	assert(type(MaxTicks) == "number", "Argument 2 must be of type number.");
	
	-- Check timer existance.
	local TimerFound = false;
	
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			TimerFound = K;
			break;
		end
	end
	
	-- If timer not found..
	if not (TimerFound) then
		return false, "Timer does not exist.";
	end
	
	-- Ensure timer is not exceeded ticks.
	if (Timer.Stored[TimerFound].Ticks >= MaxTicks) then
		-- Pause timer.
		Debug.Print("Timer.SetMaxTicks: New max ticks value for '"..Timer.Stored[TimerFound].Name.."' exceeds ticks, pausing timer..\r\n");
		Timer.Stored[TimerFound].Status = "paused";
		Timer.Stored[TimerFound].Ticks = MaxTicks;
		Page.StopTimer(TimerFound + Timer.Offset);
	end
	
	-- Set interval in table.
	Debug.Print("Timer.SetMaxTicks: Setting maximum ticks for '"..Timer.Stored[TimerFound].Name.."' to "..MaxTicks.."..\r\n");
	Timer.Stored[TimerFound].Repetitions = MaxTicks;

	return true;
end

function Timer.PauseTimer(Name)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	
	-- Check timer existance.
	local TimerFound = false;
	
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			TimerFound = K;
			break;
		end
	end
	
	-- If timer not found..
	if not (TimerFound) then
		return false, "Timer does not exist.";
	end
	
	-- Ensure timer is not exceeded ticks.
	if (Timer.Stored[TimerFound].Ticks == Timer.Stored[TimerFound].Repetitions) then
		return false, "Timer has exceeded maximum repetitions.";
	end
	
	-- Check state.
	if (Timer.Stored[TimerFound].Status == "active") then
		-- Pause timer.
		Timer.Stored[TimerFound].Status = "paused";
		
		-- Start page timer.
		Debug.Print("Timer.PauseTimer: Pausing timer '"..Timer.Stored[TimerFound].Name.."'..\r\n");
		Page.StopTimer(TimerFound + Timer.Offset);
		return true;
	elseif (Timer.Stored[TimerFound].Status == "paused") then
		-- Timer is already paused.
		return false, "Timer already paused.";
	end
end

function Timer.GetInformation(Name)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	
	-- Check timer existance.
	local TimerFound = false;
	
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			TimerFound = K;
			break;
		end
	end
	
	-- If timer not found..
	if not (TimerFound) then
		return false, "Timer does not exist.";
	end
	
	-- Make things easier to type.
	local DataTable = Timer.Stored[TimerFound];
	
	return {ID = TimerFound, Name = DataTable.Name, Status = DataTable.Status, Interval = DataTable.Interval, Repetitions = DataTable.Repetitions, Function = DataTable.Function, Arguments = DataTable.Arguments};
end

function Timer.DoesExist(Name)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	
	-- Check timer existance.
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			return true;
		end
	end
	
	return false;
end

function Timer.ResetTimer(Name)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	
	-- Check timer existance.
	local TimerFound = false;
	
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			TimerFound = K;
			break;
		end
	end
	
	-- If timer not found..
	if not (TimerFound) then
		return false, "Timer does not exist.";
	end
	
	-- Reset ticks.
	Timer.Stored[TimerFound].Ticks = 0;
	Debug.Print("Timer.ResetTimer: Reset timer ticks for '"..Timer.Stored[TimerFound].Name.."'.\r\n");
	return true;
end

function Timer.ToggleTimer(Name)
	-- Check function arguments.
	assert(type(Name) == "string", "Argument 1 must be of type string.");
	
	-- Check timer existance.
	local TimerFound = false;
	
	for K, V in pairs(Timer.Stored) do
		if (V.Name == Name) then
			TimerFound = K;
			break;
		end
	end
	
	-- If timer not found..
	if not (TimerFound) then
		return false, "Timer does not exist.";
	end
	
	-- Check state.
	if (Timer.Stored[TimerFound].Status == "active") then
		-- Pause timer.
		Debug.Print("Timer.ToggleTimer: Pausing active timer '"..Timer.Stored[TimerFound].Name.."'.\r\n");
		return Timer.PauseTimer(Timer.Stored[TimerFound].Name);
	else
		-- Start timer.
		Debug.Print("Timer.ToggleTimer: Starting paused timer '"..Timer.Stored[TimerFound].Name.."'.\r\n");
		return Timer.StartTimer(Timer.Stored[TimerFound].Name);
	end
end
