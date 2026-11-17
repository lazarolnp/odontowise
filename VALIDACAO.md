# Verificação da Dentwise — 17/11/2026

## Código e marca

- TypeScript, build de produção e os quatro testes automatizados passaram.
- Logo original aplicada sem alteração dos bytes, com comparação SHA-256.
- Código enviado ao repositório público autorizado pelo proprietário.

## Supabase real

- Migration aplicada ao projeto `hvzyflgatqlvkktlcsne` (organização `odnsmuglwibcpfgqdvlj`).
- 17 disciplinas, uma categoria e zero produtos; nenhum material fictício foi cadastrado.
- RLS habilitada nas tabelas da aplicação.
- `public-media`: público, limitado a imagens de até 5 MB.
- `original-pdfs`: privado, limitado a PDFs de até 50 MB.
- REST anônimo: disciplinas 200 com 17 registros, produtos 200 com lista vazia, marca 200 com Dentwise, metadados dos PDFs 401 (42501), `is_admin` retorna false.
- Advisor de segurança sem avisos de nível WARNING ou ERROR. As duas informações `rls_enabled_no_policy` correspondem a `private.admin_users` e `private.checkout_events`, intencionalmente fechadas a clientes por ausência de permissões e por bloqueio padrão da RLS. [Explicação do diagnóstico](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

## Pendências de operação

- Nenhum usuário administrador foi criado automaticamente. O proprietário precisa definir o e-mail da conta administrativa e concluir sua ativação.
- Compra, aprovação, entrega e reembolso precisam de configuração e teste no checkout externo.
- Contatos e materiais reais ainda precisam ser cadastrados.
- Webhook continua desabilitado (HTTP 503), sem confirmação de pagamentos.
- Revisão visual concluída em 390 × 844 e 1280 × 900. Testados navegação inicial, busca, filtro por disciplina, catálogo vazio, exemplos identificados, página demonstrativa com compra desabilitada e login privado. O console não registrou erros durante esses testes.

## Hospedagem

O projeto Vercel Dentwise usa Node 22, `npm ci`, `npm run build && npm test`, saída `dist` e as duas variáveis públicas de integração com o Supabase. Implantação verificada como READY no commit `192f0e724b9241db8f5d680f42ae850a14e07bd1`. Endereço: https://dentwise-beryl.vercel.app/. Inicial, catálogo e administração responderam HTTP 200. O estado de cada implantação posterior deve ser conferido na Vercel. Não há chaves privadas no frontend.
