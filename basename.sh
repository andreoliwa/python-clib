#!/bin/bash
# Considera todos os argumentos da linha de comando como um nome de arquivo, mesmo com espaços
FILENAME=$*
BASENAME=$(basename "${FILENAME}")
echo "'${BASENAME}'"
