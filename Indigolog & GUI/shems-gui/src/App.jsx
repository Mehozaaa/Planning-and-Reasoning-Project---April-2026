import React, { useState, useEffect, useRef } from 'react';
import { 
  Sun, Moon, Cloud, Battery, Zap, Thermometer, 
  AlertTriangle, Power, CloudRain, TrendingUp,
  Wind, Droplets, Monitor, Clock, CheckCircle2,
  DollarSign, Lightbulb, PlaySquare, RotateCcw
} from 'lucide-react';

export default function App() {
  // --- 1. INITIAL STATE (Matching shems_bat.pl s0) ---
  const [batteryLevel, setBatteryLevel] = useState(0); // Max 25
  const [gridPrice, setGridPrice] = useState(20);
  const [indoorTemp, setIndoorTemp] = useState(18);
  const [timeOfDay, setTimeOfDay] = useState(8);
  const [hoursPassed, setHoursPassed] = useState(0);
  
  // Relational Fluents
  const [sunny, setSunny] = useState(true);
  const [fridgeOn, setFridgeOn] = useState(false);
  const [lightsOn, setLightsOn] = useState(false);
  const [washerDone, setWasherDone] = useState(false);
  const [ovenDone, setOvenDone] = useState(false);
  const [priceSpikeActive, setPriceSpikeActive] = useState(false);
  
  // UI Only (Tracking for visual feedback)
  const [hvacRunning, setHvacRunning] = useState(false);
  const [isAgentActive, setIsAgentActive] = useState(false);
  
  // Terminal Logs
  const [logs, setLogs] = useState([
    { time: new Date().toLocaleTimeString(), msg: 'System Initialized to s0. Awaiting Agent Start.', type: 'info' }
  ]);
  const logEndRef = useRef(null);

  const addLog = (msg, type = 'info') => {
    setLogs(prev => [...prev, { time: new Date().toLocaleTimeString(), msg, type }]);
  };

  useEffect(() => {
    logEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [logs]);

  // --- 2. INDIGOLOG CONTROL_HOME LOOP ---
  useEffect(() => {
    if (!isAgentActive) return;

    const tick = setInterval(() => {
      // STOP CONDITION: If 24 hours have passed, exit the loop
      if (hoursPassed >= 24) {
        addLog('[SIMULATION COMPLETE] 24 Hours have passed. Agent halted.', 'warn');
        setIsAgentActive(false);
        return;
      }

      let currentBat = batteryLevel;
      let currentTemp = indoorTemp;
      let currentSunny = sunny;
      let isHvacRunningThisHour = false;
      let actionsTaken = [];

      // 1. Critical Loads
      if (!fridgeOn && currentBat > 4) {
        actionsTaken.push('turn_on_fridge');
        setFridgeOn(true);
        currentBat -= 5;
      }
      if (!lightsOn && currentBat > 4) {
        actionsTaken.push('turn_on_lights');
        setLightsOn(true);
        currentBat -= 5;
      }

      // 2. Heating
      if (currentTemp < 21 && currentBat > 4) {
        actionsTaken.push('run_hvac');
        currentTemp = Math.min(25, currentTemp + 3); // Based on hvac_heat table
        currentBat -= 5;
        isHvacRunningThisHour = true;
      } else {
        // Natural cooling so HVAC has a reason to trigger later 
        currentTemp = Math.max(15, currentTemp - 1); 
      }

      // 3. Shiftable Loads
      if (!washerDone && currentBat > 9) {
        actionsTaken.push('run_washer');
        setWasherDone(true);
        currentBat -= 10;
      }
      if (!ovenDone && currentBat > 9) {
        actionsTaken.push('run_oven');
        setOvenDone(true);
        currentBat -= 10;
      }

      // 4. Charging
      if (currentSunny && currentBat < 21) {
        actionsTaken.push('charge_solar');
        currentBat += 5;
      }
      if (!currentSunny && currentBat < 16 && gridPrice < 30) {
        actionsTaken.push('charge_grid');
        currentBat += 10;
      }

      // 5. Advance Time
      actionsTaken.push('advance_time');
      const nextHour = hoursPassed + 1;
      const nextTimeOfDay = (timeOfDay + 1) % 24;

      // BAT Rules: Advance time effects (Environment changes based on time)
      if (timeOfDay === 18 && currentSunny) {
        currentSunny = false; // causes_false(advance_time, sunny, time_of_day = 18)
        actionsTaken.push('[Env] Sun set');
      } else if (timeOfDay === 6 && !currentSunny) {
        currentSunny = true; // Added fix: causes_true(advance_time, sunny, time_of_day = 6)
        actionsTaken.push('[Env] Sun rise');
      }

      // Apply state changes atomically
      setBatteryLevel(currentBat);
      setIndoorTemp(currentTemp);
      setHoursPassed(nextHour);
      setTimeOfDay(nextTimeOfDay);
      setSunny(currentSunny);
      setHvacRunning(isHvacRunningThisHour);

      // Log the sequence of actions executed by the agent this hour
      addLog(`Hr ${hoursPassed}: [${actionsTaken.join(', ')}]`, 'agent');

    }, 2000); // 2 seconds = 1 virtual hour

    return () => clearInterval(tick);
  }, [
    isAgentActive, hoursPassed, timeOfDay, batteryLevel, gridPrice, indoorTemp, 
    sunny, fridgeOn, lightsOn, washerDone, ovenDone
  ]);

  // --- 3. EXOGENOUS ACTIONS ---
  const triggerExog = (event) => {
    if (event === 'cloud_cover_start') {
      setSunny(false);
      addLog('EXOG TRIGGER: cloud_cover_start (Sunny = false)', 'error');
    } else if (event === 'cloud_cover_end') {
      setSunny(true);
      addLog('EXOG TRIGGER: cloud_cover_end (Sunny = true)', 'info');
    } else if (event === 'price_spike_start') {
      setPriceSpikeActive(true);
      setGridPrice(30);
      addLog('EXOG TRIGGER: price_spike_start (Grid Price = 30)', 'error');
    } else if (event === 'price_spike_end') {
      setPriceSpikeActive(false);
      const isNight = timeOfDay < 8 || timeOfDay > 19;
      setGridPrice(isNight ? 10 : 20); // Return to default price based on time
      addLog(`EXOG TRIGGER: price_spike_end (Grid Price returned to ${isNight ? 10 : 20})`, 'info');
    }
  };

  const resetSimulation = () => {
    setBatteryLevel(0); setGridPrice(20); setIndoorTemp(18);
    setTimeOfDay(8); setHoursPassed(0); setSunny(true);
    setFridgeOn(false); setLightsOn(false); setWasherDone(false); 
    setOvenDone(false); setPriceSpikeActive(false); setIsAgentActive(false);
    setHvacRunning(false);
    setLogs([{ time: new Date().toLocaleTimeString(), msg: 'Simulation Reset to s0.', type: 'info' }]);
  };

  // UI Helpers
  const formatTime = (tod) => `${tod.toString().padStart(2, '0')}:00`;
  const getBatteryColor = () => {
    if (batteryLevel > 15) return 'text-green-400';
    if (batteryLevel > 5) return 'text-yellow-400';
    return 'text-red-400';
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 p-4 md:p-8 font-sans selection:bg-blue-500/30">
      
      {/* Header */}
      <header className="flex flex-col md:flex-row justify-between items-center mb-6 bg-slate-800 p-6 rounded-2xl border border-slate-700 shadow-xl shadow-black/20">
        <div className="flex items-center gap-4">
          <div className="p-3 bg-blue-500/20 text-blue-400 rounded-xl"><Clock size={32} /></div>
          <div>
            <h1 className="text-2xl font-bold text-white tracking-tight">IndiGolog SHEMS</h1>
            <p className="text-slate-400 text-sm">Discrete 24-Hour `control_home` Sequence</p>
          </div>
        </div>
        <div className="flex items-center gap-4 mt-4 md:mt-0">
          <div className="text-right mr-4 text-slate-300">
            <div className="text-sm">Simulation Hour: <span className="font-mono text-white font-bold">{hoursPassed}/24</span></div>
            <div className="text-sm font-bold text-blue-400">Time: {formatTime(timeOfDay)}</div>
          </div>
          <button onClick={resetSimulation} className="p-2 bg-slate-700 hover:bg-slate-600 rounded-lg transition-colors border border-slate-600 shadow-sm" title="Reset Simulation">
            <RotateCcw size={20} />
          </button>
          <button 
            onClick={() => setIsAgentActive(!isAgentActive)}
            disabled={hoursPassed >= 24}
            className={`px-5 py-2.5 rounded-lg font-bold transition-all shadow-lg flex items-center gap-2 ${hoursPassed >= 24 ? 'bg-slate-800 text-slate-500 cursor-not-allowed border-slate-700' : isAgentActive ? 'bg-red-500/20 text-red-400 hover:bg-red-500/30 border border-red-500/30' : 'bg-green-500/20 text-green-400 hover:bg-green-500/30 border border-green-500/30 hover:scale-105'}`}
          >
            {isAgentActive ? 'STOP AGENT' : 'START AGENT'}
          </button>
        </div>
      </header>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
        
        {/* Left Column: Telemetry & Relational Fluents */}
        <div className="lg:col-span-2 space-y-6">
          
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="bg-slate-800 p-5 rounded-2xl border border-slate-700 flex flex-col items-center justify-center shadow-lg shadow-black/10 transition-colors">
              <Battery size={32} className={`${getBatteryColor()} mb-2`} />
              <span className={`text-3xl font-bold ${getBatteryColor()}`}>{batteryLevel} <span className="text-sm font-normal text-slate-400">/ 25</span></span>
              <span className="text-slate-400 text-xs mt-1 font-medium">Battery Level</span>
            </div>
            <div className="bg-slate-800 p-5 rounded-2xl border border-slate-700 flex flex-col items-center justify-center shadow-lg shadow-black/10">
              {sunny ? <Sun size={32} className="text-yellow-400 mb-2" /> : <Moon size={32} className="text-indigo-400 mb-2" />}
              <span className="text-xl font-bold tracking-wide">{sunny ? 'SUNNY' : 'DARK/CLOUDS'}</span>
              <span className="text-slate-400 text-xs mt-1 font-medium">Weather Status</span>
            </div>
            <div className="bg-slate-800 p-5 rounded-2xl border border-slate-700 flex flex-col items-center justify-center shadow-lg shadow-black/10">
              <DollarSign size={32} className={gridPrice > 20 ? 'text-red-400 mb-2' : 'text-emerald-400 mb-2'} />
              <span className={`text-3xl font-bold ${gridPrice > 20 ? 'text-red-400' : 'text-emerald-400'}`}>{gridPrice}</span>
              <span className="text-slate-400 text-xs mt-1 font-medium">Grid Price (¢/kWh)</span>
            </div>
            <div className="bg-slate-800 p-5 rounded-2xl border border-slate-700 flex flex-col items-center justify-center shadow-lg shadow-black/10">
              <Thermometer size={32} className={indoorTemp < 21 ? 'text-blue-400 mb-2' : 'text-orange-400 mb-2'} />
              <span className="text-3xl font-bold">{indoorTemp}°C</span>
              <span className="text-slate-400 text-xs mt-1 font-medium">Indoor Temp</span>
            </div>
          </div>

          <div className="bg-slate-800 rounded-2xl border border-slate-700 overflow-hidden shadow-xl shadow-black/20">
            <div className="p-4 bg-slate-800 border-b border-slate-700">
              <h2 className="text-lg font-semibold flex items-center gap-2"><Monitor size={18} className="text-blue-400"/> Boolean Fluents & Devices</h2>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 divide-y sm:divide-y-0 sm:divide-x divide-slate-700/50">
              <div className="p-5 space-y-5 bg-slate-800/50">
                <div className="flex justify-between items-center group">
                  <div className="flex items-center gap-3"><Monitor size={18} className="text-slate-400 group-hover:text-blue-400 transition-colors"/> <span className="font-medium">Fridge</span></div>
                  <span className={`px-2.5 py-1 text-xs font-bold rounded-md border ${fridgeOn ? 'bg-green-500/20 text-green-400 border-green-500/30' : 'bg-slate-700 text-slate-400 border-slate-600'}`}>{fridgeOn ? 'ON' : 'OFF'}</span>
                </div>
                <div className="flex justify-between items-center group">
                  <div className="flex items-center gap-3"><Lightbulb size={18} className="text-slate-400 group-hover:text-yellow-400 transition-colors"/> <span className="font-medium">Lights</span></div>
                  <span className={`px-2.5 py-1 text-xs font-bold rounded-md border ${lightsOn ? 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30' : 'bg-slate-700 text-slate-400 border-slate-600'}`}>{lightsOn ? 'ON' : 'OFF'}</span>
                </div>
                <div className="flex justify-between items-center group mt-4 pt-4 border-t border-slate-700/50">
                  <div className="flex items-center gap-3"><Wind size={18} className="text-slate-400 group-hover:text-orange-400 transition-colors"/> <span className="font-medium">HVAC (Heater)</span></div>
                  <span className={`px-2.5 py-1 text-xs font-bold rounded-md border ${hvacRunning ? 'bg-orange-500/20 text-orange-400 border-orange-500/30 animate-pulse' : 'bg-slate-700 text-slate-400 border-slate-600'}`}>{hvacRunning ? 'RUNNING' : 'OFF'}</span>
                </div>
              </div>
              <div className="p-5 space-y-5 bg-slate-800/50">
                <div className="flex justify-between items-center group">
                  <div className="flex items-center gap-3"><Droplets size={18} className="text-slate-400 group-hover:text-blue-400 transition-colors"/> <span className="font-medium">Washer</span></div>
                  <span className={`px-2.5 py-1 text-xs font-bold rounded-md border ${washerDone ? 'bg-blue-500/20 text-blue-400 border-blue-500/30' : 'bg-slate-700 text-slate-400 border-slate-600'}`}>{washerDone ? 'DONE' : 'PENDING'}</span>
                </div>
                <div className="flex justify-between items-center group">
                  <div className="flex items-center gap-3"><Power size={18} className="text-slate-400 group-hover:text-red-400 transition-colors"/> <span className="font-medium">Oven</span></div>
                  <span className={`px-2.5 py-1 text-xs font-bold rounded-md border ${ovenDone ? 'bg-blue-500/20 text-blue-400 border-blue-500/30' : 'bg-slate-700 text-slate-400 border-slate-600'}`}>{ovenDone ? 'DONE' : 'PENDING'}</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Right Column: Exogenous Actions */}
        <div className="space-y-6">
          <div className="bg-slate-800 p-6 rounded-2xl border border-slate-700 shadow-xl shadow-black/20">
             <h2 className="text-lg font-semibold mb-6 flex items-center gap-2 text-purple-400"><Zap size={18}/> Exogenous Events</h2>
             
             <div className="space-y-6">
               <div>
                 <span className="text-xs text-slate-400 uppercase font-bold mb-3 block tracking-wider">Weather Anomalies</span>
                 <div className="grid grid-cols-2 gap-3">
                   <button onClick={() => triggerExog('cloud_cover_start')} disabled={!sunny} className="p-2.5 bg-slate-700 hover:bg-slate-600 disabled:opacity-40 text-sm font-medium rounded-lg border border-slate-600 shadow-sm transition-all active:scale-95">Cloud Start</button>
                   <button onClick={() => triggerExog('cloud_cover_end')} disabled={sunny} className="p-2.5 bg-slate-700 hover:bg-slate-600 disabled:opacity-40 text-sm font-medium rounded-lg border border-slate-600 shadow-sm transition-all active:scale-95">Cloud End</button>
                 </div>
               </div>
               
               <div className="border-t border-slate-700 pt-5">
                 <span className="text-xs text-slate-400 uppercase font-bold mb-3 block tracking-wider">Market Fluctuations</span>
                 <div className="grid grid-cols-2 gap-3">
                   <button onClick={() => triggerExog('price_spike_start')} disabled={priceSpikeActive} className="p-2.5 bg-red-500/20 hover:bg-red-500/30 text-red-400 disabled:bg-slate-800 disabled:text-slate-600 text-sm font-medium rounded-lg border border-red-500/30 disabled:border-slate-700 shadow-sm transition-all active:scale-95">Spike Start</button>
                   <button onClick={() => triggerExog('price_spike_end')} disabled={!priceSpikeActive} className="p-2.5 bg-green-500/20 hover:bg-green-500/30 text-green-400 disabled:bg-slate-800 disabled:text-slate-600 text-sm font-medium rounded-lg border border-green-500/30 disabled:border-slate-700 shadow-sm transition-all active:scale-95">Spike End</button>
                 </div>
               </div>
             </div>
          </div>
        </div>
      </div>

      {/* Terminal */}
      <div className="bg-[#0a0a0a] rounded-2xl border border-slate-700 overflow-hidden flex flex-col h-[280px] shadow-2xl shadow-black/40">
        <div className="bg-slate-800/80 backdrop-blur p-3 border-b border-slate-700 flex justify-between items-center text-sm font-mono text-slate-300">
          <span className="flex items-center gap-2"><PlaySquare size={14} className="text-emerald-500"/> Action Execution Sequence Log</span>
        </div>
        <div className="flex-1 p-4 overflow-y-auto font-mono text-[13px] space-y-2">
          {logs.map((log, i) => {
            let colorClass = 'text-slate-400';
            if (log.type === 'error') colorClass = 'text-red-400 font-semibold';
            if (log.type === 'warn') colorClass = 'text-yellow-400 font-semibold';
            if (log.type === 'agent') colorClass = 'text-cyan-300';
            return (
              <div key={i} className={`flex gap-3 ${colorClass} hover:bg-white/5 px-2 py-1.5 rounded transition-colors`}>
                <span className="text-slate-600 shrink-0">[{log.time}]</span><span>{log.msg}</span>
              </div>
            )
          })}
          <div ref={logEndRef} />
        </div>
      </div>
    </div>
  );
}