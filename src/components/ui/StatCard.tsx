import type { LucideIcon } from 'lucide-react';

interface StatCardProps {
  label: string;
  value: string | number;
  icon: LucideIcon;
  color: 'violet' | 'emerald' | 'amber' | 'cyan' | 'rose';
  sub?: string;
}

const colors = {
  violet: { bg: 'bg-primary-50', icon: 'bg-primary-600', text: 'text-primary-700', val: 'text-primary-900' },
  emerald: { bg: 'bg-emerald-50', icon: 'bg-emerald-500', text: 'text-emerald-700', val: 'text-emerald-900' },
  amber: { bg: 'bg-amber-50', icon: 'bg-amber-400', text: 'text-amber-700', val: 'text-amber-900' },
  cyan: { bg: 'bg-cyan-50', icon: 'bg-cyan-500', text: 'text-cyan-700', val: 'text-cyan-900' },
  rose: { bg: 'bg-rose-50', icon: 'bg-rose-500', text: 'text-rose-700', val: 'text-rose-900' },
};

export default function StatCard({ label, value, icon: Icon, color, sub }: StatCardProps) {
  const c = colors[color];
  return (
    <div className={`card ${c.bg} border-0`}>
      <div className="flex items-start justify-between">
        <div>
          <p className={`text-sm font-medium ${c.text}`}>{label}</p>
          <p className={`text-3xl font-bold mt-1 ${c.val}`}>{value}</p>
          {sub && <p className={`text-xs mt-1 ${c.text} opacity-75`}>{sub}</p>}
        </div>
        <div className={`w-12 h-12 rounded-xl ${c.icon} flex items-center justify-center`}>
          <Icon size={22} className="text-white" />
        </div>
      </div>
    </div>
  );
}
