local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddControllers(ReplicatedStorage.Controllers)  -- add folder with controllers
Knit.Start():catch(warn("started")) -- starting knit
