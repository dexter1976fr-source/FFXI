#!/usr/bin/env python3
"""
Script pour vérifier la configuration réseau et afficher les informations de connexion
"""

import socket
import subprocess
import sys

def get_local_ip():
    """Récupère l'IP locale du PC"""
    try:
        # Créer une socket UDP (pas besoin de vraiment se connecter)
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "Unable to determine"

def check_port_open(port=5000):
    """Vérifie si le port est ouvert"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(1)
        result = s.connect_ex(('127.0.0.1', port))
        s.close()
        return result == 0
    except Exception:
        return False

def get_hostname():
    """Récupère le nom de l'ordinateur"""
    return socket.gethostname()

def check_firewall_rule():
    """Vérifie si une règle de pare-feu existe pour le port 5000"""
    try:
        result = subprocess.run(
            ['netsh', 'advfirewall', 'firewall', 'show', 'rule', 'name=all'],
            capture_output=True,
            text=True,
            timeout=5
        )
        return '5000' in result.stdout
    except Exception:
        return None

def main():
    print("="*60)
    print("🌐 VÉRIFICATION DE LA CONFIGURATION RÉSEAU")
    print("="*60)
    
    # Informations de base
    hostname = get_hostname()
    local_ip = get_local_ip()
    
    print(f"\n📋 Informations système:")
    print(f"  Nom de l'ordinateur: {hostname}")
    print(f"  IP locale: {local_ip}")
    
    # Vérification du port
    port_open = check_port_open(5000)
    print(f"\n🔌 Port 5000:")
    if port_open:
        print(f"  ✅ Le port 5000 est OUVERT (serveur en cours d'exécution)")
    else:
        print(f"  ❌ Le port 5000 est FERMÉ (serveur non démarré)")
        print(f"  💡 Lancez FFXI_ALT_Control.py et activez les serveurs")
    
    # Vérification du pare-feu
    print(f"\n🛡️  Pare-feu Windows:")
    fw_check = check_firewall_rule()
    if fw_check is None:
        print(f"  ⚠️  Impossible de vérifier (nécessite des droits admin)")
    elif fw_check:
        print(f"  ✅ Une règle pour le port 5000 semble exister")
    else:
        print(f"  ⚠️  Aucune règle trouvée pour le port 5000")
        print(f"  💡 Créez une règle avec cette commande (PowerShell admin):")
        print(f"     New-NetFirewallRule -DisplayName \"FFXI ALT Control\" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow")
    
    # URLs d'accès
    print(f"\n🌍 URLs d'accès:")
    print(f"  Sur ce PC:")
    print(f"    http://localhost:5000")
    print(f"    http://127.0.0.1:5000")
    print(f"\n  Depuis la tablette/mobile (même réseau WiFi):")
    print(f"    http://{local_ip}:5000")
    
    # Instructions
    print(f"\n📱 Pour accéder depuis votre tablette:")
    print(f"  1. Assurez-vous que la tablette est sur le même réseau WiFi")
    print(f"  2. Ouvrez le navigateur de la tablette")
    print(f"  3. Allez sur: http://{local_ip}:5000")
    
    # Test de connectivité
    print(f"\n🧪 Test de connectivité:")
    print(f"  Depuis la tablette, vous pouvez tester avec:")
    print(f"    ping {local_ip}")
    
    print("\n" + "="*60)
    
    # Résumé
    if port_open:
        print("✅ Configuration OK - Le serveur est accessible")
    else:
        print("⚠️  Le serveur n'est pas démarré")
        print("   Lancez FFXI_ALT_Control.py et activez les serveurs")
    
    print("="*60)

if __name__ == "__main__":
    main()
