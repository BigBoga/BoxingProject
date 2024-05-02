local ServerStorage = game:GetService("ServerStorage")
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

Knit.AddServices(ServerStorage.Services) -- add services 
Knit.Start():catch(warn("started")) -- starting knit
