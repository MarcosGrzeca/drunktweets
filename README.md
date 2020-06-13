# drunktweets
Drunk tweets


## Experimentos Ensemble

### Processo
- Para cada dataset, separei em treinamento e teste
- Roda individualmente cada classificador
- Armazenei a probabilidade da classe positiva para as instâncias de testes
- Cada instância de teste é composta de 3 probabilidades (uma associada a cada classificador)
- As instâncias de testes foram classificadas usando o algoritmo SVMPoly com cross-validation e os resultados apresentados

### Resultados
- https://docs.google.com/spreadsheets/d/1rxl28PVpPsGzPZiD6g1_CjXJbUSD4eOkXsKWFSfc_jM/edit?usp=sharing
- Aba WI + New DL + SVM (DL)


### Files
- `ensembles/ensemblev4/comparador/comparador_oficial_as_classifier_certo.R`
- `ensembles/ensemblev4/comparador/comparador_oficial_as_classifier_certo_ds2.R`

## Experimentos LSTM

### Files
Path: `exp4/svmpoly/lstm/ds1q1.R`

### Geradores
 - DS1-Q1: `adhoc/redemaluca/ds1/dados/q1_redemaluca_lstm_PCA.R`
 - DS1-Q2: ``
 - DS1-Q3: ``
 - DS2: `exp4/svmpoly/lstm/ds2.R` **Verificar**
 - DS3: `adhoc/redemaluca/ds3/dados/ds3_redemaluca_lstm_PCA.R`



## Experimentos Bi-LSTM

