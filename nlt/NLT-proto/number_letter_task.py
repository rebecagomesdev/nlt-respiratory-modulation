import random
import asyncio
from PyQt5.QtCore import QThread, pyqtSignal

class number_letter_task(QThread):
    # envia as informações para construir o teste
    data = pyqtSignal(list, list, list)

    def __init__(self):
        super().__init__()

    def run(self):
        """ Inicia a thread """
        loop = asyncio.new_event_loop()
        loop.run_until_complete(self.trials())

    async def trials(self):
        """ sorteia e armazena os trials do experimento """
        
        trial_builder = list()
        block_indicators = list()
        current_index = 0

        # --- Função Auxiliar de Geração ---
        # Facilita a criação de blocos definindo quantos trials e quais quadrantes usar
        def add_trials(nome_bloco, num_trials, quadrantes_permitidos):
            nonlocal current_index
            for n in range(num_trials):
                number = random.randint(2, 9)
                letter = random.choice("AEIUBLDH")
                quadrant = random.choice(quadrantes_permitidos)

                # --- IDENTIFICAÇÃO DO CUSTO DE TROCA ---
                # Identifica se é Trial de Repetição ou Troca (Essencial para o projeto FAPESP)
                tipo_trial = "N/A" # O primeiro trial de todos não tem classificação
                if current_index > 0:
                    quad_anterior = trial_builder[-1]['quadrant']
                    
                    # Se ambos estão em cima (Letra) ou ambos em baixo (Número), é Repetição
                    if (quadrant in [0, 1] and quad_anterior in [0, 1]) or (quadrant in [2, 3] and quad_anterior in [2, 3]):
                        tipo_trial = "Repeticao"
                    else:
                        tipo_trial = "Troca"

                trial_builder.append({
                    'number': number, 
                    'letter': letter, 
                    'quadrant': quadrant, 
                    'block': nome_bloco,
                    'tipo_trial': tipo_trial # Esta variável vai direta para o CSV!
                })
                current_index += 1


        
        # (0) BLOCO DE FAMILIARIZAÇÃO
        
        # apenas letras (cima: quadrantes 0 e 1)
        add_trials("Familiarizacao", 12, [0, 1])
        block_indicators.append(current_index) # Pausa

        # apenas números (baixo: quadrantes 2 e 3)
        add_trials("Familiarizacao", 12, [2, 3])
        block_indicators.append(current_index) # Pausa

        # misto
        add_trials("Familiarizacao", 16, [0, 1, 2, 3])
        block_indicators.append(current_index) # fim do bloco 1. pausa para começar o bloco de baseline.


        # (1 a 5) BLOCOS EXPERIMENTAIS
        
        add_trials("Linha_de_Base", 40, [0, 1, 2, 3])
        block_indicators.append(current_index)

        add_trials("Motivacional_Simetrico", 40, [0, 1, 2, 3])
        block_indicators.append(current_index)

        add_trials("Assimetria_Punicao", 40, [0, 1, 2, 3])
        block_indicators.append(current_index)

        add_trials("Assimetria_Recompensa", 40, [0, 1, 2, 3])

        # CÁLCULO DOS GABARITOS
        right_answers_nl_test = list()

        for trial in trial_builder:
            # Quadrantes superiores (Letra)
            if trial['quadrant'] in [0, 1]:
                if trial['letter'] in "AEIOU":
                    right_answers_nl_test.append("VOWEL")
                else:
                    right_answers_nl_test.append("CONSONANT")
            
            # Quadrantes inferiores (Número)
            else:
                if trial['number'] % 2 == 0:
                    right_answers_nl_test.append("EVEN")
                else:
                    right_answers_nl_test.append("ODD")

        # Emite tudo pronto de volta para o teste.py
        self.data.emit(trial_builder, right_answers_nl_test, block_indicators)