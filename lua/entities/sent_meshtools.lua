-----------------------------------------------------------------------
-- Meshtools Base Entity
-----------------------------------------------------------------------

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Dynamic Mesh"
ENT.Author = "shadowscion"
ENT.Category = "Mesh Tools"

ENT.Spawnable = true
ENT.AdminOnly = false

local meshtools = meshtools

-----------------------------------------------------------------------
-- Meshtools Base Entity Shared
-----------------------------------------------------------------------

function ENT:Initialize()
    if SERVER then
        self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
        self:DrawShadow( false )

        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )

        self:GetPhysicsObject():Wake()
    else
        self.Mesh = {
            CRC = nil,
            Loaded = false,
            Matrix = Matrix(),
            Material = Material( "models/debug/debugwhite" ),
        }
    end
end

-----------------------------------------------------------------------
-- Meshtools Base Entity Serverside
-----------------------------------------------------------------------

if SERVER then

    function ENT:SpawnFunction( Ply, Trace, Class )
        if not Trace.Hit then return end

        local Ent = ents.Create( Class )

        Ent:SetPos( Trace.HitPos + Trace.HitNormal*100 )
        Ent:Spawn()
        Ent:Activate()

        return Ent
    end

end
-----------------------------------------------------------------------
-- Meshtools Base Entity Clientside
-----------------------------------------------------------------------

if not CLIENT then return end

local meshCache = meshtools.MeshCache

function ENT:LoadObjFromFile( filepath, forceReload )
    self.Mesh.Loaded = false
    self.Mesh.CRC = meshtools.LoadObjFromFile( filepath, forceReload )
end

function ENT:ShouldDraw()
    if not self.Mesh then return false end

    self:DrawModel()

    if self.Mesh.Loaded then return true end
    if self.Mesh.CRC then
        if meshCache[self.Mesh.CRC] then
            self.Mesh.Mesh = Mesh()
            self.Mesh.Mesh:BuildFromTriangles( meshCache[self.Mesh.CRC] )
            self.Mesh.Loaded = true
        end
        return false
    end
end

function ENT:Draw()
    if not self:ShouldDraw() then return end

    self.Mesh.Matrix:SetTranslation( self:GetPos() )
    self.Mesh.Matrix:SetAngles( self:GetAngles() )

    render.SetMaterial( self.Mesh.Material )
    render.SetLightingMode( 1 )
    cam.PushModelMatrix( self.Mesh.Matrix )

    self.Mesh.Mesh:Draw()

    cam.PopModelMatrix()
    render.SetLightingMode( 0 )
end


hook.Remove( "HUDPaint", "meshtools.LoadOverlay" )
hook.Add( "HUDPaint", "meshtools.LoadOverlay", function()
    local bc = Color( 175, 175, 175, 135 )
    local tc = Color( 225, 225, 225, 255 )

    for _, ent in pairs( ents.FindByClass( "sent_meshtools" ) ) do
        if not ent.Mesh then continue end
        if ent.Mesh.Loaded then continue end

        local scr = ( ent:GetPos() + Vector( 0, 0, 20 ) ):ToScreen()
        draw.WordBox( 6, scr.x, scr.y, "Loading.." .. ent:EntIndex(), "DermaDefault", bc, tc )
    end
end )
