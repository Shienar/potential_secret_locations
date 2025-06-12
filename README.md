# potential_secret_locations
IMPORTANT: This mod doesn't work unless you have also installed MiniMAPI at https://steamcommunity.com/sharedfiles/filedetails/?id=1978904635&amp;searchtext=minimapi

This is a lua mod for The Binding of Isaac that adds room icons to the minimap in locations where secret rooms and super secret rooms could spawn.

The mod creates and stores a 13x13 matrix of every grid index that a room can occupy, and it populates it with all existing rooms whenever a level is loaded. Using this initial grid, the mod makes note of all possible spawn locations for the secret room and super secret room.

When the player enters a new room, the mod searches for paths from a door to any potential secret room entrances. If no obstacles could be found blocking a path to a potential spawn location, the player's minimap will be updated to show the spawn location on their minimap. If an obstacle can be found blocking a potential location that has already appeared on the player's minimap, then that potential location is removed from the player's minimap.

Other Notes:
- All extraneous secret room locations will get removed when you have entered every secret room location on the floor.
- All extraneous super secret room locations will get removed when you have entered every super secret room location on the floor.
- A potential secret room location will get removed from the map if an explosion happens near it.
- If the player has blue map, the spelunker's hat, the mind, or x-ray vision, then this mod will not clutter your map with &quot;fake&quot; room locations.
- Extraneous potential secret locations will be cleared from the floor's map when the player uses the sun or world cards. The same applies for ansuuz and for picking up luna for the first time.
- If the player uses Dad's Key or the get out of jail free card, then all &quot;fake&quot; potential locations that are neighbors with the current room will be removed from the map.
- If the player has the Dog Tooth, then potential locations will be removed from the map for rooms that the dog doesn't howl in.


TLDR: You will see extra room icons for possible secret and super secret room locations as you explore the map. Some of these icons will get removed as you explore more of the map, pick up items, or enter the &quot;real&quot; secret or super secret rooms.

Steam page: https://steamcommunity.com/sharedfiles/filedetails/?id=3493320807
