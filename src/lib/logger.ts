const isDev = import.meta.env.DEV;

export const logger = {
  debug(message: string): void {
    if (isDev) console.debug(`[debug] ${message}`);
  },
  info(message: string): void {
    console.info(`[info] ${message}`);
  },
  warn(message: string): void {
    console.warn(`[warn] ${message}`);
  },
  error(message: string): void {
    console.error(`[error] ${message}`);
  },
};
