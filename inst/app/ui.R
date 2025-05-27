library(shiny)
library(DT)
library(wordcloud2)



ui <- fluidPage(
  tags$head(
    tags$link(href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap", rel="stylesheet"),
   # tags$link(href="https://cdn.jsdelivr.net/npm/bootstrap@4.0.0/dist/css/bootstrap.min.css", rel="stylesheet"),
    tags$style(HTML("
      body {
        font-family: 'Inter', sans-serif;
        margin: 10px;
        background: #ffffff;
        color: #333;
      }
      header {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        justify-content: space-between;
        background: #ffffff;
        padding: 10px;
        margin-bottom: 10px;
        box-shadow: 2px 2px 5px rgba(0,0,0,0.05);
      }
      header img {
        height: 100px;
      }
      nav {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
        margin-top: 10px;
      }
      nav button {
        padding: 8px 16px;
        border: none;
        background: #e0e0e0;
        border-radius: 5px;
        cursor: pointer;
      }
      nav button:hover {
        background: #d1d1d1;
      }
      .container {
        display: grid;
        grid-template-columns: 1fr 2fr;
        gap: 10px;
        padding: 20px;
      }
      .sidebar {
        background: #fff;
        border-radius: 12px;
        padding: 10px;
        margin-top: 10px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      }
      .main {
        display: grid;
        grid-template-rows: 1fr 1fr;
        gap: 20px;
      }
      .box {
        background: #fff;
        border-radius: 12px;
        padding: 10px 10px  10px 10px;
        margin-top: 10px;
        box-shadow: 2px 2px 8px rgba(0,0,0,0.1);
      }
      footer {
        text-align: center;
        padding: 15px;
        background: #eeeeee;
        margin-top: 10px;
        font-size: 14px;
        color: #555;
      }
      a {
        color: #c00;
        text-decoration: none;
      }
      @media (max-width: 768px) {
        .container {
          grid-template-columns: 1fr;
        }
        .main {
          grid-template-rows: auto;
        }
      }
     .op-logico   { color: #d73a49; font-weight: bold; }   /* vermelho */
      .op-simbolo  { color: #d73a49; }
      .numero      { color: #005f5f; }
      .string      { color: #032f62; }
      .parenteses  { color: #cc880a; font-weight: bold; }
    "))
  ),

  tags$header(
    tags$img(src = "logo2.png", alt = "SyntaxSearch Logo"),
    tags$nav(
      tags$a(href = "./",
             class = "btn btn-primary",
        "Home"),
      tags$a(href = "sobre.html",
                  class = "btn btn-primary",
                  "Sobre"),
      tags$a(href = "faq.html",
             class = "btn btn-primary",
             "FAQ")
    )
  ),


  # Corpo principal
  fluidRow(
    column(3,  # Sidebar à esquerda
           div(class = "box",
               h6("Escolha seu arquivo CSV"),
               fileInput('datafile', '', accept = '.csv'),
               checkboxInput("header", "Cabeçalho", TRUE),
               radioButtons("sep", "Separador", choices = c(Comma = ",", Semicolon = ";", Tab = "\t"), selected = ";"),
               radioButtons("quote", "Citação", choices = c(None = "", "Double Quote" = '"', "Single Quote" = "'"), selected = '"'),
               uiOutput("varselect"),
           ),
           div(class = "box",
               textAreaInput("expressao", "Syntax:", NULL,
                             placeholder = "(operadores: AND (OR, |)"),
               span(class  = "highlighted",
                    htmlOutput("texto_destacado")
                    )

           ),
           div(class = "box",

               uiOutput("downloadBtn")
           )
    ),
    column(9,  # Conteúdo principal à direita
           div(class = "box",
               style = "height: 500px; overflow-x: auto;",

               DTOutput("table",  width = "100%")
           ),
           div(class = "box",
               h4("Nuvem de Palavras"),
               span(sliderInput("slider", "Frequência Mínima",
                               min = 1, max = 100, value = 5)),
               wordcloud2Output("nuvem")  # se quiser adicionar a nuvem aqui depois
           )
    )
  ),

  # Rodapé
  tags$footer(
    style = "text-align:center; padding:15px; background:#eeeeee; font-size:14px;",
    tags$p("SyntaxSearch desenvolvido por Denisson Silva e Maria Sirleidy Cordeiro"),
    tags$p("Como citar:",   tags$br(),
           "Denisson Silva, & Cordeiro, M. S. (2025). silvadenisson/SyntaxSearch: pacote R syntaxsearch (syntaxsearch). Zenodo.",
           tags$a("https://doi.org/10.5281/zenodo.15511938", href = "https://doi.org/10.5281/zenodo.15511938", target="_blank")
           )
  )
)
