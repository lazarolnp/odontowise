# Dentwise — loja digital de materiais acadêmicos

React + TypeScript + Vite + Tailwind CSS, com Supabase para banco, autenticação e armazenamento. Compatível com Vercel. Identidade Dentwise fornecida pelo proprietário. O arquivo original permanece em `public/brand/dentwise-original.jpeg`. A interface usa `public/brand/dentwise-transparent.png`, versão com fundo transparente solicitada pelo proprietário, mantendo o desenho da marca.

## Estado desta entrega

- Implementados: início, catálogo com busca/filtros/ordenação, detalhes, prévias, checkout individual externo, login e painel administrativo com CRUD de produtos, disciplinas, categorias, identidade e contatos.
- Implementados no código: upload privado de originais, mídia pública separada, transação de cadastro, RLS e lista de administradores fora da API pública. O verificador privilegiado fica no schema privado, com uma função pública sem privilégios elevados para a interface.
- Banco Supabase ativado no projeto `hvzyflgatqlvkktlcsne`, com estrutura, permissões, 17 disciplinas e armazenamento privado de originais. As variáveis públicas de integração são configuradas na hospedagem, sem segredos no repositório. Primeiro administrador, produtos reais, contatos e entrega no checkout ainda precisam ser definidos.
- Webhooks: apenas estrutura reservada de eventos e função desabilitada (HTTP 503). Nenhum pagamento é aceito como confirmado pelo site.
- Área do cliente, cupons, avaliações, afiliados, pacotes e outros formatos não foram implementados.

## Desenvolvimento

Requer Node 22+ e npm.

```sh
npm ci
cp .env.example .env.local
npm run dev
npm run build
npm test
```

No Windows, copie `.env.example` para `.env.local` pelo Explorador ou PowerShell.

## Ativar o Supabase

1. Crie ou selecione um projeto Supabase. Aplique `supabase/migrations/202611170001_store.sql` pelo SQL Editor ou pelo fluxo de migrations. A migration deve ser executada uma única vez e inclui 17 disciplinas, uma categoria e configurações da Dentwise, sem produtos fictícios.
2. Desabilite o cadastro público de contas em Authentication. Crie o administrador por convite ou pelo painel Auth, com senha forte. Não há cadastro de usuários na interface da loja.
3. Insira o UUID do usuário autorizado usando o SQL Editor autenticado como proprietário:

```sql
insert into private.admin_users(user_id)
values ('UUID-REAL-DO-USUARIO');
```

4. Configure `VITE_SUPABASE_URL` e `VITE_SUPABASE_PUBLISHABLE_KEY` no ambiente de desenvolvimento e de implantação. A chave publishable/anon é pública por definição; a proteção é aplicada pelas políticas RLS. Nunca coloque `service_role`, senha do banco ou tokens privados em variáveis `VITE_*`.
5. Em Auth, configure Site URL e os endereços autorizados. Configure SMTP e recuperação de senha no provedor antes da operação; esta versão usa login por senha, sem formulário público de recuperação.
6. Entre em `/admin`. Confira a identidade em Configurações, informe contatos reais e cadastre os materiais.

## Produtos e entrega

O cadastro exige nome, descrição, curso, disciplina, categoria, preço, assuntos e checkout HTTPS. Para publicar, capa e PDF privado também são obrigatórios. Imagens de prévia são opcionais e públicas por escolha explícita do administrador.

Valores são armazenados em centavos inteiros. As páginas usam UUID estável no endereço. Mudanças de preço, publicação e conteúdo aparecem nas próximas consultas ao catálogo, sem editar código ou fazer nova implantação. A sessão administrativa não é uma autorização por si só: cada operação verifica RLS.

O bucket `original-pdfs` é privado e acessível apenas a administradores. O caminho do PDF fica em `product_files`, nunca em `products`. Não existe endpoint de download para consumidores. `public-media` contém apenas capas, logotipo e prévias autorizadas. Não envie PDFs originais como imagens ou prévias públicas.

O upload da loja **não** configura entrega automática. No Cakto ou provedor escolhido, crie um produto, envie o arquivo à plataforma de pagamento, configure a entrega e copie seu checkout individual para a loja. Teste compra, aprovação, entrega, suporte e reembolso no ambiente apropriado do provedor antes de abrir vendas.

Uploads precedem a transação SQL. Falhas tentam remover os arquivos recém-enviados; exclusão e substituição tentam limpar os antigos. Como Storage e PostgreSQL não compartilham uma transação, uma interrupção de rede pode deixar arquivos órfãos privados. Confira periodicamente o armazenamento. Produtos publicados não permitem desativar sua disciplina/categoria antes de despublicá-los.

## Segurança e testes

`npm test` verifica valores monetários, links, assinaturas de arquivos e executa a migration em PostgreSQL local embutido (PGlite), com papéis `anon` e `authenticated`. Inclui isolamento de PDFs, escrita não autorizada, publicação transacional, dependências de disciplinas e ocultação de materiais desativados.

Esses testes não substituem a validação no projeto Supabase real: valide login, revogação de administrador, sessão expirada, limites de upload, Storage RLS e acesso anônimo no ambiente de implantação. Desabilite backups públicos e preserve RLS em futuras migrations.

## Implantação Vercel

Conecte o repositório, selecione a pasta deste projeto como Root Directory, framework Vite, comando `npm run build` e saída `dist`. Configure as duas variáveis públicas do Supabase e implante novamente após alterações dessas variáveis, pois Vite as incorpora no build. `vercel.json` mantém navegação direta em `/catalogo`, `/material/:id` e `/admin`.

Não há dependência de APIs proprietárias de hospedagem no aplicativo. O código pode ser publicado na Vercel a partir deste repositório. A publicação e o banco hospedado precisam de configuração própria.

## Integrações futuras

`private.checkout_events` reserva uma caixa de eventos com unicidade por provedor/evento. Antes de ativar um webhook, implemente a assinatura específica do provedor sobre o corpo original, validação de timestamp, idempotência, retenção mínima de dados pessoais, retentativas e processamento transacional no servidor. Mantenha segredos no servidor e nunca derive confirmação de pagamento de parâmetros do navegador. A função incluída recusa todas as solicitações; não a anuncie como integração ativa.

Categorias são o tipo comercial do material; disciplinas são a organização acadêmica. Novos formatos podem usar novas categorias e evoluir o modelo quando aprovados. Não são prometidas funcionalidades futuras no fluxo atual.

Referências técnicas: https://supabase.com/docs/guides/database/postgres/row-level-security e https://supabase.com/docs/guides/storage/buckets/fundamentals.

## Comunicação e próximos formatos

A vitrine destaca a escolha e a compra de resumos, com conteúdos e prévias antes do checkout. Não utiliza depoimentos, escassez, preços ou materiais fictícios. Flashcards, mapas mentais e outros formatos poderão ser organizados pelas categorias editáveis quando houver materiais reais; esta alteração não ativa esses produtos nem implementa estudo interativo.
