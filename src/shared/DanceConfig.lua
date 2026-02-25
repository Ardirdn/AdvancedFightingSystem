--[[
    DANCE CONFIG
    Letakkan di ReplicatedStorage
]]

local DanceConfig = {}

-- List animasi dance dengan ID dari Roblox
DanceConfig.Animations = {
	-- Kategori: Random / Special (Berdasarkan prefix '💀-')
	{
		Title = "Sturdy Ice Emote",
		AnimationId = "rbxassetid://76955565394078",
		Category = "Random / Special"
	},
	{
		Title = "Reels Scorpion",
		AnimationId = "rbxassetid://123154079225871",
		Category = "Random / Special"
	},
	{
		Title = "Reels TommyArcher",
		AnimationId = "rbxassetid://126124209780505",
		Category = "Random / Special"
	},
	{
		Title = "V Pose",
		AnimationId = "rbxassetid://124470087668144",
		Category = "Random / Special"
	},
	{
		Title = "Festive Dance",
		AnimationId = "rbxassetid://85821983531957",
		Category = "Random / Special"
	},
	{
		Title = "Mean Girls Dance",
		AnimationId = "rbxassetid://116370464408262",
		Category = "Random / Special"
	},

	-- Kategori: Trendy / Popular (Berdasarkan prefix '💕-' dan 'HOT-')
	{
		Title = "GunSmoke",
		AnimationId = "rbxassetid://70780110853201",
		Category = "Trendy / Popular"
	},
	{
		Title = "LoveSick Girl",
		AnimationId = "rbxassetid://95651165606352",
		Category = "Trendy / Popular"
	},
	{
		Title = "Ride it",
		AnimationId = "rbxassetid://83917259478611",
		Category = "Trendy / Popular"
	},
	{
		Title = "Rick",
		AnimationId = "rbxassetid://122529550502845",
		Category = "Trendy / Popular"
	},
	{
		Title = "Sway Sway",
		AnimationId = "rbxassetid://120812520626732",
		Category = "Trendy / Popular"
	},
	{
		Title = "Bounce",
		AnimationId = "rbxassetid://71300867844029",
		Category = "Trendy / Popular"
	},
	{
		Title = "xOh Shhh",
		AnimationId = "rbxassetid://115328144208322",
		Category = "Trendy / Popular"
	},
	{
		Title = "Vibe",
		AnimationId = "rbxassetid://110679695312445",
		Category = "Trendy / Popular"
	},
	{
		Title = "CongaConga",
		AnimationId = "rbxassetid://135286710222311",
		Category = "Trendy / Popular"
	},
	{
		Title = "DancingShuff",
		AnimationId = "rbxassetid://109489330599694",
		Category = "Trendy / Popular"
	},
	{
		Title = "Charleston",
		AnimationId = "rbxassetid://91312765709374",
		Category = "Trendy / Popular"
	},
	{
		Title = "Blinding Lights",
		AnimationId = "rbxassetid://96888629439867",
		Category = "Trendy / Popular"
	},
	{
		Title = "Can't Take My Eyes",
		AnimationId = "rbxassetid://100376115254991",
		Category = "Trendy / Popular"
	},
	{
		Title = "SwingRik",
		AnimationId = "rbxassetid://94660108536559",
		Category = "Trendy / Popular"
	},
	{
		Title = "Spike",
		AnimationId = "rbxassetid://87743101312357",
		Category = "Trendy / Popular"
	},
	{
		Title = "SpongeBob",
		AnimationId = "rbxassetid://95166311307902",
		Category = "Trendy / Popular"
	},
	{
		Title = "Sho",
		AnimationId = "rbxassetid://97841810896453",
		Category = "Trendy / Popular"
	},
	{
		Title = "Rolling",
		AnimationId = "rbxassetid://129733550654296",
		Category = "Trendy / Popular"
	},
	{
		Title = "Don't Start Now",
		AnimationId = "rbxassetid://95503583306181",
		Category = "Trendy / Popular"
	},
	{
		Title = "Bha",
		AnimationId = "rbxassetid://74694782225710",
		Category = "Trendy / Popular"
	},
	{
		Title = "Cher",
		AnimationId = "rbxassetid://126517266885818",
		Category = "Trendy / Popular"
	},
	{
		Title = "Bring it all",
		AnimationId = "rbxassetid://135833393138331",
		Category = "Trendy / Popular"
	},
	{
		Title = "Griddy",
		AnimationId = "rbxassetid://74164119930298",
		Category = "Trendy / Popular"
	},
	{
		Title = "QuickStep",
		AnimationId = "rbxassetid://100534541129034",
		Category = "Trendy / Popular"
	},
	{
		Title = "Pagodna",
		AnimationId = "rbxassetid://98515335561014",
		Category = "Trendy / Popular"
	},
	{
		Title = "HellToe",
		AnimationId = "rbxassetid://81468669780930",
		Category = "Trendy / Popular"
	},
	{
		Title = "Delad",
		AnimationId = "rbxassetid://81468669780930",
		Category = "Trendy / Popular"
	},
	{
		Title = "X WhenWalk",
		AnimationId = "rbxassetid://70413803418483",
		Category = "Trendy / Popular"
	},
	{
		Title = "Desire",
		AnimationId = "rbxassetid://86711056289189",
		Category = "Trendy / Popular"
	},
	{
		Title = "Candy",
		AnimationId = "rbxassetid://86653253392604",
		Category = "Trendy / Popular"
	},
	{
		Title = "El Toro",
		AnimationId = "rbxassetid://90332668332869",
		Category = "Trendy / Popular"
	},
	{
		Title = "Dance Now",
		AnimationId = "rbxassetid://94632090959765",
		Category = "Trendy / Popular"
	},
	{
		Title = "Last Xmas",
		AnimationId = "rbxassetid://126399574807389",
		Category = "Trendy / Popular"
	},
	{
		Title = "Call me Maybe",
		AnimationId = "rbxassetid://113060105490036",
		Category = "Trendy / Popular"
	},
	{
		Title = "Diamond",
		AnimationId = "rbxassetid://104040868368484",
		Category = "Trendy / Popular"
	},
	{
		Title = "BlackMagic",
		AnimationId = "rbxassetid://80137049742215",
		Category = "Trendy / Popular"
	},
	{
		Title = "IceCream",
		AnimationId = "rbxassetid://123470057471111",
		Category = "Trendy / Popular"
	},
	{
		Title = "FestivalDance",
		AnimationId = "rbxassetid://74757173159199",
		Category = "Trendy / Popular"
	},
	{
		Title = "Bday",
		AnimationId = "rbxassetid://117702274211367",
		Category = "Trendy / Popular"
	},
	{
		Title = "TheBoys",
		AnimationId = "rbxassetid://119821191369707",
		Category = "Trendy / Popular"
	},
	{
		Title = "SwishSwish",
		AnimationId = "rbxassetid://116495639460380",
		Category = "Trendy / Popular"
	},
	{
		Title = "Domino",
		AnimationId = "rbxassetid://85061954246155",
		Category = "Trendy / Popular"
	},
	{
		Title = "GunShot",
		AnimationId = "rbxassetid://140392876462441",
		Category = "Trendy / Popular"
	},
	{
		Title = "Flower",
		AnimationId = "rbxassetid://130775044314636",
		Category = "Trendy / Popular"
	},

	-- Kategori: Duo Dances (Berdasarkan prefix '👫DUO-')
	{
		Title = "TwoHearts - Right",
		AnimationId = "rbxassetid://118963863357855",
		Category = "Duo Dances"
	},
	{
		Title = "TwoHearts - Left",
		AnimationId = "rbxassetid://117619207633460",
		Category = "Duo Dances"
	},
	{
		Title = "TM - Right",
		AnimationId = "rbxassetid://72764961667334",
		Category = "Duo Dances"
	},
	{
		Title = "TM - Left",
		AnimationId = "rbxassetid://103788913593653",
		Category = "Duo Dances"
	},
	{
		Title = "SPOT - Right",
		AnimationId = "rbxassetid://82007912327351",
		Category = "Duo Dances"
	},
	{
		Title = "SPOT - Left",
		AnimationId = "rbxassetid://124057960669258",
		Category = "Duo Dances"
	},
	{
		Title = "PROBLEM - Right",
		AnimationId = "rbxassetid://107553681181861",
		Category = "Duo Dances"
	},
	{
		Title = "PROBLEM - Left",
		AnimationId = "rbxassetid://78378995394651",
		Category = "Duo Dances"
	},
	{
		Title = "OMG - Right",
		AnimationId = "rbxassetid://122260769982295",
		Category = "Duo Dances"
	},
	{
		Title = "OMG - Left",
		AnimationId = "rbxassetid://118759520686731",
		Category = "Duo Dances"
	},
	{
		Title = "MeToo - Right",
		AnimationId = "rbxassetid://76875248730891",
		Category = "Duo Dances"
	},
	{
		Title = "MeToo - Left",
		AnimationId = "rbxassetid://76875248730891",
		Category = "Duo Dances"
	},

	-- Kategori: K-Pop / Song Dances (Berdasarkan judul lagu/grup)
	{
		Title = "GodsMenu",
		AnimationId = "rbxassetid://75389622986971",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "MyHouse-2PM-StrayKids",
		AnimationId = "rbxassetid://100143717118882",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Maniac-StrayKids",
		AnimationId = "rbxassetid://122859611538263",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "MegaVerse-Straykids",
		AnimationId = "rbxassetid://101415443814009",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Domino-Straykids",
		AnimationId = "rbxassetid://81872825945839",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Maison-DreamCatcher",
		AnimationId = "rbxassetid://96586354647484",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "MemeM-Purplekiss",
		AnimationId = "rbxassetid://120992928670062",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "MeltingPoint-Zerobaseone",
		AnimationId = "rbxassetid://116431633244559",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Monster",
		AnimationId = "rbxassetid://85256102363815",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Momoiro",
		AnimationId = "rbxassetid://82271689161191",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Mascara",
		AnimationId = "rbxassetid://82271689161191",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "My bag",
		AnimationId = "rbxassetid://75971303996053",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Nerdy",
		AnimationId = "rbxassetid://71067307387631",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "NewlyEdgyIdols",
		AnimationId = "rbxassetid://80791587042753",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "No Celestial-Serapfim",
		AnimationId = "rbxassetid://112106556937461",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Nobody - Soyeon",
		AnimationId = "rbxassetid://84132548882692",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Nonstop-Ohmygirl",
		AnimationId = "rbxassetid://130171219837743",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "NoNoNo",
		AnimationId = "rbxassetid://125543427853224",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Not shy - Itzy",
		AnimationId = "rbxassetid://89644043255912",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "O.O .NMIXX",
		AnimationId = "rbxassetid://133758356842822",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "GirlsPlane",
		AnimationId = "rbxassetid://72100159587805",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "OMG-Newjeans",
		AnimationId = "rbxassetid://136912457885698",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Panorama",
		AnimationId = "rbxassetid://102454047130400",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Patbinsu-Billie",
		AnimationId = "rbxassetid://96814008395229",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "PeekABoo-RedVelvet",
		AnimationId = "rbxassetid://139389088055386",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "PerfectNight-Serafim",
		AnimationId = "rbxassetid://117581748766889",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "PickMe",
		AnimationId = "rbxassetid://119198515180376",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Pop-CSRw",
		AnimationId = "rbxassetid://136216206903756",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Pop Stars KDA",
		AnimationId = "rbxassetid://132668118495912",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Pop-NEYEON",
		AnimationId = "rbxassetid://76975266623773",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Poppy-Stayc",
		AnimationId = "rbxassetid://89782674507728",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Pop-CSR",
		AnimationId = "rbxassetid://118047634996529",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Problem - Ariana Grande",
		AnimationId = "rbxassetid://111991645555796",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "PS5 TXT",
		AnimationId = "rbxassetid://79251460491215",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Psycho - Red Velvet",
		AnimationId = "rbxassetid://89135911206970",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Oyooet - XG",
		AnimationId = "rbxassetid://113701559248185",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Realize-C'na",
		AnimationId = "rbxassetid://76394864391446",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "RainOnmeAriana- TT Ver",
		AnimationId = "rbxassetid://97056500695372",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Redmoon KARD",
		AnimationId = "rbxassetid://121445760941973",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Ringo-Itzy",
		AnimationId = "rbxassetid://112441736756677",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Rising-TripleS",
		AnimationId = "rbxassetid://72115882631708",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Roki-MikitoP",
		AnimationId = "rbxassetid://113953172778613",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "RollercoasterTTVEr-NMIXX",
		AnimationId = "rbxassetid://137815854582932",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Rollin Brave Girls",
		AnimationId = "rbxassetid://117125813438447",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "MrPumkinComicalDream",
		AnimationId = "rbxassetid://139740790256732",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "WhizperTheBoyz",
		AnimationId = "rbxassetid://106200607315362",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "BeyondthewayGigo",
		AnimationId = "rbxassetid://85014134898512",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Sweet Venom - ENHYPEN",
		AnimationId = "rbxassetid://89105026590285",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Batter up - Babymonster",
		AnimationId = "rbxassetid://94258387323033",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Drama-Asepa",
		AnimationId = "rbxassetid://120457451640143",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Boogie-up",
		AnimationId = "rbxassetid://105067889181859",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Loveade - VIVIZ",
		AnimationId = "rbxassetid://91568950563528",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "ETA TT VER-Newjeans",
		AnimationId = "rbxassetid://131263077718144",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "DNA",
		AnimationId = "rbxassetid://125981789709743",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Laila",
		AnimationId = "rbxassetid://87047063408149",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Pandora",
		AnimationId = "rbxassetid://114622475015781",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "ShootingStar",
		AnimationId = "rbxassetid://112555754656016",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "TomaToma",
		AnimationId = "rbxassetid://80711681377132",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "OMG",
		AnimationId = "rbxassetid://131356265877488",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Thunderous",
		AnimationId = "rbxassetid://104091328335113",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Mic",
		AnimationId = "rbxassetid://104091328335113",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Anpaman",
		AnimationId = "rbxassetid://70406521293773",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "BestofMe",
		AnimationId = "rbxassetid://88890190557802",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Fire",
		AnimationId = "rbxassetid://121737284181357",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "DKWTD",
		AnimationId = "rbxassetid://72301157366500",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "PrettySavage",
		AnimationId = "rbxassetid://98326651808984",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "SRR",
		AnimationId = "rbxassetid://108412036156171",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "RUN",
		AnimationId = "rbxassetid://81419828122567",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Lucy",
		AnimationId = "rbxassetid://96458172211069",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "AlcFree",
		AnimationId = "rbxassetid://83187768640427",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Cheshire",
		AnimationId = "rbxassetid://74737937281430",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Attention",
		AnimationId = "rbxassetid://90621883644879",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Better-Twice",
		AnimationId = "rbxassetid://138221557825665",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "TalkThatTalk",
		AnimationId = "rbxassetid://74997435972531",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "More&More",
		AnimationId = "rbxassetid://129622132291571",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Can'tStopM",
		AnimationId = "rbxassetid://121728369334683",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "TheFeels",
		AnimationId = "rbxassetid://140141427506468",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "DTNA",
		AnimationId = "rbxassetid://128927060328977",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "VeryNice",
		AnimationId = "rbxassetid://73003423823094",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "TondemoWonders",
		AnimationId = "rbxassetid://73003423823094",
		Category = "K-Pop / Song Dances"
	},
	{
		Title = "Hot17",
		AnimationId = "rbxassetid://83704508664823",
		Category = "K-Pop / Song Dances"
	},

	-- Kategori: Various Dances (Tarian umum / lainnya)
	{
		Title = "BellyBelly",
		AnimationId = "rbxassetid://75274380409203",
		Category = "Various Dances"
	},
	{
		Title = "BellyBelly2",
		AnimationId = "rbxassetid://98905155038650",
		Category = "Various Dances"
	},
	{
		Title = "BellyBelly3",
		AnimationId = "rbxassetid://120952934017778",
		Category = "Various Dances"
	},
	{
		Title = "Ditto",
		AnimationId = "rbxassetid://107977381447930",
		Category = "Various Dances"
	},
	{
		Title = "Twoerk",
		AnimationId = "rbxassetid://107977381447930",
		Category = "Various Dances"
	},
	{
		Title = "Flair",
		AnimationId = "rbxassetid://108646776422656",
		Category = "Various Dances"
	},
	{
		Title = "HeadSpin",
		AnimationId = "rbxassetid://125632235560710",
		Category = "Various Dances"
	},
	{
		Title = "Hockey",
		AnimationId = "rbxassetid://109009727294025",
		Category = "Various Dances"
	},
	{
		Title = "SambaDance",
		AnimationId = "rbxassetid://121315731964802",
		Category = "Various Dances"
	},
	{
		Title = "Chilling",
		AnimationId = "rbxassetid://112797862188298",
		Category = "Various Dances"
	},
	{
		Title = "Vibe",
		AnimationId = "rbxassetid://127325281805062",
		Category = "Various Dances"
	},
	{
		Title = "World",
		AnimationId = "rbxassetid://127325281805062",
		Category = "Various Dances"
	},
	{
		Title = "Mashonde",
		AnimationId = "rbxassetid://131609295719160",
		Category = "Various Dances"
	},
	{
		Title = "Genie",
		AnimationId = "rbxassetid://104854289347063",
		Category = "Various Dances"
	},
	{
		Title = "Forever",
		AnimationId = "rbxassetid://102136501491717",
		Category = "Various Dances"
	},
	{
		Title = "BAMBAM",
		AnimationId = "rbxassetid://88235701974431",
		Category = "Various Dances"
	},
	{
		Title = "HeartHeart",
		AnimationId = "rbxassetid://88235701974431",
		Category = "Various Dances"
	},
	{
		Title = "EveryoneLabsMe",
		AnimationId = "rbxassetid://110794897507388",
		Category = "Various Dances"
	},
	{
		Title = "BomboYeah",
		AnimationId = "rbxassetid://125656957212572",
		Category = "Various Dances"
	},
	{
		Title = "Whistle",
		AnimationId = "rbxassetid://129320960259573",
		Category = "Various Dances"
	},
	{
		Title = "SetMeFree",
		AnimationId = "rbxassetid://95220379962915",
		Category = "Various Dances"
	},
	{
		Title = "TeddyBear",
		AnimationId = "rbxassetid://131751288855832",
		Category = "Various Dances"
	},
	{
		Title = "DumDum",
		AnimationId = "rbxassetid://88032773896457",
		Category = "Various Dances"
	},
	{
		Title = "Flower",
		AnimationId = "rbxassetid://133805697512871",
		Category = "Various Dances"
	},
	{
		Title = "YoungDum",
		AnimationId = "rbxassetid://126724448318731",
		Category = "Various Dances"
	},
	{
		Title = "Hot",
		AnimationId = "rbxassetid://123144806062432",
		Category = "Various Dances"
	},
	{
		Title = "AntiFrag",
		AnimationId = "rbxassetid://74189411858130",
		Category = "Various Dances"
	},
	{
		Title = "Rising",
		AnimationId = "rbxassetid://74189411858130",
		Category = "Various Dances"
	},
	{
		Title = "Eleven",
		AnimationId = "rbxassetid://118080131445365",
		Category = "Various Dances"
	},
	{
		Title = "GlowStick",
		AnimationId = "rbxassetid://78905238360362",
		Category = "Various Dances"
	},
	{
		Title = "PerfectWorld",
		AnimationId = "rbxassetid://91738960452272",
		Category = "Various Dances"
	},
	{
		Title = "SunBurst",
		AnimationId = "rbxassetid://99931620700611",
		Category = "Various Dances"
	},
	{
		Title = "Clear",
		AnimationId = "rbxassetid://136537974808337",
		Category = "Various Dances"
	},
	{
		Title = "Mime",
		AnimationId = "rbxassetid://112756548436663",
		Category = "Various Dances"
	},
	{
		Title = "A1",
		AnimationId = "rbxassetid://71688898088980",
		Category = "Various Dances"
	},
	{
		Title = "LaidBack",
		AnimationId = "rbxassetid://113901879463532",
		Category = "Various Dances"
	},
	{
		Title = "Jitter",
		AnimationId = "rbxassetid://133680278565201",
		Category = "Various Dances"
	},
	{
		Title = "PickItUp",
		AnimationId = "rbxassetid://133680278565201",
		Category = "Various Dances"
	},
	{
		Title = "OndaPanda",
		AnimationId = "rbxassetid://95984109954535",
		Category = "Various Dances"
	},
	{
		Title = "Revels",
		AnimationId = "rbxassetid://115107408552982",
		Category = "Various Dances"
	},
	{
		Title = "GasLaw",
		AnimationId = "rbxassetid://102523593248190",
		Category = "Various Dances"
	},
	{
		Title = "Primo",
		AnimationId = "rbxassetid://132618789976278",
		Category = "Various Dances"
	},
	{
		Title = "WakeMeUp",
		AnimationId = "rbxassetid://97498793534937",
		Category = "Various Dances"
	},
	{
		Title = "SideHuslah",
		AnimationId = "rbxassetid://135954333430509",
		Category = "Various Dances"
	},
	{
		Title = "GasLow2",
		AnimationId = "rbxassetid://94909554571996",
		Category = "Various Dances"
	},
	{
		Title = "Bomb",
		AnimationId = "rbxassetid://128274409474644",
		Category = "Various Dances"
	},
	{
		Title = "Weekend",
		AnimationId = "rbxassetid://111612787293988",
		Category = "Various Dances"
	},
	{
		Title = "HeyNow1",
		AnimationId = "rbxassetid://110232538284943",
		Category = "Various Dances"
	},
	{
		Title = "HeyNow2",
		AnimationId = "rbxassetid://114330665137830",
		Category = "Various Dances"
	},
	{
		Title = "Mufasa",
		AnimationId = "rbxassetid://71845096727816",
		Category = "Various Dances"
	},
	{
		Title = "Overdrive",
		AnimationId = "rbxassetid://86043724142914",
		Category = "Various Dances"
	},
	{
		Title = "Hicker",
		AnimationId = "rbxassetid://77378761193205",
		Category = "Various Dances"
	},
	{
		Title = "Navigator",
		AnimationId = "rbxassetid://138379324511278",
		Category = "Various Dances"
	},
	{
		Title = "SquatKick",
		AnimationId = "rbxassetid://106071888572473",
		Category = "Various Dances"
	},
	{
		Title = "KneeSlap",
		AnimationId = "rbxassetid://106071888572473",
		Category = "Various Dances"
	},
	{
		Title = "SwitchStep",
		AnimationId = "rbxassetid://91000786016468",
		Category = "Various Dances"
	},
	{
		Title = "Pump",
		AnimationId = "rbxassetid://91000786016468",
		Category = "Various Dances"
	},
	{
		Title = "WannaSeeMe",
		AnimationId = "rbxassetid://99855214874075",
		Category = "Various Dances"
	},
	{
		Title = "CrazyBoy",
		AnimationId = "rbxassetid://135347828030402",
		Category = "Various Dances"
	},
	{
		Title = "RealHeart",
		AnimationId = "rbxassetid://91493551626994",
		Category = "Various Dances"
	},
	{
		Title = "ShineShine",
		AnimationId = "rbxassetid://83032959969461",
		Category = "Various Dances"
	},
	{
		Title = "HotMarata",
		AnimationId = "rbxassetid://83032959969461",
		Category = "Various Dances"
	},
	{
		Title = "HotPatatas",
		AnimationId = "rbxassetid://101272251264447",
		Category = "Various Dances"
	},
	{
		Title = "NanaNana",
		AnimationId = "rbxassetid://73799149367189",
		Category = "Various Dances"
	},
	{
		Title = "SeySo?",
		AnimationId = "rbxassetid://89169351676548",
		Category = "Various Dances"
	},
	{
		Title = "ShowStop",
		AnimationId = "rbxassetid://132998740674158",
		Category = "Various Dances"
	},
	{
		Title = "BreakALeg",
		AnimationId = "rbxassetid://82622737477759",
		Category = "Various Dances"
	},
	{
		Title = "SuperStar",
		AnimationId = "rbxassetid://115781041991307",
		Category = "Various Dances"
	},
	{
		Title = "Tired",
		AnimationId = "rbxassetid://75735783204866",
		Category = "Various Dances"
	},
	{
		Title = "HockeyPockey",
		AnimationId = "rbxassetid://76337459187250",
		Category = "Various Dances"
	},
	{
		Title = "Sanity",
		AnimationId = "rbxassetid://109837322059170",
		Category = "Various Dances"
	},
	{
		Title = "Smug",
		AnimationId = "rbxassetid://98057174319646",
		Category = "Various Dances"
	},
	{
		Title = "CCStep",
		AnimationId = "rbxassetid://140652885141167",
		Category = "Various Dances"
	},
	{
		Title = "Charismatic",
		AnimationId = "rbxassetid://135937135482313",
		Category = "Various Dances"
	},
	{
		Title = "PullMeUp",
		AnimationId = "rbxassetid://92091428234648",
		Category = "Various Dances"
	},
	{
		Title = "SlikSlap",
		AnimationId = "rbxassetid://96431376344089",
		Category = "Various Dances"
	},
	{
		Title = "Valley",
		AnimationId = "rbxassetid://134210857187599",
		Category = "Various Dances"
	},
	{
		Title = "Funky",
		AnimationId = "rbxassetid://134640940281002",
		Category = "Various Dances"
	},
	{
		Title = "Lungs",
		AnimationId = "rbxassetid://71705274495596",
		Category = "Various Dances"
	},
	{
		Title = "OutWest",
		AnimationId = "rbxassetid://92390453415569",
		Category = "Various Dances"
	},
	{
		Title = "SoulCombo",
		AnimationId = "rbxassetid://99544342638099",
		Category = "Various Dances"
	},
	{
		Title = "FlameBurn",
		AnimationId = "rbxassetid://74277160221257",
		Category = "Various Dances"
	},
	{
		Title = "BodyWave",
		AnimationId = "rbxassetid://103480943314346",
		Category = "Various Dances"
	},
	{
		Title = "Hickers",
		AnimationId = "rbxassetid://132370762619855",
		Category = "Various Dances"
	},
	{
		Title = "Breakdown",
		AnimationId = "rbxassetid://90896748189853",
		Category = "Various Dances"
	},
	{
		Title = "Chicken",
		AnimationId = "rbxassetid://100027265859820",
		Category = "Various Dances"
	},
	{
		Title = "MonteCardo",
		AnimationId = "rbxassetid://109068282555244",
		Category = "Various Dances"
	},
	{
		Title = "Fishing",
		AnimationId = "rbxassetid://138575882526164",
		Category = "Various Dances"
	},
	{
		Title = "Snoop",
		AnimationId = "rbxassetid://80386140510546",
		Category = "Various Dances"
	},
	{
		Title = "Spring",
		AnimationId = "rbxassetid://127721740931355",
		Category = "Various Dances"
	},
	{
		Title = "Crab",
		AnimationId = "rbxassetid://136898318805164",
		Category = "Various Dances"
	},
	{
		Title = "ShimmyI",
		AnimationId = "rbxassetid://74831819777765",
		Category = "Various Dances"
	},
	{
		Title = "Smey",
		AnimationId = "rbxassetid://73336643981139",
		Category = "Various Dances"
	},
	{
		Title = "Laser",
		AnimationId = "rbxassetid://80227646253061",
		Category = "Various Dances"
	},
	{
		Title = "StartUp",
		AnimationId = "rbxassetid://113879988945830",
		Category = "Various Dances"
	},
	{
		Title = "BackStroke",
		AnimationId = "rbxassetid://91598570557335",
		Category = "Various Dances"
	},
	{
		Title = "Griddy",
		AnimationId = "rbxassetid://119912206767592",
		Category = "Various Dances"
	},
	{
		Title = "Glitters",
		AnimationId = "rbxassetid://130615066425750",
		Category = "Various Dances"
	},
	{
		Title = "Jamborey",
		AnimationId = "rbxassetid://128225104254860",
		Category = "Various Dances"
	},
	{
		Title = "StepBack",
		AnimationId = "rbxassetid://71753941982794",
		Category = "Various Dances"
	},
	{
		Title = "Cruisins",
		AnimationId = "rbxassetid://82897833289041",
		Category = "Various Dances"
	},
	{
		Title = "Security",
		AnimationId = "rbxassetid://118335967671362",
		Category = "Various Dances"
	},
	{
		Title = "Waving",
		AnimationId = "rbxassetid://129493071000960",
		Category = "Various Dances"
	},
	{
		Title = "HouseI",
		AnimationId = "rbxassetid://88278094402907",
		Category = "Various Dances"
	},
	{
		Title = "MoonWalk",
		AnimationId = "rbxassetid://94535490601613",
		Category = "Various Dances"
	},
	{
		Title = "Reckless",
		AnimationId = "rbxassetid://76056556611994",
		Category = "Various Dances"
	},
	{
		Title = "RaiseHand",
		AnimationId = "rbxassetid://76485919476622",
		Category = "Various Dances"
	},
	{
		Title = "BreakDown2",
		AnimationId = "rbxassetid://135762233944948",
		Category = "Various Dances"
	},
	{
		Title = "CrazyFeet",
		AnimationId = "rbxassetid://84008345729485",
		Category = "Various Dances"
	},
	{
		Title = "Begging",
		AnimationId = "rbxassetid://72782050092407",
		Category = "Various Dances"
	},
	{
		Title = "ElectroShuffle",
		AnimationId = "rbxassetid://140153586636730",
		Category = "Various Dances"
	},
	{
		Title = "SpongeBob",
		AnimationId = "rbxassetid://95671818316206",
		Category = "Various Dances"
	},
	{
		Title = "ElectroSwing",
		AnimationId = "rbxassetid://102960987236936",
		Category = "Various Dances"
	},
	{
		Title = "HellRock",
		AnimationId = "rbxassetid://129697789476298",
		Category = "Various Dances"
	},
	{
		Title = "JungJustice",
		AnimationId = "rbxassetid://138624038187889",
		Category = "Various Dances"
	},
	{
		Title = "DownBreaker",
		AnimationId = "rbxassetid://137175647064668",
		Category = "Various Dances"
	},
	{
		Title = "FancyFeet",
		AnimationId = "rbxassetid://137175647064668",
		Category = "Various Dances"
	},
	{
		Title = "FreeStyling",
		AnimationId = "rbxassetid://98909835328386",
		Category = "Various Dances"
	},
	{
		Title = "HotLineBling",
		AnimationId = "rbxassetid://98909835328386",
		Category = "Various Dances"
	},
	{
		Title = "PopLock",
		AnimationId = "rbxassetid://93740199304727",
		Category = "Various Dances"
	},
	{
		Title = "SlickDance",
		AnimationId = "rbxassetid://130180978909622",
		Category = "Various Dances"
	},
	{
		Title = "SmoothMove",
		AnimationId = "rbxassetid://94374480738492",
		Category = "Various Dances"
	},
	{
		Title = "Robot",
		AnimationId = "rbxassetid://125213889845794",
		Category = "Various Dances"
	},
	{
		Title = "Twist",
		AnimationId = "rbxassetid://79211232481520",
		Category = "Various Dances"
	},
	{
		Title = "Calamity",
		AnimationId = "rbxassetid://79211232481520",
		Category = "Various Dances"
	},
	{
		Title = "FreeFlow",
		AnimationId = "rbxassetid://96783372539558",
		Category = "Various Dances"
	},
	{
		Title = "BilliBounce",
		AnimationId = "rbxassetid://131083888048619",
		Category = "Various Dances"
	},
	{
		Title = "Macarena",
		AnimationId = "rbxassetid://106438018803062",
		Category = "Various Dances"
	},
	{
		Title = "Boggie",
		AnimationId = "rbxassetid://93650923841104",
		Category = "Various Dances"
	},
	{
		Title = "Thriller",
		AnimationId = "rbxassetid://112376867582866",
		Category = "Various Dances"
	},
	{
		Title = "DanceDance",
		AnimationId = "rbxassetid://81721080856336",
		Category = "Various Dances"
	},
	{
		Title = "YeahMan",
		AnimationId = "rbxassetid://99479338187803",
		Category = "Various Dances"
	},
	{
		Title = "Alright",
		AnimationId = "rbxassetid://130949605027903",
		Category = "Various Dances"
	},
	{
		Title = "Backyoh",
		AnimationId = "rbxassetid://137529043864623",
		Category = "Various Dances"
	},
	{
		Title = "IkotIkot",
		AnimationId = "rbxassetid://92979124172697",
		Category = "Various Dances"
	},
	{
		Title = "Cutie",
		AnimationId = "rbxassetid://128374205393334",
		Category = "Various Dances"
	},
	{
		Title = "Rolex",
		AnimationId = "rbxassetid://89064052023874",
		Category = "Various Dances"
	},
	{
		Title = "SlowDown",
		AnimationId = "rbxassetid://135463087467287",
		Category = "Various Dances"
	},
	{
		Title = "Snap",
		AnimationId = "rbxassetid://73964498262131",
		Category = "Various Dances"
	},
	{
		Title = "Cheer",
		AnimationId = "rbxassetid://97861619601504",
		Category = "Various Dances"
	},
	{
		Title = "Flaw",
		AnimationId = "rbxassetid://138062938632538",
		Category = "Various Dances"
	},
	{
		Title = "HulaHappy",
		AnimationId = "rbxassetid://111113690374567",
		Category = "Various Dances"
	},
	{
		Title = "Breaky",
		AnimationId = "rbxassetid://125768100936670",
		Category = "Various Dances"
	},
	{
		Title = "FrontBack",
		AnimationId = "rbxassetid://134038897824643",
		Category = "Various Dances"
	},
	{
		Title = "Shaggy",
		AnimationId = "rbxassetid://90131955239121",
		Category = "Various Dances"
	},
	{
		Title = "Comeon",
		AnimationId = "rbxassetid://126414407862767",
		Category = "Various Dances"
	},
	{
		Title = "Disco",
		AnimationId = "rbxassetid://126414407862767",
		Category = "Various Dances"
	},
	{
		Title = "Dorkey",
		AnimationId = "rbxassetid://83672739355459",
		Category = "Various Dances"
	},
	{
		Title = "RiverDance",
		AnimationId = "rbxassetid://115100075990616",
		Category = "Various Dances"
	},
	{
		Title = "LineDance",
		AnimationId = "rbxassetid://105117937146039",
		Category = "Various Dances"
	},


	-- Kategori: Pose / Emote (Semua yang memiliki Category = "Emote" di config asli)
	{
		Title = "Salute",
		AnimationId = "rbxassetid://92109492488561",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance1",
		AnimationId = "rbxassetid://86241476099446",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance2",
		AnimationId = "rbxassetid://131789866699144",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance3",
		AnimationId = "rbxassetid://99541980916506",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance4",
		AnimationId = "rbxassetid://105042771831542",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance5",
		AnimationId = "rbxassetid://109853326508333",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance6",
		AnimationId = "rbxassetid://87051982320464",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance7",
		AnimationId = "rbxassetid://131312553069528",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance8",
		AnimationId = "rbxassetid://120799477577648",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance9",
		AnimationId = "rbxassetid://123564526157711",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance10",
		AnimationId = "rbxassetid://138544517858269",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance11",
		AnimationId = "rbxassetid://139168114364804",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance12",
		AnimationId = "rbxassetid://129469087154950",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance13",
		AnimationId = "rbxassetid://112837473682935",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance14",
		AnimationId = "rbxassetid://131721155631248",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance15",
		AnimationId = "rbxassetid://114200536212898",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance16",
		AnimationId = "rbxassetid://125039393466389",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance17",
		AnimationId = "rbxassetid://101815021536565",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance18",
		AnimationId = "rbxassetid://114719233296235",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance19",
		AnimationId = "rbxassetid://122790657038063",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance20",
		AnimationId = "rbxassetid://82582508966282",
		Category = "Pose / Emote"
	},
	{
		Title = "Stance21",
		AnimationId = "rbxassetid://133494939748641",
		Category = "Pose / Emote"
	},
	{
		Title = "Woah",
		AnimationId = "rbxassetid://93674146362362",
		Category = "Pose / Emote"
	},
	{
		Title = "SpiderMan",
		AnimationId = "rbxassetid://118946607138761",
		Category = "Pose / Emote"
	},
	{
		Title = "Naruto",
		AnimationId = "rbxassetid://132219082931060",
		Category = "Pose / Emote"
	},
	{
		Title = "PushUp",
		AnimationId = "rbxassetid://92226869178365",
		Category = "Pose / Emote"
	},
	{
		Title = "UpoSahig",
		AnimationId = "rbxassetid://73038655762110",
		Category = "Pose / Emote"
	},
	{
		Title = "SitBy",
		AnimationId = "rbxassetid://81560204884465",
		Category = "Pose / Emote"
	},
	{
		Title = "LookBack",
		AnimationId = "rbxassetid://80918740279994",
		Category = "Pose / Emote"
	},
	{
		Title = "Split",
		AnimationId = "rbxassetid://84608435344575",
		Category = "Pose / Emote"
	},
	{
		Title = "StandPose",
		AnimationId = "rbxassetid://88719352335239",
		Category = "Pose / Emote"
	},
	{
		Title = "StandPose2",
		AnimationId = "rbxassetid://80757162889754",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo1",
		AnimationId = "rbxassetid://136918655964544",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo2",
		AnimationId = "rbxassetid://124248445390051",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo3",
		AnimationId = "rbxassetid://87223886493951",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo4",
		AnimationId = "rbxassetid://87938673395326",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo5",
		AnimationId = "rbxassetid://100942791732267",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo6",
		AnimationId = "rbxassetid://135217936485127",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo7",
		AnimationId = "rbxassetid://89579810041769",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo8",
		AnimationId = "rbxassetid://109767726223877",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo9",
		AnimationId = "rbxassetid://125395748947303",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo10",
		AnimationId = "rbxassetid://96737322530123",
		Category = "Pose / Emote"
	},
	{
		Title = "Upo11",
		AnimationId = "rbxassetid://75396715294579",
		Category = "Pose / Emote"
	},
	{
		Title = "Higa",
		AnimationId = "rbxassetid://123642523837192",
		Category = "Pose / Emote"
	},
	{
		Title = "Higa2",
		AnimationId = "rbxassetid://100729452459776",
		Category = "Pose / Emote"
	},
	{
		Title = "WarmUp",
		AnimationId = "rbxassetid://136093869440276",
		Category = "Pose / Emote"
	},
	{
		Title = "Ground",
		AnimationId = "rbxassetid://121834920569094",
		Category = "Pose / Emote"
	},
	{
		Title = "Boxing",
		AnimationId = "rbxassetid://121834920569094",
		Category = "Pose / Emote"
	},
	{
		Title = "BangBaril",
		AnimationId = "rbxassetid://115897266907155",
		Category = "Pose / Emote"
	},
	{
		Title = "CatWheel",
		AnimationId = "rbxassetid://137766564991489",
		Category = "Pose / Emote"
	},
	{
		Title = "Dying",
		AnimationId = "rbxassetid://106705870496471",
		Category = "Pose / Emote"
	},
	{
		Title = "MannyPacman",
		AnimationId = "rbxassetid://112079672189860",
		Category = "Pose / Emote"
	},
	{
		Title = "Kick1",
		AnimationId = "rbxassetid://82234569024925",
		Category = "Pose / Emote"
	},
	{
		Title = "Kick2",
		AnimationId = "rbxassetid://135424717422077",
		Category = "Pose / Emote"
	},
	{
		Title = "PlayingGuitar",
		AnimationId = "rbxassetid://97660703431648",
		Category = "Pose / Emote"
	},
	{
		Title = "Listening2Music",
		AnimationId = "rbxassetid://75868130786648",
		Category = "Pose / Emote"
	},
	{
		Title = "Fly",
		AnimationId = "rbxassetid://74073564053687",
		Category = "Pose / Emote"
	},
	{
		Title = "Ninja",
		AnimationId = "rbxassetid://106271491146817",
		Category = "Pose / Emote"
	},
	{
		Title = "T-Pose",
		AnimationId = "rbxassetid://126924836092320",
		Category = "Pose / Emote"
	},
	{
		Title = "SayawPose",
		AnimationId = "rbxassetid://140685446955844",
		Category = "Pose / Emote"
	},
	{
		Title = "WillYou",
		AnimationId = "rbxassetid://78500970392634",
		Category = "Pose / Emote"
	},
	{
		Title = "SideHand",
		AnimationId = "rbxassetid://100568939786930",
		Category = "Pose / Emote"
	},
	{
		Title = "Tumbling",
		AnimationId = "rbxassetid://126048030877981",
		Category = "Pose / Emote"
	},
	{
		Title = "HeadBang",
		AnimationId = "rbxassetid://138713672409739",
		Category = "Pose / Emote"
	},
	{
		Title = "Dab",
		AnimationId = "rbxassetid://115019436780056",
		Category = "Pose / Emote"
	},
	{
		Title = "Bored",
		AnimationId = "rbxassetid://138776732068537",
		Category = "Pose / Emote"
	},
	{
		Title = "Tumbling2",
		AnimationId = "rbxassetid://107725098325899",
		Category = "Pose / Emote"
	},
	{
		Title = "JumpingJack",
		AnimationId = "rbxassetid://99652774086772",
		Category = "Pose / Emote"
	},
	{
		Title = "Fasionista",
		AnimationId = "rbxassetid://95520798624730",
		Category = "Pose / Emote"
	},
	{
		Title = "UpperCut",
		AnimationId = "rbxassetid://118995766934692",
		Category = "Pose / Emote"
	},
	{
		Title = "Bye",
		AnimationId = "rbxassetid://135614795935215",
		Category = "Pose / Emote"
	},
	{
		Title = "Tawa",
		AnimationId = "rbxassetid://98563165841606",
		Category = "Pose / Emote"
	},
	{
		Title = "Cower",
		AnimationId = "rbxassetid://98563165841606",
		Category = "Pose / Emote"
	},
	{
		Title = "Cutesy",
		AnimationId = "rbxassetid://82774261581058",
		Category = "Pose / Emote"
	},
	{
		Title = "Dizzy",
		AnimationId = "rbxassetid://120168562207508",
		Category = "Pose / Emote"
	},
	{
		Title = "Baliw",
		AnimationId = "rbxassetid://112412950107558",
		Category = "Pose / Emote"
	},
	{
		Title = "Happy",
		AnimationId = "rbxassetid://109543665757417",
		Category = "Pose / Emote"
	},
	{
		Title = "Godlike",
		AnimationId = "rbxassetid://118451136111695",
		Category = "Pose / Emote"
	},
	{
		Title = "SupperHappy",
		AnimationId = "rbxassetid://84496017888126",
		Category = "Pose / Emote"
	},
	{
		Title = "Moneky",
		AnimationId = "rbxassetid://132229937280992",
		Category = "Pose / Emote"
	},
	{
		Title = "Gunshow",
		AnimationId = "rbxassetid://124664688120922",
		Category = "Pose / Emote"
	},
	{
		Title = "TopRock",
		AnimationId = "rbxassetid://115201461802170",
		Category = "Pose / Emote"
	},
	{
		Title = "HiyaMode",
		AnimationId = "rbxassetid://134075232904252",
		Category = "Pose / Emote"
	},
	{
		Title = "Shuffle2",
		AnimationId = "rbxassetid://127597936680374",
		Category = "Pose / Emote"
	},
	{
		Title = "AntokNa",
		AnimationId = "rbxassetid://138536172396937",
		Category = "Pose / Emote"
	},
	{
		Title = "Twirl",
		AnimationId = "rbxassetid://78858587270060",
		Category = "Pose / Emote"
	},
}

return DanceConfig