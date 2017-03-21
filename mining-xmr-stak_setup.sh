#!/bin/bash
tput setaf 7 ; tput setab 6 ; tput bold ; printf '%35s%s%-20s\n' "Configuracao Inicial do VPS Mining" ; tput sgr0
tput setaf 3 ; tput bold ; echo "" ; echo "Este script ira compilar o xmr-stak-cpu, fazer configuracoes no sysctl.conf e" ; tput sgr0
tput setaf 3 ; tput bold ; echo "/etc/security/limits.conf e instalar alguns pacotes uteis." ; echo "" ; tput sgr0
tput setaf 3 ; tput bold ; read -n 1 -s -p "Aperte qualquer tecla para iniciar..." ; echo "" ; echo "" ; tput sgr0

#XMR-Stak-CPU compiling
sudo apt-get update && sudo apt-get install build-essential cmake libmicrohttpd-dev openssl libssl-dev nano git htop screen -y
git clone git://github.com/fireice-uk/xmr-stak-cpu.git &&
cd xmr-stak-cpu
sed -i 's/constexpr double fDevDonationLevel.*/constexpr double fDevDonationLevel = 0.0;/' donate-level.h
cmake .
make -j $(nproc)
cp bin/xmr-stak-cpu ~/xmr-stak
cp config.txt ~/config.txt
rm -rf xmr-stak-cpu/
if [ $? != 0 ]; then
	echo "Erro exit code: $?" >&2
	exit 1
else
	echo ""; echo "XMR-Stak-CPU Compilado!"
fi
sleep 2
echo "" ; echo "Agora as configuracoes finais."
sleep 2

#Sysctl Conf
if [ ! -f "/etc/sysctl.d/99-xmrmining.conf" ]; then

echo "
# Protect Against TCP Time-Wait
net.ipv4.tcp_rfc1337 = 1

#Latency
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_slow_start_after_idle = 0

#Hugepages
vm.nr_hugepages = 128

# Do less swapping
vm.swappiness = 10
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.vfs_cache_pressure = 50" | sudo tee /etc/sysctl.d/99-xmrmining.conf
if [ $? != 0 ]; then
	echo " Erro exit code: $?" >&2
	exit 1
fi
read -p "Deseja desabilitar o IPV6? (S ou N) " resposta
if [ "$resposta" == "s" ]; then
echo " " | sudo tee -a /etc/sysctl.d/99-xmrmining.conf
echo "# Disable on all interfaces
net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.d/99-xmrmining.conf
fi
sudo sysctl -p /etc/sysctl.d/99-xmrmining.conf
fi

#Limits.conf
if ! grep -q "#Limits" /etc/security/limits.conf; then
	echo " " | sudo tee -a /etc/security/limits.conf
	echo "#Limits para mining" | tee -a /etc/security/limits.conf
echo "* soft memlock 262144" | sudo tee -a /etc/security/limits.conf
	echo "* hard memlock 262144" | sudo tee -a /etc/security/limits.conf
	echo "" ; echo ""
fi

if [ $?  -eq 0 ]; then
	echo "Finalizado!" ; echo " "
	echo "Agora voce precisa ajustar as configuracoes do config.txt do xmr-stak."
	echo "Antes, reinicie a VPS para que as configurações facam efeito!"
	read -p "Deseja reinciar agora? (S ou N) " resposta
	if [ "$resposta" == "s" ]; then
		sudo reboot 
	fi
	echo ""; echo "Ate mais!"
else
	echo " Erro exit code: $?" >&2
	exit 1
fi