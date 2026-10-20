# Gerador de Projetos

Um script em **PowerShell** para automatizar a criação da estrutura inicial de projetos de desenvolvimento.

Com apenas alguns comandos, é possível criar automaticamente a estrutura de um projeto **Front-end**, **CRUD MVC em PHP**, **Angular** ou **Flutter**, incluindo pastas e arquivos iniciais.

---

## Sobre o projeto

O objetivo deste projeto é facilitar o início de novos projetos, evitando a necessidade de criar manualmente diversas pastas e arquivos toda vez que um novo sistema é iniciado.

O gerador apresenta um menu no terminal, permitindo escolher o tipo de projeto e seu nome.

Atualmente, existem quatro opções:

- 🌐 Front-end (HTML, CSS e JavaScript)
- 🐘 CRUD MVC PHP
- 🅰️ Angular
- 📱 Flutter

---

## Tipos de projeto

### 🌐 Front-end

Estrutura com HTML semântico, CSS com variáveis e JavaScript organizado.

```
meu-projeto/
├── assets/
│   ├── icons/
│   └── img/
├── css/style.css
├── js/script.js
├── pages/
├── index.html
├── .editorconfig
├── .gitignore
└── README.md
```

Opcionalmente, é possível incluir **Bootstrap Icons** e **Chart.js** via CDN.

### 🐘 CRUD MVC PHP

Projeto MVC **funcional**, com um CRUD de produtos pronto para ser adaptado:

- Roteador com URLs amigáveis (`/produtos/1/editar`)
- Conexão com o banco via **PDO** (padrão Singleton)
- `Model` base com `todos`, `buscar`, `criar`, `atualizar` e `excluir`
- Proteção **CSRF** nos formulários e escape de saída com `e()`
- Mensagens flash, validação de formulário e página 404
- Arquivo `database.sql` com banco e tabela de exemplo
- Opção de importar o banco automaticamente no MySQL do XAMPP

```
meu-projeto/
├── app/
│   ├── config/database.php
│   ├── core/            (Router, Controller, Model, Database, helpers)
│   ├── controllers/
│   ├── models/
│   └── views/
│       ├── layouts/
│       └── pages/
├── database/database.sql
├── public/              (index.php, css, js, img)
├── routes/web.php
├── .htaccess
└── README.md
```

Após criar, acesse `http://localhost/nome-do-projeto/`.

### 🅰️ Angular

Cria o projeto com o **Angular CLI** (com roteamento, SCSS ou CSS à sua escolha e sem SSR) e adiciona:

- Estrutura de pastas `core`, `shared` e `features`
- Serviço base de API (`core/services/api`)
- `provideHttpClient()` já configurado no `app.config.ts`
- Instalação opcional de **Bootstrap Icons** e **Chart.js**

Para rodar: `npm start` (abre em `http://localhost:4200`).

### 📱 Flutter

Cria o projeto com `flutter create` e adiciona:

- Pastas `models`, `services`, `screens` e `widgets` dentro de `lib/`
- Instalação opcional do pacote `http` para consumo de APIs REST
- Organização do app configurável (ex: `br.com.empresa`)

Para rodar: `flutter run`.

---

## Extras

Ao final da criação, o script pergunta se você deseja:

- Inicializar um repositório **Git** com commit inicial (Front-end e PHP)
- Abrir o projeto no **VS Code**
- Abrir o projeto PHP no navegador

Todos os projetos recebem `.gitignore`, `.editorconfig` e `README.md`.

---

## Tecnologias utilizadas

- **PowerShell**
- **HTML5**
- **CSS3**
- **JavaScript**
- **PHP**
- **MySQL**
- **XAMPP**
- **Angular**
- **Flutter / Dart**

---

## Requisitos

| Tipo de projeto | O que precisa estar instalado |
| --- | --- |
| Front-end | Nada além do PowerShell |
| CRUD MVC PHP | [XAMPP](https://www.apachefriends.org/) (PHP 8.0+ e `mod_rewrite` ativo) |
| Angular | [Node.js](https://nodejs.org/) (versão LTS) |
| Flutter | [Flutter SDK](https://docs.flutter.dev/get-started/install) no PATH |
| Extras (opcional) | [Git](https://git-scm.com/) e [VS Code](https://code.visualstudio.com/) com o comando `code` no PATH |

---

## Como executar

Para executar o script, basta abrir o terminal do VS Code e executar o comando:

```powershell
.\criar-projeto.ps1
```

Também é possível passar o nome e o tipo direto, sem usar o menu:

```powershell
.\criar-projeto.ps1 -Nome "Minha Loja" -Tipo 2
```

| Tipo | Projeto |
| --- | --- |
| `1` | Front-end |
| `2` | CRUD MVC PHP |
| `3` | Angular |
| `4` | Flutter |

> O nome da pasta é convertido automaticamente para um formato seguro. Por exemplo, `Minha Loja Única` vira `minha-loja-unica`.

**Tenha em mente que os projetos Front-end, Angular e Flutter são criados na Área de Trabalho, enquanto os projetos CRUD MVC são criados dentro de `xampp/htdocs`.**

---

## Configuração

No topo do script existe um bloco `$Config` que permite personalizar:

```powershell
$Config = @{
    PastaProjetos   = [Environment]::GetFolderPath('Desktop')
    XamppCandidatos = @('C:\xampp', 'D:\xampp', 'C:\Program Files\xampp')
    OrgFlutter      = 'com.exemplo'
}
```

- `PastaProjetos`: onde ficam os projetos Front-end, Angular e Flutter
- `XamppCandidatos`: locais onde o XAMPP pode estar instalado
- `OrgFlutter`: organização padrão dos projetos Flutter

---

## Possíveis erros

Caso após a execução do código apareça um erro de política de execução, execute a seguinte linha:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Ou, sem alterar a configuração do sistema, execute o script assim:

```powershell
powershell -ExecutionPolicy Bypass -File .\criar-projeto.ps1
```

---

É isso, aproveite a estrutura de pastas e arquivos criada automaticamente, considere dar uma estrela :)