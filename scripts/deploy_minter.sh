#!/bin/bash
source ../.env

# Check if --debug parameter is passed
debug="false"
for arg in "$@"
do
    if [ "$arg" == "--debug" ]
    then
        debug="true"
    fi
done

SIERRA_FILE=../target/dev/carbon_v3_Minter.contract_class.json
PROJECT=0x065eea2bb966b75346475d2cc3f0a2e80754d37fdd76f9c26521640b8b5da2ac
OWNER=0x0251424ba0253188ce042669f50fcba2f1737222650050ba5af4d296b65b8996
ERC20=0x04b398bfce9eaa2d1328ec4367acc11e03451f7fc36a136c71ed695cc4333752    # USDCARB
PUBLIC_SALE_OPEN=1
MAX_VALUE=8000000000
UNIT_PRICE=11

# build the solution
build() {
    output=$(scarb build 2>&1)

    if [[ $output == *"Error"* ]]; then
        echo "Error: $output"
        exit 1
    fi
}

# declare the contract
declare() {
    build
    if [[ $debug == "true" ]]; then
        printf "declare %s --keystore-password KEYSTORE_PASSWORD --watch\n" "$SIERRA_FILE" > debug_minter.log
    fi
    output=$(starkli declare $SIERRA_FILE --keystore-password $KEYSTORE_PASSWORD --watch 2>&1)

    if [[ $output == *"Error"* ]]; then
        echo "Error: $output"
        exit 1
    fi

    address=$(echo "$output" | grep -oP '0x[0-9a-fA-F]+')
    echo $address
}

# deploy the contract
# $1 - Project_address
# $2 - Payment_token_address
# $3 - sale_open
# $4 - max_value
# $5 - unit_price
# $6 - owner

deploy() {
    class_hash=$(declare | tail -n 1)
    sleep 15
    
    if [[ $debug == "true" ]]; then        
        printf "deploy %s %s %s %s u256:%s u256:%s %s --keystore-password KEYSTORE_PASSWORD --watch\n" "$class_hash" "$PROJECT"  "$ERC20" "$PUBLIC_SALE_OPEN" "$MAX_VALUE" "$UNIT_PRICE" "$OWNER" >> debug_minter.log
    fi
    output=$(starkli deploy $class_hash "$PROJECT" "$ERC20" "$PUBLIC_SALE_OPEN" u256:"$MAX_VALUE" u256:"$UNIT_PRICE" "$OWNER" --keystore-password $KEYSTORE_PASSWORD --watch 2>&1)

    if [[ $output == *"Error"* ]]; then
        echo "Error: $output"
        exit 1
    fi

    address=$(echo "$output" | grep -oP '0x[0-9a-fA-F]+' | tail -n 1) 
    echo $address
}

contract_address=$(deploy)
echo $contract_address