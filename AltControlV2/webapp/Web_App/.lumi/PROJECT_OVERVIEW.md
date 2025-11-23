# FFXI ALT CONTROL

**Description**: Application web de contrôle à distance pour personnages ALT dans FFXI, connectée à un serveur Python local avec WebSocket temps réel

**Tech Stack**: React + TypeScript + Vite + Tailwind CSS | Backend: Python REST API + WebSocket | Storage: localStorage

## User Preferences
- **Language**: Français/English
- **Code Style**: TypeScript strict, modular services, robust synchronization
- **Design System**: Custom gradient UI with status indicators

## Directory Structure
- `/src/components`: UI components (Home, Admin, AltController, CommandButton, DirectionalPad)
- `/src/services`: Backend communication (backendService, configService)
- `/src/types`: TypeScript interfaces (backend.ts for all JSON data structures)
- `/src/utils`: Legacy utilities (being migrated to services)
- `/src/data`: Mock game data (fallback)

## Current Features

### Implemented
1. **Home Page**: Launch Control + Admin ALTs buttons with branding
2. **Admin Configuration**: Split-view panel to configure ALT 1 & ALT 2
   - Select spells, weapon skills, macros (gray/green toggle)
   - Save configurations per ALT/Job/SubJob in localStorage
   - Real-time sync with Launch Control
3. **Launch Control**: Dual ALT controllers with:
   - Real-time backend data (alt_name, jobs, levels, weapon, pet, stats)
   - WebSocket connection status (connected/reconnecting/disconnected)
   - Filtered commands based on admin configuration
   - POST /command endpoint: `{ "altName": "...", "action": "/ma \"Cure\" <t>" }`
   - Full party member targeting for support spells
   - Job abilities, pet commands (auto-included)
   - Macros execution
   - Fixed directional pad at bottom
4. **Backend Integration**:
   - REST API: GET /api/alts, POST /command
   - WebSocket: Real-time updates for status, stats, party changes
   - Full JSON data support: spells (typed), WS, macros, pet commands, party members
5. **Synchronization**: configService ensures admin changes immediately reflect in control

### Known Limitations
- Backend URL hardcoded (localhost:5000) - needs configuration
- Mock data fallback when server unavailable
- No error toast notifications yet

## Database Schema
**Type**: localStorage (client-side)

### `ffxi_alt_configs_v2`
```typescript
{
  [key: string]: {
    alt_name: string,
    main_job: string,
    sub_job: string,
    selected_spells: string[],
    selected_weapon_skills: string[],
    selected_macros: string[],
    last_updated: number
  }
}
```

## Deno Functions
N/A - Uses Python backend server

## API Endpoints
### Backend Python Server (localhost:5000)
- `GET /api/alts`: Fetch all ALT data with complete JSON
- `GET /api/alts/:altName`: Fetch specific ALT data
- `POST /command`: Send command `{ altName: string, action: string }`
- `WS /ws`: WebSocket for real-time updates

**Lumi SDK Tools Used**: None (standalone app)

## Improvement Opportunities

### High Priority
- [ ] Configure backend URL from settings page
- [ ] Add toast notifications for command success/errors
- [ ] Display command execution feedback
- [ ] Add reconnection logic with exponential backoff

### Medium Priority
- [ ] Add HP/MP/TP bars visualization
- [ ] Combat log display
- [ ] Keyboard shortcuts for quick commands
- [ ] Export/import configurations

### Low Priority / Future Enhancements
- [ ] Multi-language support (EN/FR toggle)
- [ ] Dark/light theme toggle
- [ ] Custom macro builder UI
- [ ] Command history and favorites