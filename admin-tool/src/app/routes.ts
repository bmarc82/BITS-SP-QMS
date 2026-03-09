/**
 * Navigation / Routing
 */

export const routes = [
  { path: '/dashboard',   label: 'Dashboard' },
  { path: '/connection',  label: 'Verbindung' },
  { path: '/installer',   label: 'Installation' },
  { path: '/maintenance', label: 'Wartung' },
];

export const router = {
  navigate(path: string) {
    console.log(`Navigiere zu: ${path}`);
  }
};
