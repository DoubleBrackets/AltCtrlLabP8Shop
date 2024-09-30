# Alt-Ctrl Lab Pico-8 Console
A Pico-8 Console/Arcade for the Alt-Ctrl Lab at UC Davis

### Running
Configure Pico-8 to use `pico8-home` as the home directory, either through config file or the CLI argument. Run `lab-console.p8` as the starting cart.

See [https://www.lexaloffle.com/dl/docs/pico-8_manual.html#Commandline_parameters](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#_Configuration)

### Adding Games
- Add the cart(s) to the `pico8-home/carts/arcade_games`. Must be `.p8` files.
- Add an entry to `/lib/arcade_games_config.lua`
