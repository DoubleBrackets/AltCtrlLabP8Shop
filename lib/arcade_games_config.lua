arcade_games_path = "arcade_games/"

function listing(path, name, credits, desc)
    return {
        path = path,
        name = name,
        credits = credits,
        desc = desc
    }
end

function load_arcade_game(game_index)
    game = arcade_games_list[game_index]
    load(arcade_games_path .. game.path, "exit arcade")
end

-- add new arcade games here
arcade_games_list = {
    listing(
        "insatiable.p8",
        "insatiable",
        "camden pettijohn, grant gelardi",
        "dark lord allowen the vampire has awoken from a deep slumber in an era void of humans. no longer will he have to fear the stakes of commoners but a threat is still posed against his life: the instability of his own appetite."
    ),
    listing(
        "flower.p8",
        "flower",
        "camden pettijohn",
        "prototype"
    ),
    listing(
        "dynam8.p8",
        "dynam8",
        "camden pettijohn",
        "prototype"
    ),
    listing(
        "ferrous_fight.p8",
        "ferrous fight",
        "jasper, jeren, jimmy, kaoushik",
        "a fully featured tower defense game with a unique mechanic: all 6 towers can be directly controlled with special behavior. play as the rogue ai 'blitz' as they awaken from a facility, travelling the land to defeat the milit empire."
    ),
    listing(
        "ninja_run.p8",
        "ninja run",
        "alexa, aria, arthur, jimmy, jordan, tyler, diana",
        "oh no! your house has been overrun with ninjas, and it's up to you to protect it!"
    ),
    listing(
        "catfishing.p8",
        "catfishing",
        "jeren, kaoushik, michael, nicholas, alex, katie",
        "go fishing! sell your catch, upgrade your fishing pole, and complete the encyclopedia!"
    ),
    listing(
        "dragonlair.p8",
        "dragon lair",
        "aron m, brandon h, katlyn c, monse a",
        "classic top-down rpg where the player finds hidden keys to escape the dragons lair!"
    ),
    listing(
        "deepcitydetective.p8",
        "deep city detective",
        "nathan, aron, makai, katlyn, brandon, yiyu, ziyu, bohua, julia",
        "a point-and-click adventure that follows detective scott easton who is dispatched to investigate a murder in the market district. however, not everything about the crime is what is it seems..."
    ),
}