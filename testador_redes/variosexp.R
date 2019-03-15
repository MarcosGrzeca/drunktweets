epochs <- c(2,3,4)

batchs <- c(32, 64, 128, 164, 200)

for (epoch in epochs) {
  print(epoch)

  for (batch in batchs) {
  
    print(batch)  
  }
}
