secretMod = RegisterMod("Potential Secret Locations!", 1)

require("scripts.minimapapi.init")
local MinimapAPI = require("scripts.minimapapi")

--13x13 grid of map w/ potential locations.
local matrix = {}

--ID lists for real locations. Allows for tracking of multiple.
local customSecretListIDs = {}
local customSuperSecretListIDs = {}

--Tracks total number of secret rooms found. 
--Prevents hiding possibilities until all have been found.
local secretCount = 0
local superSecretCount = 0
local secretFound = {}
local superSecretFound = { }

--This mod should avoid doing extra work if the player has items like blue map or spelunker's hat already.
local vanillaRevealSecret = false
local vanillaRevealSuperSecret = false
local hasLuna = false

local Enums = {
	--Room Type enums
	NO_ROOM = -1,
	SECRET_FALSE = 994,
	SUPERSECRET_FALSE = 995,
	ULTRASECRET_FALSE = 996,
	SECRET = 997,
	SUPERSECRET = 998,
	ULTRASECRET = 999,
	
	--Grid Type enums
	PATH = 28,
	OBSTACLE = 29,
	EMPTY = 30,
	DOOR = 31,
}

local function resetMatrix()
	for i = 1, 13 do
		matrix[i] = {}
		for j = 1, 13 do
			matrix[i][j] = Enums.NO_ROOM
		end
	end
end

local function notContainsVal(set, val)
	for k, v in pairs(set) do
		if v==val then return false end
	end
	return true
end

--Adds rooms to the map if needed.
local function searchForMapAdditions(row, column, index, row_offset, column_offset)
	if (row+row_offset) > 0 and (row+row_offset) < 14 and (column+column_offset) > 0 and (column+column_offset) < 14 then
		local index_offset = 13*row_offset + column_offset
		if matrix[row+row_offset][column+column_offset] == Enums.SECRET_FALSE or matrix[row+row_offset][column+column_offset] == Enums.SECRET then 
			if vanillaRevealSecret == false then
				--secret
				if notContainsVal(customSecretListIDs, (index+index_offset)) and notContainsVal(secretFound, (index+index_offset)) then
					customSecretListIDs[#customSecretListIDs + 1] = index+index_offset
					MinimapAPI:AddRoom{ID=(index+index_offset),Position=Vector(column - 1 + column_offset, row - 1 + row_offset),Shape=RoomShape.ROOMSHAPE_1x1,PermanentIcons={"SecretRoom"},Type=RoomType.ROOM_SECRET,DisplayFlags=5}
				end
			end
		elseif matrix[row+row_offset][column+column_offset] == Enums.SUPERSECRET_FALSE or matrix[row+row_offset][column+column_offset] == Enums.SUPERSECRET then
			if vanillaRevealSuperSecret == false then
				--super secret
				if notContainsVal(customSuperSecretListIDs, (index+index_offset)) and notContainsVal(superSecretFound, (index+index_offset)) then
					customSuperSecretListIDs[#customSuperSecretListIDs + 1] = index+index_offset
					MinimapAPI:AddRoom{ID=(index+index_offset),Position=Vector(column - 1 + column_offset, row - 1 + row_offset),Shape=RoomShape.ROOMSHAPE_1x1,PermanentIcons={"SuperSecretRoom"},Type=RoomType.ROOM_SUPERSECRET,DisplayFlags=5}
				end
			end
		end
	end
end

local function removeRoom(index, offset)
	if offset == nil then offset = 0 end
	if type(index) == "number" then
		MinimapAPI:RemoveRoomByID(index+offset)
	end
end

--debugging function
local function printMatrix(printSecretGuesses, printSuperGuesses, printUltraGuesses, printSecret, printSuperSecret, printUltraSecret)
	print("     _C1 _C2 _C3 _C4 _C5 _C6 _C7 _C8 _C9 C10 C11 C12 C13")
	for i = 1, 13 do
		str = i..". "
		if i < 10 then str = str.." " end
		for j = 1, 13 do
			if type(matrix[i][j]) == "string" then
				str = str.." "..matrix[i][j]
			elseif matrix[i][j] > 993 then 
				if printSecretGuesses and matrix[i][j] == Enums.SECRET_FALSE then 
					--potential secret rooms
					str = str.." _SC"
				elseif printSuperGuesses and matrix[i][j] == Enums.SUPERSECRET_FALSE then 
					--potential super secret rooms
					str = str.." _SS"
				elseif printUltraGuesses and matrix[i][j] == Enums.ULTRASECRET_FALSE then 
					--potential ultra secret rooms
					str = str.." _US"
				elseif printSecret and matrix[i][j] == Enums.SECRET then 
					--secret rooms
					str = str.." SEC"
				elseif printSuperSecret and matrix[i][j] == Enums.SUPERSECRET then
					--super secret rooms
					str = str.." SUP"
				elseif printUltraSecret and matrix[i][j] == Enums.ULTRASECRET then
					--ultra secret rooms
					str = str.." ULT"
				else
					str = str.."    "
				end
			elseif matrix[i][j] == Enums.NO_ROOM then
				str = str.."    "
			elseif matrix[i][j] < 10 then 
				str = str.." 00"..matrix[i][j]
			elseif matrix[i][j] < 100 then
				str = str.." 0"..matrix[i][j]
			else
				str = str.." "..matrix[i][j]
			end
		end
		if str.gsub(str, "%s+", "") ~= i.."." then print(str) end
	end
end

--debugging function
local function printGrid(height, width, grid)
	if grid == nil then return end
	print()
	for i = 0, height - 1 do
		local str = i..". "
		if i < 10 then str = str.." " end
		
		for j = 0, width - 1 do
			if grid[i] == nil then return end
			
			if grid[i][j] == Enums.EMPTY then
				str = str.."_ "
			elseif grid[i][j] == Enums.OBSTACLE then
				str = str.."O "
			elseif grid[i][j] == Enums.PATH then
				str = str.."P "
			elseif grid[i][j] == Enums.DOOR then
				str = str.."D "
			else
				str = str.."? "
			end
		end
		print(str)
	end
end

local function clearFakeSecrets(isSuperSecret)
	if isSuperSecret == false then
		--Remove fake secret rooms on map
		for k, v in pairs(customSecretListIDs) do
			removeRoom(v)
		end
				
		--Remove fake secret rooms on matrix
		for i = 1, 13 do
			for j = 1, 13 do
				if matrix[i][j] == Enums.SECRET_FALSE then
					matrix[i][j] = Enums.NO_ROOM
				end
			end
		end
	else
		--Remove fake super secret rooms on map
		for k, v in pairs(customSuperSecretListIDs) do
			removeRoom(v)
		end
				
		--Remove fake secret rooms on matrix
		for i = 1, 13 do
			for j = 1, 13 do
				if matrix[i][j] == Enums.SUPERSECRET_FALSE then
					matrix[i][j] = Enums.NO_ROOM
				end
			end
		end
	end
end

local function checkNeighborsForReal(index, shape)
	
	if shape == nil then shape = RoomShape.ROOMSHAPE_1x1 end
	
	local row, column = ((math.floor(index/13) + 1)), ((index % 13) + 1)
	
	if shape == RoomShape.ROOMSHAPE_1x1 or shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
		--[[
					1
				  3 X 4
					2
					
			1: index - 13
			2: index + 13
			3: index - 1
			4: index + 1
		]]
	
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET or matrix[row-1][column] == Enums.SECRET) then return true end
		if row < 13 and (matrix[row+1][column] == Enums.SUPERSECRET or matrix[row+1][column] == Enums.SECRET) then return true end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET or matrix[row][column-1] == Enums.SECRET) then return true end
		if column < 13 and (matrix[row][column+1] == Enums.SUPERSECRET or matrix[row][column+1] == Enums.SECRET) then return true end

	elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
		--[[
					1
				  3 X 5 
				  4 X 6
					2
			1: index - 13
			2: index + 26
			3: index - 1
			4: index + 12
			5: index + 1
			6: index + 14
		]]
		
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET or matrix[row-1][column] == Enums.SECRET) then return true end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET or matrix[row+2][column] == Enums.SECRET) then return true end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET or matrix[row][column-1] == Enums.SECRET) then return true end
		if row < 13 and column > 1 and (matrix[row+1][column-1] == Enums.SUPERSECRET or matrix[row+1][column-1] == Enums.SECRET)then return true end
		if column < 13 and (matrix[row][column+1] == Enums.SUPERSECRET or matrix[row][column+1] == Enums.SECRET) then return true end
		if row < 13 and column < 13 and (matrix[row+1][column+1] == Enums.SUPERSECRET or matrix[row+1][column+1] == Enums.SECRET)then return true end
		
	elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
		--[[
					2 3
				  1 X X 4
				    5 6
			1: index - 1
			2: index - 13
			3: index - 12
			4: index + 2
			5: index + 13
			6: index + 14
		]]
		
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET or matrix[row][column-1] == Enums.SECRET) then return true end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET or matrix[row-1][column] == Enums.SECRET) then return true end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET or matrix[row-1][column+1] == Enums.SECRET) then return true end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET or matrix[row][column+2] == Enums.SECRET) then return true end
		if row < 13 and (matrix[row+1][column] == Enums.SUPERSECRET or matrix[row+1][column] == Enums.SECRET) then return true end
		if row < 13 and column < 13 and (matrix[row+1][column+1] == Enums.SUPERSECRET or matrix[row+1][column+1] == Enums.SECRET)then return true end
	
	elseif shape == RoomShape.ROOMSHAPE_2x2 then
		--[[
					3 4
				  2 X X 5
				  1 X X 6
					7 8
			1: index + 12
			2: index - 1
			3: index - 13
			4: index - 12
			5: index + 2
			6: index + 15
			7: index + 26
			8: index + 27
		]]
		
		if column > 1  and row < 13 and (matrix[row+1][column-1] == Enums.SUPERSECRET or matrix[row+1][column-1] == Enums.SECRET) then return true end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET or matrix[row][column-1] == Enums.SECRET) then return true end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET or matrix[row-1][column] == Enums.SECRET) then return true end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET or matrix[row-1][column+1] == Enums.SECRET) then return true end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET or matrix[row][column+2] == Enums.SECRET) then return true end
		if row < 13 and column < 12 and (matrix[row+1][column+2] == Enums.SUPERSECRET or matrix[row+1][column+2] == Enums.SECRET) then return true end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET or matrix[row+2][column] == Enums.SECRET) then return true end
		if row < 12 and column < 13 and (matrix[row+2][column+1] == Enums.SUPERSECRET or matrix[row+2][column+1] == Enums.SECRET) then return true end
		
	elseif shape == RoomShape.ROOMSHAPE_LTL then
		--[[
					  3
				    2 X 4
				  1 X X 5
					6 7
			1: index + 12
			2: index
			3: index - 12
			4: index + 2
			5: index + 15
			6: index + 26
			7: index + 27
		]]
		
		--Remove adjacent secret/super secret rooms on matrix.
		if column > 1  and row < 13 and (matrix[row+1][column-1] == Enums.SUPERSECRET or matrix[row+1][column-1] == Enums.SECRET) then return true end
		if (matrix[row][column] == Enums.SUPERSECRET or matrix[row][column] == Enums.SECRET) then matrix[row][column] = Enums.NO_ROOM end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET or matrix[row-1][column+1] == Enums.SECRET) then return true end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET or matrix[row][column+2] == Enums.SECRET) then return true end
		if row < 13 and column < 12 and (matrix[row+1][column+2] == Enums.SUPERSECRET or matrix[row+1][column+2] == Enums.SECRET) then return true end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET or matrix[row+2][column] == Enums.SECRET) then return true end
		if row < 12 and column < 13 and (matrix[row+2][column+1] == Enums.SUPERSECRET or matrix[row+2][column+1] == Enums.SECRET) then return true end
		
	elseif shape == RoomShape.ROOMSHAPE_LTR then
		--[[
					3 
				  2 X 4 
				  1 X X 5
					6 7
			1: index + 12
			2: index - 1
			3: index - 13
			4: index + 1
			5: index + 15
			6: index + 26
			7: index + 27
		]]
		
		if column > 1  and row < 13 and (matrix[row+1][column-1] == Enums.SUPERSECRET or matrix[row+1][column-1] == Enums.SECRET) then return true end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET or matrix[row][column-1] == Enums.SECRET) then return true end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET or matrix[row-1][column] == Enums.SECRET) then return true end
		if column < 13 and (matrix[row][column+1] == Enums.SUPERSECRET or matrix[row][column+1] == Enums.SECRET) then return true end
		if row < 13 and column < 12 and (matrix[row+1][column+2] == Enums.SUPERSECRET or matrix[row+1][column+2] == Enums.SECRET) then return true end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET or matrix[row+2][column] == Enums.SECRET) then return true end
		if row < 12 and column < 13 and (matrix[row+2][column+1] == Enums.SUPERSECRET or matrix[row+2][column+1] == Enums.SECRET) then return true end
	
	elseif shape == RoomShape.ROOMSHAPE_LBL then
		--[[
					3 4
				  2 X X 5
				    1 X 6
					  7
			1: index + 13
			2: index - 1
			3: index - 13
			4: index - 12
			5: index + 2
			6: index + 15
			7: index + 27
		]]
		
		if row < 13 and (matrix[row+1][column] == Enums.SUPERSECRET or matrix[row+1][column] == Enums.SECRET) then return true end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET or matrix[row][column-1] == Enums.SECRET) then return true end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET or matrix[row-1][column] == Enums.SECRET) then return true end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET or matrix[row-1][column+1] == Enums.SECRET) then return true end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET or matrix[row][column+2] == Enums.SECRET) then return true end
		if row < 13 and column < 12 and (matrix[row+1][column+2] == Enums.SUPERSECRET or matrix[row+1][column+2] == Enums.SECRET) then return true end
		if row < 12 and column < 13 and (matrix[row+2][column+1] == Enums.SUPERSECRET or matrix[row+2][column+1] == Enums.SECRET) then return true end
		
	elseif shape == RoomShape.ROOMSHAPE_LBR then
		--[[
					3 4
				  2 X X 5
				  1 X 6
					7 
			1: index + 12
			2: index - 1
			3: index - 13
			4: index - 12
			5: index + 2
			6: index + 14
			7: index + 26
		]]
		
		if column > 1  and row < 13 and (matrix[row+1][column-1] == Enums.SUPERSECRET or matrix[row+1][column-1] == Enums.SECRET) then return true end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET or matrix[row][column-1] == Enums.SECRET) then return true end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET or matrix[row-1][column] == Enums.SECRET) then return true end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET or matrix[row-1][column+1] == Enums.SECRET) then return true end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET or matrix[row][column+2] == Enums.SECRET) then return true end
		if row < 13 and column < 13 and (matrix[row+1][column+1] == Enums.SUPERSECRET or matrix[row+1][column+1] == Enums.SECRET) then return true end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET or matrix[row+2][column] == Enums.SECRET) then return true end

	end
	
	return false
end

--index = level.GetCurrentRoomDesc(level).GridIndex
--Clears neighboring secrets depending on room shape.
local function clearNeighboringSecrets(index, shape)

	if shape == nil then shape = RoomShape.ROOMSHAPE_1x1 end
	
	local row, column = ((math.floor(index/13) + 1)), ((index % 13) + 1)
	
	if shape == RoomShape.ROOMSHAPE_1x1 or shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
		--[[
					1
				  3 X 4
					2
					
			1: index - 13
			2: index + 13
			3: index - 1
			4: index + 1
		]]
	
		--Remove adjacent secret/super secret rooms on matrix.
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET_FALSE or matrix[row-1][column] == Enums.SECRET_FALSE) then matrix[row-1][column] = Enums.NO_ROOM end
		if row < 13 and (matrix[row+1][column] == Enums.SUPERSECRET_FALSE or matrix[row+1][column] == Enums.SECRET_FALSE) then matrix[row+1][column] = Enums.NO_ROOM end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET_FALSE or matrix[row][column-1] == Enums.SECRET_FALSE) then matrix[row][column-1] = Enums.NO_ROOM end
		if column < 13 and (matrix[row][column+1] == Enums.SUPERSECRET_FALSE or matrix[row][column+1] == Enums.SECRET_FALSE) then matrix[row][column+1] = Enums.NO_ROOM end
			
		--Remove adjacent super secret rooms on map
		for k, v in pairs(customSuperSecretListIDs) do
			if v == (index-13) or v == (index+13) or v == (index-1) or v == (index+1) then 
				removeRoom(v) 
				table.remove(customSuperSecretListIDs, k)
			end
		end
			
		--Remove adjacent secret rooms on map
		for k, v in pairs(customSecretListIDs) do
			if v == (index-13) or v == (index+13) or v == (index-1) or v == (index+1) then 
				removeRoom(v) 
				table.remove(customSecretListIDs, k)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
		--[[
					1
				  3 X 5 
				  4 X 6
					2
			1: index - 13
			2: index + 26
			3: index - 1
			4: index + 12
			5: index + 1
			6: index + 14
		]]
		
		--Remove adjacent secret/super secret rooms on matrix.
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET_FALSE or matrix[row-1][column] == Enums.SECRET_FALSE) then matrix[row-1][column] = Enums.NO_ROOM end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET_FALSE or matrix[row+2][column] == Enums.SECRET_FALSE) then matrix[row+2][column] = Enums.NO_ROOM end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET_FALSE or matrix[row][column-1] == Enums.SECRET_FALSE) then matrix[row][column-1] = Enums.NO_ROOM end
		if row < 13 and column > 1 and (matrix[row+1][column-1] == Enums.SECRET_FALSE or matrix[row+1][column-1] == Enums.SUPERSECRET_FALSE)then matrix[row+1][column-1] = Enums.NO_ROOM end
		if column < 13 and (matrix[row][column+1] == Enums.SUPERSECRET_FALSE or matrix[row][column+1] == Enums.SECRET_FALSE) then matrix[row][column+1] = Enums.NO_ROOM end
		if row < 13 and column < 13 and (matrix[row+1][column+1] == Enums.SECRET_FALSE or matrix[row+1][column+1] == Enums.SUPERSECRET_FALSE)then matrix[row+1][column+1] = Enums.NO_ROOM end
		
		
		--Remove adjacent super secret rooms on map
		for k, v in pairs(customSuperSecretListIDs) do
			if v == (index-13) or v == (index+26) or v == (index-1) or v == (index+12) or v == (index+1) or v == (index + 14) then 
				removeRoom(v) 
				table.remove(customSuperSecretListIDs, k)
			end
		end
			
		--Remove adjacent secret rooms on map
		for k, v in pairs(customSecretListIDs) do
			if v == (index-13) or v == (index+26) or v == (index-1) or v == (index+12) or v == (index+1) or v == (index + 14) then 
				removeRoom(v) 
				table.remove(customSecretListIDs, k)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
		--[[
					2 3
				  1 X X 4
				    5 6
			1: index - 1
			2: index - 13
			3: index - 12
			4: index + 2
			5: index + 13
			6: index + 14
		]]
		
		--Remove adjacent secret/super secret rooms on matrix.
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET_FALSE or matrix[row][column-1] == Enums.SECRET_FALSE) then matrix[row][column-1] = Enums.NO_ROOM end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET_FALSE or matrix[row-1][column] == Enums.SECRET_FALSE) then matrix[row-1][column] = Enums.NO_ROOM end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET_FALSE or matrix[row-1][column+1] == Enums.SECRET_FALSE) then matrix[row-1][column+1] = Enums.NO_ROOM end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET_FALSE or matrix[row][column+2] == Enums.SECRET_FALSE) then matrix[row][column+2] = Enums.NO_ROOM end
		if row < 13 and (matrix[row+1][column] == Enums.SUPERSECRET_FALSE or matrix[row+1][column] == Enums.SECRET_FALSE) then matrix[row+1][column] = Enums.NO_ROOM end
		if row < 13 and column < 13 and (matrix[row+1][column+1] == Enums.SECRET_FALSE or matrix[row+1][column+1] == Enums.SUPERSECRET_FALSE)then matrix[row+1][column+1] = Enums.NO_ROOM end
	
		
		--Remove adjacent super secret rooms on map
		for k, v in pairs(customSuperSecretListIDs) do
			if v == (index-1) or v == (index-13) or v == (index-12) or v == (index+2) or v == (index+13) or v == (index+14) then
				removeRoom(v) 
				table.remove(customSuperSecretListIDs, k)
			end
		end
			
		--Remove adjacent secret rooms on map
		for k, v in pairs(customSecretListIDs) do
			if v == (index-1) or v == (index-13) or v == (index-12) or v == (index+2) or v == (index+13) or v == (index+14) then
				removeRoom(v) 
				table.remove(customSecretListIDs, k)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_2x2 then
		--[[
					3 4
				  2 X X 5
				  1 X X 6
					7 8
			1: index + 12
			2: index - 1
			3: index - 13
			4: index - 12
			5: index + 2
			6: index + 15
			7: index + 26
			8: index + 27
		]]
		
		--Remove adjacent secret/super secret rooms on matrix.
		if column > 1  and row < 13 and (matrix[row+1][column-1] == Enums.SUPERSECRET_FALSE or matrix[row+1][column-1] == Enums.SECRET_FALSE) then matrix[row+1][column-1] = Enums.NO_ROOM end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET_FALSE or matrix[row][column-1] == Enums.SECRET_FALSE) then matrix[row][column-1] = Enums.NO_ROOM end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET_FALSE or matrix[row-1][column] == Enums.SECRET_FALSE) then matrix[row-1][column] = Enums.NO_ROOM end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET_FALSE or matrix[row-1][column+1] == Enums.SECRET_FALSE) then matrix[row-1][column+1] = Enums.NO_ROOM end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET_FALSE or matrix[row][column+2] == Enums.SECRET_FALSE) then matrix[row][column+2] = Enums.NO_ROOM end
		if row < 13 and column < 12 and (matrix[row+1][column+2] == Enums.SUPERSECRET_FALSE or matrix[row+1][column+2] == Enums.SECRET_FALSE) then matrix[row+1][column+2] = Enums.NO_ROOM end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET_FALSE or matrix[row+2][column] == Enums.SECRET_FALSE) then matrix[row+2][column] = Enums.NO_ROOM end
		if row < 12 and column < 13 and (matrix[row+2][column+1] == Enums.SUPERSECRET_FALSE or matrix[row+2][column+1] == Enums.SECRET_FALSE) then matrix[row+2][column+1] = Enums.NO_ROOM end
		
		
		--Remove adjacent super secret rooms on map
		for k, v in pairs(customSuperSecretListIDs) do
			if v == (index+ 12) or v == (index-1) or v == (index-13) or v == (index-12) or v == (index+2) or v == (index+15) or v == (index+26) or v == (index+27) then
				removeRoom(v) 
				table.remove(customSuperSecretListIDs, k)
			end
		end
			
		--Remove adjacent secret rooms on map
		for k, v in pairs(customSecretListIDs) do
			if v == (index+ 12) or v == (index-1) or v == (index-13) or v == (index-12) or v == (index+2) or v == (index+15) or v == (index+26) or v == (index+27) then
				removeRoom(v) 
				table.remove(customSecretListIDs, k)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_LTL then
		--[[
					  3
				    2 X 4
				  1 X X 5
					6 7
			1: index + 12
			2: index
			3: index - 12
			4: index + 2
			5: index + 15
			6: index + 26
			7: index + 27
		]]
		
		--Remove adjacent secret/super secret rooms on matrix.
		if column > 1  and row < 13 and (matrix[row+1][column-1] == Enums.SUPERSECRET_FALSE or matrix[row+1][column-1] == Enums.SECRET_FALSE) then matrix[row+1][column-1] = Enums.NO_ROOM end
		if (matrix[row][column] == Enums.SUPERSECRET_FALSE or matrix[row][column] == Enums.SECRET_FALSE) then matrix[row][column] = Enums.NO_ROOM end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET_FALSE or matrix[row-1][column+1] == Enums.SECRET_FALSE) then matrix[row-1][column+1] = Enums.NO_ROOM end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET_FALSE or matrix[row][column+2] == Enums.SECRET_FALSE) then matrix[row][column+2] = Enums.NO_ROOM end
		if row < 13 and column < 12 and (matrix[row+1][column+2] == Enums.SUPERSECRET_FALSE or matrix[row+1][column+2] == Enums.SECRET_FALSE) then matrix[row+1][column+2] = Enums.NO_ROOM end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET_FALSE or matrix[row+2][column] == Enums.SECRET_FALSE) then matrix[row+2][column] = Enums.NO_ROOM end
		if row < 12 and column < 13 and (matrix[row+2][column+1] == Enums.SUPERSECRET_FALSE or matrix[row+2][column+1] == Enums.SECRET_FALSE) then matrix[row+2][column+1] = Enums.NO_ROOM end
		
		
		--Remove adjacent super secret rooms on map
		for k, v in pairs(customSuperSecretListIDs) do
			if v == (index+ 12) or v == (index) or v == (index-12) or v == (index+2) or v == (index+15) or v == (index+26) or v == (index+27) then
				removeRoom(v) 
				table.remove(customSuperSecretListIDs, k)
			end
		end
			
		--Remove adjacent secret rooms on map
		for k, v in pairs(customSecretListIDs) do
			if v == (index+ 12) or v == (index) or v == (index-12) or v == (index+2) or v == (index+15) or v == (index+26) or v == (index+27) then
				removeRoom(v) 
				table.remove(customSecretListIDs, k)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_LTR then
		--[[
					3 
				  2 X 4 
				  1 X X 5
					6 7
			1: index + 12
			2: index - 1
			3: index - 13
			4: index + 1
			5: index + 15
			6: index + 26
			7: index + 27
		]]
		
		--Remove adjacent secret/super secret rooms on matrix.
		if column > 1  and row < 13 and (matrix[row+1][column-1] == Enums.SUPERSECRET_FALSE or matrix[row+1][column-1] == Enums.SECRET_FALSE) then matrix[row+1][column-1] = Enums.NO_ROOM end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET_FALSE or matrix[row][column-1] == Enums.SECRET_FALSE) then matrix[row][column-1] = Enums.NO_ROOM end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET_FALSE or matrix[row-1][column] == Enums.SECRET_FALSE) then matrix[row-1][column] = Enums.NO_ROOM end
		if column < 13 and (matrix[row][column+1] == Enums.SUPERSECRET_FALSE or matrix[row][column+1] == Enums.SECRET_FALSE) then matrix[row][column+1] = Enums.NO_ROOM end
		if row < 13 and column < 12 and (matrix[row+1][column+2] == Enums.SUPERSECRET_FALSE or matrix[row+1][column+2] == Enums.SECRET_FALSE) then matrix[row+1][column+2] = Enums.NO_ROOM end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET_FALSE or matrix[row+2][column] == Enums.SECRET_FALSE) then matrix[row+2][column] = Enums.NO_ROOM end
		if row < 12 and column < 13 and (matrix[row+2][column+1] == Enums.SUPERSECRET_FALSE or matrix[row+2][column+1] == Enums.SECRET_FALSE) then matrix[row+2][column+1] = Enums.NO_ROOM end
		
		
		--Remove adjacent super secret rooms on map
		for k, v in pairs(customSuperSecretListIDs) do
			if v == (index+ 12) or v == (index-1) or v == (index-13) or v == (index+1) or v == (index+15) or v == (index+26) or v == (index+27) then
				removeRoom(v) 
				table.remove(customSuperSecretListIDs, k)
			end
		end
			
		--Remove adjacent secret rooms on map
		for k, v in pairs(customSecretListIDs) do
			if v == (index+ 12) or v == (index-1) or v == (index-13) or v == (index+1) or v == (index+15) or v == (index+26) or v == (index+27) then
				removeRoom(v) 
				table.remove(customSecretListIDs, k)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_LBL then
		--[[
					3 4
				  2 X X 5
				    1 X 6
					  7
			1: index + 13
			2: index - 1
			3: index - 13
			4: index - 12
			5: index + 2
			6: index + 15
			7: index + 27
		]]
		
		--Remove adjacent secret/super secret rooms on matrix.
		if row < 13 and (matrix[row+1][column] == Enums.SUPERSECRET_FALSE or matrix[row+1][column] == Enums.SECRET_FALSE) then matrix[row+1][column] = Enums.NO_ROOM end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET_FALSE or matrix[row][column-1] == Enums.SECRET_FALSE) then matrix[row][column-1] = Enums.NO_ROOM end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET_FALSE or matrix[row-1][column] == Enums.SECRET_FALSE) then matrix[row-1][column] = Enums.NO_ROOM end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET_FALSE or matrix[row-1][column+1] == Enums.SECRET_FALSE) then matrix[row-1][column+1] = Enums.NO_ROOM end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET_FALSE or matrix[row][column+2] == Enums.SECRET_FALSE) then matrix[row][column+2] = Enums.NO_ROOM end
		if row < 13 and column < 12 and (matrix[row+1][column+2] == Enums.SUPERSECRET_FALSE or matrix[row+1][column+2] == Enums.SECRET_FALSE) then matrix[row+1][column+2] = Enums.NO_ROOM end
		if row < 12 and column < 13 and (matrix[row+2][column+1] == Enums.SUPERSECRET_FALSE or matrix[row+2][column+1] == Enums.SECRET_FALSE) then matrix[row+2][column+1] = Enums.NO_ROOM end
		
		
		--Remove adjacent super secret rooms on map
		for k, v in pairs(customSuperSecretListIDs) do
			if v == (index+ 13) or v == (index-1) or v == (index-13) or v == (index-12) or v == (index+2) or v == (index+15) or v == (index+27) then
				removeRoom(v) 
				table.remove(customSuperSecretListIDs, k)
			end
		end
			
		--Remove adjacent secret rooms on map
		for k, v in pairs(customSecretListIDs) do
			if v == (index+13) or v == (index-1) or v == (index-13) or v == (index-12) or v == (index+2) or v == (index+15) or v == (index+27) then
				removeRoom(v) 
				table.remove(customSecretListIDs, k)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_LBR then
		--[[
					3 4
				  2 X X 5
				  1 X 6
					7 
			1: index + 12
			2: index - 1
			3: index - 13
			4: index - 12
			5: index + 2
			6: index + 14
			7: index + 26
		]]
		
		--Remove adjacent secret/super secret rooms on matrix.
		if column > 1  and row < 13 and (matrix[row+1][column-1] == Enums.SUPERSECRET_FALSE or matrix[row+1][column-1] == Enums.SECRET_FALSE) then matrix[row+1][column-1] = Enums.NO_ROOM end
		if column > 1 and (matrix[row][column-1] == Enums.SUPERSECRET_FALSE or matrix[row][column-1] == Enums.SECRET_FALSE) then matrix[row][column-1] = Enums.NO_ROOM end
		if row > 1 and (matrix[row-1][column] == Enums.SUPERSECRET_FALSE or matrix[row-1][column] == Enums.SECRET_FALSE) then matrix[row-1][column] = Enums.NO_ROOM end
		if row > 1 and column < 13 and (matrix[row-1][column+1] == Enums.SUPERSECRET_FALSE or matrix[row-1][column+1] == Enums.SECRET_FALSE) then matrix[row-1][column+1] = Enums.NO_ROOM end
		if column < 12 and (matrix[row][column+2] == Enums.SUPERSECRET_FALSE or matrix[row][column+2] == Enums.SECRET_FALSE) then matrix[row][column+2] = Enums.NO_ROOM end
		if row < 13 and column < 13 and (matrix[row+1][column+1] == Enums.SUPERSECRET_FALSE or matrix[row+1][column+1] == Enums.SECRET_FALSE) then matrix[row+1][column+1] = Enums.NO_ROOM end
		if row < 12 and (matrix[row+2][column] == Enums.SUPERSECRET_FALSE or matrix[row+2][column] == Enums.SECRET_FALSE) then matrix[row+2][column] = Enums.NO_ROOM end
		
		
		--Remove adjacent super secret rooms on map
		for k, v in pairs(customSuperSecretListIDs) do
			if v == (index+12) or v == (index-1) or v == (index-13) or v == (index-12) or v == (index+2) or v == (index+14) or v == (index+26) then
				removeRoom(v) 
				table.remove(customSuperSecretListIDs, k)
			end
		end
			
		--Remove adjacent secret rooms on map
		for k, v in pairs(customSecretListIDs) do
			if v == (index+12) or v == (index-1) or v == (index-13) or v == (index-12) or v == (index+2) or v == (index+14) or v == (index+26) then
				removeRoom(v) 
				table.remove(customSecretListIDs, k)
			end
		end
	end
end

--Fill matrix with the floor's possible secret/super secret room locations by just looking at the map.
local function findPossibilities()
	
	resetMatrix()
	customSecretListIDs = {}
	customSuperSecretListIDs = {}
	secretFound = {}
	superSecretFound = { }
	local level = Game():GetLevel()
	local rooms = level:GetRooms()
	
	--don't do anything in the ascent.
	--don't do anything at home.
	--don't do anything in greed mode.
	if level.IsAscent(level) == true then return end
	if level.GetStage(level) == 13 then return end
	if Game().IsGreedMode(Game()) == true then return end
	
	--Iterate through each room and update the matrix.
	
	for i = 0, rooms.Size-1 do
		local room = rooms:Get(i)
		local index = room.GridIndex
		local shape = room.Data.Shape
		-- basic 1x1  			               horizontal closet 1x1    vertical closet 1x1
		if shape == RoomShape.ROOMSHAPE_1x1 or shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
			--index = only index in room.
			
			local type = room.Data.Type
			
			if type == RoomType.ROOM_SECRET then
				matrix[math.floor(index/13) + 1][index%13 + 1] = Enums.SECRET
			elseif type == RoomType.ROOM_SUPERSECRET then
				matrix[math.floor(index/13) + 1][index%13 + 1] = Enums.SUPERSECRET
			elseif type == RoomType.ROOM_ULTRASECRET then
				matrix[math.floor(index/13) + 1][index%13 + 1] = Enums.ULTRASECRET
			else
				matrix[math.floor(index/13) + 1][index%13 + 1] = index
			end
			
		 --	   vertical 1x2						   vertical closet 1x2
		elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
			--index = top index of room.
			matrix[math.floor(index/13) + 1][index%13 + 1] = index
			matrix[(math.floor(index/13) + 1) + 1][index%13 + 1] = index
		
		--	   horizontal 2x1                      horizontal closet 2x1
		elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
			--index = left index of room.
			matrix[math.floor(index/13) + 1][index%13 + 1] = index
			matrix[math.floor(index/13) + 1][(index%13 + 1) + 1] = index
		
		--	   2x2
		elseif shape == RoomShape.ROOMSHAPE_2x2 or shape == RoomShape.ROOMSHAPE_LTL or shape == RoomShape.ROOMSHAPE_LTR or shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LBR then 
			--index = topleft index of room.
			if shape ~= RoomShape.ROOMSHAPE_LTL then matrix[math.floor(index/13) + 1][index%13 + 1] = index end
			
			--top right
			if shape ~= RoomShape.ROOMSHAPE_LTR then matrix[math.floor(index/13) + 1][(index%13 + 1) + 1] = index end
		
			--bottom left
			if shape ~= RoomShape.ROOMSHAPE_LBL then matrix[(math.floor(index/13) + 1) + 1][index%13 + 1] = index end
			
			--bottom right
			if shape ~= RoomShape.ROOMSHAPE_LBR then matrix[(math.floor(index/13) + 1) + 1][(index%13 + 1) + 1] = index end
		end
	end
	
	
	--Count the number of secret / super secret locations.
	secretCount = 0
	superSecretCount = 0
	for i = 1, 13 do
		for j = 1, 13 do
			if matrix[i][j] == Enums.SECRET then
				secretCount = secretCount + 1
			elseif matrix[i][j] == Enums.SUPERSECRET then
				superSecretCount = superSecretCount + 1
			end
		end
	end
	
	--Don't do anything extra if the player has items that make the mod irrelevant.
	if vanillaRevealSecret and vanillaRevealSuperSecret then return end
	
	--Update matrix with possible secret locations
	for i = 1, 13 do
		for j = 1, 13 do
			--Unused room location slot.
			if matrix[i][j] == Enums.NO_ROOM then
				local uniqueNeighbors = 0
				local totalNeighbors = 0
				local neighborList = {}
				local hasSpecialNeighbor = false
				
				--Check Top neighbor
				if i > 1 and matrix[i-1][j] ~= Enums.NO_ROOM then 
					local roomData = level.GetRoomByIdx(level, 13*(i-2) + (j-1)).Data
					if roomData ~= nil then
						roomType = roomData.Type
						roomShape = roomData.Shape
						--illegal top neighbors.
						if roomType == RoomType.ROOM_BOSS or roomShape == RoomShape.ROOMSHAPE_IH or roomShape == RoomShape.ROOMSHAPE_IIH then
							goto continue 
						else
							--more illegal top neighbors. We don't want to indicate to the player that we've found one though.
							if roomType ~= RoomType.ROOM_SECRET and roomType ~= RoomType.ROOM_SUPERSECRET and roomType ~= RoomType.ROOM_ULTRASECRET then
								neighborList["Top"] = matrix[i-1][j]
								uniqueNeighbors = uniqueNeighbors + 1
								totalNeighbors = totalNeighbors+1
							
								--supersecret rooms can't spawn adjacent special rooms.
								if roomType ~= RoomType.ROOM_DEFAULT then
									hasSpecialNeighbor = true
								end
							end
						end
					end
				end
				--Check Left Neighbor
				if j > 1 and matrix[i][j-1] ~= Enums.NO_ROOM then 
					local roomData = level.GetRoomByIdx(level, 13*(i-1) + (j-2)).Data
					if roomData ~= nil then
						roomType = roomData.Type
						roomShape = roomData.Shape
						--illegal left neighbors.
						if roomType == RoomType.ROOM_BOSS or roomShape == RoomShape.ROOMSHAPE_IV or roomShape == RoomShape.ROOMSHAPE_IIV then
							goto continue
						else
							--more illegal left neighbors. We don't want to indicate to the player that we've found one though.
							if roomType ~= RoomType.ROOM_SECRET and roomType ~= RoomType.ROOM_SUPERSECRET and roomType ~= RoomType.ROOM_ULTRASECRET then
								neighborList["Left"] = matrix[i][j-1]
								totalNeighbors = totalNeighbors+1
								
								--ensure uniqueness
								if neighborList["Left"] ~= neighborList["Top"] then	
									uniqueNeighbors = uniqueNeighbors + 1
								end
								
								
								--supersecret rooms can't spawn adjacent special rooms.
								if roomType ~= RoomType.ROOM_DEFAULT then
									hasSpecialNeighbor = true
								end
							end
						end
					end
				end
				--Check bottom neighbor
				if i < 13 and matrix[i+1][j] ~= Enums.NO_ROOM then 
					local roomData = level.GetRoomByIdx(level, 13*(i) + (j-1)).Data
					if roomData ~= nil then
						roomType = roomData.Type
						roomShape = roomData.Shape
						--illegal bottom neighbors.
						if roomType == RoomType.ROOM_BOSS or roomShape == RoomShape.ROOMSHAPE_IH or roomShape == RoomShape.ROOMSHAPE_IIH then
							goto continue
						else
							--more illegal bottom neighbors. We don't want to indicate to the player that we've found one though.
							if roomType ~= RoomType.ROOM_SECRET and roomType ~= RoomType.ROOM_SUPERSECRET and roomType ~= RoomType.ROOM_ULTRASECRET then
								neighborList["Bottom"] = matrix[i+1][j]
								totalNeighbors = totalNeighbors+1
								
								--ensure uniqueness
								if neighborList["Bottom"] ~= neighborList["Top"] and neighborList["Bottom"] ~= neighborList["Left"]  then	
									uniqueNeighbors = uniqueNeighbors + 1
								end
								
								--supersecret rooms can't spawn adjacent special rooms.
								if roomType ~= RoomType.ROOM_DEFAULT then
									hasSpecialNeighbor = true
								end
							end
						end
					end
				end
				--check right neighbor
				if j < 13 and matrix[i][j+1] ~= Enums.NO_ROOM then
					local roomData = level.GetRoomByIdx(level, 13*(i-1) + (j)).Data
					if roomData ~= nil then
						roomType = roomData.Type
						roomShape = roomData.Shape
						--illegal right neighbors
						if roomType == RoomType.ROOM_BOSS or roomShape == RoomShape.ROOMSHAPE_IV or roomShape == RoomShape.ROOMSHAPE_IIV then
							goto continue
						else
							--more illegal left neighbors. We don't want to indicate to the player that we've found one though.
							if roomType ~= RoomType.ROOM_SECRET and roomType ~= RoomType.ROOM_SUPERSECRET and roomType ~= RoomType.ROOM_ULTRASECRET then
								neighborList["Right"] = matrix[i][j+1]
								totalNeighbors = totalNeighbors+1
								
								--ensure uniqueness
								if neighborList["Right"] ~= neighborList["Top"] and neighborList["Right"] ~= neighborList["Left"] and neighborList["Right"] ~= neighborList["Bottom"]  then	
									uniqueNeighbors = uniqueNeighbors + 1
								end
								
								--supersecret rooms can't spawn adjacent special rooms.
								if roomType ~= RoomType.ROOM_DEFAULT then
									hasSpecialNeighbor = true
								end
							end
						end
					end
				end
				
				if uniqueNeighbors == 1 and totalNeighbors == 1 and hasSpecialNeighbor == false then
					matrix[i][j] = Enums.SUPERSECRET_FALSE
				elseif uniqueNeighbors > 1 then
					matrix[i][j] = Enums.SECRET_FALSE
				end
			
				::continue::
			end
		end
	end
	
	--debugging
	--printMatrix(true, true, true, true, true, true)
	
end

--Remove potential secret room locations by checking grid locations.
--Add remaining locations
local function updateMap()
	
	--Don't do anything if the player has items that make the mod irrelevant.
	if vanillaRevealSecret and vanillaRevealSuperSecret then return end
	
	
	--Don't do anything in crawlspaces.
	--Don't do anything in boss rooms (e.g. Mega Satan)
	--Don't do anything in I AM ERROR rooms.
	local type = Game().GetRoom(Game()).GetType(Game().GetRoom(Game()))
	if type == RoomType.ROOM_DUNGEON or type == RoomType.ROOM_ERROR or type == RoomType.ROOM_BOSS then
		return
	end
	
	--new room callback happens before new level callback, but we don't 
	--want to do anything if the level hasn't been loaded yet.
	if matrix[1] == nil then
		resetMatrix() 
		return
	end
	
	
	local level = Game():GetLevel()
	local room = level:GetCurrentRoom()
	local index = level:GetCurrentRoomDesc().GridIndex
	local row, column = (math.floor(index/13) + 1), (index%13 + 1) --13x13 matrix for rooms
	local height, width = room.GetGridHeight(room), room.GetGridWidth(room)
	local shape = room.GetRoomShape(room)
	
	--1x1 room: 0-134 indexes. Height = 9, Width = 15
	--1x2 (vertical) room: 0-239 indexes. Height = 16, Width = 15
	--2x1 (horizontal) room: 0-251 indexes. Height = 9, Width = 28
	--2x2 room: 0-447 indexes, Height = 16, Width = 28
	
	--Initialize blank grid of this room.
	local grid = {}
	for i = 0, (height - 1) do
		grid[i] = { }
		for j = 0, (width - 1) do
			grid[i][j] = Enums.EMPTY
		end
	end
	
	--Add Obstacles and doors.
	for i = 0, (room.GetGridSize(room)-1) do
		local entity = room.GetGridEntity(room, i)
		if entity ~= nil then
			local row, column = math.floor(i/width), i%width --Sourced from the GridIndexes for this room. Different from the indexes assigned to each room.
			if entity.GetType(entity) == GridEntityType.GRID_DOOR then
				grid[row][column] = Enums.DOOR
			elseif entity.GetType(entity) ~= GridEntityType.GRID_NULL and
			   entity.GetType(entity) ~= GridEntityType.GRID_DECORATION and
			   entity.GetType(entity) ~= GridEntityType.GRID_SPIDERWEB then

				grid[row][column] = Enums.OBSTACLE
			end
		end
	end
	
	--Add fires and moveable TNT because they are special.
	--Also include check for grimaces here.
	for i, entity in ipairs(Isaac.GetRoomEntities()) do
		if entity.Type == EntityType.ENTITY_FIREPLACE or
		   entity.Type == EntityType.ENTITY_MOVABLE_TNT or
		   entity.Type == EntityType.ENTITY_STONEHEAD or
		   entity.Type == EntityType.ENTITY_GAPING_MAW or 
		   entity.Type == EntityType.ENTITY_BROKEN_GAPING_MAW or 
		   entity.Type == EntityType.ENTITY_CONSTANT_STONE_SHOOTER or 
		   entity.Type == EntityType.ENTITY_QUAKE_GRIMACE or
		   entity.Type == EntityType.ENTITY_BOMB_GRIMACE or
		   entity.Type == EntityType.ENTITY_BRIMSTONE_HEAD or 
		   entity.Type == EntityType.ENTITY_STONE_EYE then
			local row, column = math.floor(entity.SpawnGridIndex/width), (entity.SpawnGridIndex)%width
			grid[row][column] = Enums.OBSTACLE
		end
	end
	
	--Create tables to manage search.
	local coordList = {}
	
	--Add starting point. (Find a point near a door)
	for i = 0, height-1 do
		for j = 0, width - 1 do
			if grid[i][j] == Enums.DOOR then
				if i == 0 then
					grid[i+1][j] = Enums.PATH
					table.insert(coordList,Vector(i+1, j))
				elseif i == (height-1) then
					grid[i-1][j] = Enums.PATH
					table.insert(coordList,Vector(i-1, j))
				elseif j == 0 then
					grid[i][j+1] = Enums.PATH
					table.insert(coordList,Vector(i, j+1))
				elseif j == (width-1) then
					grid[i][j-1] = Enums.PATH
					table.insert(coordList,Vector(i, j-1))
				end
				goto exitLoop
			end
		end
	end
	
	::exitLoop::
	
	--BFS, find visitable spots
	while coordList[1] ~= nil do
		local v = table.remove(coordList, 1)
		local i, j = v.X, v.Y
		
		--Add neighbors to end of coordList if possible.
		if grid[i-1] ~= nil and grid[i-1][j] == Enums.EMPTY then
			--Above
			grid[i-1][j] = Enums.PATH
			table.insert(coordList, Vector(i-1, j))
		end
		if grid[i+1] ~= nil and grid[i+1][j] == Enums.EMPTY then
			--Below
			grid[i+1][j] = Enums.PATH
			table.insert(coordList, Vector(i+1, j))
		end
		if grid[i] ~= nil and grid[i][j-1] == Enums.EMPTY then
			--Left
			grid[i][j-1] = Enums.PATH
			table.insert(coordList, Vector(i, j-1))
		end
		if grid[i] ~= nil and grid[i][j+1] == Enums.EMPTY then
			--Right
			grid[i][j+1] = Enums.PATH
			table.insert(coordList, Vector(i, j+1))
		end
	end
	
	--debugging
	--printGrid(height, width, grid)	
	
	--Check if a path is reachable, update matrix if necessary.
	--gridindex of X = grid[floor(X/width][X%width]
	if shape == RoomShape.ROOMSHAPE_1x1 or shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
		--[[
		--   1
		-- 3 X 4
		--   2
		-- 1 = grid index 22
		-- 2 = grid index 112
		-- 3 = grid index 61
		-- 4 = grind index 73]]
		
		if grid[1][7] ~= Enums.PATH then
			--top (1) is blocked
			--print("Top is blocked")
			if row > 1 then 
				matrix[row-1][column] = Enums.NO_ROOM 
				removeRoom(index, -13)
			end
		end
		if grid[7][7] ~= Enums.PATH then
			--bottom (2) is blocked
			--print("Bottom is blocked")
			if row < 13 then 
				matrix[row+1][column] = Enums.NO_ROOM
				removeRoom(index, 13)
			end
		end
		if grid[4][1] ~= Enums.PATH then
			--left (3) is blocked
			--print("Left is blocked")
			if column > 1 then
				matrix[row][column - 1] = Enums.NO_ROOM 
				removeRoom(index, -1)
			end
		end
		if grid[4][13] ~= Enums.PATH then
			--right (4) is blocked
			--print("Right is blocked")
			if column < 13 then 
				matrix[row][column + 1] = Enums.NO_ROOM 
				removeRoom(index, 1)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
		--[[horizontal 2x1
		--   3 4
		-- 1 X X 2
		--   5 6
		-- 1 = grid index 113
		-- 2 = grid index 138
		-- 3 = grid index 35
		-- 4 = grid index 48
		-- 5 = grid index 203
		-- 6 = grid index 216]]
		
		if grid[4][1] ~= Enums.PATH  then
			--1 is blocked
			--print("1 is blocked")
			if column > 1 then
				matrix[row][column - 1] = Enums.NO_ROOM 
				removeRoom(index, -1)
			end
		end
		if grid[4][26] ~= Enums.PATH then
			--2 is blocked
			--print("2 is blocked")
			if column < 12 then 
				matrix[row][column + 2] = Enums.NO_ROOM 
				removeRoom(index, 2)
			end
		end
		if grid[1][7] ~= Enums.PATH then
			--3 is blocked
			--print("3 is blocked")
			if row > 1 then 
				matrix[row-1][column] = Enums.NO_ROOM 
				removeRoom(index, -13)
			end
		end
		if grid[1][20] ~= Enums.PATH then 
			--4 is blocked
			--print("4 is blocked")
			if row > 1 and column < 13 then
				matrix[row-1][column + 1] = Enums.NO_ROOM
				removeRoom(index, -12)
			end
		end
		if grid[7][7] ~= Enums.PATH then 
			--5 is blocked
			--print("5 is blocked")
			if row < 13 then
				matrix[row+1][column] = Enums.NO_ROOM 
				removeRoom(index, 13)
			end
		end
		if grid[7][20] ~= Enums.PATH then 
			--6 is blocked
			--print("6 is blocked")
			if row < 13 and column < 13 then
				matrix[row+1][column + 1] = Enums.NO_ROOM
				removeRoom(index, 14)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
		--[[vertical 1x2
		--    1
		-- 	3 X 5
		--  4 X 6
		--    2
		-- 1 = grid index 22
		-- 2 = grid index 217
		-- 3 = grid index 61
		-- 4 = grid index 166
		-- 5 = grid index 73
		-- 6 = grid index 178]]
		
		if grid[1][7] ~= Enums.PATH  then 
			--1 is blocked
			--print("1 is blocked")
			if row > 1 then
				matrix[row - 1][column] = Enums.NO_ROOM
				removeRoom(index, -13)
			end
		end
		if grid[14][7] ~= Enums.PATH then
			--2 is blocked
			--print("2 is blocked")
			if row < 12 then
				matrix[row + 2][column] = Enums.NO_ROOM
				removeRoom(index, 26)
			end
		end
		if grid[4][1] ~= Enums.PATH then 
			--3 is blocked
			--print("3 is blocked")
			if column > 1 then 
				matrix[row][column-1] = Enums.NO_ROOM 
				removeRoom(index, -1)
			end
		end
		if grid[11][1] ~= Enums.PATH then 
			--4 is blocked
			--print("4 is blocked")
			if column > 1 and row < 13 then
				matrix[row+1][column-1] = Enums.NO_ROOM 
				removeRoom(index, 12)
			end
		end
		if grid[4][13] ~= Enums.PATH then 
			--5 is blocked
			--print("5 is blocked")
			if column < 13 then 
				matrix[row][column+1] = Enums.NO_ROOM 
				removeRoom(index, 1)
			end
		end
		if grid[11][13] ~= Enums.PATH then 
			--6 is blocked
			--print("6 is blocked")
			if column < 13 and row < 13 then
				matrix[row+1][column+1] = Enums.NO_ROOM 
				removeRoom(index, 14)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_2x2 then
		--[[
		--   3 4
		-- 2 X X 5
		-- 1 X X 6
		--   7 8
		-- 1 = grid index 309
		-- 2 = grid index 113
		-- 3 = grid index 35
		-- 4 = grid index 48
		-- 5 = grid index 138
		-- 6 = grid index 334
		-- 7 = grid index 399
		-- 8 = grid index 412
		]]
		
		if grid[11][1] ~= Enums.PATH  then
			--1 is blocked
			--print("1 is blocked")
			if row < 13 and column > 1 then 
				matrix[row+1][column-1] = Enums.NO_ROOM 
				removeRoom(index, 12)
			end
		end
		if grid[4][1] ~= Enums.PATH then
			--2 is blocked
			--print("2 is blocked")
			if column > 1 then 
				matrix[row][column-1] = Enums.NO_ROOM 
				removeRoom(index, -1)
			end
		end
		if grid[1][7] ~= Enums.PATH then
			--3 is blocked
			--print("3 is blocked")
			if row > 1 then 
				matrix[row - 1][column] = Enums.NO_ROOM 
				removeRoom(index, -13)
			end
		end
		if grid[1][20] ~= Enums.PATH then
			--4 is blocked
			--print("4 is blocked")
			if row > 1 and column < 13 then 
				matrix[row - 1][column+1] = Enums.NO_ROOM 
				removeRoom(index, -12)
			end
		end
		if grid[4][26] ~= Enums.PATH then 
			--5 is blocked
			--print("5 is blocked")
			if column < 12 then 
				matrix[row][column+2] = Enums.NO_ROOM 
				removeRoom(index, 2)
			end
		end
		if grid[11][26] ~= Enums.PATH then
			--6 is blocked
			--print("6 is blocked")
			if row < 13 and column < 12 then 
				matrix[row+1][column+2] = Enums.NO_ROOM 
				removeRoom(index, 15)
			end
		end
		if grid[14][7] ~= Enums.PATH then 
			--7 is blocked
			--print("7 is blocked")
			if row < 12 then 
				matrix[row+2][column] = Enums.NO_ROOM
				removeRoom(index, 26)
			end
		end
		if grid[14][20] ~= Enums.PATH then
			--8 is blocked
			--print("8 is blocked")
			if row < 12 and column < 13 then 
				matrix[row+2][column+1] = Enums.NO_ROOM 
				removeRoom(index, 27)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_LTR then
		--[[top-right square missing
		--    3
		--	2 X 4
		--	1 X X 5
		--	  6 7
		-- 1 = grid index 309
		-- 2 = grid index 113
		-- 3 = grid index 35
		-- 4 = grid index 125 244
		-- 5 = grid index 334
		-- 6 = grid index 399
		-- 7 = grid index 412]]
		
		if grid[11][1] ~= Enums.PATH  then
			--1 is blocked
			--print("1 is blocked")
			if row < 13 and column > 1 then 
				matrix[row+1][column-1] = Enums.NO_ROOM 
				removeRoom(index, 12)
			end
		end
		if grid[4][1] ~= Enums.PATH then 
			--2 is blocked
			--print("2 is blocked")
			if column > 1 then 
				matrix[row][column-1] = Enums.NO_ROOM
				removeRoom(index, -1)
			end
		end
		if grid[1][7] ~= Enums.PATH then 
			--3 is blocked
			--print("3 is blocked")
			if row > 1 then 
				matrix[row-1][column] = Enums.NO_ROOM 
				removeRoom(index, -13)
			end
		end
		if grid[4][13] ~= Enums.PATH or grid[8][20] ~= Enums.PATH then
			--4 is blocked
			--print("4 is blocked")
			if column < 13 then 
				matrix[row][column+1] = Enums.NO_ROOM
				removeRoom(index, 1)
			end
		end
		if grid[11][26] ~= Enums.PATH then  
			--5 is blocked
			--print("5 is blocked")
			if column < 12 and row < 13 then 
				matrix[row+1][column+2] = Enums.NO_ROOM 
				removeRoom(index, 15)
			end
		end
		if grid[14][7] ~= Enums.PATH then 
			--6 is blocked
			--print("6 is blocked")
			if row < 12 then 
				matrix[row+2][column] = Enums.NO_ROOM
				removeRoom(index, 26)
			end
		end
		if grid[14][20] ~= Enums.PATH then  
			--7 is blocked
			--print("7 is blocked")
			if row < 12 and column < 13 then 
				matrix[row+2][column+1] = Enums.NO_ROOM
				removeRoom(index, 27)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_LTL then
		--[[top-left square missing
		--		3
		--	  2 X 4
		--	1 X X 5
		--	  6 7
		-- 1 = grid index 309
		-- 2 = grid index 126 231
		-- 3 = grid index 48
		-- 4 = grid index 138
		-- 5 = grid index 334
		-- 6 = grid index 399
		-- 7 = grid index 412]]
		
		if grid[11][1] ~= Enums.PATH  then
			--1 is blocked
			--print("1 is blocked")
			if row < 13 and column > 1 then 
				matrix[row+1][column-1] = Enums.NO_ROOM 
				removeRoom(index, 12)
			end
		end
		if grid[4][14] ~= Enums.PATH or grid[8][7] ~= Enums.PATH then
			--2 is blocked
			--print("2 is blocked")
			matrix[row][column] = Enums.NO_ROOM
			removeRoom(index, 0)
		end
		if grid[1][20] ~= Enums.PATH then 
			--3 is blocked
			--print("3 is blocked")
			if row > 1 and column < 13 then 
				matrix[row-1][column+1] = Enums.NO_ROOM 
				removeRoom(index, -12)
			end
		end
		if grid[4][26] ~= Enums.PATH then
			--4 is blocked
			--print("4 is blocked")
			if column < 12 then 
				matrix[row][column+2] = Enums.NO_ROOM
				removeRoom(index, 2)
			end
		end
		if grid[11][26] ~= Enums.PATH then 
			--5 is blocked
			--print("5 is blocked")
			if row < 13 and column < 12 then 
				matrix[row+1][column+2] = Enums.NO_ROOM 
				removeRoom(index, 15)
			end
		end
		if grid[14][7] ~= Enums.PATH then
			--6 is blocked
			--print("6 is blocked")
			if row < 12 then 
				matrix[row+2][column] = Enums.NO_ROOM 
				removeRoom(index, 26)
			end
		end
		if grid[14][20] ~= Enums.PATH then 
			--7 is blocked
			--print("7 is blocked")
			if row < 12 and column < 13 then 
				matrix[row+2][column+1] = Enums.NO_ROOM 
				removeRoom(index, 27)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_LBR then
		--[[bottom-right square missing
		--    3 4
		--	2 X X 5
		--	1 X 6
		--    7
		-- 1 = grid index 309
		-- 2 = grid index 113
		-- 3 = grid index 35
		-- 4 = grid index 48
		-- 5 = grid index 138
		-- 6 = grid index 321 216
		-- 7 = grid index 399]]
		
		if grid[11][1] ~= Enums.PATH  then
			--1 is blocked
			--print("1 is blocked")
			if row < 13 and column > 1 then
				matrix[row+1][column-1] = Enums.NO_ROOM 
				removeRoom(index, 12)
			end
		end
		if grid[4][1] ~= Enums.PATH then
			--2 is blocked
			--print("2 is blocked")
			if column > 1 then 
				matrix[row][column] = Enums.NO_ROOM
				removeRoom(index, -1)
			end
		end
		if grid[1][7] ~= Enums.PATH then 
			--3 is blocked
			--print("3 is blocked")
			if row > 1 then
				matrix[row - 1][column] = Enums.NO_ROOM 
				removeRoom(index, -13)
			end
		end
		if grid[1][20] ~= Enums.PATH then
			--4 is blocked
			--print("4 is blocked")
			if row > 1 and column < 13 then 
				matrix[row-1][column+1] = Enums.NO_ROOM
				removeRoom(index, -12)
			end
		end
		if grid[4][26] ~= Enums.PATH then
			--5 is blocked
			--print("5 is blocked")
			if column < 12 then 
				matrix[row][column+2] = Enums.NO_ROOM
				removeRoom(index, 2)
			end
		end
		if grid[11][13] ~= Enums.PATH or grid[7][20] ~= Enums.PATH then 
			--6 is blocked
			--print("6 is blocked")
			if row < 13 and column < 13 then 
				matrix[row+1][column+1] = Enums.NO_ROOM 
				removeRoom(index, 14)
			end
		end
		if grid[14][7] ~= Enums.PATH then
			--7 is blocked
			--print("7 is blocked")
			if row < 12 then 
				matrix[row+2][column] = Enums.NO_ROOM
				removeRoom(index, 26)
			end
		end
	elseif shape == RoomShape.ROOMSHAPE_LBL then
		--[[bottom-left square missing
		--    3 4
		--	2 X X 5
		--	  1 X 6
		--    	7
		-- 1 = grid index 203 322
		-- 2 = grid index 113
		-- 3 = grid index 35
		-- 4 = grid index 48
		-- 5 = grid index 138
		-- 6 = grid index 334
		-- 7 = grid index 412]]
		
		if grid[7][7] ~= Enums.PATH or grid[11][14] ~= Enums.PATH then
			--1 is blocked
			--print("1 is blocked")
			if row < 13 then 
				matrix[row+1][column] = Enums.NO_ROOM 
				removeRoom(index, 13)
			end
		end
		if grid[4][1] ~= Enums.PATH then 
			--2 is blocked
			--print("2 is blocked")
			if column > 1 then 
				matrix[row][column-1] = Enums.NO_ROOM 
				removeRoom(index, -1)
			end
		end
		if grid[1][7] ~= Enums.PATH then
			--3 is blocked
			--print("3 is blocked")
			if row > 1 then 
				matrix[row-1][column]= Enums.NO_ROOM
				removeRoom(index, -13)
			end
		end
		if grid[1][20] ~= Enums.PATH then
			--4 is blocked
			--print("4 is blocked")
			if row > 1 and column < 13 then 
				matrix[row-1][column + 1] = Enums.NO_ROOM 
				removeRoom(index, -12)
			end
		end
		if grid[4][26] ~= Enums.PATH then
			--5 is blocked
			--print("5 is blocked")
			if column < 12 then 
				matrix[row][column+2] = Enums.NO_ROOM
				removeRoom(index, 2)
			end
		end
		if grid[11][26] ~= Enums.PATH then
			--6 is blocked
			--print("6 is blocked")
			if row < 13 and column < 12 then 
				matrix[row+1][column+2] = Enums.NO_ROOM
				removeRoom(index, 15)
			end
		end
		if grid[14][20] ~= Enums.PATH then
			--7 is blocked
			--print("7 is blocked")
			if row < 12 and column < 13 then 
				matrix[row+2][column+1] = Enums.NO_ROOM
				removeRoom(index, 27)
			end
		end
	end	
	
	--Update map with secret locations.
	if shape == RoomShape.ROOMSHAPE_1x1 or shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
		--   1
		-- 3 X 4
		--   2
		
		--1
		searchForMapAdditions(row, column, index, -1, 0)
		
		--2
		searchForMapAdditions(row, column, index, 1, 0)
		
		--3
		searchForMapAdditions(row, column, index, 0, -1)
		
		--4
		searchForMapAdditions(row, column, index, 0, 1)
		
	elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
		--vertical 1x2
		--    1
		-- 	3 X 5
		--  4 X 6
		--    2
		
		--1
		searchForMapAdditions(row, column, index, -1, 0)
		
		--2
		searchForMapAdditions(row, column, index, 2, 0)
		
		--3
		searchForMapAdditions(row, column, index, 0, -1)
		
		--4
		searchForMapAdditions(row, column, index, 1, -1)
		
		--5
		searchForMapAdditions(row, column, index, 0, 1)
		
		--6
		searchForMapAdditions(row, column, index, 1, 1)
		
	elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
		--horizontal 2x1
		--   3 4
		-- 1 X X 2
		--   5 6
		
		--1
		searchForMapAdditions(row, column, index, 0, -1)
		
		--2
		searchForMapAdditions(row, column, index, 0, 2)
		
		--3
		searchForMapAdditions(row, column, index, -1, 0)
		
		--4
		searchForMapAdditions(row, column, index, -1, 1)
		
		--5
		searchForMapAdditions(row, column, index, 1, 0)
		
		--6		
		searchForMapAdditions(row, column, index, 1, 1)
		
	elseif shape == RoomShape.ROOMSHAPE_2x2 then
		--   3 4
		-- 2 X X 5
		-- 1 X X 6
		--   7 8
		
		--1
		searchForMapAdditions(row, column, index, 1, -1)
		
		--2
		searchForMapAdditions(row, column, index, 0, -1)
		
		--3
		searchForMapAdditions(row, column, index, -1, 0)
		
		--4
		searchForMapAdditions(row, column, index, -1, 1)
		
		--5
		searchForMapAdditions(row, column, index, 0, 2)
		
		--6
		searchForMapAdditions(row, column, index, 1, 2)
		
		--7
		searchForMapAdditions(row, column, index, 2, 0)
		
		--8
		searchForMapAdditions(row, column, index, 2, 1)
	
	elseif shape == RoomShape.ROOMSHAPE_LTL then
		--top-left square missing
		--		3
		--	  2 X 4
		--	1 X X 5
		--	  6 7
		
		--1
		searchForMapAdditions(row, column, index, 1, -1)
		
		--2
		searchForMapAdditions(row, column, index, 0, 0)
		
		--3
		searchForMapAdditions(row, column, index, -1, 1)
		
		--4
		searchForMapAdditions(row, column, index, 0, 2)
		
		--5
		searchForMapAdditions(row, column, index, 1, 2)
		
		--6
		searchForMapAdditions(row, column, index, 2, 0)
		
		--7
		searchForMapAdditions(row, column, index, 2, 1)
		
	elseif shape == RoomShape.ROOMSHAPE_LTR then
		--top-right square missing
		--    3
		--	2 X 4
		--	1 X X 5
		--	  6 7
		
		--1
		searchForMapAdditions(row, column, index, 1, -1)
		
		--2
		searchForMapAdditions(row, column, index, 0, -1)
		
		--3
		searchForMapAdditions(row, column, index, -1, 0)
		
		--4
		searchForMapAdditions(row, column, index, 0, 1)
		
		--5
		searchForMapAdditions(row, column, index, 1, 2)
		
		--6
		searchForMapAdditions(row, column, index, 2, 0)
		
		--7
		searchForMapAdditions(row, column, index, 2, 1)
		
	elseif shape == RoomShape.ROOMSHAPE_LBL then
		--bottom-left square missing
		--    3 4
		--	2 X X 5
		--	  1 X 6
		--    	7
		
		--1
		searchForMapAdditions(row, column, index, 1, 0)
		
		--2
		searchForMapAdditions(row, column, index, 0, -1)
		
		--3
		searchForMapAdditions(row, column, index, -1, 0)
		
		--4
		searchForMapAdditions(row, column, index, -1, 1)
		
		--5
		searchForMapAdditions(row, column, index, 0, 2)
		
		--6
		searchForMapAdditions(row, column, index, 1, 2)
		
		--7
		searchForMapAdditions(row, column, index, 2, 1)
		
	elseif shape == RoomShape.ROOMSHAPE_LBR then
		--bottom-right square missing
		--    3 4
		--	2 X X 5
		--	1 X 6
		--    7
		
		--1
		searchForMapAdditions(row, column, index, 1, -1)
		
		--2
		searchForMapAdditions(row, column, index, 0, -1)
		
		--3
		searchForMapAdditions(row, column, index, -1, 0)
		
		--4
		searchForMapAdditions(row, column, index, -1, 1)
		
		--5
		searchForMapAdditions(row, column, index, 0, 2)

		--6
		searchForMapAdditions(row, column, index, 1, 1)
		
		--7
		searchForMapAdditions(row, column, index, 2, 0)
		
	end

	
	--debugging
	--printMatrix(true, true, true, true, true, true)
end

--Remove some potential locations from map when you enter a real location.
local function onEnterSecret()
	--Remove false possibilities on map and on matrix
	local room_type = Game().GetRoom(Game()).GetType(Game().GetRoom(Game()))
	local level = Game().GetLevel(Game())
	local index = level.GetCurrentRoomDesc(level).GridIndex
	
	if room_type == RoomType.ROOM_SECRET then
		
		removeRoom(index)
		
		if notContainsVal(secretFound, index) then
			secretFound[#secretFound + 1] = index
		end
	
		--clear neighboring fake secret/super secret locations
		clearNeighboringSecrets(index)
		
		--if all secrets have been found...
		if #secretFound == secretCount then
			clearFakeSecrets(false)
		end
	elseif room_type == RoomType.ROOM_SUPERSECRET then
		
		removeRoom(index)
		
		if notContainsVal(secretFound, index) then
			superSecretFound[#superSecretFound + 1] = index
		end
	
		--clear neighboring fake secret/super secret locations
		clearNeighboringSecrets(index)
		
		--clear fake super secret locations.
		if #superSecretFound == superSecretCount then
			clearFakeSecrets(true)
		end
	end
end

--Updates map on certain item uses.
local function onActive(mod, itemType, rng, player, flags, slot, data)
	
	
	if itemType == CollectibleType.COLLECTIBLE_CRYSTAL_BALL then
		--Same effect as world/sun/world
		
		clearFakeSecrets(false)
		
	elseif itemType == CollectibleType.COLLECTIBLE_DADS_KEY then
		--clear neighboring fake secret/super secret locations
		clearNeighboringSecrets(Game().GetLevel(Game()).GetCurrentRoomDesc(Game().GetLevel(Game())).GridIndex)
	end
	
	return nil
end

--Updates map when cards like sun/world are used.
local function onCard(mod, card, player, flags)
	if card == Card.CARD_SUN or card == Card.CARD_WORLD or card == Card.RUNE_ANSUZ then
		--Remove extra secret room possibilities.
		
		clearFakeSecrets(false)
			
		if card == Card.RUNE_ANSUZ then
			--Remove extra super secret room possibilities
			clearFakeSecrets(true)
		end
	elseif card == Card.CARD_GET_OUT_OF_JAIL then
		--clear neighboring fake secret/super secret locations
		clearNeighboringSecrets(Game().GetLevel(Game()).GetCurrentRoomDesc(Game().GetLevel(Game())).GridIndex)
	end
end

--Check if isaac has vanilla objects that reveal secret locations.
local function checkCollectibles()
	local player = Isaac.GetPlayer()
	local level = Game().GetLevel(Game())
	local index = level.GetCurrentRoomDesc(level).GridIndex
	local shape = level.GetCurrentRoom(level).GetRoomShape(level.GetCurrentRoom(level))
	
	--player has blue map or spelunker's hat.
	if (vanillaRevealSuperSecret == false or vanillaRevealSecret == false) and (player.HasCollectible(player, CollectibleType.COLLECTIBLE_BLUE_MAP, true) or player.HasCollectible(player, CollectibleType.COLLECTIBLE_SPELUNKER_HAT, true) or player.HasCollectible(player, CollectibleType.COLLECTIBLE_MIND, true) or player.HasCollectible(player, CollectibleType.COLLECTIBLE_XRAY_VISION, true)) then 
			vanillaRevealSuperSecret = true
			vanillaRevealSecret = true
			clearFakeSecrets(false)
			clearFakeSecrets(true)
	end
	
	--The player has picked up luna for the first time.
	if hasLuna == false and player.HasCollectible(player, CollectibleType.COLLECTIBLE_LUNA) then
		hasLuna = true
		clearFakeSecrets(false)
	end
	
	--dog tooth: clear fake adjacent possibilities if none of them are real.
	if player.HasCollectible(player, CollectibleType.COLLECTIBLE_DOG_TOOTH, true) and checkNeighborsForReal(index, shape) == false then
		clearNeighboringSecrets(index, shape)
	end
end

local function resetValues()
	vanillaRevealSecret = false
	vanillaRevealSuperSecret = false
	hasLuna = false
end

secretMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, updateMap)
secretMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, onEnterSecret)
secretMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, findPossibilities)
secretMod:AddCallback(ModCallbacks.MC_USE_CARD, onCard)
secretMod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, onActive)
secretMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, checkCollectibles)
secretMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, resetValues)