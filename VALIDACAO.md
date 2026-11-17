# Verificação da entrega — 17/11/2026

## Aprovado localmente

- `npm run build`: compilação TypeScript e bundle de produção concluídos, código de saída 0.
- `npm test`: 4 testes aprovados, 0 falhas.
- Banco: migration executada em PostgreSQL embutido PGlite com simulação dos papéis Supabase. Leitura pública dos produtos publicados, bloqueio de escrita por usuários comuns, ocultação dos arquivos privados, cadastro transacional e proteção de disciplinas vinculadas verificados.
- Valores monetários, links de checkout e validação de arquivos verificados.
- Resposta HTTP 200 da página inicial no servidor de desenvolvimento.

## Ainda não verificado ou ativado

- Revisão visual em navegador: a abertura da aba no navegador integrado falhou por indisponibilidade da sessão. Responsividade implementada no CSS, mas não confirmada visualmente em dispositivos reais.
- Supabase real: não conectado. Migration, credenciais públicas e administrador ainda precisam ser configurados. Não há banco hospedado operacional nesta entrega.
- Compra e entrega: dependem do produto e da configuração no checkout externo. Nenhuma transação foi executada.
- Marca: nome Dentwise e logo original recebidos e aplicados. A cópia da imagem foi comparada por SHA-256 com o arquivo recebido e é idêntica.
- Publicação: não concluída. A revisão automática bloqueou o envio de código privado à Vercel por exigir autorização explícita para a transferência. O proprietário autorizou posteriormente o envio ao repositório público `lazarolnp/odontowise`. Essa autorização não ativa banco ou checkout.

O pacote contém código-fonte, configuração de implantação, migration, testes e a versão compilada em `dist`. Os exemplos visuais são identificados e não estão à venda. A função de webhook incluída permanece desabilitada e responde HTTP 503.
