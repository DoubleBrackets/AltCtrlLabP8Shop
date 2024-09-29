# run from inside the repo directory

PWD=$(pwd)
PICO_8_PATH=$1
# home dir is where the pico 8 config files are generated
HOME_DIR=$PWD/pico8-home
STARTUP_CART=$HOME_DIR/carts/lab-console.p8

echo "Running Pico-8 from: $PICO_8_PATH"
echo "Using startup cart: $STARTUP_CART"
echo "Using home dir: $HOME_DIR"

mkdir -p $HOME_DIR

$PICO_8_PATH -home $HOME_DIR -run $STARTUP_CART

# /Users/arthu/Programs/Creation/PICO-8/pico8.exe -home C:/Users/arthu/AppData/Roaming/pico-8/carts/AltP8/pico8-home -run lab-console