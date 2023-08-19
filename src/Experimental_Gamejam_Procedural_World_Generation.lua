
-- Written by AizakkuZ, feedback is much appreciated!
local _SERVER_STORAGE = game:GetService("ServerStorage")
local _GAME_CONFIG = workspace:FindFirstChild("Game_Configuration")
local _ASSETS = _SERVER_STORAGE:FindFirstChild("Assets")

local _SERVERDATA = _SERVER_STORAGE.Game_Data
local _PHYSICAL_REPRESENTATION = _ASSETS.Physical
local _PHYSICAL_OBJECTS = _PHYSICAL_REPRESENTATION.Objects
local _PHYSICAL_MATERIALS = _PHYSICAL_REPRESENTATION.Materials

local _GAME_DATA = require(_SERVERDATA.Retreival)

local _TERRAIN = _GAME_CONFIG.Terrain -- Containment folder for generated terrain blocks
local _OBJECTS = _GAME_CONFIG.Objects -- Containment folder for objects like Trees, Foliage, etc

--[[
Settings

- Maxima - (or Maximums)

Every maximum is measured in studs

Height - Highest level of terrain generation
Depth - Deepest level of terrain generation
Size - Size of each block or chunk of generation


- Materials -

Goes from number of materials down, so in this case water is the lowest level while dirt appears at the highest

]]

local World_Generation = {}
local Settings = {
	["Maxima"] = {
		Height = 200,
		Depth = 736, 
		Size = 10
	},
	
	["Materials"] = {
		[5] = _GAME_DATA.Get_Material("Dirt"), -- Obtains information about the material in this case Dirt
		[4] = _GAME_DATA.Get_Material("Dirt"),
		[3] = _GAME_DATA.Get_Material("Dirt"),
		[2] = _GAME_DATA.Get_Material("Sandstone"),
		[1] = _GAME_DATA.Get_Material("Sand"),
		[0] = _GAME_DATA.Get_Material("Water"),
	},

}

local function Return_Sorted_HeightArray_Till_MaxHeight(Maximum_Height)
	local HeightArray = {0} 
	
	for Index = 0, Maximum_Height do -- We go from lowest to highest depth
		local Randomized_Height = math.random(0, Index)

		table.insert(HeightArray, Randomized_Height)
	end
	
	table.sort(HeightArray) -- Now we sort as we used randomized number to obtain slightly different block hieghts
	return HeightArray
end

local function Return_Combined_Array(MainArray, AddedArray)
	for _, Value in pairs (AddedArray) do
		table.insert(MainArray, Value)
	end
	
	return MainArray
end

local function Return_Constructed_HeightArray()
	local Maximum_Height = Settings.Maxima.Height
	local HeightArray = Return_Sorted_HeightArray_Till_MaxHeight(Maximum_Height)
	local Temporary_Append_Array = {} -- Creates an array which will append to the already generated height array
	
	for Index = #HeightArray, 0, -1 do
		local Randomized_Height = math.random(0, Index)

		table.insert(Temporary_Append_Array, Randomized_Height)
	end
	
	table.sort(Temporary_Append_Array, function(a,b) return a > b end) -- randomized again so we must sort, but this time backwards creating a sort of pyramid using the middle point as a pivot
	HeightArray = Return_Combined_Array(HeightArray, Temporary_Append_Array)
	HeightArray[#HeightArray+1] = 0
	return HeightArray
end

local function Return_Material_Quadrant_Needed(Height)
	local Material_Amount = #Settings.Materials
	local Maximum_Height = Settings.Maxima.Height
	
	for Quadrant = 0, Material_Amount do -- We now need to understand what quadrant a particular height must get grouped into so we use some math 
		if math.round(math.clamp((Maximum_Height/Material_Amount * Quadrant-1), 0, math.huge)) >= Height and Height <= math.round(Maximum_Height/Material_Amount * Quadrant) then
			return Quadrant
		end
	end
end

local function Plot_Down_Objects(Material, Background_Part)
	local Background_Object = _GAME_DATA.Get_Physical_Object(Material.Background_Object) -- Now we can begin plotting down any needed foliage
	
	if Background_Object then
		local Object_Iterations = Background_Object.Iterations
		local Iteration = math.random(1, Object_Iterations)
		
		local Physical_Object = _PHYSICAL_OBJECTS[string.format("%s_%s", Background_Object.Name, tostring(Iteration))]:Clone()
		
		Physical_Object:PivotTo(Background_Part.CFrame * CFrame.new(0, Background_Part.Size.Y/2, 0))
		Physical_Object:PivotTo(Physical_Object:GetPivot() * CFrame.fromEulerAnglesXYZ(0, math.random(1, 30), 0))
		Physical_Object.Parent = _OBJECTS
	end	
end

local function Create_Spawn_Location(Main_Part)
	local Spawn_Location = Instance.new("SpawnLocation")
	
	Spawn_Location.CFrame = Main_Part.CFrame * CFrame.new(0, Main_Part.Size.Y/2, 0)
	Spawn_Location.CanCollide = false
	Spawn_Location.Transparency = 1
	Spawn_Location.Anchored = true
	Spawn_Location.Parent = workspace
end


World_Generation.Generate = function()
	local HeightArray = Return_Constructed_HeightArray()
	local World_Pivot = CFrame.new(0,0,0)
	local Maximum_Size = Settings.Maxima.Size
	
	print(HeightArray)
	for Index, Height in pairs (HeightArray) do
		local Material = Settings.Materials[Return_Material_Quadrant_Needed(Height)] 
		local Main_Part = _PHYSICAL_MATERIALS[Material.Name]:Clone()
		local Background_Part = _PHYSICAL_MATERIALS[Material.Background_Material]:Clone()
		
		Main_Part.Size = Vector3.new(16, Settings.Maxima.Depth + Height, (1.724 * Maximum_Size))
		Main_Part.CFrame = CFrame.new(0, 0, Index*(1.724 * Maximum_Size))

		Background_Part.Size = Vector3.new(8, Main_Part.Size.Y, Main_Part.Size.Z)
		Background_Part.CFrame = Main_Part.CFrame * CFrame.new(-12,0,0)
		
		Main_Part.Parent = _TERRAIN
		Background_Part.Parent = _TERRAIN	
		
		if Index % 2 == 0 then
			Plot_Down_Objects(Material, Background_Part)
		elseif Index == math.round(#HeightArray/2) then
			Create_Spawn_Location(Main_Part)
		end	
	end
end

return World_Generation

