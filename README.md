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


### Gerar embeddings
- DS1-Q1: `adhoc/exportembedding/ds1/lstm_q1.R`

- DS3:
  - `adhoc/exportembedding/ds3/lstm_10_epocas_v2.txt`

### Geradores média
- DS1-Q1: `adhoc/redemaluca/ds1/dados/q1_redemaluca_lstm_PCA.R`
- DS1-Q2: ``
- DS1-Q3: ``
- DS2: `exp4/svmpoly/lstm/ds2.R` **Verificar**
- DS3: `adhoc/redemaluca/ds3/dados/ds3_redemaluca_lstm_PCA.R`
  - `adhoc/redemaluca/ds3/ds3_representacao_with_lstm_pca_15.RData`



## Experimentos Bi-LSTM

### Info úteis
 - Folder: `ipmbilstm`

### Passos
1 - Gerar embeddings
2 - Gerar média de cada tweet
3 - Classificar similar a `exp4/svmpoly/lstm/ds3.R`

### Gerar embeddings
- DS1-Q1: `ipmbilstm/exportembedding/ds1/bilstm_q1.R`
  - `ipmbilstm/exportembedding/ds1/q1/bilstm_10_epocas.txt`
- DS1-Q2:
- DS1-Q3:
- DS2: 
- DS3: `ipmbilstm/exportembedding/ds3/lstm_oficial.R`
  - `bilstm/exportembedding/ds3/bilstm_10_epocas_v2.txt`

### Gerar média de cada tweet
- DS1-Q1: `ipmbilstm/ds1/dados/q1_redemaluca_bilstm_PCA.R`
  - `ipmbilstm/exportembedding/ds1/q1_representacao_bilstm_pca.RData`
- DS1-Q2:
- DS1-Q3:
- DS2: 
- DS3: `ipmbilstm/exportembedding/ds3/ds3_redemaluca_bilstm_PCA.R`
  - `ipmbilstm/exportembedding/ds3/ds3_representacao_with_bilstm_pca_15.RData`

### Executar os classificadores
- DS1-Q1: `exp4/svmpoly/bilstm/ds1q1.R`
- DS1-Q2:
- DS1-Q3:
- DS2: 
- DS3: 


### Resultados
[Planilha de resultados](https://docs.google.com/spreadsheets/d/112byd2PSnWVh7KbdJP3AlDGEZne6a-5zVCjZrbNqXTg/edit?usp=sharing)

## Restore Database

Remover linhas
- SET @MYSQLDUMP_TEMP_LOG_BIN = @@SESSION.SQL_LOG_BIN;
- SET @@SESSION.SQL_LOG_BIN= 0;
- SET @@GLOBAL.GTID_PURGED='d2298455-xxxx-xxxx-xxxx-42010a980029:1-3413775';
- SET @@SESSION.SQL_LOG_BIN = @MYSQLDUMP_TEMP_LOG_BIN

[Fonte](https://help.poralix.com/articles/mysql-access-denied-you-need-the-super-privilege-for-this-operation)