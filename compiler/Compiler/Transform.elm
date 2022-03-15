module Compiler.Transform exposing (transform)

import MicroLaTeX.Parser.Transform
import Parser.Language exposing (Language(..))
import Parser.PrimitiveBlock exposing (PrimitiveBlock)
import XMarkdown.Transform


transform : Language -> PrimitiveBlock -> PrimitiveBlock
transform lang block =
    case lang of
        L0Lang ->
            block

        MicroLaTeXLang ->
            MicroLaTeX.Parser.Transform.transform block

        XMarkdownLang ->
            -- TODO: implement this
            XMarkdown.Transform.transform block
