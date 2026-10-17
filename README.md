# fotos_casamemento_app

Aplicativo Flutter Web para receber as fotos do casamento no Supabase.

## Publicar no GitHub Pages

O workflow `.github/workflows/deploy-pages.yml` publica automaticamente a versão Web a cada push na branch `main`.

Antes do primeiro push:

1. Crie um repositório no GitHub e envie este projeto para a branch `main`.
2. Em **Settings > Secrets and variables > Actions**, crie os Secrets:
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`
3. Em **Settings > Pages**, selecione **GitHub Actions** como fonte de publicação.
4. Aguarde o workflow terminar. A URL será exibida no ambiente `github-pages` da execução.

Para um repositório chamado `usuario.github.io`, troque no workflow `--base-href "/${{ github.event.repository.name }}/"` por `--base-href "/"`.

O arquivo local `assets/config.env` está no `.gitignore`; ele é usado apenas no desenvolvimento local e é recriado pelo workflow a partir dos Secrets.
