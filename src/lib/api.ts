import { createClient } from '@supabase/supabase-js';
import type { Product, Discipline, Category, Settings } from '../types';
const url = import.meta.env.VITE_SUPABASE_URL;
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;
export const configured = !!url && !!key;
export const supabase = configured ? createClient(url, key) : null;
export const initialSettings: Settings = { id:1, brand_name:'Dentwise', logo_path:null, contact_email:'', instagram_url:'', whatsapp_url:'', about:'Materiais de apoio para tornar sua rotina de estudos mais organizada.' };
const names = ['Anatomia Humana','Anatomia Dental','Histologia','Embriologia','Fisiologia','Bioquímica','Microbiologia','Farmacologia','Patologia','Materiais Dentários','Dentística','Periodontia','Endodontia','Cirurgia Bucomaxilofacial','Prótese Dentária','Ortodontia','Radiologia Odontológica'];
export const initialDisciplines: Discipline[] = names.map((name,i)=>({ id:`discipline-${i}`, name, active:true }));
export const initialCategories: Category[] = [{id:'resumos',name:'Resumos em PDF',active:true}];
export const demoProducts: Product[] = [0,1,2].map((i)=>({id:`exemplo-${i+1}`,name:'Seu próximo material de estudo',description:'Esta é uma demonstração da apresentação dos materiais. Os resumos reais serão publicados após o envio e a revisão das produtoras.',course:'Odontologia',discipline_id:initialDisciplines[i].id,category_id:'resumos',price_cents:0,cover_path:null,preview_paths:[],contents:[],checkout_url:'',status:'published',featured:true,is_new:false,created_at:'2026-01-01T00:00:00Z',demo:true}));
export function mediaUrl(path: string | null) { return path && supabase ? supabase.storage.from('public-media').getPublicUrl(path).data.publicUrl : undefined; }
export async function loadStore() {
  if (!supabase) return {products:[] as Product[],disciplines:initialDisciplines,categories:initialCategories,settings:initialSettings};
  const results = await Promise.all([supabase.from('products').select('*').eq('status','published').order('created_at',{ascending:false}),supabase.from('disciplines').select('*').eq('active',true).order('name'),supabase.from('categories').select('*').eq('active',true).order('name'),supabase.from('store_settings').select('*').eq('id',1).single()]);
  for (const result of results) if (result.error) throw new Error('Não foi possível carregar a loja. Tente novamente em instantes.');
  return {products:results[0].data as Product[],disciplines:results[1].data as Discipline[],categories:results[2].data as Category[],settings:results[3].data as Settings};
}
export async function upload(file: File, type:'pdf'|'image') {
  if(!supabase) throw new Error('O banco de dados ainda não foi configurado.');
  const { validateFile } = await import('./validation');
  await validateFile(file,type);
  const extension = type==='pdf'?'pdf':file.type.split('/')[1].replace('jpeg','jpg');
  const path = `${crypto.randomUUID()}.${extension}`;
  const bucket = type==='pdf'?'original-pdfs':'public-media';
  const {error} = await supabase.storage.from(bucket).upload(path,file,{contentType:type==='pdf'?'application/pdf':file.type,upsert:false});
  if(error) throw new Error('Falha no envio do arquivo. Verifique sua conexão e seu acesso.');
  return {bucket,path};
}
export async function removeFiles(files:{bucket:string;path:string}[]) {
  for(const file of files) { const result = await supabase!.storage.from(file.bucket).remove([file.path]); if(result.error) throw new Error('Os dados foram salvos, mas há arquivos antigos pendentes de limpeza. Verifique o armazenamento.'); }
}
