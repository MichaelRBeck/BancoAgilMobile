BancoÁgil 📱

Aplicativo mobile de gerenciamento financeiro desenvolvido em Flutter.

Principais funcionalidades:

Login com Firebase Authentication

Cadastro, edição e listagem de transações

Transferências entre usuários com validação de saldo

Upload de recibos (salvos em base64)

Dashboard com gráficos (linha e pizza) mostrando receitas, despesas e transferências

Filtros e ordenação de transações (por tipo, valor, data, etc.)

Scroll infinito para lidar com grandes volumes de dados

Tecnologias utilizadas

Flutter / Dart

Firebase (Auth e Firestore)

Provider para gerenciamento de estado

fl_chart para os gráficos

image_picker e flutter_image_compress para recibos

intl para formatação de moeda/data

flutter_dotenv para variáveis de ambiente

Estrutura do projeto
lib/
  pages/
    main_shell.dart
    login_page.dart
    dashboard_page.dart
    transactions_page.dart
    transaction_form_page.dart
    receipt_viewer_page.dart
  widgets/
    charts/
      line_chart_widget.dart
      pie_chart_widget.dart
    transactions/
      filters_bar.dart
    common/
      greeting_header.dart
      kpi_card.dart
      totals_bar.dart
      receipt_attachment.dart
    sign_out_action.dart
  state/
    auth_provider.dart
    user_provider.dart
    filters_provider.dart
    transactions_provider.dart
  services/
    transactions_service.dart
    transfer_local_service.dart
  utils/
    animated_routes.dart
    cpf_input_formatter.dart
    cpf_validator.dart
    formatters.dart
  firebase_options.dart

Configuração do Firebase
1) Criar projeto no Firebase

Ativar Authentication (e-mail/senha)

Criar Firestore Database

Pegar as credenciais em Configurações do Projeto > Seus Apps

2) Arquivo .env

Crie um arquivo .env na raiz do projeto com as credenciais:

.env.example

# Firebase Android
FIREBASE_ANDROID_API_KEY=
FIREBASE_ANDROID_APP_ID=
FIREBASE_ANDROID_MESSAGING_SENDER_ID=
FIREBASE_ANDROID_PROJECT_ID=
FIREBASE_ANDROID_STORAGE_BUCKET=

# Firebase iOS
FIREBASE_IOS_API_KEY=
FIREBASE_IOS_APP_ID=
FIREBASE_IOS_MESSAGING_SENDER_ID=
FIREBASE_IOS_PROJECT_ID=
FIREBASE_IOS_STORAGE_BUCKET=
FIREBASE_IOS_BUNDLE_ID=com.miker.bancoagil


Copiar o modelo:

cp .env.example .env


E preencher com os valores reais.

Como rodar o projeto
# baixar dependências
flutter pub get

# rodar no emulador/dispositivo
flutter run


Para iOS pode ser necessário rodar cd ios && pod install antes.

Funcionalidades

Dashboard: visão geral do saldo e gráficos de receitas, despesas e transferências

Transações: listagem com filtros e ordenação (mais recente, mais antigo, maior valor, menor valor)

Formulário: adicionar/editar transação com recibo (em base64), validações de saldo e CPF em transferências

Autenticação: login e controle de sessão do usuário

Regras de segurança (Firestore)

Exemplo de regra simples para garantir que cada usuário só acesse suas transações:

// Exemplo inicial, ajustar conforme necessidade
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /transactions/{id} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}

Scripts úteis
flutter clean         # limpar cache
flutter pub get       # baixar pacotes
flutter pub upgrade   # atualizar pacotes
dart format .         # formatar código
flutter build apk     # gerar APK release

Observações

O app está configurado para salvar recibos em base64 no Firestore.

Para produção seria possível migrar para o Firebase Storage, mas não é necessário para o funcionamento.
