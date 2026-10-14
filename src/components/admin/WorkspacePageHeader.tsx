import type { ReactNode } from 'react';

export function WorkspacePageHeader({ title, subtitle, eyebrow = 'Open Mic Workspace', action }: {
  title: string;
  subtitle: string;
  eyebrow?: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex items-start justify-between gap-4 rounded-[22px] border border-blue-500 bg-gradient-to-br from-blue-700 via-blue-600 to-sky-500 p-4 text-white shadow-[0_10px_24px_rgba(215,25,32,0.2)] sm:p-5">
      <div className="min-w-0">
        <p className="!text-blue-100 text-[10px] font-extrabold uppercase tracking-[0.16em] sm:text-[11px]">{eyebrow}</p>
        <h1 className="!text-white mt-1.5 text-xl font-black tracking-tight sm:text-2xl">{title}</h1>
        <p className="!text-blue-50 mt-1 text-xs font-medium leading-5 sm:text-sm">{subtitle}</p>
      </div>
      {action}
    </div>
  );
}