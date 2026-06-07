# 💡 Sugestões de Melhoria do Modelo

## Status Atual

- ✅ **Normalização Corrigida**: ImageNet normalization adicionada
- ⚠️ **Potencial Gargalo**: Apenas 10 épocas de treinamento podem ser insuficientes

## Análise do Treinamento Atual

### Métricas do Notebook:
```
Epoch 10/10 | train_loss=0.3247 train_acc=0.8750 | val_loss=0.3622 val_acc=0.8588 val_iou=0.657067596912384
```

### Observações:
- ✅ **Convergência bem-comportada**: Loss diminuindo steadily
- ⚠️ **Possível subtreinamento**: Apenas 10 épocas
- ⚠️ **Resolução baixa**: 128x128 pode perder detalhes finos
- ✅ **IoU decente**: 0.657 é razoável mas pode melhorar

## Proposta de Melhoria - Modelo v2

### Mudanças Recomendadas no Notebook:

```python
# ===== VERSÃO 2 - MELHORADA =====

# 1. Aumentar resolução
IMAGE_SIZE = 256  # ao invés de 128 (4x mais pixels!)

# 2. Aumentar épocas
NUM_EPOCHS = 30   # ao invés de 10

# 3. Adicionar técnicas de regularização
def train_epoch_v2(model, loader, optimizer, criterion, scheduler=None):
    model.train()
    total_loss = 0.0
    total_correct = 0
    total_pixels = 0
    
    for imgs, masks in loader:
        imgs = imgs.to(device)
        masks = masks.to(device)
        
        optimizer.zero_grad()
        logits = model(imgs)
        loss = criterion(logits, masks)
        loss.backward()
        
        # Gradient clipping para estabilidade
        torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
        
        optimizer.step()
        
        total_loss += loss.item() * imgs.size(0)
        preds = logits.argmax(dim=1)
        total_correct += (preds == masks).sum().item()
        total_pixels += masks.numel()
    
    # Atualizar scheduler
    if scheduler:
        scheduler.step(total_loss / len(loader.dataset))
    
    return total_loss / len(loader.dataset), total_correct / total_pixels

# 4. Aumentar tamanho do modelo (mais capacidade)
class UNetExpanded(nn.Module):
    def __init__(self, num_classes):
        super().__init__()
        # Duplicar canais em cada nível
        self.down1 = DoubleConv(3, 64)      # 3 -> 64 (era 32)
        self.pool1 = nn.MaxPool2d(2)
        self.down2 = DoubleConv(64, 128)    # 64 -> 128 (era 64)
        self.pool2 = nn.MaxPool2d(2)
        self.down3 = DoubleConv(128, 256)   # 128 -> 256 (era 128)
        self.pool3 = nn.MaxPool2d(2)
        
        self.bottleneck = DoubleConv(256, 512) # 256 -> 512 (era 256)
        
        # Decoders
        self.up3 = nn.ConvTranspose2d(512, 256, kernel_size=2, stride=2)
        self.conv3 = DoubleConv(512, 256)
        self.up2 = nn.ConvTranspose2d(256, 128, kernel_size=2, stride=2)
        self.conv2 = DoubleConv(256, 128)
        self.up1 = nn.ConvTranspose2d(128, 64, kernel_size=2, stride=2)
        self.conv1 = DoubleConv(128, 64)
        
        self.final = nn.Conv2d(64, num_classes, kernel_size=1)
    
    def forward(self, x):
        # Encoder
        x1 = self.down1(x)
        x2 = self.pool1(x1)
        x3 = self.down2(x2)
        x4 = self.pool2(x3)
        x5 = self.down3(x4)
        x6 = self.pool3(x5)
        
        # Bottleneck
        x7 = self.bottleneck(x6)
        
        # Decoder com skip connections
        x8 = self.up3(x7)
        x8 = torch.cat([x5, x8], dim=1)
        x8 = self.conv3(x8)
        
        x9 = self.up2(x8)
        x9 = torch.cat([x3, x9], dim=1)
        x9 = self.conv2(x9)
        
        x10 = self.up1(x9)
        x10 = torch.cat([x1, x10], dim=1)
        x10 = self.conv1(x10)
        
        return self.final(x10)

# 5. Usar no treinamento
model_v2 = UNetExpanded(num_classes=NUM_CLASSES).to(device)

# Otimizador melhorado
optimizer = torch.optim.AdamW(model_v2.parameters(), lr=1e-3, weight_decay=1e-4)
scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=NUM_EPOCHS)

# Função de perda com pesos para classes desbalanceadas
class_weights = torch.tensor([1.0, 2.0, 3.0]).to(device)  # Dar mais peso às classes minoritárias
criterion = nn.CrossEntropyLoss(weight=class_weights)
```

## Melhoras Esperadas

| Métrica | v1 (Atual) | v2 (Esperado) |
|---------|-----------|---------------|
| Resolução | 128x128 | 256x256 |
| Épocas | 10 | 30 |
| Canais Base | 32 | 64 |
| Capacidade | ~400K params | ~2M params |
| **Val Acc** | **85.88%** | **~90%** |
| **Val IoU** | **0.657** | **~0.75** |
| Tempo/Época | ~30s | ~120s |

## Implementação

### Passo 1: Criar nova célula no Notebook
```python
# Cell: Treinar Modelo Expandido
model_v2 = UNetExpanded(num_classes=NUM_CLASSES).to(device)
optimizer = torch.optim.AdamW(model_v2.parameters(), lr=1e-3, weight_decay=1e-4)
scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=30)
criterion = nn.CrossEntropyLoss(weight=torch.tensor([1.0, 2.0, 3.0]).to(device))

# Treinar
for epoch in range(30):
    train_loss, train_acc = train_epoch_v2(model_v2, train_loader, optimizer, criterion, scheduler)
    val_loss, val_acc, val_iou = eval_epoch(model_v2, val_loader, criterion)
    print(f"Epoch {epoch+1}/30 | train_loss={train_loss:.4f} | val_loss={val_loss:.4f} val_acc={val_acc:.4f} val_iou={val_iou:.4f}")
```

### Passo 2: Exportar
```python
# Mesmo código de exportação
torch.onnx.export(model_v2.cpu(), dummy_input, 'model_v2.onnx', opset_version=18)
subprocess.run(['onnx2tf', '-i', 'model_v2.onnx', '-o', 'exported_model_v2'], capture_output=True)
```

### Passo 3: Atualizar App
```dart
// Em tflite_service.dart
_interpreter = await Interpreter.fromAsset('lib/src/assets/pet_segmentation_unet_v2_float32.tflite');
```

## Timeline

- ⏱️ **Treino**: ~60 minutos em Tesla T4 (Colab)
- ⏱️ **Conversão**: ~5 minutos
- ⏱️ **Deploy**: ~30 minutos
- **Total**: ~1.5 horas

## Monitoramento

Após tudo pronto, coletar métricas:

```python
# Evaluar em Test Set
test_loss, test_acc, test_iou = eval_epoch(model_v2, test_loader, criterion)
print(f"Test Accuracy: {test_acc:.4f}")
print(f"Test IoU: {test_iou:.4f}")
```

---

**Nota**: A correção de normalização (já feita) é crítica. As sugestões aqui são para MELHORAR ainda mais, não são mandatórias.

