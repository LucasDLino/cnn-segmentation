# CNN Segmentation activity

Um projeto Flutter que demonstra segmentação de imagens de animais de estimação (pets) usando um modelo UNet treinado e convertido para TensorFlow Lite. O app executa inferência localmente (on-device), gera uma máscara segmentada (pet, borda e fundo) e exibe o resultado junto com uma legenda de cores.

Principais objetivos
- Exemplo prático de integração de modelo TFLite em um app Flutter.
- Inferência de segmentação de imagem diretamente no dispositivo (privacidade e performance).
- Visualização e pós-processamento simples da máscara de saída.

Funcionalidades
- Carregar imagens de exemplo ou uma foto da galeria/câmera.
- Processamento local usando `lib/src/assets/pet_segmentation_unet_float32.tflite`.
- Geração de máscara com cores diferenciadas (pet, borda, fundo).
- Tela de resultados com imagem original, máscara e legenda de cores.

Estrutura relevante do projeto
- `lib/src/features/segmentation/services/tflite_service.dart` — código de pré-processamento, inferência e geração da máscara PNG.
- `lib/src/features/presentation/pages/result_screen.dart` — exibe a imagem original e a máscara retornada pelo `TFLiteService`.
- `lib/src/assets/pet_segmentation_unet_float32.tflite` — arquivo do modelo TFLite (embutido via `pubspec.yaml`).

Requisitos
- Flutter SDK instalado (compatível com a versão usada no projeto).
- Emulador ou dispositivo Android/iOS configurado.

Como executar (rápido)
```powershell
cd C:\Users\lucas\StudioProjects\meu_grupo
flutter pub get
flutter run
```

Notas sobre o modelo TFLite
- Local do arquivo: `lib/src/assets/pet_segmentation_unet_float32.tflite`.
- Saída esperada: mapa de classes por pixel. O `TFLiteService` faz argmax (ou round) por pixel e mapeia para cores:
  - Pet/Animal — cor verde
  - Borda/Contorno — cor vermelha
  - Fundo — cor preta
- Se a máscara aparecer invertida (cores trocadas), verifique o mapeamento no arquivo `tflite_service.dart` e a ordem das classes no tensor de saída.

Uso dentro do app
- A tela de segmentação/processamento carrega a imagem e chama `TFLiteService.predict(...)`. O método retorna um PNG da máscara (Uint8List) que é exibido em `ResultScreen`.


Contribuindo
- Bug reports e PRs são bem-vindos. Para mudanças no modelo, inclua notas sobre como o modelo foi treinado e convertido.

Licença
- GNU GENERAL PUBLIC LICENSE (ver arquivo `LICENSE` no repositório)

Contato
- Para dúvidas ou suporte, inclua um e-mail ou link para o repositório.

----
Arquivo gerado/atualizado automaticamente para facilitar entendimento e uso do projeto.
