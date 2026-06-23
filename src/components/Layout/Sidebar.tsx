import { NavLink } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  LayoutDashboard, FolderOpen, Users, CreditCard,
  Bell, BarChart3, X,
} from 'lucide-react';

interface SidebarProps {
  open: boolean;
  onClose: () => void;
}

const navItems = [
  { to: '/', icon: LayoutDashboard, key: 'nav.dashboard' },
  { to: '/projets', icon: FolderOpen, key: 'nav.projects' },
  { to: '/membres', icon: Users, key: 'nav.members' },
  { to: '/cotisations', icon: CreditCard, key: 'nav.cotisations' },
  { to: '/rappels', icon: Bell, key: 'nav.reminders' },
  { to: '/rapports', icon: BarChart3, key: 'nav.reports' },
];

export default function Sidebar({ open, onClose }: SidebarProps) {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';

  return (
    <>
      {/* Overlay */}
      {open && (
        <div
          className="fixed inset-0 bg-black/40 z-20 lg:hidden"
          onClick={onClose}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`
          fixed top-0 h-full w-64 z-30 flex flex-col
          bg-gradient-to-b from-primary-700 via-primary-800 to-primary-900
          transition-transform duration-300 ease-in-out
          ${isRTL ? 'right-0' : 'left-0'}
          ${open ? 'translate-x-0' : isRTL ? 'translate-x-full lg:translate-x-0' : '-translate-x-full lg:translate-x-0'}
        `}
      >
        {/* Logo */}
        <div className="flex items-center justify-between px-6 py-5 border-b border-white/10">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
              <span className="text-white font-bold text-lg">ج</span>
            </div>
            <div>
              <div className="text-white font-bold text-lg leading-tight">{t('app.name')}</div>
              <div className="text-white/50 text-xs">{t('app.tagline')}</div>
            </div>
          </div>
          <button
            onClick={onClose}
            className="lg:hidden text-white/60 hover:text-white p-1"
          >
            <X size={20} />
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
          {navItems.map(({ to, icon: Icon, key }) => (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              onClick={onClose}
              className={({ isActive }) =>
                `sidebar-link ${isActive ? 'active' : ''}`
              }
            >
              <Icon size={20} className="shrink-0" />
              <span className="text-sm font-medium">{t(key)}</span>
            </NavLink>
          ))}
        </nav>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-white/10">
          <p className="text-white/30 text-xs text-center">
            جمعيتي v1.0
          </p>
        </div>
      </aside>
    </>
  );
}
