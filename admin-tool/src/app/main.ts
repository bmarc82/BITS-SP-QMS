/**
 * Admin Tool – Einstiegspunkt
 * QMS M365 | Version 1.0.0
 */

import { app } from './app.module';
import { router } from './routes';

app.init();
router.navigate('/dashboard');
