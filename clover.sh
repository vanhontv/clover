#!/bin/bash
sudo apt curl -y < "/dev/null"
curl https://api.nodes.guru/logo.sh | bash
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
fi
echo 'Your node name: ' $NODENAME
echo 'export NODENAME='$NODENAME >> $HOME/.bashrc
source $HOME/.bashrc
cd $HOME
sudo apt update
sudo apt install make clang pkg-config libssl-dev build-essential git curl ntp jq -y < "/dev/null"
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
rustup install nightly-2020-10-06
rustup target add wasm32-unknown-unknown --toolchain nightly-2020-10-06
git clone https://github.com/clover-network/clover.git
cd $HOME/clover
chmod +x $HOME/clover/scripts/init.sh
$HOME/clover/scripts/init.sh
sed -i "s/ChainId: u64 = CHAIN_ID/ChainId: u64 = 1337/g" $HOME/clover/runtime/src/lib.rs
cargo +nightly-2020-10-06 build --release
echo "[Unit]
Description=Clover Node
After=network-online.target
[Service]
User=$USER
WorkingDirectory=$HOME/clover
ExecStart=$HOME/clover/target/release/clover --chain $HOME/clover/specs/clover-cc1-raw.json --ws-external --rpc-cors all --name "$NODENAME" --port 30333 --ws-port 9944 --rpc-port 9933 --rpc-methods=Unsafe --validator --unsafe-ws-external --unsafe-rpc-external
Restart=always
RestartSec=3
LimitNOFILE=4096
[Install]
WantedBy=multi-user.target
" > $HOME/cloverd.service
sudo mv $HOME/cloverd.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable cloverd
sudo systemctl start cloverd
sudo systemctl status cloverd
