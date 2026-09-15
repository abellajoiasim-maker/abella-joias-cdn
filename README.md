# abella-joias-cdn

Banco de imagens independente para **abellajoias.com.br** e **catalogo.abellajoias.com.br**, servido gratuitamente via **jsDelivr** a partir deste repositório GitHub.

---

## 1. Estrutura de pastas

```
abella-joias-cdn/
├── categories/
├── galvanicas/
├── home/
├── orders/
├── products/       ← imagens de produto nomeadas por SKU (padrão novo)
├── produtos/        ← compatibilidade com o padrão antigo (Firebase) usado pelo image-helper.js
├── settings/
└── subcategorias/
```

> **Nota:** percebi que seu código atual (`image-helper.js`) já busca imagens de produto em `produtos/`, `categorias/`, `subcategorias/` etc. dentro do Firebase Storage. Mantive as duas pastas — `products/` (novo padrão SKU + WebP, conforme você pediu) e `produtos/` (caso ainda precise dela para não quebrar nada que já aponte pro nome antigo). Se `produtos/` não for mais necessária, é só apagar depois.

Cada pasta já vem com um `.gitkeep` só para o Git conseguir versionar a pasta vazia — pode apagar o `.gitkeep` assim que colocar imagens reais lá dentro.

## 2. Regra de nomenclatura (SKU)

Dentro de `products/`, toda imagem **deve**:
- ter o nome **exatamente igual ao SKU** do produto;
- estar em formato **WebP**;
- usar maiúsculas/hífen conforme o SKU cadastrado no seu sistema (ex.: `BC-1001.webp`).

Se um produto tiver mais de uma foto, um padrão comum e fácil de tratar no JS é sufixar com `-2`, `-3`, etc.:

```
products/BC-1001.webp        (imagem principal)
products/BC-1001-2.webp      (imagem secundária)
products/BC-1001-3.webp
```

## 3. Como montar a URL do jsDelivr

Formato base:

```
https://cdn.jsdelivr.net/gh/USUARIO/REPO@BRANCH_OU_TAG/CAMINHO/ARQUIVO
```

Exemplo, com usuário `SEU_USUARIO` e repositório `abella-joias-cdn`:

```
https://cdn.jsdelivr.net/gh/SEU_USUARIO/abella-joias-cdn@main/products/BC-1001.webp
```

Em JavaScript puro, dá pra montar isso dinamicamente:

```js
const CDN_BASE = 'https://cdn.jsdelivr.net/gh/SEU_USUARIO/abella-joias-cdn@main';

function obterImagemProdutoCDN(sku) {
  if (!sku) return `${CDN_BASE}/settings/placeholder.webp`;
  return `${CDN_BASE}/products/${sku}.webp`;
}

// uso:
img.src = obterImagemProdutoCDN('BC-1001');
```

### ⚠️ Importante sobre cache do jsDelivr

- Ao usar `@main` (o nome do branch), o jsDelivr cacheia os arquivos por até **7 dias** (às vezes menos, mas na prática pode demorar a atualizar).
- Isso é ótimo para performance, mas ruim se você **trocar** a imagem de um SKU que já existia (o CDN pode continuar servindo a versão antiga por um tempo).
- Para forçar a atualização de um arquivo específico depois de um push, use a **API de purge** do jsDelivr:
  ```
  https://purge.jsdelivr.net/gh/SEU_USUARIO/abella-joias-cdn@main/products/BC-1001.webp
  ```
  (basta acessar essa URL uma vez, via navegador, `fetch` ou `curl`, depois de atualizar a imagem).
- Uma alternativa mais robusta para produção é usar **tags de versão** em vez de `@main` (ex.: `@v1`, `@v2`), e trocar a versão referenciada no seu `CDN_BASE` sempre que fizer uma leva grande de atualizações. Tags versionadas nunca mudam de conteúdo, então o cache nunca fica "desatualizado" por engano — você só aponta o site pra uma tag nova.

## 4. Boas práticas para subir 2.000+ imagens

### 4.1 Antes de subir: converta e otimize

Não suba as imagens originais (JPG/PNG pesados) direto — converta tudo pra WebP primeiro, isso normalmente reduz o tamanho em 30–70%. Há um script pronto em `scripts/converter-para-webp.sh` (usa `cwebp`).

### 4.2 Limites que importam aqui

| Limite | Valor | Observação |
|---|---|---|
| Tamanho por arquivo (GitHub) | 100 MB (aviso a partir de 50 MB) | Não é problema pra fotos de produto |
| Tamanho por arquivo (jsDelivr) | 20 MB | Também tranquilo para WebP de produto |
| Tamanho recomendado de repositório | até ~1 GB confortável, GitHub alerta a partir de 5 GB | Com 2.000 imagens WebP leves, dificilmente chega perto disso |
| Arquivos por push/commit | sem limite rígido, mas pushes muito grandes (milhares de arquivos de uma vez) podem sofrer timeout/lentidão | Recomendo lotes de 200–500 arquivos por commit |

### 4.3 Suba em lotes, não tudo de uma vez

Enviar 2.000 arquivos em um único `git add .` + `git commit` + `git push` costuma funcionar, mas deixa o push grande, lento e arriscado (se cair a conexão no meio, você perde o progresso do lote inteiro). O mais seguro é dividir em lotes.

Incluí um script (`scripts/upload-em-lotes.sh`) que:
1. pega todos os arquivos novos/alterados;
2. agrupa em lotes de N arquivos (padrão: 300);
3. faz um commit + push por lote.

Uso:
```bash
chmod +x scripts/upload-em-lotes.sh
./scripts/upload-em-lotes.sh 300
```

### 4.4 Pela interface web do GitHub

Se preferir não usar linha de comando, a interface web aceita arraste-e-solte de até **100 arquivos por vez** (e até 25 MB por arquivo nesse método específico de upload via navegador). Para 2.000 imagens isso significa ~20 uploads manuais — funciona, mas o método via `git` (linha de comando) é bem mais rápido para esse volume.

---

## 5. Passo a passo para criar e configurar o repositório

1. **Criar o repositório no GitHub**
   - Acesse github.com → *New repository*
   - Nome sugerido: `abella-joias-cdn` (troque pelo nome que preferir)
   - Visibilidade: **Public** (obrigatório — o jsDelivr só serve repositórios públicos)
   - Não marque "Add a README" se for subir esta estrutura pronta (evita conflito no primeiro push)

2. **Clonar localmente**
   ```bash
   git clone https://github.com/SEU_USUARIO/abella-joias-cdn.git
   cd abella-joias-cdn
   ```

3. **Copiar esta estrutura de pastas** (a que preparei) para dentro da pasta clonada.

4. **Primeiro commit**
   ```bash
   git add .gitattributes .gitignore README.md scripts
   git commit -m "chore: estrutura inicial do banco de imagens"
   git push origin main
   ```

5. **Subir as imagens em lotes** (depois de convertidas para WebP e nomeadas por SKU em `products/`):
   ```bash
   ./scripts/upload-em-lotes.sh 300
   ```

6. **Testar o link do jsDelivr** com uma imagem real, por exemplo:
   ```
   https://cdn.jsdelivr.net/gh/SEU_USUARIO/abella-joias-cdn@main/products/BC-1001.webp
   ```
   Leva alguns minutos após o primeiro push para o jsDelivr "descobrir" o repositório pela primeira vez.

7. **Atualizar seu `image-helper.js`** para apontar pro CDN novo em vez do Firebase Storage (posso te ajudar a adaptar esse arquivo específico se quiser).

---

## 6. Scripts incluídos

- `scripts/converter-para-webp.sh` — converte um lote de imagens (jpg/png) para `.webp`, opcionalmente já renomeando pelo SKU.
- `scripts/upload-em-lotes.sh` — faz `git add` + `commit` + `push` em lotes, para não estourar um único push gigante.
