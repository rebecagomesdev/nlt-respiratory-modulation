library(pacman)
p_load("dplyr", "lme4", "simr")

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
      prob = 0.95 # probabilidade de acerto; [ref]
      ),
    
    # simula 1 /\HRV fixo por fase e sessão , por participante
    Delta_HRV = case_when(
      Fase == "Pre_Neutro" ~ 0, 
      Fase == "Pos_Neutro" & Sessao == "Box" ~ rnorm(1, mean = 15, sd = 2), # [ref]
      Fase == "Pos_Neutro" & Sessao == "Prolongada" ~ rnorm(1, mean = 8, sd = 2), # [ref]
      Fase == "Pos_Neutro" & Sessao == "Hiperventilacao" ~ rnorm(1, mean = -5, sd = 2) # [ref]
    ),
    
    # efeito da sessão no RT
    Efeito_Sessao = case_when(
      Fase == "Pre_Neutro" ~ 0,
      Fase == "Pos_Neutro" & Sessao == "Box" ~ -30, # [ref]
      Fase == "Pos_Neutro" & Sessao == "Prolongada" ~ -40, # [ref]
      Fase == "Pos_Neutro" & Sessao == "Hiperventilacao" ~ +80 # [ref]
    ),
    
    # efeito do hrv no RT
    Efeito_HRV = case_when(
      Fase == "Pre_Neutro" ~ 0,
      Fase == "Pos_Neutro" ~ -2 * Delta_HRV # [ref]
    ),
    
    Desvio_Individual = rnorm(1, mean = 0, sd = 30), # [ref]
    
    # simula o tempo de reação
    RT = ifelse(
      Tipo_Trial == "Repeticao",
      600 + Desvio_Individual +
        rlnorm(n(), meanlog = 3.5, sdlog = 0.5),
      
      800 + Desvio_Individual + Efeito_Sessao + Efeito_HRV +
        rlnorm(n(), meanlog = 3.5, sdlog = 0.5)
    )
  ) %>%
  
  # adiciona colunas dos dados da linha anterior
  mutate(
    Tipo_Anterior = lag(Tipo_Trial),
    Acerto_Anterior = lag(Acerto),
    RT_Anterior = lag(RT),
    
    # calcula o custo de troca somente se...
    Switch_Cost = case_when(
      Tipo_Trial == "Troca" & Acerto == 1 & # o tipo atual de trial for um acerto de troca e...
        Tipo_Anterior == "Repeticao" & Acerto_Anterior == 1 ~ RT - RT_Anterior, # o anterior for um acerto de repetição
      TRUE ~ NA_real_ # O resto é descartado (NA)
    )
  ) %>%
  ungroup() %>%
  arrange(ID_Participante, Sessao, Fase, Trial_N)

head(dados_brutos)
View(dados_brutos)

# verificação

dados_brutos %>%
  group_by(Sessao) %>%
  summarise(Media_Custo = mean(Switch_Cost, na.rm = TRUE))

dados_brutos %>%
  group_by(ID_Participante) %>%
  summarise(
    N_Switch = sum(!is.na(Switch_Cost))
  )

table(
  dados_brutos$ID_Participante,
  dados_brutos$Sessao,
  dados_brutos$Fase
)

nrow(dados_brutos)

n_distinct(dados_brutos$ID_Participante)

sum(!is.na(dados_brutos$Switch_Cost))

# modelo ===========

# o custo de troca é explicado pelos efeitos fixos sessão e hrv, considerando o efeito aleatório do participante (intercepto)
modelo_lmer <- lmer(
  Switch_Cost ~ Sessao * Delta_HRV + (1 | ID_Participante),
  data = dados_brutos
)

summary(modelo_lmer)
VarCorr(modelo_lmer)


# análise de poder simr ===========

# parâmetros
n_maximo <- 60
efeito <- 0.3
ICC <- 0.15

# estende modelo pro n máximo
modelo_estendido <- extend(
  modelo_lmer,
  along = "ID_Participante",
  n = n_maximo)

# ICC
sigma_residual <- sigma(modelo_estendido)

variancia_participante <- 
  sigma_residual^2 * ICC / (1 - ICC)
VarCorr(modelo_estendido)[["ID_Participante"]] <- variancia_participante


# tamanho do efeito

efeito_ms <- efeito * sigma_residual
efeito_ms

fixef(modelo_estendido)["SessaoProlongada:Delta_HRV"] <- -efeito_ms

fixef(modelo_estendido)["SessaoHiperventilacao:Delta_HRV"] <- efeito_ms

# verificar os parâmetros
ICC_observado <- 
  as.numeric(VarCorr(modelo_estendido)$ID_Participante) /
  (
    as.numeric(VarCorr(modelo_estendido)$ID_Participante) +
      sigma(modelo_estendido)^2
  )

cat("Desvio-padrão residual:", sigma_residual, "\n")
cat("Tamanho de efeito:", efeito, "\n")
cat("Efeito em ms:", efeito_ms, "\n")
cat("ICC:", ICC_observado, "\n")

fixef(modelo_estendido)

# análise de poder
set.seed(45)

curva_n_final <- powerCurve(
  modelo_estendido,
  test = fcompare(~ Sessao + Delta_HRV),
  along = "ID_Participante",
  nsim = 10
)

print(curva_n_final)
plot(curva_n_final)

head(curva_n_final$errors)