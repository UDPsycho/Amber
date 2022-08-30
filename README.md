# Amber LF

**Amber LF** is a basic local firewall implementation via iptables to try to protect the host machine by allowing only the specific bidirectional traffic configured by the user.

## Requirements

* A linux-based distribution
* iptables installed
* root privileges

## Installation

```bash
git clone https://www.github.com/UDPsycho/Amber.git
cd Amber
sudo chmod +x ./amber.sh
```

## Usage

```bash
sudo ./amber.sh [OPTIONS]
```

Type ```-h, --help``` to see all available options.

## FAQ

### **Why only bidirectional traffic is supported?**

Because to build another specific configuration I think is much better to use iptables directly instead of this script.

### **What's the purpose of this tool?**

Beyond the actual implementation of a local firewall, the main purpose of this tool was for me LEARNING, I hope for you too.

### **Why this script born?**

Because I was learning about firewalls and their implementation through iptables, so I decided to put into practice what I was learning while also practice bash scripting.

## License

Copyright (c) 2022 Psycho. None right reserved.  
[Amber LF](https://github.com/UDPsycho/Amber) is licensed under the MIT License.
