library(shiny)
library(stringr)
library(stringi)
library(wordcloud2)
library(dplyr)
library(tm)
## probelmas no operado AND
## operador ? pode equivaler ao NEAR

convert_boolean_to_regex <- function(query) {
  # 1. Substituir frases exatas por tokens temporários
  phrases <- str_extract_all(query, '"[^"]+"')[[1]]
  temp_phrases <- paste0("<<PHRASE", seq_along(phrases), ">>")
  for (i in seq_along(phrases)) {
    query <- str_replace_all(query, fixed(phrases[i]), temp_phrases[i])
  }

  # 2. Converter operadores
  query <- str_replace_all(query, "\\bAND\\b", "&&")
  query <- str_replace_all(query, "\\bOR\\b", "||")

  # 3. Recolocar frases exatas
  for (i in seq_along(phrases)) {
    clean_phrase <- str_remove_all(phrases[i], '"')
    query <- str_replace_all(query, fixed(temp_phrases[i]), clean_phrase)
  }

  # 4. Recursivamente converter:
  #    - A ∧ B => (?=.*A)(?=.*B)
  #    - A ∨ B => (A|B)
  #    (mantém parênteses)
  process_logic <- function(q) {
    # Remove excesso de espaços
    q <- str_trim(q)

    # Se contém ||
    if (str_detect(q, "\\|\\|")) {
      parts <- str_split(q, "\\|\\|")[[1]]
      return(paste0("(", paste(sapply(parts, process_logic), collapse = "|"), ")"))
    }

    # Se contém &&
    if (str_detect(q, "&&")) {
      parts <- str_split(q, "&&")[[1]]
      return(paste0(paste0("(?=.*", sapply(parts, process_logic), ")"), collapse = ""))
    }

    # Se for grupo entre parênteses
    if (str_detect(q, "^\\(.*\\)$")) {
      inner <- str_sub(q, 2, -2)
      return(process_logic(inner))
    }

    return(q)
  }

  regex_core <- process_logic(query)
  return(regex_core)
}


server <- function(input, output) {

  # Leitura dos dados
  dados <- reactive({
    req(input$datafile)
    read.csv(input$datafile$datapath, header = input$header, sep = input$sep, quote = input$quote)
  })

  #syntax
   output$texto_destacado <- renderUI({
    texto <- input$expressao


    # Marca strings com delimitadores
    texto <- str_replace_all(texto, "'([^']*)'", "[[CLASS:string]]'\\1'[[/CLASS]]")

    # Marca números
    texto <- str_replace_all(texto, "\\b(\\d+(\\.\\d+)?)\\b", "[[CLASS:numero]]\\1[[/CLASS]]")

    # Palavras-chave lógicas
    texto <- str_replace_all(texto, "\\b(AND|OR|NOT)\\b", "[[CLASS:op-logico]]\\1[[/CLASS]]")

    # Operadores simbólicos
    simbolos <- c("==", ">=", "<=", ">", "<", "\\|", "&", "\\*")
    for (s in simbolos) {
      texto <- str_replace_all(texto, s, function(x) {
        str_c("[[CLASS:op-simbolo]]", x, "[[/CLASS]]")
      })
    }

    # Parênteses
    texto <- str_replace_all(texto, "\\(", "[[CLASS:parenteses]]([[/CLASS]]")
    texto <- str_replace_all(texto, "\\)", "[[CLASS:parenteses]])[[/CLASS]]")

    # Por fim, converte marcadores em spans HTML
    texto <- texto |>
      str_replace_all("\\[\\[CLASS:(.*?)\\]\\]", "<span class='\\1'>") |>
      str_replace_all("\\[\\[/CLASS\\]\\]", "</span>")

    HTML(texto)


  })


   # selecionando variável
  output$varselect <- renderUI({
    req(dados())
    selectInput("vars", "Select a variable for Search:",
                choices = c("Sem Seleção", names(dados())),
                multiple = F,
                selected = NULL)
  })

  #df_filtrado
  df_filtrado <- reactive({
    req(dados(), input$vars)  # ou outros inputs de filtro


    df <- dados()
    var = input$vars

    if (nzchar(input$expressao) && var != "Sem Seleção") {
      df_filtrado <- df[str_detect(df[[var]], regex(convert_boolean_to_regex(input$expressao),
                                                    ignore_case = T)),
                        , drop = FALSE]

      return(df_filtrado)
    } else {
      return(dados())
    }

  })

  # tabela
  output$table <- renderDT({
    req(df_filtrado()) #, input$expressao

    df_filtrado()

  },
   extensions = c('Buttons', "Responsive"),
  options = list(dom = 'lBripS',
                 pageLength = 5,
                 lengthMenu = c(5, 10, 15, 20),
                 buttons = I('colvis'),
                # scrollX = TRUE,
                # autoWidth = TRUE,
                 columnDefs = list(list(targets = "_all", className = "dt-nowrap"))
              )

  )

  output$downloadBtn <- renderUI({
    req(df_filtrado())  # Só renderiza o botão se houver dados

    downloadButton("downloadData", "Download")

  })

  #download
  output$downloadData <- downloadHandler(

    filename = paste0("SyntaxSearch_filter_", format(Sys.time(), "%d_%b_%Y_%Hh_%Mm_%Ss"), ".csv"),

    content = function(file) {
      req(df_filtrado())

      write.csv(df_filtrado(), file)
    }

  )

  # nuvem de palavra

  output$nuvem <- renderWordcloud2({
    req(input$vars)
    req(df_filtrado())

    if(input$vars!= "Sem Seleção"){
    texto <- df_filtrado()[[input$vars]] #dados()[[input$vars]]

    # Pré-processamento do texto
    palavras <- tolower(paste(texto, collapse = " "))
    palavras <- removePunctuation(palavras)
    palavras <- stri_trans_general(palavras, "Latin-ASCII")
    palavras <- removeWords(palavras, stopwords("pt"))  # ou "en", dependendo do idioma
    palavras <- strsplit(palavras, "\\s+")[[1]]

    # Criar tabela de frequência
    tabela <- table(palavras)
    tabela_df <- as.data.frame(tabela, stringsAsFactors = FALSE)
    colnames(tabela_df) <- c("word", "freq")

    wordcloud2(tabela_df,  minSize = input$slider)

    }
  })


}



