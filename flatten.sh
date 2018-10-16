#!/user/bin/env bash

rm -rf flats/*

./node_modules/.bin/truffle-flattener contracts/Hena.sol > flats/Hena_flat.sol