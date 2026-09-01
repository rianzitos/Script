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

# Cria a pasta principal
$desktop = [Environment]::GetFolderPath("Desktop")

New-Item -ItemType Directory -Path "$desktop\$nome" -Force | Out-Null

Set-Location "$desktop\$nome"

switch ($tipo) {

    # ==========================================
    # FRONT-END
    # ==========================================

    "1" {

        Write-Host ""
        Write-Host "Criando projeto Front-end..."

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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

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

        Write-Host ""
        Write-Host "Projeto Front-end criado com sucesso!"
    }


    # ==========================================
    # CRUD MVC PHP
    # ==========================================

    "2" {

        Write-Host ""
        Write-Host "Criando projeto CRUD MVC..."

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
            New-Item -ItemType Directory -Path $pasta -Force | Out-Null
        }

        # Arquivos
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
            New-Item $arquivo -ItemType File | Out-Null
        }

        # index.php
        @"
<?php

echo "Projeto $nome funcionando!";

?>
"@ | Set-Content public/index.php

        # Conexão PDO
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

        Write-Host ""
        Write-Host "Projeto CRUD MVC criado com sucesso!"
    }




    default {

        Write-Host ""
        Write-Host "Opcao invalida!"
    }
}

Write-Host ""
Write-Host "===================================="
Write-Host " Projeto criado em:"
Write-Host (Get-Location)
Write-Host "===================================="
Write-Host ""

Read-Host "Pressione ENTER para sair"