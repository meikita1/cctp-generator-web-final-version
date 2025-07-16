#!/usr/bin/env python3
"""
Script de test pour l'API d'analyse des PDFs
"""

import requests
import json
import time

API_URL = "http://127.0.0.1:5000"

def test_browse_directories():
    """Teste la fonction de navigation dans les dossiers"""
    print("🔍 Test de navigation dans les dossiers...")
    
    try:
        response = requests.post(f"{API_URL}/api/browse-directories", 
                               json={"path": None},
                               headers={"Content-Type": "application/json"})
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text[:500]}...")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Navigation réussie ! Dossier actuel: {data['current_path']}")
            print(f"📁 {len([item for item in data['items'] if item['type'] == 'directory'])} dossiers trouvés")
            print(f"📄 {data['pdf_count']} fichiers PDF trouvés")
        else:
            print(f"❌ Erreur: {response.text}")
            
    except Exception as e:
        print(f"❌ Erreur lors du test: {e}")

def test_server_status():
    """Teste le statut du serveur"""
    print("🔧 Test du statut du serveur...")
    
    try:
        response = requests.get(f"{API_URL}/api/status")
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Serveur en ligne !")
            print(f"🔑 OpenAI configuré: {data.get('openai_configured', False)}")
            print(f"📄 DOCX disponible: {data.get('docx_available', False)}")
            print(f"🧠 Base de connaissances: {data.get('knowledge_base_status', 'Inconnue')}")
        else:
            print(f"❌ Erreur: {response.text}")
            
    except Exception as e:
        print(f"❌ Erreur lors du test: {e}")

if __name__ == "__main__":
    print("🚀 Démarrage des tests de l'API CCTP")
    print("=" * 50)
    
    test_server_status()
    print()
    test_browse_directories()
    
    print("\n" + "=" * 50)
    print("✅ Tests terminés !")
