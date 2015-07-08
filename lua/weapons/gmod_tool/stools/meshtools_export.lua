
TOOL.Category = "Mesh Tools"
TOOL.Name = "#tool.meshtools_export.listname"

TOOL.Selection = {}
TOOL.SelectionColor = Color( 0, 255, 0, 125 )

TOOL.ClientConVar["radius"] = "512"
TOOL.ClientConVar["selcol_r"] = "0"
TOOL.ClientConVar["selcol_g"] = "255"
TOOL.ClientConVar["selcol_b"] = "0"

if CLIENT then
    language.Add( "tool.meshtools_export.name", "Export" )
    language.Add( "tool.meshtools_export.listname", "Export" )
    language.Add( "tool.meshtools_export.desc", "Compiles and exports selected entities into a wavefront obj file." )
    language.Add( "tool.meshtools_export.0", "Shift-Click to select entities in a radius." )

    local function click()
        return true
    end

    TOOL.LeftClick = click
    TOOL.RightClick = click

    function TOOL.BuildCPanel( CPanel )
        CPanel:AddControl( "Color", {
            Label = "Customize your selection color!",
            Red = "export_meshtools_selcol_r",
            Green = "export_meshtools_selcol_g",
            Blue = "export_meshtools_selcol_b",
        } )

        CPanel:NumSlider( "Selection radius", "export_meshtools_radius", 64, 4096, 0 )

        -- TODO: Entity Filters

    end

    return
end

util.AddNetworkString( "meshtools.ExportSTool" )

local function isPropOwner( ply, ent )
    if CPPI then
        return ent:CPPIGetOwner() == ply
    end

    for k, v in pairs( g_SBoxObjects ) do
        for b, j in pairs( v ) do
            for _, e in pairs( j ) do
                if e == ent and k == ply:UniqueID() then return true end
            end
        end
    end

    return false
end

function TOOL:IsSelected( ent )
    local eid = ent:EntIndex()
    return self.Selection[eid] ~= nil
end

function TOOL:Select( ent )
    local eid = ent:EntIndex()

    if not self:IsSelected( ent ) then
        local oldColor = ent:GetColor()

        ent:SetColor( self.SelectionColor )
        ent:SetRenderMode( RENDERMODE_TRANSALPHA )
        ent:CallOnRemove( "meshtools.ClearSelectionOnRemove", function( e )
            self:Deselect( e )
            self.Selection[e:EntIndex()] = nil
        end )

        self.Selection[eid] = oldColor
    end
end

function TOOL:Deselect( ent )
    local eid = ent:EntIndex()

    if self:IsSelected( ent ) then
        local oldColor = self.Selection[eid]

        ent:SetColor( oldColor )
        ent:SetRenderMode( oldColor.a ~= 255 and RENDERMODE_TRANSALPHA or RENDERMODE_NORMAL )

        self.Selection[eid] = nil
    end
end

function TOOL:LeftClick( Trace )
    local ply = self:GetOwner()
    local ent = Trace.Entity

    if ent:IsWorld() and not ply:KeyDown( IN_USE ) then return false end

    if IsValid( ent ) then
        if ent:IsPlayer() then return false end
        if not isPropOwner( ply, ent ) then return false end
        if not util.IsValidPhysicsObject( ent, Trace.PhysicsBone ) then return false end
    end

    /**/

    self.SelectionColor = Color( self:GetClientNumber( "selcol_r", 0 ), self:GetClientNumber( "selcol_g", 255 ), self:GetClientNumber( "selcol_b", 0 ), 125 )

    if ply:KeyDown( IN_USE ) then
        local radius = math.Clamp( self:GetClientNumber( "radius" ), 64, 4096 )

        for _, NEnt in pairs( ents.FindInSphere( Trace.HitPos, radius ) ) do
            if IsValid( NEnt ) and isPropOwner( ply, NEnt ) then
                self:Select( NEnt )
            end
        end

        return false
    elseif self:IsSelected( ent ) then
        self:Deselect( ent )

        return false
    else
        self:Select( ent )

        return false
    end

    return false
end

function TOOL:RightClick( Trace )
    local count = table.Count( self.Selection )

    if count < 1 then
        self.Selection = {}
        return false
    end

    net.Start( "meshtools.start_export" )
        net.WriteUInt( table.Count( self.Selection ), 16 )

        for eid, _ in pairs( self.Selection ) do
            net.WriteUInt( eid, 16 )
            self:Deselect( Entity( eid ) )
        end
    net.Send( self:GetOwner() )

    self.Selection = {}

    return false
end
