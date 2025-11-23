import React from "react";

interface CommandButtonProps {
  label: string;
  onClick: () => void;
  variant?: "primary" | "danger" | "success" | "warning";
  icon?: React.ReactNode;
  disabled?: boolean;
}

const CommandButton: React.FC<CommandButtonProps> = ({
  label,
  onClick,
  variant = "primary",
  icon,
  disabled = false,
}) => {
  const variantClasses = {
    primary: "bg-gradient-to-br from-cyan-600 to-cyan-700 hover:from-cyan-500 hover:to-cyan-600 text-white",
    danger: "bg-gradient-to-br from-red-600 to-red-700 hover:from-red-500 hover:to-red-600 text-white",
    success: "bg-gradient-to-br from-green-600 to-green-700 hover:from-green-500 hover:to-green-600 text-white",
    warning: "bg-gradient-to-br from-orange-600 to-orange-700 hover:from-orange-500 hover:to-orange-600 text-white",
  };

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`
        ${variantClasses[variant]}
        px-4 py-3 rounded-lg font-semibold
        transition-all duration-200
        active:scale-95
        shadow-lg hover:shadow-xl
        disabled:opacity-50 disabled:cursor-not-allowed
        flex items-center justify-center gap-2
        min-w-[120px]
      `}
    >
      {icon && <span className="w-5 h-5">{icon}</span>}
      <span>{label}</span>
    </button>
  );
};

export default CommandButton;