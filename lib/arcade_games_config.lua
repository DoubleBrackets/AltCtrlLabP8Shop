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

arcade_games_list = {
    listing(
        "insatiable.p8",
        "insatiable",
        "camden pettijohn & grant gelardi",
        "dark lord allowen the vampire \nhas awoken from a deep slumber \nin an era void of humans. \nNo longer will he have to fear\nthe stakes of commoners but a \nthreat is still posed against \nhis life: the instability of \nhis own appetite."
    ),
    listing(
        "flower.p8",
        "flower",
        "camden pettijohn",
        "prototype"
    ),
    listing(
        "moral_ai.p8",
        "moral ai",
        "camden pettijohn",
        "prototype"
    ),
    listing(
        "dynam8.p8",
        "dynam8",
        "camden pettijohn",
        "prototype"
    )
}