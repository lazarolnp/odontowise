import { z } from 'zod';
export function safeHttps(value: string): boolean {
  try { const u = new URL(value); return u.protocol === 'https:' && !u.username && !u.password && u.hostname.includes('.') && !/^(localhost|127\.|0\.|\[|10\.|192\.168\.|169\.254\.)/i.test(u.hostname); } catch { return false; }
}
export const productSchema = z.object({
  name: z.string().trim().min(3, 'Informe um nome com pelo menos 3 caracteres.').max(160),
  description: z.string().trim().min(20, 'A descrição deve ter pelo menos 20 caracteres.').max(10000),
  course: z.string().trim().min(2).max(120), discipline_id: z.uuid('Escolha uma disciplina.'), category_id: z.uuid('Escolha uma categoria.'),
  price_cents: z.number().int().min(100, 'O preço mínimo é R$ 1,00.').max(1000000),
  checkout_url: z.string().max(2000).refine(safeHttps, 'Informe um link HTTPS válido para o checkout.'),
  contents: z.array(z.string().trim().min(1).max(300)).min(1, 'Informe pelo menos um conteúdo.').max(100),
  status: z.enum(['draft','published','inactive']), featured: z.boolean(), is_new: z.boolean(),
});
export function parsePrice(value: string) {
  const normalized = value.trim().replace(',', '.');
  if (!/^\d+(\.\d{1,2})?$/.test(normalized)) return NaN;
  return Math.round(Number(normalized) * 100);
}
export async function validateFile(file: File, type: 'pdf' | 'image') {
  const max = type === 'pdf' ? 50 * 1024 * 1024 : 5 * 1024 * 1024;
  if (file.size > max) throw new Error(type === 'pdf' ? 'O PDF deve ter no máximo 50 MB.' : 'A imagem deve ter no máximo 5 MB.');
  const bytes = new Uint8Array(await file.slice(0, 12).arrayBuffer());
  if (type === 'pdf') { if (String.fromCharCode(...bytes.slice(0,5)) !== '%PDF-') throw new Error('Selecione um arquivo PDF válido.'); }
  else if (!((bytes[0] === 0xff && bytes[1] === 0xd8 && file.type === 'image/jpeg') || (bytes[0] === 137 && bytes[1] === 80 && file.type === 'image/png') || (String.fromCharCode(...bytes.slice(0,4)) === 'RIFF' && String.fromCharCode(...bytes.slice(8,12)) === 'WEBP' && file.type === 'image/webp'))) throw new Error('Use uma imagem JPG, PNG ou WebP válida.');
}
