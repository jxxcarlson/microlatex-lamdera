module PrimitiveBlock exposing (..)

import Expect exposing (..)
import Markup
import Parser.Language exposing (Language(..))
import Parser.Line
import Parser.PrimitiveBlock exposing (PrimitiveBlock, blockListOfStringList)
import Test exposing (..)


bllc str =
    blockListOfStringList L0Lang Markup.isVerbatimLine (String.lines str) |> List.map .content


test_ label expr expectedOutput =
    test label <| \_ -> equal expr expectedOutput



{-
   FOR THE MOMENT: sequences of two or more newlines parse to [""].
   That way there is an effient representation of the end-of-block marker.
   Not sure if this is a good idea.


-}


suite : Test
suite =
    describe "The primitive block parser"
        [ test_ "two paragraphs" (bllc "abc\ndef\n\nghi\njkl") [ [ "abc", "def" ], [ "" ], [ "ghi", "jkl" ] ]
        , test_ "two paragraphs (2)" (bllc "abc\n  def\n\nghi\njkl") [ [ "abc", "  def" ], [ "" ], [ "ghi", "jkl" ] ]
        , test_ "two paragraphs (3)" (bllc "abc\ndef\n\n\nghi\njkl") [ [ "abc", "def" ], [ "" ], [ "ghi", "jkl" ] ]
        , test_ "two paragraphs (4)" (bllc "abc\ndef\n\n\n\nghi\njkl") [ [ "abc", "def" ], [ "" ], [ "ghi", "jkl" ] ]
        ]
