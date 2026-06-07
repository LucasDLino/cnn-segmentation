# Atividade - Segmentação Semântica

## Passos recomendados para instalação do ambiente de treinamento

- Conda
- Python 3.10
- CUDA 11.8
- Testado com essas configurações e funcional
- Utilizar Colab pode facilitar o desenvolvimento

```bash
conda create --name deepl python=3.10 --no-default-packages
conda activate deepl
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
pip install -r requirements.txt
```

---

# Hands-on

A atividade consiste em realizar algumas tarefas principais condizentes com o pipeline padrão adotado em problemas de segmentação semântica e implantação.

Seu objetivo geral é treinar um modelo de segmentação semântica, implantar esse modelo no seu smartphone. Por fim, enviar um print e o link do seu repositório pelo classroom.

---

# Sugestões de implementação para treinamento

## Etapa 1: Introdução e treinamento de segmentação

### Dataset
- Oxford-IIIT Pet  
  (disponível em `torchvision.datasets.OxfordIIITPet`)

### Recomendações
- Utilizar recorte reduzido do dataset para facilitar treinamento
- Pode utilizar `torch.utils.data.Subset`

### Modelo sugerido
- UNet

---

## Etapa 2: Avaliação de desempenho e métricas

### Métricas sugeridas
- IoU
- Acurácia

### Biblioteca recomendada
- `torchmetrics`

---

## Etapa 3: Visualização dos resultados

### Aplicativo de smartphone
Implementar código para aplicativo de smartphone.

### Funcionalidades
- Realizar predição no aplicativo
- Exibir a imagem com a máscara sobreposta

---

# Entregáveis

- Print do aplicativo funcionando com a segmentação em imagem
- Link do repositório com a sua implementação

---

# Sugestões de implementação para aplicação Android

- Seleção de imagem via Foto/Armazenamento
- `ImageView` para Original / Máscara Segmentada
- Botão para Inferência do modelo
- Execução do modelo em FP32
