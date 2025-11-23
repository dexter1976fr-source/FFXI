import React, { useRef } from "react";
import { ChevronUp, ChevronDown, ChevronLeft, ChevronRight } from 'lucide-react';
import { Direction } from "../types";

interface DirectionalPadProps {
  onDirectionStart: (direction: Direction) => void;
  onDirectionEnd: (direction: Direction) => void;
}

const DirectionalPad: React.FC<DirectionalPadProps> = ({ onDirectionStart, onDirectionEnd }) => {
  // Refs pour suivre l'état des touches
  const activeDirections = useRef<Set<Direction>>(new Set());

  const handleMouseDown = (direction: Direction) => {
    if (!activeDirections.current.has(direction)) {
      activeDirections.current.add(direction);
      onDirectionStart(direction);
    }
  };

  const handleMouseUp = (direction: Direction) => {
    if (activeDirections.current.has(direction)) {
      activeDirections.current.delete(direction);
      onDirectionEnd(direction);
    }
  };

  const handleMouseLeave = (direction: Direction) => {
    // Si la souris quitte le bouton pendant qu'on appuie, relâcher
    handleMouseUp(direction);
  };

  // Gestion tactile (mobile)
  const handleTouchStart = (e: React.TouchEvent, direction: Direction) => {
    e.preventDefault();
    handleMouseDown(direction);
  };

  const handleTouchEnd = (e: React.TouchEvent, direction: Direction) => {
    e.preventDefault();
    handleMouseUp(direction);
  };

  // Style commun pour les boutons
  const buttonClass = "w-14 h-14 bg-gradient-to-b from-gray-600 to-gray-700 hover:from-gray-500 hover:to-gray-600 active:from-gray-700 active:to-gray-800 rounded-lg flex items-center justify-center transition-all shadow-lg select-none";

  return (
    <div className="flex flex-col items-center gap-1">
      {/* UP */}
      <button
        onMouseDown={() => handleMouseDown("up")}
        onMouseUp={() => handleMouseUp("up")}
        onMouseLeave={() => handleMouseLeave("up")}
        onTouchStart={(e) => handleTouchStart(e, "up")}
        onTouchEnd={(e) => handleTouchEnd(e, "up")}
        className={buttonClass}
      >
        <ChevronUp className="w-8 h-8 text-white" />
      </button>

      <div className="flex gap-1">
        {/* LEFT */}
        <button
          onMouseDown={() => handleMouseDown("left")}
          onMouseUp={() => handleMouseUp("left")}
          onMouseLeave={() => handleMouseLeave("left")}
          onTouchStart={(e) => handleTouchStart(e, "left")}
          onTouchEnd={(e) => handleTouchEnd(e, "left")}
          className={buttonClass}
        >
          <ChevronLeft className="w-8 h-8 text-white" />
        </button>

        {/* CENTER (decorative) */}
        <div className="w-14 h-14 bg-gray-800 rounded-lg border-2 border-gray-600"></div>

        {/* RIGHT */}
        <button
          onMouseDown={() => handleMouseDown("right")}
          onMouseUp={() => handleMouseUp("right")}
          onMouseLeave={() => handleMouseLeave("right")}
          onTouchStart={(e) => handleTouchStart(e, "right")}
          onTouchEnd={(e) => handleTouchEnd(e, "right")}
          className={buttonClass}
        >
          <ChevronRight className="w-8 h-8 text-white" />
        </button>
      </div>

      {/* DOWN */}
      <button
        onMouseDown={() => handleMouseDown("down")}
        onMouseUp={() => handleMouseUp("down")}
        onMouseLeave={() => handleMouseLeave("down")}
        onTouchStart={(e) => handleTouchStart(e, "down")}
        onTouchEnd={(e) => handleTouchEnd(e, "down")}
        className={buttonClass}
      >
        <ChevronDown className="w-8 h-8 text-white" />
      </button>
    </div>
  );
};

export default DirectionalPad;