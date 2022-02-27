module Evergreen.V12.Parser.Expr exposing (..)

import Evergreen.V12.Parser.Token


type Expr
    = Expr String (List Expr) Evergreen.V12.Parser.Token.Meta
    | Text String Evergreen.V12.Parser.Token.Meta
    | Verbatim String String Evergreen.V12.Parser.Token.Meta
    | Error String
