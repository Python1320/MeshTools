-----------------------------------------------------------------------
-- Meshtools Import Lib
-----------------------------------------------------------------------

local meshtools = meshtools
local meshCache = meshtools.MeshCache

local table = table
local string = string
local coroutine = coroutine

-----------------------------------------------------------------------
-- Meshtools Import Lib
-----------------------------------------------------------------------

local function vertex( id, pos, norm, u, v )
    return {
        pos_index = id,
        pos = pos,
        norm = norm,
        u = u,
        v = v,
    }
end

local function fixFace( data )
    local val = string.Explode( "/", data )

    val[1] = tonumber( val[1] )
    val[2] = tonumber( val[2] )
    val[3] = tonumber( val[3] )

    return val
end

local function vec( data, norm )
    if norm then return Vector( tonumber( data[2] ), tonumber( data[3] ), tonumber( data[4] ) ):GetNormalized() end
    return Vector( tonumber( data[2] ), tonumber( data[3] ), tonumber( data[4] ) )
end

local function uvw( data )
    return { u = tonumber( data[2] ) % 1, v = tonumber( 1 - data[3] ) % 1 }
end

local function parse( obj )
    local faces, vcoords, ncoords, tcoords = {}, {}, {}, {}

    for line in string.gmatch( obj, "(.-)\n" ) do
        local data = string.Explode( "%s+", string.Trim( line ), true )
        local type = data[1]

        if     type == "f"  and #data >= 4 then faces[#faces + 1] = data
        elseif type == "v"  and #data >= 4 then vcoords[#vcoords + 1] = vec( data, false )
        elseif type == "vn" and #data >= 4 then ncoords[#ncoords + 1] = vec( data, true )
        elseif type == "vt" and #data >= 3 then tcoords[#tcoords + 1] = uvw( data )
        end

        coroutine.yield( false )
    end

    local hasNormals = #ncoords >= 1
    local hasUVW = #tcoords >= 1

    local meshData = {}

    for _, face in pairs( faces ) do
        local faceVertexA = fixFace( face[2] )
        local faceVertexB = fixFace( face[3] )

        for i = 4, #face do
            local faceVertexC = fixFace( face[i] )

            local meshVertexA = vertex( faceVertexA[1], vcoords[faceVertexA[1]] )
            local meshVertexB = vertex( faceVertexC[1], vcoords[faceVertexC[1]] )
            local meshVertexC = vertex( faceVertexB[1], vcoords[faceVertexB[1]] )

            if hasNormals then
                meshVertexA.normal = ncoords[faceVertexA[3]]
                meshVertexB.normal = ncoords[faceVertexC[3]]
                meshVertexC.normal = ncoords[faceVertexB[3]]
            else
                local normal = ( ( meshVertexC.pos - meshVertexA.pos ):Cross( meshVertexB.pos - meshVertexA.pos ) ):GetNormalized()

                meshVertexA.normal = normal
                meshVertexB.normal = normal
                meshVertexC.normal = normal
            end

            if hasUVW then
                meshVertexA.u = tcoords[faceVertexA[2]].u
                meshVertexA.v = tcoords[faceVertexA[2]].v
                meshVertexB.u = tcoords[faceVertexC[2]].u
                meshVertexB.v = tcoords[faceVertexC[2]].v
                meshVertexC.u = tcoords[faceVertexB[2]].u
                meshVertexC.v = tcoords[faceVertexB[2]].v
            end

            meshData[#meshData + 1] = meshVertexA
            meshData[#meshData + 1] = meshVertexB
            meshData[#meshData + 1] = meshVertexC

            faceVertexB = faceVertexC
        end

        coroutine.yield( false )
    end

    return meshData
end

local function assemble( obj, crc )
    meshCache[crc] = nil

    local meshData = {}

    local coro = coroutine.create( function()
        meshData = parse( obj )
        coroutine.yield( true )
    end )

    hook.Remove( "Think", "meshtools.import" .. LocalPlayer():EntIndex() )
    hook.Add( "Think", "meshtools.import" .. LocalPlayer():EntIndex(), function()
        local bm = SysTime()

        while SysTime() - bm < 0.002 do
            local _, msg = coroutine.resume( coro )

            if msg then
                print( "done" )
                meshCache[crc] = meshData
                hook.Remove( "Think", "meshtools.import" .. LocalPlayer():EntIndex() )
                break
            end
        end
    end )
end

-----------------------------------------------------------------------
-- Meshtools Import Functions
-----------------------------------------------------------------------

function meshtools.LoadObjFromFile( filepath, forceReload )
    if not file.Exists( filepath, "DATA" ) then return end

    local crc = util.CRC( filepath )
    if meshCache[crc] then
        if forceReload then meshCache[crc] = nil else return crc end
    end

    local objFile = file.Open( filepath, "rb", "DATA" )
    assemble( objFile:Read( objFile:Size() ), crc )
    objFile:Close()

    return crc
end
