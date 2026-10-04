-- Moves the test install's plugins to the lockfile, for tests/bootstrap.lua. The install already holds every
-- committed revision, so the sync runs offline first and goes online only for plugins it could not move.
-- update is vim.pack.update, and off() returns the plugins that are still off the lockfile.
return function(update, off)
	local ok, err = pcall(update, nil, { target = "lockfile", force = true, offline = true })
	local still_off = off()
	if not ok or #still_off > 0 then
		-- An error does not name the plugins it affected, so with none off, every plugin goes online.
		ok, err = pcall(update, #still_off > 0 and still_off or nil, { target = "lockfile", force = true })
		still_off = off()
	end
	return ok, err, still_off
end
