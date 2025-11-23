#!/usr/bin/env python3
"""
Script de test pour vérifier que le système Auto Engage fonctionne correctement
"""

import requests
import json
import time

# Configuration
BACKEND_URL = "http://localhost:5000"

def test_connection():
    """Test la connexion au serveur"""
    print("🔌 Test de connexion au serveur...")
    try:
        response = requests.get(f"{BACKEND_URL}/all-alts", timeout=5)
        if response.status_code == 200:
            print("✅ Serveur accessible")
            return True
        else:
            print(f"❌ Erreur HTTP {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Impossible de se connecter: {e}")
        return False

def get_all_alts():
    """Récupère la liste de tous les ALTs"""
    print("\n📋 Récupération de la liste des ALTs...")
    try:
        response = requests.get(f"{BACKEND_URL}/all-alts", timeout=5)
        if response.status_code == 200:
            data = response.json()
            alts = data.get("alts", [])
            print(f"✅ {len(alts)} ALT(s) trouvé(s)")
            for alt in alts:
                print(f"   - {alt['name']} ({alt['main_job']} {alt['main_job_level']})")
            return alts
        else:
            print(f"❌ Erreur HTTP {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return []

def get_alt_details(alt_name):
    """Récupère les détails d'un ALT spécifique"""
    print(f"\n🔍 Récupération des détails de {alt_name}...")
    try:
        response = requests.get(f"{BACKEND_URL}/alt-abilities/{alt_name}", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Données reçues pour {alt_name}")
            print(f"   Job: {data.get('main_job')} {data.get('main_job_level')}")
            print(f"   Engaged: {data.get('is_engaged', 'N/A')}")
            print(f"   Party: {', '.join(data.get('party', []))}")
            return data
        else:
            print(f"❌ Erreur HTTP {response.status_code}")
            return None
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return None

def monitor_engagement(alt_name, duration=30):
    """Surveille l'état d'engagement d'un ALT pendant X secondes"""
    print(f"\n👁️ Surveillance de l'engagement de {alt_name} pendant {duration}s...")
    print("   (Engagez le combat dans FFXI pour tester)")
    
    last_state = None
    start_time = time.time()
    
    while time.time() - start_time < duration:
        try:
            response = requests.get(f"{BACKEND_URL}/alt-abilities/{alt_name}", timeout=5)
            if response.status_code == 200:
                data = response.json()
                is_engaged = data.get('is_engaged', False)
                
                if is_engaged != last_state:
                    timestamp = time.strftime("%H:%M:%S")
                    if is_engaged:
                        print(f"   [{timestamp}] ⚔️  {alt_name} est maintenant ENGAGED")
                    else:
                        print(f"   [{timestamp}] 🛡️  {alt_name} est maintenant IDLE")
                    last_state = is_engaged
            
            time.sleep(2)  # Vérifier toutes les 2 secondes (comme dans la Web App)
            
        except KeyboardInterrupt:
            print("\n⏹️  Surveillance interrompue")
            break
        except Exception as e:
            print(f"   ❌ Erreur: {e}")
            time.sleep(2)
    
    print("✅ Surveillance terminée")

def test_auto_engage_scenario():
    """Simule un scénario complet d'auto engage"""
    print("\n🎯 Test du scénario Auto Engage")
    print("=" * 60)
    
    # 1. Vérifier la connexion
    if not test_connection():
        return
    
    # 2. Récupérer les ALTs
    alts = get_all_alts()
    if len(alts) < 2:
        print("\n⚠️  Il faut au moins 2 ALTs pour tester l'auto engage")
        print("   Lancez FFXI avec plusieurs personnages et l'addon AltControl")
        return
    
    # 3. Identifier le main et un alt
    main_name = alts[0]['name']
    alt_name = alts[1]['name'] if len(alts) > 1 else None
    
    if not alt_name:
        print("\n⚠️  Impossible de trouver un ALT")
        return
    
    print(f"\n📌 Configuration du test:")
    print(f"   Main: {main_name}")
    print(f"   ALT:  {alt_name}")
    
    # 4. Vérifier les détails du main
    main_data = get_alt_details(main_name)
    if not main_data:
        return
    
    # 5. Vérifier les détails de l'alt
    alt_data = get_alt_details(alt_name)
    if not alt_data:
        return
    
    # 6. Vérifier que l'alt est dans la party du main
    alt_party = alt_data.get('party', [])
    if main_name not in alt_party:
        print(f"\n⚠️  {alt_name} n'est pas dans la même party que {main_name}")
        print(f"   Party de {alt_name}: {', '.join(alt_party)}")
        return
    
    print(f"\n✅ {alt_name} est dans la party de {main_name}")
    
    # 7. Surveiller l'engagement
    print(f"\n📝 Instructions:")
    print(f"   1. Ouvrez la Web App pour {alt_name}")
    print(f"   2. Activez le bouton 'Auto: ON'")
    print(f"   3. Engagez le combat avec {main_name} dans FFXI")
    print(f"   4. {alt_name} devrait automatiquement attaquer")
    
    input("\nAppuyez sur Entrée pour commencer la surveillance...")
    
    monitor_engagement(main_name, duration=60)

if __name__ == "__main__":
    print("🧪 Test du système Auto Engage")
    print("=" * 60)
    
    try:
        test_auto_engage_scenario()
    except KeyboardInterrupt:
        print("\n\n⏹️  Test interrompu par l'utilisateur")
    except Exception as e:
        print(f"\n❌ Erreur inattendue: {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "=" * 60)
    print("✅ Test terminé")
