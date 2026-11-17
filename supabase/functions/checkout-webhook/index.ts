// Deliberately disabled until a provider's signature contract is configured.
// Never trust redirects, client-supplied payment statuses, or unsigned requests.
// Delivery remains exclusively the external checkout's responsibility.
Deno.serve(() => new Response(JSON.stringify({error:'Webhook integration is not configured.'}), {
  status:503, headers:{'Content-Type':'application/json','Cache-Control':'no-store'},
}));
