module Evergreen.V13.Parser.Expr exposing (..)

import Evergreen.V13.Parser.Token


type Expr
    = Expr String (List Expr) Evergreen.V13.Parser.Token.Meta
    | Text String Evergreen.V13.Parser.Token.Meta
    | Verbatim String String Evergreen.V13.Parser.Token.Meta
    | Error String
