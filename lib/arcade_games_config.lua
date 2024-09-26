arcade_games_path = "arcade_games/"

function listing(path, name, desc, credits)
    return {
        path = path,
        name = name,
        desc = desc,
        credits = credits
    }
end

function load_arcade_game(game_index)
    game = arcade_games_list[game_index]
    load(arcade_games_path .. game.path .. ".p8", "exit arcade")
end

arcade_games_list = {
    listing(
        "test_game_1",
        "test game 1",
        "the best game of all time",
        "johnny boy"
    ),
    listing(
        "test_game_2",
        "test game 2",
        "the second best game of all time",
        "no-man"
    )
}