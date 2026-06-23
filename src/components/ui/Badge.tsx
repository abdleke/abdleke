interface BadgeProps {
  variant: 'success' | 'warning' | 'danger' | 'info' | 'neutral' | 'purple';
  children: React.ReactNode;
  size?: 'sm' | 'md';
}

const variants = {
  success: 'bg-emerald-100 text-emerald-700 border-emerald-200',
  warning: 'bg-amber-100 text-amber-700 border-amber-200',
  danger: 'bg-rose-100 text-rose-700 border-rose-200',
  info: 'bg-cyan-100 text-cyan-700 border-cyan-200',
  neutral: 'bg-slate-100 text-slate-600 border-slate-200',
  purple: 'bg-primary-100 text-primary-700 border-primary-200',
};

export default function Badge({ variant, children, size = 'sm' }: BadgeProps) {
  return (
    <span className={`
      inline-flex items-center border rounded-full font-medium
      ${size === 'sm' ? 'px-2.5 py-0.5 text-xs' : 'px-3 py-1 text-sm'}
      ${variants[variant]}
    `}>
      {children}
    </span>
  );
}
