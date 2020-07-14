--at#5005
local getLibrary = loadstring(game:HttpGet('https://pastebin.com/raw/nxCukB3u', true))()
local ui_options = {
	main_color = Color3.fromRGB(41, 74, 122),
	min_size = Vector2.new(400, 300),
	can_resize = true,
	parent = game.CoreGui,
	name = "imgui"
}
local lib = getLibrary(ui_options)

local answerremote = game.ReplicatedStorage.Remotes.Events.Answer
local chatremote = game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
local questions = {}

function findQuestion(question)
    for _, fq in pairs(questions) do
        if fq.Question~=question.Question then 
            continue
        end
        for _, v in pairs(fq.Answers) do
            if not question.Answers[v] then
               return
            end
        end
        return fq
    end
end

function mergeQuestions(...)
	questions = {}
	for _, q in pairs({...}) do
		for _, v in pairs(q) do
			if not findQuestion(v) then
				table.insert(questions, v)
			end
		end
	end
end

local file = {}
local github = {}
if isfile("obbytriviaanswers.json") then
	file = game.HttpService:JSONDecode(readfile("obbytriviaanswers.json"))	
end
local githubt = game:HttpGet("https://raw.githubusercontent.com/bthecool/obbytrivia/master/questions.json", true)
if githubt then
	github = game.HttpService:JSONDecode(githubt)
end

mergeQuestions(file, github)


local currentquestion, matchingquestion
local autoanswer = true
local autoupdate = false

local window, obj = lib:AddWindow("obby trivia")
local c = window:AddTab("control panel")
local connections = {}
c:Show()
local qdisplay = c:AddLabel("Question: ???")
local adisplay = c:AddLabel("Answer: ???")
local ha = c:AddHorizontalAlignment()
ha:AddButton("Answer Manually", function()
    answerremote:FireServer(matchingquestion.Answer)
end)
ha:AddButton("Chat Answer", function()
    chatremote:FireServer(matchingquestion.Answer, "All")
end)
c:AddSwitch("Auto-Answer", function(val)
    autoanswer = val
end):Set(autoanswer)
local autocollectcoinsenabled = false
c:AddSwitch("Auto-Collect Coins", function(val)
	autocollectcoinsenabled = val
end)
spawn(function()
	while wait() do
	    if autocollectcoinsenabled then
				for _, v in pairs(workspace.Lobby.PracticeCoins:GetChildren()) do
					v.Position = game.Players.LocalPlayer.Character.Head.Position
				end
			end
	end
end)

local m = window:AddTab("misc")
local numofquestions = m:AddLabel("num of questions in arsenal: "..#questions)

function callAutoUpdate()
    if autoupdate then
        writefile("obbytriviaanswers.json", game.HttpService:JSONEncode(questions))
    end
end

m:AddSwitch("Auto-update answers file", function(val)
    autoupdate = val
		if val then
			callAutoUpdate()
		end
end):Set(autoupdate)

m:AddButton("destroy gui", function()
    for _, v in pairs(connections) do
        v:Disconnect()
    end
    obj:Destroy()
end)


function addQuestion(question)
    table.insert(questions, question)
    numofquestions.Text = "num of questions in arsenal: "..#questions
		callAutoUpdate()
end
local greencolor = Color3.new(0, 0.7058823529411765, 0);
function doQuestion(child)
	currentquestion = {
			Question = child.Frame.Question.Text,
			Answers = {},
--          Answer = nil,
	}
	for _, answer in pairs(child.Frame.Answers:GetChildren()) do
			currentquestion.Answers[answer.Text] = true
			local image = answer.ImageLabel
			table.insert(connections, image:GetPropertyChangedSignal("ImageColor3"):Connect(function()
					if image.ImageColor3 == greencolor then
							if not matchingquestion then
									currentquestion.Answer = answer.Text
									addQuestion(currentquestion)
							elseif matchingquestion.Answer~=answer.Text then --correct an incorrect question
									matchingquestion.Answer = answer.Text
									callAutoUpdate()
							end
					end
			end))
	end
	matchingquestion = findQuestion(currentquestion)
	if matchingquestion then
			qdisplay.Text = "Question: "..matchingquestion.Question
			adisplay.Text = "Answer: "..matchingquestion.Answer
			if autoanswer then
				wait(2.5) --delay answer so it doesnt look suspicious
				answerremote:FireServer(matchingquestion.Answer)
			end
	end
	table.insert(connections, child:GetPropertyChangedSignal("Parent"):Connect(function()
			if child.Parent==nil then
					matchingquestions = nil
					qdisplay.Text = "Question: ???"
					adisplay.Text = "Answer: ???"
			end
	end))
end	

table.insert(connections, game.Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(child)
    if child.Name=="Question" then
		doQuestion(child)
    end
end))
