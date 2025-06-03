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
	local level = Game():GetLevel()
	local room = level:GetCurrentRoom()
	local index = level:GetCurrentRoomDesc().GridIndex
	local row, column = (math.floor(index/13) + 1), (index%13 + 1)
	local shape = room.GetRoomShape(room)
	
	--Check for obstacles in front of door, update matrix if necessary.
	--This was hours of easy, dull, busy work.
	for i = 0, room.GetGridSize(room) do
		local entity = room.GetGridEntity(room, i)
		if entity ~= nil then
			if entity.GetType(entity) ~= GridEntityType.GRID_NULL and
			   entity.GetType(entity) ~= GridEntityType.GRID_DECORATION and
			   entity.GetType(entity) ~= GridEntityType.GRID_WALL and 
			   entity.GetType(entity) ~= GridEntityType.GRID_SPIDERWEB and
			   entity.GetType(entity) ~= GridEntityType.GRID_DOOR then
					
					if shape == RoomShape.ROOMSHAPE_1x1 or shape == RoomShape.ROOMSHAPE_IH or shape == RoomShape.ROOMSHAPE_IV then
						--   1
						-- 3 X 4
						--   2
						if entity.GetGridIndex(entity) == 22 then
							--top (1) is blocked
							--print("Top is blocked")
							if row > 1 then matrix[row-1][column] = -1 end
						elseif entity.GetGridIndex(entity) == 112 then
							--bottom (2) is blocked
							--print("Bottom is blocked")
							if row < 13 then matrix[row+1][column] = -1 end
						elseif entity.GetGridIndex(entity) == 61 then
							--left (3) is blocked
							--print("Left is blocked")
							if column > 1 then matrix[row][column - 1] = -1 end
						elseif entity.GetGridIndex(entity) == 73 then
							--right (4) is blocked
							--print("Right is blocked")
							if column < 13 then matrix[row][column + 1] = -1 end
						end
					elseif shape == RoomShape.ROOMSHAPE_2x1 or shape == RoomShape.ROOMSHAPE_IIH then
						--horizontal 2x1
						--   3 4
						-- 1 X X 2
						--   5 6
						
						if entity.GetGridIndex(entity) == 113  then
							--1 is blocked
							--print("1 is blocked")
							if column > 1 then matrix[row][column - 1] = -1 end
						elseif entity.GetGridIndex(entity) == 138 then
							--2 is blocked
							--print("2 is blocked")
							if column < 12 then matrix[row][column + 2] = -1 end
						elseif entity.GetGridIndex(entity) == 35 then
							--3 is blocked
							print("3 is blocked")
							if row > 1 then matrix[row-1][column] = -1 end
						elseif entity.GetGridIndex(entity) == 48 then 
							--4 is blocked
							--print("4 is blocked")
							if row > 1 and column < 13 then matrix[row-1][column + 1] = -1 end
						elseif entity.GetGridIndex(entity) == 203 then 
							--5 is blocked
							--print("5 is blocked")
							if row < 13 then matrix[row+1][column] = -1 end
						elseif entity.GetGridIndex(entity) == 216 then 
							--6 is blocked
							--print("6 is blocked")
							if row < 13 and column < 13 then matrix[row+1][column + 1] = -1 end
						end
					elseif shape == RoomShape.ROOMSHAPE_1x2 or shape == RoomShape.ROOMSHAPE_IIV then
						--vertical 1x2
						--    1
						-- 	3 X 5
						--  4 X 6
						--    2
						
						if entity.GetGridIndex(entity) == 22  then 
							--1 is blocked
							--print("1 is blocked")
							if row > 1 then matrix[row - 1][column] = -1 end
						elseif entity.GetGridIndex(entity) == 217 then
							--2 is blocked
							--print("2 is blocked")
							if row < 12 then matrix[row + 2][column] = -1 end
						elseif entity.GetGridIndex(entity) == 61 then 
							--3 is blocked
							--print("3 is blocked")
							if column > 1 then matrix[row][column-1] = -1 end
						elseif entity.GetGridIndex(entity) == 166 then 
							--4 is blocked
							--print("4 is blocked")
							if column > 1 and row < 13 then matrix[row+1][column-1] = -1 end
						elseif entity.GetGridIndex(entity) == 73 then 
							--5 is blocked
							--print("5 is blocked")
							if column < 13 then matrix[row][column+1] = -1 end
						elseif entity.GetGridIndex(entity) == 178 then 
							--6 is blocked
							--print("6 is blocked")
							if column < 13 and row < 13 then matrix[row+1][column+1] = -1 end
						end
					elseif shape == RoomShape.ROOMSHAPE_2x2 then
						--   3 4
						-- 2 X X 5
						-- 1 X X 6
						--   7 8
						
						if entity.GetGridIndex(entity) == 309  then
							--1 is blocked
							--print("1 is blocked")
							if row < 13 and column > 1 then matrix[row+1][column-1] = -1 end
						elseif entity.GetGridIndex(entity) == 113 then
							--2 is blocked
							--print("2 is blocked")
							if column > 1 then matrix[row][column-1] = -1 end
						elseif entity.GetGridIndex(entity) == 35 then
							--3 is blocked
							--print("3 is blocked")
							if row > 1 then matrix[row - 1][column] = -1 end
						elseif entity.GetGridIndex(entity) == 48 then
							--4 is blocked
							--print("4 is blocked")
							if row > 1 and column < 13 then matrix[row - 1][column+1] = -1 end
						elseif entity.GetGridIndex(entity) == 138 then 
							--5 is blocked
							--print("5 is blocked")
							if column < 12 then matrix[row][column+2] = -1 end
						elseif entity.GetGridIndex(entity) == 334 then
							--6 is blocked
							--print("6 is blocked")
							if row < 13 and column < 12 then matrix[row+1][column+2] = -1 end
						elseif entity.GetGridIndex(entity) == 399 then 
							--7 is blocked
							--print("7 is blocked")
							if row < 12 then matrix[row+2][column] = -1 end
						elseif entity.GetGridIndex(entity) == 412 then
							--8 is blocked
							--print("8 is blocked")
							if row < 12 and column < 13 then matrix[row+2][column+1] = -1 end
						end
					elseif shape == RoomShape.ROOMSHAPE_LTR then
						--top-right square missing
						--    3
						--	2 X 4
						--	1 X X 5
						--	  6 7
						
						
						if entity.GetGridIndex(entity) == 309  then
							--1 is blocked
							--print("1 is blocked")
							if row < 13 and column > 1 then matrix[row+1][column-1] = -1 end
						elseif entity.GetGridIndex(entity) == 113 then 
							--2 is blocked
							--print("2 is blocked")
							if column > 1 then matrix[row][column-1] = -1 end
						elseif entity.GetGridIndex(entity) == 35 then 
							--3 is blocked
							--print("3 is blocked")
							if row > 1 then matrix[row-1][column] = -1 end
						elseif entity.GetGridIndex(entity) == 125 or entity.GetGridIndex(entity) == 244 then
							--4 is blocked
							--print("4 is blocked")
							if column < 13 then matrix[row][column+1] = -1 end
						elseif entity.GetGridIndex(entity) == 334 then  
							--5 is blocked
							--print("5 is blocked")
							if column < 12 and row < 13 then matrix[row+1][column+2] = -1 end
						elseif entity.GetGridIndex(entity) == 399 then 
							--6 is blocked
							--print("6 is blocked")
							if row < 12 then matrix[row+2][column] = -1 end
						elseif entity.GetGridIndex(entity) == 412 then  
							--7 is blocked
							--print("7 is blocked")
							if row < 12 and column < 13 then matrix[row+2][column+1] = -1 end
						end
					elseif shape == RoomShape.ROOMSHAPE_LTL then
						--top-left square missing
						--		3
						--	  2 X 4
						--	1 X X 5
						--	  6 7
						
						
						if entity.GetGridIndex(entity) == 309  then
							--1 is blocked
							--print("1 is blocked")
							if row < 13 and column > 1 then matrix[row+1][column-1] = -1 end
						elseif entity.GetGridIndex(entity) == 126 or entity.GetGridIndex(entity) == 231 then
							--2 is blocked
							--print("2 is blocked")
							matrix[row][column] = -1
						elseif entity.GetGridIndex(entity) == 48 then 
							--3 is blocked
							--print("3 is blocked")
							if row > 1 and column < 13 then matrix[row-1][column+1] = -1 end
						elseif entity.GetGridIndex(entity) == 138 then
							--4 is blocked
							--print("4 is blocked")
							if column < 12 then matrix[row][column+2] = -1 end
						elseif entity.GetGridIndex(entity) == 334 then 
							--5 is blocked
							--print("5 is blocked")
							if row < 13 and column < 12 then matrix[row+1][column+2] = -1 end
						elseif entity.GetGridIndex(entity) == 399 then
							--6 is blocked
							--print("6 is blocked")
							if row < 12 then matrix[row+2][column] = -1 end
						elseif entity.GetGridIndex(entity) == 412 then 
							--7 is blocked
							--print("7 is blocked")
							if row < 12 and column < 13 then matrix[row+2][column+1] = -1 end
						end
					elseif shape == RoomShape.ROOMSHAPE_LBR then
						--bottom-right square missing
						--    3 4
						--	2 X X 5
						--	1 X 6
						--    7
						
						
						if entity.GetGridIndex(entity) == 309  then
							--1 is blocked
							--print("1 is blocked")
							if row < 13 and column > 1 then matrix[row+1][column-1] = -1 end
						elseif entity.GetGridIndex(entity) == 113 then
							--2 is blocked
							--print("2 is blocked")
							if column > 1 then matrix[row][column] = -1 end
						elseif entity.GetGridIndex(entity) == 35 then 
							--3 is blocked
							--print("3 is blocked")
							if row > 1 then matrix[row - 1][column] = -1 end
						elseif entity.GetGridIndex(entity) == 48 then
							--4 is blocked
							--print("4 is blocked")
							if row > 1 and column < 13 then matrix[row-1][column+1] = -1 end
						elseif entity.GetGridIndex(entity) == 138 then
							--5 is blocked
							--print("5 is blocked")
							if column < 12 then matrix[row][column+2] = -1 end
						elseif entity.GetGridIndex(entity) == 321 or entity.GetGridIndex(entity) == 216 then 
							--6 is blocked
							--print("6 is blocked")
							if row < 13 and column < 13 then matrix[row+1][column+1] = -1 end
						elseif entity.GetGridIndex(entity) == 399 then
							--7 is blocked
							--print("7 is blocked")
							if row < 12 then matrix[row+2][column] = -1 end
						end
					elseif shape == RoomShape.ROOMSHAPE_LBL then
						--bottom-left square missing
						--    3 4
						--	2 X X 5
						--	  1 X 6
						--    	7
						if entity.GetGridIndex(entity) == 203 or entity.GetGridIndex(entity) == 322 then
							--1 is blocked
							--print("1 is blocked")
							if row < 13 then matrix[row+1][column] = -1 end
						elseif entity.GetGridIndex(entity) == 113 then 
							--2 is blocked
							--print("2 is blocked")
							if column > 1 then matrix[row][column-1] = -1 end
						elseif entity.GetGridIndex(entity) == 35 then
							--3 is blocked
							--print("3 is blocked")
							if row > 1 then matrix[row-1][column]= -1 end
						elseif entity.GetGridIndex(entity) == 48 then
							--4 is blocked
							--print("4 is blocked")
							if row > 1 and column < 13 then matrix[row-1][column + 1] = -1 end
						elseif entity.GetGridIndex(entity) == 138 then
							--5 is blocked
							--print("5 is blocked")
							if column < 12 then matrix[row][column+2] = -1 end
						elseif entity.GetGridIndex(entity) == 334 then
							--6 is blocked
							--print("6 is blocked")
							if row < 13 and column < 12 then matrix[row+1][column+2] = -1 end
						elseif entity.GetGridIndex(entity) == 412 then
							--7 is blocked
							--print("7 is blocked")
							if row < 12 and column < 13 then matrix[row+2][column+1] = -1 end
						end
					end
			end
		end
	end
	
	
	--debugging, remove later
	printMatrix(true, true, false, true, true, false)
end

secretMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, updateMap)
secretMod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, findPossibilities)