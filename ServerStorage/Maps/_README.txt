This directory contains map models for the multi-map system.

STRUCTURE STANDARD:
Each map MUST be a Model with the following structure:

<MapName> (Model)
├── ZombieSpawnPoints (Folder) [REQUIRED]
│   └── Part/Attachment instances (minimum 8)
└── SpawnPoints (Folder) [RECOMMENDED]
    ├── ResourceSpawns (Folder)
    │   └── Part instances (minimum 4)
    └── ItemSpawns (Folder)
        └── Part instances (minimum 4)

LEGACY SUPPORT:
- ResourceSpawnPoints (Folder) at map root is also supported

CREATING MAPS:
1. Use MapGenerator tool (ServerStorage/DevOnly/MapGenerator.lua):
   require(game.ServerStorage.DevOnly.MapGenerator).generateAll()

2. Or manually create following the structure above

See MAP_STRUCTURE.md in root directory for complete documentation.

CURRENT MAPS:
- ResearchOutpost (default)
- Village
- Dockyards
- ResearchOutpost_Night (variant)

Maps are validated on load - check output for validation results.
