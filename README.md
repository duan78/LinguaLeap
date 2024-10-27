# LinguaLeap - Language Learning Platform

A modern, spaced repetition-based language learning platform built with React, TypeScript, and Supabase.

## Overview

LinguaLeap is a comprehensive language learning application that helps users master vocabulary through intelligent spaced repetition and adaptive learning algorithms. The platform tracks user progress, adapts to learning patterns, and provides personalized review schedules.

## Features

- **Smart Learning System**
  - Spaced Repetition System (SRS) for optimal review scheduling
  - Adaptive difficulty based on user performance
  - Five mastery levels: Unknown, Learning, Known, Mastered, Long-term

- **Progress Tracking**
  - Detailed statistics and learning insights
  - Visual progress indicators
  - Streak tracking for consistent practice
  - Mastery level progression

- **Vocabulary Management**
  - Organized lessons by topic
  - Example sentences for context
  - Interactive flashcard interface
  - Group practice by mastery level

- **User Experience**
  - Intuitive swipe interface for reviews
  - Real-time progress updates
  - Responsive design
  - Error handling and retry mechanisms

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd lingualeap
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp .env.example .env
```

Update `.env` with your Supabase credentials:
```
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

4. Start the development server:
```bash
npm run dev
```

## Core Algorithms

### Spaced Repetition System (SRS)

The application uses a sophisticated SRS algorithm that determines review intervals based on:
- Current mastery level
- Consecutive correct answers
- Response time
- Total review count

Mastery Levels:
1. Unknown (New words)
   - Review interval: 1 hour
   - Base score: 0

2. Learning
   - Review interval: 4 hours
   - Requires: 1+ correct answers
   - Base score: 1

3. Known
   - Review interval: 1 day
   - Requires: 2+ correct answers
   - Base score: 2

4. Mastered
   - Review interval: 3 days
   - Requires: 3+ correct answers
   - Base score: 3

5. Long-term
   - Review interval: 7 days
   - Requires: 5+ correct answers, fast response time
   - Base score: 4

### Score Calculation

```typescript
Score = BaseScore + StreakBonus + TimeBonus

where:
- BaseScore = Current mastery level (0-5)
- StreakBonus = min(correct_streak / 5, 1)
- TimeBonus = max(0, min(1, (5000 - response_time) / 5000))
```

## Project Structure

```
src/
├── components/          # Reusable UI components
├── context/            # React context providers
├── hooks/              # Custom React hooks
├── lib/               # Utility functions and configurations
├── pages/             # Route components
├── services/          # Business logic and API calls
├── store/             # State management
├── styles/            # Global styles and animations
└── types/             # TypeScript type definitions

supabase/
├── migrations/        # Database migrations
└── schema.sql        # Database schema
```

## Known Issues

1. Progress View Updates
   - Progress statistics sometimes require manual refresh
   - Inconsistent score display between views

2. Smart Practice
   - Review scheduling needs optimization
   - Response time calculation improvements needed

3. Error Handling
   - Better error messages for network issues
   - Retry mechanism refinement

## TODO

1. Features
   - [ ] Multiple language support
   - [ ] Audio pronunciation
   - [ ] Writing practice
   - [ ] Export progress data
   - [ ] Social features (leaderboards, sharing)

2. Technical
   - [ ] Offline support
   - [ ] Performance optimizations
   - [ ] Mobile app version
   - [ ] Test coverage
   - [ ] CI/CD pipeline

## Troubleshooting

Common issues and solutions:

1. Progress Not Updating
   - Clear browser cache
   - Check network connectivity
   - Verify Supabase connection

2. Review Scheduling Issues
   - Check timezone settings
   - Verify date calculations
   - Monitor review intervals

3. Performance Issues
   - Reduce unnecessary re-renders
   - Optimize database queries
   - Check browser console for errors

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details