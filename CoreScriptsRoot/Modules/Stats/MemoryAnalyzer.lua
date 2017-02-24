--[[
  Filename: MemoryAnalyzer.lua
  Written by: dbanks
  Description: Widget to display a table of who's-using-how-much-memory
--]]

--[[ Globals ]]--
local RowHeight = 30
local ValueWidthInPix = 100
local StdRowColor3 = Color3.new(0.25, 0.75, 0.75)
local AltRowColor3 = Color3.new(0.25, 0.25, 0.75)
local RowLabelTextColor3 = Color3.new(1, 1, 1)
local RowLabelBorderColor3 = Color3.new(1, 1, 1)
local RowLabelBorderWidth = 1


local LabelUDim2Position = UDim2.new(0, 0, 0, 0)
local LabelUDim2Size = UDim2.new(1, -ValueWidthInPix, 0, RowHeight)
local ValueUDim2Position = UDim2.new(1, -ValueWidthInPix, 0, 0)
local ValueUDim2Size = UDim2.new(0, ValueWidthInPix, 0, RowHeight)

--[[ Services ]]--
local CoreGuiService = game:GetService('CoreGui')
local StatsService = game:GetService("Stats")

--[[ Modules ]]--
local StatsUtils = require(CoreGuiService.RobloxGui.Modules.Stats.StatsUtils)

--[[ Helper functions ]]--
-- Read out the entire breakdown of memory data from performance
-- stats, in the form of an ordered array of {memory stat type, value}
-- pairs.
function __GetMemoryTypeValuePairs()
  local retVal = {}
          
  if StatsService == nil then
    return retVal
  end

  local performanceStats = StatsService:FindFirstChild("PerformanceStats")
  if performanceStats == nil then
    return retVal
  end  

  local memoryStats = performanceStats:FindFirstChild("Memory")          
  if memoryStats == nil then
    return retVal
  end
  
  local childen = memoryStats:GetChildren()
  for i, child in ipairs(childen) do
    local statType = child.Name
    local statValue = child:GetValue()
    table.insert(retVal, {statType, statValue})
  end
  
  return retVal
end

function __StyleLabel(label)
  label.TextXAlignment = Enum.TextXAlignment.Left
  label.TextColor3 = RowLabelTextColor3
  label.BackgroundTransparency = 1
  label.Position = UDim2.new(0, 5, 0, 0)
  label.Size = UDim2.new(1, -10, 1, 0)
end

function __StyleLabelFrame(labelFrame)
  labelFrame.BorderColor3 = RowLabelBorderColor3
  labelFrame.BorderSizePixel = RowLabelBorderWidth
  labelFrame.BackgroundTransparency = 0.6
end

--[[ Classes ]]--

--////////////////////////////////////
--
-- MemoryAnalyzerRowClass
-- A single row in the table.
--
--////////////////////////////////////
local MemoryAnalyzerRowClass = {}
MemoryAnalyzerRowClass.__index = MemoryAnalyzerRowClass


function MemoryAnalyzerRowClass.new(statType) 
  local self = {}
  setmetatable(self, MemoryAnalyzerRowClass)
      
  -- The gui widget for the row
  self._frame = Instance.new("Frame")
  self._frame.Name = "MemoryAnalyzerRowClass"
  self._frame.BackgroundTransparency = 1
  
  -- The label
  self._labelFrame = Instance.new("Frame")
  self._labelFrame.Name = "LabelFrame"
  self._labelFrame.Parent = self._frame
  self._labelFrame.Position = LabelUDim2Position
  self._labelFrame.Size = LabelUDim2Size
  __StyleLabelFrame(self._labelFrame)
  
  self._labelTextLabel = Instance.new("TextLabel")
  self._labelTextLabel.Name = "Label"
  self._labelTextLabel.Parent = self._labelFrame
  __StyleLabel(self._labelTextLabel)
  
  self._labelTextLabel.Text = StatsUtils.GetMemoryAnalyzerStatName(statType)

  -- The value
  self._valueFrame = Instance.new("Frame")
  self._valueFrame.Name = "ValueFrame"
  self._valueFrame.Parent = self._frame
  self._valueFrame.Position = ValueUDim2Position
  self._valueFrame.Size = ValueUDim2Size
  __StyleLabelFrame(self._valueFrame)
  
  self._valueTextLabel = Instance.new("TextLabel")
  self._valueTextLabel.Name = "Value"
  self._valueTextLabel.Parent = self._valueFrame
  __StyleLabel(self._valueTextLabel)
  
  return self
end  

function MemoryAnalyzerRowClass:setZIndex(zIndex) 
  self._frame.ZIndex = zIndex
  self._labelTextLabel.ZIndex = zIndex
  self._valueTextLabel.ZIndex = zIndex
end

function MemoryAnalyzerRowClass:setRowValue(value) 
  self._valueTextLabel.Text = string.format("%.3f", value)
end

function MemoryAnalyzerRowClass:getFrame()
  return self._frame
end

function MemoryAnalyzerRowClass:setRowNumber(rowNumber)
  if (rowNumber % 2 == 1) then 
    self._labelFrame.BackgroundColor3 = StdRowColor3
    self._valueFrame.BackgroundColor3 = StdRowColor3
  else
    self._labelFrame.BackgroundColor3 = AltRowColor3
    self._valueFrame.BackgroundColor3 = AltRowColor3
  end
end

--////////////////////////////////////
--
-- MemoryAnalyzerClass
-- The whole table.
--
--////////////////////////////////////
local MemoryAnalyzerClass = {}
MemoryAnalyzerClass.__index = MemoryAnalyzerClass

function MemoryAnalyzerClass.new(parentFrame) 
  local self = {}
  setmetatable(self, MemoryAnalyzerClass)
      
  -- The gui widget containing the whole thing.
  self._frame = Instance.new("Frame")
  self._frame.Name = "MemoryAnalyzerClass"
  self._frame.Parent = parentFrame
  self._frame.ZIndex = parentFrame.ZIndex
  self._frame.BackgroundTransparency = 1

  -- a map from statType to the Row used to display the stat.
  self._rowsByStatType = {}
  
  -- ordered array of rows.
  self._orderedRows = {}
  
  -- am I currently listening for updates?
  self._listenForUpdates = false
  
  -- things need to be laid out, either because I have new content or 
  -- the size of my parent container changed.
  -- Starts out as 'false' because there's no rows -> nothing to lay out.
  self._layoutDirty = false
  
  self._heightChangedCallback = nil
  self._heightInPix = 0
  
  return self
end

function MemoryAnalyzerClass:setHeightChangedCallback(callback)
  self._heightChangedCallback  = callback
end

function MemoryAnalyzerClass:__getOrMakeRowForStatType(statType) 
  if (self._rowsByStatType[statType] == nil) then
    local row = MemoryAnalyzerRowClass.new(statType)
    self._rowsByStatType[statType] = row
    table.insert(self._orderedRows, row)
    self._layoutDirty = true
  end
  return self._rowsByStatType[statType]
end
      
function MemoryAnalyzerClass:__updateStatValue(statType, value) 
  row = self:__getOrMakeRowForStatType(statType) 
  row:setRowValue(value)
end
      
-- Write latest stat values into each row.
function MemoryAnalyzerClass:renderUpdates()
  local typeValuePairs = __GetMemoryTypeValuePairs()
  for i, pair in ipairs(typeValuePairs) do
    self:__updateStatValue(pair[1], pair[2])
  end
  
  if self._layoutDirty then 
    self:__layoutRows()
  end
end
      
function MemoryAnalyzerClass:__layoutRows()    
  self._layoutDirty = false
  self._frame:ClearAllChildren()
  for i, row in ipairs(self._orderedRows) do 
    local frame = row:getFrame()
    frame.Size = UDim2.new(1, 0, 0, RowHeight)
    frame.Position = UDim2.new(0, 0, 0, RowHeight * (i - 1))
    frame.Parent = self._frame
    row:setZIndex(self._frame.ZIndex)
    row:setRowNumber(i)
  end  
  
  self._heightInPix = RowHeight * #self._orderedRows
  self._frame.Size = UDim2.new(1, 0, 0, newHeight)
  self._frame.Position = UDim2.new(0, 0, 0, 0)

  if (self._heightChangedCallback) then 
    self._heightChangedCallback(newHeight)
  end
end

function MemoryAnalyzerClass:getHeightInPix()
  return self._heightInPix
end

-- Start a thread that wakes up every n seconds
-- and updates contents of stats widget.
function MemoryAnalyzerClass:startListeningForUpdates()
  if (self._listenForUpdates) then 
    return
  end
  self._listenForUpdates = true
  
  spawn(function()
    while(self._listenForUpdates) do 
      self:renderUpdates()
      wait(1)
    end
  end)
end

-- Stop the thread that does the updates.
function MemoryAnalyzerClass:stopListeningForUpdates()        
  self._listenForUpdates = false
end
      
return MemoryAnalyzerClass