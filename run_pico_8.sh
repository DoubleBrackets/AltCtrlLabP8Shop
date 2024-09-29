PICO_8_PATH=$1
STARTUP_CART=carts/lab-console.p8
CART_DIR=carts
# home dir is where the pico 8 config files are generated
HOME_DIR=pico-8

echo "Running Pico-8 from: $PICO_8_PATH"
echo "Using startup cart: $STARTUP_CART"
echo "Using cart directory: $CART_DIR"

mkdir -p $CART_DIR
mkdir -p $HOME_DIR

./$PICO_8_PATH -home $HOME_DIR -root_path $CART_DIR -run $STARTUP_CART