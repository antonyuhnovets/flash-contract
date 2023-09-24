run:
	build/app/webapi

clear:
	sudo rm -rf $(path) || true

# Build 
# l=true for attached logs, r=true for rebuild
build-init:
	make build-restart r=$(r) l=$(l)

build-run:
	$(l) \ && docker compose up || docker compose up -d 

build-restart:
	make build-stop r=$(r)
	$(r) \ && make rebuild l=$(l) || make build-run l=$(l)

build-stop:
	docker compose down || true
	$(r) \ && make db-clear || echo "rebuild disabled"

rebuild:
	docker compose build
	make build-run l=$(l)

# App
app-start:
	docker start flash-webapi
	docker exec flash-webapi make run

app-stop:
	docker stop flash-webapi

app-build:
	docker exec flash-webapi make go-build

app-logs:
	docker logs flash-webapi

app-restart:
	make app-stop
	make app-start

app-reload:
	make app-build
	make app-restart

app-rm:
	docker rm flash-webapi || true

# Database
db-logs:
	docker logs flash-pg

db-clear:
	make clear path=pg_data
	make clear path=pg_data_test

db-rm: 
	docker rm flash-webapi || true

# Go
go-build:
	swag init -g internal/delivery/http/v2/router.go
	go build -a -o ./build/app/webapi ./cmd/daemon/main.go
	chmod +x ./build/app/webapi
	
# Contract
contract-build: 
	solc --bin --abi --include-path node_modules/ --base-path . ./contracts/$(contract).sol -o $(where)
	abigen --abi=./$(where)/$(contract).abi --bin=./$(where)/$(contract).bin --pkg=api --out=./$(to)/$(contract).go

contract-deploy:
	npx hardhat run --network $(network) scripts/deploy.js

contract-verify:
	npx hardhat verify $(address) $(input) --contract 'contracts/$(contract).sol:$(contract)' --network $(network)

# Install required pkg/dep
install-dependencies:
	go mod download
	npm install

install-node:
	sudo apt install -U nodejs
	sudo apt install -U npm

install-solc:
	sudo apt install -y libboost-all-dev cmake
	git clone --recursive --branch v0.8.17 https://github.com/ethereum/solidity.git ~/github.com/ethereum/solidity \
	&& sudo . ~/github.com/ethereum/solidity/scripts/build.sh

install-geth:
	git clone https://github.com/ethereum/go-ethereum.git ~/github.com/ethereum/go-ethereum
	cd ~/github.com/ethereum/go-ethereum/ && make devtools

install-protoc:
	sudo apt install -U unzip curl
	PROTOC_ZIP=protoc-3.14.0-linux-x86_64.zip
	curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.14.0/$PROTOC_ZIP
	sudo unzip -o $PROTOC_ZIP -d /usr/local bin/protoc
	sudo unzip -o $PROTOC_ZIP -d /usr/local 'include/*'
	rm -f $PROTOC_ZIP
