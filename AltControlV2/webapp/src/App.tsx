import React, { useState, useEffect } from 'react';
import Home from './components/Home';
import AltController from './components/AltController';
import { backendService } from './services/backendService';

function App() {
  const [currentView, setCurrentView] = useState<'home' | 'control'>('home');
  const [selectedAlts, setSelectedAlts] = useState<string[]>([]);

  useEffect(() => {
    // Initialiser SocketIO au démarrage
    backendService.initSocketIO({
      onConnection: (status) => {
        console.log('[App] Connection status:', status);
      }
    });

    return () => {
      backendService.closeSocketIO();
    };
  }, []);

  const handleLaunch = (alts: string[]) => {
    console.log('[App] Launching with ALTs:', alts);
    setSelectedAlts(alts);
    setCurrentView('control');
  };

  const handleBack = () => {
    setCurrentView('home');
    setSelectedAlts([]);
  };

  return (
    <>
      {currentView === 'home' && (
        <Home onLaunch={handleLaunch} />
      )}
      {currentView === 'control' && (
        <div className="h-screen bg-slate-950 flex flex-col">
          {/* Header */}
          <div className="bg-slate-900 border-b border-slate-700 p-4">
            <div className="flex items-center justify-between">
              <h1 className="text-2xl font-bold text-cyan-400">FFXI ALT Control V2</h1>
              <button
                onClick={handleBack}
                className="bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded-lg"
              >
                ← Back
              </button>
            </div>
          </div>

          {/* Controllers Grid */}
          <div className="flex-1 grid grid-cols-1 md:grid-cols-2 gap-4 p-4 overflow-hidden">
            {selectedAlts.map((altName, index) => (
              <AltController
                key={altName}
                altId={index + 1}
                altName={altName}
              />
            ))}
          </div>
        </div>
      )}
    </>
  );
}

export default App;
