-----------------------------------------------------------------------
-- Meshtools
-- Created by shadowscion
--
-- Credits:
--  Vercas ( vnet )
--  MDave ( smd decoder )
-----------------------------------------------------------------------

meshtools = meshtools or {}

if SERVER then
    AddCSLuaFile()
    AddCSLuaFile( "meshtools/modules/vnet.lua" )
    AddCSLuaFile( "meshtools/modules/decode.lua" )
    AddCSLuaFile( "meshtools/libraries/export.lua" )
    AddCSLuaFile( "meshtools/libraries/import.lua" )

    include( "meshtools/modules/vnet.lua" )

    util.AddNetworkString( "meshtools.start_export" )

    return
end

if CLIENT then
    meshtools.MeshCache = meshtools.MeshCache or {}

    include( "meshtools/modules/vnet.lua" )
    include( "meshtools/modules/decode.lua" )
    include( "meshtools/libraries/export.lua" )
    include( "meshtools/libraries/import.lua" )

    return
end
