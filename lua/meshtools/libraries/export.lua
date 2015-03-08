-----------------------------------------------------------------------
-- Meshtools Export Lib
-----------------------------------------------------------------------

local meshtools = meshtools

local decodeVVD = meshtools.decodeVVD
local decodeVTX = meshtools.decodeVTX
local decodeMDL = meshtools.decodeMDL

local table = table
local string = string
local coroutine = coroutine

-----------------------------------------------------------------------
-- Fake 'Origin' entity
-----------------------------------------------------------------------

local Origin = {}
Origin.__index = Origin

local function createOrigin( entGroup )
    local count = table.Count( entGroup )

    local center = Vector()
    for _, ent in pairs( entGroup ) do
        if not IsValid( ent ) then continue end
        center = center + ent:GetPos()
    end
    center = center/count

    local self = {
        Pos = center,
        Ang = Angle(),
    }

    return setmetatable( self, Origin )
end

function Origin:LocalToWorld( vector )
    local vec, _ = LocalToWorld( vector, Angle(), self.Pos, self.Ang )
    return vec
end

function Origin:LocalToWorldAngles( angle )
    local _, ang = LocalToWorld( Vector(), angle, self.Pos, self.Ang )
    return ang
end

function Origin:WorldToLocal( vector )
    local vec, _ = WorldToLocal( vector, Angle(), self.Pos, self.Ang )
    return vec
end

function Origin:WorldToLocalAngles( angle )
    local _, ang = WorldToLocal( Vector(), angle, self.Pos , self.Ang )
    return ang
end

-----------------------------------------------------------------------
-- Export Functions
-----------------------------------------------------------------------

local header = "# Compiled with MESHTOOLS Exporter for Garry's Mod\n"

local function parse( origin, entGroup )
    local vertex = 1
    local string_output = header

    for _, ent in pairs( entGroup ) do
        if not IsValid( ent ) then continue end

        -- Decompile the model
        local filepath = string.StripExtension( ent:GetModel() )

        local vvd = decodeVVD( filepath ).verts
        local vtx = decodeVTX( filepath )

        local lods = vtx.parts[1].models[1].lods[1].meshes[1].groups[1]
        local indexes = lods.indexes
        local verts = lods.verts

        local count = #indexes

        -- Obj format
        local string_vert = "\n# " .. filepath .. "\n# " .. count .. " vertices, " .. ( count/3 ) .. " tris\n\n"
        local string_norm = "\n"
        local string_uvw = "\n"
        local string_face = "\ng model" .. _ .. "\n"

        for triBase = 1, count, 3 do
            local vertA = vvd[verts[indexes[triBase + 0] + 1].vertIndex + 1]
            local vertB = vvd[verts[indexes[triBase + 1] + 1].vertIndex + 1]
            local vertC = vvd[verts[indexes[triBase + 2] + 1].vertIndex + 1]

            local vertPosA = origin:WorldToLocal( ent:LocalToWorld( vertA.pos ) )
            local vertPosB = origin:WorldToLocal( ent:LocalToWorld( vertB.pos ) )
            local vertPosC = origin:WorldToLocal( ent:LocalToWorld( vertC.pos ) )

            local normal = tostring( ( vertPosC - vertPosA ):Cross( vertPosB - vertPosA ):GetNormalized() )

            string_vert = string_vert .. "v " .. tostring( vertPosA ) .. "\n"
            string_vert = string_vert .. "v " .. tostring( vertPosB ) .. "\n"
            string_vert = string_vert .. "v " .. tostring( vertPosC ) .. "\n"

            string_norm = string_norm .. "vn " .. normal .. "\n"
            string_norm = string_norm .. "vn " .. normal .. "\n"
            string_norm = string_norm .. "vn " .. normal .. "\n"

            string_uvw = string_uvw .. "vt " .. ( vertA.u % 1 ) .. " " .. ( ( 1 - vertA.v ) % 1 ) .. " 0\n"
            string_uvw = string_uvw .. "vt " .. ( vertB.u % 1 ) .. " " .. ( ( 1 - vertB.v ) % 1 ) .. " 0\n"
            string_uvw = string_uvw .. "vt " .. ( vertC.u % 1 ) .. " " .. ( ( 1 - vertC.v ) % 1 ) .. " 0\n"

            string_face = string_face .. vertex .. "/" .. vertex .. "/" .. vertex .. " "
            string_face = string_face .. ( vertex + 2 ) .. "/" .. ( vertex + 2 ) .. "/" .. ( vertex + 2 ) .. " "
            string_face = string_face .. ( vertex + 1 ) .. "/" .. ( vertex + 1 ) .. "/" .. ( vertex + 1 ) .. "\n"

            vertex = vertex + 3

            coroutine.yield( false )
        end

        string_output = string_output.. string_vert .. string_norm .. string_uvw .. string_face

        coroutine.yield( false )
    end

    return string_output
end

function meshtools.StartExport( entGroup, filepath )
    local origin = createOrigin( entGroup )
    local output = ""

    local coro = coroutine.create( function()
        output = parse( origin, entGroup )
        coroutine.yield( true )
    end )

    hook.Remove( "Think", "meshtools.export" .. LocalPlayer():EntIndex() )
    hook.Add( "Think", "meshtools.export" .. LocalPlayer():EntIndex(), function()
        local bm = SysTime()

        while SysTime() - bm < 0.002 do
            local _, msg = coroutine.resume( coro )

            if msg then
                if filepath then
                    local doc = file.Open( filepath, "wb", "DATA" )
                    doc:Write( output )
                    doc:Close()
                end

                hook.Remove( "Think", "meshtools.export" .. LocalPlayer():EntIndex() )
                break
            end
        end
    end )
end

-----------------------------------------------------------------------
-- STool
-----------------------------------------------------------------------

net.Receive( "meshtools.start_export", function()
    local entGroup = {}
    local count = net.ReadUInt( 16 )

    for i = 0, count do
        local eid = net.ReadUInt( 16 )
        if not IsValid( Entity( eid ) ) then continue end
        table.insert( entGroup, Entity( eid ) )
    end

    if count <= 0 then return end
    meshtools.StartExport( entGroup, "test.txt" )
end )
