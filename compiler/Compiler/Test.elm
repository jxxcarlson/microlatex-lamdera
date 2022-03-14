module Compiler.Test exposing (bib, bib2, bib3, bll, blm, blmt, dpl, dpm, ibl, ibm, pl, plt, pm, pmt, txt)

import Compiler.Acc
import Compiler.DifferentialParser
import Compiler.Transform
import Markup
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock as PrimitiveBlock



-- DATA


txt =
    """| item
One

  | item
  Alpha
"""


bib =
    """| bibitem foo
[link New York Times https://nytimes.com]
"""


bib2 =
    """\\bibitem{NB}
Niels Bohr, Memoirs
"""


bib3 =
    """\\bibitem{NB}
Niels Bohr, memoirs"""



-- TEST formation of primitive blocks


bll str =
    PrimitiveBlock.blockListOfStringList L0Lang (\_ -> False) (String.lines str)


blm str =
    PrimitiveBlock.blockListOfStringList MicroLaTeXLang (\_ -> False) (String.lines str)



-- TEST formation of primitive blocks with transform


blmt str =
    blm str |> List.map (Transform.transform MicroLaTeXLang)



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
