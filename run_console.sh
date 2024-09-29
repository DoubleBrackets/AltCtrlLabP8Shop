# run from inside the repo directory


PWD=$(pwd)
PICO_8_PATH=$1
# home dir is where the pico 8 config files are generated
HOME_DIR=$PWD/pico8-home
STARTUP_CART=$HOME_DIR/carts/lab-console.p8
BACKEND_SCREEN_NAME=p8_console_backend
BACKEND_SCRIPT_PATH=$PWD/backend.py

echo "Running Pico-8 from: $PICO_8_PATH"
echo "Using startup cart: $STARTUP_CART"
echo "Using home dir: $HOME_DIR"

mkdir -p $HOME_DIR

# kill backend screen if one is running
screen -X -S $BACKEND_SCREEN_NAME quit

# start backend screen
screen -dmS $BACKEND_SCREEN_NAME python $BACKEND_SCRIPT_PATH

echo "p8 console backend started on screen: $BACKEND_SCREEN_NAME"

$PICO_8_PATH -home $HOME_DIR -run $STARTUP_CART