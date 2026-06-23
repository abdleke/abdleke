import { useTranslation } from 'react-i18next';
import { AlertTriangle } from 'lucide-react';

interface ConfirmDialogProps {
  open: boolean;
  message: string;
  onConfirm: () => void;
  onCancel: () => void;
}

export default function ConfirmDialog({ open, message, onConfirm, onCancel }: ConfirmDialogProps) {
  const { t } = useTranslation();
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50" onClick={onCancel} />
      <div className="relative bg-white rounded-2xl shadow-xl p-6 max-w-sm w-full">
        <div className="flex flex-col items-center text-center gap-4">
          <div className="w-14 h-14 bg-rose-100 rounded-full flex items-center justify-center">
            <AlertTriangle className="text-rose-500" size={28} />
          </div>
          <p className="text-slate-700 font-medium">{message}</p>
          <div className="flex gap-3 w-full">
            <button onClick={onCancel} className="flex-1 btn-secondary justify-center">
              {t('common.cancel')}
            </button>
            <button onClick={onConfirm} className="flex-1 btn-danger justify-center">
              {t('common.confirm')}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
