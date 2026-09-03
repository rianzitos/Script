# ==========================================
# GERADOR DE PROJETOS
# ==========================================

Write-Host ""
Write-Host "===================================="
Write-Host "       GERADOR DE PROJETOS"
Write-Host "===================================="
Write-Host ""

$nome = Read-Host "Nome do projeto"

Write-Host ""
Write-Host "Escolha o tipo de projeto:"
Write-Host ""
Write-Host "1 - Front-end"
Write-Host "2 - CRUD MVC PHP"
Write-Host ""

$tipo = Read-Host "Digite a opcao"


# ==========================================
# CAMINHOS
# ==========================================

# Área de Trabalho
$desktop = [Environment]::GetFolderPath("Desktop")

# Pasta htdocs do XAMPP
$htdocs = "C:\xampp\htdocs"


# ==========================================
# FRONT-END
# ==========================================

if ($tipo -eq "1") {

    Write-Host ""
    Write-Host "Criando projeto Front-end na Área de Trabalho..."
    Write-Host ""

    $caminhoProjeto = "$desktop\$nome"

    # Cria pasta principal
    New-Item -ItemType Directory -Path $caminhoProjeto -Force | Out-Null

    Set-Location $caminhoProjeto

    # Pastas
    $pastas = @(
        "css",
        "js",
        "assets",
        "assets/img",
        "assets/icons",
        "pages"
    )

    foreach ($pasta in $pastas) {
        New-Item -ItemType Directory -Path $pasta -Force | Out-Null
    }

    # Arquivos
    New-Item index.html -ItemType File | Out-Null
    New-Item css/style.css -ItemType File | Out-Null
    New-Item js/script.js -ItemType File | Out-Null
    New-Item README.md -ItemType File | Out-Null


    # HTML inicial
    @"
<!DOCTYPE html>
<html lang="pt-BR">

<head>

    <meta charset="UTF-8">

    <meta name="viewport"
          content="width=device-width, initial-scale=1.0">

    <title>$nome</title>

    <link rel="stylesheet" href="css/style.css">

</head>

<body>

    <h1>$nome</h1>

    <script src="js/script.js"></script>

</body>

</html>
"@ | Set-Content index.html


    # CSS inicial
    @"
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: Arial, sans-serif;
}
"@ | Set-Content css/style.css


    # JS inicial
    @"
// JavaScript do projeto

console.log("$nome iniciado!");
"@ | Set-Content js/script.js


    Write-Host "===================================="
    Write-Host " Projeto Front-end criado!"
    Write-Host " Local: $caminhoProjeto"
    Write-Host "===================================="
}


# ==========================================
# CRUD MVC PHP
# ==========================================

elseif ($tipo -eq "2") {

    Write-Host ""
    Write-Host "Criando projeto CRUD MVC no XAMPP..."
    Write-Host ""

    # Verifica se o XAMPP existe
    if (!(Test-Path $htdocs)) {

        Write-Host ""
        Write-Host "ERRO: A pasta do XAMPP nao foi encontrada!"
        Write-Host ""
        Write-Host "Caminho procurado:"
        Write-Host $htdocs
        Write-Host ""

        Read-Host "Pressione ENTER para sair"

        exit
    }


    $caminhoProjeto = "$htdocs\$nome"

    # Cria pasta principal
    New-Item -ItemType Directory -Path $caminhoProjeto -Force | Out-Null

    Set-Location $caminhoProjeto


    # ==========================================
    # PASTAS
    # ==========================================

    $pastas = @(

        "app",

        "app/controllers",

        "app/models",

        "app/views",

        "app/views/layouts",

        "app/views/pages",

        "app/config",

        "public",

        "public/css",

        "public/js",

        "public/img",

        "routes",

        "database"

    )


    foreach ($pasta in $pastas) {

        New-Item `
            -ItemType Directory `
            -Path $pasta `
            -Force | Out-Null
    }


    # ==========================================
    # ARQUIVOS
    # ==========================================

    $arquivos = @(

        "public/index.php",

        "public/css/style.css",

        "public/js/script.js",

        "app/config/database.php",

        "routes/web.php",

        "database/database.sql",

        "README.md"

    )


    foreach ($arquivo in $arquivos) {

        New-Item `
            -ItemType File `
            -Path $arquivo `
            -Force | Out-Null
    }


    # ==========================================
    # INDEX.PHP
    # ==========================================

    @"
<?php

echo "Projeto $nome funcionando!";

?>
"@ | Set-Content public/index.php


    # ==========================================
    # DATABASE.PHP
    # ==========================================

    @"
<?php

\$host = "localhost";
\$dbname = "nome_banco";
\$user = "root";
\$password = "";

try {

    \$pdo = new PDO(
        "mysql:host=\$host;dbname=\$dbname;charset=utf8",
        \$user,
        \$password
    );

    \$pdo->setAttribute(
        PDO::ATTR_ERRMODE,
        PDO::ERRMODE_EXCEPTION
    );

} catch (PDOException \$e) {

    die("Erro na conexão: " . \$e->getMessage());

}

?>
"@ | Set-Content app/config/database.php


    # ==========================================
    # MENSAGEM FINAL
    # ==========================================

    Write-Host ""
    Write-Host "===================================="
    Write-Host " CRUD MVC criado com sucesso!"
    Write-Host ""
    Write-Host " Local:"
    Write-Host $caminhoProjeto
    Write-Host "===================================="
}


# ==========================================
# OPÇÃO INVÁLIDA
# ==========================================

else {

    Write-Host ""
    Write-Host "Opcao invalida!"
}


Write-Host ""
Read-Host "Pressione ENTER para sair"