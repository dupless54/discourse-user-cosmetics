const REDUCED_MOTION_QUERY = "(prefers-reduced-motion: reduce)";

export function prefersReducedMotion() {
  return globalThis.matchMedia?.(REDUCED_MOTION_QUERY)?.matches === true;
}

export { REDUCED_MOTION_QUERY };
