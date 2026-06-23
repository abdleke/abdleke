import { Menu, Globe, ChevronDown } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { useState, useRef, useEffect } from 'react';
import { useApp } from '../../context/AppContext';

const LANGS = [
  { code: 'ar', label: 'العربية', flag: '🇩🇿' },
  { code: 'fr', label: 'Français', flag: '🇫🇷' },
  { code: 'en', label: 'English', flag: '🇬🇧' },
];

interface HeaderProps {
  onMenuClick: () => void;
}

export default function Header({ onMenuClick }: HeaderProps) {
  const { t, i18n } = useTranslation();
  const { state, dispatch, currentUser } = useApp();
  const [langOpen, setLangOpen] = useState(false);
  const [userOpen, setUserOpen] = useState(false);
  const langRef = useRef<HTMLDivElement>(null);
  const userRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (langRef.current && !langRef.current.contains(e.target as Node)) setLangOpen(false);
      if (userRef.current && !userRef.current.contains(e.target as Node)) setUserOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const currentLang = LANGS.find(l => l.code === i18n.language) ?? LANGS[0];
  const activeMembers = state.members.filter(m => m.statut === 'actif');

  const initials = currentUser ? `${currentUser.prenom[0]}${currentUser.nom[0]}` : '—';
  const roleLabel = currentUser ? t(`members.roles.${currentUser.role}`) : '';

  return (
    <header className="h-16 bg-white border-b border-slate-100 flex items-center justify-between px-4 lg:px-6 shrink-0">
      {/* Left: hamburger */}
      <button
        onClick={onMenuClick}
        className="lg:hidden p-2 rounded-lg text-slate-500 hover:bg-slate-100 transition-colors"
      >
        <Menu size={20} />
      </button>

      <div className="hidden lg:block" />

      {/* Right: lang + user */}
      <div className="flex items-center gap-3">
        {/* Language switcher */}
        <div ref={langRef} className="relative">
          <button
            onClick={() => setLangOpen(v => !v)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-slate-600 hover:bg-slate-100 transition-colors text-sm font-medium"
          >
            <Globe size={16} />
            <span>{currentLang.flag} {currentLang.label}</span>
            <ChevronDown size={14} className={`transition-transform ${langOpen ? 'rotate-180' : ''}`} />
          </button>
          {langOpen && (
            <div className="absolute top-full mt-1 end-0 bg-white rounded-xl shadow-lg border border-slate-100 py-1 min-w-[140px] z-50">
              {LANGS.map(l => (
                <button
                  key={l.code}
                  onClick={() => { i18n.changeLanguage(l.code); setLangOpen(false); }}
                  className={`w-full text-start px-4 py-2 text-sm hover:bg-slate-50 flex items-center gap-2 ${i18n.language === l.code ? 'text-primary-600 font-semibold' : 'text-slate-700'}`}
                >
                  <span>{l.flag}</span> {l.label}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* User switcher */}
        <div ref={userRef} className="relative">
          <button
            onClick={() => setUserOpen(v => !v)}
            className="flex items-center gap-2 px-3 py-1.5 rounded-lg hover:bg-slate-100 transition-colors"
          >
            <div className="w-8 h-8 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center text-xs font-bold">
              {initials}
            </div>
            <div className="hidden sm:block text-start">
              <div className="text-sm font-medium text-slate-800 leading-tight">
                {currentUser ? `${currentUser.prenom} ${currentUser.nom}` : '—'}
              </div>
              <div className="text-xs text-slate-400">{roleLabel}</div>
            </div>
            <ChevronDown size={14} className={`text-slate-400 transition-transform ${userOpen ? 'rotate-180' : ''}`} />
          </button>
          {userOpen && (
            <div className="absolute top-full mt-1 end-0 bg-white rounded-xl shadow-lg border border-slate-100 py-1 min-w-[200px] z-50">
              <div className="px-4 py-2 border-b border-slate-100">
                <p className="text-xs text-slate-400">{t('common.switchUser')}</p>
              </div>
              {activeMembers.map(m => (
                <button
                  key={m.id}
                  onClick={() => { dispatch({ type: 'SET_USER', payload: m.id }); setUserOpen(false); }}
                  className={`w-full text-start px-4 py-2.5 text-sm hover:bg-slate-50 flex items-center gap-3 ${state.currentUserId === m.id ? 'text-primary-600 bg-primary-50' : 'text-slate-700'}`}
                >
                  <div className="w-7 h-7 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center text-xs font-bold shrink-0">
                    {m.prenom[0]}{m.nom[0]}
                  </div>
                  <div>
                    <div className="font-medium leading-tight">{m.prenom} {m.nom}</div>
                    <div className="text-xs text-slate-400">{t(`members.roles.${m.role}`)}</div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
