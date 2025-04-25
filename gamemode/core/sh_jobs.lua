local meta = FindMetaTable("Player")

Amalgam.Jobs = {}

function Amalgam.JobBlueprint(data)
    assert(data.UniqueID, "Job must have a UniqueID")

    data.Name = data.Name or "Unnamed Job"
    data.Description = data.Description or "No description."
    data.Model = data.Model or ""
    data.JobFunc = data.JobFunc or function() end

    Amalgam.Jobs[data.UniqueID] = data
    return data
end

--[[
  Example Blueprint

  Amalgam.JobBlueprint({
    -- Unique identifier for this job (REQUIRED).
    -- Must be a unique string. Job blueprints cannot share the same UniqueID.
    UniqueID = "Unique_Job_ID",

    -- The display name of the job. Appears in UI.
    Name = "Job Name",

    -- A short description shown in the UI, explaining what this job does.
    Description = "Job Description.",

    -- The player model(s) used by this job.
    -- Accepts a single string (one model) or a table of strings (multiple options).
    Model = "models/player/example.mdl", -- or { "models/player/one.mdl", "models/player/two.mdl" }

    -- (OPTIONAL) Bodygroups to apply when the player becomes this job.
    -- Format: [bodygroupIndex] = value
    -- Can be omitted if not needed.
    BodyGroups = {
      [0] = 1,
      [1] = 2
    },

    -- (OPTIONAL) Maximum number of players allowed in this job at once.
    -- If omitted, the job has unlimited slots.
    -- Enforced in real-time during job selection.
    MaxSlots = 3,

    -- (OPTIONAL) The amount of money this job generates for the player on a recurring timer.
    -- If omitted, the player will not earn passive income from this job.
    Income = 50,

    -- (OPTIONAL) Will allow this job to use a radio and communicate with other players on the same job
    -- If omitted, this job can't use the radio or hear other jobs radios
    CanRadio = True

    -- (OPTIONAL) A function that runs when a player switches to this job.
    -- Ideal for applying job-specific logic, such as giving weapons or gear.
    -- If not provided, a default empty function will be used.
    JobFunc = function(ply)
      -- Example:
      -- ply:Give("weapon_pistol")
      -- ply:ChatPrint("Welcome to the force, Officer!")
    end
  })
--]]

Amalgam.JobBlueprint({
    UniqueID = "Job_None",
    Name = "Unemployed",
    Description = "A jobless drifter with no income and no responsibilities. Get a job, you lazy prick."
})

function meta:SetJob(job)
    local data = Amalgam.Jobs[job]
    if (not data) then return end
    if (not data.UniqueID) then return end

    job = data.UniqueID or "Job_None"

    if (data.MaxSlots and data.MaxSlots > 0) then
        local slotsCount = 0
        for _, v in pairs(player.GetAll()) do
            if (IsValid(v) and v:IsPlayer() and v:Alive() and v:GetJob() == job) then
                slotsCount = slotsCount + 1
            end
        end
        if (slotsCount >= data.MaxSlots) then 
            return false, "There are enough in this job."
        end
    end
  
  	local dModel = self:CharModel()

    if (data.Model and data.Model ~= "") then
        if (type(data.Model) == "table") then
            self:SetModel(table.Random(data.Model))
        else
            self:SetModel(data.Model)
        end
    else
    	self:SetModel(dModel)
   	end

    if (data.BodyGroups and type(data.BodyGroups) == "table") then
        for bodygroup, value in pairs(data.BodyGroups) do
            self:SetBodygroup(bodygroup, value)
        end
    end

    if (data.Income and data.Income > 0) then
        self:StartIncomeTimer()
    else
        self:StopIncomeTimer()
    end

    self:StripWeapons()
    GAMEMODE:PlayerLoadout(self)

    if (data.JobFunc) then
        data.JobFunc(self)
    end

    self.JobID = job

    local displayName = data.Name or "Unemployed"
    self:SetNWString("PlayerJobName", displayName)
end

function meta:GetJob()
    return self.JobID or "Job_None"
end

function meta:CanSetJob(id)
    if (self:GetJob() == id) then
        return false, "You already have that job"
    end
    return true
end

function meta:GetJobName()
    return self:GetNWString("PlayerJobName", "")
end

function meta:StartIncomeTimer()
    self:StopIncomeTimer()
    local incomeID  = "Amalgam_Income_" .. self:SteamID64()
    local data = Amalgam.Jobs[self:GetJob()]
    if (not data or not data.Income or data.Income <= 0) then return end

    timer.Create(incomeID , 300, 0, function()
        if (IsValid(self) and self:IsPlayer() and self:Alive() and not self:IsAfk(120)) then
            self:AddMoney(data.Income)
            net.Start("SendNotification")
                net.WriteString("You received " .. data.Income .. "$ for your work.")
            net.Send(self)
        end
    end)

    self.IncomeTimerID = incomeID
end

function meta:StopIncomeTimer()
    if (not self.IncomeTimerID) then return end
    timer.Remove(self.IncomeTimerID)
end

if (SERVER) then
    net.Receive("nChooseJob", function(len, ply)
        local job = net.ReadString()
        local canSet, reason = ply:CanSetJob(job)

        if (not Amalgam.Jobs[job]) then return end

        if (not canSet) then
            ply:Notify(reason or "You can't choose that job")
            return
        end
        ply:SetJob(job)
    end)
end