<div align="center">

# 🌟 LinguaLeap

[![GitHub stars](https://img.shields.io/github/stars/yourusername/lingualeap?style=social)](https://github.com/yourusername/lingualeap/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/yourusername/lingualeap?style=social)](https://github.com/yourusername/lingualeap/network)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![React](https://img.shields.io/badge/React-20232A?logo=react&logoColor=61DAFB)](https://reactjs.org/)

*🚀 Une plateforme d'apprentissage des langues moderne avec système de répétition espacée intelligente*

Transformez votre façon d'apprendre le vocabulaire avec notre algorithme SRS sophistiqué qui s'adapte à votre rythme d'apprentissage.

[▶️ Démo en ligne](https://lingualeap-demo.vercel.app) • [📖 Documentation](#documentation) • [🐛 Signaler un bug](https://github.com/yourusername/lingualeap/issues)

</div>

---

## ✨ Fonctionnalités principales

### 🧠 **Système d'Apprentissage Intelligent**
- **Algorithme SRS Avancé** : Planification des révisions optimisée avec espacement intelligent
- **5 Niveaux de Maîtrise** : De Inconnu à Maîtrise à long terme
- **Adaptation Personnalisée** : L'algorithme s'adapte à votre performance et votre rythme

### 📊 **Suivi de Progrès Complet**
- **Statistiques Détaillées** : Visualisez votre progression avec des graphiques intuitifs
- **Indicateurs Visuels** : Codes couleur et icônes pour chaque niveau de maîtrise
- **Streak Tracking** : Suivez vos séries d'apprentissage pour rester motivé
- **Mises à jour en Temps Réel** : Votre progression est sauvegardée instantanément

### 🎯 **Interface Interactive**
- **Cartes Swipeables** : Interface tactile moderne pour mobile et desktop
- **Feedback Visuel** : Animations fluides et retours immédiats
- **Design Responsive** : Expérience optimale sur tous les appareils
- **Pratique par Groupes** : Révisez les cartes regroupées par niveau de maîtrise

### 🛠️ **Panneau d'Administration**
- **Gestion de Contenu** : Ajoutez et modifiez facilement les leçons et cartes
- **Paramètres d'Apprentissage** : Personnalisez les exigences de maîtrise
- **Monitoring** : Suivez les patterns d'apprentissage et la performance

---

## 🚀 Démarrage Rapide

### Prérequis
- Node.js 18+
- Un compte Supabase

### Installation

```bash
# Clonez le projet
git clone https://github.com/yourusername/lingualeap.git
cd lingualeap

# Installez les dépendances
npm install

# Configurez les variables d'environnement
cp .env.example .env.local
```

### Configuration Supabase

1. Créez un nouveau projet sur [Supabase](https://supabase.com)
2. Exécutez les migrations SQL depuis `supabase/migrations/`
3. Ajoutez vos clés dans `.env.local` :

```env
VITE_SUPABASE_URL=votre_url_supabase
VITE_SUPABASE_ANON_KEY=votre_cle_anon_supabase
```

### Lancement

```bash
# Démarrez le serveur de développement
npm run dev
```

Ouvrez [http://localhost:5173](http://localhost:5173) dans votre navigateur.

---

## 🧮 Algorithme d'Apprentissage

### Système de Répétition Espacée (SRS)

Notre algorithme calcule intelligemment les intervalles de révision :

```typescript
Score = ScoreBase + BonusStreak + BonusTemps
```

#### Niveaux de Maîtrise

| Niveau | Nom | Intervalle | Score Base | Conditions |
|--------|-----|------------|------------|------------|
| 0 | 🆕 Inconnu | 1 heure | 0 | Nouveau mot |
| 1 | 📚 Apprentissage | 4 heures | 1 | 1+ réponses correctes |
| 2 | ✅ Connu | 1 jour | 2 | 2+ réponses correctes |
| 3 | 🏆 Maîtrisé | 3 jours | 3 | 3+ réponses correctes |
| 4 | 💎 Long terme | 7 jours | 4 | 5+ réponses, temps rapide |

#### Calcul de Performance

- **Bonus Streak** : Récompense les séries de réponses correctes
- **Bonus Temps** : Favorise les réponses rapides et confiantes
- **Adaptation** : L'algorithme s'ajuste selon votre progression

---

## 🏗️ Architecture & Stack Technique

<div align="center">

### 🎨 **Frontend**
[![React](https://img.shields.io/badge/React-20232A?logo=react&logoColor=61DAFB)](https://reactjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Vite](https://img.shields.io/badge/Vite-646CFF?logo=vite&logoColor=white)](https://vitejs.dev/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-06B6D4?logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)

### 🗄️ **Backend**
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org/)

### ⚡ **State Management**
[![Zustand](https://img.shields.io/badge/Zustand-000000?logo=react&logoColor=white)](https://github.com/pmndrs/zustand)
[![React Query](https://img.shields.io/badge/React_Query-FF4154?logo=react-query&logoColor=white)](https://tanstack.com/query)

</div>

### Structure du Projet

```
src/
├── 📂 components/         # Composants UI réutilisables
│   ├── 🎨 ui/            # Composants de base
│   ├── 👨‍💼 admin/        # Interface d'administration
│   └── 📱 *.tsx          # Composants fonctionnels
├── 📂 context/           # Context providers (Auth)
├── 📂 hooks/             # Hooks personnalisés React
├── 📂 lib/               # Utilitaires et client Supabase
├── 📂 pages/             # Composants de routing
├── 📂 services/          # Logique métier et API
│   ├── 🧠 learningAlgorithm.ts    # Algorithme SRS
│   ├── 🎯 smartPracticeService.ts # Pratique intelligente
│   └── 📊 progressService.ts      # Suivi de progression
├── 📂 store/             # Stores Zustand
├── 📂 styles/            # Styles globaux
└── 📂 types/             # Définitions TypeScript
```

---

## 🎯 Utilisation

### Apprendre avec les Flashcards

1. **Navigation** : Accédez à la section "Pratique" depuis le menu principal
2. **Swipe Interface** :
   - ➡️ Swipe droit pour "Je connais"
   - ⬅️ Swipe gauche pour "Je ne connais pas"
3. **Feedback Immédiat** : Voyez votre score et niveau de maîtrise évoluer
4. **Progression** : Les cartes sont automatiquement programmées pour révision

### Suivre sa Progression

- **Tableau de bord** : Vue d'ensemble de votre progression
- **Statistiques** : Mots appris, pourcentage de maîtrise, séries actives
- **Graphiques** : Visualisation de votre évolution temporelle
- **Filtres** : Affichez les cartes par niveau de maîtrise

### Gestion du Contenu (Admin)

- **Leçons** : Créez et organisez vos leçons par thème
- **Cartes** : Ajoutez du vocabulaire avec exemples et contextes
- **Paramètres** : Ajustez les seuils de maîtrise et intervalles SRS

---

## 🔧 Scripts Disponibles

```bash
# Développement
npm run dev          # Serveur de développement
npm run build        # Build de production
npm run preview      # Aperçu du build

# Code Quality
npm run lint         # Linting avec ESLint
npm run lint:fix     # Auto-correction du linting
```

---

## 🚀 Déploiement

### Vercel (Recommandé)

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/yourusername/lingualeap)

1. Connectez-vous à votre compte Vercel
2. Importez le projet GitHub
3. Configurez les variables d'environnement
4. Déployez ! 🎉

### Docker

```bash
# Build l'image
docker build -t lingualeap .

# Lancez le conteneur
docker run -p 5173:5173 lingualeap
```

---

## 🤝 Contribuer

Nous apprécions vos contributions ! Voici comment participer :

### 📋 Pour commencer

1. **Fork** le projet
2. **Clonez** votre fork : `git clone https://github.com/votre-username/lingualeap.git`
3. **Créez une branche** : `git checkout -b feature/nouvelle-fonctionnalite`

### 🔨 Développement

```bash
# Installez les dépendances
npm install

# Lancez le dev server
npm run dev

# Appliquez vos changements
git commit -m "feat: ajoute nouvelle fonctionnalité"

# Push vers votre fork
git push origin feature/nouvelle-fonctionnalite
```

### 📝 Guidelines de Contribution

- ✅ Suivez les conventions de code existantes
- ✅ Ajoutez des tests pour les nouvelles fonctionnalités
- ✅ Mettez à jour la documentation si nécessaire
- ✅ Assurez-vous que tous les tests passent
- ✅ Respectez le format [Conventional Commits](https://www.conventionalcommits.org/)

### 🐛 Rapports de Bugs

Quand vous signalez un bug, incluez :
- Description détaillée du problème
- Étapes pour reproduire
- Screenshots si applicable
- Version du navigateur/OS

---

## 📊 Roadmap

### 🎯 Prochaine Version (v2.0)

- [ ] 🌍 Support multilingue (i18n)
- [ ] 🔊 Prononciation audio (TTS)
- [ ] ✍️ Exercices d'écriture
- [ ] 📱 Application mobile PWA
- [ ] 🎮 Gamification (badges, achievements)

### 🔮 Vision Long Terme

- [ ] 🤖 Intelligence artificielle pour personnalisation avancée
- [ ] 👥 Mode apprentissage social
- [ ] 📚 Intégration avec des ressources externes
- [ ] 🎨 Thèmes personnalisables
- [ ] 📊 Analytics avancés

---

## 🆘 Support & FAQ

### Questions Fréquentes

**Q: Comment fonctionne l'algorithme SRS ?**
R: L'algorithme analyse vos performances et adapte les intervalles de révision pour optimiser la mémorisation à long terme.

**Q: Puis-je utiliser LinguaLeap hors ligne ?**
R: Une version PWA avec support hors ligne est en développement (v2.0).

**Q: Comment importer/exporter mon vocabulaire ?**
R: Cette fonctionnalité sera disponible dans la prochaine version majeure.

### Obtenir de l'Aide

- 📖 [Documentation complète](https://lingualeap-docs.vercel.app)
- 💬 [Discussions GitHub](https://github.com/yourusername/lingualeap/discussions)
- 🐛 [Issues et bug reports](https://github.com/yourusername/lingualeap/issues)
- 📧 [Contact support](mailto:support@lingualeap.app)

---

## 📜 Licence

Ce projet est sous licence [MIT](LICENSE) - créez, modifiez et distributez librement !

---

<div align="center">

**⭐ Si LinguaLeap vous aide dans votre apprentissage, n'hésitez pas à nous donner une étoile sur GitHub !**

Made with ❤️ by [Votre Nom](https://github.com/yourusername)

[🔝 Retour en haut](#-lingualeap)

</div>