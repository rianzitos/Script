#Requires -Version 5.1
<#
.SYNOPSIS
    Gerador de projetos: Front-end, PHP MVC (CRUD completo), Angular e Flutter.

.EXAMPLE
    .\gerador.ps1
    .\gerador.ps1 -Nome "Meu Projeto" -Tipo 3

.NOTES
    Se o PowerShell bloquear a execução:
    powershell -ExecutionPolicy Bypass -File .\gerador.ps1
#>

param(
    [string]$Nome,
    [ValidateSet('', '1', '2', '3', '4')]
    [string]$Tipo = ''
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ==========================================
# CONFIGURAÇÃO (edite aqui)
# ==========================================

$Config = @{
    # Onde ficam Front-end, Angular e Flutter
    PastaProjetos   = [Environment]::GetFolderPath('Desktop')
    # Locais onde o XAMPP pode estar instalado
    XamppCandidatos = @('C:\xampp', 'D:\xampp', 'C:\Program Files\xampp')
    # Organização padrão dos projetos Flutter
    OrgFlutter      = 'com.exemplo'
}


# ==========================================
# FUNÇÕES DE INTERFACE
# ==========================================

function Show-Banner {
    Clear-Host
    Write-Host ''
    Write-Host '====================================' -ForegroundColor Cyan
    Write-Host '        GERADOR DE PROJETOS' -ForegroundColor Cyan
    Write-Host '====================================' -ForegroundColor Cyan
    Write-Host ''
}

function Show-Ok    { param([string]$Msg) Write-Host "  [OK] $Msg" -ForegroundColor Green }
function Show-Info  { param([string]$Msg) Write-Host "  [..] $Msg" -ForegroundColor Gray }
function Show-Aviso { param([string]$Msg) Write-Host "  [!!] $Msg" -ForegroundColor Yellow }
function Show-Erro  { param([string]$Msg) Write-Host "`n  [ERRO] $Msg" -ForegroundColor Red }

function Read-SimNao {
    param([string]$Pergunta, [bool]$Padrao = $true)
    $sufixo = if ($Padrao) { '[S/n]' } else { '[s/N]' }
    $r = (Read-Host "  $Pergunta $sufixo").Trim().ToLower()
    if ($r -eq '') { return $Padrao }
    return ($r -in @('s', 'sim', 'y', 'yes'))
}


# ==========================================
# FUNÇÕES AUXILIARES
# ==========================================

function ConvertTo-Slug {
    param([string]$Texto, [string]$Separador = '-')
    $normalizado = $Texto.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder
    foreach ($c in $normalizado.ToCharArray()) {
        if ([System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne 'NonSpacingMark') {
            [void]$sb.Append($c)
        }
    }
    $slug = ($sb.ToString().ToLower() -replace '[^a-z0-9]+', $Separador).Trim($Separador.ToCharArray())
    if ($slug -and $slug -match '^[0-9]') { $slug = "app$Separador$slug" }
    return $slug
}

function Test-Comando {
    param([string]$Nome)
    return [bool](Get-Command $Nome -ErrorAction SilentlyContinue)
}

# Grava arquivo em UTF-8 SEM BOM (importante para PHP) e troca os @@TOKENS@@
function Write-Arquivo {
    param([string]$Raiz, [string]$Relativo, [string]$Conteudo)
    $caminho = Join-Path $Raiz $Relativo
    $dir = Split-Path $caminho -Parent
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    foreach ($chave in $script:Tokens.Keys) {
        $Conteudo = $Conteudo.Replace($chave, [string]$script:Tokens[$chave])
    }
    [System.IO.File]::WriteAllText($caminho, $Conteudo, (New-Object System.Text.UTF8Encoding($false)))
}

function New-Pastas {
    param([string]$Raiz, [string[]]$Pastas)
    foreach ($p in $Pastas) {
        New-Item -ItemType Directory -Path (Join-Path $Raiz $p) -Force | Out-Null
    }
}

function Initialize-Pasta {
    param([string]$Caminho, [switch]$PermitirExistente)
    if (Test-Path -LiteralPath $Caminho) {
        if (-not $PermitirExistente) { throw "A pasta já existe: $Caminho" }
        Show-Aviso "A pasta já existe: $Caminho"
        if (-not (Read-SimNao 'Continuar e sobrescrever arquivos com o mesmo nome?' $false)) {
            throw 'Operação cancelada pelo usuário.'
        }
    }
    else {
        New-Item -ItemType Directory -Path $Caminho -Force | Out-Null
    }
}

function Initialize-Git {
    param([string]$Raiz)
    if (-not (Test-Comando 'git')) { Show-Aviso 'Git não encontrado no PATH. Repositório não criado.'; return }
    Push-Location $Raiz
    try {
        & git init -q 2>$null
        & git add -A 2>$null
        & git commit -q -m 'chore: projeto inicial' 2>$null
        if ($LASTEXITCODE -eq 0) { Show-Ok 'Repositório Git criado com commit inicial.' }
        else { Show-Aviso 'Git iniciado, mas o commit falhou (configure user.name e user.email).' }
    }
    catch { Show-Aviso "Não foi possível iniciar o Git: $($_.Exception.Message)" }
    finally { Pop-Location }
}

function Open-Editor {
    param([string]$Raiz)
    if (Test-Comando 'code') { & code $Raiz }
    else { Show-Aviso 'Comando "code" (VS Code) não encontrado no PATH.' }
}

function Write-Readme {
    param([string]$Raiz, [string]$Descricao, [string]$ComoRodar)
    $md = @'
# @@NOME@@

@@DESC@@

## Como rodar

@@RODAR@@

## Estrutura

Gerado automaticamente pelo Gerador de Projetos em @@ANO@@.
'@
    $md = $md.Replace('@@DESC@@', $Descricao).Replace('@@RODAR@@', $ComoRodar)
    Write-Arquivo $Raiz 'README.md' $md
}

$script:Editorconfig = @'
root = true

[*]
charset = utf-8
end_of_line = crlf
indent_style = space
indent_size = 4
insert_final_newline = true
trim_trailing_whitespace = true

[*.{js,ts,json,scss,css,html,yml}]
indent_size = 2
'@


# ==========================================
# 1) FRONT-END
# ==========================================

function New-ProjetoFrontend {
    $raiz = Join-Path $Config.PastaProjetos $script:Slug
    Initialize-Pasta $raiz -PermitirExistente

    $usarIcons = Read-SimNao 'Incluir Bootstrap Icons (CDN)?' $false
    $usarChart = Read-SimNao 'Incluir Chart.js (CDN)?' $false

    Show-Info 'Criando estrutura...'
    New-Pastas $raiz @('css', 'js', 'assets/img', 'assets/icons', 'pages')

    $head = ''
    if ($usarIcons) {
        $head += '    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">' + "`n"
    }
    $scripts = ''
    if ($usarChart) {
        $scripts += '    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>' + "`n"
    }

    $html = @'
<!DOCTYPE html>
<html lang="pt-BR">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="@@NOME@@">
    <title>@@NOME@@</title>
@@HEAD@@
    <link rel="stylesheet" href="css/style.css">
</head>

<body>

    <header class="topo">
        <h1>@@NOME@@</h1>
    </header>

    <main class="conteudo">
        <p>Projeto iniciado com sucesso.</p>
    </main>

    <footer class="rodape">
        <small>&copy; @@ANO@@ @@NOME@@</small>
    </footer>

@@SCRIPTS@@
    <script src="js/script.js"></script>

</body>

</html>
'@
    $html = $html.Replace('@@HEAD@@', $head.TrimEnd()).Replace('@@SCRIPTS@@', $scripts.TrimEnd())
    Write-Arquivo $raiz 'index.html' $html

    Write-Arquivo $raiz 'css/style.css' @'
:root {
    --cor-primaria: #4f46e5;
    --cor-fundo: #f8fafc;
    --cor-texto: #0f172a;
    --raio: 12px;
}

*,
*::before,
*::after {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

html {
    scroll-behavior: smooth;
}

body {
    font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
    background: var(--cor-fundo);
    color: var(--cor-texto);
    line-height: 1.6;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
}

img {
    max-width: 100%;
    display: block;
}

.topo,
.rodape {
    padding: 1rem 1.5rem;
    background: var(--cor-primaria);
    color: #fff;
}

.conteudo {
    flex: 1;
    width: min(100% - 2rem, 1100px);
    margin: 2rem auto;
}
'@

    Write-Arquivo $raiz 'js/script.js' @'
'use strict';

document.addEventListener('DOMContentLoaded', () => {
    console.log('@@SLUG@@ iniciado!');
});
'@

    Write-Arquivo $raiz '.gitignore' "node_modules/`n.DS_Store`nThumbs.db`n.vscode/`n"
    Write-Arquivo $raiz '.editorconfig' $script:Editorconfig
    Write-Readme $raiz 'Projeto front-end em HTML, CSS e JavaScript puro.' 'Abra o `index.html` no navegador (ou use a extensão Live Server do VS Code).'

    Show-Ok "Projeto Front-end criado em: $raiz"
    return $raiz
}


# ==========================================
# 2) PHP MVC (CRUD COMPLETO)
# ==========================================

function Get-Xampp {
    foreach ($c in $Config.XamppCandidatos) {
        if (Test-Path (Join-Path $c 'htdocs')) { return $c }
    }
    return $null
}

function New-ProjetoPhp {
    $xampp = Get-Xampp
    if (-not $xampp) {
        throw ("Pasta do XAMPP não encontrada. Procurei em: " + ($Config.XamppCandidatos -join ', ') +
            ". Ajuste `$Config.XamppCandidatos no topo do script.")
    }

    $raiz = Join-Path $xampp "htdocs\$($script:Slug)"
    Initialize-Pasta $raiz -PermitirExistente

    Show-Info 'Criando estrutura MVC...'
    New-Pastas $raiz @(
        'app/config', 'app/core', 'app/controllers', 'app/models',
        'app/views/layouts', 'app/views/pages/produtos',
        'public/css', 'public/js', 'public/img',
        'routes', 'database'
    )

    # ---------- Apache ----------
    Write-Arquivo $raiz '.htaccess' @'
RewriteEngine On
RewriteRule ^$ public/ [L]
RewriteCond %{REQUEST_URI} !/public/
RewriteRule ^(.*)$ public/$1 [L]
'@

    Write-Arquivo $raiz 'public/.htaccess' @'
RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^ index.php [L]
'@

    # ---------- Front controller ----------
    Write-Arquivo $raiz 'public/index.php' @'
<?php
declare(strict_types=1);

session_start();

define('ROOT_PATH', dirname(__DIR__));
define('APP_PATH', ROOT_PATH . '/app');

// Autoload simples: procura a classe nas pastas do MVC
spl_autoload_register(function (string $classe): void {
    foreach (['core', 'controllers', 'models'] as $pasta) {
        $arquivo = APP_PATH . "/$pasta/$classe.php";
        if (is_file($arquivo)) {
            require $arquivo;
            return;
        }
    }
});

require APP_PATH . '/core/helpers.php';

$router = new Router();
require ROOT_PATH . '/routes/web.php';

$router->dispatch($_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI']);
'@

    # ---------- Config ----------
    Write-Arquivo $raiz 'app/config/database.php' @'
<?php
// Configuração do banco de dados (XAMPP: usuário root, sem senha)
return [
    'host'     => 'localhost',
    'dbname'   => '@@DB@@',
    'user'     => 'root',
    'password' => '',
    'charset'  => 'utf8mb4',
];
'@

    # ---------- Core ----------
    Write-Arquivo $raiz 'app/core/helpers.php' @'
<?php

function base_url(): string
{
    $script = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME']));
    $base   = str_replace('\\', '/', dirname($script));
    return rtrim($base === '/' ? '' : $base, '/');
}

function url(string $caminho = '/'): string
{
    return base_url() . $caminho;
}

function e(mixed $valor): string
{
    return htmlspecialchars((string) $valor, ENT_QUOTES, 'UTF-8');
}

function csrf_token(): string
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function csrf_field(): string
{
    return '<input type="hidden" name="_csrf" value="' . e(csrf_token()) . '">';
}

function flash(string $tipo, string $mensagem): void
{
    $_SESSION['flash'][] = ['tipo' => $tipo, 'mensagem' => $mensagem];
}

function pegar_flash(): array
{
    $mensagens = $_SESSION['flash'] ?? [];
    unset($_SESSION['flash']);
    return $mensagens;
}
'@

    Write-Arquivo $raiz 'app/core/Router.php' @'
<?php

class Router
{
    private array $rotas = [];

    public function get(string $caminho, array $handler): void
    {
        $this->adicionar('GET', $caminho, $handler);
    }

    public function post(string $caminho, array $handler): void
    {
        $this->adicionar('POST', $caminho, $handler);
    }

    private function adicionar(string $metodo, string $caminho, array $handler): void
    {
        // /produtos/{id}/editar  =>  #^/produtos/(?P<id>[^/]+)/editar$#
        $padrao = '#^' . preg_replace('#\{(\w+)\}#', '(?P<$1>[^/]+)', $caminho) . '$#';
        $this->rotas[] = compact('metodo', 'padrao', 'handler');
    }

    public function dispatch(string $metodo, string $uri): void
    {
        $caminho   = rawurldecode(parse_url($uri, PHP_URL_PATH) ?? '/');
        $scriptDir = rtrim(str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'])), '/');

        foreach ([$scriptDir, base_url()] as $prefixo) {
            if ($prefixo !== '' && str_starts_with($caminho, $prefixo)) {
                $caminho = substr($caminho, strlen($prefixo));
                break;
            }
        }
        $caminho = '/' . trim($caminho, '/');

        foreach ($this->rotas as $rota) {
            if ($rota['metodo'] === $metodo && preg_match($rota['padrao'], $caminho, $m)) {
                $params = array_filter($m, 'is_string', ARRAY_FILTER_USE_KEY);
                [$classe, $acao] = $rota['handler'];
                (new $classe())->$acao(...array_values($params));
                return;
            }
        }

        http_response_code(404);
        (new class extends Controller {
            public function erro(): void { $this->view('erro404'); }
        })->erro();
    }
}
'@

    Write-Arquivo $raiz 'app/core/Controller.php' @'
<?php

abstract class Controller
{
    protected function view(string $view, array $dados = [], string $layout = 'main'): void
    {
        extract($dados, EXTR_SKIP);

        ob_start();
        require APP_PATH . "/views/pages/$view.php";
        $conteudo = ob_get_clean();

        require APP_PATH . "/views/layouts/$layout.php";
    }

    protected function redirect(string $caminho): void
    {
        header('Location: ' . url($caminho));
        exit;
    }

    protected function validarCsrf(): void
    {
        $token = $_POST['_csrf'] ?? '';
        if (!hash_equals($_SESSION['csrf'] ?? '', (string) $token)) {
            http_response_code(419);
            die('Sessão expirada. Volte e tente novamente.');
        }
    }

    protected function naoEncontrado(): void
    {
        http_response_code(404);
        $this->view('erro404');
    }
}
'@

    Write-Arquivo $raiz 'app/core/Database.php' @'
<?php

class Database
{
    private static ?PDO $pdo = null;

    public static function conectar(): PDO
    {
        if (self::$pdo === null) {
            $c = require APP_PATH . '/config/database.php';
            $dsn = "mysql:host={$c['host']};dbname={$c['dbname']};charset={$c['charset']}";

            try {
                self::$pdo = new PDO($dsn, $c['user'], $c['password'], [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                ]);
            } catch (PDOException $e) {
                http_response_code(500);
                die('Erro na conexão com o banco: ' . e($e->getMessage()));
            }
        }

        return self::$pdo;
    }
}
'@

    Write-Arquivo $raiz 'app/core/Model.php' @'
<?php

abstract class Model
{
    protected static string $tabela = '';
    protected static array $campos = [];

    protected static function db(): PDO
    {
        return Database::conectar();
    }

    protected static function filtrar(array $dados): array
    {
        return array_intersect_key($dados, array_flip(static::$campos));
    }

    public static function todos(): array
    {
        return static::db()
            ->query('SELECT * FROM `' . static::$tabela . '` ORDER BY id DESC')
            ->fetchAll();
    }

    public static function buscar(int $id): ?array
    {
        $st = static::db()->prepare('SELECT * FROM `' . static::$tabela . '` WHERE id = :id');
        $st->execute(['id' => $id]);
        return $st->fetch() ?: null;
    }

    public static function criar(array $dados): int
    {
        $dados = static::filtrar($dados);
        $colunas = implode('`, `', array_keys($dados));
        $marcas  = ':' . implode(', :', array_keys($dados));

        $st = static::db()->prepare('INSERT INTO `' . static::$tabela . "` (`$colunas`) VALUES ($marcas)");
        $st->execute($dados);

        return (int) static::db()->lastInsertId();
    }

    public static function atualizar(int $id, array $dados): bool
    {
        $dados = static::filtrar($dados);
        $set = implode(', ', array_map(fn ($c) => "`$c` = :$c", array_keys($dados)));

        $st = static::db()->prepare('UPDATE `' . static::$tabela . "` SET $set WHERE id = :_id");
        return $st->execute($dados + ['_id' => $id]);
    }

    public static function excluir(int $id): bool
    {
        $st = static::db()->prepare('DELETE FROM `' . static::$tabela . '` WHERE id = :id');
        return $st->execute(['id' => $id]);
    }
}
'@

    # ---------- Model / Controllers ----------
    Write-Arquivo $raiz 'app/models/Produto.php' @'
<?php

class Produto extends Model
{
    protected static string $tabela = 'produtos';
    protected static array $campos = ['nome', 'descricao', 'preco', 'estoque'];
}
'@

    Write-Arquivo $raiz 'app/controllers/HomeController.php' @'
<?php

class HomeController extends Controller
{
    public function index(): void
    {
        $this->view('home');
    }
}
'@

    Write-Arquivo $raiz 'app/controllers/ProdutoController.php' @'
<?php

class ProdutoController extends Controller
{
    public function index(): void
    {
        $this->view('produtos/index', ['produtos' => Produto::todos()]);
    }

    public function criar(): void
    {
        $this->view('produtos/form', ['produto' => null, 'erros' => [], 'antigo' => []]);
    }

    public function salvar(): void
    {
        $this->validarCsrf();
        [$dados, $erros] = $this->validar($_POST);

        if ($erros) {
            $this->view('produtos/form', ['produto' => null, 'erros' => $erros, 'antigo' => $_POST]);
            return;
        }

        Produto::criar($dados);
        flash('sucesso', 'Produto cadastrado com sucesso.');
        $this->redirect('/produtos');
    }

    public function editar(string $id): void
    {
        $produto = Produto::buscar((int) $id);
        if (!$produto) {
            $this->naoEncontrado();
            return;
        }
        $this->view('produtos/form', ['produto' => $produto, 'erros' => [], 'antigo' => []]);
    }

    public function atualizar(string $id): void
    {
        $this->validarCsrf();
        $produto = Produto::buscar((int) $id);
        if (!$produto) {
            $this->naoEncontrado();
            return;
        }

        [$dados, $erros] = $this->validar($_POST);
        if ($erros) {
            $this->view('produtos/form', ['produto' => $produto, 'erros' => $erros, 'antigo' => $_POST]);
            return;
        }

        Produto::atualizar((int) $id, $dados);
        flash('sucesso', 'Produto atualizado com sucesso.');
        $this->redirect('/produtos');
    }

    public function excluir(string $id): void
    {
        $this->validarCsrf();
        Produto::excluir((int) $id);
        flash('sucesso', 'Produto excluído.');
        $this->redirect('/produtos');
    }

    private function validar(array $in): array
    {
        $erros   = [];
        $nome    = trim((string) ($in['nome'] ?? ''));
        $preco   = str_replace(',', '.', trim((string) ($in['preco'] ?? '')));
        $estoque = filter_var($in['estoque'] ?? 0, FILTER_VALIDATE_INT);

        if ($nome === '') {
            $erros['nome'] = 'Informe o nome do produto.';
        }
        if (!is_numeric($preco) || (float) $preco < 0) {
            $erros['preco'] = 'Informe um preço válido.';
        }
        if ($estoque === false || $estoque < 0) {
            $erros['estoque'] = 'Informe um estoque válido (número inteiro).';
        }

        $dados = [
            'nome'      => $nome,
            'descricao' => trim((string) ($in['descricao'] ?? '')),
            'preco'     => (float) $preco,
            'estoque'   => (int) $estoque,
        ];

        return [$dados, $erros];
    }
}
'@

    # ---------- Rotas ----------
    Write-Arquivo $raiz 'routes/web.php' @'
<?php
/** @var Router $router */

$router->get('/', [HomeController::class, 'index']);

// CRUD de produtos
$router->get('/produtos',                [ProdutoController::class, 'index']);
$router->get('/produtos/novo',           [ProdutoController::class, 'criar']);
$router->post('/produtos',               [ProdutoController::class, 'salvar']);
$router->get('/produtos/{id}/editar',    [ProdutoController::class, 'editar']);
$router->post('/produtos/{id}/atualizar', [ProdutoController::class, 'atualizar']);
$router->post('/produtos/{id}/excluir',  [ProdutoController::class, 'excluir']);
'@

    # ---------- Views ----------
    Write-Arquivo $raiz 'app/views/layouts/main.php' @'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>@@NOME@@</title>
    <link rel="stylesheet" href="<?= e(url('/css/style.css')) ?>">
</head>
<body>

<header class="topo">
    <a class="marca" href="<?= e(url('/')) ?>">@@NOME@@</a>
    <nav>
        <a href="<?= e(url('/')) ?>">Início</a>
        <a href="<?= e(url('/produtos')) ?>">Produtos</a>
    </nav>
</header>

<main class="conteudo">
    <?php foreach (pegar_flash() as $f): ?>
        <div class="alerta alerta-<?= e($f['tipo']) ?>"><?= e($f['mensagem']) ?></div>
    <?php endforeach; ?>

    <?= $conteudo ?>
</main>

<footer class="rodape"><small>&copy; @@ANO@@ @@NOME@@</small></footer>

<script src="<?= e(url('/js/script.js')) ?>"></script>
</body>
</html>
'@

    Write-Arquivo $raiz 'app/views/pages/home.php' @'
<section class="cartao">
    <h1>@@NOME@@</h1>
    <p>Projeto PHP MVC funcionando. Este é um CRUD de exemplo para você adaptar.</p>
    <p><a class="btn" href="<?= e(url('/produtos')) ?>">Ver produtos</a></p>
</section>
'@

    Write-Arquivo $raiz 'app/views/pages/erro404.php' @'
<section class="cartao">
    <h1>404</h1>
    <p>Página não encontrada.</p>
    <p><a class="btn" href="<?= e(url('/')) ?>">Voltar ao início</a></p>
</section>
'@

    Write-Arquivo $raiz 'app/views/pages/produtos/index.php' @'
<div class="barra">
    <h1>Produtos</h1>
    <a class="btn" href="<?= e(url('/produtos/novo')) ?>">+ Novo produto</a>
</div>

<?php if (!$produtos): ?>
    <p class="vazio">Nenhum produto cadastrado ainda.</p>
<?php else: ?>
    <div class="tabela-wrap">
        <table class="tabela">
            <thead>
                <tr><th>#</th><th>Nome</th><th>Preço</th><th>Estoque</th><th>Ações</th></tr>
            </thead>
            <tbody>
            <?php foreach ($produtos as $p): ?>
                <tr>
                    <td><?= e($p['id']) ?></td>
                    <td><?= e($p['nome']) ?></td>
                    <td>R$ <?= number_format((float) $p['preco'], 2, ',', '.') ?></td>
                    <td><?= e($p['estoque']) ?></td>
                    <td class="acoes">
                        <a class="btn btn-sec" href="<?= e(url('/produtos/' . $p['id'] . '/editar')) ?>">Editar</a>
                        <form method="post" action="<?= e(url('/produtos/' . $p['id'] . '/excluir')) ?>"
                              onsubmit="return confirm('Excluir este produto?');">
                            <?= csrf_field() ?>
                            <button class="btn btn-perigo" type="submit">Excluir</button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>
'@

    Write-Arquivo $raiz 'app/views/pages/produtos/form.php' @'
<?php
$v = fn (string $campo) => $antigo[$campo] ?? ($produto[$campo] ?? '');
$acao = $produto ? '/produtos/' . $produto['id'] . '/atualizar' : '/produtos';
?>

<h1><?= $produto ? 'Editar produto' : 'Novo produto' ?></h1>

<form class="form" method="post" action="<?= e(url($acao)) ?>" novalidate>
    <?= csrf_field() ?>

    <label>Nome
        <input type="text" name="nome" value="<?= e($v('nome')) ?>" required>
        <?php if (isset($erros['nome'])): ?><small class="erro"><?= e($erros['nome']) ?></small><?php endif; ?>
    </label>

    <label>Descrição
        <textarea name="descricao" rows="3"><?= e($v('descricao')) ?></textarea>
    </label>

    <div class="linha">
        <label>Preço (R$)
            <input type="number" step="0.01" min="0" name="preco" value="<?= e($v('preco')) ?>" required>
            <?php if (isset($erros['preco'])): ?><small class="erro"><?= e($erros['preco']) ?></small><?php endif; ?>
        </label>

        <label>Estoque
            <input type="number" step="1" min="0" name="estoque" value="<?= e($v('estoque') === '' ? 0 : $v('estoque')) ?>">
            <?php if (isset($erros['estoque'])): ?><small class="erro"><?= e($erros['estoque']) ?></small><?php endif; ?>
        </label>
    </div>

    <div class="acoes">
        <button class="btn" type="submit">Salvar</button>
        <a class="btn btn-sec" href="<?= e(url('/produtos')) ?>">Cancelar</a>
    </div>
</form>
'@

    # ---------- Assets ----------
    Write-Arquivo $raiz 'public/css/style.css' @'
:root {
    --cor-primaria: #4f46e5;
    --cor-fundo: #f8fafc;
    --cor-texto: #0f172a;
    --cor-borda: #e2e8f0;
    --raio: 10px;
}

*, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

body {
    font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
    background: var(--cor-fundo);
    color: var(--cor-texto);
    line-height: 1.6;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
}

a { color: inherit; text-decoration: none; }

.topo, .rodape {
    display: flex; align-items: center; justify-content: space-between;
    padding: 1rem 1.5rem; background: var(--cor-primaria); color: #fff;
}
.topo nav { display: flex; gap: 1.25rem; }
.marca { font-weight: 700; font-size: 1.15rem; }

.conteudo { flex: 1; width: min(100% - 2rem, 1000px); margin: 2rem auto; }

.cartao { background: #fff; padding: 2rem; border-radius: var(--raio); border: 1px solid var(--cor-borda); }
.cartao p { margin-top: .75rem; }

.barra { display: flex; align-items: center; justify-content: space-between; margin-bottom: 1.25rem; }

.btn {
    display: inline-block; padding: .55rem 1rem; border: 0; border-radius: 8px;
    background: var(--cor-primaria); color: #fff; font: inherit; cursor: pointer;
}
.btn-sec { background: #64748b; }
.btn-perigo { background: #dc2626; }
.btn:hover { filter: brightness(1.1); }

.tabela-wrap { overflow-x: auto; }
.tabela { width: 100%; border-collapse: collapse; background: #fff; border-radius: var(--raio); overflow: hidden; }
.tabela th, .tabela td { padding: .75rem 1rem; text-align: left; border-bottom: 1px solid var(--cor-borda); }
.tabela th { background: #f1f5f9; }
.acoes { display: flex; gap: .5rem; align-items: center; }
.vazio { color: #64748b; }

.form { display: grid; gap: 1rem; background: #fff; padding: 1.5rem; border-radius: var(--raio); border: 1px solid var(--cor-borda); margin-top: 1rem; }
.form label { display: grid; gap: .35rem; font-weight: 600; }
.form input, .form textarea {
    padding: .6rem .75rem; border: 1px solid var(--cor-borda); border-radius: 8px; font: inherit; font-weight: 400;
}
.linha { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
.erro { color: #dc2626; font-weight: 400; }

.alerta { padding: .75rem 1rem; border-radius: 8px; margin-bottom: 1rem; }
.alerta-sucesso { background: #dcfce7; color: #166534; }
.alerta-erro { background: #fee2e2; color: #991b1b; }

@media (max-width: 600px) { .linha { grid-template-columns: 1fr; } }
'@

    Write-Arquivo $raiz 'public/js/script.js' @'
'use strict';

document.addEventListener('DOMContentLoaded', () => {
    // JavaScript do projeto
});
'@

    # ---------- Banco ----------
    Write-Arquivo $raiz 'database/database.sql' @'
CREATE DATABASE IF NOT EXISTS `@@DB@@`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `@@DB@@`;

CREATE TABLE IF NOT EXISTS `produtos` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nome`       VARCHAR(150) NOT NULL,
  `descricao`  TEXT NULL,
  `preco`      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `estoque`    INT UNSIGNED NOT NULL DEFAULT 0,
  `criado_em`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `produtos` (`nome`, `descricao`, `preco`, `estoque`) VALUES
  ('Produto de exemplo', 'Cadastro inicial para testar o CRUD.', 19.90, 10);
'@

    Write-Arquivo $raiz '.gitignore' "vendor/`n.env`n.DS_Store`nThumbs.db`n.vscode/`n"
    Write-Arquivo $raiz '.editorconfig' $script:Editorconfig
    Write-Readme $raiz 'CRUD em PHP com arquitetura MVC, PDO e rotas amigáveis.' @'
1. Inicie **Apache** e **MySQL** no XAMPP.
2. Importe `database/database.sql` (phpMyAdmin ou linha de comando).
3. Acesse `http://localhost/@@SLUG@@/`.

Requisitos: PHP 8.0 ou superior e `mod_rewrite` ativo no Apache.
'@

    Show-Ok "Projeto PHP MVC criado em: $raiz"

    # Importação automática do banco (opcional)
    $mysql = Join-Path $xampp 'mysql\bin\mysql.exe'
    if ((Test-Path $mysql) -and (Read-SimNao 'Importar o banco de dados agora? (MySQL do XAMPP precisa estar rodando)' $false)) {
        try {
            Get-Content -Raw -Encoding UTF8 (Join-Path $raiz 'database\database.sql') | & $mysql -u root 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Show-Ok "Banco '$($script:Tokens['@@DB@@'])' criado e populado." }
            else { Show-Aviso 'Não foi possível importar. Inicie o MySQL no XAMPP e importe database.sql manualmente.' }
        }
        catch { Show-Aviso 'Falha ao importar. Importe database.sql manualmente pelo phpMyAdmin.' }
    }

    $script:UrlFinal = "http://localhost/$($script:Slug)/"
    return $raiz
}


# ==========================================
# 3) ANGULAR
# ==========================================

function New-ProjetoAngular {
    foreach ($cmd in @('node', 'npm.cmd', 'npx.cmd')) {
        if (-not (Test-Comando $cmd)) {
            throw 'Node.js/npm não encontrado. Instale a versão LTS em https://nodejs.org e reabra o terminal.'
        }
    }

    $raiz = Join-Path $Config.PastaProjetos $script:Slug
    if (Test-Path -LiteralPath $raiz) { throw "A pasta já existe: $raiz (o Angular CLI exige uma pasta nova)." }

    $estilo    = if (Read-SimNao 'Usar SCSS em vez de CSS?' $true) { 'scss' } else { 'css' }
    $usarIcons = Read-SimNao 'Instalar Bootstrap Icons?' $false
    $usarChart = Read-SimNao 'Instalar Chart.js?' $false

    Show-Info 'Executando Angular CLI (pode demorar alguns minutos)...'
    Push-Location $Config.PastaProjetos
    try {
        & npx.cmd --yes '@angular/cli@latest' new $script:Slug --routing "--style=$estilo" '--ssr=false' --skip-git --defaults
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar o projeto Angular.' }
    }
    finally { Pop-Location }

    Push-Location $raiz
    try {
        # Dependências opcionais
        $pacotes = @()
        if ($usarIcons) { $pacotes += 'bootstrap-icons' }
        if ($usarChart) { $pacotes += 'chart.js' }
        if ($pacotes.Count -gt 0) {
            Show-Info "Instalando: $($pacotes -join ', ')..."
            & npm.cmd install --silent @pacotes
            if ($LASTEXITCODE -ne 0) { Show-Aviso 'Falha ao instalar pacotes opcionais.' }
            elseif ($usarIcons -and (Test-Path 'angular.json')) {
                $json = [System.IO.File]::ReadAllText((Join-Path $raiz 'angular.json'))
                $json = $json -replace '("styles"\s*:\s*\[)', '$1 "node_modules/bootstrap-icons/font/bootstrap-icons.css",'
                [System.IO.File]::WriteAllText((Join-Path $raiz 'angular.json'), $json, (New-Object System.Text.UTF8Encoding($false)))
            }
        }

        # Estrutura de pastas escalável
        New-Pastas $raiz @('src/app/core/services', 'src/app/shared', 'src/app/features')
        foreach ($p in @('src/app/shared', 'src/app/features')) {
            Write-Arquivo $raiz "$p/.gitkeep" ''
        }

        # Serviço base de API + HttpClient
        try {
            & npx.cmd ng generate service core/services/api --skip-tests 2>&1 | Out-Null
        }
        catch { Show-Aviso 'Não foi possível gerar o serviço base de API.' }

        $cfg = Join-Path $raiz 'src/app/app.config.ts'
        if (Test-Path $cfg) {
            $ts = [System.IO.File]::ReadAllText($cfg)
            if (($ts -notmatch 'provideHttpClient') -and ($ts -match 'providers:\s*\[')) {
                $ts = "import { provideHttpClient } from '@angular/common/http';`n" + ($ts -replace 'providers:\s*\[', 'providers: [provideHttpClient(), ')
                [System.IO.File]::WriteAllText($cfg, $ts, (New-Object System.Text.UTF8Encoding($false)))
                Show-Ok 'provideHttpClient() adicionado ao app.config.ts.'
            }
        }
    }
    finally { Pop-Location }

    Show-Ok "Projeto Angular criado em: $raiz"
    $script:ComandoFinal = "cd `"$raiz`"; npm start   (abre em http://localhost:4200)"
    return $raiz
}


# ==========================================
# 4) FLUTTER
# ==========================================

function New-ProjetoFlutter {
    if (-not (Test-Comando 'flutter')) {
        throw 'Flutter não encontrado no PATH. Instale em https://docs.flutter.dev/get-started/install'
    }

    $raiz = Join-Path $Config.PastaProjetos $script:Slug
    if (Test-Path -LiteralPath $raiz) { throw "A pasta já existe: $raiz (o Flutter exige uma pasta nova)." }

    $snake = ConvertTo-Slug $Nome '_'
    $org = (Read-Host "  Organização do app [$($Config.OrgFlutter)]").Trim()
    if (-not $org) { $org = $Config.OrgFlutter }
    $usarHttp = Read-SimNao 'Adicionar o pacote http (consumo de APIs REST)?' $true

    Show-Info 'Executando flutter create...'
    Push-Location $Config.PastaProjetos
    try {
        & flutter create --org $org --project-name $snake $script:Slug
        if ($LASTEXITCODE -ne 0) { throw 'Falha ao criar o projeto Flutter.' }
    }
    finally { Pop-Location }

    Push-Location $raiz
    try {
        if ($usarHttp) { & flutter pub add http | Out-Null }
        New-Pastas $raiz @('lib/models', 'lib/services', 'lib/screens', 'lib/widgets')
        foreach ($p in @('models', 'services', 'screens', 'widgets')) {
            Write-Arquivo $raiz "lib/$p/.gitkeep" ''
        }
    }
    finally { Pop-Location }

    Show-Ok "Projeto Flutter criado em: $raiz"
    $script:ComandoFinal = "cd `"$raiz`"; flutter run"
    return $raiz
}


# ==========================================
# PROGRAMA PRINCIPAL
# ==========================================

$script:UrlFinal = $null
$script:ComandoFinal = $null

try {
    Show-Banner

    # ----- Nome -----
    if ([string]::IsNullOrWhiteSpace($Nome)) { $Nome = Read-Host 'Nome do projeto' }
    $Nome = $Nome.Trim()

    $script:Slug = ConvertTo-Slug $Nome '-'
    if (-not $script:Slug) { throw 'Nome inválido. Use ao menos uma letra ou número.' }
    if ($script:Slug -ne $Nome) { Show-Info "Nome da pasta: $($script:Slug)" }

    $script:Tokens = @{
        '@@NOME@@' = [System.Net.WebUtility]::HtmlEncode($Nome)
        '@@SLUG@@' = $script:Slug
        '@@DB@@'   = (ConvertTo-Slug $Nome '_')
        '@@ANO@@'  = (Get-Date).Year
    }

    # ----- Tipo -----
    if (-not $Tipo) {
        Write-Host ''
        Write-Host '  Escolha o tipo de projeto:' -ForegroundColor White
        Write-Host ''
        Write-Host '  1 - Front-end (HTML, CSS e JS)'
        Write-Host '  2 - Back-end PHP MVC (CRUD completo no XAMPP)'
        Write-Host '  3 - Angular (Angular CLI)'
        Write-Host '  4 - Flutter (mobile)'
        Write-Host ''
        do {
            $Tipo = (Read-Host '  Digite a opção').Trim()
            if ($Tipo -notin @('1', '2', '3', '4')) { Show-Aviso 'Opção inválida. Digite 1, 2, 3 ou 4.' }
        } until ($Tipo -in @('1', '2', '3', '4'))
    }

    Write-Host ''
    $raizProjeto = switch ($Tipo) {
        '1' { New-ProjetoFrontend }
        '2' { New-ProjetoPhp }
        '3' { New-ProjetoAngular }
        '4' { New-ProjetoFlutter }
    }
    # O caminho do projeto é sempre o último item retornado
    $raizProjeto = @($raizProjeto)[-1]

    # ----- Extras finais -----
    Write-Host ''
    if ($Tipo -in @('1', '2') -and (Read-SimNao 'Inicializar repositório Git?' $true)) { Initialize-Git $raizProjeto }
    if (Read-SimNao 'Abrir no VS Code?' $true) { Open-Editor $raizProjeto }
    if ($script:UrlFinal -and (Read-SimNao "Abrir $($script:UrlFinal) no navegador?" $false)) { Start-Process $script:UrlFinal }

    # ----- Resumo -----
    Write-Host ''
    Write-Host '====================================' -ForegroundColor Green
    Write-Host '  Projeto criado com sucesso!' -ForegroundColor Green
    Write-Host "  Local: $raizProjeto"
    if ($script:UrlFinal)     { Write-Host "  URL:   $($script:UrlFinal)" }
    if ($script:ComandoFinal) { Write-Host "  Rodar: $($script:ComandoFinal)" }
    Write-Host '====================================' -ForegroundColor Green
}
catch {
    Show-Erro $_.Exception.Message
}

Write-Host ''
Read-Host 'Pressione ENTER para sair'