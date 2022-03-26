module Compiler.Test exposing (..)

--( bll
--, blm
--, blmt
--, blx
--, blxt
--, dpl
--, dpm
--, ex1
--, ex2
--, ex3
--, ibl
--, ibm
--, ibx
--, l1
--, pl
--, plt
--, pm
--, pmt
--, pxt
--)

import Compiler.Acc
import Compiler.DifferentialParser
import Compiler.Transform
import Markup
import MicroLaTeX.Parser.TransformLaTeX
import Parser.Block exposing (ExpressionBlock)
import Parser.Forest exposing (Forest)
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock as PrimitiveBlock exposing (PrimitiveBlock)
import Tree exposing (Tree)



-- TEST formation of primitive blocks


tol0 : String -> List String
tol0 str =
    str |> String.lines |> MicroLaTeX.Parser.TransformLaTeX.toL0


bll : String -> List PrimitiveBlock
bll str =
    PrimitiveBlock.toPrimitiveBlocks L0Lang Markup.isVerbatimLine (String.lines str)


blm : String -> List PrimitiveBlock
blm str =
    PrimitiveBlock.toPrimitiveBlocks MicroLaTeXLang Markup.isVerbatimLine (String.lines str)


blx : String -> List PrimitiveBlock
blx str =
    PrimitiveBlock.toPrimitiveBlocks XMarkdownLang Markup.isVerbatimLine (String.lines str)



-- TEST formation of primitive blocks with transform


blmt : String -> List PrimitiveBlock
blmt str =
    blm str |> List.map (Compiler.Transform.transform MicroLaTeXLang)


blxt : String -> List PrimitiveBlock
blxt str =
    blx str |> List.map (Compiler.Transform.transform XMarkdownLang)



-- TEST formation of intermediate blocks
-- TEST parser with transform


plt : String -> Forest ExpressionBlock
plt str =
    Markup.parse L0Lang str |> Compiler.Acc.transformST L0Lang


pmt : String -> Forest ExpressionBlock
pmt str =
    Markup.parse MicroLaTeXLang str |> Compiler.Acc.transformST MicroLaTeXLang


pxt : String -> Forest ExpressionBlock
pxt str =
    Markup.parse XMarkdownLang str |> Compiler.Acc.transformST XMarkdownLang



-- TEST Parser


pl : String -> Forest ExpressionBlock
pl str =
    Markup.parse L0Lang str


pm : String -> Forest ExpressionBlock
pm str =
    Markup.parse MicroLaTeXLang str



-- TEST differential parser


dpl : String -> List (Tree ExpressionBlock)
dpl str =
    Compiler.DifferentialParser.init L0Lang str |> .parsed


dpm : String -> List (Tree ExpressionBlock)
dpm str =
    Compiler.DifferentialParser.init MicroLaTeXLang str |> .parsed



-- EXAMPLES


a2 =
    """
| indent
abc

  | indent
  def

    | indent
    ghi

"""


a3 =
    """
| theorem
This is a very good theorem

  $$
  x^2
  $$

  Isn't that nice?

"""


a4 =
    """
\\begin{theorem}
This is a very good theorem

  $$
  x^2
  $$

  Isn't that nice?

\\end{theorem}
"""
