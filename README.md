# BancoÁgil 📱

Aplicativo mobile de **gerenciamento financeiro** desenvolvido em **Flutter**, concebido como parte de um **Tech Challenge acadêmico**, com foco na aplicação prática de **Clean Architecture**, **gerenciamento avançado de estado**, **programação reativa**, **otimização de performance** e **segurança no desenvolvimento**.

O projeto foi estruturado visando **escalabilidade**, **manutenibilidade**, **separação de responsabilidades** e **boa experiência do usuário**, seguindo boas práticas de engenharia de software e arquitetura front-end moderna.

---

## Principais Funcionalidades

- **Autenticação segura** com Firebase Authentication.
- **CRUD completo**: Cadastro, edição e exclusão de transações financeiras.
- **Transferências entre usuários** com:
  - Validação de saldo.
  - Validação de CPF.
  - Controle transacional e integridade dos dados.
- **Dashboard financeiro** com gráficos analíticos.
- **Upload e visualização de recibos** (armazenados em base64).
- **Filtros dinâmicos** e ordenação de transações.
- **Paginação com scroll infinito**.
- **Interface reativa** e sincronizada com o estado da aplicação.

---

## Tecnologias Utilizadas

- **Flutter / Dart**
- **Firebase Authentication** (Autenticação)
- **Cloud Firestore** (Banco de dados NoSQL)
- **Provider** (Gerenciamento de Estado)
- **Streams e ChangeNotifier** (Programação Reativa)
- **fl_chart** (Visualização de dados/gráficos)
- **image_picker** e **flutter_image_compress** (Manipulação de imagens)
- **intl** (Formatação de datas e valores monetários)
- **flutter_dotenv** (Gerenciamento de variáveis de ambiente)

---

## Arquitetura e Organização do Código

O projeto adota os princípios da **Clean Architecture**, promovendo uma separação clara entre as camadas da aplicação.

### Estrutura em Camadas

- **Presentation**: Contém Widgets, Pages e os Providers (State Management).
- **Domain**: Contém Entidades, Casos de Uso (Use Cases) e os Contratos (Interfaces) de Repositórios.
- **Data / Infrastructure**: Contém Datasources (Firestore), Models e as Implementações dos Repositórios.

**Benefícios:** Baixo acoplamento, alta coesão, facilidade de testes e evolução segura da aplicação.

---

## Gerenciamento Avançado de Estado

- Uso de **Provider + ChangeNotifier**.
- Providers especializados por contexto (Autenticação, Perfil, Transações, Filtros).
- Separação clara entre **estado de UI**, **estado de domínio** e **estado derivado**.
- Fluxo de dados previsível e rastreável.

---

## Programação Reativa

A aplicação garante uma interface responsiva através de:

- Uso de **Streams** para observar alterações em tempo real no Firestore.
- Reatividade a mudanças de filtros, paginação e atualizações de saldo.
- UI sempre sincronizada com a fonte de dados (Single Source of Truth).
- Eliminação de estados inconsistentes entre telas.

---

## Performance e Otimização

- **Lazy Loading**: Carregamento sob demanda na listagem de transações.
- **Prefetch**: Pré-carregamento de páginas subsequentes.
- **Cache em memória**: Redução de chamadas redundantes ao banco de dados.
- **Scroll infinito**: Otimização para grandes volumes de dados.
- **Rebuilds seletivos**: Uso de seletores para evitar renderizações desnecessárias.

---

## Segurança no Desenvolvimento

- **Isolamento de dados**: Garantia de que um usuário nunca acesse dados de outro.
- **Regras de Segurança do Firestore**:
  - Leitura e escrita permitidas apenas para o proprietário do documento (`request.auth.uid`).
  - Transferências controladas via regras de servidor.
- **Normalização**: CPF armazenado apenas em formato numérico para padronização.
- **Proteção de Credenciais**: Uso de variáveis de ambiente (`.env`) para chaves sensíveis.

---

## Estrutura do Projeto (Pastas)

```text
lib/
 ├── features/
 │    ├── auth/
 │    ├── user/
 │    └── transactions/
 │         ├── domain/ (entities, repositories, usecases)
 │         ├── data/ (datasources, models, repositories)
 │         └── presentation/ (pages, providers, widgets)
 ├── widgets/ (common components)
 ├── core/ (utils, constants, themes)
 ├── firebase_options.dart
 └── main.dart
 ```

## Configuração do Firebase
1) Criar Projeto no Firebase
Ative o Authentication (método E-mail/Senha).
Crie o banco de dados Cloud Firestore.
Registre o app Android/iOS para obter os IDs.
2) Configurar Variáveis de Ambiente
Crie um arquivo .env na raiz do projeto seguindo o modelo:

**env**
**FIREBASE_ANDROID_API_KEY=sua_chave_aqui**
**FIREBASE_ANDROID_APP_ID=seu_app_id**
**FIREBASE_ANDROID_MESSAGING_SENDER_ID=seu_id**
**FIREBASE_ANDROID_PROJECT_ID=seu_projeto_id**
**FIREBASE_ANDROID_STORAGE_BUCKET=seu_bucket**

Para aplicar as configurações:

**cp .env.example .env**


# Como Executar o Projeto

# Instalar dependências
flutter pub get

# Executar o projeto

**flutter run**

**Regras de Segurança (Firestore)**

Exemplo das regras aplicadas no console do Firebase:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() {
      return request.auth != null;
    }

    match /users/{uid} {
      allow read, create, update: if request.auth.uid == uid;
      allow delete: if false;
    }

    match /transactions/{id} {
      allow read, create: if request.auth.uid == resource.data.userId;
      allow update, delete: if request.auth.uid == resource.data.userId
        && resource.data.type != 'transfer';
    }
  }
}
```

## Scripts Úteis

**flutter clean          # Limpa o build**
**flutter pub upgrade    # Atualiza pacotes**
**dart format .          # Formata o código conforme padrões Dart**
**flutter build apk      # Gera o executável para Android**

## Observações Finais
Armazenamento de Imagens: Os recibos são convertidos para base64 e salvos no Firestore para simplificar a estrutura e custos iniciais (evitando o Firebase Storage neste MVP).
Tech Challenge: O projeto atende integralmente aos requisitos acadêmicos, com foco em arquitetura profissional e escalável.