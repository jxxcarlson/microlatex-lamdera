module Compiler.Test exposing
    ( bll
    , blm
    , blmt
    , blx
    , blxt
    , dpl
    , dpm
    , ex
    , ibl
    , ibm
    , ibx
    , pl
    , plt
    , pm
    , pmt
    , pxt
    )

import Compiler.Acc
import Compiler.DifferentialParser
import Compiler.Transform
import Markup
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock as PrimitiveBlock


ex =
    """
\\begin{A}
    XXX
    
    YYY
    
    ZZZ
\\end{A}"""



-- TEST formation of primitive blocks


bll str =
    PrimitiveBlock.blockListOfStringList L0Lang Markup.isVerbatimLine (String.lines str)


blm str =
    PrimitiveBlock.blockListOfStringList MicroLaTeXLang Markup.isVerbatimLine (String.lines str)


blx str =
    PrimitiveBlock.blockListOfStringList XMarkdownLang Markup.isVerbatimLine (String.lines str)



-- TEST formation of primitive blocks with transform


blmt str =
    blm str |> List.map (Compiler.Transform.transform MicroLaTeXLang)


blxt str =
    blx str |> List.map (Compiler.Transform.transform XMarkdownLang)



-- TEST formation of intermediate blocks


ibl str =
    Markup.parseToIntermediateBlocks L0Lang str


ibm str =
    Markup.parseToIntermediateBlocks MicroLaTeXLang str


ibx str =
    Markup.parseToIntermediateBlocks XMarkdownLang str



-- TEST parser with transform


plt str =
    Markup.parse L0Lang str |> Compiler.Acc.transformST L0Lang


pmt str =
    Markup.parse MicroLaTeXLang str |> Compiler.Acc.transformST MicroLaTeXLang


pxt str =
    Markup.parse XMarkdownLang str |> Compiler.Acc.transformST XMarkdownLang



-- TEST Parser


pl str =
    Markup.parse L0Lang str


pm str =
    Markup.parse MicroLaTeXLang str



-- TEST differential parser


dpl str =
    Compiler.DifferentialParser.init L0Lang str |> .parsed


dpm str =
    Compiler.DifferentialParser.init MicroLaTeXLang str |> .parsed
