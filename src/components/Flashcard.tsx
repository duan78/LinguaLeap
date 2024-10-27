import React, { useState } from 'react';

interface FlashcardProps {
  front: string;
  back: string;
  onAnswer: (correct: boolean) => void;
}

export function Flashcard({ front, back, onAnswer }: FlashcardProps) {
  const [isFlipped, setIsFlipped] = useState(false);
  const [hasAnswered, setHasAnswered] = useState(false);

  const handleFlip = () => {
    if (!hasAnswered) {
      setIsFlipped(!isFlipped);
    }
  };

  const handleAnswer = (correct: boolean) => {
    setHasAnswered(true);
    onAnswer(correct);
    setTimeout(() => {
      setIsFlipped(false);
      setHasAnswered(false);
    }, 300);
  };

  return (
    <div className="w-full perspective-1000">
      <div
        className={`relative w-full transition-transform duration-300 transform-style-3d cursor-pointer ${
          isFlipped ? 'rotate-y-180' : ''
        }`}
        onClick={handleFlip}
      >
        <div className="bg-white rounded-lg shadow-lg p-8 min-h-[300px] flex flex-col justify-between backface-hidden">
          <div className="text-center text-2xl font-medium">{front}</div>
          {!isFlipped && (
            <div className="text-center text-gray-500 mt-4">
              Click to reveal answer
            </div>
          )}
        </div>

        <div className="absolute inset-0 bg-white rounded-lg shadow-lg p-8 min-h-[300px] flex flex-col justify-between backface-hidden rotate-y-180">
          <div className="text-center text-2xl font-medium">{back}</div>
          
          {!hasAnswered && (
            <div className="mt-8 flex justify-center gap-4">
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  handleAnswer(false);
                }}
                className="px-6 py-3 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors"
              >
                Still Learning
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  handleAnswer(true);
                }}
                className="px-6 py-3 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors"
              >
                Got It!
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export default Flashcard;