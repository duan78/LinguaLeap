import React, { useState, useRef, useEffect } from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface SwipeableCardProps {
  front: string;
  back: string;
  example?: string;
  onSwipe: (direction: 'left' | 'right') => void;
  direction: string | null;
}

export function SwipeableCard({ front, back, example, onSwipe, direction }: SwipeableCardProps) {
  const [isFlipped, setIsFlipped] = useState(false);
  const [startX, setStartX] = useState<number | null>(null);
  const [currentOffset, setCurrentOffset] = useState(0);
  const cardRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setIsFlipped(false);
  }, [front, back]);

  useEffect(() => {
    if (direction) {
      setCurrentOffset(direction === 'right' ? 1000 : -1000);
    } else {
      setCurrentOffset(0);
    }
  }, [direction]);

  const handleTouchStart = (e: React.TouchEvent | React.MouseEvent) => {
    if (direction) return; // Prevent interaction during animation
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    setStartX(clientX);
  };

  const handleTouchMove = (e: React.TouchEvent | React.MouseEvent) => {
    if (startX === null || direction) return;
    
    const clientX = 'touches' in e ? e.touches[0].clientX : e.clientX;
    const diff = clientX - startX;
    setCurrentOffset(diff);
  };

  const handleTouchEnd = () => {
    if (startX === null || direction) return;

    if (Math.abs(currentOffset) > 100) {
      onSwipe(currentOffset > 0 ? 'right' : 'left');
    } else {
      setCurrentOffset(0);
    }

    setStartX(null);
  };

  const cardStyle = {
    transform: `translateX(${currentOffset}px) rotate(${currentOffset * 0.1}deg)`,
    transition: startX === null ? 'transform 0.3s ease' : 'none',
  };

  return (
    <div className="relative w-full max-w-xl mx-auto">
      <div
        ref={cardRef}
        style={cardStyle}
        className="bg-white rounded-xl shadow-lg cursor-pointer touch-none select-none"
        onMouseDown={handleTouchStart}
        onMouseMove={handleTouchMove}
        onMouseUp={handleTouchEnd}
        onMouseLeave={handleTouchEnd}
        onTouchStart={handleTouchStart}
        onTouchMove={handleTouchMove}
        onTouchEnd={handleTouchEnd}
        onClick={() => !startX && !direction && setIsFlipped(!isFlipped)}
      >
        <div className={`min-h-[300px] p-8 transition-all duration-300 ${
          isFlipped ? '[transform:rotateY(180deg)]' : ''
        }`}>
          <div className={`${isFlipped ? 'hidden' : ''}`}>
            <div className="text-center">
              <h2 className="text-3xl font-bold text-gray-900 mb-4">{front}</h2>
              <p className="text-gray-600">Tap to reveal answer</p>
            </div>
          </div>

          <div className={`${!isFlipped ? 'hidden' : ''} [transform:rotateY(180deg)]`}>
            <div className="text-center">
              <h2 className="text-3xl font-bold text-gray-900 mb-4">{back}</h2>
              {example && (
                <p className="text-gray-600 italic mt-4">{example}</p>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="absolute bottom-4 left-0 right-0 flex justify-center space-x-8">
        <button
          onClick={() => !direction && onSwipe('left')}
          disabled={!!direction}
          className="p-3 rounded-full bg-red-100 text-red-600 hover:bg-red-200 transition-colors disabled:opacity-50"
        >
          <ChevronLeft className="h-6 w-6" />
        </button>
        <button
          onClick={() => !direction && onSwipe('right')}
          disabled={!!direction}
          className="p-3 rounded-full bg-green-100 text-green-600 hover:bg-green-200 transition-colors disabled:opacity-50"
        >
          <ChevronRight className="h-6 w-6" />
        </button>
      </div>
    </div>
  );
}