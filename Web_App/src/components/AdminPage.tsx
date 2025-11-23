import React from "react";
import {ArrowLeft} from 'lucide-react';
import AltAdminPanel from "./AltAdminPanel";

interface AdminPageProps {
  onBack: () => void;
}

const AdminPage: React.FC<AdminPageProps> = ({ onBack }) => {

  return (
    <div className="h-screen flex flex-col bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950">
      {/* Header */}
      <div className="bg-slate-900/80 border-b border-slate-700 p-4">
        <div className="flex items-center gap-4">
          <button
            onClick={onBack}
            className="flex items-center gap-2 text-gray-400 hover:text-cyan-400 transition-colors duration-200"
          >
            <ArrowLeft className="w-5 h-5" />
            <span className="font-medium">Retour</span>
          </button>
          <h1 className="text-2xl font-bold bg-gradient-to-r from-cyan-400 to-purple-500 bg-clip-text text-transparent">
            Administration des ALTs
          </h1>
        </div>
      </div>

      {/* Content - Split View */}
      <div className="flex-1 flex flex-col md:flex-row overflow-hidden">
        {/* ALT 1 Panel */}
        <div className="flex-1 border-b md:border-b-0 md:border-r border-slate-700">
          <AltAdminPanel altNumber={1} />
        </div>

        {/* ALT 2 Panel */}
        <div className="flex-1">
          <AltAdminPanel altNumber={2} />
        </div>
      </div>
    </div>
  );
};

export default AdminPage;