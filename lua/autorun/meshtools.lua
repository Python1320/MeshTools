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

    include( "meshtools/modules/vnet.lua" )

    util.AddNetworkString( "meshtools.start_export" )

    return
end

if CLIENT then
    include( "meshtools/modules/vnet.lua" )
    include( "meshtools/modules/decode.lua" )
    include( "meshtools/libraries/export.lua" )

    return
end
