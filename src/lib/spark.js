import { createClient } from './spark-client.js';

export const spark = createClient(import.meta.env.VITE_API_URL || 'https://api.heyitsmejosh.com');
