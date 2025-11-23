import React, { useState, useEffect } from 'react';

interface CommandButtonWithRecastProps {
  label: string;
  onClick: () => void;
  recastTime?: number; // Temps de recast en secondes (0 = disponible)
  className?: string;
  disabled?: boolean;
}

const CommandButtonWithRecast: React.FC<CommandButtonWithRecastProps> = ({
  label,
  onClick,
  recastTime = 0,
  className = '',
  disabled = false,
}) => {
  const [maxRecastTime, setMaxRecastTime] = useState(0);
  const isOnCooldown = recastTime > 0;

  useEffect(() => {
    // Capturer le temps max quand le recast commence (détection d'un nouveau recast)
    if (recastTime > maxRecastTime) {
      setMaxRecastTime(recastTime);
    }
    // Reset quand le recast est terminé
    if (recastTime === 0 && maxRecastTime > 0) {
      setMaxRecastTime(0);
    }
  }, [recastTime]);

  const handleClick = () => {
    if (!isOnCooldown && !disabled) {
      onClick();
    }
  };

  // Pourcentage restant (100% = plein recast, 0% = disponible)
  const remainingPercentage = maxRecastTime > 0 ? (recastTime / maxRecastTime) * 100 : 0;

  return (
    <button
      onClick={handleClick}
      disabled={isOnCooldown || disabled}
      className={`relative overflow-hidden ${className} ${
        isOnCooldown || disabled ? 'cursor-not-allowed' : ''
      }`}
    >
      {/* Overlay grisé qui se réduit de gauche à droite */}
      {isOnCooldown && (
        <div
          className="absolute top-0 left-0 bottom-0 bg-black bg-opacity-60 transition-all duration-100"
          style={{ 
            width: `${remainingPercentage}%`
          }}
        />
      )}
      
      {/* Contenu du bouton */}
      <div className="relative z-10 flex items-center justify-center h-full">
        <span className="text-sm font-semibold">{label}</span>
        {/* Timer en haut à gauche du bouton pendant le recast */}
        {isOnCooldown && recastTime > 0 && (
          <span className="absolute top-1 left-1 text-xs text-cyan-300 font-bold bg-black bg-opacity-70 px-1 rounded">
            {recastTime.toFixed(1)}s
          </span>
        )}
      </div>
    </button>
  );
};

export default CommandButtonWithRecast;
