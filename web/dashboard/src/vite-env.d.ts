/// <reference types="vite/client" />

import type { VisualPayload } from './types/payload';

declare global {
  interface Window {
    __BLASTRADIUS_PAYLOAD__?: VisualPayload;
  }
}

export {};
