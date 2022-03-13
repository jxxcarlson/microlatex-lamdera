module Compiler.Test exposing (bll, blm, blmt, dpl, dpm, ibl, ibm, ilist, pl, plt, pm, pmt)

import Compiler.Acc
import Compiler.DifferentialParser
import Markup
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock as PrimitiveBlock
import Parser.PrimitiveTransform as PrimitiveTransform



-- DATA


ilist =
    """\\item
Two
  
  \\item
  Alpha"""



-- TEST formation of primitive blocks


bll str =
    PrimitiveBlock.blockListOfStringList L0Lang (\_ -> False) (String.lines str)


blm str =
    PrimitiveBlock.blockListOfStringList MicroLaTeXLang (\_ -> False) (String.lines str)



-- TEST formation of primitive blocks with transform


blmt str =
    blm str |> List.map (PrimitiveTransform.transform MicroLaTeXLang)



-- TEST formation of intermediate blocks


ibl str =
    Markup.parseToIntermediateBlocks L0Lang str


ibm str =
    Markup.parseToIntermediateBlocks MicroLaTeXLang str



-- TEST parser with transform


plt str =
    Markup.parse L0Lang str |> Compiler.Acc.transformST L0Lang


pmt str =
    Markup.parse MicroLaTeXLang str |> Compiler.Acc.transformST MicroLaTeXLang



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
