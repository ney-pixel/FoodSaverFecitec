<?php
// Encerra a sessão do usuário (ação "logout" que existia em perfil.php).

require_once __DIR__ . '/../helpers.php';

exigirMetodo(['POST']);
exigirLogin();

$_SESSION = [];
session_destroy();

responder(true, 'Sessão encerrada com sucesso.');
