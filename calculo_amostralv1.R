library(pacman)
p_load("dplyr")

# matriz base (fase neutra pré e pós respiração)

dados_brutos <- expand.grid(
  ID_Participante = 1:30,
  Sessao = c("Box", "Prolongada", "Hiperventilacao"),
  Fase = c("Pre_Neutro", "Pos_Neutro"), 
  Trial_N = 1:50 
) %>% #  utiliza o resultado anterior no próximo passo
  
  group_by(
    ID_Participante, Sessao, Fase # agrupa por essas variáveis
    ) %>%
  mutate(
    # faz a distribuição aleatória de cada tipo de trial isoladamente considerando as colunas agrupadas
    Tipo_Trial = sample(rep(c("Repeticao", "Troca"), times = 25)),
    
    # simula os acertos
    Acerto = rbinom( # modela uma situação que só tem 2 saídas (acerto ou erro)
      n(), # quantos vezes precisará gerar um resultado (número de linhas esperado, 50)
      1, # número de tentativas por trial
      prob = 0.85 # probabilidade de acerto; [ref]
      ),
    
    # simula 1 /\HRV fixo por fase e sessão , por participante
    Delta_HRV = case_when(
      Fase == "Pre_Neutro" ~ 0, 
      Fase == "Pos_Neutro" & Sessao == "Box" ~ rnorm(1, mean = 15, sd = 2), # [ref]
      Fase == "Pos_Neutro" & Sessao == "Prolongada" ~ rnorm(1, mean = 8, sd = 2), # [ref]
      Fase == "Pos_Neutro" & Sessao == "Hiperventilacao" ~ rnorm(1, mean = -5, sd = 2) # [ref]
    ),
    
    # simula o tempo de reação bruto
    RT_Bruto = ifelse(
      Tipo_Trial == "Repeticao", 
      rnorm(n(), mean = 600, sd = 100), # [ref]
      rnorm(n(), mean = 800, sd = 100)  # [ref]
    )
  ) %>%
  
  # adiciona colunas dos dados da linha anterior
  mutate(
    Tipo_Anterior = lag(Tipo_Trial),
    Acerto_Anterior = lag(Acerto),
    RT_Anterior = lag(RT_Bruto),
    
    # calcula o custo de troca somente se...
    Switch_Cost = case_when(
      Tipo_Trial == "Troca" & Acerto == 1 & # o tipo atual de trial for um acerto de troca e...
        Tipo_Anterior == "Repeticao" & Acerto_Anterior == 1 ~ RT_Bruto - RT_Anterior, # o anterior for um acerto de repetição
      TRUE ~ NA_real_ # O resto é descartado (NA)
    )
  ) %>%
  ungroup() %>%
  arrange(ID_Participante, Sessao, Fase, Trial_N)

head(dados_brutos)
View(dados_brutos)