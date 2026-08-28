# AGENTS.md

## 1. Projeto

Este repositório utiliza um fluxo de desenvolvimento assistido por agentes especializados.

As informações específicas do projeto devem ser mantidas e atualizadas pelo agente responsável conforme o projeto evoluir.

### Identificação

- **Nome do projeto:** Focenda
- **Descrição:** Aplicativo nativo macOS focado em produtividade pessoal, gestão de foco, tarefas e tempo, 100% gratuito e open source.
- **Objetivo principal:** Proporcionar uma experiência fluida, rápida, elegante e 100% user-friendly para usuários de Mac maximizarem seu foco e organização diária.
- **Plataforma:** macOS (Apple Silicon e Intel, macOS 14.0+)
- **Stack principal:** 100% Swift, SwiftUI, Swift Concurrency, AppKit, XCTest
- **Repositório:** https://github.com/OOMestre/Focenda
- **Ambiente principal:** macOS nativo / Xcode

---

## 2. Princípios Gerais

Todos os agentes devem:

- ler este documento antes de iniciar ou continuar qualquer tarefa;
- consultar a documentação atual do projeto;
- entender o estado atual antes de modificar arquivos;
- preservar decisões já consolidadas;
- evitar alterações fora do escopo solicitado;
- evitar complexidade desnecessária;
- não introduzir dependências sem necessidade real;
- manter o projeto 100% Swift nativo e o mais user-friendly possível;
- documentar alterações relevantes;
- preservar compatibilidade com funcionalidades existentes;
- verificar possíveis regressões com testes automatizados;
- trabalhar sempre sobre o estado real e mais recente do projeto.

---

## 3. Arquitetura de Desenvolvimento Multi-Chat (Git Worktrees)

O desenvolvimento do Focenda adota o modelo **Multi-Chat Isolado por Git Worktree + Chat Integrador (Merge Master)**:

```
                  ┌───────────────────────────────────────────────┐
                  │          Branch Principal: staging            │
                  └──────────────────────┬────────────────────────┘
                                         │
                 ┌───────────────────────┼───────────────────────┐
                 │                       │                       │
                 ▼                       ▼                       ▼
      [Chat 1 / Worktree 1]    [Chat 2 / Worktree 2]    [Chat 3 / Worktree 3]
       .worktrees/feat-timer    .worktrees/feat-tasks    .worktrees/fix-layout
       (Branch: feat/timer)     (Branch: feat/tasks)     (Branch: fix/layout)
                 │                       │                       │
                 │ make test             │ make test             │ make test
                 │ commit (OOMestre)     │ commit (OOMestre)     │ commit (OOMestre)
                 │ push origin           │ push origin           │ push origin
                 └───────────────────────┼───────────────────────┘
                                         │
                                         ▼
                      ┌──────────────────────────────────────┐
                      │    Chat Integrador (Merge Master)    │
                      │  - git merge das branches            │
                      │  - Resolução de conflitos            │
                      │  - Validação geral (make test)       │
                      │  - make staging & push origin        │
                      │  - Limpeza de worktrees concluídos   │
                      └──────────────────────────────────────┘
```

---

## 4. Papéis dos Chats

### A. Chats de Demanda / Feature Workers (Comportamento Padrão e Automático)
- **Zero Overhead para o Usuário:** O usuário apenas descreve o que quer em linguagem natural (ex: *"Crie exportação de notas em PDF"* ou *"Corrija o bug do timer"*), sem precisar mencionar branches ou comandos.
- **Passo 1 (Automático):** O agente identifica o tipo da demanda e cria seu worktree isolado imediatamente:
  ```bash
  make worktree-add NAME=<nome-da-demanda> BRANCH=feat/<nome-da-demanda>
  ```
- **Passo 2 (Execução):** O agente trabalha **exclusivamente** dentro do diretório do worktree criado (`/Users/lucassantanalemos/Projects/Focenda/.worktrees/<nome-da-demanda>`), sem alterar a raiz.
- **Passo 3 (Testes):** Valida a implementação rodando os testes no worktree (`swift test`).
- **Passo 4 (Commit & Push):** Registra o commit convencional com autor `OOMestre` e sobe a branch para o remoto:
  ```bash
  git push origin <branch>
  ```
- **Passo 5 (Aviso):** Informa ao usuário que a demanda está concluída e que a branch `<branch>` está pronta para o Chat Integrador.

### B. Chat Integrador (Merge Master)
- Centraliza a consolidação das branches finalizadas no repositório principal (`staging`).
- Quando o usuário pedir para integrar as features feitas nos outros chats:
  1. Atualiza `staging` com o remoto (`git checkout staging && git pull origin staging`).
  2. Realiza o merge ordenado das branches (`git merge origin/<branch>`).
  3. **Resolução de Conflitos:** Analisa e resolve qualquer conflito preservando ambas as implementações e as diretrizes do projeto.
  4. Valida a suíte global de testes localmente (`make test` — 100% pass, 0 falhas).
  5. Executa o build de staging (`make staging`).
  6. Publica as integrações em `origin/staging` (`git push origin staging`).
  7. **Limpeza Total de Branches (Local + Remoto):** Remove o worktree e **deleta a branch local e remota no GitHub** (`make worktree-remove NAME=<nome>` e `git push origin --delete <branch>`). Branches integradas **NUNCA** devem se acumular no repositório GitHub.
  8. **Garantia Obrigatória de GitHub Actions CI:** Acompanha a execução do CI (`gh run watch <id> --exit-status` ou `gh run list`) e garante que todos os jobs no GitHub Actions passem com **100% de sucesso (verde)**. Se houver qualquer falha (concorrência, build, testes), corrige e envia nova correção imediatamente até o CI ficar verde.

---

## 5. Gerenciamento de Worktrees

Comandos disponíveis via Makefile:

- **Criar novo worktree para chat:**
  ```bash
  make worktree-add NAME=minha-feature BRANCH=feat/minha-feature
  ```
  *(Cria o worktree em `.worktrees/minha-feature` baseado no `staging` mais recente)*

- **Listar worktrees ativos:**
  ```bash
  make worktree-list
  ```

- **Remover worktree integrado:**
  ```bash
  make worktree-remove NAME=minha-feature
  ```

---

## 6. Git e Fluxo de Commits

Conventional Commits com autor `OOMestre`:
- `feat: <description>`
- `fix: <description>`
- `refactor: <description>`
- `test: <description>`
- `docs: <description>`
- `chore: <description>`
- `release: <version>`

Branches:
- **`staging`**: Branch principal de trabalho e integração contínua.
- **`feat/*`, `fix/*`, `refactor/*`**: Branches de trabalho isoladas em worktrees.
- **`main`**: Branch de produção estável, exclusivamente para releases oficiais aprovadas.
