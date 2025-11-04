-- SimpleFS – Complete File System Wrapper for Potassium FS
local SimpleFS = {}

-- Check if a file exists
function SimpleFS.existsFile(path)
    return isfile(path)
end

-- Check if a folder exists
function SimpleFS.existsFolder(path)
    return isfolder(path)
end

-- Read the contents of a file
function SimpleFS.read(path)
    if isfile(path) then
        return readfile(path)
    else
        error("File does not exist: " .. path)
    end
end

-- Write data to a file (overwrites if exists)
function SimpleFS.write(path, data)
    if isfile(path) then
        delfile(path)
    end
    writefile(path, data)
end

-- Append data to a file (creates if missing)
function SimpleFS.append(path, data)
    appendfile(path, data)
end

-- Delete a file
function SimpleFS.deleteFile(path)
    if isfile(path) then
        delfile(path)
    else
        error("File does not exist: " .. path)
    end
end

-- Create a folder
function SimpleFS.createFolder(path)
    if not isfolder(path) then
        makefolder(path)
    end
end

-- Delete a folder
function SimpleFS.deleteFolder(path)
    if isfolder(path) then
        delfolder(path)
    else
        error("Folder does not exist: " .. path)
    end
end

-- List files and folders in a directory
function SimpleFS.list(path)
    if isfolder(path) then
        return listfiles(path)
    else
        error("Folder does not exist: " .. path)
    end
end

-- Load a Lua file as a function
function SimpleFS.load(path, chunkname)
    if isfile(path) then
        return loadfile(path, chunkname)
    else
        error("File does not exist: " .. path)
    end
end

-- Execute a Lua file
function SimpleFS.run(path)
    if isfile(path) then
        dofile(path)
    else
        error("File does not exist: " .. path)
    end
end

-- Convenience: create or overwrite a file
function SimpleFS.createFile(path, data)
    writefile(path, data)
end

return SimpleFS
