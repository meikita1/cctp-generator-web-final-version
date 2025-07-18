<script setup>
import { ref, onMounted, computed, watch } from 'vue';

// --- CONFIGURATION ---
const API_URL = "http://127.0.0.1:5000";

// --- ÉTAT DE L'APPLICATION ---
// État de la connexion au serveur
const serverStatus = ref({
  accessible: null, // null: en attente, true: ok, false: erreur
  openai_configured: false,
  docx_available: false,
  knowledge_base_status: '',
});

// Données du projet
const models = ref([]);
const activeModel = ref(null);
const projectData = ref([]);
const previewsData = ref({});
const sectionsLibrary = ref([]);
const activeTypologyIndex = ref(null);

// État de l'interface
const isLoading = ref(false); // Pour les chargements généraux
const isExporting = ref(false); // Pour les exports
const isAnalyzingPdfs = ref(false);
const theme = ref('Sombre');
const previewScope = ref('Tout');
const searchTerm = ref('');
const showCreateModel = ref(false);
const newModelName = ref('');
const isCreatingModel = ref(false);
const analysisStatus = ref({
  running: false,
  progress: 0,
  max_files: 0,
  current_file: "",
  error: null
});
const showDirectoryBrowser = ref(false);
const directoryBrowser = ref({
  current_path: '',
  items: [],
  pdf_count: 0
});
const showPromptEditor = ref(false);
const systemPrompt = ref('');
const promptModification = ref('');
const isLoadingPrompt = ref(false);
const isGeneratingPrompt = ref(false);
const includeAiNotes = ref(true); // Option pour inclure les notes IA dans l'export

// Prompt par défaut (constante)
const DEFAULT_SYSTEM_PROMPT = `Vous êtes un assistant expert en rédaction de CCTP (Cahier des Clauses Techniques Particulières) pour le secteur du bâtiment.

CONTEXTE :
- Vous aidez à rédiger des sections de CCTP pour différentes typologies de bâtiments
- Vous devez produire un contenu technique précis, conforme aux normes et réglementations
- Le contenu doit être professionnel et adapté au contexte du marché français

INSTRUCTIONS :
1. Analysez le nom de la typologie et le titre de la section
2. Utilisez les notes fournies comme guide principal
3. Rédigez un contenu technique détaillé et structuré
4. Respectez la terminologie technique du bâtiment
5. Incluez les références aux normes pertinentes si nécessaire
6. Adaptez le niveau de détail selon le contexte

STYLE :
- Ton professionnel et technique
- Phrases claires et précises
- Structure logique avec paragraphes bien organisés
- Utilisation du vocabulaire technique approprié

CONTRAINTES :
- Restez factuel et technique
- Évitez les répétitions inutiles
- Adaptez le contenu à la typologie spécifique
- Intégrez les notes utilisateur de manière cohérente`;

// --- LOGIQUE CALCULÉE (Computed Properties) ---
const activeTypology = computed(() => {
  if (activeTypologyIndex.value !== null && projectData.value[activeTypologyIndex.value]) {
    return projectData.value[activeTypologyIndex.value];
  }
  return null;
});

const filteredLibrary = computed(() => {
  if (!searchTerm.value) return [];
  const currentSectionTitles = activeTypology.value?.sections.map(s => s.titre.toLowerCase()) || [];
  return sectionsLibrary.value.filter(s =>
    s.toLowerCase().includes(searchTerm.value.toLowerCase()) &&
    !currentSectionTitles.includes(s.toLowerCase())
  );
});

const chapterMap = computed(() => {
  const map = [];
  projectData.value.forEach((typo, typoIdx) => {
    typo.sections.forEach((section, sectionIdx) => {
      map.push({
        nom_typo: typo.nomTypologie,
        titre_section: section.titre,
        number: `${typoIdx + 1}.${sectionIdx + 1}`
      });
    });
  });
  return map;
});

const renderedPreviewHTML = computed(() => {
    let html = '';
    const typosToRender = previewScope.value === 'Tout' ? projectData.value : [activeTypology.value];

    typosToRender.forEach(typo => {
        if (!typo) return;
        const typoPreviews = previewsData.value[typo.nomTypologie] || {};
        if (Object.keys(typoPreviews).length === 0) return;

        const typoIndex = projectData.value.indexOf(typo);
        html += `<h1>${typoIndex + 1}. ${typo.nomTypologie}</h1>`;

        typo.sections.forEach(section => {
            let text = typoPreviews[section.titre];
            if (text) {
                const chapterInfo = chapterMap.value.find(c => c.nom_typo === typo.nomTypologie && c.titre_section === section.titre);
                html += `<h3>${chapterInfo.number} ${section.titre}</h3>`;

                // Séparer le texte principal, les placeholders, les exemples et les cross-ref
                let mainText = text;
                let placeholders = [];
                let exemples = [];
                let crossrefs = [];

                // Extraire les placeholders [À ...]
                mainText = mainText.replace(/(\[(?:À PRÉCISER|À VALIDER|COMPLÉTER|RÉFÉRENCE À INDIQUER).*?\])/g, (m) => {
                    if (!placeholders.includes(m)) placeholders.push(m);
                    return '';
                });

                // Extraire les exemples (voir exemple CCTP ...)
                mainText = mainText.replace(/(\(voir exemple CCTP .*?\))/g, (m) => {
                    if (!exemples.includes(m)) exemples.push(m);
                    return '';
                });

                // Extraire les cross-ref {{REF:...|...}}
                mainText = mainText.replace(/\{\{REF:(.*?)\|(.*?)\}\}/g, (match, typoName, sectionName) => {
                    const ref = chapterMap.value.find(c => c.nom_typo === typoName && c.titre_section === sectionName);
                    const label = ref ? `(voir section ${ref.number} ${sectionName})` : `(référence introuvable)`;
                    if (!crossrefs.includes(label)) crossrefs.push(label);
                    return '';
                });

                // Nettoyer le texte principal (supprimer les espaces en trop)
                mainText = mainText.trim();

                // Construire le HTML SANS balise ni couleur
                html += `<p>${mainText.replace(/\n/g, '<br>')}`;
                if (placeholders.length > 0) {
                    html += `<br><br>À compléter :<br>${placeholders.join('<br>')}`;
                }
                if (exemples.length > 0) {
                    html += `<br><br>Exemples :<br>${exemples.join('<br>')}`;
                }
                if (crossrefs.length > 0) {
                    html += `<br><br>Références croisées :<br>${crossrefs.join('<br>')}`;
                }
                html += `</p>`;
            }
        });
    });
    return html;
});


// --- MÉTHODES DE COMMUNICATION API ---
async function checkServerStatus() {
  try {
    const response = await fetch(`${API_URL}/api/status`);
    if (!response.ok) throw new Error(`Réponse réseau non OK: ${response.status}`);
    const data = await response.json();
    serverStatus.value = { ...data, accessible: true };
    fetchModels(); // Si le serveur est OK, on charge les modèles
  } catch (error) {
    console.error("Erreur de connexion au backend:", error);
    serverStatus.value.accessible = false;
  }
}

async function fetchModels() {
  try {
    const response = await fetch(`${API_URL}/api/models`);
    models.value = await response.json();
  } catch (error) {
    alert("Erreur: Impossible de charger la liste des modèles.");
    console.error(error);
  }
}

async function loadModel(modelName) {
  if (!modelName) return;
  isLoading.value = true;
  try {
    const response = await fetch(`${API_URL}/api/data/${modelName}`);
    const data = await response.json();
    projectData.value = data.project;
    previewsData.value = data.previews;
    sectionsLibrary.value = data.sectionsLibrary;
    activeModel.value = modelName;
    activeTypologyIndex.value = projectData.value.length > 0 ? 0 : null;
  } catch (error) {
    alert(`Erreur lors du chargement du modèle ${modelName}`);
  } finally {
    isLoading.value = false;
  }
}

async function saveActiveModel() {
  if (!activeModel.value) return;
  isLoading.value = true;
  try {
    await fetch(`${API_URL}/api/data/${activeModel.value}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ project: projectData.value, previews: previewsData.value })
    });
    alert(`Modèle '${activeModel.value}' sauvegardé.`);
  } catch(e) {
    alert("Erreur lors de la sauvegarde du projet.");
  } finally {
    isLoading.value = false;
  }
}

async function generateSectionContent(typo, section, action = 'génération du contenu...') {
  section.isGenerating = true;
  try {
    const response = await fetch(`${API_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        nomTypo: typo.nomTypologie,
        titreSection: section.titre,
        notes: section.contenu,
        texteActuel: previewsData.value[typo.nomTypologie]?.[section.titre] || '',
        action: action,
      })
    });
    const result = await response.json();
    if(result.error) throw new Error(result.error);
    
    if (!previewsData.value[typo.nomTypologie]) previewsData.value[typo.nomTypologie] = {};
    previewsData.value[typo.nomTypologie][section.titre] = result.text;

  } catch(e) {
    alert(`Erreur de génération: ${e.message}`);
  } finally {
    section.isGenerating = false;
  }
}

async function exportFile(format) {
  isExporting.value = true;
  try {
    // Créer une version nettoyée des données sans les transformations HTML
    const cleanPreviewsData = {};
    Object.keys(previewsData.value).forEach(typologyName => {
      cleanPreviewsData[typologyName] = {};
      Object.keys(previewsData.value[typologyName]).forEach(sectionTitle => {
        // Nettoyer les doublons avant export
        cleanPreviewsData[typologyName][sectionTitle] = cleanExportText(previewsData.value[typologyName][sectionTitle]);
      });
    });

    const response = await fetch(`${API_URL}/api/export/${format}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        project: projectData.value,
        previews: cleanPreviewsData,
        chapterMap: chapterMap.value,
        includeAiNotes: includeAiNotes.value
      })
    });
    if (!response.ok) throw new Error('La génération du fichier a échoué sur le serveur.');
    
    const blob = await response.blob();
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `CCTP_${new Date().toISOString().slice(0, 10)}.${format}`;
    document.body.appendChild(a);
    a.click();
    window.URL.revokeObjectURL(url);
    a.remove();

  } catch (error) {
    alert(`Erreur lors de l'export ${format.toUpperCase()}: ${error.message}`);
  } finally {
    isExporting.value = false;
  }
}

async function showPdfAnalysisDialog() {
  showDirectoryBrowser.value = true;
  await browseDirectories();
}

async function browseDirectories(path = null) {
  try {
    const response = await fetch(`${API_URL}/api/browse-directories`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ path: path })
    });
    
    const result = await response.json();
    if (!response.ok) {
      throw new Error(result.error || 'Erreur lors de la navigation');
    }
    
    directoryBrowser.value = result;
    
  } catch (error) {
    alert(`Erreur: ${error.message}`);
    console.error('Erreur de navigation:', error);
  }
}

async function selectDirectory(directoryPath) {
  showDirectoryBrowser.value = false;
  await startPdfAnalysis(directoryPath);
}

async function startPdfAnalysis(directoryPath) {
  isAnalyzingPdfs.value = true;
  analysisStatus.value = { running: false, progress: 0, max_files: 0, current_file: "", error: null };
  
  try {
    const response = await fetch(`${API_URL}/api/analyze-pdfs`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ directory: directoryPath })
    });
    
    const result = await response.json();
    if (!response.ok) {
      throw new Error(result.error || 'Erreur lors du démarrage de l\'analyse');
    }
    
    // Démarrer le polling du statut
    pollAnalysisStatus();
    
  } catch (error) {
    alert(`Erreur: ${error.message}`);
    isAnalyzingPdfs.value = false;
  }
}

async function analyzePdfs() {
  await showPdfAnalysisDialog();
}

async function loadSystemPrompt() {
  isLoadingPrompt.value = true;
  try {
    const response = await fetch(`${API_URL}/api/system-prompt`);
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    const data = await response.json();
    systemPrompt.value = data.prompt || getDefaultPrompt();
  } catch (error) {
    console.log('Endpoint non disponible, utilisation du prompt par défaut');
    systemPrompt.value = getDefaultPrompt();
  } finally {
    isLoadingPrompt.value = false;
  }
}

function getDefaultPrompt() {
  return DEFAULT_SYSTEM_PROMPT;
}

function resetPromptToDefault() {
  if (confirm('Êtes-vous sûr de vouloir réinitialiser le prompt à sa valeur par défaut ? Toutes vos modifications seront perdues.')) {
    systemPrompt.value = getDefaultPrompt();
    alert('Prompt réinitialisé à sa valeur par défaut.');
  }
}

async function saveSystemPrompt() {
  isLoadingPrompt.value = true;
  try {
    const response = await fetch(`${API_URL}/api/system-prompt`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt: systemPrompt.value })
    });
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    alert('Prompt système sauvegardé avec succès !');
  } catch (error) {
    alert('Fonctionnalité non disponible sur le serveur. Le prompt sera utilisé localement.');
    console.log('Sauvegarde du prompt non disponible:', error);
  } finally {
    isLoadingPrompt.value = false;
  }
}

async function generatePromptImprovement() {
  if (!promptModification.value.trim()) {
    alert('Veuillez saisir une modification ou amélioration à apporter au prompt.');
    return;
  }
  
  isGeneratingPrompt.value = true;
  try {
    const response = await fetch(`${API_URL}/api/improve-prompt`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        currentPrompt: systemPrompt.value,
        modification: promptModification.value 
      })
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }
    
    const data = await response.json();
    if (data.error) throw new Error(data.error);
    
    systemPrompt.value = data.improvedPrompt;
    promptModification.value = '';
    alert('Prompt amélioré avec succès !');
  } catch (error) {
    alert('Fonctionnalité non disponible sur le serveur. Vous pouvez modifier le prompt manuellement.');
    console.log('Amélioration du prompt non disponible:', error);
  } finally {
    isGeneratingPrompt.value = false;
  }
}

function togglePromptEditor() {
  showPromptEditor.value = !showPromptEditor.value;
  if (showPromptEditor.value && !systemPrompt.value) {
    loadSystemPrompt();
  }
}

async function pollAnalysisStatus() {
  try {
    const response = await fetch(`${API_URL}/api/analyze-pdfs/status`);
    const status = await response.json();
    analysisStatus.value = status;
    
    if (status.running) {
      // Continuer le polling si l'analyse est en cours
      setTimeout(pollAnalysisStatus, 1000);
    } else {
      // Analyse terminée
      isAnalyzingPdfs.value = false;
      if (status.error) {
        alert(`Erreur lors de l'analyse: ${status.error}`);
      } else {
        alert('Analyse des PDFs terminée avec succès! La base de connaissances a été mise à jour.');
        // Actualiser le statut du serveur
        checkServerStatus();
      }
    }
  } catch (error) {
    console.error('Erreur lors de la vérification du statut:', error);
    setTimeout(pollAnalysisStatus, 2000); // Retry after 2 seconds
  }
}

// --- MÉTHODES DE MANIPULATION LOCALE ---
function addTypology() {
  const newName = `Nouvelle Typologie ${projectData.value.length + 1}`;
  projectData.value.push({ nomTypologie: newName, sections: [] });
  activeTypologyIndex.value = projectData.value.length - 1;
}

function duplicateTypology() {
  if (activeTypology.value) {
    const duplicatedTypology = JSON.parse(JSON.stringify(activeTypology.value));
    duplicatedTypology.nomTypologie = `${duplicatedTypology.nomTypologie} (Copie)`;
    projectData.value.push(duplicatedTypology);
    activeTypologyIndex.value = projectData.value.length - 1;
  }
}

function deleteTypology(index) {
  if (confirm(`Êtes-vous sûr de vouloir supprimer la typologie "${projectData.value[index].nomTypologie}" ?`)) {
    projectData.value.splice(index, 1);
    if (activeTypologyIndex.value >= index) {
      activeTypologyIndex.value = activeTypologyIndex.value > 0 ? activeTypologyIndex.value - 1 : null;
    }
  }
}

function clearGeneratedContent() {
  if (activeTypology.value && confirm(`Êtes-vous sûr de vouloir supprimer tout le contenu généré par l'IA pour la typologie "${activeTypology.value.nomTypologie}" ?`)) {
    const typologyName = activeTypology.value.nomTypologie;
    if (previewsData.value[typologyName]) {
      previewsData.value[typologyName] = {};
    }
    alert('Contenu généré par l\'IA supprimé pour cette typologie.');
  }
}

function clearSectionContent(sectionTitle) {
  if (activeTypology.value && confirm(`Êtes-vous sûr de vouloir supprimer le contenu généré par l'IA pour la section "${sectionTitle}" ?`)) {
    const typologyName = activeTypology.value.nomTypologie;
    if (previewsData.value[typologyName] && previewsData.value[typologyName][sectionTitle]) {
      delete previewsData.value[typologyName][sectionTitle];
    }
  }
}

async function generateAllSections() {
  if (!activeTypology.value || !activeTypology.value.sections || activeTypology.value.sections.length === 0) {
    alert('Aucune section à générer pour cette typologie.');
    return;
  }
  
  if (!confirm(`Êtes-vous sûr de vouloir générer toutes les sections de la typologie "${activeTypology.value.nomTypologie}" ? Cela peut prendre plusieurs minutes.`)) {
    return;
  }
  
  const totalSections = activeTypology.value.sections.length;
  let completedSections = 0;
  
  for (const section of activeTypology.value.sections) {
    if (section.isGenerating) continue; // Ignorer les sections déjà en cours de génération
    
    try {
      await generateSectionContent(activeTypology.value, section);
      completedSections++;
    } catch (error) {
      console.error(`Erreur lors de la génération de la section "${section.titre}":`, error);
      // Continuer avec les autres sections même si une échoue
    }
  }
  
  alert(`Génération terminée : ${completedSections}/${totalSections} sections générées avec succès.`);
}

// --- MÉTHODES SUPPLÉMENTAIRES ---
function deleteSection(sectionIndex) {
    if (activeTypology.value && activeTypology.value.sections) {
        if (confirm(`Êtes-vous sûr de vouloir supprimer la section "${activeTypology.value.sections[sectionIndex].titre}" ?`)) {
            // Supprimer également le contenu généré pour cette section
            const typologyName = activeTypology.value.nomTypologie;
            const sectionTitle = activeTypology.value.sections[sectionIndex].titre;
            
            if (previewsData.value[typologyName] && previewsData.value[typologyName][sectionTitle]) {
                delete previewsData.value[typologyName][sectionTitle];
            }
            
            // Supprimer la section de la liste
            activeTypology.value.sections.splice(sectionIndex, 1);
        }
    }
}

async function createNewModel() {
  if (!newModelName.value.trim()) {
    alert('Veuillez saisir un nom pour le nouveau modèle.');
    return;
  }
  
  isCreatingModel.value = true;
  try {
    const response = await fetch(`${API_URL}/api/models`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: newModelName.value.trim() })
    });
    
    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Erreur lors de la création du modèle');
    }
    
    // Recharger la liste des modèles
    await fetchModels();
    
    // Charger le nouveau modèle
    await loadModel(newModelName.value.trim());
    
    // Réinitialiser et fermer le modal
    newModelName.value = '';
    showCreateModel.value = false;
    
    alert(`Modèle "${newModelName.value.trim()}" créé avec succès !`);
    
  } catch (error) {
    alert(`Erreur: ${error.message}`);
  } finally {
    isCreatingModel.value = false;
  }
}

function addSectionFromSearch(sectionName) {
    if (sectionName && activeTypology.value) {
        if (!activeTypology.value.sections) activeTypology.value.sections = [];
        activeTypology.value.sections.push({ titre: sectionName, contenu: "" });
        searchTerm.value = '';
    }
}

// Fonction pour ajouter une section personnalisée
function addCustomSection(sectionName) {
  if (sectionName && activeTypology.value) {
    const trimmedName = sectionName.trim();
    if (trimmedName) {
      if (!activeTypology.value.sections) activeTypology.value.sections = [];
      activeTypology.value.sections.push({ titre: trimmedName, contenu: "" });
      
      // Proposer d'ajouter à la bibliothèque
      if (confirm(`Section "${trimmedName}" créée ! Voulez-vous l'ajouter à la bibliothèque pour la réutiliser dans d'autres projets ?`)) {
        addSectionToLibrary(trimmedName);
      }
      
      searchTerm.value = '';
    }
  }
}

// Fonction pour ajouter une section vide
function addEmptySection() {
  if (activeTypology.value) {
    if (!activeTypology.value.sections) activeTypology.value.sections = [];
    activeTypology.value.sections.push({ titre: "Nouvelle section", contenu: "" });
  }
}

// Fonction pour changer le thème
function toggleTheme() {
  theme.value = theme.value === 'Sombre' ? 'Clair' : 'Sombre';
  document.body.dataset.theme = theme.value.toLowerCase();
  localStorage.setItem('theme', theme.value);
}

// Fonction pour vérifier si une section existe dans la bibliothèque
function isSectionInLibrary(sectionTitle) {
  return sectionsLibrary.value.some(s => s.toLowerCase() === sectionTitle.toLowerCase());
}

// Fonction pour proposer d'ajouter une section à la bibliothèque
function suggestAddingToLibrary(sectionTitle) {
  if (!isSectionInLibrary(sectionTitle)) {
    if (confirm(`La section "${sectionTitle}" n'existe pas dans la bibliothèque. Voulez-vous l'ajouter pour la réutiliser dans d'autres projets ?`)) {
      addSectionToLibrary(sectionTitle);
    }
  }
}

// Fonction pour ajouter une section à la bibliothèque
function addSectionToLibrary(sectionTitle) {
  if (!isSectionInLibrary(sectionTitle)) {
    sectionsLibrary.value.push(sectionTitle);
    // Trier la bibliothèque pour maintenir l'ordre alphabétique
    sectionsLibrary.value.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
    
    // Envoyer une notification visuelle
    alert(`Section "${sectionTitle}" ajoutée à la bibliothèque avec succès !`);
    
    // Note: La bibliothèque sera sauvegardée automatiquement lors de la prochaine sauvegarde du projet
    // car le backend met à jour la bibliothèque quand il sauvegarde les projets
  }
}

// Fonction pour vérifier et suggérer d'ajouter une section lors de la modification du titre
function checkAndSuggestSection(sectionTitle) {
  if (sectionTitle && sectionTitle.trim()) {
    const trimmedTitle = sectionTitle.trim();
    // Vérifier si la section n'existe pas et si elle n'est pas vide
    if (!isSectionInLibrary(trimmedTitle) && trimmedTitle.length > 2) {
      // Attendre un peu avant de proposer pour éviter les propositions trop fréquentes
      setTimeout(() => {
        if (confirm(`La section "${trimmedTitle}" n'existe pas dans la bibliothèque. Voulez-vous l'ajouter pour la réutiliser dans d'autres projets ?`)) {
          addSectionToLibrary(trimmedTitle);
        }
      }, 500);
    }
  }
}

// Fonction utilitaire pour nettoyer les doublons dans le texte (placeholders/références)
function cleanExportText(text) {
  if (!text) return "";
  // Supprimer les doublons de type "[À VALIDER ...][À VALIDER ...]" même séparés par des espaces ou retours à la ligne
  text = text.replace(/(\[(?:À PRÉCISER|À VALIDER|COMPLÉTER|RÉFÉRENCE À INDIQUER)[^\]]*\])([\s\r\n]*)\1+/g, '$1');
  // Supprimer les doublons de références d'exemples même séparés par des espaces ou retours à la ligne
  text = text.replace(/(\(voir exemple CCTP[^\)]*\))([\s\r\n]*)\1+/g, '$1');
  return text;
}

// --- CYCLE DE VIE ---
onMounted(() => {
  // Charger le thème depuis localStorage ou utiliser 'Sombre' par défaut
  const savedTheme = localStorage.getItem('theme');
  if (savedTheme && (savedTheme === 'Sombre' || savedTheme === 'Clair')) {
    theme.value = savedTheme;
  }
  document.body.dataset.theme = theme.value.toLowerCase();
  checkServerStatus();
});
</script>

<template>
  <div v-if="serverStatus.accessible === false" class="status-overlay error">
    <h1>Serveur Backend Inaccessible</h1>
    <p>Impossible de se connecter au serveur à l'adresse <strong>{{ API_URL }}</strong>.</p>
    <p>Veuillez vous assurer que le serveur Python (Flask) est bien lancé et qu'il n'y a pas d'erreur dans son terminal.</p>
  </div>
  
  <div v-else-if="serverStatus.accessible === null" class="status-overlay">
    <h1>Connexion au serveur...</h1>
  </div>

  <div v-else class="main-layout" :class="{ loading: isLoading }">
    <!-- PANNEAU DE GAUCHE -->
    <div class="pane left-pane">
      <header class="pane-header">
        <div class="header-content">
          <h2>Projet CCTP</h2>
          <button @click="toggleTheme" class="theme-toggle-btn" title="Changer le thème">
            {{ theme === 'Sombre' ? '☀️' : '🌙' }}
          </button>
        </div>
        <p v-if="serverStatus.openai_configured === false" class="warning">⚠️ Clé OpenAI non configurée</p>
      </header>
      
      <div class="form-group">
        <label for="model-select">Modèle de Projet</label>
        <div class="model-selection">
          <select id="model-select" @change="loadModel($event.target.value)" :disabled="isLoading">
            <option disabled :selected="!activeModel">-- Choisir un modèle --</option>
            <option v-for="model in models" :key="model" :value="model">{{ model }}</option>
          </select>
          <button @click="showCreateModel = true" class="accent small" title="Créer un nouveau modèle">
            + Nouveau
          </button>
        </div>
      </div>

      <!-- Modal de création de modèle -->
      <div v-if="showCreateModel" class="modal-overlay" @click="showCreateModel = false">
        <div class="modal-content create-model-modal" @click.stop>
          <h3>Créer un nouveau modèle</h3>
          <div class="form-group">
            <label for="new-model-name">Nom du modèle :</label>
            <input 
              id="new-model-name" 
              v-model="newModelName" 
              placeholder="Ex: Projet Résidentiel 2024"
              @keydown.enter="createNewModel"
              :disabled="isCreatingModel"
            />
          </div>
          <div class="modal-actions">
            <button @click="showCreateModel = false" class="secondary" :disabled="isCreatingModel">
              Annuler
            </button>
            <button @click="createNewModel" class="accent" :disabled="!newModelName.trim() || isCreatingModel">
              {{ isCreatingModel ? 'Création...' : 'Créer le modèle' }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="activeModel" class="typology-section">
        <h3>Typologies</h3>
        <ul class="item-list">
          <li v-for="(typo, index) in projectData" :key="index" @click="activeTypologyIndex = index" :class="{ active: index === activeTypologyIndex }">
            <span>{{ typo.nomTypologie }}</span>
            <div class="item-controls">
                <button @click.stop="moveTypology(index, -1)" :disabled="index === 0">↑</button>
                <button @click.stop="moveTypology(index, 1)" :disabled="index === projectData.length - 1">↓</button>
                <button @click.stop="deleteTypology(index)" class="danger">✕</button>
            </div>
          </li>
        </ul>
        <button @click="addTypology" class="accent full-width">+ Ajouter une typologie</button>
      </div>
      
      <div class="knowledge-base-section">
        <h3>Base de Connaissances</h3>
        <p class="kb-status">{{ serverStatus.knowledge_base_status }}</p>
        <button @click="analyzePdfs" :disabled="isAnalyzingPdfs || isLoading" class="accent full-width">
          {{ isAnalyzingPdfs ? 'Analyse en cours...' : '📄 Analyser les PDFs d\'exemples' }}
        </button>
        
        <!-- Modal de navigation des dossiers -->
        <div v-if="showDirectoryBrowser" class="modal-overlay" @click="showDirectoryBrowser = false">
          <div class="modal-content directory-browser" @click.stop>
            <h3>Sélectionner le dossier contenant les PDFs d'exemples</h3>
            <div class="current-path">
              <strong>Dossier actuel:</strong> {{ directoryBrowser.current_path }}
            </div>
            <div class="pdf-count">
              📄 {{ directoryBrowser.pdf_count }} fichier(s) PDF trouvé(s)
            </div>
            <div class="directory-list">
              <div v-for="item in directoryBrowser.items" :key="item.path" 
                   class="directory-item" 
                   :class="item.type"
                   @click="item.type === 'directory' || item.type === 'parent' ? browseDirectories(item.path) : null">
                <span class="item-icon">
                  {{ item.type === 'parent' ? '⬆️' : item.type === 'directory' ? '📁' : '📄' }}
                </span>
                <span class="item-name">{{ item.name }}</span>
              </div>
            </div>
            <div class="modal-actions">
              <button @click="showDirectoryBrowser = false" class="secondary">Annuler</button>
              <button @click="selectDirectory(directoryBrowser.current_path)" 
                      :disabled="directoryBrowser.pdf_count === 0" 
                      class="accent">
                Sélectionner ce dossier ({{ directoryBrowser.pdf_count }} PDFs)
              </button>
            </div>
          </div>
        </div>
        <div v-if="analysisStatus.running" class="analysis-progress">
          <p>{{ analysisStatus.current_file }}</p>
          <div class="progress-bar">
            <div class="progress-fill" :style="{ width: `${(analysisStatus.progress / analysisStatus.max_files) * 100}%` }"></div>
          </div>
          <p class="progress-text">{{ analysisStatus.progress }} / {{ analysisStatus.max_files }} fichiers</p>
        </div>
      </div>
      
      <div class="prompt-editor-section">
        <h3>
          Configuration du Prompt IA
          <button @click="togglePromptEditor" class="small" :class="{ active: showPromptEditor }">
            {{ showPromptEditor ? '▼' : '▶' }}
          </button>
        </h3>
        
        <div v-if="showPromptEditor" class="prompt-editor-content">
          <label>Prompt système actuel :</label>
          <textarea 
            v-model="systemPrompt" 
            rows="8" 
            placeholder="Chargement du prompt système..."
            :disabled="isLoadingPrompt"
            class="prompt-textarea"
          ></textarea>
          
          <div class="prompt-actions">
            <button @click="saveSystemPrompt" :disabled="isLoadingPrompt" class="accent small">
              {{ isLoadingPrompt ? 'Sauvegarde...' : '💾 Sauvegarder' }}
            </button>
            <button @click="loadSystemPrompt" :disabled="isLoadingPrompt" class="small">
              {{ isLoadingPrompt ? 'Chargement...' : '🔄 Recharger' }}
            </button>
            <button @click="resetPromptToDefault" :disabled="isLoadingPrompt" class="small danger">
              🔄 Réinitialiser
            </button>
          </div>
          
          <div class="prompt-chat">
            <label>Améliorer le prompt avec l'IA :</label>
            <textarea 
              v-model="promptModification" 
              rows="3" 
              placeholder="Décrivez les améliorations ou modifications à apporter au prompt..."
              class="prompt-modification"
            ></textarea>
            <button @click="generatePromptImprovement" :disabled="isGeneratingPrompt || !promptModification.trim()" class="accent">
              {{ isGeneratingPrompt ? 'Génération...' : '🪄 Améliorer le prompt' }}
            </button>
          </div>
        </div>
      </div>
      
      <footer class="pane-footer">
        <button @click="saveActiveModel" :disabled="!activeModel || isLoading" class="accent">💾 Sauvegarder le projet</button>
        <div class="export-options">
          <div class="checkbox-group">
            <label>
              <input type="checkbox" v-model="includeAiNotes" />
              Inclure les notes IA (placeholders et exemples)
            </label>
          </div>
          <div class="export-buttons">
            <button @click="exportFile('pdf')" :disabled="!activeModel || isExporting" class="danger">{{ isExporting ? 'Export...' : 'Exporter PDF' }}</button>
            <button @click="exportFile('docx')" :disabled="!activeModel || isExporting || !serverStatus.docx_available" class="primary">{{ isExporting ? 'Export...' : 'Exporter Word' }}</button>
          </div>
        </div>
      </footer>
    </div>

    <!-- PANNEAU CENTRAL -->
    <div class="pane center-pane">
      <div v-if="activeTypology" class="editor-content">
        <div class="form-group typology-header">
          <label for="typology-name">Nom de la Typologie</label>
          <div class="typology-controls">
            <input id="typology-name" v-model="activeTypology.nomTypologie" />
            <div class="typology-buttons">
              <button @click="saveActiveModel" :disabled="!activeModel || isLoading" class="accent small" title="Sauvegarder cette typologie">
                {{ isLoading ? '...' : '💾' }}
              </button>
              <button @click="duplicateTypology" class="primary small" title="Dupliquer cette typologie">
                📋
              </button>
              <button @click="generateAllSections" class="accent small" title="Générer toutes les sections de cette typologie" :disabled="!activeTypology.sections || activeTypology.sections.length === 0">
                🪄 Tout générer
              </button>
              <button @click="clearGeneratedContent" class="danger small" title="Supprimer tout le contenu généré par l'IA pour cette typologie">
                🗑️ Tout supprimer
              </button>
            </div>
          </div>
        </div>
        
        <div class="form-group search-group">
          <label for="section-search">Ajouter une section</label>
          <input id="section-search" v-model="searchTerm" placeholder="Rechercher une section..." />
          <ul v-if="filteredLibrary.length > 0" class="search-results">
              <li v-for="sectionName in filteredLibrary" :key="sectionName" @click="addSectionFromSearch(sectionName)">
                  {{ sectionName }}
              </li>
          </ul>
          <div v-if="searchTerm && filteredLibrary.length === 0" class="no-results">
            <p>Aucune section trouvée pour "{{ searchTerm }}"</p>
            <button @click="addCustomSection(searchTerm)" class="accent small">
              ➕ Créer la section "{{ searchTerm }}"
            </button>
          </div>
          <div class="search-actions">
            <button @click="addEmptySection()" class="primary small">
              ➕ Ajouter une section vide
            </button>
          </div>
        </div>
        
        <div v-for="(section, sIndex) in activeTypology.sections" :key="sIndex" class="section-editor">
          <header class="section-header">
            <div class="section-title-container">
              <h4>{{ chapterMap.find(c => c.nom_typo === activeTypology.nomTypologie && c.titre_section === section.titre)?.number }}</h4>
              <input v-model="section.titre" 
                     class="section-title-input" 
                     @blur="checkAndSuggestSection(section.titre)"
                     placeholder="Titre de la section"/>
            </div>
            <div class="section-controls">
              <button v-if="!isSectionInLibrary(section.titre)" 
                      @click="suggestAddingToLibrary(section.titre)" 
                      class="accent small" 
                      title="Ajouter cette section à la bibliothèque">
                📚 Ajouter à la bibliothèque
              </button>
              <button @click="moveSection(sIndex, -1)" :disabled="sIndex === 0" class="small">↑</button>
              <button @click="moveSection(sIndex, 1)" :disabled="sIndex === activeTypology.sections.length - 1" class="small">↓</button>
              <button @click="deleteSection(sIndex)" class="danger small">Supprimer</button>
            </div>
          </header>
          
          <label>Notes pour la génération :</label>
          <textarea v-model="section.contenu" rows="3"></textarea>
          
          <div class="button-group">
            <button @click="generateSectionContent(activeTypology, section)" :disabled="section.isGenerating" class="accent">
              {{ section.isGenerating ? '...' : '🪄 Générer' }}
            </button>
            <button @click="generateSectionContent(activeTypology, section, 'lengthen')" :disabled="section.isGenerating" class="small">Développer</button>
            <button @click="generateSectionContent(activeTypology, section, 'shorten')" :disabled="section.isGenerating" class="small">Résumer</button>
            <button @click="generateSectionContent(activeTypology, section, 'correct')" :disabled="section.isGenerating" class="small">Corriger</button>
          </div>
          
          <div class="ai-output-section">
            <label>Texte CCTP (généré par IA) :</label>
            <div class="ai-textarea-container">
              <textarea 
                v-if="previewsData[activeTypology.nomTypologie]"
                v-model="previewsData[activeTypology.nomTypologie][section.titre]" 
                rows="6"
                class="ai-output"
              ></textarea>
              <button 
                @click="clearSectionContent(section.titre)" 
                class="ai-clear-button" 
                title="Supprimer le contenu IA de cette section"
                v-if="previewsData[activeTypology.nomTypologie] && previewsData[activeTypology.nomTypologie][section.titre]"
              >
                ✕
              </button>
            </div>
          </div>
        </div>
      </div>
      <div v-else class="welcome-message">
        <h2>Bienvenue sur IDE-CCTP</h2>
        <p>Sélectionnez un modèle à gauche pour commencer à travailler.</p>
      </div>
    </div>

    <!-- PANNEAU DE DROITE -->
    <div class="pane right-pane">
      <header class="pane-header">
        <h3>Vue du CCTP</h3>
        <div class="radio-group">
            <input type="radio" id="preview-all" value="Tout" v-model="previewScope">
            <label for="preview-all">Tout le projet</label>
            <input type="radio" id="preview-current" value="Actuelle" v-model="previewScope" :disabled="!activeTypology">
            <label for="preview-current">Typologie active</label>
        </div>
      </header>
      <div class="preview-content" v-html="renderedPreviewHTML"></div>
    </div>
  </div>
</template>

<style>
/* --- Styles Globaux & Thèmes --- */
:root {
  --app-bg: #f5f6fa;
  --pane-bg: #ffffff;
  --text-fg: #2f3542;
  --header-fg: #273c75;
  --border-color: #dcdde1;
  --button-primary-bg: #2980f2;
  --button-accent-bg: #28a745;
  --button-danger-bg: #dc3545;
  --button-fg: #ffffff;
  --list-hover-bg: #e9ecef;
  --list-active-bg: #273c75;
  --list-active-fg: #ffffff;
  --warning-fg: #856404;
  --warning-bg: #fff3cd;
  --placeholder-fg: #D22B2B;
  --reference-fg: #28a745;
  --cross-ref-fg: #007bff;
}

body[data-theme='sombre'] {
  --app-bg: #2f3640;
  --pane-bg: #353b48;
  --text-fg: #f5f6fa;
  --header-fg: #7ed6df;
  --border-color: #485460;
  --button-primary-bg: #3498db;
  --button-accent-bg: #44bd32;
  --button-danger-bg: #e84118;
  --list-hover-bg: #40739e;
  --list-active-bg: #192a56;
  --list-active-fg: #ffffff;
  --warning-fg: #ffeaa7;
  --warning-bg: #d35400;
  --placeholder-fg: #ff7979;
  --reference-fg: #55efc4;
  --cross-ref-fg: #74b9ff;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  background-color: var(--app-bg);
  color: var(--text-fg);
}

/* --- Styles de la Mise en Page Principale --- */
.main-layout {
  display: grid;
  grid-template-columns: 350px 1.5fr 1fr;
  gap: 10px;
  height: 100vh;
  padding: 10px;
  box-sizing: border-box;
}
.pane {
  background-color: var(--pane-bg);
  border-radius: 8px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
}
.left-pane { gap: 20px; }
.center-pane { gap: 20px; }
.right-pane { gap: 5px; }
.pane-header {
  border-bottom: 1px solid var(--border-color);
  padding-bottom: 10px;
  margin-bottom: 10px;
}
.right-pane .pane-header {
  margin-bottom: 5px;
}
.pane-footer {
  margin-top: auto;
  padding-top: 15px;
  border-top: 1px solid var(--border-color);
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 10px;
  align-items: center;
}

.export-options {
  display: flex;
  flex-direction: column;
  gap: 10px;
  align-items: center;
}

.checkbox-group {
  display: flex;
  align-items: center;
  gap: 5px;
}

.checkbox-group label {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 0.85rem;
  cursor: pointer;
}

.checkbox-group input[type="checkbox"] {
  margin: 0;
  cursor: pointer;
}

.export-buttons {
  display: flex;
  gap: 10px;
}

/* --- Styles pour le header avec bouton de thème --- */
.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 5px;
}

.theme-toggle-btn {
  padding: 8px 12px;
  background-color: var(--button-accent-bg);
  color: var(--button-fg);
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.2s ease;
}

.theme-toggle-btn:hover {
  opacity: 0.8;
  transform: scale(1.05);
}

.theme-toggle-btn:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

/* --- Styles des Composants UI --- */
button {
  cursor: pointer;
  padding: 10px 15px;
  border: none;
  border-radius: 5px;
  font-weight: 500;
  background-color: var(--border-color);
  color: var(--text-fg);
}
button:disabled { cursor: not-allowed; opacity: 0.6; }
button.primary { background-color: var(--button-primary-bg); color: var(--button-fg); }
button.accent { background-color: var(--button-accent-bg); color: var(--button-fg); }
button.danger { background-color: var(--button-danger-bg); color: var(--button-fg); }
button.small { padding: 5px 8px; font-size: 0.8rem; }
.full-width { width: 100%; }

.form-group { display: flex; flex-direction: column; gap: 5px; }
label { font-weight: 500; font-size: 0.9rem; }
input, select, textarea {
  background-color: var(--app-bg);
  color: var(--text-fg);
  border: 1px solid var(--border-color);
  border-radius: 5px;
  padding: 10px;
  width: 100%;
  box-sizing: border-box;
}
textarea.ai-output { font-style: italic; }

/* --- Styles Spécifiques --- */
.status-overlay { text-align: center; padding: 50px; }
.status-overlay.error { color: var(--button-danger-bg); }
.warning { font-size: 0.8rem; background-color: var(--warning-bg); color: var(--warning-fg); padding: 5px; border-radius: 4px; text-align: center; }

.item-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 5px; }
.item-list li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
  border-radius: 5px;
  cursor: pointer;
  border: 1px solid transparent;
}
.item-list li:hover { background-color: var(--list-hover-bg); }
.item-list li.active { background-color: var(--list-active-bg); color: var(--list-active-fg); border-color: var(--list-active-bg); }
.item-list li .item-controls { display: flex; gap: 5px; }
.item-list li .item-controls button { padding: 2px 6px; font-size: 0.9rem; }

.search-group { position: relative; }
.search-results {
  position: absolute;
  top: 100%;
  left: 0; right: 0;
  background: var(--pane-bg);
  border: 1px solid var(--border-color);
  z-index: 10;
  list-style: none;
  padding: 0;
  margin: 0;
  max-height: 200px;
  overflow-y: auto;
}
.search-results li { padding: 10px; cursor: pointer; }
.search-results li:hover { background-color: var(--list-hover-bg); }

.no-results {
  background-color: var(--app-bg);
  border: 1px solid var(--border-color);
  border-radius: 5px;
  padding: 15px;
  margin-top: 5px;
  text-align: center;
}

.no-results p {
  margin: 0 0 10px 0;
  color: var(--text-fg);
  font-size: 0.9rem;
}

.search-actions {
  margin-top: 10px;
  display: flex;
  justify-content: center;
}

.section-editor {
  border: 1px solid var(--border-color);
  padding: 15px;
  border-radius: 6px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.section-header { 
  display: flex; 
  justify-content: space-between; 
  align-items: center; 
  flex-wrap: wrap;
  gap: 10px;
}
.section-title-container {
  display: flex;
  align-items: center;
  gap: 10px;
  flex: 1;
}
.section-title-container h4 {
  margin: 0;
  font-size: 1rem;
  color: var(--header-fg);
  min-width: 40px;
}
.section-title-input {
  background-color: var(--app-bg);
  color: var(--text-fg);
  border: 1px solid var(--border-color);
  border-radius: 4px;
  padding: 8px;
  font-size: 0.95rem;
  font-weight: 500;
  flex: 1;
  min-width: 200px;
}
.section-title-input:focus {
  outline: none;
  border-color: var(--button-accent-bg);
  box-shadow: 0 0 0 2px rgba(40, 167, 69, 0.2);
}
.section-controls { 
  display: flex; 
  gap: 5px; 
  flex-shrink: 0;
}
.button-group { display: flex; gap: 5px; }

.preview-content {
    background-color: var(--app-bg);
    padding: 15px;
    border-radius: 5px;
    height: 100%;
    overflow-y: auto;
}
.preview-content h1 { font-size: 1.5rem; color: var(--header-fg); margin-top: 20px; }
.preview-content h3 { font-size: 1.1rem; border-bottom: 1px solid var(--border-color); padding-bottom: 5px; }
.preview-content p { line-height: 1.6; }
/* .preview-content .placeholder { color: var(--placeholder-fg); font-weight: bold; } */
/* .preview-content .reference { color: var(--reference-fg); font-style: italic; } */
/* .preview-content .cross_ref { color: var(--cross-ref-fg); font-style: italic; } */

/* --- Styles pour le groupe radio --- */
.radio-group {
  display: flex;
  gap: 15px;
  align-items: center;
  margin-top: 10px;
}

.radio-group input[type="radio"] {
  margin-right: 5px;
  width: auto;
}

.radio-group label {
  margin-right: 0;
  font-size: 0.9rem;
  cursor: pointer;
}

/* --- Styles pour l'éditeur de prompt --- */
.prompt-editor-section {
  border-top: 1px solid var(--border-color);
  padding-top: 15px;
  margin-top: 15px;
}

.prompt-editor-section h3 {
  margin: 0 0 10px 0;
  color: var(--header-fg);
  font-size: 1.1rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.prompt-editor-section h3 button {
  margin-left: 10px;
  padding: 2px 6px;
  font-size: 0.8rem;
  border: 1px solid var(--border-color);
  background-color: var(--app-bg);
}

.prompt-editor-section h3 button.active {
  background-color: var(--button-accent-bg);
  color: var(--button-fg);
}

.prompt-editor-content {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.prompt-textarea {
  font-family: 'Courier New', monospace;
  font-size: 0.85rem;
  line-height: 1.4;
  min-height: 150px;
  resize: vertical;
}

.prompt-actions {
  display: flex;
  gap: 10px;
}

.prompt-chat {
  border-top: 1px solid var(--border-color);
  padding-top: 10px;
  margin-top: 10px;
}

.prompt-modification {
  font-size: 0.9rem;
  margin-bottom: 10px;
}

/* --- Styles pour la Base de Connaissances --- */
.knowledge-base-section {
  border-top: 1px solid var(--border-color);
  padding-top: 15px;
  margin-top: 15px;
}

.knowledge-base-section h3 {
  margin: 0 0 10px 0;
  color: var(--header-fg);
  font-size: 1.1rem;
}

.kb-status {
  font-size: 0.9rem;
  color: var(--text-fg);
  margin: 5px 0 10px 0;
  opacity: 0.8;
}

.analysis-progress {
  margin-top: 10px;
  padding: 10px;
  background-color: var(--app-bg);
  border-radius: 5px;
  border: 1px solid var(--border-color);
}

.analysis-progress p {
  margin: 5px 0;
  font-size: 0.9rem;
  color: var(--text-fg);
}

.progress-bar {
  width: 100%;
  height: 20px;
  background-color: var(--border-color);
  border-radius: 10px;
  overflow: hidden;
  margin: 10px 0;
}

.progress-fill {
  height: 100%;
  background-color: var(--button-accent-bg);
  transition: width 0.3s ease;
  border-radius: 10px;
}

.progress-text {
  text-align: center;
  font-weight: 500;
  color: var(--text-fg);
}

/* --- Styles pour le Modal de Navigation --- */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-content {
  background-color: var(--pane-bg);
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
  max-width: 90%;
  max-height: 80%;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.directory-browser {
  width: 600px;
  height: 500px;
}

.directory-browser h3 {
  margin: 0;
  padding: 20px 20px 10px 20px;
  color: var(--header-fg);
  border-bottom: 1px solid var(--border-color);
}

.current-path {
  padding: 10px 20px;
  background-color: var(--app-bg);
  border-bottom: 1px solid var(--border-color);
  font-size: 0.9rem;
  word-break: break-all;
}

.pdf-count {
  padding: 10px 20px;
  background-color: var(--app-bg);
  border-bottom: 1px solid var(--border-color);
  font-size: 0.9rem;
  color: var(--button-accent-bg);
  font-weight: 500;
}

.directory-list {
  flex: 1;
  overflow-y: auto;
  padding: 10px 0;
}

.directory-item {
  display: flex;
  align-items: center;
  padding: 10px 20px;
  cursor: pointer;
  transition: background-color 0.2s;
}

.directory-item:hover {
  background-color: var(--list-hover-bg);
}

.directory-item.pdf {
  cursor: default;
  opacity: 0.7;
}

.directory-item.pdf:hover {
  background-color: transparent;
}

.item-icon {
  margin-right: 10px;
  font-size: 1.2rem;
}

.item-name {
  flex: 1;
  color: var(--text-fg);
}

.modal-actions {
  padding: 20px;
  border-top: 1px solid var(--border-color);
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.modal-actions button {
  padding: 10px 20px;
}

button.secondary {
  background-color: var(--border-color);
  color: var(--text-fg);
}

button.secondary:hover {
  background-color: var(--list-hover-bg);
}
</style>