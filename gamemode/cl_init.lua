include("shared.lua")

function GM:Initialize()
	RunConsoleCommand( "cl_showhints", "0" )
end

function GM:ForceDermaSkin()
	return "AmalgamSkin"
end