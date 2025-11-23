import React from "react";

interface SelectableButtonProps {
  label: string;
  sublabel?: string;
  isSelected: boolean;
  onClick: () => void;
  variant?: "primary" | "danger" | "success" | "warning";
}

const SelectableButton: React.FC<SelectableButtonProps> = ({ 
  label, 
  sublabel,
  isSelected, 
  onClick,
  variant = "primary" 
}) => {
  const variantClasses = {
    primary: isSelected 
      ? "bg-cyan-600 border-cyan-400 shadow-cyan-500/50" 
      : "bg-slate-700 border-slate-600",
    danger: isSelected 
      ? "bg-red-600 border-red-400 shadow-red-500/50" 
      : "bg-slate-700 border-slate-600",
    success: isSelected 
      ? "bg-green-600 border-green-400 shadow-green-500/50" 
      : "bg-slate-700 border-slate-600",
    warning: isSelected 
      ? "bg-orange-600 border-orange-400 shadow-orange-500/50" 
      : "bg-slate-700 border-slate-600",
  };

  return (
    <button
      onClick={onClick}
      className={`
        ${variantClasses[variant]}
        px-3 py-2 rounded-lg border-2
        transition-all duration-200
        hover:brightness-110
        active:scale-95
        text-left
        ${isSelected ? "shadow-lg" : "shadow"}
      `}
    >
      <div className="flex items-center gap-2">
        <div className={`w-4 h-4 rounded border-2 flex items-center justify-center ${
          isSelected ? "bg-white border-white" : "bg-transparent border-gray-400"
        }`}>
          {isSelected && (
            <svg className="w-3 h-3 text-gray-900" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
            </svg>
          )}
        </div>
        <div className="flex-1">
          <div className={`font-semibold text-sm ${isSelected ? "text-white" : "text-gray-300"}`}>
            {label}
          </div>
          {sublabel && (
            <div className={`text-xs ${isSelected ? "text-gray-100" : "text-gray-500"}`}>
              {sublabel}
            </div>
          )}
        </div>
      </div>
    </button>
  );
};

export default SelectableButton;