import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';
import { ChevronLeft, ChevronRight, X } from 'lucide-react';

interface ImageLightboxProps {
  src: string;
  alt: string;
  open: boolean;
  onClose: () => void;
  closeAriaLabel?: string;
  onPrevious?: () => void;
  onNext?: () => void;
  positionLabel?: string;
  hideNavigationControls?: boolean;
  edgeToEdge?: boolean;
  pagination?: { currentIndex: number; total: number; onSelect: (index: number) => void };
  peekPreviousSrc?: string;
  peekNextSrc?: string;
}

export function ImageLightbox({ src, alt, open, onClose, closeAriaLabel = 'Tutup', onPrevious, onNext, positionLabel, hideNavigationControls = false, edgeToEdge = false, pagination, peekPreviousSrc, peekNextSrc }: ImageLightboxProps) {
  const touchStart = useRef<{ x: number; y: number } | null>(null);
  const pointerStart = useRef<{ x: number; y: number } | null>(null);
  const slidingRef = useRef(false);
  const transitionTimeoutRef = useRef<number | null>(null);
  const [slideOffset, setSlideOffset] = useState(0);
  const [sliding, setSliding] = useState(false);
  const showPagination = Boolean(pagination && pagination.total > 1);
  const showSwipeCarousel = edgeToEdge && showPagination && Boolean(peekPreviousSrc || peekNextSrc);
  const imageHeightClass = showPagination
    ? 'max-h-[calc(100dvh-8rem)] sm:max-h-[calc(100dvh-9rem)]'
    : 'max-h-[calc(100dvh-2rem)] sm:max-h-[calc(100dvh-3rem)]';

  useLayoutEffect(() => {
    slidingRef.current = false;
    if (transitionTimeoutRef.current !== null) window.clearTimeout(transitionTimeoutRef.current);
    transitionTimeoutRef.current = null;
    setSlideOffset(0);
    setSliding(false);
  }, [src]);

  useEffect(() => () => {
    if (transitionTimeoutRef.current !== null) window.clearTimeout(transitionTimeoutRef.current);
  }, []);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      if (e.key === 'ArrowLeft') onPrevious?.();
      if (e.key === 'ArrowRight') onNext?.();
    };
    window.addEventListener('keydown', onKey);
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => {
      window.removeEventListener('keydown', onKey);
      document.body.style.overflow = prev;
    };
  }, [open, onClose, onNext, onPrevious]);

  if (!open) return null;

  function requestSlide(direction: -1 | 1) {
    if (slidingRef.current) return;
    const canMove = direction < 0 ? onPrevious : onNext;
    if (!canMove) return;
    if (!showSwipeCarousel) {
      canMove();
      return;
    }
    slidingRef.current = true;
    setSlideOffset(direction);
    setSliding(true);
    transitionTimeoutRef.current = window.setTimeout(() => finishSlide(direction), 360);
  }

  function finishSlide(direction: -1 | 1) {
    if (!slidingRef.current) return;
    slidingRef.current = false;
    if (transitionTimeoutRef.current !== null) window.clearTimeout(transitionTimeoutRef.current);
    transitionTimeoutRef.current = null;
    if (direction < 0) onPrevious?.();
    else onNext?.();
  }

  function handleTouchEnd(event: React.TouchEvent<HTMLDivElement>) {
    const start = touchStart.current;
    touchStart.current = null;
    const touch = event.changedTouches[0];
    if (!start || !touch) return;
    const deltaX = touch.clientX - start.x;
    const deltaY = touch.clientY - start.y;
    if (Math.abs(deltaX) < 50 || Math.abs(deltaX) < Math.abs(deltaY)) return;
    if (deltaX < 0) requestSlide(1);
    else requestSlide(-1);
  }

  function handlePointerEnd(event: React.PointerEvent<HTMLDivElement>) {
    const start = pointerStart.current;
    pointerStart.current = null;
    if (!start || event.pointerType !== 'mouse') return;
    const deltaX = event.clientX - start.x;
    const deltaY = event.clientY - start.y;
    if (Math.abs(deltaX) < 50 || Math.abs(deltaX) < Math.abs(deltaY)) return;
    if (deltaX < 0) requestSlide(1);
    else requestSlide(-1);
  }

  function handleTrackTransitionEnd(event: React.TransitionEvent<HTMLDivElement>) {
    if (event.propertyName !== 'transform') return;
    finishSlide(slideOffset < 0 ? -1 : 1);
  }

  return createPortal(
    <div
      className={`fixed inset-0 z-[1000] overflow-auto overscroll-contain bg-slate-950/85 ${showSwipeCarousel ? 'px-0' : 'px-3'} py-[calc(1rem+env(safe-area-inset-top))] pb-[calc(1rem+env(safe-area-inset-bottom))] backdrop-blur-sm animate-fade-in sm:p-6`}
      onClick={onClose}
      role="dialog"
      aria-modal="true"
    >
      <button
        onClick={onClose}
        aria-label={closeAriaLabel}
        className="fixed right-3 top-[calc(0.75rem+env(safe-area-inset-top))] z-10 flex h-11 w-11 items-center justify-center rounded-full bg-white/15 text-white backdrop-blur transition hover:bg-white/25 focus:outline-none focus:ring-2 focus:ring-white/50 sm:right-5 sm:top-5"
      >
        <X className="h-6 w-6" />
      </button>
      {positionLabel && <span className="fixed left-1/2 top-[calc(0.9rem+env(safe-area-inset-top))] z-10 -translate-x-1/2 rounded-full bg-white/15 px-3 py-1.5 text-sm font-semibold text-white backdrop-blur">{positionLabel}</span>}
      {!hideNavigationControls && onPrevious && (
        <button
          type="button"
          onClick={(event) => { event.stopPropagation(); onPrevious(); }}
          aria-label="Foto sebelumnya"
          className="fixed left-2 top-1/2 z-10 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-full bg-white/15 text-white backdrop-blur transition hover:bg-white/25 focus:outline-none focus:ring-2 focus:ring-white/50 sm:left-5"
        >
          <ChevronLeft className="h-6 w-6" />
        </button>
      )}
      {!hideNavigationControls && onNext && (
        <button
          type="button"
          onClick={(event) => { event.stopPropagation(); onNext(); }}
          aria-label="Foto berikutnya"
          className="fixed right-2 top-1/2 z-10 flex h-11 w-11 -translate-y-1/2 items-center justify-center rounded-full bg-white/15 text-white backdrop-blur transition hover:bg-white/25 focus:outline-none focus:ring-2 focus:ring-white/50 sm:right-5"
        >
          <ChevronRight className="h-6 w-6" />
        </button>
      )}
      <div className={`flex min-h-full min-w-full items-center justify-center py-2 sm:py-0 ${showPagination ? 'flex-col gap-3 py-14' : ''}`}>
        <div
          onClick={(e) => e.stopPropagation()}
          onTouchStart={(event) => {
            const touch = event.touches[0];
            if (touch) touchStart.current = { x: touch.clientX, y: touch.clientY };
          }}
          onTouchEnd={handleTouchEnd}
          onPointerDown={(event) => {
            if (event.pointerType === 'mouse') pointerStart.current = { x: event.clientX, y: event.clientY };
          }}
          onPointerUp={handlePointerEnd}
          onPointerCancel={() => { pointerStart.current = null; }}
          className={`relative flex ${showSwipeCarousel ? 'w-full overflow-hidden' : 'max-w-full overflow-auto'} ${imageHeightClass} items-center justify-center overscroll-contain shadow-2xl ${edgeToEdge ? '' : 'rounded-lg'} ${onPrevious || onNext ? 'cursor-grab active:cursor-grabbing' : ''}`}
        >
          {showSwipeCarousel ? (
            <div
              onTransitionEnd={handleTrackTransitionEnd}
              className="flex w-[300%] shrink-0"
              style={{
                transform: `translateX(-${((slideOffset + 1) / 3) * 100}%)`,
                transition: sliding ? 'transform 320ms cubic-bezier(0.22, 0.61, 0.36, 1)' : 'none',
              }}
            >
              {[peekPreviousSrc, src, peekNextSrc].map((photo, index) => <div key={index} className="flex w-1/3 shrink-0 items-center justify-center"><img src={photo} alt={index === 1 ? alt : ''} aria-hidden={index !== 1} className={`block h-auto w-auto ${imageHeightClass} max-w-[calc(100vw-1.5rem)] select-none object-contain sm:max-w-[calc(100vw-3rem)]`} /></div>)}
            </div>
          ) : (
            <img
              src={src}
              alt={alt}
              className={`block h-auto w-auto ${imageHeightClass} max-w-[calc(100vw-1.5rem)] select-none object-contain animate-scale-in touch-pan-x touch-pan-y sm:max-w-[calc(100vw-3rem)] ${edgeToEdge ? '' : 'rounded-lg'}`}
            />
          )}
        </div>
        {showPagination && pagination && (
          <div className="flex items-center justify-center gap-2" role="group" aria-label="Pilih foto dokumentasi" onClick={(event) => event.stopPropagation()}>
            {Array.from({ length: pagination.total }, (_, index) => <button key={index} type="button" onClick={() => pagination.onSelect(index)} aria-label={`Tampilkan foto ${index + 1} dari ${pagination.total}`} aria-current={index === pagination.currentIndex ? 'true' : undefined} className={`h-1.5 rounded-full transition-all duration-200 ${index === pagination.currentIndex ? 'w-2.5 bg-white' : 'w-1.5 bg-white/45 hover:bg-white/75'}`} />)}
          </div>
        )}
      </div>
    </div>
    , document.body,
  );
}
