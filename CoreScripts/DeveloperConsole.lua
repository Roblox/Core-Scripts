local Create = assert(LoadLibrary("RbxUtility").Create)

if script.Parent:FindFirstChild("ControlFrame") then
	gui = script.Parent:FindFirstChild("ControlFrame")
else
	gui = script.Parent
end

local Dev_Container = Create'Frame'{
	Name = 'DevConsoleContainer';
	Parent = Instance.new("ScreenGui",game.Players.LocalPlayer.PlayerGui);
	BackgroundColor3 = Color3.new(0,0,0);
	BackgroundTransparency = 0.9;
	Position = UDim2.new(0, 100, 0, 10);
	Size = UDim2.new(0.5, 20, 0.5, 20);
	Visible = false;
	BackgroundTransparency = 0.9;
}

local Explorer_Panel = Create'Frame'{
	Name = "ExplorerPanel";
	Position = UDim2.new(0.1,2,0.1,26);
	Size = UDim2.new(0.8,-4,0.8,-28);
	BackgroundColor3 = Color3.new(1,1,1);
	Parent = Dev_Container;
	Visible = false;
	ZIndex = 2;
};

local ToggleConsole = Create'BindableFunction'{
	Name = 'ToggleDevConsole';
	Parent = gui
}

local ToggleExplorer = Create'BindableFunction'{
	Name = 'ToggleExplorer';
	Parent = gui;
}


local devConsoleInitialized = false
local explorerToggled = false

function initializeDeveloperConsole()
	if devConsoleInitialized then
		return
	end
	devConsoleInitialized = true

	---Dev-Console Variables
	local LOCAL_CONSOLE = 1
	local SERVER_CONSOLE = 2
	local SERVER_STATS = 3
	local EXPLORER_PANEL = 4

	local MAX_LIST_SIZE = 1000

	local minimumSize = Vector2.new(643, 180)
	local currentConsole = LOCAL_CONSOLE

	local localMessageList = {}
	local serverMessageList = {}

	local localOffset = 0
	local serverOffset = 0
	local serverStatsOffset = 0
	local explorerPanelOffset = 0
	
	local errorToggleOn = true
	local warningToggleOn = true
	local infoToggleOn = true
	local outputToggleOn = true
	local wordWrapToggleOn = false
	
	local textHolderSize = 0
	
	local frameNumber = 0

	--Create Dev-Console

	local Dev_Body = Create'Frame'{
		Name = 'Body';
		Parent = Dev_Container;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.5;
		Position = UDim2.new(0, 0, 0, 21);
		Size = UDim2.new(1, 0, 1, -25);
	}
	
	local Dev_OptionsHolder = Create'Frame'{
		Name = 'OptionsHolder';
		Parent = Dev_Body;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 1.0;
		Position = UDim2.new(0, 409, 0, 0);
		Size = UDim2.new(1, -355, 0, 24);
		ClipsDescendants = true
	}
	
	local Dev_OptionsBar = Create'Frame'{
		Name = 'OptionsBar';
		Parent = Dev_OptionsHolder;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 1.0;
		Position = UDim2.new(0.0, -250, 0, 4);
		Size = UDim2.new(0, 234, 0, 18);
	}
	
	local Dev_ErrorToggleFilter = Create'TextButton'{
		Name = 'ErrorToggleButton';
		Parent = Dev_OptionsBar;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1.0, 0, 0);
		Position = UDim2.new(0, 115, 0, 0);
		Size = UDim2.new(0, 18, 0, 18);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "";
		TextColor3 = Color3.new(1.0, 0, 0);
	}	
	
	Create'Frame'{
		Name = 'CheckFrame';
		Parent = Dev_ErrorToggleFilter;
		BackgroundColor3 = Color3.new(1.0,0,0);
		BorderColor3 = Color3.new(1.0, 0, 0);
		Position = UDim2.new(0, 4, 0, 4);
		Size = UDim2.new(0, 10, 0, 10);
	}
	
	local Dev_InfoToggleFilter = Create'TextButton'{
		Name = 'InfoToggleButton';
		Parent = Dev_OptionsBar;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(0.4, 0.5, 1.0);
		Position = UDim2.new(0, 65, 0, 0);
		Size = UDim2.new(0, 18, 0, 18);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "";
		TextColor3 = Color3.new(0.4, 0.5, 1.0);
	}
	
	Create'Frame'{
		Name = 'CheckFrame';
		Parent = Dev_InfoToggleFilter;
		BackgroundColor3 = Color3.new(0.4, 0.5, 1.0);
		BorderColor3 = Color3.new(0.4, 0.5, 1.0);
		Position = UDim2.new(0, 4, 0, 4);
		Size = UDim2.new(0, 10, 0, 10);
	}
	
	local Dev_OutputToggleFilter = Create'TextButton'{
		Name = 'OutputToggleButton';
		Parent = Dev_OptionsBar;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1.0, 1.0, 1.0);
		Position = UDim2.new(0, 40, 0, 0);
		Size = UDim2.new(0, 18, 0, 18);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "";
		TextColor3 = Color3.new(1.0, 1.0, 1.0);
	}
	
	Create'Frame'{
		Name = 'CheckFrame';
		Parent = Dev_OutputToggleFilter;
		BackgroundColor3 = Color3.new(1.0, 1.0, 1.0);
		BorderColor3 = Color3.new(1.0, 1.0, 1.0);
		Position = UDim2.new(0, 4, 0, 4);
		Size = UDim2.new(0, 10, 0, 10);
	}
	
	local Dev_WarningToggleFilter = Create'TextButton'{
		Name = 'WarningToggleButton';
		Parent = Dev_OptionsBar;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(1.0, 0.6, 0.4);
		Position = UDim2.new(0, 90, 0, 0);
		Size = UDim2.new(0, 18, 0, 18);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "";
		TextColor3 = Color3.new(1.0, 0.6, 0.4);
	}
	
	Create'Frame'{
		Name = 'CheckFrame';
		Parent = Dev_WarningToggleFilter;
		BackgroundColor3 = Color3.new(1.0, 0.6, 0.4);
		BorderColor3 = Color3.new(1.0, 0.6, 0.4);
		Position = UDim2.new(0, 4, 0, 4);
		Size = UDim2.new(0, 10, 0, 10);
	}
	
	local Dev_WordWrapToggle = Create'TextButton'{
		Name = 'WordWrapToggleButton';
		Parent = Dev_OptionsBar;
		BackgroundColor3 = Color3.new(0,0,0);
		BorderColor3 = Color3.new(0.8, 0.8, 0.8);
		Position = UDim2.new(0, 215, 0, 0);
		Size = UDim2.new(0, 18, 0, 18);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "";
		TextColor3 = Color3.new(0.8, 0.8, 0.8);
	}
	
	Create'Frame'{
		Name = 'CheckFrame';
		Parent = Dev_WordWrapToggle;
		BackgroundColor3 = Color3.new(0.8, 0.8, 0.8);
		BorderColor3 = Color3.new(0.8, 0.8, 0.8);
		Position = UDim2.new(0, 4, 0, 4);
		Size = UDim2.new(0, 10, 0, 10);
		Visible = false
	}
	
	Create'TextLabel'{
		Name = 'Filter';
		Parent = Dev_OptionsBar;
		BackgroundTransparency = 1.0;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(0, 40, 0, 18);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "Filter";
		TextColor3 = Color3.new(1, 1, 1);
	}
	
	Create'TextLabel'{
		Name = 'WordWrap';
		Parent = Dev_OptionsBar;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 150, 0, 0);
		Size = UDim2.new(0, 50, 0, 18);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "Word Wrap";
		TextColor3 = Color3.new(1, 1, 1);
	}

	local Dev_ScrollBar = Create'Frame'{
		Name = 'ScrollBar';
		Parent = Dev_Body;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.9;
		Position = UDim2.new(1, -20, 0, 26);
		Size = UDim2.new(0, 20, 1, -50);
		Visible = false;
		BackgroundTransparency = 0.9;
	}

	local Dev_ScrollArea = Create'Frame'{
		Name = 'ScrollArea';
		Parent = Dev_ScrollBar;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 0, 23);
		Size = UDim2.new(1, 0, 1, -46);
		BackgroundTransparency = 1;
	}

	local Dev_Handle = Create'ImageButton'{
		Name = 'Handle';
		Parent = Dev_ScrollArea;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.5;
		Position = UDim2.new(0, 0, .2, 0);
		Size = UDim2.new(0, 20, 0, 40);
		BackgroundTransparency = 0.5;
	}
	
	Create'ImageLabel'{
		Name = 'ImageLabel';
		Parent = Dev_Handle;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 0.5, -8);
		Rotation = 180;
		Size = UDim2.new(1, 0, 0, 16);
		Image = "http://www.roblox.com/Asset?id=151205881";
	}

	local Dev_DownButton = Create'ImageButton'{
		Name = 'Down';
		Parent = Dev_ScrollBar;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.5;
		Position = UDim2.new(0, 0, 1, -20);
		Size = UDim2.new(0, 20, 0, 20);
		BackgroundTransparency = 0.5;
	}

	Create'ImageLabel'{
		Name = 'ImageLabel';
		Parent = Dev_DownButton;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 3, 0, 3);
		Size = UDim2.new(0, 14, 0, 14);
		Rotation = 180;
		Image = "http://www.roblox.com/Asset?id=151205813";
	}

	local Dev_UpButton = Create'ImageButton'{
		Name = 'Up';
		Parent = Dev_ScrollBar;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.5;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(0, 20, 0, 20);
	}

	Create'ImageLabel'{
		Name = 'ImageLabel';
		Parent = Dev_UpButton;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 3, 0, 3);
		Size = UDim2.new(0, 14, 0, 14);
		Image = "http://www.roblox.com/Asset?id=151205813";
	}
	
	local flagExists, flagValue = pcall(function () return settings():GetFFlag("ConsoleCodeExecutionEnabled") end)
	local codeExecutionEnabled = flagExists and flagValue
	local isCreator = game.Players.LocalPlayer.userId == game.CreatorId
	local function shouldShowCommandBar()
		return codeExecutionEnabled and isCreator
	end
	local function getCommandBarOffset()
		return shouldShowCommandBar() and currentConsole == SERVER_CONSOLE and -22 or 0
	end
	
	local Dev_TextBox = Create'Frame'{
		Name = 'TextBox';
		Parent = Dev_Body;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.6;
		Position = UDim2.new(0, 2, 0, 26);
		Size = UDim2.new(1, -4, 1, -28);
		ClipsDescendants = true;
	}

	local Dev_TextHolder = Create'Frame'{
		Name = 'TextHolder';
		Parent = Dev_TextBox;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
	}
	
	local Dev_OptionsButton = Create'ImageButton'{
		Name = 'OptionsButton';
		Parent = Dev_Body;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 1.0;
		Position = UDim2.new(0, 390, 0, 2);
		Size = UDim2.new(0, 20, 0, 20);
	}
	
	Create'ImageLabel'{
		Name = 'ImageLabel';
		Parent = Dev_OptionsButton;
		BackgroundTransparency = 1.0;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 1, 0);
		Rotation = 0;
		Image = "http://www.roblox.com/Asset?id=152093917";
	}
	
	local Dev_CommandBar = Create'Frame'{
		Name = "CommandBar";
		Parent = Dev_Container;
		BackgroundTransparency = 0;
		BackgroundColor3 = Color3.new(0, 0, 0);
		BorderSizePixel = 0;
		Size = UDim2.new(1, -25, 0, 24);
		Position = UDim2.new(0, 2, 1, -28);
		Visible = false;
		ZIndex = 2;
		BorderSizePixel = 0;
	}
	
	local Dev_CommandBarTextBox = Create'TextBox'{
		Name = 'CommandBarTextBox';
		Parent = Dev_CommandBar;
		BackgroundTransparency = 1;
		MultiLine = false;
		ZIndex = 2;
		Position = UDim2.new(0, 25, 0, 2);
		Size = UDim2.new(1, -30, 0, 20);
		Font = Enum.Font.Legacy;
		FontSize = Enum.FontSize.Size10;
		TextColor3 = Color3.new(1, 1, 1);
		TextXAlignment = Enum.TextXAlignment.Left;
		TextYAlignment = Enum.TextYAlignment.Center;
		Text = "Code goes here";
	}
	
	Create'TextLabel'{
		Name = "PromptLabel";
		Parent = Dev_CommandBar;
		BackgroundTransparency = 1;
		Size = UDim2.new(0, 20, 1, 0);
		Position = UDim2.new(0, 5, 0, 0);
		Font = Enum.Font.Legacy;
		FontSize = Enum.FontSize.Size10;
		TextColor3 = Color3.new(1, 1, 1);
		TextXAlignment = Enum.TextXAlignment.Center;
		TextYAlignment = Enum.TextYAlignment.Center;
		ZIndex = 2;
		Text = ">";
	}
	
	Dev_CommandBarTextBox.FocusLost:connect(function(enterPressed)
		if enterPressed then
			local code = Dev_CommandBarTextBox.Text
			game:GetService("LogService"):ExecuteScript(code)
			Dev_CommandBarTextBox.Text = ""
			
			-- scroll to the bottom of the console
			serverOffset = 0
			Dev_CommandBarTextBox:CaptureFocus()
		end
	end)
	
	local Dev_ResizeButton = Create'ImageButton'{
		Name = 'ResizeButton';
		Parent = Dev_Body;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.5;
		Position = UDim2.new(1, -20, 1, -20);
		Size = UDim2.new(0, 20, 0, 20);
	}
	
	Create'ImageLabel'{
		Name = 'ImageLabel';
		Parent = Dev_ResizeButton;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 6, 0, 6);
		Size = UDim2.new(0.8, 0, 0.8, 0);
		Rotation = 135;
		Image = "http://www.roblox.com/Asset?id=151205813";
	}

	Create'TextButton'{
		Name = 'LocalConsole';
		Parent = Dev_Body;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.6;
		Position = UDim2.new(0, 7, 0, 5);
		Size = UDim2.new(0, 90, 0, 20);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "Local Console";
		TextColor3 = Color3.new(1, 1, 1);
		TextYAlignment = Enum.TextYAlignment.Center;
	}

	Create'TextButton'{
		Name = 'ServerConsole';
		Parent = Dev_Body;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.8;
		Position = UDim2.new(0, 102, 0, 5);
		Size = UDim2.new(0, 90, 0, 17);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "Server Console";
		TextColor3 = Color3.new(1, 1, 1);
		TextYAlignment = Enum.TextYAlignment.Center;
	}

	Create'TextButton'{
		Name = 'ServerStats';
		Parent = Dev_Body;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.8;
		Position = UDim2.new(0, 197, 0, 5);
		Size = UDim2.new(0, 90, 0, 17);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "Server Stats";
		TextColor3 = Color3.new(1, 1, 1);
		TextYAlignment = Enum.TextYAlignment.Center;
	}
	
	Create'TextButton'{
		Name = 'ExplorerPanel';
		Parent = Dev_Body;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.8;
		Position = UDim2.new(0, 292, 0, 5);
		Size = UDim2.new(0, 90, 0, 17);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		Text = "Explorer Panel";
		TextColor3 = Color3.new(1, 1, 1);
		TextYAlignment = Enum.TextYAlignment.Center;
	}

	local Dev_TitleBar = Create'Frame'{
		Name = 'TitleBar';
		Parent = Dev_Container;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.5;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 0, 20);
	}

	local Dev_CloseButton = Create'ImageButton'{
		Name = 'CloseButton';
		Parent = Dev_TitleBar;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.5;
		Position = UDim2.new(1, -20, 0, 0);
		Size = UDim2.new(0, 20, 0, 20);
	}
	
	Create'ImageLabel'{
		Parent = Dev_CloseButton;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 3, 0, 3);
		Size = UDim2.new(0, 14, 0, 14);
		Image = "http://www.roblox.com/Asset?id=151205852";
	}

	Create'TextButton'{
		Name = 'TextButton';
		Parent = Dev_TitleBar;
		BackgroundColor3 = Color3.new(0,0,0);
		BackgroundTransparency = 0.5;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, -23, 1, 0);
		Text = "";
	}

	Create'TextLabel'{
		Name = 'TitleText';
		Parent = Dev_TitleBar;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(0, 185, 0, 20);
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size18;
		Text = "Server Console";
		TextColor3 = Color3.new(1, 1, 1);
		Text = "Roblox Developer Console";
		TextYAlignment = Enum.TextYAlignment.Top;
	}
	
	local Dev_StatsChartFrame = Create'Frame'{
		Name = 'ChartFrame';
		BackgroundColor3 = Color3.new(0, 0, 0);
		BackgroundTransparency = 0.5;
		BorderColor3 = Color3.new(1.0, 1.0, 1.0);
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(0, 250, 0, 100);
	}
	
	Create'TextLabel'{
		Name = 'TitleText';
		Parent = Dev_StatsChartFrame;
		BackgroundTransparency = 0.5;
		BackgroundColor3 = Color3.new(255,0,0);
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(1, 0, 0, 15);
		Text = "";
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		TextColor3 = Color3.new(1, 1, 1);
		TextYAlignment = Enum.TextYAlignment.Top;
	}
	
	Create'TextLabel'{
		Name = 'ChartValue';
		Parent = Dev_StatsChartFrame;
		BackgroundTransparency = 1.0;
		BackgroundColor3 = Color3.new(0,0,0);
		Position = UDim2.new(0, 5, 0, 39);
		Size = UDim2.new(0, 100, 0, 15);
		Text = "";
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		TextColor3 = Color3.new(1, 1, 1);
		TextYAlignment = Enum.TextYAlignment.Top;
		TextXAlignment = Enum.TextXAlignment.Left;
	}
	
	Create'TextLabel'{
		Name = 'ChartMaxValue';
		Parent = Dev_StatsChartFrame;
		BackgroundTransparency = 1.0;
		BackgroundColor3 = Color3.new(0,0,0);
		Position = UDim2.new(0, 5, 0, 15);
		Size = UDim2.new(0, 100, 0, 15);
		Text = "Max: ";
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		TextColor3 = Color3.new(1, 1, 1);
		TextYAlignment = Enum.TextYAlignment.Top;
		TextXAlignment = Enum.TextXAlignment.Left;
	}
	
	Create'TextLabel'{
		Name = 'ChartMinValue';
		Parent = Dev_StatsChartFrame;
		BackgroundTransparency = 1.0;
		BackgroundColor3 = Color3.new(0,0,0);
		Position = UDim2.new(0, 5, 0, 27);
		Size = UDim2.new(0, 100, 0, 15);
		Text = "Min: ";
		Font = "SourceSansBold";
		FontSize = Enum.FontSize.Size14;
		TextColor3 = Color3.new(1, 1, 1);
		TextYAlignment = Enum.TextYAlignment.Top;
		TextXAlignment = Enum.TextXAlignment.Left;
	}
	
	local Dev_StatsChartBar = Create'TextLabel'{
		Name = 'StatsChartBar';
		BackgroundColor3 = Color3.new(0,255,0);
		Position = UDim2.new(0, 0, 0, 52);
		Size = UDim2.new(0, 5, 0, 40);
		Text = "";
	}

	---Saved Mouse Information
	local previousMousePos = nil
	local pPos = nil

	local previousMousePosResize = nil
	local pSize = nil

	local previousMousePosScroll = nil
	local pScrollHandle = nil
	local pOffset = nil

	local scrollUpIsDown = false
	local scrollDownIsDown = false

	function clean()
		previousMousePos = nil
		pPos = nil
		previousMousePosResize = nil
		pSize = nil
		previousMousePosScroll = nil
		pScrollHandle = nil
		pOffset = nil
		scrollUpIsDown = false
		scrollDownIsDown = false
	end

	-- Set up server stat charts
	local numBars = 40
	local numCharts = 0
	local charts = {}
	local statsListenerConnection = nil
	
	function initStatsListener()
		if (statsListenerConnection == nil) then
			game.NetworkClient:GetChildren()[1]:RequestServerStats(true)
			statsListenerConnection = game.NetworkClient:GetChildren()[1].StatsReceived:connect(refreshCharts)
		end
	end
	
	function removeStatsListener()
		if (statsListenerConnection ~= nil) then
			game.NetworkClient:GetChildren()[1]:RequestServerStats(false)
			statsListenerConnection:disconnect()
			statsListenerConnection = nil
		end
	end
	
	function createChart(_frame)
		local chart = {
			frame = _frame,
			values = {},
			bars = {},
			curIndex = 0
		}
		return chart
	end
	
	function setupCharts(name)
		local newChart = createChart(Dev_StatsChartFrame:Clone())
		newChart.frame.Parent = Dev_TextHolder
		newChart.frame.TitleText.Text = name
		local newPos = 5 + numCharts * 110
		newChart.frame.Position = UDim2.new(0, 5, 0, newPos);
		for i = 1, numBars do
			local bar = Dev_StatsChartBar:Clone()
			bar.Position = UDim2.new(bar.Position.X.Scale, i * (bar.Size.X.Offset + 1), bar.Position.Y.Scale, bar.Position.Y.Offset)
			bar.Parent = newChart.frame
			table.insert(newChart.bars, bar)
		end

		charts[name] = newChart
		numCharts = numCharts + 1
		textHolderSize = newPos + 110
	end
	
	function clearCharts()
		for i, chart in pairs(charts) do
			chart.frame.Parent = nil
			charts[i] = nil
		end
		numCharts = 0
	end
	
	function refreshCharts(stats)
		for name, stat in pairs(stats) do
			if (charts[name] == nil) then
				setupCharts(name)
			end
			
			local chart = charts[name]
			chart.curIndex = chart.curIndex + 1
			
			-- remove old data
			if chart.curIndex > numBars + 1 then
				chart.curIndex = numBars + 1
				table.remove(chart.values, 1)
			end
			
			chart.values[chart.curIndex] = stat
			
			updateChart(chart)
		end
	end

	function updateChart(chart)
		local maxValue = .0001
		local minValue = chart.values[chart.curIndex]

		for i = chart.curIndex, chart.curIndex-numBars, -1 do
			if i == 0 then break end
			if chart.values[i] > maxValue then maxValue = chart.values[i] end
			if chart.values[i] < minValue then minValue = chart.values[i] end
		end
		
		chart.frame.ChartValue.Text = "Current: "..chart.values[chart.curIndex]
		chart.frame.ChartMaxValue.Text = "Max: "..maxValue
		chart.frame.ChartMinValue.Text = "Min: "..minValue

		for i = 1,numBars do

			if chart.curIndex - i + 1 < 1 then 
				chart.bars[i].BackgroundTransparency = 1
			else
				chart.bars[i].BackgroundTransparency = 0

				chart.bars[i].Size = UDim2.new(chart.bars[i].Size.X.Scale, chart.bars[i].Size.X.Offset, chart.bars[i].Size.Y.Scale, 
					Dev_StatsChartBar.Size.Y.Offset * (chart.values[chart.curIndex - i + 1] / maxValue))
		
				chart.bars[i].Position = UDim2.new(chart.bars[i].Position.X.Scale, chart.bars[i].Position.X.Offset, Dev_StatsChartBar.Position.Y.Scale,
					Dev_StatsChartBar.Position.Y.Offset + (45 - chart.bars[i].Size.Y.Offset))
			end

		end
	end
	
	---Handle Dev-Console Position
	function refreshConsolePosition(x, y)
		if not previousMousePos then
			return
		end
		
		local delta = Vector2.new(x, y) - previousMousePos
		Dev_Container.Position = UDim2.new(0, pPos.X + delta.X, 0, pPos.Y + delta.Y)
	end
	
	

	Dev_TitleBar.TextButton.MouseButton1Down:connect(function(x, y)
		previousMousePos = Vector2.new(x, y)
		pPos = Dev_Container.AbsolutePosition
	end)

	Dev_TitleBar.TextButton.MouseButton1Up:connect(function(x, y)
		clean()
	end)

	---Handle Dev-Console Size
	function refreshConsoleSize(x, y)
		if not previousMousePosResize then
			return
		end
		
		local delta = Vector2.new(x, y) - previousMousePosResize
		Dev_Container.Size = UDim2.new(0, math.max(pSize.X + delta.X, minimumSize.X), 0, math.max(pSize.Y + delta.Y, minimumSize.Y))
	end
	Dev_Container.Body.ResizeButton.MouseButton1Down:connect(function(x, y)
		previousMousePosResize = Vector2.new(x, y)
		pSize = Dev_Container.AbsoluteSize
	end)

	Dev_Container.Body.ResizeButton.MouseButton1Up:connect(function(x, y)
		clean()
	end)


	---Handle Dev-Console Close Button
	Dev_TitleBar.CloseButton.MouseButton1Down:connect(function(x, y)
		Dev_Container.Visible = false
	end)

	Dev_Container.TitleBar.CloseButton.MouseButton1Up:connect(function()
		clean()
		removeStatsListener()
		clearCharts() 
	end)
	
	local optionsHidden = true
	local animating = false
	--Options
	function startAnimation()
		if animating then return end
		animating = true
		
		repeat
			if optionsHidden then
				frameNumber = frameNumber - 1
			else
				frameNumber = frameNumber + 1
			end
			
			local x = frameNumber / 5
			local smoothStep = x * x * (3 - (2 * x))
			Dev_OptionsButton.ImageLabel.Rotation = smoothStep * 5 * 9
			Dev_OptionsBar.Position = UDim2.new(0, (smoothStep * 5 * 50) - 250, 0, 4)
			
			wait()
			if (frameNumber <= 0 and optionsHidden) or (frameNumber >= 5 and not optionsHidden) then
				animating = false
			end
		until not animating
	end
	
	Dev_OptionsButton.MouseButton1Down:connect(function(x, y)
		optionsHidden = not optionsHidden
		startAnimation()
	end)
	
	--Scroll Position
	
	function changeOffset(value)
		if (currentConsole == LOCAL_CONSOLE) then
			localOffset = localOffset + value
		elseif (currentConsole == SERVER_CONSOLE) then
			serverOffset = serverOffset + value
		elseif (currentConsole == SERVER_STATS) then
			serverStatsOffset = serverStatsOffset + value
		elseif (currentConsole == EXPLORER_PANEL) then
			explorerPanelOffset = explorerPanelOffset + value
		end
		
		repositionList()
	end

	--Refresh Dev-Console Text
	function refreshTextHolderForReal()
		local childMessages = Dev_TextHolder:GetChildren()
		
		local messageList = {}
		
		if (currentConsole == LOCAL_CONSOLE) then
			messageList = localMessageList
		elseif (currentConsole == SERVER_CONSOLE) then
			messageList = serverMessageList
		end
		
		local posOffset = 0

		for i = 1, #childMessages do
			childMessages[i].Visible = false
		end
		
		for i = 1, #messageList do
			local message
			
			local movePosition = false
			
			if i > #childMessages then
				message = Create'TextLabel'{
					Name = 'Message';
					Parent = Dev_TextHolder;
					BackgroundTransparency = 1;
					TextXAlignment = 'Left';
					Size = UDim2.new(1, 0, 0, 14);
					FontSize = 'Size10';
					ZIndex = 1;
				}
				movePosition = true
			else
				message = childMessages[i]
			end
			
			if (outputToggleOn or messageList[i].Type ~= Enum.MessageType.MessageOutput) and
			   (infoToggleOn or messageList[i].Type ~= Enum.MessageType.MessageInfo) and
			   (warningToggleOn or messageList[i].Type ~= Enum.MessageType.MessageWarning) and
			   (errorToggleOn or messageList[i].Type ~= Enum.MessageType.MessageError) then
				message.TextWrapped = wordWrapToggleOn
				message.Size = UDim2.new(0.98, 0, 0, 2000)
				message.Parent = Dev_Container
				message.Text = messageList[i].Time.." -- "..messageList[i].Message
							
				message.Size = UDim2.new(0.98, 0, 0, message.TextBounds.Y)
				message.Position = UDim2.new(0, 5, 0, posOffset)
				message.Parent = Dev_TextHolder
				posOffset = posOffset + message.TextBounds.Y
								
				if movePosition then
					if (currentConsole == LOCAL_CONSOLE and localOffset > 0) or (currentConsole == SERVER_CONSOLE and serverOffset > 0) then
						changeOffset(message.TextBounds.Y)
					end
				end
				
				message.Visible = true
			
				if messageList[i].Type == Enum.MessageType.MessageError then
					message.TextColor3 = Color3.new(1, 0, 0)
				elseif messageList[i].Type == Enum.MessageType.MessageInfo then
					message.TextColor3 = Color3.new(0.4, 0.5, 1)
				elseif messageList[i].Type == Enum.MessageType.MessageWarning then
					message.TextColor3 = Color3.new(1, 0.6, 0.4)
				else
					message.TextColor3 = Color3.new(1, 1, 1)
				end
			end
			
			
		end
		
		textHolderSize = posOffset
		
		repositionList()
		
	end

	-- Refreshing the textholder every 0.1 (if needed) is good enough, surely fast enough
	-- We don't want it to update 50x in a tick because there are 50 messages in that tick
	-- (Whenever for one reason or another a lot of output comes in, it can lag
	--	This will make it behave better in a situation of a lot of output comming in)
	local refreshQueued = false
	function refreshTextHolder()
		if refreshQueued or currentConsole == SERVER_STATS then return end
		Delay(0.1,function()
			refreshQueued = false
			refreshTextHolderForReal()
		end) refreshQueued = true
	end

	--Handle Dev-Console Scrollbar

	local inside = 0
	function holdingUpButton()
		if scrollUpIsDown then
			return
		end
		scrollUpIsDown = true
		wait(.6)
		inside = inside + 1
		while scrollUpIsDown and inside < 2 do
			wait()
			changeOffset(12)
		end
		inside = inside - 1
	end

	function holdingDownButton()
		if scrollDownIsDown then
			return
		end
		scrollDownIsDown = true
		wait(.6)
		inside = inside + 1
		while scrollDownIsDown and inside < 2 do
			wait()
			changeOffset(-12)
		end
		inside = inside - 1
	end

	Dev_Container.Body.ScrollBar.Up.MouseButton1Click:connect(function()
		changeOffset(10)
	end)

	Dev_Container.Body.ScrollBar.Up.MouseButton1Down:connect(function()
		changeOffset(10)
		holdingUpButton()
	end)

	Dev_Container.Body.ScrollBar.Up.MouseButton1Up:connect(function()
		clean()
	end)

	Dev_Container.Body.ScrollBar.Down.MouseButton1Down:connect(function()
		changeOffset(-10)
		holdingDownButton()
	end)

	Dev_Container.Body.ScrollBar.Down.MouseButton1Up:connect(function()
		clean()
	end)

	function handleScroll(x, y)
		if not previousMousePosScroll then
			return
		end
		
		local delta = (Vector2.new(x, y) - previousMousePosScroll).Y
		
		local backRatio = 1 - (Dev_Container.Body.TextBox.AbsoluteSize.Y / Dev_TextHolder.AbsoluteSize.Y)
		
		local movementSize = Dev_ScrollArea.AbsoluteSize.Y - Dev_ScrollArea.Handle.AbsoluteSize.Y
		local normalDelta = math.max(math.min(delta, movementSize), 0 - movementSize)
		local normalRatio = normalDelta / movementSize
		
		local textMovementSize = (backRatio * Dev_TextHolder.AbsoluteSize.Y)
		local offsetChange = textMovementSize * normalRatio
		
		if (currentConsole == LOCAL_CONSOLE) then
			localOffset = pOffset - offsetChange
		elseif (currentConsole == SERVER_CONSOLE) then
			serverOffset = pOffset - offsetChange
		elseif (currentConsole == SERVER_STATS) then
			serverStatsOffset = pOffset - offsetChange
		end
	end

	Dev_ScrollArea.Handle.MouseButton1Down:connect(function(x, y)
		previousMousePosScroll = Vector2.new(x, y)
		pScrollHandle = Dev_ScrollArea.Handle.AbsolutePosition
		if (currentConsole == LOCAL_CONSOLE) then
			pOffset = localOffset
		elseif (currentConsole == SERVER_CONSOLE) then
			pOffset = serverOffset
		elseif (currentConsole == SERVER_STATS) then
			pOffset = serverStatsOffset
		elseif (currentConsole == EXPLORER_PANEL) then
			pOffset = serverStatsOffset
		end
		
	end)

	Dev_ScrollArea.Handle.MouseButton1Up:connect(function(x, y)
		clean()
	end)
	
	local function existsInsideContainer(container, x, y)
		local pos = container.AbsolutePosition
		local size = container.AbsoluteSize
		if x < pos.X or x > pos.X + size.X or y < pos.y or y > pos.y + size.y then
			return false
		end
		return true
	end



	--Refresh Dev-Console Message Positions
	function repositionList()
		
		if (currentConsole == LOCAL_CONSOLE) then
			localOffset = math.min(math.max(localOffset, 0), textHolderSize - Dev_Container.Body.TextBox.AbsoluteSize.Y)
			Dev_TextHolder.Size = UDim2.new(1, 0, 0, textHolderSize)
		elseif (currentConsole == SERVER_CONSOLE) then
			serverOffset = math.min(math.max(serverOffset, 0), textHolderSize - Dev_Container.Body.TextBox.AbsoluteSize.Y)
			Dev_TextHolder.Size = UDim2.new(1, 0, 0, textHolderSize)
		elseif (currentConsole == SERVER_STATS) then
			serverStatsOffset = math.min(math.max(serverStatsOffset, 0), textHolderSize - Dev_Container.Body.TextBox.AbsoluteSize.Y)
			Dev_TextHolder.Size = UDim2.new(1, 0, 0, textHolderSize)
		elseif (currentConsole == EXPLORER_PANEL) then
			serverStatsOffset = math.min(math.max(explorerPanelOffset, 0), textHolderSize - Dev_Container.Body.TextBox.AbsoluteSize.Y)
			Dev_TextHolder.Size = UDim2.new(1, 0, 0, textHolderSize)
		end
			
		local ratio = Dev_Container.Body.TextBox.AbsoluteSize.Y / Dev_TextHolder.AbsoluteSize.Y

		if ratio >= 1 then
			Dev_Container.Body.ScrollBar.Visible = false
			Dev_Container.Body.TextBox.Size = UDim2.new(1, -4, 1, -28 + getCommandBarOffset())
			
			if (currentConsole == LOCAL_CONSOLE) then
				Dev_TextHolder.Position = UDim2.new(0, 0, 1, 0 - textHolderSize)
			elseif (currentConsole == SERVER_CONSOLE) then
				Dev_TextHolder.Position = UDim2.new(0, 0, 1, 0 - textHolderSize)
			end
			
			
		else
			Dev_Container.Body.ScrollBar.Visible = true
			Dev_Container.Body.TextBox.Size = UDim2.new(1, -25, 1, -28 + getCommandBarOffset())
			
			local backRatio = 1 - ratio
			local offsetRatio
			
			if (currentConsole == LOCAL_CONSOLE) then
				offsetRatio = localOffset / Dev_TextHolder.AbsoluteSize.Y
			elseif (currentConsole == SERVER_CONSOLE) then
				offsetRatio = serverOffset / Dev_TextHolder.AbsoluteSize.Y
			elseif (currentConsole == SERVER_STATS) then
				offsetRatio = (serverStatsOffset / Dev_TextHolder.AbsoluteSize.Y)
			elseif (currentConsole == EXPLORER_PANEL) then
				offsetRatio = (explorerPanelOffset / Dev_TextHolder.AbsoluteSize.Y)
			end

			local topRatio = math.max(0, backRatio - offsetRatio)
			local scrollHandleSize = math.max((Dev_ScrollArea.AbsoluteSize.Y) * ratio, 21)
			
			local scrollRatio = scrollHandleSize / Dev_ScrollArea.AbsoluteSize.Y
			local ratioConversion = (1 - scrollRatio) / (1 - ratio)
			
			local topScrollRatio = topRatio * ratioConversion
					
			local sPos = math.min((Dev_ScrollArea.AbsoluteSize.Y) * topScrollRatio, Dev_ScrollArea.AbsoluteSize.Y - scrollHandleSize)
						
			Dev_ScrollArea.Handle.Size = UDim2.new(1, 0, 0, scrollHandleSize)
			Dev_ScrollArea.Handle.Position = UDim2.new(0, 0, 0, sPos)
			
			if (currentConsole == LOCAL_CONSOLE) then
				Dev_TextHolder.Position = UDim2.new(0, 0, 1, 0 - textHolderSize + localOffset)
			elseif (currentConsole == SERVER_CONSOLE) then
				Dev_TextHolder.Position = UDim2.new(0, 0, 1, 0 - textHolderSize + serverOffset)
			elseif (currentConsole == SERVER_STATS) then
				Dev_TextHolder.Position = UDim2.new(0, 0, 1, 0 - textHolderSize + serverStatsOffset)
			elseif (currentConsole == EXPLORER_PANEL) then
				Dev_TextHolder.Position = UDim2.new(0, 0, 1, 0 - textHolderSize + explorerPanelOffset)
			end
			
		end
	end
	
	-- Easy, fast, and working nicely
	local function numberWithZero(num)
		return (num < 10 and "0" or "")..num
	end
	
	local str = "%s:%s:%s"

	function ConvertTimeStamp(timeStamp)
		local localTime = timeStamp - os.time() + math.floor(tick())
		local dayTime = localTime % 86400
				
		local hour = math.floor(dayTime/3600)
		
		dayTime = dayTime - (hour * 3600)
		local minute = math.floor(dayTime/60)
		
		dayTime = dayTime - (minute * 60)
		local second = dayTime
		
		local h = numberWithZero(hour)
		local m = numberWithZero(minute)
		local s = numberWithZero(dayTime)

		return str:format(h,m,s)
	end
	
	--Filter
	
	Dev_OptionsBar.ErrorToggleButton.MouseButton1Down:connect(function(x, y)
		errorToggleOn = not errorToggleOn
		Dev_OptionsBar.ErrorToggleButton.CheckFrame.Visible = errorToggleOn
		refreshTextHolder()
	end)
	
	Dev_OptionsBar.WarningToggleButton.MouseButton1Down:connect(function(x, y)
		warningToggleOn = not warningToggleOn
		Dev_OptionsBar.WarningToggleButton.CheckFrame.Visible = warningToggleOn
		refreshTextHolder()
	end)
	
	Dev_OptionsBar.InfoToggleButton.MouseButton1Down:connect(function(x, y)
		infoToggleOn = not infoToggleOn
		Dev_OptionsBar.InfoToggleButton.CheckFrame.Visible = infoToggleOn
		refreshTextHolder()
	end)
	
	Dev_OptionsBar.OutputToggleButton.MouseButton1Down:connect(function(x, y)
		outputToggleOn = not outputToggleOn
		Dev_OptionsBar.OutputToggleButton.CheckFrame.Visible = outputToggleOn
		refreshTextHolder()
	end)
	
	Dev_OptionsBar.WordWrapToggleButton.MouseButton1Down:connect(function(x, y)
		wordWrapToggleOn = not wordWrapToggleOn
		Dev_OptionsBar.WordWrapToggleButton.CheckFrame.Visible = wordWrapToggleOn
		refreshTextHolder()
	end)

	---Dev-Console Message Functionality
	function AddLocalMessage(str, messageType, timeStamp)
		localMessageList[#localMessageList+1] = {Message = str, Time = ConvertTimeStamp(timeStamp), Type = messageType}
		while #localMessageList > MAX_LIST_SIZE do
			table.remove(localMessageList, 1)
		end
		
		refreshTextHolder()
	end

	function AddServerMessage(str, messageType, timeStamp)
		serverMessageList[#serverMessageList+1] = {Message = str, Time = ConvertTimeStamp(timeStamp), Type = messageType}
		while #serverMessageList > MAX_LIST_SIZE do
			table.remove(serverMessageList, 1)
		end
		
		refreshTextHolder()
	end

	--Handle Dev-Console Local/Server Buttons
	Dev_Container.Body.LocalConsole.MouseButton1Click:connect(function(x, y)
		if (currentConsole ~= LOCAL_CONSOLE) then
			
			if (currentConsole == SERVER_STATS) then 
				removeStatsListener()
				clearCharts() 
			end
			
			Dev_Container.CommandBar.Visible = false
			Explorer_Panel.Visible = false
			
			currentConsole = LOCAL_CONSOLE
			local localConsole = Dev_Container.Body.LocalConsole
			local serverConsole = Dev_Container.Body.ServerConsole
			local serverStats = Dev_Container.Body.ServerStats
			local explorerPanelButton = Dev_Container.Body.ExplorerPanel
			
			localConsole.Size = UDim2.new(0, 90, 0, 20)
			serverConsole.Size = UDim2.new(0, 90, 0, 17)
			serverStats.Size = UDim2.new(0, 90, 0, 17)
			explorerPanelButton.Size = UDim2.new(0, 90, 0, 17)
			localConsole.BackgroundTransparency = 0.6
			serverConsole.BackgroundTransparency = 0.8
			serverStats.BackgroundTransparency = 0.8
			explorerPanelButton.BackgroundTransparency = 0.8
			
			if game:FindFirstChild("Players") and game.Players["LocalPlayer"] then
				local mouse = game.Players.LocalPlayer:GetMouse()
				local mousePos = Vector2.new(mouse.X, mouse.Y)
				refreshConsolePosition(mouse.X, mouse.Y)
				refreshConsoleSize(mouse.X, mouse.Y)
				handleScroll(mouse.X, mouse.Y)
			end
			
			refreshTextHolder()			
		end
	end)

	Dev_Container.Body.LocalConsole.MouseButton1Up:connect(function()
		clean()
	end)
	
	local serverHistoryRequested = false;

	Dev_Container.Body.ServerConsole.MouseButton1Click:connect(function(x, y)
		
		if not serverHistoryRequested then
			serverHistoryRequested = true
			game:GetService("LogService"):RequestServerOutput()
		end
		
		if (currentConsole ~= SERVER_CONSOLE) then
			
			Dev_Container.CommandBar.Visible = shouldShowCommandBar()
			Explorer_Panel.Visible = false
			if (currentConsole == SERVER_STATS) then 
				removeStatsListener()
				clearCharts() 
			end
			
			currentConsole = SERVER_CONSOLE
			local localConsole = Dev_Container.Body.LocalConsole
			local serverConsole = Dev_Container.Body.ServerConsole
			local serverStats = Dev_Container.Body.ServerStats
			local explorerPanelButton = Dev_Container.Body.ExplorerPanel
			
			localConsole.Size = UDim2.new(0, 90, 0, 17)
			serverConsole.Size = UDim2.new(0, 90, 0, 20)
			serverStats.Size = UDim2.new(0, 90, 0, 17)
			explorerPanelButton.Size = UDim2.new(0, 90, 0, 17)
			localConsole.BackgroundTransparency = 0.8
			serverConsole.BackgroundTransparency = 0.6
			serverStats.BackgroundTransparency = 0.8
			explorerPanelButton.BackgroundTransparency = 0.8
			
			if game:FindFirstChild("Players") and game.Players["LocalPlayer"] then
				local mouse = game.Players.LocalPlayer:GetMouse()
				local mousePos = Vector2.new(mouse.X, mouse.Y)
				refreshConsolePosition(mouse.X, mouse.Y)
				refreshConsoleSize(mouse.X, mouse.Y)
				handleScroll(mouse.X, mouse.Y)
			end
			
			refreshTextHolder()
		end
	end)

	---Extra Mouse Handlers for Dev-Console
	Dev_Container.Body.ServerConsole.MouseButton1Up:connect(function()
		clean()
	end)

	Dev_Container.Body.ServerStats.MouseButton1Click:connect(function(x, y)
		if (currentConsole ~= SERVER_STATS) then
			
			Dev_Container.CommandBar.Visible = false
			Explorer_Panel.Visible = false
			
			currentConsole = SERVER_STATS
			local localConsole = Dev_Container.Body.LocalConsole
			local serverConsole = Dev_Container.Body.ServerConsole
			local serverStats = Dev_Container.Body.ServerStats
			local explorerPanelButton = Dev_Container.Body.ExplorerPanel
			
			localConsole.Size = UDim2.new(0, 90, 0, 17)
			serverConsole.Size = UDim2.new(0, 90, 0, 17)
			serverStats.Size = UDim2.new(0, 90, 0, 20)
			explorerPanelButton.Size = UDim2.new(0, 90, 0, 17)
			localConsole.BackgroundTransparency = 0.8
			serverConsole.BackgroundTransparency = 0.8
			serverStats.BackgroundTransparency = 0.6
			explorerPanelButton.BackgroundTransparency = 0.8
			
			-- clear holder of log entries
			local messages = Dev_TextHolder:GetChildren()
			for i = 1, #messages do
				messages[i].Visible = false
			end
			
			pcall(function() initStatsListener() end)

		end
	end)

	Dev_Container.Body.ServerStats.MouseButton1Up:connect(function()
		clean()
	end)
	
	Dev_Container.Body.ExplorerPanel.MouseButton1Click:connect(function(x, y)
		if (currentConsole ~= EXPLORER_PANEL) then
			
			if (currentConsole == SERVER_STATS) then 
				removeStatsListener()
				clearCharts() 
			end
			
			Dev_Container.CommandBar.Visible = shouldShowCommandBar()
			Explorer_Panel.Visible = shouldShowCommandBar()
			ToggleExplorer:Invoke()
			
			currentConsole = EXPLORER_PANEL
			local localConsole = Dev_Container.Body.LocalConsole
			local serverConsole = Dev_Container.Body.ServerConsole
			local serverStats = Dev_Container.Body.ServerStats
			local explorerPanelButton = Dev_Container.Body.ExplorerPanel
			
			localConsole.Size = UDim2.new(0, 90, 0, 17)
			serverConsole.Size = UDim2.new(0, 90, 0, 17)
			serverStats.Size = UDim2.new(0, 90, 0, 17)
			explorerPanelButton.Size = UDim2.new(0, 90, 0, 20)
			localConsole.BackgroundTransparency = 0.8
			serverConsole.BackgroundTransparency = 0.8
			serverStats.BackgroundTransparency = 0.8
			explorerPanelButton.BackgroundTransparency = 0.6
			
			if game:FindFirstChild("Players") and game.Players["LocalPlayer"] then
				local mouse = game.Players.LocalPlayer:GetMouse()
				local mousePos = Vector2.new(mouse.X, mouse.Y)
				refreshConsolePosition(mouse.X, mouse.Y)
				refreshConsoleSize(mouse.X, mouse.Y)
				handleScroll(mouse.X, mouse.Y)
			end
			
			refreshTextHolder()			
		end
	end)

	Dev_Container.Body.ExplorerPanel.MouseButton1Up:connect(function()
		clean()
	end)
	
	if game:FindFirstChild("Players") and game.Players["LocalPlayer"] then
		local LocalMouse = game.Players.LocalPlayer:GetMouse()
		LocalMouse.Move:connect(function()
			if not Dev_Container.Visible then
				return
			end
			local mouse = game.Players.LocalPlayer:GetMouse()
			local mousePos = Vector2.new(mouse.X, mouse.Y)
			refreshConsolePosition(mouse.X, mouse.Y)
			refreshConsoleSize(mouse.X, mouse.Y)
			handleScroll(mouse.X, mouse.Y)
			
			refreshTextHolder()
			repositionList()
		end)

		LocalMouse.Button1Up:connect(function()
			clean()
		end)
		
		LocalMouse.WheelForward:connect(function()
			if not Dev_Container.Visible then
				return
			end
			if existsInsideContainer(Dev_Container, LocalMouse.X, LocalMouse.Y) then
				changeOffset(10)
			end
		end)
		
		LocalMouse.WheelBackward:connect(function()
			if not Dev_Container.Visible then
				return
			end
			if existsInsideContainer(Dev_Container, LocalMouse.X, LocalMouse.Y) then
				changeOffset(-10)
			end
		end)
		
	end
	
	Dev_ScrollArea.Handle.MouseButton1Down:connect(function()
		repositionList()
	end)
	
	---Populate Dev-Console with dummy messages
	
	local history = game:GetService("LogService"):GetLogHistory()
	
	for i = 1, #history do
		AddLocalMessage(history[i].message, history[i].messageType, history[i].timestamp)
	end
	
	game:GetService("LogService").MessageOut:connect(function(message, messageType)
		AddLocalMessage(message, messageType, os.time())
	end)
	
	game:GetService("LogService").ServerMessageOut:connect(AddServerMessage)
	
end

local currentlyToggling = false

function ToggleConsole.OnInvoke()
	if currentlyToggling then
		return
	end

	currentlyToggling = true
	initializeDeveloperConsole()
	Dev_Container.Visible = not Dev_Container.Visible
	currentlyToggling = false
	
	if not Dev_Container.Visible then
		removeStatsListener()
		clearCharts() 
	end
	
end

ToggleConsole:Invoke() -- Testing...

-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- BEGIN EXPLORER PANEL SECTION----------------------------------------------------------------------------------------------
-- Written by Anaminus, implemented by CloneTrooper1019 ---------------------------------------------------------------------
-- A seperate script for this would probably work better --------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

local function CreateExplorer()
	local function New(ty,data)
		
		-- THIS IS NOT THE SAME AS RBXUTILITY.New, DO NOT REPLACE IT.

		local obj
		if type(ty) == 'string' then
			obj = Instance.new(ty)
		else
			obj = ty
		end
		for k, v in pairs(data) do
			if type(k) == 'number' then
				v.Parent = obj
			else
				obj[k] = v
			end
		end
		return obj
	end
	local Option = {
		Modifiable = false;
		Selectable = true;
		Whitelist = {"Workspace","Players","Lighting","ReplicatedStorage","ReplicatedFirst","StarterGui","StarterPack","Debris","Teams","TestService"}
	}

	local GUI_SIZE = 16
	local ENTRY_PADDING = 1
	local ENTRY_MARGIN = 1

	local ENTRY_SIZE = GUI_SIZE + ENTRY_PADDING*2
	local ENTRY_BOUND = ENTRY_SIZE + ENTRY_MARGIN
	local HEADER_SIZE = ENTRY_SIZE

	local FONT = 'SourceSans'
	local FONT_SIZE do
		local size = {8,9,10,11,12,14,18,24,36,48}
		local s
		local n = math.huge
		for i = 1,#size do
			if size[i] <= GUI_SIZE then
				FONT_SIZE = i - 1
			end
		end
	end

	local GuiColor = {
		Background      = Color3.new(170/255, 170/255, 170/255);
		Border          = Color3.new(149/255, 149/255, 149/255);
		Selected        = Color3.new( 96/255, 140/255, 211/255);
		BorderSelected  = Color3.new( 86/255, 125/255, 188/255);
		Text            = Color3.new(  0/255,   0/255,   0/255);
		TextDisabled    = Color3.new(128/255, 128/255, 128/255);
		TextSelected    = Color3.new(255/255, 255/255, 255/255);
		Button          = Color3.new(221/255, 221/255, 221/255);
		ButtonBorder    = Color3.new(149/255, 149/255, 149/255);
		ButtonSelected  = Color3.new(255/255,   0/255,   0/255);
		Field           = Color3.new(255/255, 255/255, 255/255);
		FieldBorder     = Color3.new(191/255, 191/255, 191/255);
		TitleBackground = Color3.new(178/255, 178/255, 178/255);
	}

	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	---- Icon map constants

	local MAP_ID = 129293660

	-- Indices based on implementation of Icon function.
	local ACTION_CUT         = 160
	local ACTION_COPY        = 161
	local ACTION_PASTE       = 162
	local ACTION_DELETE      = 163
	local ACTION_SORT        = 164
	local ACTION_CUT_OVER    = 174
	local ACTION_COPY_OVER   = 175
	local ACTION_PASTE_OVER  = 176
	local ACTION_DELETE_OVER = 177
	local ACTION_SORT_OVER   = 178

	local NODE_COLLAPSED      = 165
	local NODE_EXPANDED       = 166
	local NODE_COLLAPSED_OVER = 179
	local NODE_EXPANDED_OVER  = 180

	local ExplorerIndex = {
		["Accoutrement"] = 32;
		["Animation"] = 60;
		["AnimationTrack"] = 60;
		["ArcHandles"] = 56;
		["Backpack"] = 20;
		["BillboardGui"] = 64;
		["BindableEvent"] = 67;
		["BindableFunction"] = 66;
		["BlockMesh"] = 8;
		["BodyAngularVelocity"] = 14;
		["BodyForce"] = 14;
		["BodyGyro"] = 14;
		["BodyPosition"] = 14;
		["BodyThrust"] = 14;
		["BodyVelocity"] = 14;
		["BoolValue"] = 4;
		["BrickColorValue"] = 4;
		["Camera"] = 5;
		["CFrameValue"] = 4;
		["CharacterMesh"] = 60;
		["ClickDetector"] = 41;
		["Color3Value"] = 4;
		["Configuration"] = 58;
		["CoreGui"] = 46;
		["CornerWedgePart"] = 1;
		["CustomEvent"] = 4;
		["CustomEventReceiver"] = 4;
		["CylinderMesh"] = 8;
		["Debris"] = 30;
		["Decal"] = 7;
		["Dialog"] = 62;
		["DialogChoice"] = 63;
		["DoubleConstrainedValue"] = 4;
		["Explosion"] = 36;
		["Fire"] = 61;
		["Flag"] = 38;
		["FlagStand"] = 39;
		["FloorWire"] = 4;
		["ForceField"] = 37;
		["Frame"] = 48;
		["GuiButton"] = 52;
		["GuiMain"] = 47;
		["Handles"] = 53;
		["Hat"] = 45;
		["Hint"] = 33;
		["HopperBin"] = 22;
		["Humanoid"] = 9;
		["ImageButton"] = 52;
		["ImageLabel"] = 49;
		["IntConstrainedValue"] = 4;
		["IntValue"] = 4;
		["JointInstance"] = 34;
		["Keyframe"] = 60;
		["Lighting"] = 13;
		["LocalScript"] = 18;
		["MarketplaceService"] = 46;
		["Message"] = 33;
		["Model"] = 2;
		["NetworkClient"] = 16;
		["NetworkReplicator"] = 29;
		["NetworkServer"] = 15;
		["NumberValue"] = 4;
		["ObjectValue"] = 4;
		["Pants"] = 44;
		["ParallelRampPart"] = 1;
		["Part"] = 1;
		["PartPairLasso"] = 57;
		["Platform"] = 35;
		["Player"] = 12;
		["PlayerGui"] = 46;
		["Players"] = 21;
		["PointLight"] = 13;
		["Pose"] = 60;
		["PrismPart"] = 1;
		["PyramidPart"] = 1;
		["RayValue"] = 4;
		["ReplicatedStorage"] = 0;
		["RightAngleRampPart"] = 1;
		["RocketPropulsion"] = 14;
		["ScreenGui"] = 47;
		["Script"] = 6;
		["Seat"] = 35;
		["SelectionBox"] = 54;
		["SelectionPartLasso"] = 57;
		["SelectionPointLasso"] = 57;
		["ServerScriptService"] = 0;
		["ServerStorage"] = 0;
		["Shirt"] = 43;
		["ShirtGraphic"] = 40;
		["SkateboardPlatform"] = 35;
		["Sky"] = 28;
		["Smoke"] = 59;
		["Sound"] = 11;
		["SoundService"] = 31;
		["Sparkles"] = 42;
		["SpawnLocation"] = 25;
		["SpecialMesh"] = 8;
		["SpotLight"] = 13;
		["StarterGear"] = 20;
		["StarterGui"] = 46;
		["StarterPack"] = 20;
		["Status"] = 2;
		["StringValue"] = 4;
		["SurfaceSelection"] = 55;
		["Team"] = 24;
		["Teams"] = 23;
		["Terrain"] = 65;
		["TestService"] = 68;
		["TextBox"] = 51;
		["TextButton"] = 51;
		["TextLabel"] = 50;
		["Texture"] = 10;
		["TextureTrail"] = 4;
		["Tool"] = 17;
		["TouchTransmitter"] = 37;
		["TrussPart"] = 1;
		["Vector3Value"] = 4;
		["VehicleSeat"] = 35;
		["WedgePart"] = 1;
		["Weld"] = 34;
		["Workspace"] = 19;
	}

	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------

	-- Connects a function to an event such that it fires asynchronously
	function Connect(event,func)
		return event:connect(function(...)
			local a = {...}
			Spawn(function() func(unpack(a)) end)
		end)
	end

	-- returns the ascendant ScreenGui of an object
	function GetScreen(screen)
		if screen == nil then return nil end
		while not screen:IsA("ScreenGui") do
			screen = screen.Parent
			if screen == nil then return nil end
		end
		return screen
	end

	do
		local ZIndexLock = {}
		-- Sets the ZIndex of an object and its descendants. Objects are locked so
		-- that SetZIndexOnChanged doesn't spawn multiple threads that set the
		-- ZIndex of the same object.
		function SetZIndex(object,z)
			if not ZIndexLock[object] then
				ZIndexLock[object] = true
				if object:IsA'GuiObject' then
					object.ZIndex = z
				end
				local children = object:GetChildren()
				for i = 1,#children do
					SetZIndex(children[i],z)
				end
				ZIndexLock[object] = nil
			end
		end

		function SetZIndexOnChanged(object)
			return object.Changed:connect(function(p)
				if p == "ZIndex" then
					SetZIndex(object,object.ZIndex)
				end
			end)
		end
	end

	---- IconMap ----
	-- Image size: 256px x 256px
	-- Icon size: 16px x 16px
	-- Padding between each icon: 2px
	-- Padding around image edge: 1px
	-- Total icons: 14 x 14 (196)
	local Icon do
		local iconMap = 'http://www.roblox.com/asset/?id=' .. MAP_ID
		Game:GetService('ContentProvider'):Preload(iconMap)
		local iconDehash do
			-- 14 x 14, 0-based input, 0-based output
			local f=math.floor
			function iconDehash(h)
				return f(h/14%14),f(h%14)
			end
		end

		function Icon(IconFrame,index)
			local row,col = iconDehash(index)
			local mapSize = Vector2.new(256,256)
			local pad,border = 2,1
			local iconSize = 16

			local class = 'Frame'
			if type(IconFrame) == 'string' then
				class = IconFrame
				IconFrame = nil
			end

			if not IconFrame then
				IconFrame = New(class,{
					Name = "Icon";
					BackgroundTransparency = 1;
					ClipsDescendants = true;
					New('ImageLabel',{
						Name = "IconMap";
						Active = false;
						BackgroundTransparency = 1;
						Image = iconMap;
						Size = UDim2.new(mapSize.x/iconSize,0,mapSize.y/iconSize,0);
					});
				})
			end

			IconFrame.IconMap.Position = UDim2.new(-col - (pad*(col+1) + border)/iconSize,0,-row - (pad*(row+1) + border)/iconSize,0)
			return IconFrame
		end
	end

	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	---- ScrollBar
	do
		-- AutoButtonColor doesn't always reset properly
		local function ResetButtonColor(button)
			local active = button.Active
			button.Active = not active
			button.Active = active
		end

		local function ArrowGraphic(size,dir,scaled,template)
			local Frame = New('Frame',{
				Name = "Arrow Graphic";
				BorderSizePixel = 0;
				Size = UDim2.new(0,size,0,size);
				Transparency = 1;
			})
			if not template then
				template = Instance.new("Frame")
				template.BorderSizePixel = 0
			end

			local transform
			if dir == nil or dir == 'Up' then
				function transform(p,s) return p,s end
			elseif dir == 'Down' then
				function transform(p,s) return UDim2.new(0,p.X.Offset,0,size-p.Y.Offset-1),s end
			elseif dir == 'Left' then
				function transform(p,s) return UDim2.new(0,p.Y.Offset,0,p.X.Offset),UDim2.new(0,s.Y.Offset,0,s.X.Offset) end
			elseif dir == 'Right' then
				function transform(p,s) return UDim2.new(0,size-p.Y.Offset-1,0,p.X.Offset),UDim2.new(0,s.Y.Offset,0,s.X.Offset) end
			end

			local scale
			if scaled then
				function scale(p,s) return UDim2.new(p.X.Offset/size,0,p.Y.Offset/size,0),UDim2.new(s.X.Offset/size,0,s.Y.Offset/size,0) end
			else
				function scale(p,s) return p,s end
			end

			local o = math.floor(size/4)
			if size%2 == 0 then
				local n = size/2-1
				for i = 0,n do
					local t = template:Clone()
					local p,s = scale(transform(
						UDim2.new(0,n-i,0,o+i),
						UDim2.new(0,(i+1)*2,0,1)
					))
					t.Position = p
					t.Size = s
					t.Parent = Frame
				end
			else
				local n = (size-1)/2
				for i = 0,n do
					local t = template:Clone()
					local p,s = scale(transform(
						UDim2.new(0,n-i,0,o+i),
						UDim2.new(0,i*2+1,0,1)
					))
					t.Position = p
					t.Size = s
					t.Parent = Frame
				end
			end
			if size%4 > 1 then
				local t = template:Clone()
				local p,s = scale(transform(
					UDim2.new(0,0,0,size-o-1),
					UDim2.new(0,size,0,1)
				))
				t.Position = p
				t.Size = s
				t.Parent = Frame
			end
			return Frame
		end


		local function GripGraphic(size,dir,spacing,scaled,template)
			local Frame = New('Frame',{
				Name = "Grip Graphic";
				BorderSizePixel = 0;
				Size = UDim2.new(0,size.x,0,size.y);
				Transparency = 1;
			})
			if not template then
				template = Instance.new("Frame")
				template.BorderSizePixel = 0
			end

			spacing = spacing or 2

			local scale
			if scaled then
				function scale(p) return UDim2.new(p.X.Offset/size.x,0,p.Y.Offset/size.y,0) end
			else
				function scale(p) return p end
			end

			if dir == 'Vertical' then
				for i=0,size.x-1,spacing do
					local t = template:Clone()
					t.Size = scale(UDim2.new(0,1,0,size.y))
					t.Position = scale(UDim2.new(0,i,0,0))
					t.Parent = Frame
				end
			elseif dir == nil or dir == 'Horizontal' then
				for i=0,size.y-1,spacing do
					local t = template:Clone()
					t.Size = scale(UDim2.new(0,size.x,0,1))
					t.Position = scale(UDim2.new(0,0,0,i))
					t.Parent = Frame
				end
			end

			return Frame
		end

		local mt = {
			__index = {
				GetScrollPercent = function(self)
					return self.ScrollIndex/(self.TotalSpace-self.VisibleSpace)
				end;
				CanScrollDown = function(self)
					return self.ScrollIndex + self.VisibleSpace < self.TotalSpace
				end;
				CanScrollUp = function(self)
					return self.ScrollIndex > 0
				end;
				ScrollDown = function(self)
					self.ScrollIndex = self.ScrollIndex + self.PageIncrement
					self:Update()
				end;
				ScrollUp = function(self)
					self.ScrollIndex = self.ScrollIndex - self.PageIncrement
					self:Update()
				end;
				ScrollTo = function(self,index)
					self.ScrollIndex = index
					self:Update()
				end;
				SetScrollPercent = function(self,percent)
					self.ScrollIndex = math.floor((self.TotalSpace - self.VisibleSpace)*percent + 0.5)
					self:Update()
				end;
			};
		}
		mt.__index.CanScrollRight = mt.__index.CanScrollDown
		mt.__index.CanScrollLeft = mt.__index.CanScrollUp
		mt.__index.ScrollLeft = mt.__index.ScrollUp
		mt.__index.ScrollRight = mt.__index.ScrollDown

		function ScrollBar(horizontal)
			-- New row scroll bar
			local ScrollFrame = New('Frame',{
				Name = "ScrollFrame";
				Position = horizontal and UDim2.new(0,0,1,-GUI_SIZE) or UDim2.new(1,-GUI_SIZE,0,0);
				Size = horizontal and UDim2.new(1,0,0,GUI_SIZE) or UDim2.new(0,GUI_SIZE,1,0);
				BackgroundTransparency = 1;
				New('ImageButton',{
					Name = "ScrollDown";
					Position = horizontal and UDim2.new(1,-GUI_SIZE,0,0) or UDim2.new(0,0,1,-GUI_SIZE);
					Size = UDim2.new(0, GUI_SIZE, 0, GUI_SIZE);
					BackgroundColor3 = GuiColor.Button;
					BorderColor3 = GuiColor.Border;
					--BorderSizePixel = 0;
				});
				New('ImageButton',{
					Name = "ScrollUp";
					Size = UDim2.new(0, GUI_SIZE, 0, GUI_SIZE);
					BackgroundColor3 = GuiColor.Button;
					BorderColor3 = GuiColor.Border;
					--BorderSizePixel = 0;
				});
				New('ImageButton',{
					Name = "ScrollBar";
					Size = horizontal and UDim2.new(1,-GUI_SIZE*2,1,0) or UDim2.new(1,0,1,-GUI_SIZE*2);
					Position = horizontal and UDim2.new(0,GUI_SIZE,0,0) or UDim2.new(0,0,0,GUI_SIZE);
					AutoButtonColor = false;
					BackgroundColor3 = Color3.new(0.94902, 0.94902, 0.94902);
					BorderColor3 = GuiColor.Border;
					--BorderSizePixel = 0;
					New('ImageButton',{
						Name = "ScrollThumb";
						AutoButtonColor = false;
						Size = UDim2.new(0, GUI_SIZE, 0, GUI_SIZE);
						BackgroundColor3 = GuiColor.Button;
						BorderColor3 = GuiColor.Border;
						--BorderSizePixel = 0;
					});
				});
			})

			local graphicTemplate = New('Frame',{
				Name="Graphic";
				BorderSizePixel = 0;
				BackgroundColor3 = GuiColor.Border;
			})
			local graphicSize = GUI_SIZE/2

			local ScrollDownFrame = ScrollFrame.ScrollDown
				local ScrollDownGraphic = ArrowGraphic(graphicSize,horizontal and 'Right' or 'Down',true,graphicTemplate)
				ScrollDownGraphic.Position = UDim2.new(0.5,-graphicSize/2,0.5,-graphicSize/2)
				ScrollDownGraphic.Parent = ScrollDownFrame
			local ScrollUpFrame = ScrollFrame.ScrollUp
				local ScrollUpGraphic = ArrowGraphic(graphicSize,horizontal and 'Left' or 'Up',true,graphicTemplate)
				ScrollUpGraphic.Position = UDim2.new(0.5,-graphicSize/2,0.5,-graphicSize/2)
				ScrollUpGraphic.Parent = ScrollUpFrame
			local ScrollBarFrame = ScrollFrame.ScrollBar
			local ScrollThumbFrame = ScrollBarFrame.ScrollThumb
			do
				local size = GUI_SIZE*3/8
				local Decal = GripGraphic(Vector2.new(size,size),horizontal and 'Vertical' or 'Horizontal',2,graphicTemplate)
				Decal.Position = UDim2.new(0.5,-size/2,0.5,-size/2)
				Decal.Parent = ScrollThumbFrame
			end

			local Class = setmetatable({
				GUI = ScrollFrame;
				ScrollIndex = 0;
				VisibleSpace = 0;
				TotalSpace = 0;
				PageIncrement = 1;
			},mt)

			local UpdateScrollThumb
			if horizontal then
				function UpdateScrollThumb()
					ScrollThumbFrame.Size = UDim2.new(Class.VisibleSpace/Class.TotalSpace,0,0,GUI_SIZE)
					if ScrollThumbFrame.AbsoluteSize.x < GUI_SIZE then
						ScrollThumbFrame.Size = UDim2.new(0,GUI_SIZE,0,GUI_SIZE)
					end
					local barSize = ScrollBarFrame.AbsoluteSize.x
					ScrollThumbFrame.Position = UDim2.new(Class:GetScrollPercent()*(barSize - ScrollThumbFrame.AbsoluteSize.x)/barSize,0,0,0)
				end
			else
				function UpdateScrollThumb()
					ScrollThumbFrame.Size = UDim2.new(0,GUI_SIZE,Class.VisibleSpace/Class.TotalSpace,0)
					if ScrollThumbFrame.AbsoluteSize.y < GUI_SIZE then
						ScrollThumbFrame.Size = UDim2.new(0,GUI_SIZE,0,GUI_SIZE)
					end
					local barSize = ScrollBarFrame.AbsoluteSize.y
					ScrollThumbFrame.Position = UDim2.new(0,0,Class:GetScrollPercent()*(barSize - ScrollThumbFrame.AbsoluteSize.y)/barSize,0)
				end
			end

			local lastDown
			local lastUp
			local scrollStyle = {BackgroundColor3=GuiColor.Border,BackgroundTransparency=0}
			local scrollStyle_ds = {BackgroundColor3=GuiColor.Border,BackgroundTransparency=0.7}

			local function Update()
				local t = Class.TotalSpace
				local v = Class.VisibleSpace
				local s = Class.ScrollIndex
				if v <= t then
					if s > 0 then
						if s + v > t then
							Class.ScrollIndex = t - v
						end
					else
						Class.ScrollIndex = 0
					end
				else
					Class.ScrollIndex = 0
				end

				if Class.UpdateCallback then
					if Class.UpdateCallback(Class) == false then
						return
					end
				end

				local down = Class:CanScrollDown()
				local up = Class:CanScrollUp()
				if down ~= lastDown then
					lastDown = down
					ScrollDownFrame.Active = down
					ScrollDownFrame.AutoButtonColor = down
					local children = ScrollDownGraphic:GetChildren()
					local style = down and scrollStyle or scrollStyle_ds
					for i = 1,#children do
						New(children[i],style)
					end
				end
				if up ~= lastUp then
					lastUp = up
					ScrollUpFrame.Active = up
					ScrollUpFrame.AutoButtonColor = up
					local children = ScrollUpGraphic:GetChildren()
					local style = up and scrollStyle or scrollStyle_ds
					for i = 1,#children do
						New(children[i],style)
					end
				end
				ScrollThumbFrame.Visible = down or up
				UpdateScrollThumb()
			end
			Class.Update = Update

			SetZIndexOnChanged(ScrollFrame)

			local MouseDrag = New('ImageButton',{
				Name = "MouseDrag";
				Position = UDim2.new(-0.25,0,-0.25,0);
				Size = UDim2.new(1.5,0,1.5,0);
				Transparency = 1;
				AutoButtonColor = false;
				Active = true;
				ZIndex = 10;
			})

			local scrollEventID = 0
			ScrollDownFrame.MouseButton1Down:connect(function()
				scrollEventID = tick()
				local current = scrollEventID
				local up_con
				up_con = MouseDrag.MouseButton1Up:connect(function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollDownFrame)
					up_con:disconnect(); drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
				Class:ScrollDown()
				wait(0.2) -- delay before auto scroll
				while scrollEventID == current do
					Class:ScrollDown()
					if not Class:CanScrollDown() then break end
					wait()
				end
			end)

			ScrollDownFrame.MouseButton1Up:connect(function()
				scrollEventID = tick()
			end)

			ScrollUpFrame.MouseButton1Down:connect(function()
				scrollEventID = tick()
				local current = scrollEventID
				local up_con
				up_con = MouseDrag.MouseButton1Up:connect(function()
					scrollEventID = tick()
					MouseDrag.Parent = nil
					ResetButtonColor(ScrollUpFrame)
					up_con:disconnect(); drag = nil
				end)
				MouseDrag.Parent = GetScreen(ScrollFrame)
				Class:ScrollUp()
				wait(0.2)
				while scrollEventID == current do
					Class:ScrollUp()
					if not Class:CanScrollUp() then break end
					wait()
				end
			end)

			ScrollUpFrame.MouseButton1Up:connect(function()
				scrollEventID = tick()
			end)

			if horizontal then
				ScrollBarFrame.MouseButton1Down:connect(function(x,y)
					scrollEventID = tick()
					local current = scrollEventID
					local up_con
					up_con = MouseDrag.MouseButton1Up:connect(function()
						scrollEventID = tick()
						MouseDrag.Parent = nil
						ResetButtonColor(ScrollUpFrame)
						up_con:disconnect(); drag = nil
					end)
					MouseDrag.Parent = GetScreen(ScrollFrame)
					if x > ScrollThumbFrame.AbsolutePosition.x then
						Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
						wait(0.2)
						while scrollEventID == current do
							if x < ScrollThumbFrame.AbsolutePosition.x + ScrollThumbFrame.AbsoluteSize.x then break end
							Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
							wait()
						end
					else
						Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
						wait(0.2)
						while scrollEventID == current do
							if x > ScrollThumbFrame.AbsolutePosition.x then break end
							Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
							wait()
						end
					end
				end)
			else
				ScrollBarFrame.MouseButton1Down:connect(function(x,y)
					scrollEventID = tick()
					local current = scrollEventID
					local up_con
					up_con = MouseDrag.MouseButton1Up:connect(function()
						scrollEventID = tick()
						MouseDrag.Parent = nil
						ResetButtonColor(ScrollUpFrame)
						up_con:disconnect(); drag = nil
					end)
					MouseDrag.Parent = GetScreen(ScrollFrame)
					if y > ScrollThumbFrame.AbsolutePosition.y then
						Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
						wait(0.2)
						while scrollEventID == current do
							if y < ScrollThumbFrame.AbsolutePosition.y + ScrollThumbFrame.AbsoluteSize.y then break end
							Class:ScrollTo(Class.ScrollIndex + Class.VisibleSpace)
							wait()
						end
					else
						Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
						wait(0.2)
						while scrollEventID == current do
							if y > ScrollThumbFrame.AbsolutePosition.y then break end
							Class:ScrollTo(Class.ScrollIndex - Class.VisibleSpace)
							wait()
						end
					end
				end)
			end

			if horizontal then
				ScrollThumbFrame.MouseButton1Down:connect(function(x,y)
					scrollEventID = tick()
					local mouse_offset = x - ScrollThumbFrame.AbsolutePosition.x
					local drag_con
					local up_con
					drag_con = MouseDrag.MouseMoved:connect(function(x,y)
						local bar_abs_pos = ScrollBarFrame.AbsolutePosition.x
						local bar_drag = ScrollBarFrame.AbsoluteSize.x - ScrollThumbFrame.AbsoluteSize.x
						local bar_abs_one = bar_abs_pos + bar_drag
						x = x - mouse_offset
						x = x < bar_abs_pos and bar_abs_pos or x > bar_abs_one and bar_abs_one or x
						x = x - bar_abs_pos
						Class:SetScrollPercent(x/(bar_drag))
					end)
					up_con = MouseDrag.MouseButton1Up:connect(function()
						scrollEventID = tick()
						MouseDrag.Parent = nil
						ResetButtonColor(ScrollThumbFrame)
						drag_con:disconnect(); drag_con = nil
						up_con:disconnect(); drag = nil
					end)
					MouseDrag.Parent = GetScreen(ScrollFrame)
				end)
			else
				ScrollThumbFrame.MouseButton1Down:connect(function(x,y)
					scrollEventID = tick()
					local mouse_offset = y - ScrollThumbFrame.AbsolutePosition.y
					local drag_con
					local up_con
					drag_con = MouseDrag.MouseMoved:connect(function(x,y)
						local bar_abs_pos = ScrollBarFrame.AbsolutePosition.y
						local bar_drag = ScrollBarFrame.AbsoluteSize.y - ScrollThumbFrame.AbsoluteSize.y
						local bar_abs_one = bar_abs_pos + bar_drag
						y = y - mouse_offset
						y = y < bar_abs_pos and bar_abs_pos or y > bar_abs_one and bar_abs_one or y
						y = y - bar_abs_pos
						Class:SetScrollPercent(y/(bar_drag))
					end)
					up_con = MouseDrag.MouseButton1Up:connect(function()
						scrollEventID = tick()
						MouseDrag.Parent = nil
						ResetButtonColor(ScrollThumbFrame)
						drag_con:disconnect(); drag_con = nil
						up_con:disconnect(); drag = nil
					end)
					MouseDrag.Parent = GetScreen(ScrollFrame)
				end)
			end

			function Class:Destroy()
				ScrollFrame:Destroy()
				MouseDrag:Destroy()
				for k in pairs(Class) do
					Class[k] = nil
				end
				setmetatable(Class,nil)
			end

			Update()

			return Class
		end
	end

	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	---- Explorer panel


	New(Explorer_Panel,{
		BackgroundColor3 = GuiColor.Field;
		BorderColor3 = GuiColor.Border;
		Active = true;
	})

	local listFrame = New('Frame',{
		Name = "List";
		BackgroundTransparency = 1;
		ClipsDescendants = true;
		Position = UDim2.new(0,0,0,HEADER_SIZE);
		Size = UDim2.new(1,-GUI_SIZE,1,-HEADER_SIZE);
		Parent = Explorer_Panel;
	})

	local scrollBar = ScrollBar(false)
	scrollBar.PageIncrement = 1
	New(scrollBar.GUI,{
		Position = UDim2.new(1,-GUI_SIZE,0,HEADER_SIZE);
		Size = UDim2.new(0,GUI_SIZE,1,-HEADER_SIZE);
		Parent = Explorer_Panel;
	})

	local scrollBarH = ScrollBar(true)
	scrollBarH.PageIncrement = GUI_SIZE
	New(scrollBarH.GUI,{
		Position = UDim2.new(0,0,1,-GUI_SIZE);
		Size = UDim2.new(1,-GUI_SIZE,0,GUI_SIZE);
		Visible = false;
		Parent = Explorer_Panel;
	})

	local headerFrame = New('Frame',{
		Name = "Header";
		BackgroundColor3 = GuiColor.Background;
		BorderColor3 = GuiColor.Border;
		Position = UDim2.new(0,0,0,0);
		Size = UDim2.new(1,0,0,HEADER_SIZE);
		Parent = Explorer_Panel;
		New('TextLabel',{
			Text = "Explorer";
			BackgroundTransparency = 1;
			TextColor3 = GuiColor.Text;
			TextXAlignment = 'Left';
			Font = FONT;
			FontSize = FONT_SIZE;
			Position = UDim2.new(0,4,0,0);
			Size = UDim2.new(1,-4,1,0);
		});
	})

	Explorer_Panel.ZIndex = 2
	SetZIndexOnChanged(Explorer_Panel)

	local getTextWidth do
		local text = New('TextLabel',{
			Name = "TextWidth";
			TextXAlignment = 'Left';
			TextYAlignment = 'Center';
			Font = FONT;
			FontSize = FONT_SIZE;
			Text = "";
			Position = UDim2.new(0,0,0,0);
			Size = UDim2.new(1,0,1,0);
			Visible = false;
			Parent = Explorer_Panel;
		})
		function getTextWidth(s)
			text.Text = s
			return text.TextBounds.x
		end
	end

	-- Holds the game tree converted to a list.
	local TreeList = {}
	-- Matches objects to their tree node representation.
	local NodeLookup = {}

	local nodeWidth = 0

	local updateList,rawUpdateList,updateScroll,rawUpdateSize do
		local function r(t)
			for i = 1,#t do
				TreeList[#TreeList+1] = t[i]

				local w = (t[i].Depth)*(2+ENTRY_PADDING+GUI_SIZE) + 2 + ENTRY_SIZE + 4 + getTextWidth(t[i].Object.Name) + 4
				if w > nodeWidth then
					nodeWidth = w
				end
				if t[i].Expanded then
					r(t[i])
				end
			end
		end

		function rawUpdateSize()
			scrollBarH.TotalSpace = nodeWidth
			scrollBarH.VisibleSpace = listFrame.AbsoluteSize.x
			scrollBarH:Update()
			local visible = scrollBarH:CanScrollDown() or scrollBarH:CanScrollUp()
			scrollBarH.GUI.Visible = visible

			listFrame.Size = UDim2.new(1,-GUI_SIZE,1,-GUI_SIZE*(visible and 1 or 0) - HEADER_SIZE)

			scrollBar.VisibleSpace = math.ceil(listFrame.AbsoluteSize.y/ENTRY_BOUND)
			scrollBar.GUI.Size = UDim2.new(0,GUI_SIZE,1,-GUI_SIZE*(visible and 1 or 0) - HEADER_SIZE)

			scrollBar.TotalSpace = #TreeList+1
			scrollBar:Update()
		end

		function rawUpdateList()
			-- Clear then repopulate the entire list. It appears to be fast enough.
			TreeList = {}
			nodeWidth = 0
			r(NodeLookup[Game])
			rawUpdateSize()
		end

		-- Adding or removing large models will cause many updates to occur. We
		-- can reduce the number of updates by creating a delay, then dropping any
		-- updates that occur during the delay.
		local updatingList = false
		function updateList()
			if updatingList then return end
			updatingList = true
			wait(0.25)
			updatingList = false
			rawUpdateList()
		end

		local updatingScroll = false
		function updateScroll()
			if updatingScroll then return end
			updatingScroll = true
			wait(0.25)
			updatingScroll = false
			scrollBar:Update()
		end
	end

	local Selection do
		local bindGetSelection = Explorer_Panel:FindFirstChild("GetSelection")
		if not bindGetSelection then
			bindGetSelection = New('BindableFunction',{Name = "GetSelection"})
			bindGetSelection.Parent = Explorer_Panel
		end

		local bindSetSelection = Explorer_Panel:FindFirstChild("SetSelection")
		if not bindSetSelection then
			bindSetSelection = New('BindableFunction',{Name = "SetSelection"})
			bindSetSelection.Parent = Explorer_Panel
		end

		local bindSelectionChanged = Explorer_Panel:FindFirstChild("SelectionChanged")
		if not bindSelectionChanged then
			bindSelectionChanged = New('BindableEvent',{Name = "SelectionChanged"})
			bindSelectionChanged.Parent = Explorer_Panel
		end

		local SelectionList = {}
		local SelectionSet = {}
		Selection = {
			Selected = SelectionSet;
			List = SelectionList;
		}

		local function addObject(object)
			-- list update
			local lupdate = false
			-- scroll update
			local supdate = false

			if not SelectionSet[object] then
				local node = NodeLookup[object]
				if node then
					table.insert(SelectionList,object)
					SelectionSet[object] = true
					node.Selected = true

					-- expand all ancestors so that selected node becomes visible
					node = node.Parent
					while node do
						if not node.Expanded then
							node.Expanded = true
							lupdate = true
						end
						node = node.Parent
					end
					supdate = true
				end
			end
			return lupdate,supdate
		end

		function Selection:Set(objects)
			local lupdate = false
			local supdate = false

			if #SelectionList > 0 then
				for i = 1,#SelectionList do
					local object = SelectionList[i]
					local node = NodeLookup[object]
					if node then
						node.Selected = false
						SelectionSet[object] = nil
					end
				end

				SelectionList = {}
				Selection.List = SelectionList
				supdate = true
			end

			for i = 1,#objects do
				local l,s = addObject(objects[i])
				lupdate = l or lupdate
				supdate = s or supdate
			end

			if lupdate then
				rawUpdateList()
				supdate = true
			elseif supdate then
				scrollBar:Update()
			end

			if supdate then
				bindSelectionChanged:Fire()
			end
		end

		function Selection:Add(object)
			local l,s = addObject(object)
			if l then
				rawUpdateList()
				bindSelectionChanged:Fire()
			elseif s then
				scrollBar:Update()
				bindSelectionChanged:Fire()
			end
		end

		function Selection:Remove(object,noupdate)
			if SelectionSet[object] then
				local node = NodeLookup[object]
				if node then
					node.Selected = false
					SelectionSet[object] = nil
					for i = 1,#SelectionList do
						if SelectionList[i] == object then
							table.remove(SelectionList,i)
							break
						end
					end

					if not noupdate then
						scrollBar:Update()
					end
					bindSelectionChanged:Fire()
				end
			end
		end

		function Selection:Get()
			local list = {}
			for i = 1,#SelectionList do
				list[i] = SelectionList[i]
			end
			return list
		end

		bindSetSelection.OnInvoke = function(...)
			Selection:Set(...)
		end

		bindGetSelection.OnInvoke = function()
			return Selection:Get()
		end
	end

	local function cancelReparentDrag()end
	local function cancelSelectDrag()end
	do
		local listEntries = {}
		local nameConnLookup = {}

		local mouseDrag = New('ImageButton',{
			Name = "MouseDrag";
			Position = UDim2.new(-0.25,0,-0.25,0);
			Size = UDim2.new(1.5,0,1.5,0);
			Transparency = 1;
			AutoButtonColor = false;
			Active = true;
			ZIndex = 10;
		})
		local function dragSelect(last,add,button)
			local connDrag
			local conUp

			conDrag = mouseDrag.MouseMoved:connect(function(x,y)
				local pos = Vector2.new(x,y) - listFrame.AbsolutePosition
				local size = listFrame.AbsoluteSize
				if pos.x < 0 or pos.x > size.x or pos.y < 0 or pos.y > size.y then return end

				local i = math.ceil(pos.y/ENTRY_BOUND) + scrollBar.ScrollIndex
				-- Mouse may have made a large step, so interpolate between the
				-- last index and the current.
				for n = i<last and i or last, i>last and i or last do
					local node = TreeList[n]
					if node then
						if add then
							Selection:Add(node.Object)
						else
							Selection:Remove(node.Object)
						end
					end
				end
				last = i
			end)

			function cancelSelectDrag()
				mouseDrag.Parent = nil
				conDrag:disconnect()
				conUp:disconnect()
				function cancelSelectDrag()end
			end

			conUp = mouseDrag[button]:connect(cancelSelectDrag)

			mouseDrag.Parent = GetScreen(listFrame)
		end

		local function dragReparent(object,dragGhost,clickPos,ghostOffset)
			local connDrag
			local conUp
			local conUp2

			local parentIndex = nil
			local dragged = false

			local parentHighlight = New('Frame',{
				Transparency = 1;
				Visible = false;
				New('Frame',{
					BorderSizePixel = 0;
					BackgroundColor3 = Color3.new(0,0,0);
					BackgroundTransparency = 0.1;
					Position = UDim2.new(0,0,0,0);
					Size = UDim2.new(1,0,0,1);
				});
				New('Frame',{
					BorderSizePixel = 0;
					BackgroundColor3 = Color3.new(0,0,0);
					BackgroundTransparency = 0.1;
					Position = UDim2.new(1,0,0,0);
					Size = UDim2.new(0,1,1,0);
				});
				New('Frame',{
					BorderSizePixel = 0;
					BackgroundColor3 = Color3.new(0,0,0);
					BackgroundTransparency = 0.1;
					Position = UDim2.new(0,0,1,0);
					Size = UDim2.new(1,0,0,1);
				});
				New('Frame',{
					BorderSizePixel = 0;
					BackgroundColor3 = Color3.new(0,0,0);
					BackgroundTransparency = 0.1;
					Position = UDim2.new(0,0,0,0);
					Size = UDim2.new(0,1,1,0);
				});
			})
			SetZIndex(parentHighlight,9)

			conDrag = mouseDrag.MouseMoved:connect(function(x,y)
				local dragPos = Vector2.new(x,y)
				if dragged then
					local pos = dragPos - listFrame.AbsolutePosition
					local size = listFrame.AbsoluteSize

					parentIndex = nil
					parentHighlight.Visible = false
					if pos.x >= 0 and pos.x <= size.x and pos.y >= 0 and pos.y <= size.y then
						local i = math.ceil(pos.y/ENTRY_BOUND)
						local node = TreeList[i + scrollBar.ScrollIndex]
						if node and node.Object ~= object and not object:IsAncestorOf(node.Object) then
							parentIndex = i
							local entry = listEntries[i]
							if entry then
								parentHighlight.Visible = true
								parentHighlight.Position = UDim2.new(0,1,0,entry.AbsolutePosition.y-listFrame.AbsolutePosition.y)
								parentHighlight.Size = UDim2.new(0,size.x-4,0,entry.AbsoluteSize.y)
							end
						end
					end

					dragGhost.Position = UDim2.new(0,dragPos.x+ghostOffset.x,0,dragPos.y+ghostOffset.y)
				elseif (clickPos-dragPos).magnitude > 8 then
					dragged = true
					SetZIndex(dragGhost,9)
					dragGhost.IndentFrame.Transparency = 0.25
					dragGhost.IndentFrame.EntryText.TextColor3 = GuiColor.TextSelected
					dragGhost.Position = UDim2.new(0,dragPos.x+ghostOffset.x,0,dragPos.y+ghostOffset.y)
					dragGhost.Parent = GetScreen(listFrame)
					parentHighlight.Parent = listFrame
				end
			end)

			function cancelReparentDrag()
				mouseDrag.Parent = nil
				conDrag:disconnect()
				conUp:disconnect()
				conUp2:disconnect()
				dragGhost:Destroy()
				parentHighlight:Destroy()
				function cancelReparentDrag()end
			end

			local wasSelected = Selection.Selected[object]
			if not wasSelected and Option.Selectable then
				Selection:Set({object})
			end

			conUp = mouseDrag.MouseButton1Up:connect(function()
				cancelReparentDrag()
				if dragged then
					if parentIndex then
						local parentNode = TreeList[parentIndex + scrollBar.ScrollIndex]
						if parentNode then
							parentNode.Expanded = true

							local parentObj = parentNode.Object
							local function parent(a,b)
								a.Parent = b
							end
							if Option.Selectable then
								local list = Selection.List
								for i = 1,#list do
									pcall(parent,list[i],parentObj)
								end
							else
								pcall(parent,object,parentObj)
							end
						end
					end
				else
					-- do selection click
					if wasSelected and Option.Selectable then
						Selection:Set({})
					end
				end
			end)
			conUp2 = mouseDrag.MouseButton2Down:connect(function()
				cancelReparentDrag()
			end)

			mouseDrag.Parent = GetScreen(listFrame)
		end

		local entryTemplate = New('ImageButton',{
			Name = "Entry";
			Transparency = 1;
			AutoButtonColor = false;
			Position = UDim2.new(0,0,0,0);
			Size = UDim2.new(1,0,0,ENTRY_SIZE);
			New('Frame',{
				Name = "IndentFrame";
				BackgroundTransparency = 1;
				BackgroundColor3 = GuiColor.Selected;
				BorderColor3 = GuiColor.BorderSelected;
				Position = UDim2.new(0,0,0,0);
				Size = UDim2.new(1,0,1,0);
				New(Icon('ImageButton',0),{
					Name = "Expand";
					AutoButtonColor = false;
					Position = UDim2.new(0,-GUI_SIZE,0.5,-GUI_SIZE/2);
					Size = UDim2.new(0,GUI_SIZE,0,GUI_SIZE);
				});
				New(Icon(nil,0),{
					Name = "ExplorerIcon";
					Position = UDim2.new(0,2+ENTRY_PADDING,0.5,-GUI_SIZE/2);
					Size = UDim2.new(0,GUI_SIZE,0,GUI_SIZE);
				});
				New('TextLabel',{
					Name = "EntryText";
					BackgroundTransparency = 1;
					TextColor3 = GuiColor.Text;
					TextXAlignment = 'Left';
					TextYAlignment = 'Center';
					Font = FONT;
					FontSize = FONT_SIZE;
					Text = "";
					Position = UDim2.new(0,2+ENTRY_SIZE+4,0,0);
					Size = UDim2.new(1,-2,1,0);
				});
			});
		})

		function scrollBar.UpdateCallback(self)
			for i = 1,self.VisibleSpace do
				local node = TreeList[i + self.ScrollIndex]
				if node then
					local entry = listEntries[i]
					if not entry then
						entry = New(entryTemplate:Clone(),{
							Position = UDim2.new(0,2,0,ENTRY_BOUND*(i-1)+2);
							Size = UDim2.new(0,nodeWidth,0,ENTRY_SIZE);
							ZIndex = listFrame.ZIndex;
						})
						listEntries[i] = entry

						local expand = entry.IndentFrame.Expand
						expand.MouseEnter:connect(function()
							local node = TreeList[i + self.ScrollIndex]
							if #node > 0 then
								if node.Expanded then
									Icon(expand,NODE_EXPANDED_OVER)
								else
									Icon(expand,NODE_COLLAPSED_OVER)
								end
							end
						end)
						expand.MouseLeave:connect(function()
							local node = TreeList[i + self.ScrollIndex]
							if #node > 0 then
								if node.Expanded then
									Icon(expand,NODE_EXPANDED)
								else
									Icon(expand,NODE_COLLAPSED)
								end
							end
						end)
						expand.MouseButton1Down:connect(function()
							local node = TreeList[i + self.ScrollIndex]
							if #node > 0 then
								node.Expanded = not node.Expanded
								-- use raw update so the list updates instantly
								rawUpdateList()
							end
						end)

						entry.MouseButton1Down:connect(function(x,y)
							local node = TreeList[i + self.ScrollIndex]
							if Option.Modifiable then
								local pos = Vector2.new(x,y)
								dragReparent(node.Object,entry:Clone(),pos,entry.AbsolutePosition-pos)
							elseif Option.Selectable then
								if Selection.Selected[node.Object] then
									Selection:Set({})
								else
									Selection:Set({node.Object})
								end
								dragSelect(i+self.ScrollIndex,true,'MouseButton1Up')
							end
						end)

						entry.MouseButton2Down:connect(function()
							if not Option.Selectable then return end

							local node = TreeList[i + self.ScrollIndex]
							if Selection.Selected[node.Object] then
								Selection:Remove(node.Object)
								dragSelect(i+self.ScrollIndex,false,'MouseButton2Up')
							else
								Selection:Add(node.Object)
								dragSelect(i+self.ScrollIndex,true,'MouseButton2Up')
							end
						end)

						entry.Parent = listFrame
					end

					entry.Visible = true

					local object = node.Object

					-- update expand icon
					if #node == 0 then
						entry.IndentFrame.Expand.Visible = false
					elseif node.Expanded then
						Icon(entry.IndentFrame.Expand,NODE_EXPANDED)
						entry.IndentFrame.Expand.Visible = true
					else
						Icon(entry.IndentFrame.Expand,NODE_COLLAPSED)
						entry.IndentFrame.Expand.Visible = true
					end

					-- update explorer icon
					Icon(entry.IndentFrame.ExplorerIcon,ExplorerIndex[object.ClassName] or 0)

					-- update indentation
					local w = (node.Depth)*(2+ENTRY_PADDING+GUI_SIZE)
					entry.IndentFrame.Position = UDim2.new(0,w,0,0)
					entry.IndentFrame.Size = UDim2.new(1,-w,1,0)

					-- update name change detection
					if nameConnLookup[entry] then
						nameConnLookup[entry]:disconnect()
					end
					local text = entry.IndentFrame.EntryText
					local objName = object.Name
					if objName == "Instance" then
						objName = tostring(object.ClassName)
					end
					text.Text = objName
					nameConnLookup[entry] = node.Object.Changed:connect(function(p)
						if p == 'Name' then
							text.Text = object.Name
						end
					end)

					-- update selection
					entry.IndentFrame.Transparency = node.Selected and 0 or 1
					text.TextColor3 = GuiColor[node.Selected and 'TextSelected' or 'Text']

					entry.Size = UDim2.new(0,nodeWidth,0,ENTRY_SIZE)
				elseif listEntries[i] then
					listEntries[i].Visible = false
				end
			end
			for i = self.VisibleSpace+1,self.TotalSpace do
				local entry = listEntries[i]
				if entry then
					listEntries[i] = nil
					entry:Destroy()
				end
			end
		end

		function scrollBarH.UpdateCallback(self)
			for i = 1,scrollBar.VisibleSpace do
				local node = TreeList[i + scrollBar.ScrollIndex]
				if node then
					local entry = listEntries[i]
					if entry then
						entry.Position = UDim2.new(0,2 - scrollBarH.ScrollIndex,0,ENTRY_BOUND*(i-1)+2)
					end
				end
			end
		end

		Connect(listFrame.Changed,function(p)
			if p == 'AbsoluteSize' then
				rawUpdateSize()
			end
		end)

		local wheelAmount = 6
		Explorer_Panel.MouseWheelForward:connect(function()
			if scrollBar.VisibleSpace - 1 > wheelAmount then
				scrollBar:ScrollTo(scrollBar.ScrollIndex - wheelAmount)
			else
				scrollBar:ScrollTo(scrollBar.ScrollIndex - scrollBar.VisibleSpace)
			end
		end)
		Explorer_Panel.MouseWheelBackward:connect(function()
			if scrollBar.VisibleSpace - 1 > wheelAmount then
				scrollBar:ScrollTo(scrollBar.ScrollIndex + wheelAmount)
			else
				scrollBar:ScrollTo(scrollBar.ScrollIndex + scrollBar.VisibleSpace)
			end
		end)
	end

	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	---- Object detection

	-- Inserts `v` into `t` at `i`. Also sets `Index` field in `v`.
	local function insert(t,i,v)
		for n = #t,i,-1 do
			local v = t[n]
			v.Index = n+1
			t[n+1] = v
		end
		v.Index = i
		t[i] = v
	end

	-- Removes `i` from `t`. Also sets `Index` field in removed value.
	local function remove(t,i)
		local v = t[i]
		for n = i+1,#t do
			local v = t[n]
			v.Index = n-1
			t[n-1] = v
		end
		t[#t] = nil
		v.Index = 0
		return v
	end

	-- Returns how deep `o` is in the tree.
	local function depth(o)
		local d = -1
		while o do
			o = o.Parent
			d = d + 1
		end
		return d
	end


	local connLookup = {}

	-- Returns whether a node would be present in the tree list
	local function nodeIsVisible(node)
		local visible = true
		node = node.Parent
		while node and visible do
			visible = visible and node.Expanded
			node = node.Parent
		end
		return visible
	end

	-- Removes an object's tree node. Called when the object stops existing in the
	-- game tree.
	local function removeObject(object)
		local objectNode = NodeLookup[object]
		if not objectNode then
			return
		end

		local visible = nodeIsVisible(objectNode)

		Selection:Remove(object,true)

		local parent = objectNode.Parent
		remove(parent,objectNode.Index)
		NodeLookup[object] = nil
		connLookup[object]:disconnect()
		connLookup[object] = nil

		if visible then
			updateList()
		elseif nodeIsVisible(parent) then
			updateScroll()
		end
	end

	-- Moves a tree node to a new parent. Called when an existing object's parent
	-- changes.
	local function moveObject(object,parent)
		local objectNode = NodeLookup[object]
		if not objectNode then
			return
		end

		local parentNode = NodeLookup[parent]
		if not parentNode then
			return
		end

		local visible = nodeIsVisible(objectNode)

		remove(objectNode.Parent,objectNode.Index)
		objectNode.Parent = parentNode

		objectNode.Depth = depth(object)
		local function r(node,d)
			for i = 1,#node do
				node[i].Depth = d
				r(node[i],d+1)
			end
		end
		r(objectNode,objectNode.Depth+1)

		insert(parentNode,#parentNode+1,objectNode)

		if visible or nodeIsVisible(objectNode) then
			updateList()
		elseif nodeIsVisible(objectNode.Parent) then
			updateScroll()
		end
	end

	-- ScriptContext['/Libraries/LibraryRegistration/LibraryRegistration']
	-- This RobloxLocked object lets me index its properties for some reason

	local function check(object)
		return object.AncestryChanged
	end

	-- News a new tree node from an object. Called when an object starts
	-- existing in the game tree.
	local function addObject(object,noupdate)
		if script then
			-- protect against naughty RobloxLocked objects
			local s = pcall(check,object)
			if not s then
				return
			end
		end

		local parentNode = NodeLookup[object.Parent]
		if not parentNode then
			return
		end

		local objectNode = {
			Object = object;
			Parent = parentNode;
			Index = 0;
			Expanded = false;
			Selected = false;
			Depth = depth(object);
		}

		connLookup[object] = Connect(object.AncestryChanged,function(c,p)
			if c == object then
				if p == nil then
					removeObject(c)
				else
					moveObject(c,p)
				end
			end
		end)

		NodeLookup[object] = objectNode
		insert(parentNode,#parentNode+1,objectNode)

		if not noupdate then
			if nodeIsVisible(objectNode) then
				updateList()
			elseif nodeIsVisible(objectNode.Parent) then
				updateScroll()
			end
		end
	end

	do
		NodeLookup[Game] = {
			Object = Game;
			Parent = nil;
			Index = 0;
			Expanded = true;
		}

		Connect(Game.DescendantAdded,addObject)
		Connect(Game.DescendantRemoving,removeObject)

		local function get(o)
			return o:GetChildren()
		end

		local function r(o)
			local s,children = pcall(get,o)
			if s then
				for i = 1,#children do
					addObject(children[i],true)
					r(children[i])
				end
			end
		end

		for _,v in pairs(Option.Whitelist) do
			Spawn(function ()
				local service = game:WaitForChild(v)
				addObject(service,true)
				r(service)
				updateList()
			end)
		end

		scrollBar.VisibleSpace = math.ceil(listFrame.AbsoluteSize.y/ENTRY_BOUND)
		updateList()
	end

	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	---- Actions

	local actionButtons do
		actionButtons = {}

		local totalActions = (4) + 1
		local currentActions = totalActions
		local function makeButton(icon,over,name)
			local button = New(Icon('ImageButton',icon),{
				Name = name .. "Button";
				Visible = Option.Modifiable and Option.Selectable;
				Position = UDim2.new(1,-(GUI_SIZE+2)*currentActions+2,0.5,-GUI_SIZE/2);
				Size = UDim2.new(0,GUI_SIZE,0,GUI_SIZE);
				Parent = headerFrame;
			})

			local tipText = New('TextLabel',{
				Name = name .. "Text";
				Text = name;
				Visible = false;
				BackgroundTransparency = 1;
				TextXAlignment = 'Right';
				Font = FONT;
				FontSize = FONT_SIZE;
				Position = UDim2.new(0,0,0,0);
				Size = UDim2.new(1,-(GUI_SIZE+2)*totalActions,1,0);
				Parent = headerFrame;
			})


			button.MouseEnter:connect(function()
				Icon(button,over)
				tipText.Visible = true
			end)
			button.MouseLeave:connect(function()
				Icon(button,icon)
				tipText.Visible = false
			end)

			currentActions = currentActions - 1
			actionButtons[#actionButtons+1] = button
			return button
		end

		local clipboard = {}
		local function delete(o)
			o.Parent = nil
		end

		-- CUT
		makeButton(ACTION_CUT,ACTION_CUT_OVER,"Cut").MouseButton1Click:connect(function()
			if not Option.Modifiable then return end
			clipboard = {}
			local list = Selection.List
			local cut = {}
			for i = 1,#list do
				local obj = list[i]:Clone()
				if obj then
					table.insert(clipboard,obj)
					table.insert(cut,list[i])
				end
			end
			for i = 1,#cut do
				pcall(delete,cut[i])
			end
		end)

		-- COPY
		makeButton(ACTION_COPY,ACTION_COPY_OVER,"Copy").MouseButton1Click:connect(function()
			if not Option.Modifiable then return end
			clipboard = {}
			local list = Selection.List
			for i = 1,#list do
				table.insert(clipboard,list[i]:Clone())
			end
		end)

		-- PASTE
		makeButton(ACTION_PASTE,ACTION_PASTE_OVER,"Paste").MouseButton1Click:connect(function()
			if not Option.Modifiable then return end
			local parent = Selection.List[1] or Workspace
			for i = 1,#clipboard do
				clipboard[i]:Clone().Parent = parent
			end
		end)

		-- DELETE
		makeButton(ACTION_DELETE,ACTION_DELETE_OVER,"Delete").MouseButton1Click:connect(function()
			if not Option.Modifiable then return end
			local list = Selection:Get()
			for i = 1,#list do
				pcall(delete,list[i])
			end
			Selection:Set({})
		end)

		-- SORT
		-- local actionSort = makeButton(ACTION_SORT,ACTION_SORT_OVER,"Sort")
	end

	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	----------------------------------------------------------------
	---- Option Bindables

	do
		local optionCallback = {
			Modifiable = function(value)
				for i = 1,#actionButtons do
					actionButtons[i].Visible = value and Option.Selectable
				end
				cancelReparentDrag()
			end;
			Selectable = function(value)
				for i = 1,#actionButtons do
					actionButtons[i].Visible = value and Option.Modifiable
				end
				cancelSelectDrag()
				Selection:Set({})
			end;
		}

		local bindSetOption = Explorer_Panel:FindFirstChild("SetOption")
		if not bindSetOption then
			bindSetOption = New('BindableFunction',{Name = "SetOption"})
			bindSetOption.Parent = Explorer_Panel
		end

		bindSetOption.OnInvoke = function(optionName,value)
			if optionCallback[optionName] then
				Option[optionName] = value
				optionCallback[optionName](value)
			end
		end

		local bindGetOption = Explorer_Panel:FindFirstChild("GetOption")
		if not bindGetOption then
			bindGetOption = New('BindableFunction',{Name = "GetOption"})
			bindGetOption.Parent = Explorer_Panel
		end

		bindGetOption.OnInvoke = function(optionName)
			if optionName then
				return Option[optionName]
			else
				local options = {}
				for k,v in pairs(Option) do
					options[k] = v
				end
				return options
			end
		end
	end
end

ToggleExplorer.OnInvoke = function ()
	if not explorerToggled then
		explorerToggled = true
		CreateExplorer()
	end
	Explorer_Panel.ZIndex = 1
	Explorer_Panel.ZIndex = 2
end
