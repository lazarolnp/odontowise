export type Discipline = { id: string; name: string; active: boolean };
export type Category = Discipline;
export type Product = {
  id: string; name: string; description: string; course: string;
  discipline_id: string; category_id: string; price_cents: number;
  cover_path: string | null; preview_paths: string[]; contents: string[];
  checkout_url: string; status: 'draft' | 'published' | 'inactive';
  featured: boolean; is_new: boolean; created_at: string; demo?: boolean;
};
export type Settings = { id: number; brand_name: string; logo_path: string | null; contact_email: string; instagram_url: string; whatsapp_url: string; about: string };
