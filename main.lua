secretMod = RegisterMod("Potential Secret Locations!", 1)

local matrix = {}

local function resetMatrix()
	for i = 1, 13 do
		matrix[i] = {}
		for j = 1, 13 do
			matrix[i][j] = -1
		end
	end
end

--debugging function
local function printMatrix(printSecretGuesses, printSuperGuesses, printUltraGuesses, printSecret, printSuperSecret, printUltraSecret)
	print()
	for i = 1, 13 do
		str = i..". "
		if i < 10 then str = str.." " end
		for j = 1, 13 do
			if type(matrix[i][j]) == "string" then
				str = str.." "..matrix[i][j]
			elseif matrix[i][j] > 993 then 
				if printSecretGuesses and matrix[i][j] == 994 then 
					--potential secret rooms
					str = str.." _SC"
				elseif printSuperGuesses and matrix[i][j] == 995 then 
					--potential super secret rooms
					str = str.." _SS"
				elseif printUltraGuesses and matrix[i][j] == 996 then 
					--potential ultra secret rooms
					str = str.." _US"
				elseif printSecret and matrix[i][j] == 997 then 
					--secret rooms
					str = str.." SEC"
				elseif printSuperSecret and matrix[i][j] == 998 then
					--super secret rooms
					str = str.." SUP"
				elseif printUltraSecret and matrix[i][j] == 999 then
					--ultra secret rooms
					str = str.." ULT"
				else
					str = str.."    "
				end
			elseif matrix[i][j] == -1 then
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


--Fill matrix with the floor's possible secret/super secret room locations by just looking at the map.
local function findPossibilities()
	
	resetMatrix()
	
	--Iterate through each room and update the matrix.
	local level = Game():GetLevel()
	local rooms = level:GetRooms()
	for i = 0, rooms.Size-1 do
		local room = rooms:Get(i)
		local index = room.GridIndex
		local shape = room.Data.Shape
		-- basic 1x1  			               horizontal closet 1x1    vertical closet 1x1
		if shape == RoomShape.ROOMSHAPE_1x1 or shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
			--index = only index in room.
			
			local type = room.Data.Type
			
			if type == RoomType.ROOM_SECRET then
				matrix[math.floor(index/13) + 1][index%13 + 1] = 997
			elseif type == RoomType.ROOM_SUPERSECRET then
				matrix[math.floor(index/13) + 1][index%13 + 1] = 998
			elseif type == RoomType.ROOM_ULTRASECRET then
				matrix[math.floor(index/13) + 1][index%13 + 1] = 999
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
	
	--debugging, remove later.
	
	--Update matrix with possible secret locations
	--NOTE: This won't suggest super secret locations in locations that
	--border secret rooms, which gives hints about the location of secret rooms.
	--Solution/TODO: Don't give possible super secret locations until secret room has been found.
	for i = 1, 13 do
		for j = 1, 13 do
			--Unused room location slot.
			if matrix[i][j] == -1 then
				local uniqueNeighbors = 0
				local neighborList = {}
				
				
				if i > 1 and matrix[i-1][j] ~= -1 then 
					local roomData = level.GetRoomByIdx(level, 13*(i-2) + (j-1)).Data
					if roomData ~= nil then
						roomType = roomData.Type
						roomShape = roomData.Shape
						if roomType == RoomType.ROOM_BOSS or roomType == RoomType.ROOM_SECRET or roomType == RoomType.ROOM_SUPERSECRET or roomType == RoomType.ROOM_ULTRASECRET or roomShape == RoomShape.ROOMSHAPE_IH or roomShape == RoomShape.ROOMSHAPE_IIH then
							break
						end
						neighborList["Top"] = matrix[i-1][j]
						uniqueNeighbors = uniqueNeighbors + 1
					end
				end
				if j > 1 and matrix[i][j-1] ~= -1 then 
					local roomData = level.GetRoomByIdx(level, 13*(i-1) + (j-2)).Data
					if roomData ~= nil then
						roomType = roomData.Type
						roomShape = roomData.Shape
						if roomType == RoomType.ROOM_BOSS or roomType == RoomType.ROOM_SECRET or roomType == RoomType.ROOM_SUPERSECRET or roomType == RoomType.ROOM_ULTRASECRET or roomShape == RoomShape.ROOMSHAPE_IV or roomShape == RoomShape.ROOMSHAPE_IIV then
							break
						end
						neighborList["Left"] = matrix[i][j-1]
						if neighborList["Left"] ~= neighborList["Top"] then uniqueNeighbors = uniqueNeighbors + 1 end
					end
				end
				if i < 13 and matrix[i+1][j] ~= -1 then 
					local roomData = level.GetRoomByIdx(level, 13*(i) + (j-1)).Data
					if roomData ~= nil then
						roomType = roomData.Type
						roomShape = roomData.Shape
						if roomType == RoomType.ROOM_BOSS or roomType == RoomType.ROOM_SECRET or roomType == RoomType.ROOM_SUPERSECRET or roomType == RoomType.ROOM_ULTRASECRET or roomShape == RoomShape.ROOMSHAPE_IH or roomShape == RoomShape.ROOMSHAPE_IIH then
							break
						end
						neighborList["Bottom"] = matrix[i+1][j]
						if neighborList["Bottom"] ~= neighborList["Top"] and neighborList["Bottom"] ~= neighborList["Left"] then uniqueNeighbors = uniqueNeighbors + 1 end
					end
				end
				if i < 13 and matrix[i][j+1] ~= -1 then
					local roomData = level.GetRoomByIdx(level, 13*(i-1) + (j)).Data
					if roomData ~= nil then
						roomType = roomData.Type
						roomShape = roomData.Shape
						if roomType == RoomType.ROOM_BOSS or roomType == RoomType.ROOM_SECRET or roomType == RoomType.ROOM_SUPERSECRET or roomType == RoomType.ROOM_ULTRASECRET or roomShape == RoomShape.ROOMSHAPE_IV or roomShape == RoomShape.ROOMSHAPE_IIV  then
							break
						end
						neighborList["Right"] = matrix[i][j+1]
						if neighborList["Right"] ~= neighborList["Top"] and neighborList["Right"] ~= neighborList["Left"] and neighborList["Right"] ~= neighborList["Bottom"] then uniqueNeighbors = uniqueNeighbors + 1 end 
					end
				end
				
				if uniqueNeighbors == 1 then
					--supersecret
					matrix[i][j] = 995 
				elseif uniqueNeighbors > 1 then
					--secret
					matrix[i][j] = 994
				end
				
			end
		end
	end
	
	--debugging, remove later.
	Isaac.GetPlayer().UseCard(Isaac.GetPlayer(), 22)
	printMatrix(true, true, false, true, true, false)
end

--Remove potential secret room locations by checking grid locations.
local function updateMap()
	
	-- HxW:
	-- 9x15 for 1x1 (7x13 not counting walls)
	-- 16x28 for 2x2
	-- 9x28 for 1x2
	-- 16x15 for 2x1
	local room = Game():GetLevel():GetCurrentRoom()
	local height = room.GetGridHeight(room)
	local disableBot, disableLeft, disableRight, disableTop = false, false, false, false
	local shape = room.GetRoomShape(room)
	
	for i = 0, room.GetGridSize(room) do
		local entity = room.GetGridEntity(room, i)
		if entity ~= nil then
			if entity.GetType(entity) ~= GridEntityType.GRID_NULL and
			   entity.GetType(entity) ~= GridEntityType.GRID_DECORATION and
			   entity.GetType(entity) ~= GridEntityType.GRID_WALL and 
			   entity.GetType(entity) ~= GridEntityType.GRID_SPIDERWEB and
			   entity.GetType(entity) ~= GridEntityType.GRID_DOOR then
					
					--print(entity.GetType(entity)..","..entity.GetGridIndex(entity))
					
					if shape == RoomShape.ROOMSHAPE_1x1 or shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
						if entity.GetGridIndex(entity) == 22 then
							disableTop = true
						end
						
						if entity.GetGridIndex(entity) == 112 then
							disableBot = true
						end
						
						if entity.GetGridIndex(entity) == 61 then
							disableLeft = true
						end
						
						if entity.GetGridIndex(entity) == 73 then
							disableRight = true
						end
					end
			end
		end
	end
	
	
	--debugging, remove later
	print("BlockBot: "..tostring(disableBot).." BlockLeft: "..tostring(disableLeft).." BlockRight: "..tostring(disableRight).." BlockTop: "..tostring(disableTop))
	--printMatrix(true, true, false, true, true, false)
	
	--TODO - use the disable variables
end

secretMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, updateMap)
secretMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, findPossibilities)